--[[
	ClassDefaults
	Combat moves every weapon of a class shares, so a new sword gets them without copying data.
	WeaponRegistry merges these into each weapon definition: any field the weapon leaves nil is
	taken from here; a weapon can still override one by setting the field itself.

	Add a class: a table keyed by the class id (same as Classes.Definitions / WeaponBehaviors).
	Fields use the same shapes as Combat.Types (e.g. Riposte: RiposteDefinition).

	Used by: WeaponRegistry. See Docs.Combat > "Riposte" / "Adding a weapon type".
]]

return {
	Sword = {
		Riposte = {
			Animation = "Riposte",
			DamageMultiplier = 2.5, -- x weapon Damage; the staggered target's CritMultiplier applies on top
			Range = 5.5,
			Weight = "Heavy",
			Sound = "Lunge",
		},
	},
}
