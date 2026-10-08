--[[
	InventoryItemsController  (client LocalScript, next to InventoryController)
	Drives the Equipment screen of the Inventory panel (reference-style layout, dark theme):
		- Body.EquipmentPanel   character preview (InventoryController) + LevelLabel + StatsPanel
		                        (HP, Stamina, ATK are live; SP/DEF/STR/AGI/DEX/INT show "-" until
		                        those systems exist)
		- Body.SlotsPanel       SlotList rows (Weapon is live; Jacket/Gloves/Pants/Shield are empty
		                        placeholders) and the DetailCard of the selected item with an Equip button
		- Body.ItemsPanel       CategoryBar (only Swords exists), SearchBar, ItemGrid with one ItemSlot per
		                        owned weapon (3D icon + name), Footer (count, Sort; Lock is a placeholder)
	Click a grid weapon (or the Weapon row) to select it and see its details; press Equip to send
	EquipRemote("Equip", weaponId). The server (InventoryService + WeaponService) decides whether it
	is allowed; this script only displays what the server says. Owned weapons come from
	Inventory.Remotes (GetInventory / InventoryChanged), the equipped one from the character
	attribute CombatConfig.Attributes.EquippedWeapon.

	The grid slots are the pre-built ItemSlot1..N buttons; unused slots stay empty.
	ItemGrid is a normal scrolling frame. (PAGED_GRID is a fallback for a rotated panel, where Roblox cannot
	clip: it shows only the rows that fit and pages them with the mouse wheel; ScrollTrack shows the position.)
	Selection/equipped state is drawn with child Frames (SelectedMarker, EquippedBadge), never by
	recoloring a button, because ButtonHoverEffects tweens button colors on hover.
	The Main Menu Gui uses ZIndexBehavior.Global, so everything created inside a slot or card gets a
	ZIndex above its parent's. See Docs.Inventory.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local menuGui = script.Parent
local panel = menuGui:WaitForChild("InventoryPanel")
local body = panel:WaitForChild("Body")
local leftPanel = body:WaitForChild("EquipmentPanel")
local statsPanel = leftPanel:WaitForChild("StatsPanel")
local levelLabel = leftPanel:WaitForChild("LevelLabel")
local slotsPanel = body:WaitForChild("SlotsPanel")
local slotList = slotsPanel:WaitForChild("SlotList")
local card = slotsPanel:WaitForChild("DetailCard")
local itemsPanel = body:WaitForChild("ItemsPanel")
local itemGrid = itemsPanel:WaitForChild("ItemGrid")
local gridLayout = itemGrid:WaitForChild("UIGridLayout")
local searchBox = itemsPanel:WaitForChild("SearchBar"):WaitForChild("SearchBox")
local footer = itemsPanel:WaitForChild("Footer")

local Combat = ReplicatedStorage:WaitForChild("Combat")
local CombatConfig = require(Combat:WaitForChild("CombatConfig"))
local WeaponRegistry = require(Combat:WaitForChild("WeaponRegistry"))
local EquipRemote = Combat:WaitForChild("Remotes"):WaitForChild("EquipRemote")
local InventoryRemotes = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("Remotes")
local GetInventory = InventoryRemotes:WaitForChild("GetInventory") :: RemoteFunction
local InventoryChanged = InventoryRemotes:WaitForChild("InventoryChanged") :: RemoteEvent

local TEAL = Color3.fromRGB(40, 196, 188)
local TEXT = Color3.fromRGB(236, 240, 244)
local COLUMNS = 5
local TRACK_SPACE = 10 -- px kept free on the grid's right edge for ScrollTrack (paged mode only)
-- Roblox cannot clip rotated GUIs. PAGED_GRID = true makes the grid show only the rows that fit and
-- page by mouse wheel instead of native scrolling; use it ONLY if InventoryPanel is ever rotated again.
local PAGED_GRID = false
local GENERATED = { "Icon", "NameLabel", "EquippedBadge", "SelectedMarker" } -- children created inside a slot

local owned: { string } = {}
local fetched = false
local selectedRow = "Weapon" -- Weapon / Jacket / Gloves / Pants / Shield
local selectedWeapon: string? = nil
local sortAscending = true

-- ItemSlot1, ItemSlot2, ... in numeric order
local slots: { TextButton } = {}
for _, child in itemGrid:GetChildren() do
	if child:IsA("TextButton") and child.Name:match("^ItemSlot%d+$") then
		table.insert(slots, child)
	end
end
table.sort(slots, function(a, b)
	return tonumber(a.Name:match("%d+")) < tonumber(b.Name:match("%d+"))
end)
local slotWeapon: { [TextButton]: string } = {}
local scrollRow = 0 -- first row shown in the grid
local visibleRows = math.ceil(#slots / COLUMNS)
local visibleCount = #slots -- slots actually shown (visibleRows * COLUMNS), set by fitCells

local function displayName(weaponId: string): string
	local definition = WeaponRegistry.Get(weaponId)
	return definition and definition.DisplayName or weaponId
end

local function equippedId(): string?
	local character = player.Character
	local id = character and character:GetAttribute(CombatConfig.Attributes.EquippedWeapon)
	return if typeof(id) == "string" then id else nil
end

local function isOwned(weaponId: string?): boolean
	return weaponId ~= nil and table.find(owned, weaponId) ~= nil
end

--------------------------------------------------------------------------- icons

local function clearChildren(parent: GuiObject, names: { string })
	for _, name in names do
		local old = parent:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
end

-- 3D icon: the weapon model in a ViewportFrame, tilted so a long blade fits a square slot.
local function buildIcon(weaponId: string, holder: GuiObject, size: UDim2, position: UDim2)
	local template = WeaponRegistry.GetModel(weaponId)
	if not template then
		return
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Icon"
	viewport.BackgroundTransparency = 1
	viewport.Size = size
	viewport.Position = position
	viewport.ZIndex = holder.ZIndex + 1
	viewport.Ambient = Color3.fromRGB(170, 170, 170)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local model = template:Clone()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	-- blade runs along +Y and the crossguard along Z: look down the X axis and tilt around it
	model:PivotTo(CFrame.Angles(math.rad(-45), 0, 0))
	model.Parent = viewport

	local boxCFrame, boxSize = model:GetBoundingBox()
	local center = boxCFrame.Position
	local distance = math.max(boxSize.X, boxSize.Y, boxSize.Z) * 2.1
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(center + Vector3.new(distance, 0, 0), center)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	viewport.Parent = holder
end

local function outlineFrame(slot: GuiObject, name: string, strokeColor: Color3, fillTransparency: number): Frame
	local marker = Instance.new("Frame")
	marker.Name = name
	marker.BackgroundColor3 = strokeColor
	marker.BackgroundTransparency = fillTransparency
	marker.BorderSizePixel = 0
	marker.Size = UDim2.fromScale(1, 1)
	marker.ZIndex = slot.ZIndex + 4
	local corner = slot:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = marker
	end
	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = marker
	marker.Parent = slot
	return marker
end

local function fillSlot(slot: GuiObject, weaponId: string, isEquipped: boolean, isSelected: boolean)
	clearChildren(slot, GENERATED)
	buildIcon(weaponId, slot, UDim2.fromScale(0.84, 0.62), UDim2.fromScale(0.08, 0.04))

	local label = Instance.new("TextLabel")
	label.Name = "NameLabel"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.94, 0.26)
	label.Position = UDim2.fromScale(0.03, 0.7)
	label.Font = Enum.Font.GothamMedium
	label.Text = displayName(weaponId)
	label.TextColor3 = TEXT
	label.TextScaled = true
	label.ZIndex = slot.ZIndex + 2
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 13
	limit.MinTextSize = 4
	limit.Parent = label
	label.Parent = slot

	if isEquipped then
		local badge = Instance.new("TextLabel")
		badge.Name = "EquippedBadge"
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, -3, 0, 3)
		badge.Size = UDim2.fromScale(0.26, 0.22)
		badge.BackgroundColor3 = TEAL
		badge.BorderSizePixel = 0
		badge.Font = Enum.Font.GothamBold
		badge.Text = "E"
		badge.TextColor3 = Color3.fromRGB(10, 24, 26)
		badge.TextScaled = true
		badge.ZIndex = slot.ZIndex + 3
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 2)
		corner.Parent = badge
		badge.Parent = slot
	end

	if isSelected then
		outlineFrame(slot, "SelectedMarker", TEAL, 0.88)
	end
end

--------------------------------------------------------------------------- left: stats

local function setStat(name: string, value: string)
	local row = statsPanel:FindFirstChild("Stat_" .. name)
	if row then
		row.Value.Text = value
	end
end

local function updateStats()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		setStat("HP", string.format("%d / %d", math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5)))
	end
	-- Stamina attributes are set by the sprint system (see Docs.Sprint)
	local stamina = character and character:GetAttribute("Stamina")
	local maxStamina = character and character:GetAttribute("MaxStamina")
	if typeof(stamina) == "number" and typeof(maxStamina) == "number" then
		setStat("Stamina", string.format("%d / %d", math.floor(stamina + 0.5), math.floor(maxStamina + 0.5)))
	end
	local equipped = equippedId()
	local definition = equipped and WeaponRegistry.Get(equipped)
	setStat("ATK", definition and tostring(definition.Damage) or "-")

	local classGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("ClassGui")
	local classLevel = classGui and classGui:FindFirstChild("ClassFrame") and classGui.ClassFrame:FindFirstChild("LevelLabel")
	levelLabel.Text = classLevel and classLevel.Text or "Lv. -"
end

--------------------------------------------------------------------------- middle: slot list + detail card

local function setCardIcon(weaponId: string?)
	local iconBox = card:WaitForChild("IconBox")
	clearChildren(iconBox, { "Icon" })
	if weaponId then
		buildIcon(weaponId, iconBox, UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.05, 0.05))
	end
end

local function renderCard()
	local weaponId = if selectedRow == "Weapon" then selectedWeapon else nil
	local definition = weaponId and WeaponRegistry.Get(weaponId)
	local equipButton = card:WaitForChild("EquipButton")
	local dim = equipButton:WaitForChild("Dim")

	card.AtkLabel.Text = if selectedRow == "Weapon" then "Weapon ATK" else "Defense"
	card.ReachLabel.Visible = selectedRow == "Weapon"
	card.ReachValue.Visible = selectedRow == "Weapon"

	if definition then
		card.ItemName.Text = displayName(weaponId :: string)
		card.AtkValue.Text = tostring(definition.Damage)
		card.ReachValue.Text = tostring(definition.Reach)
	else
		card.ItemName.Text = if selectedRow == "Weapon" then "No weapon" else "Empty (" .. selectedRow .. ")"
		card.AtkValue.Text = "-"
		card.ReachValue.Text = "-"
	end
	setCardIcon(if definition then weaponId else nil)

	-- Equip: enabled only for an owned weapon that is not already equipped
	local canEquip = definition ~= nil and weaponId ~= equippedId() and isOwned(weaponId)
	equipButton.Text = if definition == nil then "Nothing to equip" elseif weaponId == equippedId() then "Equipped" else "Equip"
	dim.BackgroundTransparency = if canEquip then 1 else 0.1
	equipButton.TextTransparency = if canEquip then 0 else 0.5
end

local function renderRows()
	local equipped = equippedId()
	for _, row in slotList:GetChildren() do
		if row:IsA("TextButton") then
			local rowName = row.Name:gsub("^Row_", "")
			local isSelected = rowName == selectedRow
			local highlight = row:FindFirstChild("Highlight")
			if highlight then
				highlight.BackgroundTransparency = if isSelected then 0.6 else 1
				highlight.UIStroke.Transparency = if isSelected then 0 else 1
			end
			if rowName == "Weapon" then
				row.NameLabel.Text = if equipped and WeaponRegistry.Get(equipped) then displayName(equipped) else "Empty"
			end
		end
	end
end

--------------------------------------------------------------------------- right: grid

local function renderGrid()
	local equipped = equippedId()
	local query = string.lower(searchBox.Text)
	local visible: { string } = {}
	for _, weaponId in owned do
		if query == "" or string.find(string.lower(displayName(weaponId)), query, 1, true) then
			table.insert(visible, weaponId)
		end
	end
	table.sort(visible, function(a, b)
		if sortAscending then
			return displayName(a) < displayName(b)
		end
		return displayName(a) > displayName(b)
	end)

	-- whole rows only: show visibleRows rows starting at scrollRow
	local totalRows = math.max(1, math.ceil(#visible / COLUMNS))
	if PAGED_GRID then
		scrollRow = math.clamp(scrollRow, 0, math.max(0, totalRows - visibleRows))
	else
		scrollRow = 0
	end
	local offset = scrollRow * COLUMNS

	for index, slot in slots do
		local weaponId = if index <= visibleCount then visible[offset + index] else nil
		slotWeapon[slot] = weaponId
		if weaponId then
			fillSlot(slot, weaponId, weaponId == equipped, selectedRow == "Weapon" and weaponId == selectedWeapon)
		else
			clearChildren(slot, GENERATED)
		end
	end

	local track = itemsPanel:FindFirstChild("ScrollTrack")
	if track then
		track.Visible = PAGED_GRID and totalRows > visibleRows
		track.Thumb.Size = UDim2.fromScale(1, math.min(1, visibleRows / totalRows))
		track.Thumb.Position = UDim2.fromScale(0, scrollRow / totalRows)
	end

	footer.HeldCount.Text = string.format("%d/%d", #owned, #slots)
	footer.SortButton.Text = if sortAscending then "Sort: A-Z" else "Sort: Z-A"
end

-- square cells that fill the grid width (COLUMNS per row); show only the rows that fit completely
local function fitCells()
	local padding = itemGrid:FindFirstChildOfClass("UIPadding")
	local sidePadding = padding and (padding.PaddingLeft.Offset + padding.PaddingRight.Offset) or 0
	local verticalPadding = padding and (padding.PaddingTop.Offset + padding.PaddingBottom.Offset) or 0
	local gap = gridLayout.CellPadding.X.Offset
	local reserved = if PAGED_GRID then TRACK_SPACE else itemGrid.ScrollBarThickness
	local usable = itemGrid.AbsoluteSize.X - sidePadding - reserved - gap * (COLUMNS - 1)
	local cell = math.floor(usable / COLUMNS)
	if cell <= 8 then
		return
	end
	gridLayout.CellSize = UDim2.fromOffset(cell, cell)
	if PAGED_GRID then
		visibleRows = math.max(1, math.floor((itemGrid.AbsoluteSize.Y - verticalPadding + gap) / (cell + gap)))
		visibleCount = math.min(#slots, visibleRows * COLUMNS)
	else
		visibleRows = math.ceil(#slots / COLUMNS)
		visibleCount = #slots
	end
	for index, slot in slots do
		slot.Visible = index <= visibleCount
	end
	renderGrid()
end

--------------------------------------------------------------------------- refresh + input

local function refresh()
	local equipped = equippedId()
	if selectedWeapon == nil or not isOwned(selectedWeapon) then
		selectedWeapon = equipped
	end
	renderRows()
	renderGrid()
	renderCard()
	updateStats()
end

local function applySnapshot(snapshot: any): boolean
	if type(snapshot) == "table" and type(snapshot.Weapons) == "table" then
		owned = snapshot.Weapons
		fetched = true
		refresh()
		return true
	end
	return false
end

local function fetch()
	local ok, snapshot = pcall(function()
		return GetInventory:InvokeServer()
	end)
	if ok then
		applySnapshot(snapshot)
	end
end

for _, slot in slots do
	slot.MouseButton1Click:Connect(function()
		local weaponId = slotWeapon[slot]
		if weaponId then
			selectedRow = "Weapon"
			selectedWeapon = weaponId
			refresh()
		end
	end)
end

for _, row in slotList:GetChildren() do
	if row:IsA("TextButton") then
		row.MouseButton1Click:Connect(function()
			selectedRow = row.Name:gsub("^Row_", "")
			if selectedRow == "Weapon" then
				selectedWeapon = equippedId()
			end
			refresh()
		end)
	end
end

card:WaitForChild("EquipButton").MouseButton1Click:Connect(function()
	local weaponId = selectedWeapon
	if selectedRow == "Weapon" and weaponId and isOwned(weaponId) and weaponId ~= equippedId() then
		EquipRemote:FireServer("Equip", weaponId)
	end
end)

footer:WaitForChild("SortButton").MouseButton1Click:Connect(function()
	sortAscending = not sortAscending
	renderGrid()
end)

InventoryChanged.OnClientEvent:Connect(applySnapshot)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	scrollRow = 0
	renderGrid()
end)
itemGrid:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCells)

-- mouse wheel: one grid row per notch while the Equipment tab is open (renderGrid clamps the row)
UserInputService.InputChanged:Connect(function(input: InputObject)
	if PAGED_GRID and input.UserInputType == Enum.UserInputType.MouseWheel and panel.Visible and body.Visible then
		scrollRow -= math.sign(input.Position.Z)
		renderGrid()
	end
end)

-- while the panel is open, keep HP / Stamina live
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if not panel.Visible then
		return
	end
	selectedRow = "Weapon"
	selectedWeapon = equippedId()
	scrollRow = 0
	if not fetched then
		task.spawn(fetch)
	end
	fitCells()
	refresh()
	task.spawn(function()
		while panel.Visible do
			updateStats()
			task.wait(0.25)
		end
	end)
end)

local attributeConnection: RBXScriptConnection?
local function bindCharacter(character: Model)
	if attributeConnection then
		attributeConnection:Disconnect()
	end
	attributeConnection = character:GetAttributeChangedSignal(CombatConfig.Attributes.EquippedWeapon):Connect(refresh)
	refresh()
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	bindCharacter(player.Character)
end

fitCells()
refresh()
task.spawn(fetch)
