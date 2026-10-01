--[[
	ClassDefaults
	Combat moves every weapon of a class shares, so a new sword gets them without copying data.
	WeaponRegistry merges these into each weapon definition: any field the weapon leaves nil is
	taken from here; a weapon can still override one by setting the field itself.

	Add a class: a table keyed by the class id (same as Classes.Definitions / WeaponBehaviors).
	Fields use the same shapes as Combat.Types (e.g. Riposte: RiposteDefinition, RunningAttack:
	AttackDefinition).

	Contextual attack numbers (2026-10-01) are scaled from a Light1 (1.0x damage, 12 poise). Ratios
	follow Elden Ring's stance damage order (running < jump < guard counter) but are toned down,
	since players call ER's jump attack overtuned. The exact values are judgment calls (unsourced).

	Used by: WeaponRegistry. See Docs.Combat > "Riposte" / "Contextual attacks" / "Adding a weapon type".
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
		RunningAttack = { -- sprint + attack: a long lunging slash that closes distance
			Animation = "RunningAttack",
			DamageMultiplier = 1.3,
			StaminaCost = 16,
			PoiseDamage = 24,
			Weight = "Heavy",
			Lunge = 2.2,
			Sound = "Lunge",
		},
		JumpAttack = { -- attack in the air: overhead plunge that slams down
			Animation = "JumpAttack",
			DamageMultiplier = 1.5,
			StaminaCost = 18,
			PoiseDamage = 30,
			Weight = "Heavy",
			HyperArmor = true,
			Lunge = 1, -- carries you forward into range (assist stops short of the target)
			Plunge = 55,
			Sound = "HeavySwing",
		},
		RollAttack = { -- attack out of a roll: quick rising thrust
			Animation = "RollAttack",
			DamageMultiplier = 1.1,
			StaminaCost = 12,
			PoiseDamage = 14,
			Weight = "Light",
			Lunge = 1.6,
			Sound = "Swing",
		},
		GuardCounter = { -- attack right after blocking/parrying a hit: heavy rising cut out of the guard
			Animation = "GuardCounter",
			DamageMultiplier = 1.6,
			StaminaCost = 16,
			PoiseDamage = 36,
			Weight = "Heavy",
			HyperArmor = true,
			Lunge = 1.2,
			Sound = "HeavySwing",
		},
	},
}
