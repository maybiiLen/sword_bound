--[[
	PlayerDataService  (server only)
	The ONE place player save data is loaded and saved, for every system in the game.
	Wraps ProfileStore (by loleris): session locking, auto-save every few minutes,
	save on leave and on server shutdown.

	Usage from any server script / module:
		local PlayerDataService = require(ServerScriptService.PlayerData.PlayerDataService)

		local data = PlayerDataService:WaitForData(player)   -- yields until loaded (nil if they left)
		if data then data.Gold += 10 end                       -- mutate directly; it auto-saves

		PlayerDataService.Loaded:Connect(function(player, data) ... end)
		PlayerDataService.Releasing:Connect(function(player, data) ... end)  -- last chance to write

	API:
		:GetData(player) -> table?          non-yielding; nil until loaded
		:WaitForData(player, timeout?) -> table?
		:IsLoaded(player) -> boolean
		.Loaded          Signal(player, data)   only future loads; late listeners use ForEachLoaded
		:ForEachLoaded(fn(player, data))    runs fn for already-loaded players now AND future loads
		.Releasing       Signal(player, data)

	Adding a new saved field: add it to DataTemplate (never here).
	Studio: without "Enable Studio Access to API Services" (Game Settings > Security),
	ProfileStore runs in mock mode: everything works but nothing persists after you stop.

	Started by: PlayerDataLoader (Script). See Docs.PlayerData.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.Parent.ProfileStore)
local DataTemplate = require(script.Parent.DataTemplate)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local STORE_NAME = "PlayerData_v1"

local PlayerDataService = {
	Loaded = Signal.new(),
	Releasing = Signal.new(),
}

local store = ProfileStore.New(STORE_NAME, DataTemplate)
local profiles: { [Player]: any } = {}
local started = false

local function profileKey(player: Player): string
	return "Player_" .. player.UserId
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(profileKey(player), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		if player.Parent == Players then
			player:Kick("Your data couldn't be loaded. Please rejoin.")
		end
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick("Your data session ended (you joined on another server). Please rejoin.")
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	player:SetAttribute("DataLoaded", true)
	PlayerDataService.Loaded:Fire(player, profile.Data)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		PlayerDataService.Releasing:Fire(player, profile.Data)
		profile:EndSession()
	end
end

function PlayerDataService:Start()
	if started then
		return
	end
	started = true

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	if RunService:IsStudio() then
		task.delay(5, function()
			if ProfileStore.DataStoreState ~= "Access" then
				warn("[PlayerDataService] DataStore state is '" .. tostring(ProfileStore.DataStoreState)
					.. "': running in MOCK mode, data will not persist. Enable Studio API access in Game Settings > Security to test saving.")
			end
		end)
	end
end

function PlayerDataService:GetData(player: Player): any
	local profile = profiles[player]
	return profile and profile.Data
end

function PlayerDataService:IsLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

function PlayerDataService:WaitForData(player: Player, timeout: number?): any
	local deadline = os.clock() + (timeout or 60)
	while profiles[player] == nil do
		if player.Parent ~= Players or os.clock() > deadline then
			return nil
		end
		task.wait(0.1)
	end
	return profiles[player].Data
end

function PlayerDataService:ForEachLoaded(fn: (Player, any) -> ())
	for player, profile in profiles do
		task.spawn(fn, player, profile.Data)
	end
	return PlayerDataService.Loaded:Connect(fn)
end

return PlayerDataService
