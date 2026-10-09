--[[
	InventoryItemsController  (client LocalScript, next to InventoryController)
	Drives the Equipment screen of the Inventory panel (reference-style layout, dark theme):
		- Body.EquipmentPanel   character preview (InventoryController) + LevelLabel + StatsPanel
		                        (HP, Stamina, ATK are live; SP/DEF/STR/AGI/DEX/INT show "-" until
		                        those systems exist)
		- Body.SlotsPanel       SlotList rows (Weapon is live; Jacket/Gloves/Pants/Shield are empty
		                        placeholders) and the DetailCard of the selected item with an Equip button
		- Body.ItemsPanel       FilterBar (Filter by weapon class + Sort dropdowns; everything lives in ONE
		                        list, there are no category tabs), SearchBar, ItemGrid with one ItemSlot per
		                        owned weapon (3D icon + name), Footer (count; Lock is a placeholder)
		                        Filter options come from the classes in WeaponRegistry, so a new weapon class
		                        shows up in the Filter menu on its own.
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
local filterBar = itemsPanel:WaitForChild("FilterBar")
local filterButton = filterBar:WaitForChild("FilterButton") :: TextButton
local sortButton = filterBar:WaitForChild("SortButton") :: TextButton

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
local filterClass: string? = nil -- nil = show every weapon class
local sortIndex = 1 -- index into SORTS

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

local function classOf(weaponId: string): string
	local definition = WeaponRegistry.Get(weaponId)
	return definition and definition.Class or "Other"
end

local function classLabel(className: string): string
	return className .. "s" -- Sword -> Swords
end

local function damageOf(weaponId: string): number
	local definition = WeaponRegistry.Get(weaponId)
	return definition and definition.Damage or 0
end

-- Sort menu entries; ties fall back to the name so the order is always stable
local SORTS: { { Label: string, Less: (string, string) -> boolean } } = {
	{ Label = "Name A-Z", Less = function(a, b) return displayName(a) < displayName(b) end },
	{ Label = "Name Z-A", Less = function(a, b) return displayName(a) > displayName(b) end },
	{
		Label = "ATK High-Low",
		Less = function(a, b)
			if damageOf(a) ~= damageOf(b) then
				return damageOf(a) > damageOf(b)
			end
			return displayName(a) < displayName(b)
		end,
	},
	{
		Label = "ATK Low-High",
		Less = function(a, b)
			if damageOf(a) ~= damageOf(b) then
				return damageOf(a) < damageOf(b)
			end
			return displayName(a) < displayName(b)
		end,
	},
}

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Name = "EmptyLabel"
emptyLabel.BackgroundTransparency = 1
emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
emptyLabel.Position = UDim2.fromScale(0.5, 0.26)
emptyLabel.Size = UDim2.fromScale(0.8, 0.05)
emptyLabel.Font = Enum.Font.GothamMedium
emptyLabel.Text = "No weapons found"
emptyLabel.TextColor3 = Color3.fromRGB(150, 158, 166)
emptyLabel.TextScaled = true
emptyLabel.ZIndex = itemGrid.ZIndex + 2
emptyLabel.Visible = false
local emptyLimit = Instance.new("UITextSizeConstraint")
emptyLimit.MaxTextSize = 14
emptyLimit.MinTextSize = 4
emptyLimit.Parent = emptyLabel
emptyLabel.Parent = itemsPanel

local function updateToolbar()
	filterButton.Text = "Filter: " .. (if filterClass then classLabel(filterClass) else "All")
	sortButton.Text = "Sort: " .. SORTS[sortIndex].Label
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
		local matchesFilter = filterClass == nil or classOf(weaponId) == filterClass
		local matchesSearch = query == "" or string.find(string.lower(displayName(weaponId)), query, 1, true)
		if matchesFilter and matchesSearch then
			table.insert(visible, weaponId)
		end
	end
	table.sort(visible, SORTS[sortIndex].Less)

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
	emptyLabel.Visible = #visible == 0
	updateToolbar()
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

--------------------------------------------------------------------------- Filter / Sort dropdowns

local MENU_Z = 40 -- above everything in the panel (the Main Menu Gui uses ZIndexBehavior.Global)
local menuFrame: Frame? = nil
local menuBlocker: TextButton? = nil

local function closeMenu()
	if menuFrame then
		menuFrame:Destroy()
		menuFrame = nil
	end
	if menuBlocker then
		menuBlocker:Destroy()
		menuBlocker = nil
	end
end

-- Drops a small list under `owner`. A transparent full-panel button behind it closes the menu on any outside click.
local function openMenu(owner: GuiObject, labels: { string }, currentIndex: number, onPick: (number) -> ())
	closeMenu()

	local blocker = Instance.new("TextButton")
	blocker.Name = "DropdownBlocker"
	blocker.BackgroundTransparency = 1
	blocker.Text = ""
	blocker.AutoButtonColor = false
	blocker.Size = UDim2.fromScale(1, 1)
	blocker.ZIndex = MENU_Z - 1
	blocker.MouseButton1Click:Connect(closeMenu)
	blocker.Parent = panel
	menuBlocker = blocker

	local panelSize = panel.AbsoluteSize
	local rel = owner.AbsolutePosition - panel.AbsolutePosition
	local menu = Instance.new("Frame")
	menu.Name = "DropdownMenu"
	menu.BackgroundColor3 = Color3.fromRGB(26, 29, 34)
	menu.BorderSizePixel = 0
	menu.ZIndex = MENU_Z
	menu.Position = UDim2.fromScale(rel.X / panelSize.X, (rel.Y + owner.AbsoluteSize.Y + 2) / panelSize.Y)
	menu.Size = UDim2.fromScale(owner.AbsoluteSize.X / panelSize.X, owner.AbsoluteSize.Y * #labels / panelSize.Y)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 78, 90)
	stroke.Thickness = 1
	stroke.Parent = menu
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = menu

	for index, label in labels do
		local row = Instance.new("TextButton")
		row.Name = "Option" .. index
		row.LayoutOrder = index
		row.Size = UDim2.fromScale(1, 1 / #labels)
		row.BackgroundColor3 = Color3.fromRGB(34, 38, 45)
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		row.Font = Enum.Font.GothamMedium
		row.Text = label
		row.TextColor3 = if index == currentIndex then TEAL else TEXT
		row.TextScaled = true
		row.ZIndex = MENU_Z + 1
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 13
		limit.MinTextSize = 4
		limit.Parent = row
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.2, 0)
		pad.PaddingBottom = UDim.new(0.2, 0)
		pad.Parent = row
		row.MouseButton1Click:Connect(function()
			closeMenu()
			onPick(index)
		end)
		row.Parent = menu
	end
	menu.Parent = panel
	menuFrame = menu
end

filterButton.MouseButton1Click:Connect(function()
	-- one entry per weapon class that exists in the game, plus "All"
	local classes: { string } = {}
	for _, definition in WeaponRegistry.GetAll() do
		if not table.find(classes, definition.Class) then
			table.insert(classes, definition.Class)
		end
	end
	table.sort(classes)

	local labels = { "All" }
	local values: { string? } = { nil }
	local current = 1
	for _, className in classes do
		table.insert(labels, classLabel(className))
		values[#labels] = className
		if className == filterClass then
			current = #labels
		end
	end
	openMenu(filterButton, labels, current, function(index)
		filterClass = values[index]
		scrollRow = 0
		renderGrid()
	end)
end)

sortButton.MouseButton1Click:Connect(function()
	local labels = {}
	for _, entry in SORTS do
		table.insert(labels, entry.Label)
	end
	openMenu(sortButton, labels, sortIndex, function(index)
		sortIndex = index
		renderGrid()
	end)
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
	closeMenu()
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

