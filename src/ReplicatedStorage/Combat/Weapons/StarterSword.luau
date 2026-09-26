--[[
	Weapon: StarterSword ("Anneal Blade")
	Pure data; copy this module to make a new sword. Fields are documented in Combat.Types
	(WeaponDefinition / AttackDefinition) and Docs.Combat > "Adding a new sword".

	Animations are Roblox-owned placeholders until our animator makes real ones:
		R15: 522635514 Sword Slash, 522638767 Sword Lunge, 507768375 tool hold
		R6:  129967390 Slash, 129967478 Lunge, 182393478 tool hold
	When real animations have "HitStart"/"HitEnd" keyframe markers, set UseMarkers = true on
	that attack and HitWindow becomes only the server's validation window.
]]

return {
	Id = "StarterSword",
	DisplayName = "Anneal Blade",
	Class = "Sword",
	Model = "StarterSword",
	Damage = 12,
	Reach = 7,
	ComboResetTime = 0.8,

	IdleAnimation = "rbxassetid://507768375",
	IdleAnimationR6 = "rbxassetid://182393478",

	Combo = {
		{
			Animation = "rbxassetid://522635514",
			AnimationR6 = "rbxassetid://129967390",
			Duration = 0.45,
			DamageMultiplier = 1.0,
			HitWindow = { 0.15, 0.75 },
			Sound = "Swing",
		},
		{
			Animation = "rbxassetid://522635514",
			AnimationR6 = "rbxassetid://129967390",
			Duration = 0.45,
			DamageMultiplier = 1.1,
			HitWindow = { 0.15, 0.75 },
			Sound = "Swing",
		},
		{
			Animation = "rbxassetid://522638767",
			AnimationR6 = "rbxassetid://129967478",
			Duration = 0.65,
			DamageMultiplier = 1.5,
			HitWindow = { 0.2, 0.8 },
			Sound = "Lunge",
		},
	},

	Skills = {},
}
