--[[
	DamageService  (server only)
	The single place damage is applied. Scales by the attacker's class level
	(ProgressionService:GetDamageMultiplier) and grants XP for killing blows: any Model with an
	"XPReward" attribute gives that much XP to the player who landed the final hit.

	API:
		:ApplyDamage(attacker: Player, humanoid, baseDamage, info?) -> damageDealt
			info = { Class = "Sword", WeaponId = "StarterSword" }
		:CanDamage(attacker: Player, humanoid) -> boolean     (PvP rule, alive check)
		.Damaged  Signal(attacker, humanoid, amount, info)
		.Killed   Signal(attacker, model, info)

	Teammates' mobs: just set the XPReward attribute on the mob Model; nothing else to wire.
	See Docs.Combat > "Damage" and Docs.Progression > "Granting XP".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)
local ProgressionService = require(script.Parent.ProgressionService)

local DamageService = {
	Damaged = Signal.new(),
	Killed = Signal.new(),
}

function DamageService:CanDamage(attacker: Player, humanoid: Humanoid): boolean
	if humanoid.Health <= 0 then
		return false
	end
	local model = humanoid.Parent
	if model == attacker.Character then
		return false
	end
	if not CombatConfig.PvPEnabled and Players:GetPlayerFromCharacter(model) then
		return false
	end
	return true
end

function DamageService:ApplyDamage(attacker: Player, humanoid: Humanoid, baseDamage: number, info: { Class: string?, WeaponId: string? }?): number
	if not self:CanDamage(attacker, humanoid) then
		return 0
	end
	info = info or {}
	local amount = baseDamage * ProgressionService:GetDamageMultiplier(attacker, info.Class)
	amount = math.floor(amount * 10 + 0.5) / 10

	humanoid:TakeDamage(amount)
	self.Damaged:Fire(attacker, humanoid, amount, info)

	if humanoid.Health <= 0 then
		local model = humanoid.Parent :: Model
		self.Killed:Fire(attacker, model, info)
		local reward = model:GetAttribute(CombatConfig.Attributes.XPReward)
		if typeof(reward) == "number" and reward > 0 then
			ProgressionService:AddXP(attacker, reward, "Kill:" .. model.Name)
		end
	end
	return amount
end

return DamageService
