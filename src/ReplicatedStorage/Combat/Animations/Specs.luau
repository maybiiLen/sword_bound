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
	publish with AnimationBuilder.Publish() (fills AnimationLibrary.Published for live servers).
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

-- Same tuck, rotating about the forward axis (Z) for side rolls: +Z tips the head to the
-- character's left (-X), -Z to the right.
local function sideRollPose(rot: number, pos: Vector3, waist: number, legs)
	return with(TUCK_ARMS, { Root = { Pos = pos, Rot = V(0, 0, rot) }, Waist = V(waist, 0, 0), Legs = legs })
end

local ROLL_START_LEGS = { RightHip = V(30, 0, 0), RightKnee = V(-40, 0, 0), LeftHip = V(30, 0, 0), LeftKnee = V(-40, 0, 0) }
local ROLL_LAND_LEGS = { RightHip = V(60, 0, 0), RightKnee = V(-90, 0, 0), LeftHip = V(70, 0, 0), LeftKnee = V(-100, 0, 0) }
local ROLL_END = with(GUARD, { Root = { Pos = V(0, -0.35, 0), Rot = V(0, 0, 0) }, Waist = V(-10, 0, 0) })

-- Directional rolls for lock-on (2026-10-01). Same timing and markers as Roll (keys at most 90
-- degrees apart so the rotation interpolates the right way round).
local function sideRollSpec(sign: number)
	return {
		Priority = "Action3",
		Loop = false,
		Keyframes = {
			{ T = 0, Pose = sideRollPose(0, V(0, -0.25, 0), -15, ROLL_START_LEGS), Ease = "Linear" },
			{ T = 0.1, Pose = sideRollPose(80 * sign, V(0.5 * sign, -1.2, 0), -35, TUCK_LEGS), Ease = "Linear" },
			{ T = 0.22, Pose = sideRollPose(170 * sign, V(0.2 * sign, -0.7, 0), -40, TUCK_LEGS), Ease = "Linear" },
			{ T = 0.34, Pose = sideRollPose(260 * sign, V(-0.4 * sign, -1.3, 0), -35, TUCK_LEGS), Ease = "Linear" },
			{ T = 0.46, Pose = sideRollPose(320 * sign, V(-0.2 * sign, -1.0, 0), -20, ROLL_LAND_LEGS), Ease = "Out" },
			{ T = 0.62, Pose = ROLL_END },
		},
		Markers = { IFrameStart = 0.05, IFrameEnd = 0.35, CancelOpen = 0.5 },
	}
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

-- Light4 (2026-10-09): the string's finisher, a spinning horizontal cut. From Light3's low end pose
-- the body coils right, the hips fire and the whole body turns one full circle to the left with the
-- blade held out at waist height, then holds a wide low end pose (the payoff beat). The spin keys
-- are at most ~95 degrees apart so pose interpolation never takes the short way round. Legs use
-- direct angles during the spin so they turn with the hips (a pivot on the spot). Inspired by the
-- vault's moveset research (spinning finishers in DMC/Genshin strings); timing is judgment.
local SPIN_LEGS = { RightHip = V(18, 0, 0), RightKnee = V(-30, 0, 0), LeftHip = V(22, 0, 0), LeftKnee = V(-34, 0, 0) }
local SPIN_ARM = { Pos = V(1.35, -0.05, -0.55), Blade = V(0.85, 0.05, -0.5), Pole = V(1, -0.4, 0.3) }
local SPIN_LEFT_ARM = { Shoulder = V(10, 0, -60), Elbow = V(20, 0, 0) }

Specs.Light4 = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(STANCE, { -- Light3's end: low, blade in front
			Root = { Pos = V(0, -0.75, -0.2), Rot = V(0, 0, 0) },
			Waist = V(-20, 0, 0),
			RightHand = { Pos = V(0.25, -0.85, -1.1), Blade = V(0, -0.5, -0.85) },
			LeftArm = { Shoulder = V(20, 0, -25), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.0, 1.1),
		}), Ease = "Out" },
		{ T = 0.1, Pose = with(STANCE, { -- coil right: blade pulled back past the right hip
			Root = { Pos = V(0, -0.5, 0.1), Rot = V(0, -35, 0) },
			Waist = V(-6, -40, 0),
			RightHand = { Pos = V(1.3, -0.1, 0.5), Blade = V(0.5, 0.1, 0.85), Pole = V(1, -0.2, 0.6) },
			LeftArm = { Shoulder = V(40, 0, -30), Elbow = V(60, 0, 0) },
			Feet = stepFeet(-0.8, 0.6, 0.25, 0),
		}), Ease = "In" },
		{ T = 0.16, Pose = { -- hips fire, the spin starts
			Root = { Pos = V(0, -0.45, -0.05), Rot = V(0, 15, 0) },
			Waist = V(-8, -20, 0),
			RightHand = { Pos = V(1.4, 0, -0.2), Blade = V(0.85, 0.05, -0.5), Pole = V(1, -0.4, 0.3) },
			LeftArm = SPIN_LEFT_ARM,
			Legs = SPIN_LEGS,
		}, Ease = "Linear" },
		{ T = 0.22, Pose = { -- blade crosses the front
			Root = { Pos = V(0, -0.45, -0.05), Rot = V(0, 100, 0) },
			Waist = V(-10, -5, 0),
			RightHand = SPIN_ARM,
			LeftArm = SPIN_LEFT_ARM,
			Legs = SPIN_LEGS,
		}, Ease = "Linear" },
		{ T = 0.29, Pose = { -- back to the camera
			Root = { Pos = V(0, -0.45, -0.05), Rot = V(0, 190, 0) },
			Waist = V(-10, 0, 0),
			RightHand = SPIN_ARM,
			LeftArm = SPIN_LEFT_ARM,
			Legs = SPIN_LEGS,
		}, Ease = "Linear" },
		{ T = 0.36, Pose = {
			Root = { Pos = V(0, -0.45, -0.05), Rot = V(0, 280, 0) },
			Waist = V(-10, 5, 0),
			RightHand = SPIN_ARM,
			LeftArm = SPIN_LEFT_ARM,
			Legs = SPIN_LEGS,
		}, Ease = "Out" },
		{ T = 0.44, Pose = with(STANCE, { -- around again, wide low end pose
			Root = { Pos = V(0, -0.7, -0.1), Rot = V(0, 350, 0) },
			Waist = V(-16, 20, 0),
			RightHand = { Pos = V(-0.3, -0.6, -1.2), Blade = V(-0.75, -0.2, -0.6), Pole = V(0.4, -1, 0.2) },
			LeftArm = { Shoulder = V(0, 0, -55), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-1.1, 1.2),
		}), Ease = "Out" },
		{ T = 0.6, Pose = with(STANCE, { -- hold the end pose (payoff beat)
			Root = { Pos = V(0, -0.72, -0.1), Rot = V(0, 352, 0) },
			Waist = V(-16, 24, 0),
			RightHand = { Pos = V(-0.4, -0.65, -1.1), Blade = V(-0.8, -0.25, -0.5), Pole = V(0.4, -1, 0.2) },
			LeftArm = { Shoulder = V(0, 0, -55), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-1.1, 1.2),
		}), Ease = "InOut" },
		{ T = 0.9, Pose = with(STANCE, { -- recover, rear foot drags in
			Root = { Pos = V(0, -0.42, 0), Rot = V(0, 4, 0) },
			Waist = V(-8, 10, 0),
			RightHand = { Pos = V(0.2, -0.8, -1.0), Blade = V(-0.45, 0.35, -0.8) },
			LeftArm = { Shoulder = V(10, 0, -25), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-0.6, 0.9, 0, 0.16),
		}), Ease = "InOut" },
		{ T = 1.15, Pose = GUARD },
	},
	Markers = { Lunge = 0.12, HitStart = 0.18, HitEnd = 0.4, CancelOpen = 0.62, RollOpen = 0.66, MoveOpen = 0.8 },
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

Specs.RollBack = {
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = rollPose(0, V(0, -0.25, 0), -15, ROLL_START_LEGS), Ease = "Linear" },
		{ T = 0.1, Pose = rollPose(80, V(0, -1.2, -0.5), -35, TUCK_LEGS), Ease = "Linear" },
		{ T = 0.22, Pose = rollPose(170, V(0, -0.7, -0.2), -40, TUCK_LEGS), Ease = "Linear" },
		{ T = 0.34, Pose = rollPose(260, V(0, -1.3, 0.4), -35, TUCK_LEGS), Ease = "Linear" },
		{ T = 0.46, Pose = rollPose(320, V(0, -1.0, 0.2), -20, ROLL_LAND_LEGS), Ease = "Out" },
		{ T = 0.62, Pose = ROLL_END },
	},
	Markers = { IFrameStart = 0.05, IFrameEnd = 0.35, CancelOpen = 0.5 },
}

Specs.RollLeft = sideRollSpec(1)
Specs.RollRight = sideRollSpec(-1)

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

-- RunningAttack: sprint into a lunging one-arm thrust (see the spec's comment).
Specs.RunningAttack = {
	-- 2026-10-08: rebuilt as its own move. It used to be a leaning copy of Light1's forehand, so it
	-- read as a normal slash. Now it is the kit's only straight-line attack: the sprint carries into
	-- a deep lean, the sword arm drives fully out (inspired by DMC's Stinger and SAO's Rage Spike
	-- line), the pose is held while the warp carries you up to 8 studs, then a skid recovery.
	-- Poses and timing are judgment (unsourced); see "Sword combat feel revision" in the vault.
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(STANCE, { -- running lean, blade drawn back at the hip, point forward
			Root = { Pos = V(0, -0.5, 0.1), Rot = V(0, -15, 0) },
			Waist = V(-15, -30, 0),
			RightHand = { Pos = V(0.95, -0.3, 0.6), Blade = V(0.05, 0.3, -1), Pole = V(1, -0.5, 0.3) },
			LeftArm = { Shoulder = V(55, 0, -20), Elbow = V(60, 0, 0) },
			Feet = stepFeet(-0.8, 0.8),
		}), Ease = "In" },
		{ T = 0.1, Pose = with(STANCE, { -- coil: drop low, hand pulls further back, lead foot lifts
			Root = { Pos = V(0, -0.72, 0.15), Rot = V(0, -22, 0) },
			Waist = V(-22, -38, 0),
			-- torso-space blade tilted up by the lean so it stays level in the world
			RightHand = { Pos = V(1.0, -0.1, 0.75), Blade = V(0.05, 0.42, -0.9), Pole = V(1, -0.5, 0.3) },
			LeftArm = { Shoulder = V(70, 0, -15), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-1.2, 0.9, 0.3, 0),
		}), Ease = "In" },
		{ T = 0.2, Pose = with(STANCE, { -- thrust home: full extension, deep lean, long stance
			Root = { Pos = V(0, -0.95, -0.35), Rot = V(0, 18, 0) },
			Waist = V(-38, 20, 0),
			RightHand = { Pos = V(0.35, 1.15, -1.65), Blade = V(0, 0.68, -0.73), Pole = V(1, -0.3, 0.2) },
			LeftArm = { Shoulder = V(-25, 0, -55), Elbow = V(15, 0, 0) },
			Feet = stepFeet(-2.0, 2.0),
		}), Ease = "Out" },
		{ T = 0.36, Pose = with(STANCE, { -- hold the line while the warp carries you
			Root = { Pos = V(0, -0.95, -0.38), Rot = V(0, 20, 0) },
			Waist = V(-36, 22, 0),
			RightHand = { Pos = V(0.35, 1.1, -1.62), Blade = V(0, 0.65, -0.76), Pole = V(1, -0.3, 0.2) },
			LeftArm = { Shoulder = V(-25, 0, -55), Elbow = V(15, 0, 0) },
			Feet = stepFeet(-2.0, 2.1),
		}), Ease = "InOut" },
		{ T = 0.55, Pose = with(STANCE, { -- skid: blade comes back up, weight rocks back
			Root = { Pos = V(0, -0.7, -0.15), Rot = V(0, 8, 0) },
			Waist = V(-18, 8, 0),
			RightHand = { Pos = V(0.6, -0.4, -1.3), Blade = V(-0.1, 0.4, -0.9) },
			LeftArm = { Shoulder = V(20, 0, -30), Elbow = V(30, 0, 0) },
			Feet = stepFeet(-1.6, 1.6),
		}), Ease = "InOut" },
		{ T = 0.85, Pose = with(GUARD, { -- recover, rear foot drags in
			Root = { Pos = V(0, -0.4, 0), Rot = V(0, 4, 0) },
			Waist = V(-6, 4, 0),
			Feet = stepFeet(-0.7, 0.9, 0, 0.14),
		}), Ease = "InOut" },
		{ T = 1.05, Pose = GUARD },
	},
	Markers = { Lunge = 0.04, HitStart = 0.2, HitEnd = 0.36, CancelOpen = 0.6, RollOpen = 0.64, MoveOpen = 0.8 },
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

-- RollAttack: out of the roll's crouch, a low rising slash (fast HitStart, small commitment).
Specs.RollAttack = {
	-- 2026-10-08: rebuilt as a low rising slash. It used to be a rising thrust, which now belongs to
	-- the running attack. Out of the roll's crouch, the blade trails low on the right and rips up
	-- across the body to high left: the only attack that starts near the ground. Poses and timing
	-- are judgment (unsourced); see "Sword combat feel revision" in the vault.
	Priority = "Action3",
	Loop = false,
	Keyframes = {
		{ T = 0, Pose = with(STANCE, { -- crouched out of the roll, blade trailing low right
			Root = { Pos = V(0, -1.0, 0.1), Rot = V(0, -20, 0) },
			Waist = V(-22, -30, 0),
			RightHand = { Pos = V(1.1, -1.1, 0.4), Blade = V(0.3, -0.5, 0.8), Pole = V(1, -0.3, 0.4) },
			LeftArm = { Shoulder = V(40, 0, -25), Elbow = V(50, 0, 0) },
			Feet = stepFeet(-0.8, 0.9),
		}), Ease = "In" },
		{ T = 0.07, Pose = with(STANCE, { -- coil lower, lead foot lifts
			Root = { Pos = V(0, -1.05, 0.12), Rot = V(0, -26, 0) },
			Waist = V(-24, -38, 0),
			RightHand = { Pos = V(1.2, -1.2, 0.55), Blade = V(0.35, -0.45, 0.8), Pole = V(1, -0.3, 0.4) },
			LeftArm = { Shoulder = V(45, 0, -25), Elbow = V(55, 0, 0) },
			Feet = stepFeet(-1.0, 0.9, 0.22, 0),
		}), Ease = "In" },
		{ T = 0.12, Pose = with(STANCE, { -- hips fire, rising, blade swings forward low
			Root = { Pos = V(0, -0.8, -0.05), Rot = V(0, -4, 0) },
			Waist = V(-14, -15, 0),
			RightHand = { Pos = V(0.9, -0.7, -0.6), Blade = V(0.2, 0.2, -1), Pole = V(1, -0.4, 0.3) },
			LeftArm = { Shoulder = V(30, 0, -35), Elbow = V(40, 0, 0) },
			Feet = stepFeet(-1.3, 1.1),
		}), Ease = "Linear" },
		{ T = 0.17, Pose = with(STANCE, { -- contact: blade rising through the front
			Root = { Pos = V(0, -0.5, -0.15), Rot = V(0, 10, 0) },
			Waist = V(-6, 10, 0),
			RightHand = { Pos = V(0.2, 0.3, -1.4), Blade = V(-0.25, 0.9, -0.35), Pole = V(1, -0.2, 0.3) },
			LeftArm = { Shoulder = V(20, 0, -40), Elbow = V(35, 0, 0) },
			Feet = stepFeet(-1.3, 1.3),
		}), Ease = "Out" },
		{ T = 0.25, Pose = with(STANCE, { -- end high left, standing tall
			Root = { Pos = V(0, -0.3, -0.1), Rot = V(0, 18, 0) },
			Waist = V(4, 30, 0),
			RightHand = { Pos = V(-0.6, 1.3, -0.6), Blade = V(-0.6, 0.7, 0.35), Pole = V(0.5, 0.2, -1) },
			LeftArm = { Shoulder = V(0, 0, -50), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-1.2, 1.35),
		}), Ease = "Out" },
		{ T = 0.38, Pose = with(STANCE, { -- overshoot hold
			Root = { Pos = V(0, -0.28, -0.08), Rot = V(0, 20, 0) },
			Waist = V(5, 34, 0),
			RightHand = { Pos = V(-0.7, 1.4, -0.4), Blade = V(-0.6, 0.75, 0.3), Pole = V(0.5, 0.2, -1) },
			LeftArm = { Shoulder = V(0, 0, -52), Elbow = V(25, 0, 0) },
			Feet = stepFeet(-1.2, 1.35),
		}), Ease = "InOut" },
		{ T = 0.62, Pose = with(STANCE, { -- recover, blade comes down to guard, rear foot drags in
			Root = { Pos = V(0, -0.4, 0), Rot = V(0, 6, 0) },
			Waist = V(-6, 10, 0),
			RightHand = { Pos = V(0.3, -0.4, -1.1), Blade = V(-0.3, 0.5, -0.8) },
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
	Markers = { Lunge = 0.05, HitStart = 0.11, HitEnd = 0.24, CancelOpen = 0.42, RollOpen = 0.48, MoveOpen = 0.62 },
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

-- Hit reactions (2026-10-09, vault "Hit reactions, pushback and armor research"). Played on
-- non-player targets (NPCs) by Combat.HitReactions; CombatRules.HitReaction picks which one.
-- Craft rules from the research: start ON the peak pose (played with fade 0), hold it through the
-- hitstop, then ease out; the body is thrown the way the blade's energy goes. Upper body only, so
-- the enemy's legs and its own guard arm keep playing underneath. Values are judgment (unsourced).
local REACT_REST = { Waist = V(0, 0, 0), Neck = V(0, 0, 0), LeftArm = { Shoulder = V(10, 0, -12), Elbow = V(20, 0, 0) } }

local function lightReaction(waist: Vector3, neck: Vector3, arm: Vector3)
	return {
		-- Action2: above the idle/guard (Action) but below attacks (Action3) and Stagger/GuardBreak
		-- (Action4), so an enemy's next attack or a stagger takes over the moment it starts
		Priority = "Action2",
		Loop = false,
		UpperBodyOnly = true,
		Keyframes = {
			{ T = 0, Pose = { Waist = waist, Neck = neck, LeftArm = { Shoulder = arm, Elbow = V(30, 0, 0) } }, Ease = "Out" },
			{ T = 0.09, Pose = { Waist = waist * 1.15, Neck = neck * 1.15, LeftArm = { Shoulder = arm, Elbow = V(35, 0, 0) } }, Ease = "InOut" },
			{ T = 0.4, Pose = REACT_REST },
		},
		Markers = {},
	}
end

local function heavyReaction(waist: Vector3, neck: Vector3, arm: Vector3)
	return {
		Priority = "Action2",
		Loop = false,
		UpperBodyOnly = true,
		Keyframes = {
			{ T = 0, Pose = { Waist = waist, Neck = neck, LeftArm = { Shoulder = arm, Elbow = V(15, 0, 0) } }, Ease = "Out" },
			{ T = 0.16, Pose = { Waist = waist * 1.2, Neck = neck * 1.2, LeftArm = { Shoulder = arm * 1.1, Elbow = V(20, 0, 0) } }, Ease = "InOut" },
			{ T = 0.45, Pose = { Waist = waist * 0.5, Neck = neck * 0.4, LeftArm = { Shoulder = V(30, 0, -30), Elbow = V(30, 0, 0) } }, Ease = "InOut" },
			{ T = 0.7, Pose = REACT_REST },
		},
		Markers = {},
	}
end

Specs.HitLightFront = lightReaction(V(22, 0, 0), V(18, 0, 0), V(30, 0, -40)) -- rocked back
Specs.HitLightLeft = lightReaction(V(8, -34, -14), V(6, -24, -12), V(20, 0, -55)) -- blade from its left: twist right
Specs.HitLightRight = lightReaction(V(8, 34, 14), V(6, 24, 12), V(40, 0, -20)) -- blade from its right: twist left
Specs.HitLightBack = lightReaction(V(-24, 0, 0), V(-20, 0, 0), V(-15, 0, -35)) -- hit from behind: whipped forward
Specs.HitHeavyFront = heavyReaction(V(36, 0, 0), V(26, 0, 0), V(70, 0, -65)) -- folded back hard, arm flung
Specs.HitHeavyBack = heavyReaction(V(-38, 0, 0), V(-26, 0, 0), V(-35, 0, -55))

-- ArmorTwitch: a short shake blended at TwitchWeight over the enemy's own attack when armor absorbs
-- a hit (it keeps attacking; For Honor/Elden Ring hyper armor pattern). Not truly additive: it
-- pulls toward its pose at that weight, and HitReactions fades it out early so it never pops.
Specs.ArmorTwitch = {
	Priority = "Action4",
	Loop = false,
	UpperBodyOnly = true,
	Keyframes = {
		{ T = 0, Pose = { Waist = V(8, 6, 0), Neck = V(6, 0, 0) }, Ease = "Out" },
		{ T = 0.06, Pose = { Waist = V(5, -4, 0), Neck = V(4, 0, 0) }, Ease = "InOut" },
		{ T = 0.22, Pose = { Waist = V(0, 0, 0), Neck = V(0, 0, 0) } },
	},
	Markers = {},
}

-- Timing pass (2026-10-08, "Sword combat feel revision" in the vault). The first light hit landed at
-- 0.26 s, slower than Genshin sword openers (Keqing 0.17 s, Kaeya 0.23 s, KQM library) and slow for
-- Roblox M1s, while the hit-to-hit pace was fine. The lights now land at ~0.19 s and chain every
-- ~0.42 s; the finisher lands at ~0.27 s. Instead of re-keying every pose, keyframe and marker
-- times go through a piecewise linear map ({ old, new } anchors); times after the last anchor
-- shift by the same amount as the last anchor.
local function retime(spec: { [string]: any }, anchors: { { number } })
	local function map(t: number): number
		for i = 2, #anchors do
			local a = anchors[i - 1]
			local b = anchors[i]
			if t <= b[1] then
				local f = (t - a[1]) / (b[1] - a[1])
				return math.round((a[2] + (b[2] - a[2]) * f) * 1000) / 1000
			end
		end
		local last = anchors[#anchors]
		return math.round((t + last[2] - last[1]) * 1000) / 1000
	end
	for _, keyframe in spec.Keyframes do
		keyframe.T = map(keyframe.T)
	end
	local markers = {}
	for name, t in spec.Markers do
		markers[name] = map(t)
	end
	spec.Markers = markers
end

local LIGHT_TIMING = { { 0, 0 }, { 0.26, 0.19 }, { 0.38, 0.29 }, { 0.5, 0.42 }, { 0.72, 0.62 } }
retime(Specs.Light1, LIGHT_TIMING)
retime(Specs.Light2, LIGHT_TIMING)
-- Light3 is the 3rd of 4 hits since 2026-10-09 (Light4 is the finisher), so it lost the long hold
retime(Specs.Light3, { { 0, 0 }, { 0.34, 0.23 }, { 0.46, 0.32 }, { 0.64, 0.46 }, { 0.95, 0.64 } })

return Specs

