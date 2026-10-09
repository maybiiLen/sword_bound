--[[
	GrowthService  (server only)
	Owns Growth Points: how many a player has earned, how many they have put into each of the 7
	attributes (VIT END MND STR DEX AGI INT), and the rules for spending / resetting them. The
	server is authoritative; the Growth screen only requests.

	Points earned  = GrowthConfig.StartingPoints + sum over every class of (Level - 1) * PointsPerLevel
	Points spent   = sum of data.Growth.Allocated
	Points to use  = earned - spent

	Saved shape (DataTemplate.Growth):  { Allocated = { [attrId] = points } }

	API:
		:GetAllocated(player) -> { [attrId] = points }?   a copy; nil until data is loaded
		:GetAvailable(player) -> number
		:Spend(player, request) -> (ok, message?)           request = { [attrId] = points to add }
		:Reset(player) -> (ok, message?)                    returns every spent point (costs ResetCost Col)
		:Start()

	Replication: Player attributes GrowthPoints and Growth_<AttrId> (names in GrowthConfig).
	Remotes (ReplicatedStorage.Growth.Remotes), both RemoteFunctions returning (ok, message?):
		SpendRemote(request)   request = { [attrId] = integer }  -- validated here
		ResetRemote()

	Nothing in combat reads these yet; use GrowthConfig.ComputeStats with :GetAllocated to wire real
	HP / stamina / damage later. See Docs.Growth.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GrowthConfig = require(ReplicatedStorage.Growth.GrowthConfig)
local PlayerDataService = require(ServerScriptService.PlayerData.PlayerDataService)
local ProgressionService = require(ServerScriptService.Combat.ProgressionService)

local Remotes = ReplicatedStorage.Growth.Remotes
local SpendRemote = Remotes.SpendRemote :: RemoteFunction
local ResetRemote = Remotes.ResetRemote :: RemoteFunction

local PointsAttribute = GrowthConfig.PlayerAttributes.Points
local AttributePrefix = GrowthConfig.PlayerAttributes.Prefix
local MAX_POINTS_PER_ATTRIBUTE = GrowthConfig.MaxAttribute - 1
local REQUEST_COOLDOWN = 0.15

local GrowthService = {}

local lastRequest: { [Player]: number } = {}

-- Make sure the saved table has the expected shape (older or hand-edited saves).
local function allocatedOf(data: any): { [string]: number }
	if type(data.Growth) ~= "table" then
		data.Growth = {}
	end
	if type(data.Growth.Allocated) ~= "table" then
		data.Growth.Allocated = {}
	end
	local allocated = data.Growth.Allocated
	for _, def in GrowthConfig.Attributes do
		local value = allocated[def.Id]
		if type(value) ~= "number" or value ~= value or value < 0 then
			allocated[def.Id] = 0
		else
			allocated[def.Id] = math.min(math.floor(value), MAX_POINTS_PER_ATTRIBUTE)
		end
	end
	return allocated
end

local function spentOf(allocated: { [string]: number }): number
	local total = 0
	for _, def in GrowthConfig.Attributes do
		total += allocated[def.Id]
	end
	return total
end

local function earnedOf(data: any): number
	local total = GrowthConfig.StartingPoints
	if type(data.Classes) == "table" then
		for _, entry in data.Classes do
			if type(entry) == "table" and type(entry.Level) == "number" then
				total += math.max(0, entry.Level - 1) * GrowthConfig.PointsPerLevel
			end
		end
	end
	return total
end

local function availableOf(data: any): number
	return earnedOf(data) - spentOf(allocatedOf(data))
end

local function refreshAttributes(player: Player)
	local data = PlayerDataService:GetData(player)
	if not data then
		return
	end
	local allocated = allocatedOf(data)
	player:SetAttribute(PointsAttribute, math.max(0, availableOf(data)))
	for _, def in GrowthConfig.Attributes do
		player:SetAttribute(AttributePrefix .. def.Id, allocated[def.Id])
	end
end

local function onLoaded(player: Player, data: any)
	local allocated = allocatedOf(data)
	-- Fewer points earned than spent (e.g. StartingPoints was lowered): hand them all back.
	if availableOf(data) < 0 then
		for _, def in GrowthConfig.Attributes do
			allocated[def.Id] = 0
		end
	end
	refreshAttributes(player)
end

function GrowthService:GetAllocated(player: Player): { [string]: number }?
	local data = PlayerDataService:GetData(player)
	if not data then
		return nil
	end
	return table.clone(allocatedOf(data))
end

function GrowthService:GetAvailable(player: Player): number
	local data = PlayerDataService:GetData(player)
	return data and math.max(0, availableOf(data)) or 0
end

function GrowthService:Spend(player: Player, request: any): (boolean, string?)
	if typeof(request) ~= "table" then
		return false, "Invalid request."
	end
	local data = PlayerDataService:GetData(player)
	if not data then
		return false, "Your data is still loading."
	end

	local adds: { [string]: number } = {}
	local total = 0
	for id, amount in request do
		if typeof(id) ~= "string" or not GrowthConfig.Get(id) then
			return false, "Unknown attribute."
		end
		if typeof(amount) ~= "number" or amount ~= math.floor(amount) or amount < 0 or amount > 1000 then
			return false, "Invalid amount."
		end
		if amount > 0 then
			adds[id] = amount
			total += amount
		end
	end
	if total == 0 then
		return false, "Nothing to spend."
	end

	local allocated = allocatedOf(data)
	if total > availableOf(data) then
		return false, "Not enough Growth Points."
	end
	for id, amount in adds do
		if allocated[id] + amount > MAX_POINTS_PER_ATTRIBUTE then
			return false, id .. " is already at its maximum."
		end
	end

	for id, amount in adds do
		allocated[id] += amount
	end
	refreshAttributes(player)
	return true
end

function GrowthService:Reset(player: Player): (boolean, string?)
	local data = PlayerDataService:GetData(player)
	if not data then
		return false, "Your data is still loading."
	end
	if GrowthConfig.ResetCost > 0 then
		return false, "Not enough Col." -- no currency exists yet; wire it here when it does
	end
	local allocated = allocatedOf(data)
	for _, def in GrowthConfig.Attributes do
		allocated[def.Id] = 0
	end
	refreshAttributes(player)
	return true
end

local function rateLimited(player: Player): boolean
	local now = os.clock()
	if now - (lastRequest[player] or 0) < REQUEST_COOLDOWN then
		return true
	end
	lastRequest[player] = now
	return false
end

function GrowthService:Start()
	PlayerDataService:ForEachLoaded(onLoaded)

	-- Levelling up in any class earns points.
	ProgressionService.LevelUp:Connect(function(player: Player)
		refreshAttributes(player)
	end)

	SpendRemote.OnServerInvoke = function(player: Player, request: any)
		if rateLimited(player) then
			return false, "Slow down."
		end
		return self:Spend(player, request)
	end

	ResetRemote.OnServerInvoke = function(player: Player)
		if rateLimited(player) then
			return false, "Slow down."
		end
		return self:Reset(player)
	end

	game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
		lastRequest[player] = nil
	end)
end

return GrowthService

