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

	Class stats (2026-10-08, Phase 0): DamageType is the class's default damage type (an attack can
	override it), CritMultiplier is the bonus vs a staggered target, GuardDamage scales the stamina a
	blocker loses. Sword is the baseline (1.5 / 1.0); other classes are tuned against it.

	Used by: WeaponRegistry. See Docs.Combat > "Riposte" / "Contextual attacks" / "Adding a weapon type"
	/ "Damage types, armor, stun rules".
]]

return {
	Sword = {
		DamageType = "Slash",
		CritMultiplier = 1.5,
		GuardDamage = 1.0,
		Riposte = {
			Animation = "Riposte",
			DamageType = "Pierce",
			DamageMultiplier = 2.5, -- x weapon Damage; the weapon's CritMultiplier applies on top (target is staggered)
			Range = 5.5,
			Warp = 0, -- the riposte has its own lunge and hold
			Weight = "Heavy",
			Sound = "Lunge",
		},
		RunningAttack = { -- sprint + attack: a leaning one-arm thrust that carries the sprint up to 8
			-- studs into the target and stops on contact (2026-10-08: its own move, the only straight-line
			-- attack in the kit; inspired by DMC's Stinger and SAO's Rage Spike, see the vault)
			Animation = "RunningAttack",
			DamageMultiplier = 1.3,
			StaminaCost = 16,
			PoiseDamage = 24,
			Weight = "Heavy",
			DamageType = "Pierce",
			Lunge = 3,
			Warp = 8,
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
			Warp = 2,
			Plunge = 55,
			Sound = "HeavySwing",
		},
		RollAttack = { -- attack out of a roll: low rising slash from the crouch (2026-10-08: was a thrust,
			-- which now belongs to the running attack)
			Animation = "RollAttack",
			DamageMultiplier = 1.1,
			StaminaCost = 12,
			PoiseDamage = 14,
			Weight = "Light",
			Lunge = 1.6,
			Warp = 3,
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
			Warp = 2.5,
			Sound = "HeavySwing",
		},
	},
}

