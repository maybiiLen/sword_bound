--!strict
--[[
	XPCurve
	Pure math for levels and XP; no state, safe on client and server.

	API:
		XPCurve.XPToNext(level) -> number         XP needed for level -> level+1 (0 at max)
		XPCurve.TotalXPForLevel(level) -> number  cumulative XP from level 1
		XPCurve.Apply(level, xp, amount) -> (newLevel, newXP, levelsGained)

	Tune the curve in ClassConfig (BaseXP, Exponent, MaxLevel). See Docs.Progression.
]]

local ClassConfig = require(script.Parent.ClassConfig)

local XPCurve = {}

function XPCurve.XPToNext(level: number): number
	if level >= ClassConfig.MaxLevel then
		return 0
	end
	return math.floor(ClassConfig.BaseXP * level ^ ClassConfig.Exponent)
end

function XPCurve.TotalXPForLevel(level: number): number
	local total = 0
	for l = 1, math.min(level, ClassConfig.MaxLevel) - 1 do
		total += XPCurve.XPToNext(l)
	end
	return total
end

function XPCurve.Apply(level: number, xp: number, amount: number): (number, number, number)
	local startLevel = level
	if level >= ClassConfig.MaxLevel then
		return ClassConfig.MaxLevel, 0, 0
	end
	xp += math.max(amount, 0)
	while level < ClassConfig.MaxLevel and xp >= XPCurve.XPToNext(level) do
		xp -= XPCurve.XPToNext(level)
		level += 1
	end
	if level >= ClassConfig.MaxLevel then
		xp = 0
	end
	return level, xp, level - startLevel
end

return XPCurve
