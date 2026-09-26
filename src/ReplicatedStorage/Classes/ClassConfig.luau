--!strict
--[[
	ClassConfig
	Global class/progression tuning (FF14-style: your class = the weapon type you hold,
	and every class levels independently).

	Used by: XPCurve, ProgressionService, ClassHudController. See Docs.Progression.
]]

local ClassConfig = {
	MaxLevel = 20,
	DamageBonusPerLevel = 0.05, -- +5% weapon damage per level above 1 (level 20 = +95%)

	-- XP needed to go from level L to L+1 = floor(BaseXP * L ^ Exponent)
	BaseXP = 100,
	Exponent = 1.5,

	-- Replicated attributes on the Player (read these on the client; the server writes them)
	Attributes = {
		ActiveClass = "ActiveClass", -- class id of the equipped weapon, e.g. "Sword"
		Level = "ClassLevel", -- level of the active class
		XP = "ClassXP", -- XP into the current level
		XPToNext = "ClassXPToNext", -- XP needed for the next level (0 at max level)
	},
}

return table.freeze(ClassConfig)
