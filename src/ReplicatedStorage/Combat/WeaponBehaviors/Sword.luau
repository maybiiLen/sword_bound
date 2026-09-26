--[[
	Sword  (client behavior, extends BaseWeapon)
	Used by every weapon definition with Class = "Sword". Adds on top of BaseWeapon:
		- a swept Hitbox from the model's BladeBase to BladeTip attachments, live during the hit window
		- the blade's SwingTrail during the hit window
		- the attack's swing Sound
		- local hit feedback: spark, hit-stop (the attack animation freezes for a few frames) and
		  camera shake, sized by the attack's Weight (CombatConfig.HitStop / CombatConfig.Shake)

	New swords never need to touch this file: they're definitions + models.
	A new weapon TYPE (Bow, Spear...) is a sibling module named after its class.

	See Docs.Combat > "Adding a weapon type".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = ReplicatedStorage.Combat
local BaseWeapon = require(script.Parent.BaseWeapon)
local Hitbox = require(Combat.Hitbox)
local Effects = require(Combat.Effects)
local CombatConfig = require(Combat.CombatConfig)

local Sword = setmetatable({}, { __index = BaseWeapon })
Sword.__index = Sword

function Sword.new(definition, character: Model, model: Model, animationSet)
	local self = setmetatable(BaseWeapon.new(definition, character, model, animationSet), Sword)

	local handle = model.PrimaryPart :: BasePart
	self.Hitbox = self.Trove:Add(Hitbox.new({
		Base = handle:FindFirstChild("BladeBase") :: Attachment,
		Tip = handle:FindFirstChild("BladeTip") :: Attachment,
		Ignore = { character },
	}))
	self.Trove:Add(self.Hitbox.Hit:Connect(function(target: Model, _part: BasePart, position: Vector3)
		local current = self._attack
		local weight = current and current.attack.Weight or "Light"
		Effects.HitSpark(position)
		Effects.HitStop(self:GetAttackTrack(), CombatConfig.HitStop[weight] or 0.06)
		Effects.Shake(CombatConfig.Shake[weight] or 0.25)
		self:ReportHit(target, position)
	end))

	return self
end

function Sword:OnAttackStart(attack)
	Effects.PlaySound(self.Character:FindFirstChild("HumanoidRootPart"), attack.Sound)
end

function Sword:OnHitWindowOpen()
	Effects.SetTrail(self.Character, true)
	self.Hitbox:Start()
end

function Sword:OnHitWindowClose()
	self.Hitbox:Stop()
	Effects.SetTrail(self.Character, false)
end

return Sword
