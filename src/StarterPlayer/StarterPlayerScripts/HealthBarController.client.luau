local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("SAO_HUD")
local hudRoot = hud:WaitForChild("HUDRoot")

-- NOTE: Screen scaling is handled by the HUD's own layout (aspect ratio constraints
-- set up in Studio), so this script intentionally doesn't touch any UIScale.

local container = hudRoot:WaitForChild("HealthBarContainer")
local nameLabel = hudRoot:WaitForChild("PlayerNameLabel")
local barBack = container:WaitForChild("BarBack")
local fill = barBack:WaitForChild("Fill")
local hpText = barBack:WaitForChild("HPText")

nameLabel.Text = player.DisplayName

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
