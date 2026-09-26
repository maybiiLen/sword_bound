--[[
	CameraController  (client)
	Elden Ring style combat camera, active while the weapon is drawn (WeaponController toggles it):
		- free orbit with the mouse locked to the centre (hold Left Alt to free the cursor),
		  gamepad right stick, touch drag on the right side of the screen, wheel to zoom
		- over-the-shoulder offset, smoothed follow, wall collision
		- lock-on framing: when LockOnController has a target the camera turns to keep you and the
		  target in view; a quick mouse flick / stick flick switches target
		- feedback: :Shake(trauma) and :Punch(studs) (a quick dolly-in, our "FOV kick" that
		  doesn't fight the Sprint system's FOV tween)
	With the weapon sheathed the default Roblox camera is used (shake still applies).

	The character still turns to face where it moves (AutoRotate); MovementController takes
	over facing while locked on or mid-attack.

	API:
		CameraController:Start(lockOnController)
		CameraController:SetEnabled(enabled)
		CameraController:Shake(trauma)          0..1, stacks
		CameraController:Punch(studs)
		CameraController.Enabled

	Tuning: CombatConfig.Camera. See Docs.Combat > "Camera".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)

local Settings = CombatConfig.Camera
local player = Players.LocalPlayer

local CameraController = {
	Enabled = false,
}

local lockOn = nil
local yaw, pitch = 0, 0
local distance, zoomTarget = Settings.Distance, Settings.Distance
local focus: Vector3? = nil
local trauma, punch = 0, 0
local stick = Vector2.zero
local stickFlicked = false
local flickX, flickStart = 0, 0
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function freeCursorHeld(): boolean
	for _, key in CombatConfig.FreeCursorKeys do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function lerpAngle(a: number, b: number, t: number): number
	local diff = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + diff * t
end

local function rotate(dx: number, dy: number)
	if lockOn and lockOn.Target then
		return
	end
	yaw -= dx
	pitch = math.clamp(pitch - dy, math.rad(Settings.MinPitch), math.rad(Settings.MaxPitch))
end

local function onFlick(dx: number)
	if not (lockOn and lockOn.Target) then
		return
	end
	local now = os.clock()
	if now - flickStart > 0.25 then
		flickX, flickStart = 0, now
	end
	flickX += dx
	if math.abs(flickX) >= CombatConfig.LockOnSwitchPixels then
		lockOn:Switch(if flickX > 0 then 1 else -1)
		flickX, flickStart = 0, now
	end
end

local function onInputChanged(input: InputObject, processed: boolean)
	if not CameraController.Enabled then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			rotate(input.Delta.X * Settings.MouseSensitivity, input.Delta.Y * Settings.MouseSensitivity)
			onFlick(input.Delta.X)
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
		zoomTarget = math.clamp(zoomTarget - input.Position.Z * 1.5, Settings.MinDistance, Settings.MaxDistance)
	elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
		stick = Vector2.new(input.Position.X, input.Position.Y)
	elseif input.UserInputType == Enum.UserInputType.Touch and not processed then
		local camera = workspace.CurrentCamera
		if camera and input.Position.X > camera.ViewportSize.X * 0.4 then
			rotate(input.Delta.X * Settings.MouseSensitivity * 1.4, input.Delta.Y * Settings.MouseSensitivity * 1.4)
			onFlick(input.Delta.X)
		end
	end
end

local function shakeOffset(now: number): CFrame
	if trauma <= 0 then
		return CFrame.identity
	end
	local amount = trauma * trauma
	local maxAngle = 0.045 * amount
	return CFrame.Angles(
		math.noise(now * 22, 1.7) * maxAngle,
		math.noise(now * 22, 5.3) * maxAngle,
		math.noise(now * 22, 9.1) * maxAngle * 0.5
	)
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	local now = os.clock()
	trauma = math.max(trauma - dt * 1.8, 0)
	punch *= math.exp(-9 * dt)

	if not CameraController.Enabled then
		if trauma > 0 and camera then
			camera.CFrame *= shakeOffset(now)
		end
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not camera or not root then
		return
	end

	if freeCursorHeld() then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	if stick.Magnitude > 0.15 then
		rotate(stick.X * Settings.GamepadSensitivity * dt, -stick.Y * Settings.GamepadSensitivity * dt * 0.7)
	end
	local flicking = math.abs(stick.X) > 0.8
	if flicking and not stickFlicked and lockOn and lockOn.Target then
		lockOn:Switch(if stick.X > 0 then 1 else -1)
	end
	stickFlicked = flicking

	local targetPart = lockOn and lockOn.TargetPart
	if targetPart then
		local offset = targetPart.Position - root.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude > 0.5 then
			local desiredYaw = math.atan2(-flat.X, -flat.Z)
			local desiredPitch = math.rad(Settings.LockOnPitch) + math.atan2(offset.Y, flat.Magnitude) * 0.5
			local t = 1 - math.exp(-10 * dt)
			yaw = lerpAngle(yaw, desiredYaw, t)
			pitch = pitch + (math.clamp(desiredPitch, math.rad(Settings.MinPitch), math.rad(Settings.MaxPitch)) - pitch) * t
		end
	end

	local targetFocus = root.Position + Vector3.new(0, Settings.FocusHeight, 0)
	focus = if focus then focus:Lerp(targetFocus, 1 - math.exp(-25 * dt)) else targetFocus
	distance += (zoomTarget - distance) * (1 - math.exp(-12 * dt))

	local rotation = CFrame.fromOrientation(pitch, yaw, 0)
	local pivot = focus :: Vector3
	local desired = (CFrame.new(pivot) * rotation * CFrame.new(Settings.ShoulderOffset.X, Settings.ShoulderOffset.Y, distance - punch)).Position

	raycastParams.FilterDescendantsInstances = { character }
	local toCamera = desired - pivot
	local hit = workspace:Spherecast(pivot, 0.4, toCamera, raycastParams)
	local position = if hit then pivot + toCamera.Unit * math.max(hit.Distance - 0.1, 0.5) else desired

	camera.CFrame = CFrame.new(position) * rotation * shakeOffset(now)
	camera.Focus = CFrame.new(pivot)
end

function CameraController:SetEnabled(enabled: boolean)
	if self.Enabled == enabled then
		return
	end
	self.Enabled = enabled
	local camera = workspace.CurrentCamera
	if enabled then
		if camera then
			local look = camera.CFrame.LookVector
			yaw = math.atan2(-look.X, -look.Z)
			pitch = math.clamp(math.asin(math.clamp(look.Y, -1, 1)), math.rad(Settings.MinPitch), math.rad(Settings.MaxPitch))
		end
		focus = nil
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if camera then
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end

function CameraController:Shake(amount: number)
	trauma = math.min(trauma + amount, 1)
end

function CameraController:Punch(studs: number)
	punch = math.max(punch, studs)
end

function CameraController:Start(lockOnController)
	lockOn = lockOnController
	UserInputService.InputChanged:Connect(onInputChanged)
	RunService:BindToRenderStep("CombatCamera", Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraController
