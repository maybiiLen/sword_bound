--!strict
--[[
	Types
	Shared Luau types for weapon and class data. Require this for type annotations:
		local Types = require(ReplicatedStorage.Combat.Types)
		local def: Types.WeaponDefinition = ...

	See Docs.Combat > "Adding a new sword" for what each field means.
]]

export type AttackDefinition = {
	Animation: string, -- R15 animation id
	AnimationR6: string?, -- optional R6 animation id
	Duration: number, -- seconds; the animation is sped up or slowed down to fit
	DamageMultiplier: number,
	HitWindow: { number }, -- { start, end } as fractions of Duration (0-1); server validates hits against this
	UseMarkers: boolean?, -- true: the animation's "HitStart"/"HitEnd" markers open/close the hitbox instead
	Sound: string?, -- Sound name in Combat.Assets.Sounds played at swing start
}

export type WeaponDefinition = {
	Id: string,
	DisplayName: string,
	Class: string, -- progression class id (ReplicatedStorage.Classes.Definitions) AND behavior module name
	Model: string, -- model name in Combat.Assets.WeaponModels
	Damage: number,
	Reach: number, -- studs from the wielder's root part the weapon can hit
	Combo: { AttackDefinition },
	ComboResetTime: number, -- seconds after a swing before the combo restarts at step 1
	IdleAnimation: string?, -- held pose while drawn (R15)
	IdleAnimationR6: string?,
	Skills: { any }, -- reserved for Sword Skills
}

export type ClassDefinition = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	Icon: string?,
}

return {}
