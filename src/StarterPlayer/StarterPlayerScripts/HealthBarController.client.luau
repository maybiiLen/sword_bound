local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("SAO_HUD")
local hudRoot = hud:WaitForChild("HUDRoot")
local uiScale = hudRoot:WaitForChild("HUDScale")

local camera = workspace.CurrentCamera

-- The HUD was designed against this reference resolution.
-- Everything scales up/down from here so it looks the same relative size
-- on any screen (desktop, laptop, tablet, phone).
local BASE_RESOLUTION = Vector2.new(1280, 720)
local MIN_SCALE = 0.3
local MAX_SCALE = 1.6

local function updateHUDScale()
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return
	end

	-- Scale by the smaller of the two ratios so the HUD never overflows
	-- the screen on unusually narrow or short aspect ratios (e.g. mobile).
	local scaleX = viewport.X / BASE_RESOLUTION.X
	local scaleY = viewport.Y / BASE_RESOLUTION.Y
	local scale = math.min(scaleX, scaleY)

	scale = math.clamp(scale, MIN_SCALE, MAX_SCALE)
	uiScale.Scale = scale
end

updateHUDScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHUDScale)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	updateHUDScale()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHUDScale)
end)

local container = hudRoot:WaitForChild("HealthBarContainer")
local nameLabel = hudRoot:WaitForChild("PlayerNameLabel")
local barBack = container:WaitForChild("BarBack")
local fill = barBack:WaitForChild("Fill")
local hpText = barBack:WaitForChild("HPText")

nameLabel.Text = player.Name

local TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateHealthBar(humanoid)
	local health = math.max(humanoid.Health, 0)
	local maxHealth = humanoid.MaxHealth
	local ratio = maxHealth > 0 and (health / maxHealth) or 0

	local targetSize = UDim2.new(ratio, 0, 1, 0)
	TweenService:Create(fill, TWEEN_INFO, {Size = targetSize}):Play()

	-- Color shifts as health drops: cyan -> yellow -> red, SAO-ish warning feel
	local color
	if ratio > 0.5 then
		color = Color3.fromRGB(107, 214, 11) -- green (matches user-set Fill color)
	elseif ratio > 0.25 then
		color = Color3.fromRGB(255, 210, 60) -- amber warning
	else
		color = Color3.fromRGB(255, 70, 70) -- critical red
	end
	TweenService:Create(fill, TWEEN_INFO, {BackgroundColor3 = color}):Play()

	hpText.Text = string.format("%d / %d", math.floor(health + 0.5), math.floor(maxHealth + 0.5))
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Initialize immediately
	updateHealthBar(humanoid)

	humanoid.HealthChanged:Connect(function()
		updateHealthBar(humanoid)
	end)

	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateHealthBar(humanoid)
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
