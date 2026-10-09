--[[
	DataTemplate
	Default save data for a brand-new player. ProfileStore reconciles every loaded profile
	against this table, so ADDING a new key here is safe: existing players get the default
	the next time they join.

	Rules (ProfileStore):
		- Only strings, numbers, booleans and tables of those.
		- No Instances, Vector3, Color3, CFrame, functions.
		- Arrays must have no gaps; don't mix array and dictionary keys in one table.

	Team convention: each system owns ONE top-level key and documents it below.
	Don't rename or delete keys without talking to the owner (it wipes players' data).

		Key             Owner      Written by
		Version         shared     (bump if you need a migration)
		EquippedWeapon  combat     WeaponService
		Classes         combat     ProgressionService   { [classId] = { Level, XP } }
		Inventory       inventory  InventoryService     { Weapons = { [weaponId] = true } }  (owned weapons)
		Growth          growth     GrowthService        { Allocated = { [attrId] = points } }  (Growth Points spent)

	See Docs.PlayerData.
]]

return {
	Version = 1,
	EquippedWeapon = "TestSword",
	Classes = {},
	Inventory = {
		-- Weapons the player owns (EquipRemote "Equip" is gated on this). New players start with both.
		Weapons = { TestSword = true, StarterSword = true },
	},
	Growth = {
		-- Growth Points the player has put into each attribute (attribute value = 1 + points).
		Allocated = { VIT = 0, END = 0, MND = 0, STR = 0, DEX = 0, AGI = 0, INT = 0 },
	},
}

