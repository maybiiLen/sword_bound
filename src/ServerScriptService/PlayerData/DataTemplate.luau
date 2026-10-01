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

	See Docs.PlayerData.
]]

return {
	Version = 1,
	EquippedWeapon = "TestSword",
	Classes = {},
}
