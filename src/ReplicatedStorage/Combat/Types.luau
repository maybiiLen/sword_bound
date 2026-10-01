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
	Plunge: number?, -- jump attacks: downward speed (studs/s) set on the "Lunge" marker, slams you to the ground
}

export type HeavyDefinition = AttackDefinition & {
	ChargeAnimation: string, -- looping pose while holding the attack button
	FullChargeDamageBonus: number, -- extra DamageMultiplier fraction at full charge (0.5 = +50%)
	FullChargePoiseBonus: number,
}

export type RiposteDefinition = {
	Animation: string, -- markers: Lunge, HitStart (damage lands here, guaranteed), HitEnd, CancelOpen, MoveOpen
	DamageMultiplier: number, -- x weapon Damage (the staggered target's CritMultiplier applies on top)
	Range: number, -- studs from your root to the target's root to start a finisher
	Weight: string?, -- "Light" | "Heavy" hit feel
	Sound: string?, -- Sound name played at the start
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
	Riposte: RiposteDefinition?, -- finisher on a posture/guard-broken enemy (defaults from Combat.ClassDefaults)
	-- Contextual attacks: the attack button does one of these instead of Light1 when the situation
	-- matches (all optional, defaults from Combat.ClassDefaults). See Docs.Combat > CONTEXTUAL ATTACKS.
	RunningAttack: AttackDefinition?, -- attack while sprinting
	JumpAttack: AttackDefinition?, -- attack in the air (use Plunge to slam down)
	RollAttack: AttackDefinition?, -- attack out of a roll/backstep (or within RollAttackWindow after)
	GuardCounter: AttackDefinition?, -- attack within GuardCounterWindow of blocking or parrying a hit
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
