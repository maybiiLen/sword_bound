local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local menuGui = script.Parent
local PanelManager = require(menuGui:WaitForChild("PanelManager"))
local panel = menuGui:WaitForChild("InboxPanel")
local closeButton = panel.TitleBar:WaitForChild("CloseButton")

-- The Inbox button lives under SAO_HUD, not Main Menu Gui.
local saoHud = playerGui:WaitForChild("SAO_HUD")
local inboxButton = saoHud:WaitForChild("Inbox Button")

local isOpen = false

local function closePanel()
	isOpen = false
	panel.Visible = false
end

local function openPanel()
	PanelManager.open("Inbox") -- close any other open HUD panel first
	isOpen = true
	panel.Visible = true
end

PanelManager.register("Inbox", closePanel)

inboxButton.MouseButton1Click:Connect(function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)
