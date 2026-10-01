--[[
	WeaponController  (client)
	The local player's combat state machine. Predicts every action instantly (animation,
	movement, hitbox) and tells the server, which validates the same rules (CombatService) and
	mirrors the state in the character's CombatState attribute.

	States:
		Idle       free
		Attacking  a light (combo) or heavy attack; committed until its CancelOpen marker
		Charging   holding attack past HeavyHoldThreshold; release swings the heavy
		Rolling    roll / backstep; i-frames are server-side
		Blocking   holding block; a block started just before a hit parries it
		Staggered  poise broken or guard broken (server-driven), no actions

	Rules (the "not a clicker" part):
		- attack swings a light on PRESS; still holding at HeavyHoldThreshold (before the light's
		  HitStart) turns that same swing into a heavy charge, release swings the heavy
		- a light's first WindupCancelTime can be cancelled into block or roll (Sekiro style)
		- attacks keep your momentum (MomentumCarryTime), lunge toward a target in range and
		  stop short of it (LungeAssistRange / LungeStopDistance), and stop the lunge on a hit;
		  Light1 out of a sprint lunges further (SprintAttackLungeMultiplier)
		- inputs during an action are buffered for InputBufferTime and fire as soon as their
		  window opens (the newest press replaces an older one)
		- staggered cancels: the next light at CancelOpen, a roll at RollOpen (defaults to
		  CancelOpen), and the action is over at MoveOpen; nothing else cancels an attack
		- after MoveOpen the attack track keeps playing its settle until you move or act
		- every attack/roll costs stamina and is refused at 0 stamina
		- attacks turn you toward the lock-on target / stick direction during the wind-up and
		  commit to that direction at HitStart; movement is slowed while acting
		- a hit from an enemy flinches you out of an attack unless it has HyperArmor

	Weapon lifecycle: the server puts "WeaponModel" in the character and sets EquippedWeapon;
	this creates WeaponBehaviors.<Class>.new(definition, character, model, animationSet) and
	follows WeaponDrawn (drawn = combat camera on).

	API:
		WeaponController:Start(input, movement, camera, lockOn)
		WeaponController.State
		WeaponController.StateChanged  Signal(state)
		WeaponController:GetWeapon() -> behavior object?

	See Docs.Combat > "State machine".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = ReplicatedStorage.Combat
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local CombatConfig = require(Combat.CombatConfig)
local WeaponRegistry = require(Combat.WeaponRegistry)
local Effects = require(Combat.Effects)
local AnimationSet = require(Combat.Animations.AnimationSet)
local AnimationLibrary = require(Combat.Animations.AnimationLibrary)

local Attr = CombatConfig.Attributes
local Remotes = Combat.Remotes
local player = Players.LocalPlayer

local WeaponController = {
	State = "Idle",
	StateChanged = Signal.new(),
}

local movement, camera, lockOn

local characterTrove = Trove.new()
local character: Model? = nil
local humanoid: Humanoid? = nil
local anims = nil
local weapon = nil

local action: { kind: string, token: number, cancelOpen: boolean, rollOpen: boolean, attack: any?, startedAt: number?, pressId: number? }? = nil
local token = 0
local comboStep = 0
local lastLightEnd = -math.huge
local buffered: string? = nil
local bufferedAt = 0
local attackHeld = false
local attackPressedAt = 0
local pressId = 0
local chargeStart = 0
local blockHeld = false
local flinchUntil = 0
local pendingPressId = 0 -- the attack press starting the next light (a held press can turn it into a heavy)
local bufferedPressId = 0

local startLight, startRoll, startBlock

local function setState(state: string)
	if WeaponController.State ~= state then
		WeaponController.State = state
		WeaponController.StateChanged:Fire(state)
	end
	movement:SetSpeedMultiplier(CombatConfig.MoveSpeedMultipliers[state] or 1)
end

local function isAlive(): boolean
	return humanoid ~= nil and humanoid.Health > 0
end

local function hasStamina(): boolean
	local stamina = character and character:GetAttribute("Stamina")
	return typeof(stamina) ~= "number" or stamina > 0
end

local function rootLook(): Vector3
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.CFrame.LookVector else Vector3.new(0, 0, -1)
end

local function canAct(kind: string?): boolean
	if not isAlive() or os.clock() < flinchUntil then
		return false
	end
	local state = WeaponController.State
	if state == "Idle" or state == "Blocking" then
		return true
	end
	if state == "Attacking" and action and action.kind == "Light" and (kind == "Roll" or kind == "Block") then
		if os.clock() - (action.startedAt or 0) <= CombatConfig.WindupCancelTime then
			return true
		end
	end
	if (state == "Attacking" or state == "Rolling") and action then
		if kind == "Roll" then
			return action.rollOpen
		end
		return action.cancelOpen
	end
	return false
end

local function stopBlocking(notifyServer: boolean)
	if weapon then
		weapon:SetBlocking(false)
	end
	if notifyServer and WeaponController.State == "Blocking" then
		Remotes.ActionRemote:FireServer("Block", false)
	end
end

local function cancelAll()
	token += 1
	action = nil
	buffered = nil
	if weapon then
		weapon:CancelAttack()
		weapon:StopCharge()
		weapon:SetBlocking(false)
	end
	if anims then
		anims:Stop("Roll", 0.1)
		anims:Stop("Backstep", 0.1)
	end
	movement:StopDash()
	movement:SetFacing(nil)
end

-- ignoreWindow: the action just ended, so anything queued may fire.
local function consumeBuffer(ignoreWindow: boolean?): boolean
	local kind = buffered
	if not kind then
		return false
	end
	if os.clock() - bufferedAt > CombatConfig.InputBufferTime then
		buffered = nil
		return false
	end
	if not ignoreWindow and not canAct(kind) then
		return false -- stays queued until its window opens
	end
	buffered = nil
	if kind == "Light" then
		pendingPressId = bufferedPressId
		return startLight()
	elseif kind == "Roll" then
		return startRoll()
	end
	return false
end

local function endAction(myToken: number)
	if myToken ~= token or not action then
		return
	end
	if action.kind == "Light" then
		lastLightEnd = os.clock()
	else
		comboStep = 0
	end
	action = nil
	movement:SetFacing(nil)
	if consumeBuffer(true) then
		return
	end
	if blockHeld and weapon and weapon.Drawn then
		startBlock()
	else
		setState("Idle")
	end
end

-- Momentum: an attack keeps the velocity you had and eases it out instead of stopping dead.
local function carryMomentum()
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local velocity = root.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = flat.Magnitude
	if speed > 2 then
		movement:Dash(flat.Unit, speed, CombatConfig.MomentumCarryTime)
	end
end

-- What a lunge steers toward: the lock-on target, else the nearest living enemy inside a cone in
-- front of us, within LungeAssistRange.
local function findLungeTarget(root: BasePart): BasePart?
	local range = CombatConfig.LungeAssistRange
	local locked = lockOn.TargetPart
	if locked and locked.Parent and (locked.Position - root.Position).Magnitude <= range then
		return locked
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local lookVector = root.CFrame.LookVector
	local look = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
	local minDot = math.cos(math.rad(CombatConfig.LungeAssistAngle))
	local best: BasePart? = nil
	local bestDistance = math.huge
	local seen = {}
	for _, part in workspace:GetPartBoundsInRadius(root.Position, range, params) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not seen[model] then
			seen[model] = true
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local targetRoot = model:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and targetRoot and targetRoot:IsA("BasePart") then
				local offset = targetRoot.Position - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local distance = flat.Magnitude
				if distance > 0.1 and distance < bestDistance and look:Dot(flat.Unit) >= minDot then
					best = targetRoot
					bestDistance = distance
				end
			end
		end
	end
	return best
end

-- Lunge ~LungeSpeed x scale x LungeTime x 2/3 studs, steered toward a target in range and cut short
-- so we stop LungeStopDistance from it instead of overshooting.
local function lunge(scale: number)
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or scale <= 0 then
		return
	end
	local direction = rootLook()
	local target = findLungeTarget(root)
	if target then
		local offset = target.Position - root.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		local fullDistance = CombatConfig.LungeSpeed * scale * CombatConfig.LungeTime * (2 / 3)
		local allowed = math.clamp(flat.Magnitude - CombatConfig.LungeStopDistance, 0, fullDistance)
		if allowed <= 0.05 then
			return
		end
		direction = flat.Unit
		scale = scale * (allowed / fullDistance)
	end
	movement:Dash(direction, CombatConfig.LungeSpeed * scale, CombatConfig.LungeTime)
end

local function beginAttack(kind: string, attack, chargeRatio: number?, lungeScale: number?)
	token += 1
	local myToken = token
	action = {
		kind = kind,
		token = myToken,
		cancelOpen = false,
		rollOpen = false,
		attack = attack,
		startedAt = os.clock(),
		pressId = if kind == "Light" then pendingPressId else 0,
	}
	pendingPressId = 0
	carryMomentum()
	setState("Attacking")

	if lockOn.Target then
		movement:SetFacing(nil)
	else
		movement:SetFacing(movement:GetIntentDirection())
	end

	weapon:PlayAttack(attack, {
		Lunge = function()
			if myToken == token and (attack.Lunge or 0) > 0 then
				lunge(attack.Lunge * (lungeScale or 1))
			end
		end,
		HitStart = function()
			if myToken == token then
				movement:SetFacing(rootLook())
				if kind == "Heavy" then
					camera:Punch(0.6 + (chargeRatio or 0) * 1.2)
				end
			end
		end,
		CancelOpen = function()
			if myToken == token and action then
				action.cancelOpen = true
				if AnimationLibrary.MarkerTime(attack.Animation, "RollOpen") == nil then
					action.rollOpen = true
				end
				consumeBuffer()
			end
		end,
		RollOpen = function()
			if myToken == token and action then
				action.rollOpen = true
				consumeBuffer()
			end
		end,
		Ended = function()
			endAction(myToken)
		end,
	})
end

function startLight(): boolean
	if not weapon or not weapon.Drawn or not hasStamina() then
		return false
	end
	local definition = weapon.Definition
	local count = #definition.Combo
	local chaining = (action and action.kind == "Light")
		or os.clock() - lastLightEnd <= definition.ComboResetTime
	comboStep = if chaining and comboStep > 0 then comboStep % count + 1 else 1

	local sprintAttack = comboStep == 1 and character ~= nil and character:GetAttribute("Sprinting") == true
	stopBlocking(false)
	Remotes.AttackRemote:FireServer("Light", comboStep)
	beginAttack("Light", definition.Combo[comboStep], nil, if sprintAttack then CombatConfig.SprintAttackLungeMultiplier else 1)
	return true
end

-- fromLight: the light this same press started is still before its hit window, so it becomes
-- the heavy (the server cancels the light and refunds its stamina).
local function startCharge(fromLight: boolean?)
	if not weapon or not weapon.Drawn then
		return
	end
	if fromLight then
		cancelAll()
		comboStep = 0
	elseif not canAct() or not hasStamina() then
		return
	end
	stopBlocking(false)
	token += 1
	action = { kind = "Charge", token = token, cancelOpen = false, rollOpen = false }
	chargeStart = os.clock()
	setState("Charging")
	movement:SetFacing(if lockOn.Target then nil else movement:GetIntentDirection())
	weapon:StartCharge()
	Remotes.AttackRemote:FireServer("ChargeStart", fromLight == true)
end

local function releaseHeavy()
	if WeaponController.State ~= "Charging" or not weapon then
		return
	end
	local ratio = math.clamp((os.clock() - chargeStart) / CombatConfig.HeavyFullCharge, 0, 1)
	weapon:StopCharge()
	comboStep = 0
	Remotes.AttackRemote:FireServer("Heavy")
	beginAttack("Heavy", weapon.Definition.Heavy, ratio)
end

function startRoll(): boolean
	if not anims or not hasStamina() then
		return false
	end
	local input = movement:GetMoveInput()
	local backstep = input.Magnitude == 0
	local direction = if backstep then -rootLook() else input
	local name = if backstep then "Backstep" else "Roll"

	local wasBlocking = WeaponController.State == "Blocking"
	cancelAll()
	if wasBlocking then
		Remotes.ActionRemote:FireServer("Block", false)
	end
	Remotes.ActionRemote:FireServer(name, direction)

	token += 1
	local myToken = token
	action = { kind = name, token = myToken, cancelOpen = false, rollOpen = false }
	setState("Rolling")
	comboStep = 0

	if backstep then
		movement:SetFacing(rootLook())
		movement:Dash(direction, CombatConfig.BackstepSpeed, 0.32)
	else
		movement:FaceInstantly(direction)
		movement:SetFacing(direction)
		movement:Dash(direction, CombatConfig.RollSpeed, 0.5)
	end
	anims:Play(name, 0.05)
	Effects.PlaySound(character and character:FindFirstChild("HumanoidRootPart"), "Roll")

	local cancelAt = AnimationLibrary.MarkerTime(name, "CancelOpen") or AnimationLibrary.Length(name)
	task.delay(cancelAt, function()
		if myToken == token and action then
			action.cancelOpen = true
			action.rollOpen = true
			consumeBuffer()
		end
	end)
	task.delay(AnimationLibrary.Length(name), function()
		endAction(myToken)
	end)
	return true
end

function startBlock()
	if not weapon or not weapon.Drawn then
		return
	end
	token += 1
	action = nil
	setState("Blocking")
	movement:SetFacing(nil)
	weapon:SetBlocking(true)
	Remotes.ActionRemote:FireServer("Block", true, workspace:GetServerTimeNow()) -- press time, for ping-fair parries
end

local function request(kind: string, fromPress: number?)
	if canAct(kind) then
		if kind == "Light" then
			pendingPressId = fromPress or 0
			startLight()
		elseif kind == "Roll" then
			startRoll()
		end
	elseif WeaponController.State == "Attacking" or WeaponController.State == "Rolling" then
		buffered = kind
		bufferedAt = os.clock()
		bufferedPressId = if kind == "Light" then fromPress or 0 else 0
	end
end

local function onAttackPressed()
	if not weapon or not isAlive() then
		return
	end
	if not weapon.Drawn then
		-- Clicking no longer auto-draws the weapon (that caused accidental swings/PvP hits).
		-- Players must press E (CombatConfig.ToggleWeaponInputs) to draw before they can attack.
		return
	end
	attackHeld = true
	attackPressedAt = os.clock()
	pressId += 1
	local myPress = pressId
	-- Swing on PRESS. If the button is still down at HeavyHoldThreshold, the light this press
	-- started (still before its hit window) turns into a heavy charge instead.
	request("Light", myPress)
	task.delay(CombatConfig.HeavyHoldThreshold, function()
		if not attackHeld or pressId ~= myPress then
			return
		end
		if action and action.kind == "Light" and action.pressId == myPress then
			local hitStart = AnimationLibrary.MarkerTime(action.attack.Animation, "HitStart") or 0
			if os.clock() - (action.startedAt or 0) < hitStart then
				startCharge(true)
			end
		elseif buffered == "Light" and bufferedPressId == myPress then
			buffered = nil
			startCharge()
		else
			startCharge()
		end
	end)
end

local function onAttackReleased()
	if not attackHeld then
		return
	end
	attackHeld = false
	if WeaponController.State == "Charging" then
		releaseHeavy()
	end
end

local function onBlockPressed()
	blockHeld = true
	if not weapon or not weapon.Drawn or not canAct("Block") then
		return
	end
	if WeaponController.State == "Idle" then
		startBlock()
	elseif WeaponController.State == "Attacking" then
		cancelAll() -- wind-up cancel (or recovery after CancelOpen) into guard
		startBlock()
	end
end

local function onBlockReleased()
	blockHeld = false
	if WeaponController.State == "Blocking" then
		stopBlocking(true)
		setState("Idle")
	end
end

local function onRollPressed()
	if isAlive() then
		request("Roll")
	end
end

local function onLockOnPressed()
	if not weapon or not isAlive() then
		return
	end
	if not weapon.Drawn then
		Remotes.EquipRemote:FireServer("Toggle")
	end
	lockOn:Toggle()
end

local function onTogglePressed()
	if not weapon or not isAlive() then
		return
	end
	if WeaponController.State == "Idle" then
		Remotes.EquipRemote:FireServer("Toggle")
	end
end

local function enterStagger(kind: string, duration: number?)
	cancelAll()
	setState("Staggered")
	if anims then
		anims:Play(kind, 0.05)
	end
	Effects.Shake(CombatConfig.Shake.Stagger)
	local myToken = token
	duration = duration or if kind == "GuardBreak" then CombatConfig.GuardBreakTime else CombatConfig.StaggerTime
	task.delay((duration :: number) + 0.5, function()
		if myToken == token and WeaponController.State == "Staggered" then
			setState("Idle")
		end
	end)
end

local function onReact(kind: string, extra: any?)
	local duration: number? = if typeof(extra) == "number" then extra else nil
	if not isAlive() or not anims then
		return
	end
	if kind == "Stagger" or kind == "GuardBreak" then
		enterStagger(kind, duration)
	elseif kind == "Flinch" then
		local attack = action and action.attack
		if attack and attack.HyperArmor then
			return
		end
		local wasBlocking = WeaponController.State == "Blocking"
		cancelAll()
		if wasBlocking then
			Remotes.ActionRemote:FireServer("Block", false)
		end
		flinchUntil = os.clock() + CombatConfig.FlinchTime
		setState("Idle")
		anims:Play("Flinch", 0.05)
	elseif kind == "BlockImpact" then
		anims:Play("BlockImpact", 0.03)
		Effects.Shake(CombatConfig.Shake.Block)
	elseif kind == "ParrySuccess" then
		local perfect = extra == true
		local track = anims:Play("Parry", 0.03)
		Effects.Shake(if perfect then CombatConfig.Shake.PerfectParry else CombatConfig.Shake.Parry)
		Effects.Punch(if perfect then CombatConfig.Punch.PerfectParry else CombatConfig.Punch.Parry)
		local freeze = if perfect then CombatConfig.HitStop.PerfectParry else CombatConfig.HitStop.Parry
		task.delay(0.06, function()
			Effects.HitStop(track, freeze) -- hold the deflect pose for a beat
		end)
	elseif kind == "ParryRecoil" then
		-- we got parried: a short recoil (room for one counter slash), not the long stagger
		cancelAll()
		setState("Staggered")
		anims:Play("Flinch", 0.03)
		Effects.Shake(CombatConfig.Shake.Block)
		local myToken = token
		task.delay(duration or CombatConfig.ParryRecoilTime, function()
			if myToken == token and WeaponController.State == "Staggered" then
				setState("Idle")
			end
		end)
	end
end

local function clearWeapon()
	cancelAll()
	if weapon then
		weapon:Destroy()
		weapon = nil
	end
	comboStep = 0
	setState("Idle")
end

local function applyDrawn(drawn: boolean)
	camera:SetEnabled(drawn and isAlive())
	if not drawn then
		lockOn:Clear()
	end
end

local function buildWeapon(char: Model)
	clearWeapon()
	local weaponId = char:GetAttribute(Attr.EquippedWeapon)
	local model = char:FindFirstChild(CombatConfig.WeaponModelName)
	if not weaponId or not model or model:GetAttribute("WeaponId") ~= weaponId or not anims then
		applyDrawn(false)
		return
	end
	local definition = WeaponRegistry.Get(weaponId)
	local Behavior = WeaponRegistry.GetBehavior(weaponId)
	if not definition or not Behavior then
		return
	end
	local ok, result = pcall(Behavior.new, definition, char, model, anims)
	if not ok then
		warn("[WeaponController] Failed to create weapon behavior: " .. tostring(result))
		return
	end
	weapon = result
	weapon.HitLanded = function()
		movement:StopDash()
	end
	local drawn = char:GetAttribute(Attr.WeaponDrawn) == true
	weapon:SetDrawn(drawn)
	applyDrawn(drawn)
end

local function onCharacterAdded(char: Model)
	characterTrove:Clean()
	clearWeapon()
	camera:SetEnabled(false)
	if anims then
		anims:Destroy()
		anims = nil
	end
	character, humanoid = nil, nil

	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum or player.Character ~= char then
		return
	end
	local animator = hum:WaitForChild("Animator", 10) :: Animator?
	if not animator or player.Character ~= char then
		return
	end
	character, humanoid = char, hum
	anims = AnimationSet.new(animator, hum.RigType == Enum.HumanoidRigType.R6)
	anims:Preload({ "Roll", "Backstep", "Flinch", "Stagger", "GuardBreak", "BlockImpact", "Parry" })
	attackHeld, blockHeld, flinchUntil, lastLightEnd = false, false, 0, -math.huge

	local function refresh()
		buildWeapon(char)
	end
	characterTrove:Add(char:GetAttributeChangedSignal(Attr.EquippedWeapon):Connect(refresh))
	characterTrove:Add(char.ChildAdded:Connect(function(child)
		if child.Name == CombatConfig.WeaponModelName then
			refresh()
		end
	end))
	characterTrove:Add(char:GetAttributeChangedSignal(Attr.WeaponDrawn):Connect(function()
		local drawn = char:GetAttribute(Attr.WeaponDrawn) == true
		if weapon and weapon.Drawn ~= drawn then
			if not drawn then
				cancelAll()
				setState("Idle")
			end
			weapon:SetDrawn(drawn)
			Effects.PlaySound(char:FindFirstChild("HumanoidRootPart"), if drawn then "Draw" else "Sheath")
		end
		applyDrawn(drawn)
	end))
	characterTrove:Add(char:GetAttributeChangedSignal(Attr.CombatState):Connect(function()
		local serverState = char:GetAttribute(Attr.CombatState)
		if serverState == "Staggered" and WeaponController.State ~= "Staggered" then
			enterStagger("Stagger")
		elseif serverState ~= "Staggered" and WeaponController.State == "Staggered" then
			token += 1
			setState("Idle")
			if blockHeld and weapon and weapon.Drawn then
				startBlock()
			end
		end
	end))
	characterTrove:Add(hum.Died:Connect(function()
		clearWeapon()
		camera:SetEnabled(false)
		lockOn:Clear()
	end))
	refresh()
end

function WeaponController:GetWeapon()
	return weapon
end

function WeaponController:Start(inputController, movementController, cameraController, lockOnController)
	movement, camera, lockOn = movementController, cameraController, lockOnController
	inputController.AttackPressed:Connect(onAttackPressed)
	inputController.AttackReleased:Connect(onAttackReleased)
	inputController.BlockPressed:Connect(onBlockPressed)
	inputController.BlockReleased:Connect(onBlockReleased)
	inputController.RollPressed:Connect(onRollPressed)
	inputController.LockOnPressed:Connect(onLockOnPressed)
	inputController.TogglePressed:Connect(onTogglePressed)
	Remotes.ReactRemote.OnClientEvent:Connect(onReact)
	RunService.Heartbeat:Connect(function()
		if action == nil and weapon and weapon:HasSettle() and movement:GetMoveInput().Magnitude > 0 then
			weapon:StopSettle(0.25)
		end
	end)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

return WeaponController
