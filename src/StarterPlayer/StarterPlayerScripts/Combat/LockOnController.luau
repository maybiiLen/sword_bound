--[[
	LockOnController  (client)
	Picks and tracks a lock-on target: any living Humanoid model within CombatConfig.LockOnRange
	that isn't you (and isn't another player while PvP is off). The best candidate is the one
	closest to the centre of the screen, weighted a little by distance.

	While locked: CameraController frames the target, MovementController turns you to face it
	(so movement becomes strafing) and a small marker is drawn on it. The lock breaks when the
	target dies, is removed, or goes past LockOnBreakRange.

	API:
		LockOnController:Start()
		LockOnController:Toggle()       lock the best target, or release
		LockOnController:Switch(dir)    dir = 1 (right) / -1 (left) on screen
		LockOnController:Clear()
		LockOnController.Target         Model?
		LockOnController.TargetPart     BasePart? (root part)
		LockOnController.Changed        Signal(target?)

	See Docs.Combat > "Lock-on".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)

local player = Players.LocalPlayer

local LockOnController = {
	Target = nil :: Model?,
	TargetPart = nil :: BasePart?,
	Changed = Signal.new(),
}

local marker: BillboardGui? = nil
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function rootOf(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model.PrimaryPart
	return if root and root:IsA("BasePart") then root else nil
end

local function isValid(model: Model?, range: number): boolean
	if not model or not model.Parent then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local root = rootOf(model)
	if not humanoid or humanoid.Health <= 0 or not root or not myRoot then
		return false
	end
	if not CombatConfig.PvPEnabled and Players:GetPlayerFromCharacter(model) then
		return false
	end
	return (root.Position - myRoot.Position).Magnitude <= range
end

local function candidates(): { Model }
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then
		return {}
	end
	overlapParams.FilterDescendantsInstances = { character }
	local seen: { [Model]: boolean } = {}
	local list = {}
	for _, part in workspace:GetPartBoundsInRadius(myRoot.Position, CombatConfig.LockOnRange, overlapParams) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not seen[model] then
			seen[model] = true
			if isValid(model, CombatConfig.LockOnRange) then
				table.insert(list, model)
			end
		end
	end
	return list
end

local function screenPoint(model: Model): (Vector3?, boolean)
	local camera = workspace.CurrentCamera
	local root = rootOf(model)
	if not camera or not root then
		return nil, false
	end
	local point, onScreen = camera:WorldToViewportPoint(root.Position)
	return point, onScreen and point.Z > 0
end

local function destroyMarker()
	if marker then
		marker:Destroy()
		marker = nil
	end
end

local function createMarker(part: BasePart)
	destroyMarker()
	local gui = Instance.new("BillboardGui")
	gui.Name = "LockOnMarker"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(16, 16)
	gui.Adornee = part
	gui.ResetOnSpawn = false
	local diamond = Instance.new("Frame")
	diamond.AnchorPoint = Vector2.new(0.5, 0.5)
	diamond.Position = UDim2.fromScale(0.5, 0.5)
	diamond.Size = UDim2.fromOffset(9, 9)
	diamond.Rotation = 45
	diamond.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	diamond.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 90)
	stroke.Thickness = 2
	stroke.Parent = diamond
	diamond.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	marker = gui
end

local function setTarget(model: Model?)
	if LockOnController.Target == model then
		return
	end
	LockOnController.Target = model
	LockOnController.TargetPart = if model then rootOf(model) else nil
	if model and LockOnController.TargetPart then
		local markerPart = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or LockOnController.TargetPart
		createMarker(markerPart :: BasePart)
	else
		destroyMarker()
	end
	LockOnController.Changed:Fire(model)
end

function LockOnController:Clear()
	setTarget(nil)
end

function LockOnController:Toggle()
	if self.Target then
		setTarget(nil)
		return
	end
	local camera = workspace.CurrentCamera
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not camera or not myRoot then
		return
	end
	local centre = camera.ViewportSize / 2
	local best, bestScore = nil, math.huge
	for _, model in candidates() do
		local point, visible = screenPoint(model)
		if point and visible then
			local root = rootOf(model) :: BasePart
			local screenDistance = (Vector2.new(point.X, point.Y) - centre).Magnitude / centre.Magnitude
			local worldDistance = (root.Position - myRoot.Position).Magnitude / CombatConfig.LockOnRange
			local score = screenDistance + worldDistance * 0.35
			if score < bestScore then
				best, bestScore = model, score
			end
		end
	end
	setTarget(best)
end

function LockOnController:Switch(direction: number)
	local current = self.Target
	if not current then
		return
	end
	local currentPoint = screenPoint(current)
	if not currentPoint then
		return
	end
	local best, bestDx = nil, math.huge
	for _, model in candidates() do
		if model ~= current then
			local point, visible = screenPoint(model)
			if point and visible then
				local dx = (point.X - currentPoint.X) * direction
				if dx > 0 and dx < bestDx then
					best, bestDx = model, dx
				end
			end
		end
	end
	if best then
		setTarget(best)
	end
end

function LockOnController:Start()
	RunService.Heartbeat:Connect(function()
		if self.Target and not isValid(self.Target, CombatConfig.LockOnBreakRange) then
			setTarget(nil)
		end
	end)
	player.CharacterRemoving:Connect(function()
		setTarget(nil)
	end)
end

return LockOnController
