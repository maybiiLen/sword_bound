local menuGui = script.Parent
local PanelManager = require(menuGui:WaitForChild("PanelManager"))
local dropdown = menuGui:WaitForChild("DropdownMenu")
local settingsWrap = dropdown:WaitForChild("Wrap_Settings Button")
local settingsButton = settingsWrap:WaitForChild("Settings Button")
local panel = menuGui:WaitForChild("SettingsPanel")
local closeButton = panel.TitleBar:WaitForChild("CloseButton")

local isOpen = false

local function closePanel()
	isOpen = false
	panel.Visible = false
end

local function openPanel()
	PanelManager.open("Settings") -- close any other open HUD panel first
	isOpen = true
	panel.Visible = true
end

PanelManager.register("Settings", closePanel)

settingsButton.MouseButton1Click:Connect(function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)

-- Simple visual toggle-switch behavior for each placeholder setting row.
local TOGGLE_ON = Color3.fromRGB(255, 193, 7)
local TOGGLE_OFF = Color3.fromRGB(210, 210, 210)

local function wireToggle(toggle)
	local knob = toggle:WaitForChild("Knob")
	local isOn = false
	toggle.MouseButton1Click:Connect(function()
		isOn = not isOn
		toggle.BackgroundColor3 = isOn and TOGGLE_ON or TOGGLE_OFF
		knob.Position = isOn and UDim2.new(0.94, 0, 0.5, 0) or UDim2.new(0.06, 0, 0.5, 0)
		knob.AnchorPoint = isOn and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
	end)
end

for _, row in ipairs(panel.Body:GetChildren()) do
	if row:IsA("Frame") and row.Name:match("^Row_") then
		local toggle = row:FindFirstChild("Toggle")
		if toggle then
			wireToggle(toggle)
		end
	end
end
