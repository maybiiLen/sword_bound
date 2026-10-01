--[[
	CombatService  (server only)
	The server half of combat. Clients predict everything (animation, movement, hitbox); this
	mirrors their state machine and decides what actually happened. All timings come from the
	animation markers in ReplicatedStorage.Combat.Animations.Specs, same as the client.

	Per-player state (also replicated as character attributes):
		Idle | Attacking | Charging | Rolling | Blocking | Staggered
		CombatState, SprintBlocked (state ~= Idle), MoveSpeedMultiplier (CombatConfig table),
		IFrames (true inside a roll's IFrameStart..IFrameEnd), BlockStartedAt (server time).

	AttackRemote (client -> server)
		("Light", step)   weapon drawn, can act, step 1 or the next combo step, stamina
		("ChargeStart", fromLight?)   weapon drawn, can act, stamina > 0. fromLight = true: the light
		                  attack this press started is still before its HitStart, so it is cancelled,
		                  its stamina refunded, and the press becomes a heavy charge.
		("Heavy")         must be Charging; charge ratio measured here, not trusted
		("Riposte", targetModel)   weapon has a Riposte, can act, target alive and staggered by
		                  "Stagger" or "GuardBreak" (not a parry recoil), within Riposte.Range +
		                  ReachTolerance. The target is held ("Riposted") for the whole finisher,
		                  the attacker has i-frames, damage lands at HitStart (no hitbox needed).
		("Context", name)  a contextual attack; name is a weapon field (RunningAttack, JumpAttack,
		                  RollAttack, GuardCounter) the weapon has, can act, stamina, and its situation:
		                    RunningAttack  Sprinting attribute, or moving >= RunningAttackMinSpeed - 4
		                    JumpAttack     the server sees you airborne (ground raycast) within JumpAttackGrace
		                                   before or after the request (positions replicate late)
		                    RollAttack     in a roll/backstep past its CancelOpen, or RollAttackWindow after one
		                    GuardCounter   GuardCounterUntil (set by DamageService on block/parry) not expired
		                  Hits then go through HitRemote like any attack.
	ActionRemote (client -> server)
		("Roll" | "Backstep", direction)   can act, stamina
		("Block", true, clientServerTime?) | ("Block", false)   weapon drawn, can act. The block's start
		                  time is the client's GetServerTimeNow() at the press, clamped to at most
		                  MaxParryRewind earlier than now (ping compensation). Raising block within
		                  ParrySpamLockout of releasing it only gets ParryWindowSpammed.
	HitRemote (client -> server: targetModel, position)
		Current attack, inside HitStart..HitEnd (+/- HitWindowAllowance), within Reach +
		ReachTolerance, each target once per swing -> DamageService:ResolveHit.

	"Can act" = Idle/Blocking, or the current attack/roll has reached its CancelOpen marker
	(RollOpen for rolls; minus ActionTimingTolerance), and not staggered or flinching.
	A light attack's first WindupCancelTime can be cancelled into Block or Roll.
	An attack ends for gameplay at its MoveOpen marker (AnimationLibrary.ActionLength); the
	client keeps playing the settle as a cosmetic tail.

	Reactions to the player (ReactRemote): Stagger / GuardBreak (from PoiseService) and Flinch
	(ignored while the current attack has HyperArmor). DamageService sends BlockImpact and
	ParrySuccess itself.

	API:
		:GetState(player) -> string
		:HasHyperArmor(player) -> boolean
		.AttackStarted  Signal(player, kind, attack, definition)
		.HitConfirmed   Signal(player, targetModel, result, damage)
		.HitRejected    Signal(player, reason)      handy when tuning validation

	See Docs.Combat > "Server validation".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = ReplicatedStorage.Combat
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(Combat.CombatConfig)
local AnimationLibrary = require(Combat.Animations.AnimationLibrary)
local WeaponService = require(script.Parent.WeaponService)
local DamageService = require(script.Parent.DamageService)
local PoiseService = require(script.Parent.PoiseService)
local StaminaService = require(script.Parent.StaminaService)

local Attr = CombatConfig.Attributes
local Remotes = Combat.Remotes

local CombatService = {
	AttackStarted = Signal.new(),
	HitConfirmed = Signal.new(),
	HitRejected = Signal.new(),
}

type Action = {
	kind: string, -- "Light" | "Heavy" | "Charge" | "Roll" | "Backstep" | "Riposte" | a contextual attack name
	start: number,
	length: number,
	cancelOpen: number,
	rollOpen: number,
	hitStart: number?,
	hitEnd: number?,
	attack: any?,
	definition: any?,
	step: number?,
	chargeRatio: number?,
	hit: { [Model]: boolean },
}

type Actor = {
	character: Model,
	state: string,
	action: Action?,
	chargeStart: number,
	lastLightStep: number,
	lastLightEnd: number,
	flinchUntil: number,
	lastBlockRelease: number,
	lastRollEnd: number,
	lastAirborne: number,
}

local CONTEXT_ATTACKS = { RunningAttack = true, JumpAttack = true, RollAttack = true, GuardCounter = true }

local actors: { [Player]: Actor } = {}

local function getActor(player: Player): Actor?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local actor = actors[player]
	if not actor or actor.character ~= character then
		actor = {
			character = character,
			state = "Idle",
			action = nil,
			chargeStart = 0,
			lastLightStep = 0,
			lastLightEnd = 0,
			flinchUntil = 0,
			lastBlockRelease = -math.huge,
			lastRollEnd = -math.huge,
			lastAirborne = -math.huge,
		}
		actors[player] = actor
	end
	return actor
end

local function setState(actor: Actor, state: string)
	actor.state = state
	local character = actor.character
	character:SetAttribute(Attr.CombatState, state)
	character:SetAttribute(Attr.SprintBlocked, state ~= "Idle")
	character:SetAttribute(Attr.MoveSpeedMultiplier, CombatConfig.MoveSpeedMultipliers[state] or 1)
	if state ~= "Blocking" then
		character:SetAttribute(Attr.BlockStartedAt, nil)
		character:SetAttribute(Attr.BlockParryWindow, nil)
	end
	if state ~= "Rolling" then
		character:SetAttribute(Attr.IFrames, nil)
	end
end

local function fireOthers(player: Player, ...)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.EffectRemote:FireClient(other, ...)
		end
	end
end

local function canAct(actor: Actor, now: number, kind: string?): boolean
	if actor.state == "Staggered" or now < actor.flinchUntil then
		return false
	end
	if actor.state == "Idle" or actor.state == "Blocking" then
		return true
	end
	local action = actor.action
	if actor.state == "Attacking" and action and action.kind == "Light" and (kind == "Roll" or kind == "Block") then
		if now - action.start <= CombatConfig.WindupCancelTime + CombatConfig.ActionTimingTolerance then
			return true
		end
	end
	if (actor.state == "Attacking" or actor.state == "Rolling") and action then
		local opensAt = action.cancelOpen
		if kind == "Roll" then
			opensAt = action.rollOpen
		end
		return now >= action.start + opensAt - CombatConfig.ActionTimingTolerance
	end
	return false
end

local function finishLater(actor: Actor, action: Action)
	task.delay(action.length, function()
		if actor.action ~= action then
			return
		end
		actor.action = nil
		if action.kind == "Light" then
			actor.lastLightEnd = os.clock()
		end
		if action.kind == "Roll" or action.kind == "Backstep" then
			actor.lastRollEnd = os.clock()
		end
		if actor.character.Parent then
			setState(actor, "Idle")
		end
	end)
end

local function newAction(kind: string, animation: string, now: number): Action
	local length = AnimationLibrary.ActionLength(animation)
	return {
		kind = kind,
		start = now,
		length = length,
		cancelOpen = AnimationLibrary.MarkerTime(animation, "CancelOpen") or length,
		rollOpen = AnimationLibrary.RollOpenTime(animation),
		hitStart = AnimationLibrary.MarkerTime(animation, "HitStart"),
		hitEnd = AnimationLibrary.MarkerTime(animation, "HitEnd"),
		hit = {},
	}
end

local function startAttack(player: Player, actor: Actor, kind: string, attack: any, definition: any, now: number, step: number?, chargeRatio: number?)
	local action = newAction(kind, attack.Animation, now)
	action.attack = attack
	action.definition = definition
	action.step = step
	action.chargeRatio = chargeRatio
	actor.action = action
	if kind == "Light" then
		actor.lastLightStep = step :: number
	else
		actor.lastLightStep = 0
	end
	setState(actor, "Attacking")
	finishLater(actor, action)

	if action.hitStart and action.hitEnd then
		fireOthers(player, "Swing", actor.character, attack.Sound, action.hitStart, action.hitEnd - action.hitStart)
	end
	CombatService.AttackStarted:Fire(player, kind, attack, definition)
end

-- Is the situation for a contextual attack real? (the client already decided; this is the sanity check)
local function contextAllowed(name: string, actor: Actor, now: number): (boolean, string?)
	local character = actor.character
	local tolerance = CombatConfig.ActionTimingTolerance
	if name == "RunningAttack" then
		if character:GetAttribute("Sprinting") == true then
			return true
		end
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local velocity = root.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			if speed >= CombatConfig.RunningAttackMinSpeed - 4 then
				return true
			end
		end
		return false, "running attack while not running"
	elseif name == "JumpAttack" then
		if now - actor.lastAirborne <= CombatConfig.JumpAttackGrace + tolerance then
			return true
		end
		return false, "jump attack while grounded"
	elseif name == "RollAttack" then
		local action = actor.action
		if action and (action.kind == "Roll" or action.kind == "Backstep") then
			return true -- canAct already checked the roll's CancelOpen
		end
		if now - actor.lastRollEnd <= CombatConfig.RollAttackWindow + tolerance then
			return true
		end
		return false, "roll attack without a roll"
	elseif name == "GuardCounter" then
		local openUntil = character:GetAttribute(Attr.GuardCounterUntil)
		if typeof(openUntil) == "number" and workspace:GetServerTimeNow() <= openUntil + tolerance then
			return true
		end
		return false, "guard counter without a blocked hit"
	end
	return false, "unknown contextual attack"
end

local function onAttack(player: Player, kind: unknown, arg: unknown)
	local actor = getActor(player)
	local definition = WeaponService:GetEquipped(player)
	if not actor or not definition or not WeaponService:IsDrawn(player) then
		return
	end
	local now = os.clock()

	if kind == "Light" then
		if typeof(arg) ~= "number" or arg % 1 ~= 0 then
			return
		end
		local attack = definition.Combo[arg]
		if not attack then
			return
		end
		if not canAct(actor, now) then
			CombatService.HitRejected:Fire(player, "light attack while busy (" .. actor.state .. ")")
			return
		end
		if arg ~= 1 then
			local current = actor.action
			local chainedFromCurrent = current ~= nil and current.kind == "Light" and current.step == arg - 1
			local chainedFromRecent = actor.lastLightStep == arg - 1
				and now - actor.lastLightEnd <= definition.ComboResetTime + CombatConfig.InputBufferTime + CombatConfig.ActionTimingTolerance
			if not chainedFromCurrent and not chainedFromRecent then
				CombatService.HitRejected:Fire(player, "invalid combo step " .. arg)
				return
			end
		end
		if not StaminaService:TrySpend(player, attack.StaminaCost) then
			return
		end
		startAttack(player, actor, "Light", attack, definition, now, arg, nil)
	elseif kind == "ChargeStart" then
		if not definition.Heavy then
			return
		end
		local current = actor.action
		local fromLight = arg == true
			and actor.state == "Attacking"
			and current ~= nil
			and current.kind == "Light"
			and current.hitStart ~= nil
			and now - current.start <= current.hitStart + CombatConfig.ActionTimingTolerance
		if fromLight then
			-- the press that started this light was held: it was a heavy all along
			StaminaService:Refund(player, current.attack and current.attack.StaminaCost or 0)
			actor.lastLightStep = 0
		elseif not canAct(actor, now) then
			return
		end
		if StaminaService:Get(player) <= 0 then
			return
		end
		actor.chargeStart = now
		actor.action = nil
		setState(actor, "Charging")
	elseif kind == "Heavy" then
		if actor.state ~= "Charging" then
			return
		end
		local heavy = definition.Heavy
		if not StaminaService:TrySpend(player, heavy.StaminaCost) then
			setState(actor, "Idle")
			return
		end
		local ratio = math.clamp((now - actor.chargeStart) / CombatConfig.HeavyFullCharge, 0, 1)
		startAttack(player, actor, "Heavy", heavy, definition, now, nil, ratio)
	elseif kind == "Context" then
		if typeof(arg) ~= "string" or not CONTEXT_ATTACKS[arg] then
			return
		end
		local name = arg :: string
		local attack = (definition :: any)[name]
		if not attack then
			return
		end
		if not canAct(actor, now) then
			CombatService.HitRejected:Fire(player, name .. " while busy (" .. actor.state .. ")")
			return
		end
		local function begin()
			if not StaminaService:TrySpend(player, attack.StaminaCost) then
				return
			end
			if name == "GuardCounter" then
				actor.character:SetAttribute(Attr.GuardCounterUntil, nil) -- one counter per blocked hit
			end
			startAttack(player, actor, name, attack, definition, now, nil, nil)
		end
		local allowed, reason = contextAllowed(name, actor, now)
		if allowed then
			begin()
		elseif name == "JumpAttack" then
			-- The server sees the character's position ~0.2 s late (measured in Studio), so a jump
			-- attack pressed early in a jump arrives before the server has seen the jump. Wait up to
			-- JumpAttackGrace for it; the action still counts from when the request arrived.
			task.spawn(function()
				local waited = 0
				while waited < CombatConfig.JumpAttackGrace do
					waited += task.wait()
					if actor.lastAirborne >= now then
						if actor.character.Parent and canAct(actor, os.clock()) then
							begin()
						end
						return
					end
				end
				CombatService.HitRejected:Fire(player, reason or name)
			end)
		else
			CombatService.HitRejected:Fire(player, reason or name)
		end
	elseif kind == "Riposte" then
		local riposte = definition.Riposte
		if not riposte or typeof(arg) ~= "Instance" or not arg:IsA("Model") or not arg:IsDescendantOf(workspace) then
			return
		end
		local target = arg :: Model
		local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
		local staggerKind = target:GetAttribute(Attr.StaggerKind)
		if not targetHumanoid or targetHumanoid.Health <= 0 or not PoiseService:IsStaggered(target)
			or (staggerKind ~= "Stagger" and staggerKind ~= "GuardBreak") then
			CombatService.HitRejected:Fire(player, "riposte target not open (" .. tostring(staggerKind) .. ")")
			return
		end
		if not canAct(actor, now) then
			CombatService.HitRejected:Fire(player, "riposte while busy (" .. actor.state .. ")")
			return
		end
		local root = actor.character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
		if not root or not targetRoot or (root.Position - (targetRoot :: BasePart).Position).Magnitude > riposte.Range + CombatConfig.ReachTolerance then
			CombatService.HitRejected:Fire(player, "riposte out of range")
			return
		end
		if not DamageService:CanDamage(player, targetHumanoid) then
			return
		end
		-- hold the victim for the whole finisher (keeps poise as-is; the crit multiplier applies)
		PoiseService:Stagger(target, AnimationLibrary.Length(riposte.Animation) + 0.2, "Riposted", true)
		startAttack(player, actor, "Riposte", riposte, definition, now, nil, nil)
		local action = actor.action :: Action
		local character = actor.character
		character:SetAttribute(Attr.IFrames, true)
		task.delay(action.hitStart or 0.3, function()
			if actor.action ~= action or targetHumanoid.Health <= 0 or not target:IsDescendantOf(workspace) then
				return
			end
			local hitRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
			DamageService:ResolveHit({
				Attacker = player,
				Target = targetHumanoid,
				Damage = definition.Damage * riposte.DamageMultiplier,
				PoiseDamage = 0,
				Position = if hitRoot then (hitRoot :: BasePart).Position else nil,
				Class = definition.Class,
				WeaponId = definition.Id,
			})
		end)
		task.delay(action.length, function()
			if actor.action == action or actor.action == nil then
				character:SetAttribute(Attr.IFrames, nil)
			end
		end)
	end
end

local function onAction(player: Player, kind: unknown, arg: unknown, arg2: unknown)
	local actor = getActor(player)
	if not actor then
		return
	end
	local now = os.clock()

	if kind == "Roll" or kind == "Backstep" then
		if not canAct(actor, now, "Roll") then
			CombatService.HitRejected:Fire(player, kind .. " while busy (" .. actor.state .. ")")
			return
		end
		local cost = if kind == "Roll" then CombatConfig.RollStaminaCost else CombatConfig.BackstepStaminaCost
		if not StaminaService:TrySpend(player, cost) then
			return
		end
		local action = newAction(kind, kind, now)
		actor.action = action
		actor.lastLightStep = 0
		setState(actor, "Rolling")
		finishLater(actor, action)

		local iStart = AnimationLibrary.MarkerTime(kind, "IFrameStart") or 0
		local iEnd = AnimationLibrary.MarkerTime(kind, "IFrameEnd") or action.length
		local character = actor.character
		task.delay(iStart, function()
			if actor.action == action then
				character:SetAttribute(Attr.IFrames, true)
			end
		end)
		task.delay(iEnd, function()
			if actor.action == action then
				character:SetAttribute(Attr.IFrames, nil)
			end
		end)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			fireOthers(player, "Sound", root, "Roll")
		end
	elseif kind == "Block" then
		if arg == true then
			local definition = WeaponService:GetEquipped(player)
			if actor.state == "Blocking" or not definition or not WeaponService:IsDrawn(player) or not canAct(actor, now, "Block") then
				return
			end
			actor.action = nil
			setState(actor, "Blocking")
			-- ping compensation: trust the client's press time, but never more than MaxParryRewind back
			local serverNow = workspace:GetServerTimeNow()
			local startedAt = serverNow
			if typeof(arg2) == "number" and arg2 == arg2 then
				startedAt = math.clamp(arg2, serverNow - CombatConfig.MaxParryRewind, serverNow)
			end
			-- anti-mash: re-raising block right after releasing it only gets a tiny window
			local window = CombatConfig.ParryWindow
			if now - actor.lastBlockRelease <= CombatConfig.ParrySpamLockout then
				window = CombatConfig.ParryWindowSpammed
			end
			actor.character:SetAttribute(Attr.BlockParryWindow, window)
			actor.character:SetAttribute(Attr.BlockStartedAt, startedAt)
		elseif arg == false and actor.state == "Blocking" then
			actor.lastBlockRelease = now
			setState(actor, "Idle")
		end
	end
end

local function getTargetPosition(model: Model): Vector3
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if root and root:IsA("BasePart") then root.Position else model:GetPivot().Position
end

local function onHit(player: Player, target: unknown, position: unknown)
	local actor = actors[player]
	local character = player.Character
	local action = actor and actor.action
	if not actor or not action or actor.character ~= character or not character or not action.attack then
		return
	end
	if typeof(target) ~= "Instance" or not target:IsA("Model") or not target:IsDescendantOf(workspace) then
		return
	end
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid or action.kind == "Riposte" or action.hit[target] or not action.hitStart or not action.hitEnd then
		return
	end

	local allowance = CombatConfig.HitWindowAllowance
	local elapsed = os.clock() - action.start
	local windowStart = action.hitStart - allowance
	-- hit-stop freezes the client's timeline, so a multi-target swing reports later than real time
	local windowEnd = action.hitEnd + allowance + CombatConfig.HitStop.Heavy * 2
	if elapsed < windowStart or elapsed > windowEnd then
		CombatService.HitRejected:Fire(player, string.format("outside hit window (%.2fs, window %.2f-%.2f)", elapsed, windowStart, windowEnd))
		return
	end

	local definition = action.definition
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetPosition = getTargetPosition(target)
	local distance = root and (root.Position - targetPosition).Magnitude or math.huge
	if distance > definition.Reach + CombatConfig.ReachTolerance then
		CombatService.HitRejected:Fire(player, string.format("out of reach (%.1f studs)", distance))
		return
	end
	if not DamageService:CanDamage(player, humanoid) then
		return
	end
	action.hit[target] = true

	local attack = action.attack
	local damage = definition.Damage * attack.DamageMultiplier
	local poise = attack.PoiseDamage or 0
	if action.kind == "Heavy" and action.chargeRatio then
		damage *= 1 + (attack.FullChargeDamageBonus or 0) * action.chargeRatio
		poise *= 1 + (attack.FullChargePoiseBonus or 0) * action.chargeRatio
	end

	local effectPosition = targetPosition
	if typeof(position) == "Vector3" and (position - targetPosition).Magnitude < 8 then
		effectPosition = position
	end
	local result, dealt = DamageService:ResolveHit({
		Attacker = player,
		Target = humanoid,
		Damage = damage,
		PoiseDamage = poise,
		Position = effectPosition,
		Class = definition.Class,
		WeaponId = definition.Id,
	})
	CombatService.HitConfirmed:Fire(player, target, result, dealt)
end

function CombatService:GetState(player: Player): string
	local actor = actors[player]
	return if actor and actor.character == player.Character then actor.state else "Idle"
end

function CombatService:HasHyperArmor(player: Player): boolean
	local actor = actors[player]
	local action = actor and actor.action
	return action ~= nil and action.attack ~= nil and action.attack.HyperArmor == true
end

function CombatService:Start()
	Remotes.AttackRemote.OnServerEvent:Connect(onAttack)
	Remotes.ActionRemote.OnServerEvent:Connect(onAction)
	Remotes.HitRemote.OnServerEvent:Connect(onHit)

	PoiseService.Staggered:Connect(function(model: Model, kind: string, duration: number)
		local player = Players:GetPlayerFromCharacter(model)
		local actor = player and getActor(player)
		if not player or not actor then
			return
		end
		actor.action = nil
		actor.lastLightStep = 0
		setState(actor, "Staggered")
		Remotes.ReactRemote:FireClient(player, kind, duration)
	end)
	PoiseService.StaggerEnded:Connect(function(model: Model)
		local player = Players:GetPlayerFromCharacter(model)
		local actor = player and actors[player]
		if actor and actor.character == model and actor.state == "Staggered" then
			setState(actor, "Idle")
		end
	end)
	PoiseService.Flinched:Connect(function(model: Model)
		local player = Players:GetPlayerFromCharacter(model)
		local actor = player and actors[player]
		if not player or not actor or actor.character ~= model or CombatService:HasHyperArmor(player) then
			return
		end
		actor.flinchUntil = os.clock() + CombatConfig.FlinchTime
		if actor.state == "Attacking" or actor.state == "Charging" then
			actor.action = nil
			setState(actor, "Idle")
		end
		Remotes.ReactRemote:FireClient(player, "Flinch")
	end)

	if CombatConfig.DebugValidation and RunService:IsStudio() then
		CombatService.HitRejected:Connect(function(player, reason)
			print(`[CombatService] rejected {player.Name}: {reason}`)
		end)
	end

	-- Remember when each player was last airborne (jump attack check). Humanoid.FloorMaterial
	-- stays on the floor on the server for client-owned characters (tested 2026-10-01), so this
	-- raycasts down from the replicated root instead: nothing within HipHeight + half the root +
	-- 1.2 studs = airborne.
	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Exclude
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local actor = getActor(player)
			if actor then
				local character = actor.character
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if humanoid and root then
					groundParams.FilterDescendantsInstances = { character }
					local reach = humanoid.HipHeight + root.Size.Y / 2 + 1.2
					local hit = workspace:Raycast(root.Position, Vector3.new(0, -reach, 0), groundParams)
					if hit == nil then
						actor.lastAirborne = now
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		actors[player] = nil
	end)
end

return CombatService
