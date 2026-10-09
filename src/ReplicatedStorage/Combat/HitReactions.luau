--[[
	HitReactions  (client only, 2026-10-09)
	Plays hit reactions on NON-player targets (Sparring Knight, mobs, bosses, training dummies),
	locally on each client. The attacking client predicts the reaction the moment its blade connects
	(WeaponBehaviors.Sword); every other client gets the server's "React" effect (Effects.Listen).
	CombatRules.HitReaction picks the reaction, so both sides agree.

	- R15 rigs play the Specs clips (HitLight*, HitHeavy*, ArmorTwitch) with fade 0, so the enemy
	  snaps straight to the peak pose, frozen for the hitstop, then eases out (research: start on the
	  hit pose, hold through the freeze). Reactions are Action2, so the enemy's next attack (Action3)
	  or a stagger (Action4) takes over. ArmorTwitch blends at HitReaction.TwitchWeight over the
	  enemy's own attack and fades out early so it never pops.
	- Other rigs with a root Motor6D (custom mob rigs) get a procedural tilt of the root joint.
	- Static models (the training dummy: anchored parts, no joints) rock away from the attacker
	  around their base, locally (the server never sees it).
	- Player characters are skipped: their own client plays their flinch and it replicates.

	API:
		HitReactions.Play(model, reaction, freezeSeconds?, attackerPosition?)

	See Docs.Combat > "Hit reactions".
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = ReplicatedStorage.Combat
local CombatConfig = require(Combat.CombatConfig)
local AnimationSet = require(Combat.Animations.AnimationSet)

local REACTIONS = { "HitLightFront", "HitLightLeft", "HitLightRight", "HitLightBack", "HitHeavyFront", "HitHeavyBack", "ArmorTwitch" }

-- procedural tilt for rigs without the clips: { pitch, yaw } degrees at the peak
local TILT = {
	HitLightFront = { 10, 0 },
	HitLightBack = { -10, 0 },
	HitLightLeft = { 2, -12 },
	HitLightRight = { 2, 12 },
	HitHeavyFront = { 18, 0 },
	HitHeavyBack = { -18, 0 },
	ArmorTwitch = { 3, 2 },
}

local HitReactions = {}

-- strong tables (Instances can drop out of weak-keyed tables while they still exist), cleared when
-- the model is destroyed
local sets: { [Model]: any } = {}
local tilts: { [Model]: {} } = {}
local watched: { [Model]: boolean } = {}
local twitchTokens: { [Model]: {} } = {}
local wobbles: { [Model]: { token: {}, original: CFrame } } = {}

local function watch(model: Model)
	if watched[model] then
		return
	end
	watched[model] = true
	model.Destroying:Once(function()
		local set = sets[model]
		if set then
			set:Destroy()
		end
		sets[model] = nil
		tilts[model] = nil
		wobbles[model] = nil
		twitchTokens[model] = nil
		watched[model] = nil
	end)
end

local function animationSetFor(model: Model, humanoid: Humanoid)
	local set = sets[model]
	if set then
		return set
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	set = AnimationSet.new(animator :: Animator, false)
	sets[model] = set
	return set
end

local function playClip(model: Model, humanoid: Humanoid, reaction: string, freeze: number): boolean
	local set = animationSetFor(model, humanoid)
	local track = set:Get(reaction)
	if not track then
		return false
	end
	for _, name in REACTIONS do
		if name ~= reaction then
			set:Stop(name, 0.05)
		end
	end
	local weight = 1
	if reaction == "ArmorTwitch" then
		weight = CombatConfig.HitReaction.TwitchWeight
	end
	track:Play(0, weight, 1)
	track.TimePosition = 0
	if freeze > 0 then
		track:AdjustSpeed(0)
		task.delay(freeze, function()
			if track.IsPlaying then
				track:AdjustSpeed(1)
			end
		end)
	end
	if reaction == "ArmorTwitch" then
		-- fade it out before its neutral last key, so the enemy's attack pose doesn't snap back
		local token = {}
		twitchTokens[model] = token
		task.delay(freeze + 0.12, function()
			if twitchTokens[model] == token and track.IsPlaying then
				track:Stop(0.08)
			end
		end)
	end
	return true
end

local function rootJoint(model: Model): Motor6D?
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	for _, child in root:GetChildren() do
		if child:IsA("Motor6D") then
			return child
		end
	end
	return nil
end

local function playTilt(model: Model, reaction: string, freeze: number)
	local joint = rootJoint(model)
	local angles = TILT[reaction]
	if not joint or not angles then
		return
	end
	local peak = CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), 0)
	local heavy = string.find(reaction, "Heavy", 1, true) ~= nil
	local length = if heavy then 0.55 else 0.32
	local token = {}
	tilts[model] = token
	joint.Transform = peak
	task.spawn(function()
		task.wait(freeze + 0.04)
		local started = os.clock()
		while tilts[model] == token and joint.Parent do
			local alpha = (os.clock() - started) / length
			if alpha >= 1 then
				joint.Transform = CFrame.identity
				break
			end
			local remaining = (1 - alpha) * (1 - alpha)
			joint.Transform = CFrame.identity:Lerp(peak, remaining)
			RunService.RenderStepped:Wait()
		end
	end)
end

-- degrees a static model rocks away from the hit
local WOBBLE = { Light = 7, Heavy = 12, Twitch = 3 }

local function playWobble(model: Model, reaction: string, freeze: number, attackerPosition: Vector3?)
	local running = wobbles[model]
	local original = if running then running.original else model:GetPivot()
	local boxCFrame, size = model:GetBoundingBox()
	local basePosition = boxCFrame.Position - Vector3.new(0, size.Y / 2, 0)
	local away = original.LookVector * -1
	if attackerPosition then
		local offset = basePosition - attackerPosition
		local flatOffset = Vector3.new(offset.X, 0, offset.Z)
		if flatOffset.Magnitude > 1e-3 then
			away = flatOffset.Unit
		end
	end
	local degrees = WOBBLE.Light
	if reaction == "ArmorTwitch" then
		degrees = WOBBLE.Twitch
	elseif string.find(reaction, "Heavy", 1, true) then
		degrees = WOBBLE.Heavy
	end
	-- rotate about the horizontal axis perpendicular to the push, through the base
	local axis = Vector3.yAxis:Cross(away)
	if axis.Magnitude < 1e-3 then
		return
	end
	axis = axis.Unit
	local function tilted(angle: number): CFrame
		local rotation = CFrame.fromAxisAngle(axis, math.rad(angle))
		local relative = original - basePosition
		return CFrame.new(basePosition) * rotation * relative
	end
	local token = {}
	wobbles[model] = { token = token, original = original }
	model:PivotTo(tilted(degrees))
	local length = if degrees >= WOBBLE.Heavy then 0.5 else 0.3
	task.spawn(function()
		task.wait(freeze + 0.03)
		local started = os.clock()
		while true do
			local entry = wobbles[model]
			if not entry or entry.token ~= token or not model.Parent then
				return
			end
			local alpha = (os.clock() - started) / length
			if alpha >= 1 then
				model:PivotTo(original)
				wobbles[model] = nil
				return
			end
			-- damped swing: past upright a little, then settle
			local swing = math.cos(alpha * math.pi * 1.5) * (1 - alpha)
			model:PivotTo(tilted(degrees * swing))
			RunService.RenderStepped:Wait()
		end
	end)
end

function HitReactions.Play(model: Instance?, reaction: string?, freezeSeconds: number?, attackerPosition: Vector3?)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or typeof(reaction) ~= "string" then
		return
	end
	if Players:GetPlayerFromCharacter(model) then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local freeze = freezeSeconds or 0
	watch(model)
	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15 and model:FindFirstChild("UpperTorso") ~= nil
	if isR15 and playClip(model, humanoid, reaction, freeze) then
		return
	end
	if rootJoint(model) then
		playTilt(model, reaction, freeze)
		return
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and root.Anchored then
		playWobble(model, reaction, freeze, attackerPosition)
	end
end

return HitReactions

