--[[
	InventoryService  (server only)
	Owns which weapons each player owns (saved in PlayerData under "Inventory").
	Ownership is the gate for equipping: WeaponService only honours EquipRemote "Equip" for
	weapons the player owns.

	Saved shape (DataTemplate.Inventory):  { Weapons = { [weaponId] = true } }

	API:
		:Owns(player, weaponId) -> boolean
		:GetWeapons(player) -> { weaponId }          sorted, only registered weapons
		:GrantWeapon(player, weaponId) -> boolean   adds it and tells the client; false if unknown
		:Start()

	Remotes (ReplicatedStorage.Inventory.Remotes):
		GetInventory      RemoteFunction  client asks for { Weapons = { weaponId } } (no arguments)
		InventoryChanged  RemoteEvent     server -> client, same snapshot, after a grant

	A player is never locked out of the weapon they have equipped: on load, EquippedWeapon is
	added to the owned set if it is missing (covers saves from before inventory existed).

	Used by: WeaponService, InventoryItemsController (client UI). See Docs.Inventory.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local WeaponRegistry = require(ReplicatedStorage.Combat.WeaponRegistry)
local PlayerDataService = require(ServerScriptService.PlayerData.PlayerDataService)

local Remotes = ReplicatedStorage.Inventory.Remotes
local GetInventory = Remotes.GetInventory :: RemoteFunction
local InventoryChanged = Remotes.InventoryChanged :: RemoteEvent

local InventoryService = {}

-- Make sure the saved table has the expected shape (older or hand-edited saves).
local function weaponsOf(data: any): { [string]: boolean }
	if type(data.Inventory) ~= "table" then
		data.Inventory = { Weapons = {} }
	end
	if type(data.Inventory.Weapons) ~= "table" then
		data.Inventory.Weapons = {}
	end
	return data.Inventory.Weapons
end

function InventoryService:Owns(player: Player, weaponId: string): boolean
	local data = PlayerDataService:GetData(player)
	return data ~= nil and weaponsOf(data)[weaponId] == true
end

function InventoryService:GetWeapons(player: Player): { string }
	local list = {}
	local data = PlayerDataService:GetData(player)
	if data then
		for weaponId, owned in weaponsOf(data) do
			if owned == true and WeaponRegistry.Get(weaponId) then
				table.insert(list, weaponId)
			end
		end
	end
	table.sort(list)
	return list
end

function InventoryService:GrantWeapon(player: Player, weaponId: string): boolean
	if typeof(weaponId) ~= "string" or not WeaponRegistry.Get(weaponId) then
		return false
	end
	local data = PlayerDataService:GetData(player)
	if not data then
		return false
	end
	local weapons = weaponsOf(data)
	if weapons[weaponId] ~= true then
		weapons[weaponId] = true
		InventoryChanged:FireClient(player, { Weapons = self:GetWeapons(player) })
	end
	return true
end

function InventoryService:Start()
	PlayerDataService:ForEachLoaded(function(_player: Player, data: any)
		local weapons = weaponsOf(data)
		local equippedId = data.EquippedWeapon
		if typeof(equippedId) == "string" and WeaponRegistry.Get(equippedId) and weapons[equippedId] ~= true then
			weapons[equippedId] = true
		end
	end)

	GetInventory.OnServerInvoke = function(player: Player)
		if not PlayerDataService:WaitForData(player, 30) then
			return nil
		end
		return { Weapons = self:GetWeapons(player) }
	end
end

return InventoryService
