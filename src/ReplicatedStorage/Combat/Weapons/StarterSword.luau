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
			Animation = "Light3",
			DamageMultiplier = 1.4,
			StaminaCost = 16,
			PoiseDamage = 20,
			Weight = "Heavy",
			Lunge = 1.4,
			Warp = 3,
			Knockback = 4, -- finisher: pushes the target 4 studs away (ends the string, like TSB/Deepwoken)
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

