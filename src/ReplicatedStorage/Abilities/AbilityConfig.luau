--[[
	AbilityConfig  (shared data)
	Tuning for the ability hotbar (3 ability slots + 1 ultimate bar at the bottom of the screen).
	Change names, keys, colors and numbers HERE, not in AbilityHudController.

	Used by: AbilityHudController. See Docs.Abilities.
]]

return {
	-- The three ability slots, left to right. Name is a placeholder until real abilities exist
	-- (an ability system can overwrite it with AbilityHudController:SetAbilityName).
	Slots = {
		{ Name = "Ability 1", Key = Enum.KeyCode.One, PreviewCooldown = 4 },
		{ Name = "Ability 2", Key = Enum.KeyCode.Two, PreviewCooldown = 6 },
		{ Name = "Ability 3", Key = Enum.KeyCode.Three, PreviewCooldown = 8 },
	},

	UltimateName = "ULTIMATE",
	UltimateKey = Enum.KeyCode.R,

	-- PREVIEW MODE: no ability system exists yet, so the HUD fakes one to be visible/testable.
	-- Pressing a slot starts its PreviewCooldown and charges the ultimate; pressing the ultimate
	-- key when full empties the bar. Set PreviewMode = false once real abilities drive the HUD.
	PreviewMode = true,
	PreviewUltimateGain = 0.2, -- fraction of the ultimate bar one ability press adds

	-- Player attributes a real ability system can set instead of calling the controller API.
	-- (%d = slot number). Cooldown end is a workspace:GetServerTimeNow() timestamp.
	Attributes = {
		CooldownEnd = "Ability%dCooldownEnd",
		CooldownTime = "Ability%dCooldownTime", -- total cooldown length in seconds
		UltimateCharge = "UltimateCharge", -- 0..1
	},

	Colors = {
		Red = Color3.fromRGB(200, 38, 44),
		RedFull = Color3.fromRGB(255, 70, 60), -- ultimate bar when it is full
		SlotBackground = Color3.fromRGB(58, 58, 58),
		BarBackground = Color3.fromRGB(34, 34, 34),
	},
}
