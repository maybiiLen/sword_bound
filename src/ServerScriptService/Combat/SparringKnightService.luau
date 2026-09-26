--[[
	SparringKnightService  (server only)
	A simple sword NPC for practising the defensive game: it walks up, circles into range and
	throws one of two telegraphed attacks with hyper armor, so you have to roll, block or parry
	instead of trading hits. Break its poise (or parry it) to stagger it and land crits.

	Setup: any R15 Model tagged "SparringKnight" (CombatConfig.EnemyTag) with a Humanoid, a
	HumanoidRootPart and a sword model named "WeaponModel" (needs a SwingTrail for the trail).
	Also tag it "TrainingDummy" so DummyService respawns it. Useful attributes on the model:
		XPReward, MaxPoise (PoiseService), AggroRange (default 40)

	Animation: runtime-registered animations can't replicate from the server, so the server only
	sets the model attribute KnightAction = "<AnimationName>|<serial>" and every client plays it
	locally (StarterPlayerScripts.Combat.KnightAnimator). Hit timing comes from the same
	Animations.Specs markers.

	Hits go through DamageService:ResolveHit, so dodges (IFrames), blocks and parries all work.
	See Docs.Combat > "Sparring knight".
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = ReplicatedStorage.Combat
local CombatConfig = require(Combat.CombatConfig)
local AnimationLibrary = require(Combat.Animations.AnimationLibrary)
local DamageService = require(script.Parent.DamageService)
local PoiseService = require(script.Parent.PoiseService)

local Remotes = Combat.Remotes

local ATTACKS = {
	{ Animation = "KnightSlash", Damage = 10, PoiseDamage = 22, Reach = 7, Arc = 150, Sound = "Swing", Weight = 2 },
	{ Animation = "KnightDelayedChop", Damage = 18, PoiseDamage = 42, Reach = 7.5, Arc = 70, Sound = "HeavySwing", Weight = 1 },
}
local WALK_SPEED = 10
local ATTACK_RANGE = 6.5
local KEEP_DISTANCE = 4.5
local TRACK_UNTIL_BEFORE_HIT = 0.3 -- stops turning this long before HitStart (commits to the swing)
local COOLDOWN = NumberRange.new(1.3, 2.6)
local TURN_SPEED = 8

local SparringKnightService = {}

type Knight = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	align: AlignOrientation,
	state: string, -- "Idle" | "Attacking" | "Staggered"
	token: number,
	serial: number,
	nextAttackAt: number,
	facing: Vector3?,
}

local knights: { [Model]: Knight } = {}

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else Vector3.zero
end

local function playAction(knight: Knight, animation: string)
	knight.serial += 1
	knight.model:SetAttribute("KnightAction", animation .. "|" .. knight.serial)
end

local function findTarget(knight: Knight): (Model?, Humanoid?)
	local range = knight.model:GetAttribute("AggroRange") or 40
	local best, bestHumanoid, bestDistance = nil, nil, range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 then
			local distance = (root.Position - knight.root.Position).Magnitude
			if distance < bestDistance then
				best, bestHumanoid, bestDistance = character, humanoid, distance
			end
		end
	end
	return best, bestHumanoid
end

local function pickAttack()
	local total = 0
	for _, attack in ATTACKS do
		total += attack.Weight
	end
	local roll = math.random() * total
	for _, attack in ATTACKS do
		roll -= attack.Weight
		if roll <= 0 then
			return attack
		end
	end
	return ATTACKS[1]
end

local function inArc(knight: Knight, targetRoot: BasePart, attack): boolean
	local offset = targetRoot.Position - knight.root.Position
	if Vector3.new(offset.X, 0, offset.Z).Magnitude > attack.Reach or math.abs(offset.Y) > 5 then
		return false
	end
	local look = flat(knight.root.CFrame.LookVector)
	return look:Dot(flat(offset)) >= math.cos(math.rad(attack.Arc / 2))
end

local function attack(knight: Knight, target: Model)
	local chosen = pickAttack()
	knight.token += 1
	local myToken = knight.token
	knight.state = "Attacking"
	knight.humanoid:Move(Vector3.zero)
	knight.humanoid.WalkSpeed = 0
	playAction(knight, chosen.Animation)

	local hitStart = AnimationLibrary.MarkerTime(chosen.Animation, "HitStart") or 0.5
	local hitEnd = AnimationLibrary.MarkerTime(chosen.Animation, "HitEnd") or hitStart + 0.15
	local length = AnimationLibrary.Length(chosen.Animation)
	for _, player in Players:GetPlayers() do
		Remotes.EffectRemote:FireClient(player, "Swing", knight.model, chosen.Sound, hitStart, hitEnd - hitStart)
	end

	local start = os.clock()
	local hit: { [Model]: boolean } = {}
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if knight.token ~= myToken or knight.humanoid.Health <= 0 then
			connection:Disconnect()
			return
		end
		local elapsed = os.clock() - start
		local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
		if targetRoot and elapsed < hitStart - TRACK_UNTIL_BEFORE_HIT then
			knight.facing = flat(targetRoot.Position - knight.root.Position)
		end
		if elapsed >= hitStart and elapsed <= hitEnd then
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if character and humanoid and root and not hit[character] and inArc(knight, root, chosen) then
					hit[character] = true
					DamageService:ResolveHit({
						Attacker = knight.model,
						Target = humanoid,
						Damage = chosen.Damage,
						PoiseDamage = chosen.PoiseDamage,
						Position = root.Position + Vector3.new(0, 0.5, 0),
					})
				end
			end
		end
		if elapsed >= length then
			connection:Disconnect()
			if knight.token == myToken and knight.state == "Attacking" then
				knight.state = "Idle"
				knight.humanoid.WalkSpeed = WALK_SPEED
				knight.nextAttackAt = os.clock() + COOLDOWN.Min + math.random() * (COOLDOWN.Max - COOLDOWN.Min)
			end
		end
	end)
end

local function step(knight: Knight, dt: number)
	if knight.humanoid.Health <= 0 then
		return
	end
	if knight.state == "Idle" then
		local target = findTarget(knight)
		local targetRoot = target and target:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not target or not targetRoot then
			knight.humanoid:Move(Vector3.zero)
			knight.facing = nil
		else
			local offset = targetRoot.Position - knight.root.Position
			local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
			knight.facing = flat(offset)
			if distance > KEEP_DISTANCE + 0.5 then
				knight.humanoid:Move(flat(offset))
			else
				knight.humanoid:Move(Vector3.zero)
			end
			if distance <= ATTACK_RANGE and os.clock() >= knight.nextAttackAt then
				attack(knight, target)
			end
		end
	end

	if knight.facing and knight.facing.Magnitude > 0 then
		local current = knight.align.CFrame.LookVector
		local blended = current:Lerp(knight.facing, math.min(1, dt * TURN_SPEED))
		if blended.Magnitude > 1e-3 then
			knight.align.CFrame = CFrame.lookAlong(Vector3.zero, flat(blended))
		end
		knight.align.Enabled = true
	else
		knight.align.Enabled = false
	end
end

local function register(model: Instance)
	if knights[model] or not model:IsA("Model") or not model:IsDescendantOf(workspace) then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		warn(`[SparringKnight] {model:GetFullName()} needs a Humanoid and HumanoidRootPart`)
		return
	end

	humanoid.WalkSpeed = WALK_SPEED
	humanoid.AutoRotate = false
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local attachment = root:FindFirstChild("KnightFacingAttachment") or Instance.new("Attachment")
	attachment.Name = "KnightFacingAttachment"
	attachment.Parent = root
	local align = Instance.new("AlignOrientation")
	align.Name = "KnightFacing"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment :: Attachment
	align.RigidityEnabled = false
	align.Responsiveness = 30
	align.MaxTorque = 1e6
	align.CFrame = CFrame.lookAlong(Vector3.zero, flat(root.CFrame.LookVector))
	align.Parent = root

	local knight: Knight = {
		model = model,
		humanoid = humanoid,
		root = root,
		align = align,
		state = "Idle",
		token = 0,
		serial = 0,
		nextAttackAt = os.clock() + 1,
		facing = nil,
	}
	knights[model] = knight
	model:SetAttribute(CombatConfig.Attributes.CombatState, "Idle")

	humanoid.Died:Once(function()
		knight.token += 1
		knight.state = "Dead"
		align.Enabled = false
	end)
	model.Destroying:Once(function()
		knights[model] = nil
	end)
end

function SparringKnightService:Start()
	PoiseService.Staggered:Connect(function(model: Model, kind: string, duration: number)
		local knight = knights[model]
		if not knight or knight.humanoid.Health <= 0 then
			return
		end
		knight.token += 1
		knight.state = "Staggered"
		knight.facing = nil
		knight.humanoid:Move(Vector3.zero)
		knight.humanoid.WalkSpeed = 0
		playAction(knight, if kind == "GuardBreak" then "GuardBreak" else "Stagger")
	end)
	PoiseService.StaggerEnded:Connect(function(model: Model)
		local knight = knights[model]
		if knight and knight.state == "Staggered" and knight.humanoid.Health > 0 then
			knight.state = "Idle"
			knight.humanoid.WalkSpeed = WALK_SPEED
			knight.nextAttackAt = os.clock() + 0.4
			playAction(knight, "")
		end
	end)
	PoiseService.Flinched:Connect(function(model: Model)
		local knight = knights[model]
		if knight and knight.state == "Idle" then
			playAction(knight, "Flinch")
			knight.nextAttackAt = math.max(knight.nextAttackAt, os.clock() + CombatConfig.FlinchTime)
		end
	end)

	CollectionService:GetInstanceAddedSignal(CombatConfig.EnemyTag):Connect(register)
	for _, model in CollectionService:GetTagged(CombatConfig.EnemyTag) do
		register(model)
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, knight in knights do
			step(knight, dt)
		end
	end)
end

return SparringKnightService
