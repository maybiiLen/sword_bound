--[[
	ProgressionService  (server only)
	Class levels and XP. Your class is the Class of the weapon you have equipped; each class
	levels 1 -> ClassConfig.MaxLevel on its own and is saved in PlayerData (data.Classes).

	API:
		:AddXP(player, amount, source?)                XP to the ACTIVE class (nothing if none)
		:AddClassXP(player, classId, amount, source?)  XP to a specific class
		:SetActiveClass(player, classId?)              called by WeaponService on equip (nil = none)
		:GetActiveClass(player) -> string?
		:GetLevel(player, classId?) -> number          classId defaults to the active class
		:GetDamageMultiplier(player, classId?) -> number   1 + (level - 1) * DamageBonusPerLevel
		.LevelUp     Signal(player, classId, newLevel)
		.XPGained    Signal(player, classId, amount, source)

	`source` is a free-form string for logs/analytics, e.g. "Kill:TrainingDummy", "Quest:Intro".

	Replication: Player attributes ActiveClass / ClassLevel / ClassXP / ClassXPToNext for the
	active class, Level_<ClassId> for every class (e.g. Level_Sword), and
	Combat.Remotes.LevelUpRemote(classId, newLevel) fired to that player on level-up.

	See Docs.Progression.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local ClassConfig = require(ReplicatedStorage.Classes.ClassConfig)
local ClassRegistry = require(ReplicatedStorage.Classes.ClassRegistry)
local XPCurve = require(ReplicatedStorage.Classes.XPCurve)
local PlayerDataService = require(ServerScriptService.PlayerData.PlayerDataService)

local Attributes = ClassConfig.Attributes
local LevelUpRemote = ReplicatedStorage.Combat.Remotes.LevelUpRemote

local ProgressionService = {
	LevelUp = Signal.new(),
	XPGained = Signal.new(),
}

local function getClassEntry(player: Player, classId: string): { Level: number, XP: number }?
	if not ClassRegistry.Get(classId) then
		return nil
	end
	local data = PlayerDataService:GetData(player)
	if not data then
		return nil
	end
	local entry = data.Classes[classId]
	if not entry then
		entry = { Level = 1, XP = 0 }
		data.Classes[classId] = entry
	end
	return entry
end

local function refreshAttributes(player: Player)
	local data = PlayerDataService:GetData(player)
	if not data then
		return
	end
	for classId, entry in data.Classes do
		player:SetAttribute("Level_" .. classId, entry.Level)
	end

	local classId = player:GetAttribute(Attributes.ActiveClass)
	local entry = classId and getClassEntry(player, classId)
	player:SetAttribute(Attributes.Level, entry and entry.Level or nil)
	player:SetAttribute(Attributes.XP, entry and entry.XP or nil)
	player:SetAttribute(Attributes.XPToNext, entry and XPCurve.XPToNext(entry.Level) or nil)
end

function ProgressionService:Start()
	PlayerDataService:ForEachLoaded(function(player)
		refreshAttributes(player)
	end)
end

function ProgressionService:SetActiveClass(player: Player, classId: string?)
	if classId and not ClassRegistry.Get(classId) then
		warn(`[ProgressionService] Unknown class '{classId}'`)
		classId = nil
	end
	if classId then
		getClassEntry(player, classId)
	end
	player:SetAttribute(Attributes.ActiveClass, classId)
	refreshAttributes(player)
end

function ProgressionService:GetActiveClass(player: Player): string?
	return player:GetAttribute(Attributes.ActiveClass)
end

function ProgressionService:GetLevel(player: Player, classId: string?): number
	local id = classId or self:GetActiveClass(player)
	local entry = id and getClassEntry(player, id)
	return entry and entry.Level or 1
end

function ProgressionService:GetDamageMultiplier(player: Player, classId: string?): number
	return 1 + (self:GetLevel(player, classId) - 1) * ClassConfig.DamageBonusPerLevel
end

function ProgressionService:AddClassXP(player: Player, classId: string, amount: number, source: string?)
	local entry = getClassEntry(player, classId)
	if not entry or amount <= 0 then
		return
	end

	local newLevel, newXP, gained = XPCurve.Apply(entry.Level, entry.XP, amount)
	entry.Level = newLevel
	entry.XP = newXP
	refreshAttributes(player)

	self.XPGained:Fire(player, classId, amount, source)
	if gained > 0 then
		self.LevelUp:Fire(player, classId, newLevel)
		LevelUpRemote:FireClient(player, classId, newLevel)
	end
end

function ProgressionService:AddXP(player: Player, amount: number, source: string?)
	local classId = self:GetActiveClass(player)
	if classId then
		self:AddClassXP(player, classId, amount, source)
	end
end

return ProgressionService
