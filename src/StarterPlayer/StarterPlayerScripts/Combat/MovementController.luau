--[[
	MovementController  (client)
	Character motion that combat needs on top of normal walking. The client owns its own
	character's physics, so all of this runs locally and replicates like normal movement.

		- Facing: while locked on the character faces the target (AutoRotate off, AlignOrientation),
		  so walking becomes strafing. Actions can override facing with :SetFacing(dir) (e.g. an
		  attack turns toward the target / stick direction during its wind-up, then commits).
		- Dashes: :Dash(dir, speed, duration) drives a LinearVelocity with an ease-out curve. Used
		  for rolls, backsteps and attack lunges.
		- Speed: :SetSpeedMultiplier(x) writes the MoveSpeedMultiplier attribute locally for instant
		  prediction; the server writes the same attribute authoritatively and the Sprint system
		  applies it to WalkSpeed on both sides.

	API:
		MovementController:Start(lockOnController)
		MovementController:SetFacing(direction?)       nil = back to normal facing rules
		MovementController:GetIntentDirection() -> Vector3   lock target > move input > current facing
		MovementController:GetMoveInput() -> Vector3         flat, zero if not moving
		MovementController:Dash(direction, speed, duration)
		MovementController:StopDash()
		MovementController:FaceInstantly(direction)
		MovementController:SetSpeedMultiplier(multiplier)

	See Docs.Combat > "Movement".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)

local Attr = CombatConfig.Attributes
local player = Players.LocalPlayer

local MovementController = {}

local lockOn = nil
local character: Model? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local align: AlignOrientation? = nil
local velocity: LinearVelocity? = nil
local facingOverride: Vector3? = nil
local dash: { direction: Vector3, speed: number, duration: number, start: number }? = nil

local function flat(v: Vector3): Vector3?
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else nil
end

local function setup(newCharacter: Model)
	character, humanoid, root, align, velocity = nil, nil, nil, nil, nil
	facingOverride, dash = nil, nil
	local hum = newCharacter:WaitForChild("Humanoid", 10) :: Humanoid?
	local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hum or not rootPart or player.Character ~= newCharacter then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "CombatMoveAttachment"
	attachment.Parent = rootPart

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "CombatFacing"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = 40
	alignOrientation.Enabled = false
	alignOrientation.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "CombatDash"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	linearVelocity.PrimaryTangentAxis = Vector3.xAxis
	linearVelocity.SecondaryTangentAxis = Vector3.zAxis
	linearVelocity.MaxForce = 1e5
	linearVelocity.Enabled = false
	linearVelocity.Parent = rootPart

	character, humanoid, root, align, velocity = newCharacter, hum, rootPart, alignOrientation, linearVelocity
end

local function step()
	local hum, rootPart, alignOrientation, linearVelocity = humanoid, root, align, velocity
	if not hum or not rootPart or not alignOrientation or not linearVelocity then
		return
	end

	local desired = facingOverride
	if not desired and lockOn and lockOn.TargetPart then
		desired = flat(lockOn.TargetPart.Position - rootPart.Position)
	end
	if desired and hum.Health > 0 then
		hum.AutoRotate = false
		alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, desired)
		alignOrientation.Enabled = true
	else
		hum.AutoRotate = true
		alignOrientation.Enabled = false
	end

	local current = dash
	if current then
		local t = (os.clock() - current.start) / current.duration
		if t >= 1 then
			dash = nil
			linearVelocity.Enabled = false
		else
			local speed = current.speed * (1 - t * t)
			linearVelocity.PlaneVelocity = Vector2.new(current.direction.X, current.direction.Z) * speed
			linearVelocity.Enabled = true
		end
	end
end

function MovementController:SetFacing(direction: Vector3?)
	facingOverride = if direction then flat(direction) else nil
end

function MovementController:GetMoveInput(): Vector3
	local hum = humanoid
	if hum and hum.MoveDirection.Magnitude > 0.1 then
		return flat(hum.MoveDirection) or Vector3.zero
	end
	return Vector3.zero
end

function MovementController:GetIntentDirection(): Vector3
	local rootPart = root
	if not rootPart then
		return Vector3.new(0, 0, -1)
	end
	if lockOn and lockOn.TargetPart then
		local toTarget = flat(lockOn.TargetPart.Position - rootPart.Position)
		if toTarget then
			return toTarget
		end
	end
	local input = self:GetMoveInput()
	if input.Magnitude > 0 then
		return input
	end
	return flat(rootPart.CFrame.LookVector) or Vector3.new(0, 0, -1)
end

function MovementController:FaceInstantly(direction: Vector3)
	local rootPart = root
	local dir = flat(direction)
	if rootPart and dir then
		rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + dir)
	end
end

function MovementController:Dash(direction: Vector3, speed: number, duration: number)
	local dir = flat(direction)
	if not dir or not velocity then
		return
	end
	dash = { direction = dir, speed = speed, duration = duration, start = os.clock() }
end

function MovementController:StopDash()
	dash = nil
	if velocity then
		velocity.Enabled = false
	end
end

function MovementController:SetSpeedMultiplier(multiplier: number)
	if character then
		character:SetAttribute(Attr.MoveSpeedMultiplier, multiplier)
	end
end

function MovementController:Start(lockOnController)
	lockOn = lockOnController
	player.CharacterAdded:Connect(setup)
	if player.Character then
		task.spawn(setup, player.Character)
	end
	RunService.PreSimulation:Connect(step)
end

return MovementController
