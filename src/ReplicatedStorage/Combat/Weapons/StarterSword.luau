--[[
	Weapon: StarterSword ("Anneal Blade")
	Pure data; copy this module to make a new sword. Fields are documented in Combat.Types
	(WeaponDefinition / AttackDefinition / HeavyDefinition) and Docs.Combat > "Adding a new sword".

	Animation names refer to Combat.Animations.Specs / AnimationLibrary. Timing (hit windows,
	cancel points) comes from those animations' markers, not from this file.
]]

return {
	Id = "StarterSword",
	DisplayName = "Anneal Blade",
	Class = "Sword",
	Model = "ForgeSword", -- WeaponForge model (2026-10-08); the old part-built "StarterSword" model is kept in WeaponModels
	Damage = 12,
	Reach = 7,
	ComboResetTime = 0.6,
	BlockStability = 0.5,

	IdleAnimation = "GuardIdle",
	BlockAnimation = "BlockIdle",

	Combo = {
		{
			Animation = "Light1",
			DamageMultiplier = 1.0,
			StaminaCost = 12,
			PoiseDamage = 12,
			Weight = "Light",
			Lunge = 1,
			Warp = 4, -- travels up to 4 studs to the target (CombatRules.WarpDistance)
			Sound = "Swing",
		},
		{
			Animation = "Light2",
			DamageMultiplier = 1.05,
			StaminaCost = 12,
			PoiseDamage = 12,
			Weight = "Light",
			Lunge = 1,
			Warp = 4, -- travels up to 4 studs to the target (CombatRules.WarpDistance)
			Sound = "Swing",
		},
		{
			Animation = "Light3", -- overhead chop (2026-10-09: no longer the finisher)
			DamageMultiplier = 1.15,
			StaminaCost = 14,
			PoiseDamage = 16,
			Weight = "Light",
			Lunge = 1.2,
			Warp = 3.5,
			Sound = "Swing",
		},
		{
			Animation = "Light4", -- spinning finisher (2026-10-09): one full turn at waist height, hits
			                      -- all around, pushes the target away and ends the string
			DamageMultiplier = 1.5,
			StaminaCost = 16,
			PoiseDamage = 22,
			Weight = "Heavy",
			Lunge = 1.4,
			Warp = 3,
			Knockback = 4, -- like TSB's 4th hit and Deepwoken's Flourish (vault: Roblox sword combat feel research)
			Sound = "Lunge",
		},
	},

	Heavy = {
		ChargeAnimation = "HeavyCharge",
		Animation = "HeavyRelease",
		DamageMultiplier = 1.8,
		FullChargeDamageBonus = 0.6,
		StaminaCost = 24,
		PoiseDamage = 32,
		FullChargePoiseBonus = 0.5,
		Weight = "Heavy",
		Lunge = 2,
		Warp = 3,
		Knockback = 3,
		HyperArmor = true,
		Sound = "HeavySwing",
	},

	Skills = {},
}

