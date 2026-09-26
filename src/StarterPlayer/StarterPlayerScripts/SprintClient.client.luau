--!strict
-- Client side of the sprint system: input, predicted speed change, sprint animation,
-- camera FOV kick and the stamina bar. The server (SprintServer) is authoritative;
-- this script only predicts the start of a sprint so it feels instant.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local SprintFolder = ReplicatedStorage:WaitForChild("Sprint")
local Config = require(SprintFolder:WaitForChild("SprintConfig"))
local SprintRemote = SprintFolder:WaitForChild("SprintRemote") :: RemoteEvent
local Animations = SprintFolder:WaitForChild("Animations")

local Attr = Config.Attributes

local ACTION_NAME = "Sprint"
local TOGGLE_IDLE_CANCEL_TIME = 0.75
local HIDE_DELAY = 1.5
local TRAIL_HOLD_TIME = 0.4
local LOW_STAMINA_RATIO = 0.3

local COLOR_NORMAL = Color3.fromRGB(80, 220, 140)
local COLOR_LOW = Color3.fromRGB(255, 190, 70)
local COLOR_EXHAUSTED = Color3.fromRGB(235, 75, 75)

local gui = player:WaitForChild("PlayerGui"):WaitForChild("SprintGui") :: ScreenGui
local container = gui:WaitForChild("Container") :: CanvasGroup
local track = container:WaitForChild("Track") :: Frame
local fill = track:WaitForChild("Fill") :: Frame
local trail = track:WaitForChild("Trail") :: Frame
local titleLabel = container:WaitForChild("Title") :: TextLabel
local valueLabel = container:WaitForChild("Value") :: TextLabel

local character: Model? = nil
local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil
local sprintTrack: AnimationTrack? = nil
local animSpeedMultiplier = 1
local characterConnections: { RBXScriptConnection } = {}

local intent = false
local toggleMode = false
local requestTime = 0
local idleSince: number? = nil
local predictedSprinting = false
local sprintVisualsActive = false

local displayedStamina = Config.MaxStamina
local trailStamina = Config.MaxStamina
local trailHoldUntil = 0
local lastActiveTime = 0
local barVisible = false

local baseFov = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70
local fovTween: Tween? = nil

local function setIntent(wants: boolean)
	if intent == wants then
		return
	end
	intent = wants
	requestTime = os.clock()
	idleSince = nil
	SprintRemote:FireServer(wants)
	ContextActionService:SetTitle(ACTION_NAME, if wants then "Walk" else "Sprint")
end

local function computeSprinting(): boolean
	local char = character
	local hum = humanoid
	if not intent or not char or not hum or hum.Health <= 0 then
		return false
	end
	if char:GetAttribute(Attr.Sprinting) == true then
		return true
	end
	-- Server hasn't confirmed yet: trust our own prediction briefly, then defer to the server.
	if os.clock() - requestTime > Config.PredictionGrace then
		return false
	end
	local stamina = char:GetAttribute(Attr.Stamina)
	return char:GetAttribute(Attr.Exhausted) ~= true
		and char:GetAttribute(Attr.Blocked) ~= true
		and typeof(stamina) == "number"
		and stamina > 0
end

local function setFov(active: boolean)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if fovTween then
		fovTween:Cancel()
	end
	local target = if active then baseFov + Config.FovBoost else baseFov
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(Config.FovTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = target }
	)
	fovTween = tween
	tween:Play()
end

local function setBarVisible(visible: boolean)
	if barVisible == visible then
		return
	end
	barVisible = visible
	TweenService:Create(
		container,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = if visible then 0 else 1 }
	):Play()
end

local function applySprinting(sprinting: boolean)
	if predictedSprinting == sprinting then
		return
	end
	predictedSprinting = sprinting
	if humanoid then
		humanoid.WalkSpeed = if sprinting then Config.SprintSpeed else Config.WalkSpeed
	end
end

local function setSprintVisuals(active: boolean, speedRatio: number)
	local animTrack = sprintTrack
	if active ~= sprintVisualsActive then
		sprintVisualsActive = active
		setFov(active)
		if animTrack then
			if active then
				animTrack:Play(Config.AnimationFadeTime)
			else
				animTrack:Stop(Config.AnimationFadeTime)
			end
		end
	end
	if active and animTrack then
		animTrack:AdjustSpeed(math.clamp(speedRatio, 0.6, 1.4) * Config.AnimationBaseSpeed * animSpeedMultiplier)
	end
end

local function onAction(_: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		if inputState == Enum.UserInputState.Begin then
			toggleMode = false
			setIntent(true)
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			setIntent(false)
		end
	elseif inputState == Enum.UserInputState.Begin then
		-- Gamepad stick-click and the touch button toggle instead of requiring a hold.
		toggleMode = true
		setIntent(not intent)
	end
	return Enum.ContextActionResult.Sink
end

local function disconnectCharacter()
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	if sprintTrack then
		sprintTrack:Stop(0)
		sprintTrack:Destroy()
		sprintTrack = nil
	end
	character, humanoid, rootPart = nil, nil, nil
end

local function onCharacterAdded(newCharacter: Model)
	disconnectCharacter()
	character = newCharacter

	-- The server resets its state on respawn, so reset locally without firing the remote.
	intent = false
	toggleMode = false
	predictedSprinting = false
	sprintVisualsActive = false
	displayedStamina = Config.MaxStamina
	trailStamina = Config.MaxStamina
	ContextActionService:SetTitle(ACTION_NAME, "Sprint")
	setFov(false)

	local hum = newCharacter:WaitForChild("Humanoid") :: Humanoid
	local root = newCharacter:WaitForChild("HumanoidRootPart") :: BasePart
	local animator = hum:WaitForChild("Animator") :: Animator
	if character ~= newCharacter then
		return
	end
	humanoid = hum
	rootPart = root

	local animName = if hum.RigType == Enum.HumanoidRigType.R15 then "SprintR15" else "SprintR6"
	local animation = Animations:FindFirstChild(animName) :: Animation?
	if animation then
		local loaded = animator:LoadAnimation(animation)
		loaded.Priority = Enum.AnimationPriority.Movement
		loaded.Looped = true
		sprintTrack = loaded
		local multiplier = animation:GetAttribute("PlaybackSpeed")
		animSpeedMultiplier = if typeof(multiplier) == "number" then multiplier else 1
	else
		warn(`[Sprint] Missing animation {animName} in ReplicatedStorage.Sprint.Animations`)
	end

	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal(Attr.Exhausted):Connect(function()
		if newCharacter:GetAttribute(Attr.Exhausted) == true then
			toggleMode = false
			setIntent(false)
		end
	end))
	table.insert(characterConnections, hum.Died:Connect(function()
		setIntent(false)
	end))
end

local function updateBar(dt: number, now: number)
	local char = character
	local maxStamina = Config.MaxStamina
	local target = maxStamina
	local exhausted = false
	if char then
		local m = char:GetAttribute(Attr.MaxStamina)
		local s = char:GetAttribute(Attr.Stamina)
		if typeof(m) == "number" and m > 0 then
			maxStamina = m
		end
		if typeof(s) == "number" then
			target = s
		end
		exhausted = char:GetAttribute(Attr.Exhausted) == true
	end

	-- Stamina replicates at ~10Hz; smooth it so the bar moves continuously.
	displayedStamina += (target - displayedStamina) * (1 - math.exp(-15 * dt))

	if displayedStamina >= trailStamina then
		trailStamina = displayedStamina
		trailHoldUntil = now + TRAIL_HOLD_TIME
	elseif now >= trailHoldUntil then
		trailStamina += (displayedStamina - trailStamina) * (1 - math.exp(-5 * dt))
	end

	local ratio = math.clamp(displayedStamina / maxStamina, 0, 1)
	fill.Size = UDim2.fromScale(ratio, 1)
	trail.Size = UDim2.fromScale(math.clamp(trailStamina / maxStamina, 0, 1), 1)

	local targetColor = if exhausted then COLOR_EXHAUSTED elseif ratio < LOW_STAMINA_RATIO then COLOR_LOW else COLOR_NORMAL
	fill.BackgroundColor3 = fill.BackgroundColor3:Lerp(targetColor, 1 - math.exp(-10 * dt))

	local title = if exhausted then "WINDED" else "STAMINA"
	if titleLabel.Text ~= title then
		titleLabel.Text = title
		titleLabel.TextColor3 = if exhausted then COLOR_EXHAUSTED else Color3.fromRGB(235, 238, 245)
	end
	local valueText = tostring(math.round(displayedStamina))
	if valueLabel.Text ~= valueText then
		valueLabel.Text = valueText
	end

	if predictedSprinting or target < maxStamina - 0.5 then
		lastActiveTime = now
	end
	setBarVisible(char ~= nil and now - lastActiveTime < HIDE_DELAY)
end

local function onRenderStep(dt: number)
	local now = os.clock()
	local hum = humanoid
	local root = rootPart

	applySprinting(computeSprinting())

	local active = false
	local speedRatio = 1
	if hum and root then
		local velocity = root.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		-- Velocity rather than MoveDirection so click-to-move and scripted MoveTo also count.
		local moving = horizontalSpeed >= Config.MinMoveSpeed
		local state = hum:GetState()
		local grounded = state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics

		active = predictedSprinting and moving and grounded
		speedRatio = horizontalSpeed / Config.SprintSpeed

		if toggleMode and intent then
			if moving then
				idleSince = nil
			elseif not idleSince then
				idleSince = now
			elseif now - idleSince >= TOGGLE_IDLE_CANCEL_TIME then
				setIntent(false)
			end
		end
	end

	setSprintVisuals(active, speedRatio)
	updateBar(dt, now)
end

local boundKeys = table.clone(Config.KeyboardKeys)
table.move(Config.GamepadKeys, 1, #Config.GamepadKeys, #boundKeys + 1, boundKeys)
ContextActionService:BindActionAtPriority(
	ACTION_NAME,
	onAction,
	true,
	Enum.ContextActionPriority.High.Value,
	table.unpack(boundKeys)
)
ContextActionService:SetTitle(ACTION_NAME, "Sprint")
ContextActionService:SetPosition(ACTION_NAME, UDim2.new(1, -170, 1, -150))

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(function(oldCharacter)
	if character == oldCharacter then
		disconnectCharacter()
		setFov(false)
	end
end)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

RunService.RenderStepped:Connect(onRenderStep)
