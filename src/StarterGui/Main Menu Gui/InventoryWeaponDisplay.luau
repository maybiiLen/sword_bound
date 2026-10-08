--[[
	InventoryWeaponDisplay  (client ModuleScript, next to InventoryCamera)
	While the Inventory is open, the equipped weapon is shown DRAWN in the live character's hand, so the
	weapon you equip is the one you see. It uses the normal draw/sheath request (EquipRemote "Toggle"),
	so the server stays in charge and the draw animation / other players behave as usual.
	The weapon STAYS in the hand the whole time the panel is open: the draw/sheathe key (E) is blocked
	while open, so it can't be toggled off and back on.

		InventoryWeaponDisplay.Enter()   remember whether the weapon was drawn, draw it if it wasn't,
		                                 and block attack / block / roll / lock-on input
		InventoryWeaponDisplay.Exit()    put the weapon back the way it was before the inventory opened
		                                 and give the combat input back

	Equipping a different weapon while the panel is open makes the server put the new one on the back
	(WeaponService:Equip resets WeaponDrawn); this module then draws it again. Pressing E while the
	inventory is open does nothing (see NO COMBAT WHILE OPEN).

	NO COMBAT WHILE OPEN: a high-priority ContextActionService action swallows the BEGIN of the combat
	inputs in CombatConfig (AttackInputs, BlockInputs, RollInputs, LockOnInputs, ToggleWeaponInputs), so the
	character cannot swing, block, roll, lock on or sheathe/redraw the weapon with E. Releases still pass
	through so nothing gets stuck. This module's own draw/sheathe requests go straight to EquipRemote, so
	they are not affected by the block. Clicks on the inventory's own buttons are unaffected.
	Called by InventoryController. See Docs.Inventory > CHARACTER VIEW.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatConfig"))
local EquipRemote = ReplicatedStorage.Combat:WaitForChild("Remotes"):WaitForChild("EquipRemote")

local player = Players.LocalPlayer
local ATTR = CombatConfig.Attributes

local BLOCK_ACTION = "InventoryBlockCombat"

local REDRAW_DELAY = 0.2 -- lets both attributes (EquippedWeapon, WeaponDrawn) arrive before deciding
local RETRIES = 8 -- the server ignores toggles during its cooldown or mid-attack, so ask again
local RETRY_WAIT = 0.5

local InventoryWeaponDisplay = {}

local active = false
local wasDrawn = false
local requestId = 0 -- a newer request cancels an older retry loop
local weaponConnection: RBXScriptConnection? = nil
local characterConnection: RBXScriptConnection? = nil

-- every input that starts a combat action, including the draw/sheathe key (E): the weapon must stay drawn while open
local function combatInputs(): { any }
	local inputs = {}
	for _, list in {
		CombatConfig.AttackInputs,
		CombatConfig.BlockInputs,
		CombatConfig.RollInputs,
		CombatConfig.LockOnInputs,
		CombatConfig.ToggleWeaponInputs,
	} do
		for _, input in list do
			table.insert(inputs, input)
		end
	end
	return inputs
end

local function hasWeapon(): boolean
	local character = player.Character
	return character ~= nil and typeof(character:GetAttribute(ATTR.EquippedWeapon)) == "string"
end

local function isDrawn(): boolean
	local character = player.Character
	return character ~= nil and character:GetAttribute(ATTR.WeaponDrawn) == true
end

-- ask the server until the weapon is in the wanted state
local function setDrawn(target: boolean)
	requestId += 1
	local mine = requestId
	task.spawn(function()
		for _ = 1, RETRIES do
			if requestId ~= mine or not hasWeapon() or isDrawn() == target then
				return
			end
			EquipRemote:FireServer("Toggle")
			task.wait(RETRY_WAIT)
		end
	end)
end

local function watchCharacter(character: Model)
	if weaponConnection then
		weaponConnection:Disconnect()
	end
	-- a different weapon was equipped (or we respawned): it arrives sheathed, so draw it
	weaponConnection = character:GetAttributeChangedSignal(ATTR.EquippedWeapon):Connect(function()
		task.delay(REDRAW_DELAY, function()
			if active and player.Character == character and hasWeapon() and not isDrawn() then
				setDrawn(true)
			end
		end)
	end)
end

function InventoryWeaponDisplay.Enter()
	if active then
		return
	end
	active = true
	wasDrawn = isDrawn()

	ContextActionService:BindActionAtPriority(BLOCK_ACTION, function(_, state)
		-- swallow presses only; releases pass so a held block / charged attack cannot get stuck
		return if state == Enum.UserInputState.Begin then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
	end, false, Enum.ContextActionPriority.High.Value, table.unpack(combatInputs()))

	characterConnection = player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end

	if hasWeapon() and not wasDrawn then
		setDrawn(true)
	end
end

function InventoryWeaponDisplay.Exit()
	if not active then
		return
	end
	active = false
	ContextActionService:UnbindAction(BLOCK_ACTION)
	if weaponConnection then
		weaponConnection:Disconnect()
		weaponConnection = nil
	end
	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end

	if hasWeapon() and isDrawn() ~= wasDrawn then
		setDrawn(wasDrawn)
	else
		requestId += 1 -- nothing to restore: cancel any request still retrying
	end
end

return InventoryWeaponDisplay

