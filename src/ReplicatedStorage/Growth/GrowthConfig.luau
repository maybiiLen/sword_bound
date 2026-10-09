--[[
	GrowthConfig  (shared: server + client)
	All tuning for the Growth screen (attribute points): the 7 attributes, how many Growth Points a
	player gets, the Bonus Modifier ladder, and the pure math that turns attributes into the stats
	shown on the panel. No state lives here.

	Public API:
		.Attributes            list of { Id, Name, Glyph, Description } in display order
		.Get(id) -> def?
		.StartingPoints / .PointsPerLevel / .MaxAttribute / .ResetCost
		.PlayerAttributes      names of the replicated Player attributes (see below)
		.Bonuses(id) -> { { Req, Stat, Percent } }   the ladder shown in the right-hand list
		.ComputeStats(allocated, weaponAtk, weaponClass) -> stats table (see function)
		.ScalingFor(weaponClass) -> { [attrId] = grade }

	Replicated Player attributes (written by ServerScriptService.Growth.GrowthService):
		GrowthPoints      unspent Growth Points
		Growth_<AttrId>   points the player has put into that attribute (0 = attribute value 1)

	An attribute's value is always 1 + points put into it (every attribute starts at 1).
	Used by: GrowthService (server), StarterGui.Main Menu Gui.GrowthController (client).
	See Docs.Growth.
]]

local GrowthConfig = {}

GrowthConfig.StartingPoints = 5 -- points every new player begins with
GrowthConfig.PointsPerLevel = 3 -- per class level gained beyond 1, summed over all classes
GrowthConfig.MaxAttribute = 99 -- highest attribute VALUE (so 98 points max per attribute)
GrowthConfig.ResetCost = 0 -- Col per redistribution; there is no currency yet, so keep this 0

GrowthConfig.PlayerAttributes = {
	Points = "GrowthPoints",
	Prefix = "Growth_", -- + attribute id, e.g. Growth_STR
}

GrowthConfig.Attributes = {
	{ Id = "VIT", Name = "VIT", Glyph = "❤", Description = "Vitality: Raises maximum HP and a little defense." },
	{ Id = "END", Name = "END", Glyph = "⚡", Description = "Endurance: Raises maximum stamina and defense." },
	{ Id = "MND", Name = "MND", Glyph = "🔥", Description = "Mind: Raises maximum SP for skills and abilities." },
	{ Id = "STR", Name = "STR", Glyph = "💪", Description = "Strength: Affects STR-based weapons and defense." },
	{ Id = "DEX", Name = "DEX", Glyph = "🎯", Description = "Dexterity: Affects DEX-based weapons and attack." },
	{ Id = "AGI", Name = "AGI", Glyph = "👟", Description = "Agility: Affects AGI-based weapons and stamina." },
	{ Id = "INT", Name = "INT", Glyph = "📖", Description = "Intelligence: Affects INT-based weapons and SP." },
}

local byId = {}
for _, def in GrowthConfig.Attributes do
	byId[def.Id] = def
end

function GrowthConfig.Get(id: string)
	return byId[id]
end

-- Stat labels used in the Bonus Modifier list.
GrowthConfig.StatNames = {
	HP = "Max HP",
	STA = "Stamina",
	SP = "SP",
	ATK = "Attack",
	DEF = "Defense",
}

-- Base stats and what each attribute point adds (flat), before percent bonuses.
GrowthConfig.Base = { HP = 100, STA = 100, SP = 100, DEF = 10 }
GrowthConfig.PerPoint = {
	HP = { VIT = 10 },
	STA = { END = 5 },
	SP = { MND = 5 },
	DEF = { END = 2, VIT = 1, STR = 1 },
}

-- Weapon scaling: a weapon CLASS has a grade per attribute; each point of that attribute adds
-- (weapon ATK * GradeWeight) to attack. "-" means that attribute does nothing for the class.
GrowthConfig.GradeWeight = { S = 0.04, A = 0.03, B = 0.022, C = 0.016, D = 0.01, E = 0.005 }
GrowthConfig.Scaling = {
	Sword = { STR = "B", DEX = "C", AGI = "D", INT = "E" },
	Bow = { STR = "D", DEX = "S", AGI = "C", INT = "E" },
}
local NO_SCALING = {}

function GrowthConfig.ScalingFor(weaponClass: string?): { [string]: string }
	return (weaponClass and GrowthConfig.Scaling[weaponClass]) or NO_SCALING
end

-- The Bonus Modifier ladder. Every attribute has the same shape (thresholds + percentages) but
-- boosts its own pair of stats: { statA, statB }. Req is the attribute VALUE needed.
local LADDER = {
	{ 5, 1, 2 }, { 5, 2, 3 }, { 10, 1, 3 }, { 20, 2, 5 }, { 30, 1, 3 }, { 40, 2, 5 },
	{ 50, 1, 3 }, { 60, 2, 5 }, { 70, 1, 2 }, { 80, 2, 3 }, { 90, 1, 2 }, { 90, 2, 3 },
}
local STAT_PAIRS = {
	VIT = { "HP", "DEF" },
	END = { "STA", "DEF" },
	MND = { "SP", "STA" },
	STR = { "ATK", "DEF" },
	DEX = { "ATK", "STA" },
	AGI = { "STA", "HP" },
	INT = { "SP", "ATK" },
}

local bonusCache = {}
function GrowthConfig.Bonuses(id: string)
	local cached = bonusCache[id]
	if cached then
		return cached
	end
	local pair = STAT_PAIRS[id]
	local list = {}
	if pair then
		for _, step in LADDER do
			table.insert(list, { Req = step[1], Stat = pair[step[2]], Percent = step[3] })
		end
	end
	bonusCache[id] = list
	return list
end

-- allocated: { [attrId] = points put in }. Returns:
--   { Values = { [attrId] = value }, HP, STA, SP, ATK, DEF  (final numbers),
--     AtkBase, AtkAcv, AtkMod, DefBase, DefMod  (the breakdown shown on the panel) }
function GrowthConfig.ComputeStats(allocated: { [string]: number }, weaponAtk: number, weaponClass: string?)
	local values = {}
	for _, def in GrowthConfig.Attributes do
		values[def.Id] = 1 + math.max(0, math.floor(allocated[def.Id] or 0))
	end

	-- Percent bonuses from every ladder step the attribute value has reached.
	local percent = { HP = 0, STA = 0, SP = 0, ATK = 0, DEF = 0 }
	for _, def in GrowthConfig.Attributes do
		for _, step in GrowthConfig.Bonuses(def.Id) do
			if values[def.Id] >= step.Req then
				percent[step.Stat] += step.Percent
			end
		end
	end

	local function flat(stat: string, base: number): number
		local total = base
		for attrId, perPoint in GrowthConfig.PerPoint[stat] or {} do
			total += (values[attrId] - 1) * perPoint
		end
		return total
	end

	local function withPercent(stat: string, flatValue: number): number
		return math.floor(flatValue * (1 + percent[stat] / 100) + 0.5)
	end

	local acv = 0
	for attrId, grade in GrowthConfig.ScalingFor(weaponClass) do
		local weight = GrowthConfig.GradeWeight[grade]
		if weight then
			acv += weaponAtk * weight * (values[attrId] - 1)
		end
	end
	acv = math.floor(acv + 0.5)

	local atkFlat = weaponAtk + acv
	local atk = withPercent("ATK", atkFlat)
	local defFlat = flat("DEF", GrowthConfig.Base.DEF)
	local def = withPercent("DEF", defFlat)

	return {
		Values = values,
		HP = withPercent("HP", flat("HP", GrowthConfig.Base.HP)),
		STA = withPercent("STA", flat("STA", GrowthConfig.Base.STA)),
		SP = withPercent("SP", flat("SP", GrowthConfig.Base.SP)),
		ATK = atk,
		DEF = def,
		AtkBase = weaponAtk,
		AtkAcv = acv,
		AtkMod = atk - atkFlat,
		DefBase = defFlat,
		DefMod = def - defFlat,
	}
end

return GrowthConfig

