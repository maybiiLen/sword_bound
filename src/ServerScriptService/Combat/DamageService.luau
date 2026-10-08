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
			DamageType: string?,        -- "Slash" (default) | "Strike" | "Pierce" (CombatConfig.DamageTypes)
			CritMultiplier: number?,    -- the attacker's weapon class value (CombatConfig.CritMultiplier if nil)
			GuardDamage: number?,       -- x stamina a blocker loses (1 if nil)
			Weight: string?,            -- "Light" | "Heavy": hit effect size on other clients
		}
		The math lives in Combat.CombatRules (shared with the unit tests).
		Resolution order:
			1. target has IFrames (rolling)          -> "Dodged", nothing happens
			2. target blocking and facing attacker:
			   block started <= the block's parry window ago (BlockParryWindow attribute: ParryWindow, or
			   ParryWindowSpammed if re-raised right after releasing) -> "Parried": attacker loses PoiseDamage x ParryPoiseMultiplier
		                                          poise; empty = full stagger, else ParryRecoilTime recoil.
		                                          <= PerfectParryWindow = "PerfectParry" effects.
		   A parry or a block that doesn't guard-break opens the target's guard counter: sets
		   GuardCounterUntil = now + GuardCounterWindow (read by CombatService and WeaponController).
			   otherwise                            -> "Blocked": BlockDamageMultiplier chip damage,
			                                           stamina loss; 0 stamina -> "GuardBreak"
			   blocked stamina cost = CombatRules.GuardStaminaCost (damage type and GuardDamage scale it)
			3. otherwise                             -> "Hit" (or "Crit" on a staggered target):
			                                           damage (player attackers scale with class level),
			                                           x CritMultiplier on a staggered target,
			                                           x counter bonus if the target was Attacking/Charging
			                                           (info.Counter = true), x the target's armor DamageTaken
			                                           while its attack's armor window is up,
			                                           poise damage -> flinch or stagger
		PvP (a player hitting a player) uses the CombatConfig.PvP multipliers.
		Killing blow on a Model with XPReward (by a player) -> ProgressionService:AddXP.

	:ApplyDamage(attacker: Player, humanoid, baseDamage, info?) -> damageDealt
		Kept for existing callers; same as ResolveHit with info = { Class, WeaponId, PoiseDamage }.
	:CanDamage(attacker, humanoid) -> boolean     (PvP rule, alive check, not yourself)
	:SetArmorProvider(fn)   fn(model) -> the attack whose armor window is up right now, or nil.
	                        CombatService registers it at Start (avoids a circular require).
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
local CombatRules = require(ReplicatedStorage.Combat.CombatRules)
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

local armorProvider: ((Model) -> any?)? = nil

function DamageService:SetArmorProvider(provider: (Model) -> any?)
	armorProvider = provider
end

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

-- EffectRemote to every client except `except` (the attacker already played it locally).
-- "Hit" extras: targetModel, damageType, counter, weight, direction (Effects.Listen -> Combat.VFX).
local function fireEffect(kind: string, position: Vector3, except: Player?, ...)
	for _, other in Players:GetPlayers() do
		if other ~= except then
			Remotes.EffectRemote:FireClient(other, kind, position, ...)
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
	local pvp = attackerPlayer ~= nil and targetPlayer ~= nil
	local damageType = hit.DamageType or "Slash"
	local info = { Class = hit.Class, WeaponId = hit.WeaponId, DamageType = damageType, Counter = false }

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
				local broke = PoiseService:DrainPoise(attackerModel, drain, pvp)
				if not broke then
					PoiseService:Stagger(attackerModel, CombatConfig.ParryRecoilTime, "ParryRecoil", true, pvp)
				end
			end
			target:SetAttribute(Attr.GuardCounterUntil, workspace:GetServerTimeNow() + CombatConfig.GuardCounterWindow)
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
		local staminaLeft = 1
		if targetPlayer then
			local cost = CombatRules.GuardStaminaCost(hit.Damage, damageType, hit.GuardDamage, stability)
			staminaLeft = StaminaService:Spend(targetPlayer, cost)
		end
		if staminaLeft <= 0 then
			result = "GuardBreak"
			PoiseService:Stagger(target, CombatConfig.GuardBreakTime, "GuardBreak", false, pvp)
		else
			target:SetAttribute(Attr.GuardCounterUntil, workspace:GetServerTimeNow() + CombatConfig.GuardCounterWindow)
			if targetPlayer then
				Remotes.ReactRemote:FireClient(targetPlayer, "BlockImpact")
			end
		end
		fireEffect("Block", position, nil)
		self.Damaged:Fire(attacker, humanoid, chip, info)
		self.Resolved:Fire(attacker, humanoid, result, chip)
		return result, chip
	end

	local levelMultiplier = 1
	if attackerPlayer then
		levelMultiplier = ProgressionService:GetDamageMultiplier(attackerPlayer, hit.Class)
	end
	local result = "Hit"
	local staggered = PoiseService:IsStaggered(target)
	if staggered then
		result = "Crit"
	end
	-- counter hit: the target was mid-attack (a staggered target is never Attacking)
	local isCounter = CombatRules.IsCounterState(target:GetAttribute(Attr.CombatState))
	info.Counter = isCounter
	-- armor: the target's current attack has its armor window up
	local armorTaken = 1
	if armorProvider then
		local armoredAttack = armorProvider(target)
		if armoredAttack then
			armorTaken = CombatRules.ArmorDamageTaken(armoredAttack, pvp)
		end
	end
	local amount = CombatRules.HitDamage({
		Base = hit.Damage,
		LevelMultiplier = levelMultiplier,
		Staggered = staggered,
		CritMultiplier = hit.CritMultiplier,
		Counter = CombatRules.CounterMultiplier(damageType, isCounter, pvp),
		ArmorTaken = armorTaken,
		PvP = pvp,
	})

	humanoid:TakeDamage(amount)
	self.Damaged:Fire(attacker, humanoid, amount, info)
	-- effect direction: along the thrust for Pierce, across the swing otherwise (what the
	-- attacker's own client uses), so every client draws the sparks the same way
	local attackerRoot = rootOf(attackerModel)
	local direction = nil
	if attackerRoot then
		direction = if damageType == "Pierce" then attackerRoot.CFrame.LookVector else attackerRoot.CFrame.RightVector
	end
	fireEffect("Hit", position, attackerPlayer, target, damageType, isCounter, hit.Weight or "Light", direction)

	if humanoid.Health > 0 and (hit.PoiseDamage or 0) > 0 then
		local poiseDamage = hit.PoiseDamage
		if pvp then
			poiseDamage *= CombatConfig.PvP.PoiseMultiplier
		end
		PoiseService:ApplyPoiseDamage(target, poiseDamage, pvp)
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

