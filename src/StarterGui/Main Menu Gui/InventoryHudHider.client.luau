--[[
	InventoryHudHider  (client LocalScript, next to InventoryController)
	While the Inventory panel is open, hides every other HUD and menu so only the inventory is
	on screen, and puts them back exactly as they were when it closes:
		- the other ScreenGuis in PlayerGui (SAO_HUD, SprintGui, ClassGui, AbilityHud, ...)
		- the HUD part of this Main Menu Gui (the menu button; see HIDE_IN_MENU_GUI)
		- Roblox's own CoreGui (chat, player list, backpack, health, emotes)
	Roblox's top-left menu buttons cannot be hidden by scripts. TouchGui (Roblox mobile controls)
	is left alone (KEEP). Only things that were visible are hidden, and only those are restored.
	See Docs.Inventory.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local menuGui = script.Parent
local panel = menuGui:WaitForChild("InventoryPanel")

local KEEP = { TouchGui = true, Freecam = true }
-- Only the persistent menu button is hidden. The dropdown and the other panels close themselves
-- (DropdownController / PanelManager) when the inventory opens, so they must not be touched here:
-- restoring one of them would re-open something that closed on its own.
local HIDE_IN_MENU_GUI = { "Main Menu" }
local CORE_TYPES = {
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.EmotesMenu,
}

local hidden = false
local hiddenGuis: { ScreenGui } = {}
local hiddenObjects: { GuiObject } = {}
local savedCore: { [Enum.CoreGuiType]: boolean } = {}

local function hideScreenGui(gui: Instance)
	if gui:IsA("ScreenGui") and gui ~= menuGui and gui.Enabled and not KEEP[gui.Name] then
		table.insert(hiddenGuis, gui)
		gui.Enabled = false
	end
end

local function hideOthers()
	if hidden then
		return
	end
	hidden = true
	for _, gui in playerGui:GetChildren() do
		hideScreenGui(gui)
	end
	for _, name in HIDE_IN_MENU_GUI do
		local child = menuGui:FindFirstChild(name)
		if child and child:IsA("GuiObject") and child.Visible then
			table.insert(hiddenObjects, child)
			child.Visible = false
		end
	end
	for _, coreType in CORE_TYPES do
		savedCore[coreType] = StarterGui:GetCoreGuiEnabled(coreType)
		if savedCore[coreType] then
			pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreType, false)
		end
	end
end

local function restoreOthers()
	if not hidden then
		return
	end
	hidden = false
	for _, gui in hiddenGuis do
		if gui.Parent then
			gui.Enabled = true
		end
	end
	for _, object in hiddenObjects do
		if object.Parent then
			object.Visible = true
		end
	end
	for coreType, wasEnabled in savedCore do
		if wasEnabled then
			pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreType, true)
		end
	end
	table.clear(hiddenGuis)
	table.clear(hiddenObjects)
	table.clear(savedCore)
end

-- a HUD respawned (ResetOnSpawn) while the inventory is open stays hidden too
playerGui.ChildAdded:Connect(function(child)
	if hidden then
		hideScreenGui(child)
	end
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		hideOthers()
	else
		restoreOthers()
	end
end)

if panel.Visible then
	hideOthers()
end
