--[[
	Weapon: TestSword ("Test Sword")
	Pure data; same stats and combo as StarterSword, with the imported TestSword model.
	Fields are documented in Combat.Types and Docs.Combat > "Adding a new sword".
]]

return {
	Id = "TestSword",
	DisplayName = "Test Sword",
	Class = "Sword",
	Model = "TestSword",
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
			Sound = "Swing",
		},
		{
			Animation = "Light2",
			DamageMultiplier = 1.05,
			StaminaCost = 12,
			PoiseDamage = 12,
			Weight = "Light",
			Lunge = 1,
			Sound = "Swing",
		},
		{
			Animation = "Light3",
			DamageMultiplier = 1.4,
			StaminaCost = 16,
			PoiseDamage = 20,
			Weight = "Heavy",
			Lunge = 1.4,
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
		HyperArmor = true,
		Sound = "HeavySwing",
	},

	Skills = {},
}
