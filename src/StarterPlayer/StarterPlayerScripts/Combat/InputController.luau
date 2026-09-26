--[[
	InputController  (client)
	Turns raw input into combat intents. Keybinds live in CombatConfig (AttackInputs,
	BlockInputs, RollInputs, LockOnInputs, ToggleWeaponInputs); change them there, not here.
	Uses ContextActionService so other systems can bind over it and mobile gets on-screen
	buttons. Every binding returns Pass, so e.g. right mouse still rotates the default camera
	while the weapon is sheathed.

	API:
		InputController.AttackPressed / AttackReleased   Signal()   (tap = light, hold = heavy charge)
		InputController.BlockPressed / BlockReleased     Signal()
		InputController.RollPressed                      Signal()
		InputController.LockOnPressed                    Signal()
		InputController.TogglePressed                    Signal()
		InputController:Start()

	Used by: WeaponController. See Docs.Combat > "Controls".
]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)

local InputController = {
	AttackPressed = Signal.new(),
	AttackReleased = Signal.new(),
	BlockPressed = Signal.new(),
	BlockReleased = Signal.new(),
	RollPressed = Signal.new(),
	LockOnPressed = Signal.new(),
	TogglePressed = Signal.new(),
}

local function bind(name: string, inputs: { any }, title: string, position: UDim2, pressed, released)
	ContextActionService:BindAction(name, function(_, state)
		if state == Enum.UserInputState.Begin then
			pressed:Fire()
		elseif released and (state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel) then
			released:Fire()
		end
		return Enum.ContextActionResult.Pass
	end, true, table.unpack(inputs))
	ContextActionService:SetTitle(name, title)
	ContextActionService:SetPosition(name, position)
end

function InputController:Start()
	bind("CombatAttack", CombatConfig.AttackInputs, "Attack", UDim2.new(1, -170, 1, -230), self.AttackPressed, self.AttackReleased)
	bind("CombatBlock", CombatConfig.BlockInputs, "Block", UDim2.new(1, -250, 1, -230), self.BlockPressed, self.BlockReleased)
	bind("CombatRoll", CombatConfig.RollInputs, "Roll", UDim2.new(1, -90, 1, -230), self.RollPressed)
	bind("CombatLockOn", CombatConfig.LockOnInputs, "Lock", UDim2.new(1, -330, 1, -230), self.LockOnPressed)
	bind("CombatToggleWeapon", CombatConfig.ToggleWeaponInputs, "Draw", UDim2.new(1, -250, 1, -150), self.TogglePressed)
end

return InputController
