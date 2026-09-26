--!strict
-- Shared tuning for the sprint system. Read by both SprintServer and SprintClient,
-- so server validation and client prediction always agree.
-- See Docs.Sprint.

local SprintConfig = {
	-- Movement
	WalkSpeed = 16,
	SprintSpeed = 26,

	-- Stamina (units per second). The pool is shared with combat (Combat.StaminaService).
	MaxStamina = 100,
	DrainRate = 18,
	RegenRate = 32,
	RegenDelay = 0.8, -- seconds after the last spend (sprint, attack, roll, block) before regen begins
	MinStaminaToSprint = 25, -- after exhaustion, stamina must recover to this before sprinting again
	MinMoveSpeed = 2, -- horizontal studs/s below which sprinting does not drain stamina

	-- Networking
	StaminaReplicateInterval = 0.1,
	MaxRequestsPerSecond = 15,
	PredictionGrace = 0.5, -- how long the client trusts its own prediction before the server confirms

	-- Animation
	AnimationFadeTime = 0.2,
	AnimationBaseSpeed = 1.0,

	-- Camera
	FovBoost = 8,
	FovTweenTime = 0.3,

	-- Input
	KeyboardKeys = { Enum.KeyCode.LeftShift },
	GamepadKeys = { Enum.KeyCode.ButtonL3 },

	-- Attribute names (on the character) other systems can read or set
	Attributes = {
		Stamina = "Stamina",
		MaxStamina = "MaxStamina",
		Sprinting = "Sprinting",
		Exhausted = "Exhausted",
		Blocked = "SprintBlocked", -- set true from any server script (e.g. while attacking) to prevent sprinting
		SpeedMultiplier = "MoveSpeedMultiplier", -- x WalkSpeed; combat sets it during attacks, blocks and rolls
	},
}

return table.freeze(SprintConfig)
