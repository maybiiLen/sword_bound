--[[
	InputController  (client)
	Turns raw input into combat intents. Keybinds live in CombatConfig (AttackInputs,
	ToggleWeaponInputs); change them there, not here. Uses ContextActionService so other
	systems can bind over it and mobile gets an on-screen attack button.

	API:
		InputController.AttackPressed   Signal()
		InputController.TogglePressed   Signal()
		InputController:Start()

	Used by: WeaponController. See Docs.Combat > "Controls".
]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)

local InputController = {
	AttackPressed = Signal.new(),
	TogglePressed = Signal.new(),
}

function InputController:Start()
	ContextActionService:BindAction("CombatAttack", function(_, state)
		if state == Enum.UserInputState.Begin then
			InputController.AttackPressed:Fire()
		end
		return Enum.ContextActionResult.Pass
	end, true, table.unpack(CombatConfig.AttackInputs))
	ContextActionService:SetTitle("CombatAttack", "Attack")
	ContextActionService:SetPosition("CombatAttack", UDim2.new(1, -170, 1, -230))

	ContextActionService:BindAction("CombatToggleWeapon", function(_, state)
		if state == Enum.UserInputState.Begin then
			InputController.TogglePressed:Fire()
		end
		return Enum.ContextActionResult.Pass
	end, true, table.unpack(CombatConfig.ToggleWeaponInputs))
	ContextActionService:SetTitle("CombatToggleWeapon", "Draw")
	ContextActionService:SetPosition("CombatToggleWeapon", UDim2.new(1, -250, 1, -150))
end

return InputController
