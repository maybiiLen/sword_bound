--[[
	AnimationBuilder  (dev tool, Studio edit mode only)
	Compiles Combat.Animations.Specs into KeyframeSequences in
	ReplicatedStorage.Combat.Assets.AnimSaves (ReplicatedStorage so clients can register them
	during Studio playtests before they are published).

	Hands and feet are solved with two-bone IK against the default R15 proportions, so a spec can
	say "grip here, blade pointing there" instead of hand-tuning every joint.

	Run from the command bar (or the Studio MCP):
		local Specs = require(game.ReplicatedStorage.Combat.Animations.Specs:Clone())
		require(game.ServerStorage.CombatDev.AnimationBuilder:Clone()).Build(Specs)
	(Clone() sidesteps the require cache so edits are picked up.)

	Re-running overwrites the generated sequences. If an animator has polished one in the
	Animation Editor, rename it (e.g. Light1_Polished) so the builder never overwrites it.
	See Docs.Combat > "Animation pipeline".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationBuilder = {}

local V = Vector3.new
local rad = math.rad

-- Default R15 joint offsets (Attachment0 in the parent part, Attachment1 in the child part).
local RIG = {
	RootC0 = V(0, -0.95, 0),
	RootC1 = V(0, -0.204, 0),
	Shoulder = V(0.749, 0.587, 0),
	ArmUpper = V(0.387, -0.765, 0),
	ArmLower = V(0, -0.798, 0),
	WristToGrip = 0.275,
	Hip = V(0.377, -0.204, 0),
	LegUpper = V(0, -0.910, 0),
	LegLower = V(0, -1.017, 0),
}

local PRIORITY = {
	Idle = Enum.AnimationPriority.Idle,
	Movement = Enum.AnimationPriority.Movement,
	Action = Enum.AnimationPriority.Action,
	Action2 = Enum.AnimationPriority.Action2,
	Action3 = Enum.AnimationPriority.Action3,
	Action4 = Enum.AnimationPriority.Action4,
}

local function angles(v: Vector3?): CFrame
	if not v then
		return CFrame.identity
	end
	return CFrame.Angles(rad(v.X), rad(v.Y), rad(v.Z))
end

local function frame(yAxis: Vector3, xHint: Vector3): CFrame
	local y = yAxis.Unit
	local x = xHint - y * xHint:Dot(y)
	if x.Magnitude < 1e-4 then
		x = Vector3.zAxis:Cross(y)
		if x.Magnitude < 1e-4 then
			x = Vector3.xAxis
		end
	end
	x = x.Unit
	return CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y))
end

local function rotationOnly(cf: CFrame): CFrame
	return cf - cf.Position
end

-- Two-bone IK in the parent's space. Returns the upper and lower segment rotations and the
-- (reach-clamped) end position.
local function solveLimb(s: Vector3, target: Vector3, upperRest: Vector3, lowerRest: Vector3, pole: Vector3, hingeRest: Vector3)
	local l1, l2 = upperRest.Magnitude, lowerRest.Magnitude
	local toTarget = target - s
	local dir = if toTarget.Magnitude > 1e-4 then toTarget.Unit else V(0, -1, 0)
	local d = math.clamp(toTarget.Magnitude, math.abs(l1 - l2) + 1e-3, l1 + l2 - 1e-3)
	local a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
	local h = math.sqrt(math.max(l1 * l1 - a * a, 0))
	local perp = pole - dir * pole:Dot(dir)
	if perp.Magnitude < 1e-4 then
		perp = frame(dir, Vector3.xAxis).ZVector
	end
	perp = perp.Unit
	local elbow = s + dir * a + perp * h
	local wrist = s + dir * d
	local hinge = perp:Cross(dir).Unit

	local upper = frame(elbow - s, hinge) * frame(upperRest, hingeRest):Inverse()
	local lower = frame(elbow - wrist, hinge) * frame(-lowerRest, hingeRest):Inverse()
	return upper, lower, wrist
end

local function solveRightHand(spec)
	local s = RIG.Shoulder
	local blade = spec.Blade.Unit
	local up = spec.Up or (s - spec.Pos)
	local handY = up - blade * up:Dot(blade)
	if handY.Magnitude < 1e-4 then
		handY = V(0, 1, 0)
	end
	handY = handY.Unit
	local handZ = -blade
	local hand = CFrame.fromMatrix(Vector3.zero, handY:Cross(handZ), handY, handZ)
	local wristTarget = spec.Pos + handY * RIG.WristToGrip
	local upper, lower = solveLimb(s, wristTarget, RIG.ArmUpper, RIG.ArmLower, spec.Pole or V(0.8, -1, 0.6), Vector3.xAxis)
	return upper, upper:Inverse() * lower, lower:Inverse() * hand
end

local function solveLeftHand(spec)
	local s = V(-RIG.Shoulder.X, RIG.Shoulder.Y, RIG.Shoulder.Z)
	local upperRest = V(-RIG.ArmUpper.X, RIG.ArmUpper.Y, RIG.ArmUpper.Z)
	local upper, lower = solveLimb(s, spec.Pos, upperRest, RIG.ArmLower, spec.Pole or V(-0.8, -1, 0.6), Vector3.xAxis)
	return upper, upper:Inverse() * lower, CFrame.identity
end

local function solveFoot(side: number, target: Vector3, rootTransform: CFrame, pole: Vector3)
	local lowerTorso = CFrame.new(RIG.RootC0) * rootTransform * CFrame.new(-RIG.RootC1)
	local localTarget = lowerTorso:PointToObjectSpace(target)
	local hip = V(RIG.Hip.X * side, RIG.Hip.Y, RIG.Hip.Z)
	local upper, lower = solveLimb(hip, localTarget, RIG.LegUpper, RIG.LegLower, pole, -Vector3.xAxis)
	local footWorld = rotationOnly(rootTransform):Inverse()
	return upper, upper:Inverse() * lower, lower:Inverse() * footWorld
end

-- Returns { [partName]: Transform CFrame } for the joints this pose drives.
function AnimationBuilder.Solve(pose, upperBodyOnly: boolean?): { [string]: CFrame }
	local out: { [string]: CFrame } = {}

	local rootTransform = CFrame.identity
	if pose.Root and not upperBodyOnly then
		rootTransform = CFrame.new(pose.Root.Pos or Vector3.zero) * angles(pose.Root.Rot)
		out.LowerTorso = rootTransform
	end

	local waist = pose.Waist or Vector3.zero
	out.UpperTorso = angles(waist)
	out.Head = if pose.Neck then angles(pose.Neck) else angles(V(-waist.X * 0.5, -waist.Y * 0.6, 0))

	if pose.RightHand then
		out.RightUpperArm, out.RightLowerArm, out.RightHand = solveRightHand(pose.RightHand)
	end
	if pose.LeftHand then
		out.LeftUpperArm, out.LeftLowerArm, out.LeftHand = solveLeftHand(pose.LeftHand)
	elseif pose.LeftArm then
		out.LeftUpperArm = angles(pose.LeftArm.Shoulder)
		out.LeftLowerArm = angles(pose.LeftArm.Elbow)
		out.LeftHand = angles(pose.LeftArm.Wrist)
	end

	if not upperBodyOnly then
		if pose.Feet then
			out.RightUpperLeg, out.RightLowerLeg, out.RightFoot = solveFoot(1, pose.Feet.Right, rootTransform, V(0.2, 0, -1))
			out.LeftUpperLeg, out.LeftLowerLeg, out.LeftFoot = solveFoot(-1, pose.Feet.Left, rootTransform, V(-0.2, 0, -1))
		elseif pose.Legs then
			out.RightUpperLeg = angles(pose.Legs.RightHip)
			out.RightLowerLeg = angles(pose.Legs.RightKnee)
			out.LeftUpperLeg = angles(pose.Legs.LeftHip)
			out.LeftLowerLeg = angles(pose.Legs.LeftKnee)
		end
	end
	return out
end

local HIERARCHY = {
	HumanoidRootPart = { "LowerTorso" },
	LowerTorso = { "UpperTorso", "RightUpperLeg", "LeftUpperLeg" },
	UpperTorso = { "Head", "RightUpperArm", "LeftUpperArm" },
	RightUpperArm = { "RightLowerArm" },
	RightLowerArm = { "RightHand" },
	LeftUpperArm = { "LeftLowerArm" },
	LeftLowerArm = { "LeftHand" },
	RightUpperLeg = { "RightLowerLeg" },
	RightLowerLeg = { "RightFoot" },
	LeftUpperLeg = { "LeftLowerLeg" },
	LeftLowerLeg = { "LeftFoot" },
}

local function subtreeHas(name: string, transforms): boolean
	if transforms[name] then
		return true
	end
	for _, child in HIERARCHY[name] or {} do
		if subtreeHas(child, transforms) then
			return true
		end
	end
	return false
end

local function easing(ease: string?): (Enum.PoseEasingStyle, Enum.PoseEasingDirection)
	if ease == nil or ease == "Linear" then
		return Enum.PoseEasingStyle.Linear, Enum.PoseEasingDirection.In
	end
	return Enum.PoseEasingStyle.CubicV2, Enum.PoseEasingDirection[ease]
end

local function buildPose(name: string, transforms, style, direction, parent: Instance)
	local pose = Instance.new("Pose")
	pose.Name = name
	pose.CFrame = transforms[name] or CFrame.identity
	pose.Weight = if transforms[name] then 1 else 0
	pose.EasingStyle = style
	pose.EasingDirection = direction
	for _, child in HIERARCHY[name] or {} do
		if subtreeHas(child, transforms) then
			buildPose(child, transforms, style, direction, pose)
		end
	end
	pose.Parent = parent
end

function AnimationBuilder.BuildOne(name: string, spec): KeyframeSequence
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = name
	sequence.Loop = spec.Loop == true
	sequence.Priority = PRIORITY[spec.Priority] or Enum.AnimationPriority.Action

	local keyframesByTime: { [number]: Keyframe } = {}
	for _, key in spec.Keyframes do
		local keyframe = Instance.new("Keyframe")
		keyframe.Time = key.T
		local style, direction = easing(key.Ease)
		buildPose("HumanoidRootPart", AnimationBuilder.Solve(key.Pose, spec.UpperBodyOnly), style, direction, keyframe)
		keyframe.Parent = sequence
		keyframesByTime[key.T] = keyframe
	end

	for markerName, time in spec.Markers or {} do
		local keyframe = keyframesByTime[time]
		if not keyframe then
			keyframe = Instance.new("Keyframe")
			keyframe.Time = time
			keyframe.Parent = sequence
			keyframesByTime[time] = keyframe
		end
		local marker = Instance.new("KeyframeMarker")
		marker.Name = markerName
		marker.Parent = keyframe
	end
	return sequence
end

function AnimationBuilder.Build(specs): { string }
	local assets = ReplicatedStorage.Combat.Assets
	local folder = assets:FindFirstChild("AnimSaves")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "AnimSaves"
		folder.Parent = assets
	end
	local built = {}
	for name, spec in specs do
		local existing = folder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		AnimationBuilder.BuildOne(name, spec).Parent = folder
		table.insert(built, name)
	end
	table.sort(built)
	return built
end

return AnimationBuilder
