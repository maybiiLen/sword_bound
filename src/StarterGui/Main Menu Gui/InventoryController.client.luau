--[[
	InventoryController  (client LocalScript)
	Opens / closes the Inventory panel from the dropdown button and keeps the item grid's
	CanvasSize correct. The character is no longer shown as a duplicate in a ViewportFrame:
	opening the panel hands the camera to InventoryCamera, which frames the LIVE character at
	the left of the screen, and InventoryWeaponDisplay draws the equipped weapon into its hand
	(see Docs.Inventory > CHARACTER VIEW). The panel's contents are driven
	by InventoryItemsController / InventoryTabController, other HUDs are hidden by InventoryHudHider.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local menuGui = script.Parent
local PanelManager = require(menuGui:WaitForChild("PanelManager"))
local InventoryCamera = require(menuGui:WaitForChild("InventoryCamera"))
local InventoryWeaponDisplay = require(menuGui:WaitForChild("InventoryWeaponDisplay"))
local dropdown = menuGui:WaitForChild("DropdownMenu")
local inventoryWrap = dropdown:WaitForChild("Wrap_Inventory Button")
local inventoryButton = inventoryWrap:WaitForChild("Inventory Button")
local panel = menuGui:WaitForChild("InventoryPanel")
-- Always start closed, even if the panel was left visible in Studio while editing the layout. A panel
-- that starts visible never goes through openPanel(): no camera lock, and the HUD would be hidden from
-- the first frame with the menu button out of reach.
panel.Visible = false
local closeButton = panel.TitleBar:WaitForChild("CloseButton")

local equipPanel = panel.Body.EquipmentPanel
local nameLabel = equipPanel:WaitForChild("PlayerNameLabel")

-- AutomaticCanvasSize on the item grid doesn't reliably pick up the true content height
-- here (a UIGridLayout + UIPadding combination that under-reports its own size), so the
-- grid was clipping the bottom rows with no way to scroll to them. Compute CanvasSize
-- manually instead, and keep it live so it still works if slots are added/removed later.
local itemGrid = panel.Body.ItemsPanel:WaitForChild("ItemGrid")
local itemGridLayout = itemGrid:WaitForChild("UIGridLayout")
local itemGridPadding = itemGrid:FindFirstChildOfClass("UIPadding")

local function fixItemGridCanvasSize()
	itemGrid.AutomaticCanvasSize = Enum.AutomaticSize.None
	local extraY = 0
	if itemGridPadding then
		-- Resolve each UDim properly (Scale * parent size + Offset) instead of assuming
		-- Offset alone, since these can be set either way.
		local parentHeight = itemGrid.AbsoluteSize.Y
		local topPad = itemGridPadding.PaddingTop.Scale * parentHeight + itemGridPadding.PaddingTop.Offset
		local bottomPad = itemGridPadding.PaddingBottom.Scale * parentHeight + itemGridPadding.PaddingBottom.Offset
		extraY = topPad + bottomPad
	end
	-- Small safety buffer on top of the exact measurement, so rounding never re-clips the last row.
	itemGrid.CanvasSize = UDim2.new(0, 0, 0, itemGridLayout.AbsoluteContentSize.Y + extraY + 6)
end

fixItemGridCanvasSize()
itemGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fixItemGridCanvasSize)

local isOpen = false

local function closePanel()
	isOpen = false
	panel.Visible = false
	InventoryCamera.Exit()
	InventoryWeaponDisplay.Exit() -- sheathe again if it was sheathed before the inventory opened
end

local function openPanel()
	PanelManager.open("Inventory") -- close any other open HUD panel first
	isOpen = true
	panel.Visible = true
	nameLabel.Text = player.DisplayName
	InventoryCamera.Enter()
	InventoryWeaponDisplay.Enter() -- show the equipped weapon in the character's hand
end

PanelManager.register("Inventory", closePanel)

inventoryButton.MouseButton1Click:Connect(function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)
