--[[
	InventoryServer
	Bootstraps the server side of inventory. The only Script in this folder; InventoryService is
	a module. WeaponService requires InventoryService too (it gates equipping on ownership), so
	it does not matter which starts first. PlayerData is started by its own loader.
	See Docs.Inventory.
]]

require(script.Parent:WaitForChild("InventoryService")):Start()
