--[[
	Sword  (client behavior, extends BaseWeapon)
	Used by every weapon definition with Class = "Sword". Adds on top of BaseWeapon:
		- a swept Hitbox from the model's BladeBase to BladeTip attachments, live during the hit window
		- the blade's SwingTrail during the hit window
		- the attack's swing Sound
		- local hit feedback: the damage-type hit effect (Combat.VFX: Slash / Strike / Pierce, red
		  with a white target flash on a counter hit), hit-stop (the attack animation freezes for
		  CombatConfig.ClassHitStop[class][Weight], + CounterHitStop on a counter hit) and camera
		  shake sized by the attack's Weight (CombatConfig.Shake)
		- the class swing trail look (CombatConfig.ClassTrails) applied when the weapon is built

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
local CombatRules = require(Combat.CombatRules)
local HitReactions = require(Combat.HitReactions)
local AnimationLibrary = require(Combat.Animations.AnimationLibrary)

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
	Effects.StyleTrail(model, definition.Class)
	self.Trove:Add(self.Hitbox.Hit:Connect(function(target: Model, _part: BasePart, position: Vector3)
		local current = self._attack
		local attack = current and current.attack
		local weight = attack and attack.Weight or "Light"
		-- predict what the server will decide: damage type from the attack, counter from the
		-- target's replicated CombatState (DamageService uses the same CombatRules)
		local damageType = CombatRules.DamageTypeOf(attack, self.Definition)
		local counter = CombatRules.IsCounterState(target:GetAttribute(CombatConfig.Attributes.CombatState))
		local root = self.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local direction = nil
		if root then
			direction = if damageType == "Pierce" then root.CFrame.LookVector else root.CFrame.RightVector
		end
		Effects.HitSpark(position, {
			Own = true, -- your own hit: full-volume rolloff (CombatAudio)
			DamageType = damageType,
			Counter = counter,
			Weight = weight,
			Direction = direction,
			Target = target,
		})
		local classStops = CombatConfig.ClassHitStop[self.Definition.Class]
		local stop = (classStops and classStops[weight]) or CombatConfig.HitStop[weight] or 0.06
		if counter then
			stop += CombatConfig.CounterHitStop
		end
		-- predict the target's hit reaction (the server sends the same one to everyone else). A
		-- staggered or blocking target has its own animation, so it gets none.
		local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
		local targetState = target:GetAttribute(CombatConfig.Attributes.CombatState)
		local breaksPoise = CombatRules.PredictsPoiseBreak(target, attack)
		if root and targetRoot and targetState ~= "Staggered" and targetState ~= "Blocking" and not breaksPoise then
			local fromBehind = CombatRules.IsFromBehind(targetRoot.CFrame, root.Position)
			local reaction, _slide, _slideTime, armored = CombatRules.HitReaction(attack, CombatRules.ArmorTierOf(target), counter, fromBehind)
			if armored then
				stop += CombatConfig.HitReaction.ArmorHitStop
				Effects.FlashModel(target, Color3.new(1, 1, 1), CombatConfig.HitReaction.ArmorFlashTime)
			end
			HitReactions.Play(target, reaction, stop, root.Position)
		end
		Effects.HitStop(self:GetAttackTrack(), stop)
		Effects.Shake(CombatConfig.Shake[weight] or 0.25)
		self:ReportHit(target, position)
	end))

	return self
end

function Sword:OnAttackStart(attack)
	-- time the whoosh so its loudest point lands on the hit frame (CombatAudio PeakAt), the way
	-- God of War seeks into its files (vault: Combat sound design research)
	local hitAt = AnimationLibrary.MarkerTime(attack.Animation, "HitStart")
	Effects.PlaySound(self.Character:FindFirstChild("HumanoidRootPart"), attack.Sound, nil, hitAt)
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

