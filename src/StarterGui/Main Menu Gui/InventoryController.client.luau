local Players = game:GetService("Players")
local player = Players.LocalPlayer

local menuGui = script.Parent
local PanelManager = require(menuGui:WaitForChild("PanelManager"))
local dropdown = menuGui:WaitForChild("DropdownMenu")
local inventoryWrap = dropdown:WaitForChild("Wrap_Inventory Button")
local inventoryButton = inventoryWrap:WaitForChild("Inventory Button")
local panel = menuGui:WaitForChild("InventoryPanel")
local closeButton = panel.TitleBar:WaitForChild("CloseButton")

local equipPanel = panel.Body.EquipmentPanel
local avatarViewport = equipPanel:WaitForChild("AvatarViewport")
local nameLabel = equipPanel:WaitForChild("PlayerNameLabel")

local viewportWorld = nil -- WorldModel holding the cloned character, rebuilt each open
local viewportCamera = nil

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

local function clearAvatarPreview()
	if viewportWorld then
		viewportWorld:Destroy()
		viewportWorld = nil
	 end
	if viewportCamera then
		viewportCamera:Destroy()
		viewportCamera = nil
	end
end

local function buildAvatarPreview()
	clearAvatarPreview()

	local character = player.Character
	if not character then
		return
	end

	local originalRoot = character:FindFirstChild("HumanoidRootPart")
	if not originalRoot then
		return
	end

	viewportWorld = Instance.new("WorldModel")
	viewportWorld.Name = "PreviewWorld"
	viewportWorld.Parent = avatarViewport

	-- Build the preview from the character's current APPEARANCE (hair, clothes, equipped
	-- gear) rather than cloning the live character directly. Cloning the live character
	-- freezes whatever pose it happened to be in (mid-walk, mid-jump, etc.) at the exact
	-- moment the menu opened. CreateHumanoidModelFromDescription instead builds a brand
	-- new rig in a clean, neutral standing pose -- and as a bonus, this also sidesteps
	-- the Archivable=false issue entirely, since it's a fresh model, not a clone.
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local appearance = humanoid:GetAppliedDescription()
	local clone = Players:CreateHumanoidModelFromDescription(appearance, humanoid.RigType)
	clone.Parent = viewportWorld

	local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
	if not cloneRoot then
		return
	end

	-- No pose-freezing hack needed -- CreateHumanoidModelFromDescription already returns
	-- a rig in its default idle stance with no animations playing.

	viewportCamera = Instance.new("Camera")
	viewportCamera.Name = "PreviewCamera"
	viewportCamera.Parent = avatarViewport
	avatarViewport.CurrentCamera = viewportCamera

	-- Frame the FULL BODY, head-on: use the model's actual bounding box (robust to any
	-- rig type, height, or accessories) rather than a fixed distance, so nothing gets
	-- cropped. Stand in front of the character (along its own facing direction) and
	-- look back at its center, so we always see the front regardless of spawn orientation.
	local boundsCFrame, boundsSize = clone:GetBoundingBox()
	local focusPosition = boundsCFrame.Position
	local facing = cloneRoot.CFrame.LookVector

	-- Distance needed to fit the taller of (height, width) into the viewport's vertical
	-- FOV, plus ~25% padding so the character isn't touching the edges.
	local fovRad = math.rad(viewportCamera.FieldOfView)
	local neededDistance = (boundsSize.Y / 2) / math.tan(fovRad / 2)
	local distance = neededDistance * 1.6

	local cameraPosition = focusPosition + facing * distance
	viewportCamera.CFrame = CFrame.lookAt(cameraPosition, focusPosition)
end

local isOpen = false

local function closePanel()
	isOpen = false
	panel.Visible = false
	clearAvatarPreview()
end

local function openPanel()
	PanelManager.open("Inventory") -- close any other open HUD panel first
	isOpen = true
	panel.Visible = true
	nameLabel.Text = player.DisplayName
	buildAvatarPreview()
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
