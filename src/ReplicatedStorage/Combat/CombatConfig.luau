--!strict
--[[
	CombatConfig
	Global combat tuning shared by client and server. Per-weapon numbers (damage, stamina costs,
	poise damage, which animations) live in the weapon's definition under Combat.Weapons, and
	animation timing lives in Combat.Animations.Specs, not here.

	Used by: every combat module. See Docs.Combat > "Tuning".
]]

local CombatConfig = {
	DefaultWeapon = "TestSword", -- given to players whose save has no weapon

	-- Input (ContextActionService bindings)
	AttackInputs = { Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonR2 } :: { any },
	BlockInputs = { Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL1 } :: { any },
	RollInputs = { Enum.KeyCode.Q, Enum.KeyCode.ButtonB } :: { any },
	LockOnInputs = { Enum.UserInputType.MouseButton3, Enum.KeyCode.F, Enum.KeyCode.ButtonR3 } :: { any }, -- not Tab: Roblox uses it for the player list
	ToggleWeaponInputs = { Enum.KeyCode.E, Enum.KeyCode.ButtonY } :: { any },
	FreeCursorKeys = { Enum.KeyCode.LeftAlt } :: { any }, -- hold to unlock the mouse while in combat camera
	HeavyHoldThreshold = 0.14, -- the light swings on PRESS; still holding at this point turns it into a heavy
	                           -- charge (must stay below every light attack's HitStart, 0.19 since the
	                           -- 2026-10-08 timing pass; a unit test checks it)
	HeavyFullCharge = 1.0, -- seconds of charging for the full-charge bonus
	InputBufferTime = 0.35, -- presses this long before an action can cancel are queued
	WindupCancelTime = 0.15, -- a light attack's first 0.15 s can be cancelled into block or roll (Sekiro style)

	-- Stamina (the pool itself is SprintConfig.MaxStamina / RegenRate; costs of attacks are per attack)
	RollStaminaCost = 18,
	BackstepStaminaCost = 10,
	BlockRegenMultiplier = 0.35, -- stamina regenerates slower while holding block

	-- Movement
	RollSpeed = 30, -- studs/s at the start of a roll, eases out over the roll
	BackstepSpeed = 22,
	LungeSpeed = 20, -- forward step on an attack's "Lunge" marker when there is NO target (x attack.Lunge);
	                 -- ~2 studs at Lunge 1, so a whiff still moves you
	LungeTime = 0.15,
	LungeAssistAngle = 60, -- half-angle in degrees of the cone attacks look for a target in (not locked on)

	-- Attack warp (2026-10-08, "Sword combat feel revision" in the vault). With a target, the Lunge
	-- marker becomes a warp: travel = distance to target - WarpStopDistance, clamped to the attack's
	-- Warp (studs), re-aimed every frame until HitStart, so the swing always lands at blade range.
	-- Modeled on Unreal Motion Warping; distances are starting values for playtesting (unsourced).
	WarpStopDistance = 3.5, -- end this far from the target's root (blade reach is 7, so it lands mid blade)
	DefaultWarp = 3, -- studs, for attacks that don't set Warp
	WarpSideScale = 0.4, -- a target at the edge of the cone gets this fraction of the warp (God of War style)
	WarpMaxSpeed = 75, -- studs/s cap on the warp velocity
	SoftTargetRange = 10, -- not locked on: attacks aim at the best enemy in the cone this close
	LockedWarpRange = 16, -- locked on: the warp works on the lock target this close
	SoftTurnRate = { Windup = 720, Active = 180 }, -- degrees/s the character turns toward the target
	                                              -- (TDM pattern: fast in windup, slow mid swing, none after)
	KnockbackTime = 0.22, -- seconds an attack's Knockback (studs) pushes a non-player target

	-- Hit reactions, pushback and armor tiers (2026-10-09, vault "Hit reactions, pushback and armor
	-- research"). Patterns are sourced (Elden Ring damage levels and poise, GBVSR/Capcom pushback,
	-- God of War small hit translations, Genshin extra hit freeze on unbroken poise); the numbers are
	-- judgment (unsourced). CombatRules.HitReaction picks the reaction and the slide from these.
	HitReaction = {
		BackAngle = 110, -- the attacker is "behind" the victim when more than this many degrees off its facing
		ArmorFlashTime = 0.08, -- white flash on a hit that armor absorbed (no flinch)
		ArmorHitStop = 0.04, -- extra hitstop on an armored hit, so it still feels solid
		TwitchWeight = 0.45, -- weight of the additive ArmorTwitch track over the enemy's attack
	},
	HitPush = { Light = 1.0, Heavy = 2.0 } :: { [string]: number }, -- studs a clean hit slides a non-player
	                                                               -- target (attack.Push / Knockback override)
	HitPushTime = 0.12, -- seconds a normal hit's slide takes (Knockback uses KnockbackTime)
	AttackerStep = { Light = 0.9, Heavy = 0 } :: { [string]: number }, -- studs the attacker steps in when a
	                                                                 -- hit connects (attack.Step overrides), so a
	                                                                 -- string stays glued to a sliding target
	AttackerStepTime = 0.12,
	MinSpacing = 3.0, -- the attacker step never brings you closer than this to the target
	PushChainCap = 10, -- max studs of slide one target takes per PushChainWindow (no infinite carries)
	PushChainWindow = 2,
	-- Armor tiers: model attribute ArmorTier, else "Boss" when the name has [BOSS], else DefaultArmorTier.
	--   ArmorWhileAttacking  hits during the target's own attack only twitch it (hyper armor)
	--   AlwaysArmored        every hit only twitches it (super armor); poise still breaks it
	--   PushScale            slide multiplier on a normal hit; ArmoredPushScale when armor absorbed it
	ArmorTiers = {
		Fodder = { ArmorWhileAttacking = false, AlwaysArmored = false, PushScale = 1, ArmoredPushScale = 1 },
		Elite = { ArmorWhileAttacking = true, AlwaysArmored = false, PushScale = 1, ArmoredPushScale = 0.25 },
		Boss = { ArmorWhileAttacking = true, AlwaysArmored = true, PushScale = 0.25, ArmoredPushScale = 0 },
	} :: { [string]: any },
	DefaultArmorTier = "Fodder",
	WarpReachRecheck = 0.25, -- server: a hit beyond Reach + ReachTolerance (but inside the warp allowance)
	                         -- is checked again this much later, once the attacker's warp has replicated
	MomentumCarryTime = 0.18, -- an attack keeps your current velocity and eases it out over this long
	SprintAttackLungeMultiplier = 1.8, -- Light1 started while sprinting lunges this much further
	                                   -- (only for weapons without a RunningAttack)

	-- Contextual attacks (weapon fields RunningAttack / JumpAttack / RollAttack / GuardCounter)
	RunningAttackMinSpeed = 20, -- horizontal studs/s you must be moving (sprint is 26, walk 16)
	RollAttackWindow = 0.3, -- seconds after a roll/backstep ends that attack still gives the roll attack
	GuardCounterWindow = 0.6, -- seconds after blocking or parrying a hit that attack gives the guard counter
	JumpAttackGrace = 0.25, -- server: a jump attack is valid if the server sees you airborne within this long
	                        -- before or after the request (it sees positions ~0.2 s late)
	MoveSpeedMultipliers = { -- x WalkSpeed while in each CombatState
		Idle = 1,
		Attacking = 0.3, -- was 0.15 (killed all momentum); velocity is also carried in, see MomentumCarryTime
		Charging = 0.3,
		Blocking = 0.55,
		Rolling = 0,
		Staggered = 0,
	} :: { [string]: number },

	-- Defense
	ParryWindow = 0.3, -- a hit landing within this long of starting a block is parried (was 0.2)
	ParrySpamLockout = 0.4, -- raising block again within this long of releasing it is "spamming"...
	ParryWindowSpammed = 0.07, -- ...and only gets this tiny window (Sekiro-style anti-mash)
	MaxParryRewind = 0.15, -- the client's block timestamp may be up to this much earlier than the
	                      -- server receiving it (ping compensation for the parry window)
	BlockAngle = 120, -- degrees in front of you a block covers
	BlockDamageMultiplier = 0.1, -- damage that gets through a block
	BlockStaminaPerDamage = 1.6, -- stamina lost per point of blocked damage (x (1 - weapon BlockStability))
	GuardBreakTime = 1.0,
	ParryRecoilTime = 0.45, -- a parried attacker recoils this long (room for one counter slash)
	ParryPoiseMultiplier = 1.0, -- a parry drains attack.PoiseDamage x this from the ATTACKER's poise;
	                            -- emptying it gives the full StaggerTime stagger instead of a recoil
	PerfectParryWindow = 0.08, -- a parry this early into the block is "perfect": bigger effects + impact frame

	-- Poise / stagger
	PlayerMaxPoise = 40,
	PoiseRegenDelay = 3, -- seconds without taking poise damage before poise refills
	StaggerTime = 1.1,
	FlinchTime = 0.35,
	CritMultiplier = 1.5, -- damage x this against a staggered target (a weapon's CritMultiplier overrides it)
	StaggerImmunityTime = 1.0, -- after a stagger ends, poise can't break into a new full stagger this long
	                           -- (stops chain-staggering a target; PvP uses PvP.StaggerImmunityTime)

	-- Damage types (2026-10-08; see CombatRules). Attacks set DamageType (default: the weapon's, else Slash).
	--   CounterBonus  x damage when the hit lands while the target is Attacking or Charging
	--   GuardStamina  x the stamina a blocked hit costs the blocker
	DamageTypes = {
		Slash = { CounterBonus = 1.1, GuardStamina = 1.0 },
		Strike = { CounterBonus = 1.1, GuardStamina = 1.4 }, -- maces/hammers/axes: break guards
		Pierce = { CounterBonus = 1.3, GuardStamina = 0.9 }, -- thrusts: punish attacks
	} :: { [string]: { CounterBonus: number, GuardStamina: number } },
	ArmorDamageTaken = 0.9, -- x damage taken while an attack's armor window is up (attack.Armor.DamageTaken overrides)

	-- Player vs player only (PvP is off today; this is the hook for balancing it separately)
	PvP = {
		DamageMultiplier = 1.0,
		PoiseMultiplier = 1.0,
		CounterBonusScale = 0.5, -- keeps half of a damage type's counter bonus (ER: pierce +30% PvE, +15% PvP)
		ArmorDamageTaken = 0.9,
		StaggerImmunityTime = 3.0,
	},

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
	HitStop = { Light = 0.06, Heavy = 0.11, Parry = 0.1, PerfectParry = 0.14 } :: { [string]: number },
	Shake = { Light = 0.25, Heavy = 0.6, Block = 0.2, Parry = 0.45, PerfectParry = 0.7, Stagger = 0.5 } :: { [string]: number },
	Punch = { Parry = 0.3, PerfectParry = 0.6 } :: { [string]: number }, -- camera punch (studs) for the parrier

	-- Hitstop per weapon class and attack Weight (2026-10-08). Heavier classes freeze longer; base
	-- values stay at or under 0.18 s and a counter adds CounterHitStop (max 0.22 s), inside the
	-- research range (sweet spot 0.1-0.2 s, discomfort near 0.54 s). Falls back to HitStop[Weight]
	-- for classes not listed. CombatService widens its hit window from these values.
	ClassHitStop = {
		Dagger = { Light = 0.05, Heavy = 0.08 },
		Sword = { Light = 0.07, Heavy = 0.12 },
		Rapier = { Light = 0.06, Heavy = 0.1 },
		Greatsword = { Light = 0.1, Heavy = 0.16 },
		Greataxe = { Light = 0.11, Heavy = 0.18 },
	} :: { [string]: { [string]: number } },
	CounterHitStop = 0.04,

	-- Swing trail look per weapon class (VFX.StyleTrail). Sequences are { time, value } pairs.
	ClassTrails = {
		Dagger = { Lifetime = 0.08, WidthScale = { { 0, 0.7 }, { 1, 0.1 } }, Transparency = { { 0, 0.2 }, { 0.4, 0.55 }, { 1, 1 } }, Color = "#9FD8FF", TipColor = "#FFFFFF" },
		Sword = { Lifetime = 0.12, WidthScale = { { 0, 1 }, { 1, 0.2 } }, Transparency = { { 0, 0.15 }, { 0.3, 0.5 }, { 1, 1 } }, Color = "#8FD3FF", TipColor = "#FFFFFF" },
		Rapier = { Lifetime = 0.06, WidthScale = { { 0, 0.5 }, { 1, 0.1 } }, Transparency = { { 0, 0.15 }, { 0.4, 0.5 }, { 1, 1 } }, Color = "#FFF1B8", TipColor = "#FFFFFF" },
		Greatsword = { Lifetime = 0.22, WidthScale = { { 0, 1 }, { 1, 0.25 } }, Transparency = { { 0, 0.1 }, { 0.3, 0.45 }, { 1, 1 } }, Color = "#FFB27A", TipColor = "#FFF4E6" },
		Greataxe = { Lifetime = 0.16, WidthScale = { { 0, 1 }, { 1, 0.3 } }, Transparency = { { 0, 0.1 }, { 0.3, 0.45 }, { 1, 1 } }, Color = "#FF9A6A", TipColor = "#FFF4E6" },
	},

	-- Combat.VFX tuning (hit sparks by damage type; values from the VFX cookbook in the vault)
	VFX = {
		PoolSize = 6, -- pooled holders kept per effect recipe
		AutomaticQualityScale = 0.7, -- Emit multiplier when graphics quality is Automatic
		HeavyEmitScale = 1.4,
		CounterEmitScale = 1.3,
		CounterFlashTime = 0.1, -- white Highlight on a counter-hit victim
		Palette = {
			Slash = { core = "#F2FAFF", glow = "#7FD4FF" },
			Strike = { core = "#FFF0D6", glow = "#FF9A3C", dust = "#8A7A66" },
			Pierce = { core = "#FFFFE6", glow = "#FFD84A" },
			Block = { core = "#FFF3DA", glow = "#FFC873" },
			Counter = "#FF3B2F",
			CounterCore = "#FFE3E0",
		},
	},

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
	RiposteMarkColor = Color3.fromRGB(255, 45, 45), -- highlight on an enemy you can finish (riposte)

	Attributes = {
		EquippedWeapon = "EquippedWeapon", -- weapon id, set by the server
		WeaponDrawn = "WeaponDrawn", -- true when the weapon is in hand
		CombatState = "CombatState", -- "Idle" | "Attacking" | "Charging" | "Rolling" | "Blocking" | "Staggered"
		StaggerKind = "StaggerKind", -- why a model is staggered: "Stagger" | "GuardBreak" | "ParryRecoil" | "Riposted"
		SprintBlocked = "SprintBlocked", -- owned by the Sprint system; combat sets it during actions
		MoveSpeedMultiplier = "MoveSpeedMultiplier", -- read by the Sprint system when it sets WalkSpeed
		IFrames = "IFrames", -- true while hits pass through (rolls)
		BlockStartedAt = "BlockStartedAt", -- server time the current block started (nil = not blocking)
		BlockParryWindow = "BlockParryWindow", -- parry window of the current block (ParryWindow or ParryWindowSpammed)
		GuardCounterUntil = "GuardCounterUntil", -- server time until which attack gives the guard counter (set on block/parry)
		Poise = "Poise",
		MaxPoise = "MaxPoise",
		XPReward = "XPReward", -- on any NPC model: XP granted to whoever lands the killing blow
	},
}

return table.freeze(CombatConfig)

