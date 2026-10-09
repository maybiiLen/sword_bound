--[[
	GrowthController  (client LocalScript, next to InventoryController)
	The Growth screen: opens from the person button ("Upgrades Button") in the dropdown menu and
	shows the player's attributes (VIT END MND STR DEX AGI INT), Growth Points, derived stats
	(HP, Stamina, SP, ATK, DEF), the Bonus Modifier ladder of the selected attribute, and the
	equipped weapon. Layout instances live in StarterGui.Main Menu Gui.GrowthPanel; this script only
	fills them in.

	Flow: click an attribute row to select it, use the arrows to PLAN points (shown in blue, nothing
	is saved), then "Spend Points" asks the server (Growth.Remotes.SpendRemote) to commit them.
	"Undo Changes" drops the plan; "Reset Points" refunds every spent point (ResetRemote).

	Reads (all replicated by the server, see GrowthConfig.PlayerAttributes):
		Player attributes GrowthPoints, Growth_<AttrId>, ClassLevel, Col (optional, 0 if absent)
		Character attribute EquippedWeapon

	Opening reuses InventoryCamera (frames the live character at the left and freezes movement),
	and InventoryHudHider hides the other HUDs while GrowthPanel is visible. See Docs.Growth.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local menuGui = script.Parent
local PanelManager = require(menuGui:WaitForChild("PanelManager"))
local InventoryCamera = require(menuGui:WaitForChild("InventoryCamera"))

local GrowthConfig = require(ReplicatedStorage:WaitForChild("Growth"):WaitForChild("GrowthConfig"))
local Remotes = ReplicatedStorage.Growth:WaitForChild("Remotes")
local SpendRemote = Remotes:WaitForChild("SpendRemote") :: RemoteFunction
local ResetRemote = Remotes:WaitForChild("ResetRemote") :: RemoteFunction
local WeaponRegistry = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("WeaponRegistry"))
local CombatConfig = require(ReplicatedStorage.Combat:WaitForChild("CombatConfig"))
local ClassConfig = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("ClassConfig"))

local dropdown = menuGui:WaitForChild("DropdownMenu")
local openButton = dropdown:WaitForChild("Wrap_Upgrades Button"):WaitForChild("Upgrades Button")

local panel = menuGui:WaitForChild("GrowthPanel")
panel.Visible = false -- always start closed, even if it was left visible in Studio
local canvas = panel:WaitForChild("Canvas")
local closeButton = canvas:WaitForChild("CloseButton")
local pointsValue = canvas:WaitForChild("GrowthPointsBar"):WaitForChild("Value")
local colValue = canvas:WaitForChild("ColBox"):WaitForChild("ColValue")
local redistValue = canvas:WaitForChild("RedistBox"):WaitForChild("Value")
local attributeList = canvas:WaitForChild("AttributeList")
local statsBlock = canvas:WaitForChild("StatsBlock")
local modPanel = canvas:WaitForChild("ModPanel")
local weaponCard = canvas:WaitForChild("WeaponCard")
local spendButton = canvas:WaitForChild("SpendButton")
local resetButton = canvas:WaitForChild("ResetButton")
local backButton = canvas:WaitForChild("BackButton")
local feedback = canvas:WaitForChild("Feedback")

local CREAM = Color3.fromRGB(233, 229, 216)
local CREAM_TEXT = Color3.fromRGB(62, 60, 54)
local ROW = Color3.fromRGB(118, 112, 102)
local TEAL = Color3.fromRGB(76, 196, 208)
local DIM = Color3.fromRGB(176, 172, 162)
local WHITE = Color3.new(1, 1, 1)
local BLUE_ON_DARK = "#7aa2ff"
local BLUE_ON_LIGHT = "#2f5ee0"
local ARROW = "\u{2192}"

local PointsAttribute = GrowthConfig.PlayerAttributes.Points
local AttributePrefix = GrowthConfig.PlayerAttributes.Prefix

local selectedId = GrowthConfig.Attributes[1].Id
local pending: { [string]: number } = {} -- planned, not yet saved
local isOpen = false
local busy = false
local feedbackToken = 0

-- Data helpers -------------------------------------------------------------------------------

local function allocatedNow(): { [string]: number }
	local alloc = {}
	for _, def in GrowthConfig.Attributes do
		alloc[def.Id] = player:GetAttribute(AttributePrefix .. def.Id) or 0
	end
	return alloc
end

local function pendingTotal(): number
	local total = 0
	for _, amount in pending do
		total += amount
	end
	return total
end

local function spentTotal(alloc: { [string]: number }): number
	local total = 0
	for _, amount in alloc do
		total += amount
	end
	return total
end

local function plannedAllocation(alloc: { [string]: number }): { [string]: number }
	local planned = {}
	for id, amount in alloc do
		planned[id] = amount + (pending[id] or 0)
	end
	return planned
end

local function equippedWeapon()
	local character = player.Character
	local id = character and character:GetAttribute(CombatConfig.Attributes.EquippedWeapon)
	return id and WeaponRegistry.Get(id) or nil
end

local function showFeedback(text: string)
	feedbackToken += 1
	local token = feedbackToken
	feedback.Text = text
	task.delay(3, function()
		if token == feedbackToken then
			feedback.Text = ""
		end
	end)
end

-- Drawing ----------------------------------------------------------------------------------------

local function setButtonLook(button: TextButton, enabled: boolean, highlight: boolean?)
	if enabled then
		button.BackgroundColor3 = if highlight then TEAL else CREAM
		button.TextColor3 = if highlight then WHITE else CREAM_TEXT
	else
		button.BackgroundColor3 = ROW
		button.TextColor3 = DIM
	end
end

local function setStat(key: string, current: number, new: number, detail: string?)
	local row = statsBlock:FindFirstChild("Stat_" .. key)
	if not row then
		return
	end
	row.Value.Text = tostring(current)
	row.Detail.Text = detail or ""
	row.New.Text = if new ~= current then `{ARROW} {new}` else ""
end

local function refresh()
	if not isOpen then
		return
	end

	local alloc = allocatedNow()
	local planned = plannedAllocation(alloc)
	local available = player:GetAttribute(PointsAttribute) or 0
	local remaining = available - pendingTotal()

	-- header numbers
	if pendingTotal() > 0 then
		pointsValue.Text = `{available} {ARROW} <font color="{BLUE_ON_LIGHT}">{remaining}</font>`
	else
		pointsValue.Text = tostring(available)
	end
	colValue.Text = tostring(player:GetAttribute("Col") or 0)
	redistValue.Text = `{GrowthConfig.ResetCost} Col`

	-- attribute rows
	for _, def in GrowthConfig.Attributes do
		local row = attributeList:FindFirstChild("Row_" .. def.Id)
		if row then
			local selected = def.Id == selectedId
			local planPoints = pending[def.Id] or 0
			local value = 1 + alloc[def.Id]
			local newValue = value + planPoints

			row.BackgroundColor3 = if selected then TEAL else ROW
			row.BackgroundTransparency = if selected then 0.05 else 0.2
			row.Description.Visible = selected
			row.Minus.Visible = selected
			row.Plus.Visible = selected
			row.CurrentValue.Text = tostring(value)
			row.NewValue.Text = tostring(newValue)
			row.NewValue.TextColor3 = if planPoints > 0 then Color3.fromRGB(70, 110, 245) else CREAM
			row.NameLabel.TextColor3 = if selected then WHITE else CREAM

			local canMinus = planPoints > 0
			local canPlus = remaining > 0 and newValue < GrowthConfig.MaxAttribute
			row.Minus.TextTransparency = if canMinus then 0 else 0.65
			row.Plus.TextTransparency = if canPlus then 0 else 0.65
		end
	end

	-- derived stats (current vs planned)
	local weapon = equippedWeapon()
	local weaponAtk = weapon and weapon.Damage or 0
	local weaponClass = weapon and weapon.Class or nil
	local now = GrowthConfig.ComputeStats(alloc, weaponAtk, weaponClass)
	local after = GrowthConfig.ComputeStats(planned, weaponAtk, weaponClass)

	statsBlock.LevelLabel.Text = `Lv. {player:GetAttribute(ClassConfig.Attributes.Level) or 1}`
	setStat("HP", now.HP, after.HP)
	setStat("STA", now.STA, after.STA)
	setStat("SP", now.SP, after.SP)
	setStat(
		"ATK",
		now.ATK,
		after.ATK,
		`({now.AtkBase} +{now.AtkAcv} <font color="#ff6b6b">ACV</font> +{now.AtkMod} <font color="#c58cff">MOD</font>)`
	)
	setStat("DEF", now.DEF, after.DEF, `({now.DefBase} +{now.DefMod} <font color="#c58cff">MOD</font>)`)

	-- bonus modifier ladder for the selected attribute (previewing planned points)
	modPanel.AttrCode.Text = selectedId
	local plannedValue = after.Values[selectedId]
	local bonuses = GrowthConfig.Bonuses(selectedId)
	for i = 1, 12 do
		local row = modPanel:FindFirstChild("Mod_" .. i)
		local bonus = bonuses[i]
		if row then
			row.Visible = bonus ~= nil
			if bonus then
				local reached = plannedValue >= bonus.Req
				row.Req.Text = tostring(bonus.Req)
				row.Req.BackgroundColor3 = if reached then WHITE else ROW
				row.Req.TextColor3 = if reached then Color3.fromRGB(40, 150, 165) else DIM
				row.Effect.Text = `{GrowthConfig.StatNames[bonus.Stat] or bonus.Stat} +{bonus.Percent}%`
				row.Effect.BackgroundColor3 = if reached then TEAL else ROW
				row.Effect.BackgroundTransparency = if reached then 0.05 else 0.3
				row.Effect.TextColor3 = if reached then WHITE else DIM
			end
		end
	end

	-- equipped weapon card
	if weapon then
		weaponCard.WeaponName.Text = weapon.DisplayName or weapon.Id
		weaponCard.WeaponClass.Text = weapon.Class or ""
		local acvText = if after.AtkAcv ~= now.AtkAcv
			then ` <font color="{BLUE_ON_LIGHT}">{ARROW} +{after.AtkAcv}</font>`
			else ""
		weaponCard.WeaponAtk.Text = `Weapon ATK {weaponAtk} +{now.AtkAcv}{acvText}`

		local parts = {}
		local scaling = GrowthConfig.ScalingFor(weapon.Class)
		for _, id in { "STR", "DEX", "AGI", "INT" } do
			table.insert(parts, `{id} {scaling[id] or "-"}`)
		end
		weaponCard.Scaling.Text = "ACV  " .. table.concat(parts, "  ")
	else
		weaponCard.WeaponName.Text = "No weapon"
		weaponCard.WeaponClass.Text = ""
		weaponCard.WeaponAtk.Text = "Weapon ATK 0"
		weaponCard.Scaling.Text = ""
	end

	-- bottom buttons
	local planning = pendingTotal() > 0
	setButtonLook(spendButton, planning and not busy, true)
	resetButton.Text = if planning then "Undo Changes" else "Reset Points"
	setButtonLook(resetButton, (planning or spentTotal(alloc) > 0) and not busy)
end

-- Actions ------------------------------------------------------------------------------------------

local function select(id: string)
	selectedId = id
	refresh()
end

local function plan(id: string, delta: number)
	local alloc = allocatedNow()
	local available = player:GetAttribute(PointsAttribute) or 0
	local current = pending[id] or 0
	local target = current + delta
	if delta > 0 then
		if available - pendingTotal() <= 0 or 1 + alloc[id] + target > GrowthConfig.MaxAttribute then
			return
		end
	elseif target < 0 then
		return
	end
	pending[id] = if target > 0 then target else nil
	refresh()
end

local function spend()
	if busy or pendingTotal() == 0 then
		return
	end
	busy = true
	refresh()
	local ok, success, message = pcall(function()
		return SpendRemote:InvokeServer(table.clone(pending))
	end)
	busy = false
	if ok and success then
		table.clear(pending)
		showFeedback("Growth Points spent.")
	else
		showFeedback(if ok and message then tostring(message) else "Could not spend points.")
	end
	refresh()
end

local function resetOrUndo()
	if busy then
		return
	end
	if pendingTotal() > 0 then
		table.clear(pending)
		refresh()
		return
	end
	if spentTotal(allocatedNow()) == 0 then
		return
	end
	busy = true
	refresh()
	local ok, success, message = pcall(function()
		return ResetRemote:InvokeServer()
	end)
	busy = false
	if ok and success then
		showFeedback("All Growth Points returned.")
	else
		showFeedback(if ok and message then tostring(message) else "Could not reset points.")
	end
	refresh()
end

local function closePanel()
	if not isOpen and not panel.Visible then
		return
	end
	isOpen = false
	panel.Visible = false
	table.clear(pending) -- an unconfirmed plan is dropped
	InventoryCamera.Exit()
end

local function openPanel()
	PanelManager.open("Growth") -- close any other open HUD panel first
	isOpen = true
	panel.Visible = true
	feedback.Text = ""
	InventoryCamera.Enter()
	refresh()
end

PanelManager.register("Growth", closePanel)

openButton.MouseButton1Click:Connect(function()
	if isOpen then
		closePanel()
	else
		openPanel()
	end
end)

closeButton.MouseButton1Click:Connect(closePanel)
backButton.MouseButton1Click:Connect(closePanel)
spendButton.MouseButton1Click:Connect(spend)
resetButton.MouseButton1Click:Connect(resetOrUndo)

for _, def in GrowthConfig.Attributes do
	local row = attributeList:WaitForChild("Row_" .. def.Id)
	row:WaitForChild("Select").MouseButton1Click:Connect(function()
		select(def.Id)
	end)
	row:WaitForChild("Minus").MouseButton1Click:Connect(function()
		plan(def.Id, -1)
	end)
	row:WaitForChild("Plus").MouseButton1Click:Connect(function()
		plan(def.Id, 1)
	end)
	player:GetAttributeChangedSignal(AttributePrefix .. def.Id):Connect(refresh)
end

-- keep the screen live while it is open
player:GetAttributeChangedSignal(PointsAttribute):Connect(refresh)
player:GetAttributeChangedSignal(ClassConfig.Attributes.Level):Connect(refresh)
player:GetAttributeChangedSignal("Col"):Connect(refresh)

local function watchCharacter(character: Model)
	character:GetAttributeChangedSignal(CombatConfig.Attributes.EquippedWeapon):Connect(refresh)
	refresh()
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	watchCharacter(player.Character)
end

