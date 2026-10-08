--[[
	InventoryCamera  (client ModuleScript, next to PanelManager)
	Shows the player's LIVE character in the inventory instead of a duplicate: while the Inventory
	is open the camera locks onto the real character from a 3/4 front angle, framed so the character
	stands in the left part of the screen (above the stats panel) and faces the menu. The character
	keeps animating (idle, drawing the sword with E, ...). Movement stops the moment the panel opens, even if
	a key is held: a high-priority ContextActionService sink swallows new walk/jump presses, and every frame
	the humanoid's move input is forced to zero (the held key's state lives inside Roblox's control scripts,
	which a sink cannot reset). The cursor is freed.

	API (called by InventoryController):
		InventoryCamera.Enter()   take over the camera + block movement input
		InventoryCamera.Exit()    restore the previous camera, mouse and movement input

	The camera is bound after the combat camera (Camera priority + 5), so it overrides it while the
	panel is open; the combat camera carries on by itself once Exit() runs.
	Framing numbers are the constants below. See Docs.Inventory > CHARACTER VIEW.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- framing (tuned for the layout in Docs.Inventory)
local FOV = 40
local CHARACTER_HEIGHT_ON_SCREEN = 0.62 -- fraction of the screen height the character fills
local SCREEN_X = 0.2 -- where the character's center sits on screen (0 = left edge, 1 = right edge)
local SCREEN_Y = 0.37 -- ... and vertically (0 = top), above the stats panel
local YAW_DEGREES = 35 -- camera swings this far to the character's left so it turns toward the menu
local EASE_SPEED = 9 -- how fast the camera glides in / follows (higher = snappier)
local MIN_DISTANCE = 3 -- closest the camera may be pushed by a wall

local BIND_NAME = "InventoryCamera"
local FREEZE_ACTION = "InventoryFreezeMovement"
-- movement inputs swallowed while the inventory is open (combat keys such as E / Q are left alone)
local FROZEN_INPUTS = {
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
	Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.KeyCode.Thumbstick1,
}

local InventoryCamera = {}

local active = false
local saved: { cameraType: Enum.CameraType, cframe: CFrame, fov: number }? = nil
local current: CFrame? = nil
local characterHeight = 6

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- where the camera should be right now, from the character's live position and facing
local function targetCFrame(root: BasePart, viewportSize: Vector2): CFrame
	local halfTan = math.tan(math.rad(FOV) / 2)
	local distance = (characterHeight / CHARACTER_HEIGHT_ON_SCREEN) / (2 * halfTan)

	local facing = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	facing = if facing.Magnitude > 0.01 then facing.Unit else Vector3.new(0, 0, -1)
	local toCamera = CFrame.Angles(0, math.rad(-YAW_DEGREES), 0):VectorToWorldSpace(facing)
	local right = (-toCamera):Cross(Vector3.yAxis).Unit

	-- aim off to the right and below the character so it lands at (SCREEN_X, SCREEN_Y)
	local halfHeight = distance * halfTan
	local halfWidth = halfHeight * (viewportSize.X / viewportSize.Y)
	local center = root.Position
	local aim = center + right * ((0.5 - SCREEN_X) * 2 * halfWidth) - Vector3.yAxis * ((0.5 - SCREEN_Y) * 2 * halfHeight)

	-- don't sit inside a wall
	local character = player.Character
	raycastParams.FilterDescendantsInstances = if character then { character } else {}
	local hit = workspace:Raycast(aim, toCamera * distance, raycastParams)
	local usable = if hit then math.max(hit.Distance - 0.4, MIN_DISTANCE) else distance

	return CFrame.lookAt(aim + toCamera * usable, aim)
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not camera or not root then
		return
	end

	-- hold the character still: this runs after Roblox's control scripts, so it wins over a held key
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:Move(Vector3.zero)
		humanoid.Jump = false
	end

	-- override whatever the combat / default camera did this frame
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FOV
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	local target = targetCFrame(root, camera.ViewportSize)
	current = if current then current:Lerp(target, 1 - math.exp(-EASE_SPEED * dt)) else camera.CFrame
	camera.CFrame = current :: CFrame
end

function InventoryCamera.Enter()
	if active then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	active = true
	saved = { cameraType = camera.CameraType, cframe = camera.CFrame, fov = camera.FieldOfView }
	current = nil

	local character = player.Character
	if character then
		local _, size = character:GetBoundingBox()
		characterHeight = math.clamp(size.Y, 4, 9)
		-- stop sideways momentum right away (falling is left alone)
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local velocity = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
		end
	end

	ContextActionService:BindActionAtPriority(FREEZE_ACTION, function()
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, table.unpack(FROZEN_INPUTS))
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 5, update)
end

function InventoryCamera.Exit()
	if not active then
		return
	end
	active = false
	RunService:UnbindFromRenderStep(BIND_NAME)

	local camera = workspace.CurrentCamera
	if camera and saved then
		camera.CFrame = saved.cframe
		camera.FieldOfView = saved.fov
		camera.CameraType = saved.cameraType
	end
	saved = nil
	current = nil

	ContextActionService:UnbindAction(FREEZE_ACTION)
end

return InventoryCamera
