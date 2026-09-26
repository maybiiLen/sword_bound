--[[
	WeaponController  (client)
	Owns the local player's weapon behavior object and the combo state machine.

	Weapon lifecycle: the server puts "WeaponModel" in the character and sets the EquippedWeapon
	attribute; this creates WeaponBehaviors.<Class>.new(definition, character, model) and follows
	the WeaponDrawn attribute (idle pose on/off).

	Combo state machine (state mirrored to CombatState on the server):
		Idle      --attack-->  Attacking(step 1)
		Attacking --ends-->    Recovery          (buffered press within InputBufferTime chains instantly)
		Recovery  --attack-->  Attacking(step + 1, wraps to 1 after the last step)
		Recovery  --ComboResetTime passes--> Idle (combo restarts at step 1)
	Attacking while sheathed draws the weapon instead. E (Toggle) is ignored mid-swing.
	While attacking, the server sets SprintBlocked so the Sprint system stops sprinting.

	API:
		WeaponController:Start(inputController)
		WeaponController.State -> "Idle" | "Attacking" | "Recovery"
		WeaponController.StateChanged  Signal(state)
		WeaponController:GetWeapon() -> behavior object?

	See Docs.Combat > "Combo".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = ReplicatedStorage.Combat
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local CombatConfig = require(Combat.CombatConfig)
local WeaponRegistry = require(Combat.WeaponRegistry)
local Effects = require(Combat.Effects)

local Attr = CombatConfig.Attributes
local Remotes = Combat.Remotes
local player = Players.LocalPlayer

local WeaponController = {
	State = "Idle",
	StateChanged = Signal.new(),
}

local weapon = nil
local characterTrove = Trove.new()
local comboStep = 0
local swingEndsAt = 0
local buffered = false
local stateToken = 0

local function setState(state: string)
	stateToken += 1
	if WeaponController.State ~= state then
		WeaponController.State = state
		WeaponController.StateChanged:Fire(state)
	end
end

local function resetCombo()
	comboStep = 0
	buffered = false
	setState("Idle")
end

local startAttack

local function onSwingEnded()
	if buffered then
		buffered = false
		startAttack()
		return
	end
	setState("Recovery")
	local token = stateToken
	task.delay(weapon.Definition.ComboResetTime, function()
		if token == stateToken then
			resetCombo()
		end
	end)
end

function startAttack()
	local definition = weapon.Definition
	comboStep = if comboStep >= #definition.Combo then 1 else comboStep + 1
	setState("Attacking")
	local token = stateToken

	Remotes.AttackRemote:FireServer(comboStep)
	local duration = weapon:Attack(comboStep)
	swingEndsAt = os.clock() + duration

	task.delay(duration, function()
		if token == stateToken and weapon then
			onSwingEnded()
		end
	end)
end

local function isAlive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function onAttackPressed()
	if not weapon or not isAlive() then
		return
	end
	if not weapon.Drawn then
		Remotes.EquipRemote:FireServer("Toggle")
		return
	end
	if WeaponController.State == "Attacking" then
		if swingEndsAt - os.clock() <= CombatConfig.InputBufferTime then
			buffered = true
		end
		return
	end
	if WeaponController.State == "Idle" then
		comboStep = 0
	end
	startAttack()
end

local function onTogglePressed()
	if not weapon or WeaponController.State == "Attacking" or not isAlive() then
		return
	end
	Remotes.EquipRemote:FireServer("Toggle")
end

local function clearWeapon()
	if weapon then
		weapon:Destroy()
		weapon = nil
	end
	resetCombo()
end

local function buildWeapon(character: Model)
	clearWeapon()
	local weaponId = character:GetAttribute(Attr.EquippedWeapon)
	local model = character:FindFirstChild(CombatConfig.WeaponModelName)
	if not weaponId or not model or model:GetAttribute("WeaponId") ~= weaponId then
		return
	end
	local definition = WeaponRegistry.Get(weaponId)
	local Behavior = WeaponRegistry.GetBehavior(weaponId)
	if not definition or not Behavior then
		return
	end
	local ok, result = pcall(Behavior.new, definition, character, model)
	if not ok then
		warn("[WeaponController] Failed to create weapon behavior: " .. tostring(result))
		return
	end
	weapon = result
	weapon:SetDrawn(character:GetAttribute(Attr.WeaponDrawn) == true)
end

local function onCharacterAdded(character: Model)
	characterTrove:Clean()
	clearWeapon()

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid or player.Character ~= character then
		return
	end
	humanoid:WaitForChild("Animator", 10)

	local function refresh()
		buildWeapon(character)
	end
	characterTrove:Add(character:GetAttributeChangedSignal(Attr.EquippedWeapon):Connect(refresh))
	characterTrove:Add(character.ChildAdded:Connect(function(child)
		if child.Name == CombatConfig.WeaponModelName then
			refresh()
		end
	end))
	characterTrove:Add(character:GetAttributeChangedSignal(Attr.WeaponDrawn):Connect(function()
		local drawn = character:GetAttribute(Attr.WeaponDrawn) == true
		if weapon and weapon.Drawn ~= drawn then
			weapon:SetDrawn(drawn)
			if not drawn then
				resetCombo()
			end
			Effects.PlaySound(character:FindFirstChild("HumanoidRootPart"), if drawn then "Draw" else "Sheath")
		end
	end))
	characterTrove:Add(humanoid.Died:Connect(clearWeapon))
	refresh()
end

function WeaponController:GetWeapon()
	return weapon
end

function WeaponController:Start(inputController)
	inputController.AttackPressed:Connect(onAttackPressed)
	inputController.TogglePressed:Connect(onTogglePressed)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

return WeaponController
