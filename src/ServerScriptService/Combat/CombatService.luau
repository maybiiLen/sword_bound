--[[
	CombatService  (server only)
	The server half of attacking. Clients predict (animation + hitbox); this decides.

	AttackRemote (client -> server: step)
		Accepted only if: weapon equipped AND drawn, alive, step is 1 or the next combo step
		(within ComboResetTime), and the previous swing is (almost) finished.
		On accept: CombatState = "Attacking" and SprintBlocked = true on the character for the
		swing's Duration, then CombatState = "Idle". Other clients get the swing effects.

	HitRemote (client -> server: targetModel, position)
		Accepted only if: there is a current swing, the time since it started is inside its
		HitWindow (+/- CombatConfig.HitWindowAllowance for latency), the target has a living
		Humanoid, is within Reach + ReachTolerance, and wasn't already hit by this swing.
		Then DamageService applies Damage * DamageMultiplier (level-scaled there).

	API:
		.AttackStarted  Signal(player, step, definition)
		.HitConfirmed   Signal(player, targetModel, damage)
		.HitRejected    Signal(player, reason)      handy when tuning validation

	See Docs.Combat > "Server validation".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = ReplicatedStorage.Combat
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(Combat.CombatConfig)
local WeaponService = require(script.Parent.WeaponService)
local DamageService = require(script.Parent.DamageService)

local Attr = CombatConfig.Attributes
local Remotes = Combat.Remotes

local CombatService = {
	AttackStarted = Signal.new(),
	HitConfirmed = Signal.new(),
	HitRejected = Signal.new(),
}

type Swing = {
	step: number,
	startTime: number,
	duration: number,
	attack: any,
	definition: any,
	character: Model,
	hit: { [Model]: boolean },
}

local swings: { [Player]: Swing } = {}

local function fireOthers(player: Player, ...)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.EffectRemote:FireClient(other, ...)
		end
	end
end

local function getTargetPosition(model: Model): Vector3
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if root and root:IsA("BasePart") then root.Position else model:GetPivot().Position
end

local function onAttack(player: Player, step: unknown)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local definition = WeaponService:GetEquipped(player)
	if typeof(step) ~= "number" or not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	if not definition or not WeaponService:IsDrawn(player) then
		return
	end
	local attack = definition.Combo[step]
	if not attack or step % 1 ~= 0 then
		return
	end

	local now = os.clock()
	local previous = swings[player]
	if previous and previous.character == character then
		local previousEnd = previous.startTime + previous.duration
		if now < previousEnd - CombatConfig.AttackTimingTolerance then
			CombatService.HitRejected:Fire(player, "attack overlaps previous swing")
			return
		end
		local chained = step == previous.step + 1 and now <= previousEnd + definition.ComboResetTime + CombatConfig.InputBufferTime
		if step ~= 1 and not chained then
			CombatService.HitRejected:Fire(player, "invalid combo step " .. step)
			return
		end
	elseif step ~= 1 then
		return
	end

	local swing: Swing = {
		step = step,
		startTime = now,
		duration = attack.Duration,
		attack = attack,
		definition = definition,
		character = character,
		hit = {},
	}
	swings[player] = swing

	character:SetAttribute(Attr.CombatState, "Attacking")
	character:SetAttribute(Attr.SprintBlocked, true)
	task.delay(attack.Duration, function()
		if swings[player] == swing and character.Parent then
			character:SetAttribute(Attr.CombatState, "Idle")
			character:SetAttribute(Attr.SprintBlocked, false)
		end
	end)

	fireOthers(
		player,
		"Swing",
		character,
		attack.Sound,
		attack.HitWindow[1] * attack.Duration,
		(attack.HitWindow[2] - attack.HitWindow[1]) * attack.Duration
	)
	CombatService.AttackStarted:Fire(player, step, definition)
end

local function onHit(player: Player, target: unknown, position: unknown)
	local swing = swings[player]
	local character = player.Character
	if not swing or swing.character ~= character or not character then
		return
	end
	if typeof(target) ~= "Instance" or not target:IsA("Model") or not target:IsDescendantOf(workspace) then
		return
	end
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if swing.hit[target] then
		return
	end

	local allowance = CombatConfig.HitWindowAllowance
	local elapsed = os.clock() - swing.startTime
	local windowStart = swing.attack.HitWindow[1] * swing.duration - allowance
	local windowEnd = swing.attack.HitWindow[2] * swing.duration + allowance
	if elapsed < windowStart or elapsed > windowEnd then
		CombatService.HitRejected:Fire(player, string.format("outside hit window (%.2fs, window %.2f-%.2f)", elapsed, windowStart, windowEnd))
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetPosition = getTargetPosition(target)
	local distance = root and (root.Position - targetPosition).Magnitude or math.huge
	if distance > swing.definition.Reach + CombatConfig.ReachTolerance then
		CombatService.HitRejected:Fire(player, string.format("out of reach (%.1f studs)", distance))
		return
	end

	if not DamageService:CanDamage(player, humanoid) then
		return
	end
	swing.hit[target] = true

	local damage = DamageService:ApplyDamage(player, humanoid, swing.definition.Damage * swing.attack.DamageMultiplier, {
		Class = swing.definition.Class,
		WeaponId = swing.definition.Id,
	})

	local effectPosition = targetPosition
	if typeof(position) == "Vector3" and (position - targetPosition).Magnitude < 8 then
		effectPosition = position
	end
	fireOthers(player, "Hit", effectPosition)
	CombatService.HitConfirmed:Fire(player, target, damage)
end

function CombatService:Start()
	Remotes.AttackRemote.OnServerEvent:Connect(onAttack)
	Remotes.HitRemote.OnServerEvent:Connect(onHit)
	Players.PlayerRemoving:Connect(function(player)
		swings[player] = nil
	end)
end

return CombatService
