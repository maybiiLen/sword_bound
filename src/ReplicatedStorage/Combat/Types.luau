--!strict
--[[
	Types
	Shared Luau types for weapon and class data. Require this for type annotations:
		local Types = require(ReplicatedStorage.Combat.Types)
		local def: Types.WeaponDefinition = ...

	Timing (when the blade can hit, when you can cancel) is NOT here: it comes from the
	animation's markers in Combat.Animations.Specs, so animation and gameplay can't drift apart.
	See Docs.Combat > "Adding a new sword" for what each field means.
]]

export type AttackDefinition = {
	Animation: string, -- AnimationLibrary name, e.g. "Light1" (markers: HitStart, HitEnd, CancelOpen, Lunge)
	DamageMultiplier: number, -- x weapon Damage
	StaminaCost: number,
	PoiseDamage: number, -- breaks the target's poise (stagger) when it reaches 0
	Weight: string, -- "Light" | "Heavy": hit-stop and camera shake strength (CombatConfig.HitStop/Shake)
	Lunge: number?, -- x CombatConfig.LungeSpeed forward push on the "Lunge" marker (0/nil = none)
	HyperArmor: boolean?, -- true: taking a hit doesn't flinch you out of this attack (poise break still does)
	Sound: string?, -- Sound name in Combat.Assets.Sounds played at swing start
}

export type HeavyDefinition = AttackDefinition & {
	ChargeAnimation: string, -- looping pose while holding the attack button
	FullChargeDamageBonus: number, -- extra DamageMultiplier fraction at full charge (0.5 = +50%)
	FullChargePoiseBonus: number,
}

export type WeaponDefinition = {
	Id: string,
	DisplayName: string,
	Class: string, -- progression class id (ReplicatedStorage.Classes.Definitions) AND behavior module name
	Model: string, -- model name in Combat.Assets.WeaponModels
	Damage: number,
	Reach: number, -- studs from the wielder's root part the weapon can hit
	Combo: { AttackDefinition }, -- light attacks, chained by tapping attack
	Heavy: HeavyDefinition, -- hold attack to charge, release to swing
	ComboResetTime: number, -- seconds after a light attack ends before the combo restarts at 1
	BlockStability: number, -- 0..1, higher = less stamina lost per blocked hit
	IdleAnimation: string, -- drawn guard pose (AnimationLibrary name)
	BlockAnimation: string, -- looping block pose
	Skills: { any }, -- reserved for Sword Skills
}

export type ClassDefinition = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	Icon: string?,
}

return {}
