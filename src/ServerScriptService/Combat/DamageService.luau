--[[
	DamageService  (server only)
	The single place hits are resolved and damage is applied, for player AND NPC attackers.

	:ResolveHit(hit) -> (result, damage)
		hit = {
			Attacker: Player | Model,   -- a player, or an NPC model
			Target: Humanoid,
			Damage: number,             -- before level scaling
			PoiseDamage: number?,
			Position: Vector3?,         -- where to show the spark
			Class: string?, WeaponId: string?,
		}
		Resolution order:
			1. target has IFrames (rolling)          -> "Dodged", nothing happens
			2. target blocking and facing attacker:
			   block started <= the block's parry window ago (BlockParryWindow attribute: ParryWindow, or
			   ParryWindowSpammed if re-raised right after releasing) -> "Parried": attacker loses PoiseDamage x ParryPoiseMultiplier
		                                          poise; empty = full stagger, else ParryRecoilTime recoil.
		                                          <= PerfectParryWindow = "PerfectParry" effects.
			   otherwise                            -> "Blocked": BlockDamageMultiplier chip damage,
			                                           stamina loss; 0 stamina -> "GuardBreak"
			3. otherwise                             -> "Hit" (or "Crit" on a staggered target):
			                                           damage (player attackers scale with class level),
			                                           poise damage -> flinch or stagger
		Killing blow on a Model with XPReward (by a player) -> ProgressionService:AddXP.

	:ApplyDamage(attacker: Player, humanoid, baseDamage, info?) -> damageDealt
		Kept for existing callers; same as ResolveHit with info = { Class, WeaponId, PoiseDamage }.
	:CanDamage(attacker, humanoid) -> boolean     (PvP rule, alive check, not yourself)
	.Damaged  Signal(attacker, humanoid, amount, info)
	.Killed   Signal(attacker, model, info)
	.Resolved Signal(attacker, humanoid, result, amount)

	Teammates' mobs: set XPReward (and optionally MaxPoise) on the mob Model; nothing else to wire.
	See Docs.Combat > "Damage" and Docs.Progression > "Granting XP".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)
local WeaponRegistry = require(ReplicatedStorage.Combat.WeaponRegistry)
local ProgressionService = require(script.Parent.ProgressionService)
local PoiseService = require(script.Parent.PoiseService)
local StaminaService = require(script.Parent.StaminaService)

local Attr = CombatConfig.Attributes
local Remotes = ReplicatedStorage.Combat.Remotes

local DamageService = {
	Damaged = Signal.new(),
	Killed = Signal.new(),
	Resolved = Signal.new(),
}

local function attackerModelOf(attacker: Instance): Model?
	if attacker:IsA("Player") then
		return attacker.Character
	end
	return if attacker:IsA("Model") then attacker else nil
end

local function rootOf(model: Model?): BasePart?
	local root = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
	return if root and root:IsA("BasePart") then root else nil
end

local function fireEffect(kind: string, position: Vector3, except: Player?, model: Model?)
	for _, other in Players:GetPlayers() do
		if other ~= except then
			Remotes.EffectRemote:FireClient(other, kind, position, model)
		end
	end
end

local function isFacing(target: Model, attackerModel: Model?): boolean
	local targetRoot, attackerRoot = rootOf(target), rootOf(attackerModel)
	if not targetRoot or not attackerRoot then
		return true
	end
	local toAttacker = attackerRoot.Position - targetRoot.Position
	toAttacker = Vector3.new(toAttacker.X, 0, toAttacker.Z)
	if toAttacker.Magnitude < 0.01 then
		return true
	end
	local look = targetRoot.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z).Unit
	return look:Dot(toAttacker.Unit) >= math.cos(math.rad(CombatConfig.BlockAngle / 2))
end

function DamageService:CanDamage(attacker: Instance, humanoid: Humanoid): boolean
	if humanoid.Health <= 0 then
		return false
	end
	local model = humanoid.Parent
	local attackerModel = attackerModelOf(attacker)
	if model == attackerModel then
		return false
	end
	if attacker:IsA("Player") and not CombatConfig.PvPEnabled and Players:GetPlayerFromCharacter(model) then
		return false
	end
	return true
end

function DamageService:ResolveHit(hit): (string, number)
	local attacker: Instance = hit.Attacker
	local humanoid: Humanoid = hit.Target
	if not self:CanDamage(attacker, humanoid) then
		return "Invalid", 0
	end
	local target = humanoid.Parent :: Model
	local attackerPlayer = if attacker:IsA("Player") then attacker else nil
	local attackerModel = attackerModelOf(attacker)
	local targetPlayer = Players:GetPlayerFromCharacter(target)
	local position = hit.Position or (rootOf(target) and (rootOf(target) :: BasePart).Position) or target:GetPivot().Position
	local info = { Class = hit.Class, WeaponId = hit.WeaponId }

	if target:GetAttribute(Attr.IFrames) == true then
		self.Resolved:Fire(attacker, humanoid, "Dodged", 0)
		return "Dodged", 0
	end

	local blockStartedAt = target:GetAttribute(Attr.BlockStartedAt)
	if typeof(blockStartedAt) == "number" and isFacing(target, attackerModel) then
		local sinceBlock = workspace:GetServerTimeNow() - blockStartedAt
		local parryWindow = target:GetAttribute(Attr.BlockParryWindow)
		if typeof(parryWindow) ~= "number" then
			parryWindow = CombatConfig.ParryWindow -- NPC blockers and older callers
		end
		if sinceBlock <= parryWindow then
			local perfect = sinceBlock <= CombatConfig.PerfectParryWindow
			if attackerModel then
				-- Sekiro-style: a parry drains the attacker's poise; only an empty bar is a full stagger,
				-- otherwise it is a short recoil (room for one counter slash).
				local drain = (hit.PoiseDamage or 0) * CombatConfig.ParryPoiseMultiplier
				local broke = PoiseService:DrainPoise(attackerModel, drain)
				if not broke then
					PoiseService:Stagger(attackerModel, CombatConfig.ParryRecoilTime, "ParryRecoil", true)
				end
			end
			if targetPlayer then
				Remotes.ReactRemote:FireClient(targetPlayer, "ParrySuccess", perfect)
			end
			fireEffect(if perfect then "PerfectParry" else "Parry", position, nil, attackerModel)
			self.Resolved:Fire(attacker, humanoid, "Parried", 0)
			return "Parried", 0
		end

		local stability = 0.3
		if targetPlayer then
			local weaponId = target:GetAttribute(Attr.EquippedWeapon)
			local definition = weaponId and WeaponRegistry.Get(weaponId)
			stability = definition and definition.BlockStability or stability
		end
		local chip = math.floor(hit.Damage * CombatConfig.BlockDamageMultiplier * 10 + 0.5) / 10
		humanoid:TakeDamage(chip)
		local result = "Blocked"
		local staminaLeft = if targetPlayer
			then StaminaService:Spend(targetPlayer, hit.Damage * CombatConfig.BlockStaminaPerDamage * (1 - stability))
			else 1
		if staminaLeft <= 0 then
			result = "GuardBreak"
			PoiseService:Stagger(target, CombatConfig.GuardBreakTime, "GuardBreak")
		elseif targetPlayer then
			Remotes.ReactRemote:FireClient(targetPlayer, "BlockImpact")
		end
		fireEffect("Block", position, nil)
		self.Damaged:Fire(attacker, humanoid, chip, info)
		self.Resolved:Fire(attacker, humanoid, result, chip)
		return result, chip
	end

	local amount = hit.Damage
	if attackerPlayer then
		amount *= ProgressionService:GetDamageMultiplier(attackerPlayer, hit.Class)
	end
	local result = "Hit"
	if PoiseService:IsStaggered(target) then
		amount *= CombatConfig.CritMultiplier
		result = "Crit"
	end
	amount = math.floor(amount * 10 + 0.5) / 10

	humanoid:TakeDamage(amount)
	self.Damaged:Fire(attacker, humanoid, amount, info)
	fireEffect("Hit", position, attackerPlayer)

	if humanoid.Health > 0 and (hit.PoiseDamage or 0) > 0 then
		PoiseService:ApplyPoiseDamage(target, hit.PoiseDamage)
	end

	if humanoid.Health <= 0 then
		self.Killed:Fire(attacker, target, info)
		local reward = target:GetAttribute(Attr.XPReward)
		if attackerPlayer and typeof(reward) == "number" and reward > 0 then
			ProgressionService:AddXP(attackerPlayer, reward, "Kill:" .. target.Name)
		end
	end
	self.Resolved:Fire(attacker, humanoid, result, amount)
	return result, amount
end

function DamageService:ApplyDamage(attacker: Player, humanoid: Humanoid, baseDamage: number, info: { Class: string?, WeaponId: string?, PoiseDamage: number? }?): number
	info = info or {}
	local _, amount = self:ResolveHit({
		Attacker = attacker,
		Target = humanoid,
		Damage = baseDamage,
		PoiseDamage = info.PoiseDamage,
		Class = info.Class,
		WeaponId = info.WeaponId,
	})
	return amount
end

return DamageService
