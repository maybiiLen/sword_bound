--[[
	PosePreview  (dev tool, Studio edit mode only)
	Lays out keyframes of the generated animations (Combat.Assets.AnimSaves) as a row of posed R15
	rigs holding a weapon model, so poses can be checked in a screenshot without play testing.
	Works with the 2026 AnimationConstraint rigs: every part is anchored and placed by walking the
	joints from the HumanoidRootPart (part1 = part0 * attachment0 * pose * attachment1^-1).

	Command bar / MCP (Edit mode), after running AnimationBuilder:
		local PosePreview = require(game.ServerStorage.CombatDev.PosePreview:Clone())
		PosePreview.Show({
			{ "RunningAttack", { 0, 0.1, 0.2, 0.36 } },   -- one row per animation, keyframe times
			{ "RollAttack", { 0, 0.17, 0.25 } },
		}, { Origin = Vector3.new(0, 80, 0), Weapon = "ForgeSword" })
		PosePreview.Clear()
	Rows run along X (7 studs apart), rows 30 studs apart along Z; rigs face -X, so look at a row
	from -Z (screen right is -X: the first keyframe is on the right).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PosePreview = {}

local FOLDER_NAME = "PosePreview"

local function getFolder(): Folder
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = workspace
	end
	return folder :: Folder
end

local function makeRig(weaponName: string?): Model
	local rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	local animate = rig:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	if weaponName then
		local source = ReplicatedStorage.Combat.Assets.WeaponModels:FindFirstChild(weaponName)
		if source then
			local weapon = source:Clone()
			weapon.Name = "Weapon"
			for _, part in weapon:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			weapon.Parent = rig
		end
	end
	return rig
end

local function findKeyframe(sequence: Instance, time: number): Keyframe?
	for _, keyframe in sequence:GetChildren() do
		if keyframe:IsA("Keyframe") and math.abs(keyframe.Time - time) < 0.005 then
			return keyframe
		end
	end
	return nil
end

local function pose(rig: Model, keyframe: Keyframe, rootCFrame: CFrame)
	local poses: { [string]: CFrame } = {}
	for _, item in keyframe:GetDescendants() do
		if item:IsA("Pose") then
			poses[item.Name] = item.CFrame
		end
	end
	local rootPart = rig:FindFirstChild("HumanoidRootPart") :: BasePart
	rootPart.CFrame = rootCFrame
	local weaponModel = rig:FindFirstChild("Weapon")
	local joints = {}
	for _, joint in rig:GetDescendants() do
		local isJoint = joint:IsA("AnimationConstraint") or joint:IsA("Motor6D")
		local inWeapon = weaponModel ~= nil and joint:IsDescendantOf(weaponModel)
		if isJoint and not inWeapon then
			table.insert(joints, joint)
		end
	end
	local solved = { [rootPart] = true }
	local progress = true
	while progress do
		progress = false
		for _, joint in joints do
			local part0, part1, offset0, offset1
			if joint:IsA("AnimationConstraint") then
				local a0 = (joint :: AnimationConstraint).Attachment0
				local a1 = (joint :: AnimationConstraint).Attachment1
				if a0 and a1 then
					part0, part1, offset0, offset1 = a0.Parent, a1.Parent, a0.CFrame, a1.CFrame
				end
			else
				local motor = joint :: Motor6D
				part0, part1, offset0, offset1 = motor.Part0, motor.Part1, motor.C0, motor.C1
			end
			if part0 and part1 and solved[part0] and not solved[part1] then
				local jointPose = poses[part1.Name] or CFrame.identity
				;(part1 :: BasePart).CFrame = (part0 :: BasePart).CFrame * offset0 * jointPose * offset1:Inverse()
				solved[part1] = true
				progress = true
			end
		end
	end
	local weapon = rig:FindFirstChild("Weapon") :: Model?
	local hand = rig:FindFirstChild("RightHand") :: BasePart?
	if weapon and weapon.PrimaryPart and hand then
		local grip = weapon.PrimaryPart:FindFirstChild("Grip") :: Attachment?
		local handGrip = hand:FindFirstChild("RightGripAttachment") :: Attachment?
		if grip and handGrip then
			weapon:PivotTo(handGrip.WorldCFrame * grip.CFrame:Inverse())
		end
	end
end

function PosePreview.Clear()
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if folder then
		folder:Destroy()
	end
end

-- rows: { { animationName, { keyframeTime, ... } }, ... }
function PosePreview.Show(rows: { any }, options: { Origin: Vector3?, Weapon: string? }?): string
	PosePreview.Clear()
	local folder = getFolder()
	local origin = (options and options.Origin) or Vector3.new(0, 80, 0)
	local weaponName = if options and options.Weapon then options.Weapon else "ForgeSword"
	local saves = ReplicatedStorage.Combat.Assets.AnimSaves
	local template = makeRig(weaponName)
	local missing = {}
	for rowIndex, row in rows do
		local sequence = saves:FindFirstChild(row[1])
		for column, time in row[2] do
			local keyframe = sequence and findKeyframe(sequence, time)
			if keyframe then
				local rig = template:Clone()
				rig.Name = `{row[1]}_{time}`
				local position = origin + Vector3.new((column - 1) * 7, 0, (rowIndex - 1) * 30)
				pose(rig, keyframe, CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0))
				rig.Parent = folder
			else
				table.insert(missing, `{row[1]}@{time}`)
			end
		end
	end
	template:Destroy()
	return if #missing > 0 then "missing keyframes: " .. table.concat(missing, ", ") else "ok"
end

return PosePreview

