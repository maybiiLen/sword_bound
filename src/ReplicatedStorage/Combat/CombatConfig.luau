--!strict
--[[
	CombatConfig
	Global combat tuning shared by client and server. Per-weapon numbers (damage, stamina costs,
	poise damage, which animations) live in the weapon's definition under Combat.Weapons, and
	animation timing lives in Combat.Animations.Specs, not here.

	Used by: every combat module. See Docs.Combat > "Tuning".
]]

local CombatConfig = {
	DefaultWeapon = "StarterSword", -- given to players whose save has no weapon

	-- Input (ContextActionService bindings)
	AttackInputs = { Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonR2 } :: { any },
	BlockInputs = { Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL1 } :: { any },
	RollInputs = { Enum.KeyCode.Q, Enum.KeyCode.ButtonB } :: { any },
	LockOnInputs = { Enum.UserInputType.MouseButton3, Enum.KeyCode.F, Enum.KeyCode.ButtonR3 } :: { any }, -- not Tab: Roblox uses it for the player list
	ToggleWeaponInputs = { Enum.KeyCode.E, Enum.KeyCode.ButtonY } :: { any },
	FreeCursorKeys = { Enum.KeyCode.LeftAlt } :: { any }, -- hold to unlock the mouse while in combat camera
	HeavyHoldThreshold = 0.2, -- holding attack longer than this starts a heavy charge instead of a light
	HeavyFullCharge = 1.0, -- seconds of charging for the full-charge bonus
	InputBufferTime = 0.35, -- presses this long before an action can cancel are queued

	-- Stamina (the pool itself is SprintConfig.MaxStamina / RegenRate; costs of attacks are per attack)
	RollStaminaCost = 18,
	BackstepStaminaCost = 10,
	BlockRegenMultiplier = 0.35, -- stamina regenerates slower while holding block

	-- Movement
	RollSpeed = 30, -- studs/s at the start of a roll, eases out over the roll
	BackstepSpeed = 22,
	LungeSpeed = 12, -- forward push on an attack's "Lunge" marker (x attack.Lunge)
	LungeTime = 0.12,
	MoveSpeedMultipliers = { -- x WalkSpeed while in each CombatState
		Idle = 1,
		Attacking = 0.15,
		Charging = 0.3,
		Blocking = 0.55,
		Rolling = 0,
		Staggered = 0,
	} :: { [string]: number },

	-- Defense
	ParryWindow = 0.2, -- a hit landing within this long of starting a block is parried
	BlockAngle = 120, -- degrees in front of you a block covers
	BlockDamageMultiplier = 0.1, -- damage that gets through a block
	BlockStaminaPerDamage = 1.6, -- stamina lost per point of blocked damage (x (1 - weapon BlockStability))
	GuardBreakTime = 1.0,
	ParryStaggerTime = 1.6, -- how long an attacker is staggered after being parried (riposte window)

	-- Poise / stagger
	PlayerMaxPoise = 40,
	PoiseRegenDelay = 3, -- seconds without taking poise damage before poise refills
	StaggerTime = 1.1,
	FlinchTime = 0.35,
	CritMultiplier = 1.5, -- damage x this against a staggered target

	-- Lock-on
	LockOnRange = 60,
	LockOnBreakRange = 75,
	LockOnSwitchPixels = 110, -- mouse flick distance that switches lock-on target

	-- Camera (combat camera, active while the weapon is drawn)
	Camera = {
		Distance = 11,
		MinDistance = 6,
		MaxDistance = 18,
		ShoulderOffset = Vector3.new(1.8, 0.4, 0),
		FocusHeight = 1.6,
		MouseSensitivity = 0.0035, -- radians per pixel
		GamepadSensitivity = 3.2, -- radians per second at full stick
		MinPitch = -70,
		MaxPitch = 55,
		LockOnPitch = -12,
	},

	-- Feedback per attack Weight
	HitStop = { Light = 0.06, Heavy = 0.11 } :: { [string]: number },
	Shake = { Light = 0.25, Heavy = 0.6, Block = 0.2, Parry = 0.45, Stagger = 0.5 } :: { [string]: number },

	-- Server validation
	HitWindowAllowance = 0.25, -- seconds of slack either side of a hit window (network jitter)
	ReachTolerance = 4, -- studs added to a weapon's Reach before a hit is rejected
	ActionTimingTolerance = 0.15, -- how early an action may cancel the previous one (latency)
	ToggleCooldown = 0.4, -- seconds between draw/sheath toggles
	PvPEnabled = false, -- false: players can only damage non-player Humanoids (mobs, dummies)
	DebugValidation = true, -- Studio only: print every rejected attack/hit/roll to the output

	-- CollectionService tags
	DummyTag = "TrainingDummy", -- respawning targets (DummyService)
	EnemyTag = "SparringKnight", -- AI sparring enemies (Enemies.SparringKnight)

	-- Rig attachment names the weapon attaches to (R15 name, R6 fallback part)
	HandAttachment = "RightGripAttachment",
	BackAttachment = "BodyBackAttachment",

	-- Names used on instances
	WeaponModelName = "WeaponModel",

	-- Attributes (on the character / NPC model unless noted)
	Attributes = {
		EquippedWeapon = "EquippedWeapon", -- weapon id, set by the server
		WeaponDrawn = "WeaponDrawn", -- true when the weapon is in hand
		CombatState = "CombatState", -- "Idle" | "Attacking" | "Charging" | "Rolling" | "Blocking" | "Staggered"
		SprintBlocked = "SprintBlocked", -- owned by the Sprint system; combat sets it during actions
		MoveSpeedMultiplier = "MoveSpeedMultiplier", -- read by the Sprint system when it sets WalkSpeed
		IFrames = "IFrames", -- true while hits pass through (rolls)
		BlockStartedAt = "BlockStartedAt", -- server time the current block started (nil = not blocking)
		Poise = "Poise",
		MaxPoise = "MaxPoise",
		XPReward = "XPReward", -- on any NPC model: XP granted to whoever lands the killing blow
	},
}

return table.freeze(CombatConfig)
