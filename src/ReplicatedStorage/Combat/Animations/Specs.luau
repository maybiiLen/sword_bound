--[[
	Animations.Specs
	The single source of truth for sword animation timing AND poses. Two consumers:
		- ServerStorage.CombatDev.AnimationBuilder turns these into KeyframeSequences
		  (Combat.Assets.AnimSaves) that animators can open in the Animation Editor / Moon Animator.
		- Gameplay reads marker times from here (AnimationLibrary.MarkerTime), so the server's
		  hit windows always match what the animation shows.

	Spec fields:
		Priority        "Idle" | "Movement" | "Action" | "Action2" | "Action3" | "Action4"
		Loop            boolean
		UpperBodyOnly   true: legs are left to the walk/run animations
		Keyframes       { { T = seconds, Pose = pose, Ease = "Linear" | "In" | "Out" | "InOut" } }
		                Ease describes the motion from this keyframe to the next.
		Markers         { [markerName]: seconds }   HitStart, HitEnd, CancelOpen, Lunge, IFrameStart...
		                Cancel timing (staggered like Elden Ring: attack first, roll next, move last):
		                  CancelOpen  the next attack may start
		                  RollOpen    a roll may start (default: CancelOpen)
		                  MoveOpen    the action is over for gameplay (default: animation end).
		                              The track keeps playing its settle as a cosmetic tail until
		                              the player moves or starts something else.

	Pose fields (all optional; angles in degrees, R15 joint space):
		Root       { Pos = Vector3, Rot = Vector3 }   LowerTorso relative to HumanoidRootPart
		Waist      Vector3                            UpperTorso (-X leans forward, -Y twists right)
		Neck       Vector3                            default: counters the waist so the head stays level
		RightHand  { Pos, Blade, Up?, Pole? }         IK, UpperTorso space (+X right, +Y up, -Z forward):
		                                              grip position, blade direction, hand-up hint, elbow hint
		LeftHand   { Pos, Pole? }                     IK, UpperTorso space
		LeftArm    { Shoulder, Elbow?, Wrist? }       direct angles instead of LeftHand
		Feet       { Right = Vector3, Left = Vector3 } IK ankle targets in HumanoidRootPart space (ground ~ Y -2.88)
		Legs       { RightHip, RightKnee, LeftHip, LeftKnee }  direct angles instead of Feet

	After editing: run AnimationBuilder (see Docs.Combat > "Animation pipeline"), playtest, then
	publish the KeyframeSequences and paste the ids into AnimationLibrary.Published.
]]

local V = Vector3.new

local function with(base: { [string]: any }, overrides: { [string]: any }): { [string]: any }
	local result = table.clone(base)
	for key, value in overrides do
		result[key] = value
	end
	return result
end

local STANCE = {
	Root = { Pos = V(0, -0.3, 0), Rot = V(0, 0, 0) },
	Feet = { Right = V(0.6, -2.88, 0.5), Left = V(-0.5, -2.88, -0.55) },
}

local GUARD_UPPER = {
	Waist = V(-4, 0, 0),
	RightHand = { Pos = V(0.55, -0.75, -0.95), Blade = V(-0.2, 0.6, -0.75) },
	LeftArm = { Shoulder = V(10, 0, -12), Elbow = V(20, 0, 0) },
}

local GUARD = with(GUARD_UPPER, STANCE)

local BLOCK_UPPER = {
	Waist = V(-6, 15, 0),
	RightHand = { Pos = V(0.45, 0.35, -1.0), Blade = V(-1, 0.3, -0.1), Pole = V(1, -1, 0.3) },
	LeftHand = { Pos = V(-0.45, 0.45, -1.05), Pole = V(-1, -1, 0.3) },
}

local CHARGE = {
	Root = { Pos = V(0, -0.55, 0), Rot = V(0, -15, 0) },
	Feet = { Right = V(0.75, -2.88, 0.75), Left = V(-0.6, -2.88, -0.7) },
	Waist = V(8, -35, 0),
	RightHand = { Pos = V(1.1, 1.0, 0.5), Blade = V(0.3, 0.45, 0.85), Pole = V(1, -0.2, 0.5) },
	LeftArm = { Shoulder = V(45, 0, -25), Elbow = V(50, 0, 0) },
}

local CHOP_HIGH = with(STANCE, {
	Root = { Pos = V(0, -0.2, 0.1), Rot = V(0, 0, 0) },
	Waist = V(14, -10, 0),
	RightHand = { Pos = V(0.35, 1.55, 0.15), Blade = V(0.1, 0.35, 1), Pole = V(1, 0.2, 0.3) },
	LeftArm = { Shoulder = V(100, 0, 0), Elbow = V(60, 0, 0) },
})

local CHOP_HOLD = with(CHOP_HIGH, {
	Waist = V(18, -10, 0),
	RightHand = { Pos = V(0.3, 1.65, 0.3), Blade = V(0.1, 0.3, 1), Pole = V(1, 0.2, 0.3) },
})

local CHOP_MID = with(STANCE, {
	Root = { Pos = V(0, -0.45, -0.1), Rot = V(0, 0, 0) },
	Waist = V(-10, -5, 0),
	RightHand = { Pos = V(0.3, 0.3, -1.4), Blade = V(0, 0.8, -0.6) },
	LeftArm = { Shoulder = V(50, 0, -10), Elbow = V(40, 0, 0) },
})

local CHOP_LOW = with(STANCE, {
	Root = { Pos = V(0, -0.7, -0.2), Rot = V(0, 0, 0) },
	Waist = V(-28, 0, 0),
	RightHand = { Pos = V(0.2, -0.85, -1.15), Blade = V(0, -0.55, -0.85) },
	LeftArm = { Shoulder = V(20, 0, -25), Elbow = V(30, 0, 0) },
})

local SLASH_R_WIND = with(STANCE, {
	Root = { Pos = V(0, -0.35, 0), Rot = V(0, -12, 0) },
	Waist = V(0, -40, 0),
	RightHand = { Pos = V(1.35, 0.45, 0.35), Blade = V(0.35, 0.55, 0.75), Pole = V(1, -0.2, 0.6) },
	LeftArm = { Shoulder = V(40, 0, -30), Elbow = V(60, 0, 0) },
})

local SLASH_R_PEAK = with(SLASH_R_WIND, {
	Waist = V(0, -45, 0),
	RightHand = { Pos = V(1.4, 0.55, 0.45), Blade = V(0.35, 0.55, 0.75), Pole = V(1, -0.2, 0.6) },
})

local SLASH_R_MID = with(STANCE, {
	Root = { Pos = V(0, -0.4, 0), Rot = V(0, 0, 0) },
	Waist = V(-8, 0, 0),
	RightHand = { Pos = V(0.5, -0.2, -1.35), Blade = V(0.1, 0.05, -1) },
	LeftArm = { Shoulder = V(20, 0, -35), Elbow = V(40, 0, 0) },
})

local SLASH_R_END = with(STANCE, {
	Root = { Pos = V(0, -0.4, 0), Rot = V(0, 12, 0) },
	Waist = V(-12, 35, 0),
	RightHand = { Pos = V(-0.45, -0.75, -0.95), Blade = V(-0.9, -0.35, -0.35), Pole = V(0.4, -1, 0.2) },
	LeftArm = { Shoulder = V(0, 0, -45), Elbow = V(30, 0, 0) },
})

local SLASH_R_FOLLOW = with(SLASH_R_END, {
	Waist = V(-10, 38, 0),
	RightHand = { Pos = V(-0.55, -0.85, -0.8), Blade = V(-0.8, -0.5, 0.2), Pole = V(0.4, -1, 0.2) },
})

local SLASH_L_WIND = with(STANCE, {
	Root = { Pos = V(0, -0.35, 0), Rot = V(0, 10, 0) },
	Waist = V(0, 40, 0),
	RightHand = { Pos = V(-0.35, -0.7, -0.75), Blade = V(-0.85, -0.3, 0.4), Pole = V(0.3, 0.3, -1) },
	LeftArm = { Shoulder = V(20, 0, -35), Elbow = V(40, 0, 0) },
})

local SLASH_L_PEAK = with(SLASH_L_WIND, {
	Waist = V(0, 45, 0),
	RightHand = { Pos = V(-0.45, -0.75, -0.65), Blade = V(-0.85, -0.3, 0.45), Pole = V(0.3, 0.3, -1) },
})

local SLASH_L_MID = with(STANCE, {
	Root = { Pos = V(0, -0.4, 0), Rot = V(0, 0, 0) },
	Waist = V(-5, 0, 0),
	RightHand = { Pos = V(0.55, -0.35, -1.35), Blade = V(0.15, 0.25, -1) },
	LeftArm = { Shoulder = V(30, 0, -30), Elbow = V(40, 0, 0) },
})

local SLASH_L_END = with(STANCE, {
	Root = { Pos = V(0, -0.35, 0), Rot = V(0, -10, 0) },
	Waist = V(0, -35, 0),
	RightHand = { Pos = V(1.45, 0.25, -0.45), Blade = V(0.85, 0.45, 0.3), Pole = V(1, -0.5, 0.4) },
	LeftArm = { Shoulder = V(40, 0, -20), Elbow = V(50, 0, 0) },
})

local SLASH_L_FOLLOW = with(SLASH_L_END, {
	Waist = V(0, -38, 0),
	RightHand = { Pos = V(1.5, 0.35, -0.25), Blade = V(0.7, 0.6, 0.5), Pole = V(1, -0.5, 0.4) },
})

local TUCK_LEGS = { RightHip = V(100, 0, 0), RightKnee = V(-120, 0, 0), LeftHip = V(100, 0, 0), LeftKnee = V(-120, 0, 0) }
local TUCK_ARMS = {
	RightHand = { Pos = V(0.6, -0.5, -0.7), Blade = V(0, -0.6, 0.8) },
	LeftArm = { Shoulder = V(60, 0, -10), Elbow = V(90, 0, 0) },
}

local function rollPose(rot: number, pos: Vector3, waist: number, legs)
	return with(TUCK_ARMS, { Root = { Pos = pos, Rot = V(rot, 0, 0) }, Waist = V(waist, 0, 0), Legs = legs })
end

-- Feet for the player's light attacks, in HumanoidRootPart space (-Z forward, ground ~ Y -2.88).
-- The lead (left) foot steps in on the Lunge; the rear foot stays planted in the world while
-- the root is pushed forward (so its Z grows), then drags back in during the settle.
local function stepFeet(leftZ: number, rightZ: number, leftLift: number?, rightLift: number?)
	return {
		Left = V(-0.5, -2.88 + (leftLift or 0), leftZ),
		Right = V(0.6, -2.88 + (rightLift or 0), rightZ),
	}
end

local Specs = {}

Specs.GuardIdle = {
	Priority = "Action",
	Loop = true,
	UpperBodyOnly = true,
	Keyframes = {
		{ T = 0, Pose = GUARD_UPPER, Ease = "InOut" },
		{ T = 1, Pose = with(GUARD_UPPER, { Waist = V(-6, 0, 0), RightHand = { Pos = V(0.55, -0.72, -0.95), Blade = V(-0.2, 0.62, -0.75) } }), Ease = "InOut" },
		{ T = 2, Pose = GUARD_UPPER },
	},
	Markers = {},
}

-- Player light combo (reworked 2026-09-30 for weight; Knight* specs keep the old poses).
-- Every swing follows the same recipe:
--   anticipation (weight back, coil) -> hips fire first -> torso -> arm -> blade crosses the
--   front at full speed (Linear) -> Out-eased end -> overshoot -> slow settle back to guard.
-- The lead foot steps in on the Lunge so the feet stay planted while the root is pushed.
-- Light2 and Light3 start from the previous swing's end pose, so a chain flows instead of
-- snapping back to guard between hits.
Specs.Light1 = {
	-- forehand, right to left
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = GUARD, Ease = "Out" },
		{ T = 0.14, Pose = with(STANCE, { -- anticipation: weight back, coil right
			Root = { Pos = V(0, -0.35, 0.12), Rot = V(0, -16, 0) },
			Waist = V(4, -38, 0),
			RightHand = { Pos = V(1.35, 0.45, 0.35), Blade = V(0.35, 0.55, 0.75), Pole = V(1, -0.2, 0.6) },
			LeftArm = { Shoulder = V(40, 0, -30), Elbow = V(60, 0, 0) },
		}), Ease = "Out" },
		{ T = 0.2, Pose = with(STANCE, { -- coil peak, lead foot lifts
			Root = { Pos = V(0, -0.38, 0.14), Rot = V(0, -20, 0) },
			Waist = V(4, -46, 0),
			RightHand = { Pos = V(1.45, 0.6, 0.5), Blade = V(0.35, 0.55, 0.75), Pole = V(1, -0.2, 0.6) },
			LeftArm = { Shoulder = V(45, 0, -30), Elbow = V(60, 0, 0) },
			Feet = stepFeet(-0.85, 0.5, 0.26, 0),
		}), Ease = "In" },
		{ T = 0.24, Pose = with(STANCE, { -- hips fire first, torso and blade still back
			Root = { Pos = V(0, -0.5, -0.05), Rot = V(0, 4, 0) },
			Waist = V(-4, -30, 0),
			RightHand = { Pos = V(1.3, 0.4, 0), Blade = V(0.5, 0.4, 0.75), Pole = V(1, -0.2, 0.5) },
			LeftArm = { Shoulder = V(35, 0, -32), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-1.1, 0.95),
		}), Ease = "Linear" },
		{ T = 0.29, Pose = with(STANCE, { -- contact: blade crosses the front at full speed
			Root = { Pos = V(0, -0.58, -0.1), Rot = V(0, 12, 0) },
			Waist = V(-12, -4, 0),
			RightHand = { Pos = V(0.5, -0.2, -1.35), Blade = V(0.1, 0.05, -1) },
			LeftArm = { Shoulder = V(20, 0, -35), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-0.7, 1.35),
		}), Ease = "Out" },
		{ T = 0.36, Pose = with(STANCE, { -- end of the cut
			Root = { Pos = V(0, -0.55, -0.08), Rot = V(0, 16, 0) },
			Waist = V(-14, 38, 0),
			RightHand = { Pos = V(-0.45, -0.75, -0.95), Blade = V(-0.9, -0.35, -0.35), Pole = V(0.4, -1, 0.2) },
			LeftArm = { Shoulder = V(0, 0, -45), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.6, 1.45),
		}), Ease = "Out" },
		{ T = 0.46, Pose = with(STANCE, { -- overshoot / follow-through
			Root = { Pos = V(0, -0.52, -0.05), Rot = V(0, 18, 0) },
			Waist = V(-12, 44, 0),
			RightHand = { Pos = V(-0.6, -0.88, -0.75), Blade = V(-0.8, -0.5, 0.2), Pole = V(0.4, -1, 0.2) },
			LeftArm = { Shoulder = V(0, 0, -48), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.6, 1.45),
		}), Ease = "InOut" },
		{ T = 0.72, Pose = with(STANCE, { -- recover, rear foot starts to drag in
			Root = { Pos = V(0, -0.42, 0), Rot = V(0, 8, 0) },
			Waist = V(-8, 18, 0),
			RightHand = { Pos = V(0.15, -0.8, -1.0), Blade = V(-0.45, 0.35, -0.8) },
			LeftArm = { Shoulder = V(10, 0, -25), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-0.58, 0.95, 0, 0.16),
		}), Ease = "InOut" },
		{ T = 0.9, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.33, 0), Rot = V(0, 3, 0) },
			Waist = V(-5, 6, 0),
			Feet = stepFeet(-0.56, 0.55),
		}), Ease = "InOut" },
		{ T = 1.15, Pose = GUARD },
	},
	Markers = { Lunge = 0.2, HitStart = 0.26, HitEnd = 0.38, CancelOpen = 0.5, RollOpen = 0.58, MoveOpen = 0.72 },
}

Specs.Light2 = {
	-- backhand, left to right; starts from Light1's follow-through
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.5, -0.05), Rot = V(0, 16, 0) },
			Waist = V(-10, 40, 0),
			RightHand = { Pos = V(-0.5, -0.8, -0.85), Blade = V(-0.85, -0.4, 0.1), Pole = V(0.3, 0.3, -1) },
			LeftArm = { Shoulder = V(10, 0, -40), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.6, 1.3),
		}), Ease = "Out" },
		{ T = 0.12, Pose = with(STANCE, { -- coil left, rear foot drags in
			Root = { Pos = V(0, -0.4, 0.1), Rot = V(0, 14, 0) },
			Waist = V(4, 46, 0),
			RightHand = { Pos = V(-0.45, -0.75, -0.65), Blade = V(-0.85, -0.3, 0.45), Pole = V(0.3, 0.3, -1) },
			LeftArm = { Shoulder = V(20, 0, -35), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-0.6, 0.65, 0, 0.08),
		}), Ease = "Out" },
		{ T = 0.2, Pose = with(STANCE, { -- coil peak, lead foot lifts
			Root = { Pos = V(0, -0.38, 0.12), Rot = V(0, 16, 0) },
			Waist = V(4, 48, 0),
			RightHand = { Pos = V(-0.5, -0.72, -0.6), Blade = V(-0.85, -0.3, 0.45), Pole = V(0.3, 0.3, -1) },
			LeftArm = { Shoulder = V(20, 0, -35), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-0.85, 0.5, 0.26, 0),
		}), Ease = "In" },
		{ T = 0.24, Pose = with(STANCE, { -- hips fire first
			Root = { Pos = V(0, -0.5, -0.05), Rot = V(0, -4, 0) },
			Waist = V(-4, 30, 0),
			RightHand = { Pos = V(-0.25, -0.6, -0.95), Blade = V(-0.75, -0.1, -0.55), Pole = V(0.3, 0.3, -1) },
			LeftArm = { Shoulder = V(25, 0, -32), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-1.1, 0.95),
		}), Ease = "Linear" },
		{ T = 0.29, Pose = with(STANCE, { -- contact
			Root = { Pos = V(0, -0.58, -0.1), Rot = V(0, -12, 0) },
			Waist = V(-10, 2, 0),
			RightHand = { Pos = V(0.55, -0.35, -1.35), Blade = V(0.15, 0.25, -1) },
			LeftArm = { Shoulder = V(30, 0, -30), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-0.7, 1.35),
		}), Ease = "Out" },
		{ T = 0.36, Pose = with(STANCE, { -- end of the cut
			Root = { Pos = V(0, -0.55, -0.08), Rot = V(0, -14, 0) },
			Waist = V(-6, -36, 0),
			RightHand = { Pos = V(1.45, 0.25, -0.45), Blade = V(0.85, 0.45, 0.3), Pole = V(1, -0.5, 0.4) },
			LeftArm = { Shoulder = V(40, 0, -20), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-0.6, 1.45),
		}), Ease = "Out" },
		{ T = 0.46, Pose = with(STANCE, { -- overshoot
			Root = { Pos = V(0, -0.52, -0.05), Rot = V(0, -16, 0) },
			Waist = V(-4, -42, 0),
			RightHand = { Pos = V(1.55, 0.4, -0.2), Blade = V(0.7, 0.6, 0.5), Pole = V(1, -0.5, 0.4) },
			LeftArm = { Shoulder = V(40, 0, -20), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-0.6, 1.45),
		}), Ease = "InOut" },
		{ T = 0.72, Pose = with(STANCE, { -- recover
			Root = { Pos = V(0, -0.42, 0), Rot = V(0, -6, 0) },
			Waist = V(-6, -16, 0),
			RightHand = { Pos = V(1.0, -0.2, -0.8), Blade = V(0.3, 0.7, -0.5), Pole = V(1, -0.5, 0.4) },
			LeftArm = { Shoulder = V(20, 0, -18), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.58, 0.95, 0, 0.16),
		}), Ease = "InOut" },
		{ T = 0.9, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.33, 0), Rot = V(0, -3, 0) },
			Waist = V(-5, -6, 0),
			Feet = stepFeet(-0.56, 0.55),
		}), Ease = "InOut" },
		{ T = 1.15, Pose = GUARD },
	},
	Markers = { Lunge = 0.2, HitStart = 0.26, HitEnd = 0.38, CancelOpen = 0.5, RollOpen = 0.58, MoveOpen = 0.72 },
}

Specs.Light3 = {
	-- overhead finisher; starts from Light2's follow-through (blade high right)
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.5, -0.05), Rot = V(0, -16, 0) },
			Waist = V(-4, -40, 0),
			RightHand = { Pos = V(1.5, 0.35, -0.25), Blade = V(0.7, 0.6, 0.5), Pole = V(1, -0.5, 0.4) },
			LeftArm = { Shoulder = V(40, 0, -20), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-0.6, 1.3),
		}), Ease = "InOut" },
		{ T = 0.16, Pose = with(STANCE, { -- blade rises, rear foot drags in
			Root = { Pos = V(0, -0.3, 0.1), Rot = V(0, -6, 0) },
			Waist = V(10, -15, 0),
			RightHand = { Pos = V(0.8, 1.3, 0.2), Blade = V(0.2, 0.5, 0.85), Pole = V(1, 0.2, 0.3) },
			LeftArm = { Shoulder = V(80, 0, -10), Elbow = V(60, 0, 0) },
			Feet = stepFeet(-0.55, 0.7, 0, 0.08),
		}), Ease = "Out" },
		{ T = 0.28, Pose = with(STANCE, { -- coil high, leaning back, lead foot lifts
			Root = { Pos = V(0, -0.18, 0.15), Rot = V(0, -4, 0) },
			Waist = V(16, -10, 0),
			RightHand = { Pos = V(0.3, 1.7, 0.35), Blade = V(0.1, 0.3, 1), Pole = V(1, 0.2, 0.3) },
			LeftArm = { Shoulder = V(105, 0, 0), Elbow = V(55, 0, 0) },
			Feet = stepFeet(-0.85, 0.5, 0.28, 0),
		}), Ease = "In" },
		{ T = 0.33, Pose = with(STANCE, { -- hips drop and drive, torso still back
			Root = { Pos = V(0, -0.45, -0.1), Rot = V(0, 0, 0) },
			Waist = V(8, -8, 0),
			RightHand = { Pos = V(0.32, 1.5, 0), Blade = V(0.1, 0.55, 0.8), Pole = V(1, 0.2, 0.3) },
			LeftArm = { Shoulder = V(95, 0, 0), Elbow = V(55, 0, 0) },
			Feet = stepFeet(-1.2, 1.0),
		}), Ease = "Linear" },
		{ T = 0.39, Pose = with(STANCE, { -- contact
			Root = { Pos = V(0, -0.72, -0.2), Rot = V(0, 0, 0) },
			Waist = V(-14, -4, 0),
			RightHand = { Pos = V(0.3, 0.3, -1.45), Blade = V(0, 0.75, -0.65) },
			LeftArm = { Shoulder = V(50, 0, -10), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-0.8, 1.5),
		}), Ease = "Out" },
		{ T = 0.46, Pose = with(STANCE, { -- end low
			Root = { Pos = V(0, -0.82, -0.25), Rot = V(0, 0, 0) },
			Waist = V(-30, 0, 0),
			RightHand = { Pos = V(0.2, -0.9, -1.15), Blade = V(0, -0.55, -0.85) },
			LeftArm = { Shoulder = V(20, 0, -25), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.7, 1.7),
		}), Ease = "Out" },
		{ T = 0.6, Pose = with(STANCE, { -- heavy hold in the low pose
			Root = { Pos = V(0, -0.85, -0.25), Rot = V(0, 0, 0) },
			Waist = V(-32, 2, 0),
			RightHand = { Pos = V(0.2, -0.95, -1.1), Blade = V(0, -0.6, -0.8) },
			LeftArm = { Shoulder = V(20, 0, -25), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.7, 1.7),
		}), Ease = "InOut" },
		{ T = 0.95, Pose = with(STANCE, { -- rise, rear foot drags in
			Root = { Pos = V(0, -0.5, -0.1), Rot = V(0, 0, 0) },
			Waist = V(-14, 0, 0),
			RightHand = { Pos = V(0.4, -0.8, -1.05), Blade = V(-0.1, 0.2, -0.95) },
			LeftArm = { Shoulder = V(15, 0, -20), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-0.6, 1.0, 0, 0.16),
		}), Ease = "InOut" },
		{ T = 1.15, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.34, 0), Rot = V(0, 0, 0) },
			Waist = V(-6, 0, 0),
			Feet = stepFeet(-0.56, 0.55),
		}), Ease = "InOut" },
		{ T = 1.4, Pose = GUARD },
	},
	Markers = { Lunge = 0.3, HitStart = 0.34, HitEnd = 0.46, CancelOpen = 0.64, RollOpen = 0.72, MoveOpen = 0.95 },
}

Specs.HeavyCharge = {
	Priority = "Action2",
	Loop = true,
	Keyframes = {
		{ T = 0, Pose = CHARGE, Ease = "InOut" },
		{ T = 0.4, Pose = with(CHARGE, {
			Waist = V(8, -38, 0),
			RightHand = { Pos = V(1.15, 1.05, 0.58), Blade = V(0.3, 0.45, 0.85), Pole = V(1, -0.2, 0.5) },
		}), Ease = "InOut" },
		{ T = 0.8, Pose = CHARGE },
	},
	Markers = {},
}

Specs.HeavyRelease = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = CHARGE, Ease = "Out" },
		{ T = 0.1, Pose = with(CHARGE, {
			Waist = V(10, -42, 0),
			RightHand = { Pos = V(1.2, 1.1, 0.6), Blade = V(0.3, 0.45, 0.85), Pole = V(1, -0.2, 0.5) },
		}), Ease = "In" },
		{ T = 0.18, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.6, -0.3), Rot = V(0, 0, 0) },
			Waist = V(-15, 0, 0),
			RightHand = { Pos = V(0.4, 0.2, -1.45), Blade = V(-0.1, 0.5, -0.85) },
			LeftArm = { Shoulder = V(30, 0, -40), Elbow = V(30, 0, 0) },
		}), Ease = "Linear" },
		{ T = 0.28, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.85, -0.4), Rot = V(0, 15, 0) },
			Feet = { Right = V(0.75, -2.88, 0.75), Left = V(-0.6, -2.88, -0.85) },
			Waist = V(-30, 30, 0),
			RightHand = { Pos = V(-0.25, -0.9, -1.1), Blade = V(-0.5, -0.6, -0.6), Pole = V(0.5, -1, 0.2) },
			LeftArm = { Shoulder = V(10, 0, -60), Elbow = V(20, 0, 0) },
		}), Ease = "Out" },
		{ T = 0.7, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.8, -0.35), Rot = V(0, 12, 0) },
			Feet = { Right = V(0.75, -2.88, 0.75), Left = V(-0.6, -2.88, -0.85) },
			Waist = V(-26, 28, 0),
			RightHand = { Pos = V(-0.2, -0.95, -1.0), Blade = V(-0.45, -0.65, -0.55), Pole = V(0.5, -1, 0.2) },
			LeftArm = { Shoulder = V(10, 0, -50), Elbow = V(25, 0, 0) },
		}), Ease = "InOut" },
		{ T = 1.15, Pose = GUARD },
	},
	Markers = { Lunge = 0.06, HitStart = 0.1, HitEnd = 0.28, CancelOpen = 0.8 },
}

Specs.Roll = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = rollPose(0, V(0, -0.25, 0), -15, { RightHip = V(30, 0, 0), RightKnee = V(-40, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-40, 0, 0) }), Ease = "Linear" },
		{ T = 0.1, Pose = rollPose(-80, V(0, -1.2, 0.5), -35, TUCK_LEGS), Ease = "Linear" },
		{ T = 0.22, Pose = rollPose(-170, V(0, -0.7, 0.2), -40, TUCK_LEGS), Ease = "Linear" },
		{ T = 0.34, Pose = rollPose(-260, V(0, -1.3, -0.4), -35, TUCK_LEGS), Ease = "Linear" },
		{ T = 0.46, Pose = rollPose(-320, V(0, -1.0, -0.2), -20, { RightHip = V(60, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(70, 0, 0), LeftKnee = V(-100, 0, 0) }), Ease = "Out" },
		{ T = 0.62, Pose = with(GUARD, { Root = { Pos = V(0, -0.35, 0), Rot = V(0, 0, 0) }, Waist = V(-10, 0, 0) }) },
	},
	Markers = { IFrameStart = 0.05, IFrameEnd = 0.35, CancelOpen = 0.5 },
}

Specs.Backstep = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = GUARD, Ease = "Out" },
		{ T = 0.08, Pose = with(GUARD, {
			Root = { Pos = V(0, 0.1, 0), Rot = V(-6, 0, 0) },
			Feet = { Right = V(0.6, -2.7, 0.5), Left = V(-0.5, -2.65, -0.3) },
			Waist = V(-10, 0, 0),
		}), Ease = "InOut" },
		{ T = 0.25, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.55, 0), Rot = V(-4, 0, 0) },
			Feet = { Right = V(0.6, -2.88, 0.7), Left = V(-0.5, -2.88, 0.1) },
			Waist = V(-15, 0, 0),
		}), Ease = "InOut" },
		{ T = 0.45, Pose = GUARD },
	},
	Markers = { IFrameStart = 0.02, IFrameEnd = 0.22, CancelOpen = 0.34 },
}

Specs.BlockIdle = {
	Priority = "Action2",
	Loop = true,
	UpperBodyOnly = true,
	Keyframes = {
		{ T = 0, Pose = BLOCK_UPPER, Ease = "InOut" },
		{ T = 0.5, Pose = with(BLOCK_UPPER, {
			RightHand = { Pos = V(0.45, 0.38, -1.0), Blade = V(-1, 0.3, -0.1), Pole = V(1, -1, 0.3) },
			LeftHand = { Pos = V(-0.45, 0.48, -1.05), Pole = V(-1, -1, 0.3) },
		}), Ease = "InOut" },
		{ T = 1, Pose = BLOCK_UPPER },
	},
	Markers = {},
}

Specs.BlockImpact = {
	Priority = "Action4",
	Loop = false,
	UpperBodyOnly = true,
	Keyframes = {
		{ T = 0, Pose = BLOCK_UPPER, Ease = "Out" },
		{ T = 0.06, Pose = with(BLOCK_UPPER, {
			Waist = V(8, 20, 0),
			RightHand = { Pos = V(0.45, 0.45, -0.7), Blade = V(-1, 0.35, -0.1), Pole = V(1, -1, 0.3) },
			LeftHand = { Pos = V(-0.4, 0.55, -0.75), Pole = V(-1, -1, 0.3) },
		}), Ease = "InOut" },
		{ T = 0.35, Pose = BLOCK_UPPER },
	},
	Markers = {},
}

Specs.Parry = {
	Priority = "Action4",
	Loop = false,
	UpperBodyOnly = true,
	Keyframes = {
		{ T = 0, Pose = BLOCK_UPPER, Ease = "Out" },
		{ T = 0.07, Pose = {
			Waist = V(0, -25, 0),
			RightHand = { Pos = V(1.3, 0.7, -0.55), Blade = V(0.6, 0.8, 0.1), Pole = V(1, -0.3, 0.4) },
			LeftArm = { Shoulder = V(30, 0, -50), Elbow = V(20, 0, 0) },
		}, Ease = "Linear" },
		{ T = 0.2, Pose = {
			Waist = V(0, -28, 0),
			RightHand = { Pos = V(1.35, 0.75, -0.5), Blade = V(0.6, 0.8, 0.15), Pole = V(1, -0.3, 0.4) },
			LeftArm = { Shoulder = V(30, 0, -55), Elbow = V(20, 0, 0) },
		}, Ease = "InOut" },
		{ T = 0.5, Pose = GUARD_UPPER },
	},
	Markers = {},
}

Specs.GuardBreak = {
	Priority = "Action4",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(BLOCK_UPPER, STANCE), Ease = "Out" },
		{ T = 0.1, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.2, 0.25), Rot = V(12, 0, 0) },
			Waist = V(22, 0, 0),
			Neck = V(15, 0, 0),
			RightHand = { Pos = V(1.5, 0.9, 0.4), Blade = V(0.4, 0.9, 0.3), Pole = V(1, -0.5, 0.5) },
			LeftArm = { Shoulder = V(80, 0, -80), Elbow = V(10, 0, 0) },
		}), Ease = "InOut" },
		{ T = 0.5, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.7, 0), Rot = V(0, 0, 0) },
			Waist = V(-25, 0, 0),
			Neck = V(-10, 0, 0),
			RightHand = { Pos = V(1.1, -1.0, -0.4), Blade = V(0, -0.5, -0.8) },
			LeftArm = { Shoulder = V(10, 0, -10), Elbow = V(30, 0, 0) },
		}), Ease = "InOut" },
		{ T = 0.9, Pose = GUARD },
	},
	Markers = {},
}

Specs.Stagger = {
	Priority = "Action4",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = GUARD, Ease = "Out" },
		{ T = 0.12, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.2, 0.35), Rot = V(10, 0, 0) },
			Waist = V(25, 10, 0),
			Neck = V(15, 0, 0),
			RightHand = { Pos = V(1.3, -0.3, 0.3), Blade = V(0.3, -0.2, 0.9) },
			LeftArm = { Shoulder = V(40, 0, -60), Elbow = V(20, 0, 0) },
		}), Ease = "InOut" },
		{ T = 0.45, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.8, 0), Rot = V(0, 0, 0) },
			Waist = V(-30, -5, 0),
			Neck = V(-10, 0, 0),
			RightHand = { Pos = V(1.0, -1.1, -0.5), Blade = V(0.1, -0.6, -0.8) },
			LeftArm = { Shoulder = V(10, 0, -10), Elbow = V(30, 0, 0) },
		}), Ease = "Linear" },
		{ T = 0.8, Pose = with(STANCE, {
			Root = { Pos = V(0, -0.65, 0), Rot = V(0, 0, 0) },
			Waist = V(-22, -5, 0),
			Neck = V(-5, 0, 0),
			RightHand = { Pos = V(1.0, -1.0, -0.6), Blade = V(0.1, -0.4, -0.9) },
			LeftArm = { Shoulder = V(10, 0, -12), Elbow = V(30, 0, 0) },
		}), Ease = "InOut" },
		{ T = 1.1, Pose = GUARD },
	},
	Markers = {},
}

Specs.Flinch = {
	Priority = "Action4",
	Loop = false,
	UpperBodyOnly = true,
	Keyframes = {
		{ T = 0, Pose = GUARD_UPPER, Ease = "Out" },
		{ T = 0.07, Pose = with(GUARD_UPPER, {
			Waist = V(14, 8, 0),
			Neck = V(10, 0, 0),
			RightHand = { Pos = V(0.7, -0.6, -0.7), Blade = V(-0.1, 0.7, -0.6) },
		}), Ease = "InOut" },
		{ T = 0.35, Pose = GUARD_UPPER },
	},
	Markers = {},
}

-- Enemy-only: the same slash with a longer, readable wind-up.
Specs.KnightSlash = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = GUARD, Ease = "Out" },
		{ T = 0.45, Pose = SLASH_R_WIND, Ease = "Linear" },
		{ T = 0.6, Pose = SLASH_R_PEAK, Ease = "In" },
		{ T = 0.67, Pose = SLASH_R_MID, Ease = "Linear" },
		{ T = 0.74, Pose = SLASH_R_END, Ease = "Out" },
		{ T = 0.95, Pose = SLASH_R_FOLLOW, Ease = "InOut" },
		{ T = 1.3, Pose = GUARD },
	},
	Markers = { HitStart = 0.6, HitEnd = 0.74 },
}

-- Enemy-only: raises the sword, HOLDS it (the delay that punishes panic rolls), then chops.
Specs.KnightDelayedChop = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = GUARD, Ease = "Out" },
		{ T = 0.35, Pose = CHOP_HIGH, Ease = "InOut" },
		{ T = 0.95, Pose = CHOP_HOLD, Ease = "In" },
		{ T = 1.02, Pose = CHOP_MID, Ease = "Linear" },
		{ T = 1.08, Pose = CHOP_LOW, Ease = "Out" },
		{ T = 1.3, Pose = with(CHOP_LOW, { Waist = V(-25, 0, 0) }), Ease = "InOut" },
		{ T = 1.6, Pose = GUARD },
	},
	Markers = { HitStart = 0.95, HitEnd = 1.1 },
}

-- Riposte: finisher on a posture-broken enemy. Step in, run the blade through, hold it there for a
-- beat, rip it out to the right, settle. Damage is applied by the server at HitStart (guaranteed),
-- the attacker has i-frames for the whole action. RipOut is a cosmetic marker (second burst).
Specs.Riposte = {
	Priority = "Action4",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = GUARD, Ease = "Out" },
		{ T = 0.12, Pose = with(STANCE, { -- draw back: blade level, hand at the hip
			Root = { Pos = V(0, -0.4, 0.12), Rot = V(0, -20, 0) },
			Waist = V(6, -35, 0),
			RightHand = { Pos = V(0.9, -0.3, 0.5), Blade = V(0.05, 0.1, -1), Pole = V(1, -0.5, 0.3) },
			LeftArm = { Shoulder = V(50, 0, -20), Elbow = V(70, 0, 0) },
		}), Ease = "In" },
		{ T = 0.2, Pose = with(STANCE, { -- lead foot lifts
			Root = { Pos = V(0, -0.42, 0.14), Rot = V(0, -22, 0) },
			Waist = V(6, -38, 0),
			RightHand = { Pos = V(0.95, -0.3, 0.6), Blade = V(0.05, 0.1, -1), Pole = V(1, -0.5, 0.3) },
			LeftArm = { Shoulder = V(55, 0, -20), Elbow = V(70, 0, 0) },
			Feet = stepFeet(-0.85, 0.5, 0.25, 0),
		}), Ease = "In" },
		{ T = 0.3, Pose = with(STANCE, { -- thrust home
			Root = { Pos = V(0, -0.6, -0.15), Rot = V(0, 10, 0) },
			Waist = V(-14, 5, 0),
			RightHand = { Pos = V(0.35, 0, -1.75), Blade = V(0, 0.05, -1), Pole = V(1, -0.3, 0.2) },
			LeftArm = { Shoulder = V(30, 0, -40), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.15, 1.0),
		}), Ease = "Out" },
		{ T = 0.55, Pose = with(STANCE, { -- hold it there
			Root = { Pos = V(0, -0.62, -0.15), Rot = V(0, 12, 0) },
			Waist = V(-16, 8, 0),
			RightHand = { Pos = V(0.35, -0.05, -1.7), Blade = V(0, 0, -1), Pole = V(1, -0.3, 0.2) },
			LeftArm = { Shoulder = V(30, 0, -40), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.1, 1.05),
		}), Ease = "In" },
		{ T = 0.68, Pose = with(STANCE, { -- rip it out to the right
			Root = { Pos = V(0, -0.5, -0.05), Rot = V(0, -10, 0) },
			Waist = V(-8, -35, 0),
			RightHand = { Pos = V(1.3, 0.3, -0.6), Blade = V(0.8, 0.5, -0.3), Pole = V(1, -0.5, 0.4) },
			LeftArm = { Shoulder = V(40, 0, -20), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-1.0, 1.05),
		}), Ease = "Out" },
		{ T = 0.95, Pose = with(STANCE, { -- recover, rear foot drags in
			Root = { Pos = V(0, -0.4, 0), Rot = V(0, -4, 0) },
			Waist = V(-4, -15, 0),
			RightHand = { Pos = V(1.0, -0.3, -0.7), Blade = V(0.4, 0.6, -0.6), Pole = V(1, -0.5, 0.4) },
			LeftArm = { Shoulder = V(20, 0, -20), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.6, 0.9, 0, 0.16),
		}), Ease = "InOut" },
		{ T = 1.3, Pose = GUARD },
	},
	Markers = { Lunge = 0.18, HitStart = 0.3, HitEnd = 0.36, RipOut = 0.68, CancelOpen = 1.0, RollOpen = 1.0, MoveOpen = 1.05 },
}

-- Contextual attacks (2026-10-01). Same recipe as the light combo: coil, hips fire, blade crosses
-- on a Linear key, Out-eased end, overshoot, slow settle. Timings are judgment calls (unsourced).

-- RunningAttack: sprint into a deep, leaning forehand slash with a long step (lunge 2.2).
Specs.RunningAttack = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(STANCE, { -- running lean, coiled right
			Root = { Pos = V(0, -0.4, 0), Rot = V(0, -20, 0) },
			Waist = V(-10, -40, 0),
			RightHand = { Pos = V(1.35, 0.35, 0.5), Blade = V(0.4, 0.5, 0.75), Pole = V(1, -0.2, 0.6) },
			LeftArm = { Shoulder = V(50, 0, -30), Elbow = V(60, 0, 0) },
			Feet = stepFeet(-0.6, 0.6),
		}), Ease = "Out" },
		{ T = 0.1, Pose = with(STANCE, { -- coil peak, lead foot lifts
			Root = { Pos = V(0, -0.45, 0.1), Rot = V(0, -24, 0) },
			Waist = V(-8, -48, 0),
			RightHand = { Pos = V(1.45, 0.5, 0.55), Blade = V(0.4, 0.5, 0.75), Pole = V(1, -0.2, 0.6) },
			LeftArm = { Shoulder = V(55, 0, -30), Elbow = V(60, 0, 0) },
			Feet = stepFeet(-1.0, 0.6, 0.3, 0),
		}), Ease = "In" },
		{ T = 0.16, Pose = with(STANCE, { -- hips fire, long step
			Root = { Pos = V(0, -0.7, -0.1), Rot = V(0, 4, 0) },
			Waist = V(-14, -30, 0),
			RightHand = { Pos = V(1.3, 0.35, 0), Blade = V(0.5, 0.35, 0.75), Pole = V(1, -0.2, 0.5) },
			LeftArm = { Shoulder = V(35, 0, -32), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-1.5, 1.2),
		}), Ease = "Linear" },
		{ T = 0.22, Pose = with(STANCE, { -- contact, low and leaning in
			Root = { Pos = V(0, -0.85, -0.2), Rot = V(0, 14, 0) },
			Waist = V(-22, -2, 0),
			RightHand = { Pos = V(0.5, -0.25, -1.45), Blade = V(0.1, 0, -1) },
			LeftArm = { Shoulder = V(15, 0, -40), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-1.2, 1.7),
		}), Ease = "Out" },
		{ T = 0.3, Pose = with(STANCE, { -- end of the cut
			Root = { Pos = V(0, -0.85, -0.2), Rot = V(0, 20, 0) },
			Waist = V(-22, 42, 0),
			RightHand = { Pos = V(-0.5, -0.8, -0.9), Blade = V(-0.9, -0.4, -0.3), Pole = V(0.4, -1, 0.2) },
			LeftArm = { Shoulder = V(0, 0, -50), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.1, 1.8),
		}), Ease = "Out" },
		{ T = 0.45, Pose = with(STANCE, { -- follow-through skid
			Root = { Pos = V(0, -0.8, -0.15), Rot = V(0, 22, 0) },
			Waist = V(-18, 48, 0),
			RightHand = { Pos = V(-0.65, -0.9, -0.7), Blade = V(-0.8, -0.5, 0.2), Pole = V(0.4, -1, 0.2) },
			LeftArm = { Shoulder = V(0, 0, -52), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.1, 1.8),
		}), Ease = "InOut" },
		{ T = 0.8, Pose = with(STANCE, { -- recover, rear foot drags in
			Root = { Pos = V(0, -0.45, 0), Rot = V(0, 8, 0) },
			Waist = V(-8, 18, 0),
			RightHand = { Pos = V(0.15, -0.8, -1.0), Blade = V(-0.45, 0.35, -0.8) },
			LeftArm = { Shoulder = V(10, 0, -25), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-0.6, 1.0, 0, 0.16),
		}), Ease = "InOut" },
		{ T = 1.0, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.33, 0), Rot = V(0, 3, 0) },
			Waist = V(-5, 6, 0),
			Feet = stepFeet(-0.56, 0.55),
		}), Ease = "InOut" },
		{ T = 1.25, Pose = GUARD },
	},
	Markers = { Lunge = 0.08, HitStart = 0.18, HitEnd = 0.32, CancelOpen = 0.62, RollOpen = 0.68, MoveOpen = 0.85 },
}

-- JumpAttack: blade high in the air, legs tucked, chop down as the Plunge (on the Lunge marker)
-- slams you to the ground, land in a deep crouch.
local AIR_LEGS = { RightHip = V(50, 0, 0), RightKnee = V(-80, 0, 0), LeftHip = V(70, 0, 0), LeftKnee = V(-60, 0, 0) }
local LANDING_FEET = { Right = V(0.7, -2.88, 0.8), Left = V(-0.55, -2.88, -0.9) }

Specs.JumpAttack = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = { -- blade raised, leaning back
			Root = { Pos = V(0, 0, 0), Rot = V(0, 0, 0) },
			Waist = V(16, -10, 0),
			RightHand = { Pos = V(0.3, 1.7, 0.35), Blade = V(0.1, 0.3, 1), Pole = V(1, 0.2, 0.3) },
			LeftArm = { Shoulder = V(105, 0, 0), Elbow = V(55, 0, 0) },
			Legs = AIR_LEGS,
		}, Ease = "Out" },
		{ T = 0.16, Pose = { -- peak
			Root = { Pos = V(0, 0, 0.05), Rot = V(0, 0, 0) },
			Waist = V(20, -8, 0),
			RightHand = { Pos = V(0.3, 1.8, 0.45), Blade = V(0.05, 0.2, 1), Pole = V(1, 0.2, 0.3) },
			LeftArm = { Shoulder = V(110, 0, 0), Elbow = V(50, 0, 0) },
			Legs = AIR_LEGS,
		}, Ease = "In" },
		{ T = 0.24, Pose = { -- chop drives down
			Root = { Pos = V(0, -0.2, -0.1), Rot = V(0, 0, 0) },
			Waist = V(0, -6, 0),
			RightHand = { Pos = V(0.32, 1.2, -0.6), Blade = V(0.05, 0.85, -0.5), Pole = V(1, 0.2, 0.3) },
			LeftArm = { Shoulder = V(80, 0, 0), Elbow = V(50, 0, 0) },
			Legs = { RightHip = V(30, 0, 0), RightKnee = V(-50, 0, 0), LeftHip = V(40, 0, 0), LeftKnee = V(-40, 0, 0) },
		}, Ease = "Linear" },
		{ T = 0.3, Pose = { -- impact, landing crouch
			Root = { Pos = V(0, -1.1, -0.25), Rot = V(0, 0, 0) },
			Waist = V(-32, 0, 0),
			RightHand = { Pos = V(0.25, -0.6, -1.4), Blade = V(0, -0.45, -0.9) },
			LeftArm = { Shoulder = V(25, 0, -25), Elbow = V(30, 0, 0) },
			Feet = LANDING_FEET,
		}, Ease = "Out" },
		{ T = 0.5, Pose = { -- hold the crouch
			Root = { Pos = V(0, -1.15, -0.25), Rot = V(0, 0, 0) },
			Waist = V(-34, 2, 0),
			RightHand = { Pos = V(0.25, -0.75, -1.35), Blade = V(0, -0.6, -0.8) },
			LeftArm = { Shoulder = V(25, 0, -25), Elbow = V(30, 0, 0) },
			Feet = LANDING_FEET,
		}, Ease = "InOut" },
		{ T = 0.95, Pose = with(STANCE, { -- rise, rear foot drags in
			Root = { Pos = V(0, -0.55, -0.1), Rot = V(0, 0, 0) },
			Waist = V(-14, 0, 0),
			RightHand = { Pos = V(0.4, -0.8, -1.05), Blade = V(-0.1, 0.2, -0.95) },
			LeftArm = { Shoulder = V(15, 0, -20), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-0.7, 0.8, 0, 0.12),
		}), Ease = "InOut" },
		{ T = 1.15, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.34, 0), Rot = V(0, 0, 0) },
			Waist = V(-6, 0, 0),
			Feet = stepFeet(-0.56, 0.55),
		}), Ease = "InOut" },
		{ T = 1.35, Pose = GUARD },
	},
	Markers = { Lunge = 0.18, HitStart = 0.24, HitEnd = 0.4, CancelOpen = 0.78, RollOpen = 0.82, MoveOpen = 0.98 },
}

-- RollAttack: out of the roll's crouch, a quick rising thrust (fast HitStart, small commitment).
Specs.RollAttack = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(STANCE, { -- crouched, blade low at the hip pointing forward
			Root = { Pos = V(0, -0.9, 0.1), Rot = V(0, -10, 0) },
			Waist = V(-20, -15, 0),
			RightHand = { Pos = V(0.8, -0.6, 0.2), Blade = V(0.05, 0.15, -1), Pole = V(1, -0.5, 0.3) },
			LeftArm = { Shoulder = V(40, 0, -20), Elbow = V(60, 0, 0) },
			Feet = stepFeet(-0.7, 0.8),
		}), Ease = "Out" },
		{ T = 0.08, Pose = with(STANCE, { -- draw back, lead foot lifts
			Root = { Pos = V(0, -0.85, 0.15), Rot = V(0, -18, 0) },
			Waist = V(-12, -30, 0),
			RightHand = { Pos = V(0.95, -0.4, 0.55), Blade = V(0.05, 0.15, -1), Pole = V(1, -0.5, 0.3) },
			LeftArm = { Shoulder = V(50, 0, -20), Elbow = V(70, 0, 0) },
			Feet = stepFeet(-0.95, 0.7, 0.2, 0),
		}), Ease = "In" },
		{ T = 0.16, Pose = with(STANCE, { -- thrust, rising out of the crouch
			Root = { Pos = V(0, -0.6, -0.2), Rot = V(0, 10, 0) },
			Waist = V(-16, 6, 0),
			RightHand = { Pos = V(0.35, 0.05, -1.8), Blade = V(0, 0.12, -1), Pole = V(1, -0.3, 0.2) },
			LeftArm = { Shoulder = V(30, 0, -45), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.3, 1.1),
		}), Ease = "Out" },
		{ T = 0.3, Pose = with(STANCE, { -- extended
			Root = { Pos = V(0, -0.62, -0.22), Rot = V(0, 12, 0) },
			Waist = V(-18, 8, 0),
			RightHand = { Pos = V(0.35, 0.1, -1.75), Blade = V(0, 0.15, -1), Pole = V(1, -0.3, 0.2) },
			LeftArm = { Shoulder = V(30, 0, -45), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.25, 1.15),
		}), Ease = "InOut" },
		{ T = 0.6, Pose = with(STANCE, { -- recover, rear foot drags in
			Root = { Pos = V(0, -0.42, 0), Rot = V(0, 4, 0) },
			Waist = V(-6, 8, 0),
			RightHand = { Pos = V(0.4, -0.6, -1.1), Blade = V(-0.3, 0.45, -0.8) },
			LeftArm = { Shoulder = V(15, 0, -25), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-0.6, 0.9, 0, 0.14),
		}), Ease = "InOut" },
		{ T = 0.8, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.33, 0), Rot = V(0, 2, 0) },
			Waist = V(-5, 3, 0),
			Feet = stepFeet(-0.56, 0.55),
		}), Ease = "InOut" },
		{ T = 1.0, Pose = GUARD },
	},
	Markers = { Lunge = 0.06, HitStart = 0.13, HitEnd = 0.24, CancelOpen = 0.42, RollOpen = 0.48, MoveOpen = 0.62 },
}

-- GuardCounter: out of the block, drop the blade low left and cut up across to high right.
Specs.GuardCounter = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(BLOCK_UPPER, STANCE), Ease = "Out" },
		{ T = 0.07, Pose = with(STANCE, { -- coil low left, lead foot lifts
			Root = { Pos = V(0, -0.55, 0.05), Rot = V(0, 14, 0) },
			Waist = V(-6, 40, 0),
			RightHand = { Pos = V(-0.45, -0.8, -0.6), Blade = V(-0.8, -0.45, 0.4), Pole = V(0.3, 0.3, -1) },
			LeftArm = { Shoulder = V(20, 0, -35), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-0.85, 0.55, 0.25, 0),
		}), Ease = "In" },
		{ T = 0.14, Pose = with(STANCE, { -- hips fire
			Root = { Pos = V(0, -0.6, -0.05), Rot = V(0, -2, 0) },
			Waist = V(-8, 22, 0),
			RightHand = { Pos = V(-0.1, -0.7, -1.05), Blade = V(-0.6, -0.2, -0.75), Pole = V(0.3, 0.3, -1) },
			LeftArm = { Shoulder = V(25, 0, -32), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-1.2, 0.95),
		}), Ease = "Linear" },
		{ T = 0.2, Pose = with(STANCE, { -- contact, rising across the front
			Root = { Pos = V(0, -0.55, -0.1), Rot = V(0, -12, 0) },
			Waist = V(-4, -6, 0),
			RightHand = { Pos = V(0.6, 0, -1.4), Blade = V(0.35, 0.55, -0.75) },
			LeftArm = { Shoulder = V(30, 0, -30), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-0.9, 1.35),
		}), Ease = "Out" },
		{ T = 0.3, Pose = with(STANCE, { -- end high right
			Root = { Pos = V(0, -0.4, -0.05), Rot = V(0, -16, 0) },
			Waist = V(10, -38, 0),
			RightHand = { Pos = V(1.4, 1.1, -0.35), Blade = V(0.55, 0.8, 0.2), Pole = V(1, -0.4, 0.4) },
			LeftArm = { Shoulder = V(45, 0, -25), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-0.8, 1.45),
		}), Ease = "Out" },
		{ T = 0.45, Pose = with(STANCE, { -- overshoot
			Root = { Pos = V(0, -0.4, -0.05), Rot = V(0, -16, 0) },
			Waist = V(12, -42, 0),
			RightHand = { Pos = V(1.5, 1.25, -0.2), Blade = V(0.5, 0.75, 0.45), Pole = V(1, -0.4, 0.4) },
			LeftArm = { Shoulder = V(45, 0, -25), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-0.8, 1.45),
		}), Ease = "InOut" },
		{ T = 0.8, Pose = with(STANCE, { -- recover, rear foot drags in
			Root = { Pos = V(0, -0.42, 0), Rot = V(0, -6, 0) },
			Waist = V(-4, -15, 0),
			RightHand = { Pos = V(1.0, -0.2, -0.8), Blade = V(0.3, 0.7, -0.5), Pole = V(1, -0.5, 0.4) },
			LeftArm = { Shoulder = V(20, 0, -18), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-0.6, 0.95, 0, 0.16),
		}), Ease = "InOut" },
		{ T = 1.0, Pose = with(GUARD, {
			Root = { Pos = V(0, -0.33, 0), Rot = V(0, -3, 0) },
			Waist = V(-5, -6, 0),
			Feet = stepFeet(-0.56, 0.55),
		}), Ease = "InOut" },
		{ T = 1.2, Pose = GUARD },
	},
	Markers = { Lunge = 0.06, HitStart = 0.15, HitEnd = 0.3, CancelOpen = 0.6, RollOpen = 0.66, MoveOpen = 0.82 },
}

return Specs
