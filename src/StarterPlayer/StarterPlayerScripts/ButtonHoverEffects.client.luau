local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HOVER_TIME = 0.12
local DARKEN_FACTOR = 0.82 -- how much to darken the background on hover (1 = no change)
local STROKE_TRANSPARENCY_BOOST = 0.25 -- how much more visible the border becomes on hover

local hoveredButtons = {} -- guards against double-wiring the same button twice

local function applyHoverEffect(button)
	if hoveredButtons[button] then
		return
	end
	hoveredButtons[button] = true

	local originalColor = button.BackgroundColor3
	local hasBackground = button.BackgroundTransparency < 1
	local darkColor = Color3.new(originalColor.R * DARKEN_FACTOR, originalColor.G * DARKEN_FACTOR, originalColor.B * DARKEN_FACTOR)

	local stroke = button:FindFirstChildOfClass("UIStroke")
	local originalStrokeTransparency = stroke and stroke.Transparency

	button.MouseEnter:Connect(function()
		if hasBackground then
			TweenService:Create(button, TweenInfo.new(HOVER_TIME), { BackgroundColor3 = darkColor }):Play()
		end
		if stroke then
			local target = math.clamp(originalStrokeTransparency - STROKE_TRANSPARENCY_BOOST, 0, 1)
			TweenService:Create(stroke, TweenInfo.new(HOVER_TIME), { Transparency = target }):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if hasBackground then
			TweenService:Create(button, TweenInfo.new(HOVER_TIME), { BackgroundColor3 = originalColor }):Play()
		end
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(HOVER_TIME), { Transparency = originalStrokeTransparency }):Play()
		end
	end)
end

local function scanAndApply(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			applyHoverEffect(descendant)
		end
	end
	root.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("GuiButton") then
			applyHoverEffect(descendant)
		end
	end)
end

-- Covers: main menu button, shop/inbox buttons, dropdown menu buttons,
-- equipment slots, item grid slots, mount slots, inventory tabs, close button --
-- every custom interactive button in the HUD and inventory.
local saoHud = playerGui:WaitForChild("SAO_HUD")
local mainMenuGui = playerGui:WaitForChild("Main Menu Gui")

scanAndApply(saoHud)
scanAndApply(mainMenuGui)
