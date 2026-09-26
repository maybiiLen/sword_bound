--!strict
--[[
	CombatConfig
	Global combat tuning shared by client and server. Per-weapon numbers (damage, reach,
	combo timing) live in the weapon's definition under Combat.Weapons, not here.

	Used by: every combat module. See Docs.Combat > "Tuning".
]]

local CombatConfig = {
	DefaultWeapon = "StarterSword", -- given to players whose save has no weapon

	-- Input (ContextActionService bindings)
	AttackInputs = { Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2 } :: { any },
	ToggleWeaponInputs = { Enum.KeyCode.E, Enum.KeyCode.ButtonY } :: { any },
	InputBufferTime = 0.35, -- an attack pressed this long before the current swing ends is queued

	-- Server validation
	HitWindowAllowance = 0.25, -- seconds of slack either side of a hit window (network jitter)
	ReachTolerance = 4, -- studs added to a weapon's Reach before a hit is rejected
	AttackTimingTolerance = 0.15, -- how early the next attack may start before the previous ends
	ToggleCooldown = 0.4, -- seconds between draw/sheath toggles
	PvPEnabled = false, -- false: players can only damage non-player Humanoids (mobs, dummies)

	-- CollectionService tag for respawning training dummies (see DummyService)
	DummyTag = "TrainingDummy",

	-- Rig attachment names the weapon attaches to (R15 name, R6 fallback part)
	HandAttachment = "RightGripAttachment",
	BackAttachment = "BodyBackAttachment",

	-- Names used on instances
	WeaponModelName = "WeaponModel",

	-- Attributes (on the character unless noted)
	Attributes = {
		EquippedWeapon = "EquippedWeapon", -- weapon id, set by the server
		WeaponDrawn = "WeaponDrawn", -- true when the weapon is in hand
		CombatState = "CombatState", -- "Idle" | "Attacking"
		SprintBlocked = "SprintBlocked", -- owned by the Sprint system; combat sets it while attacking
		XPReward = "XPReward", -- on any NPC model: XP granted to whoever lands the killing blow
	},
}

return table.freeze(CombatConfig)
