--[[
	Effects  (client only)
	Cosmetic combat effects: sounds, trails, sparks, hit-stop, camera shake. Nothing here
	affects gameplay.

	The acting client calls these directly for instant feedback; every OTHER client gets the
	same effects through Combat.Remotes.EffectRemote (fired by the server), handled in
	Effects.Listen(). So the attacker never sees an effect twice.

	API:
		Effects.PlaySound(parent, soundName)            Sound from Combat.Assets.Sounds
		Effects.SetTrail(character, enabled)            the SwingTrail on the character's weapon
		Effects.HitSpark(position)
		Effects.BlockSpark(position)                    pale sparks + clang
		Effects.ParryFlash(position, perfect?, attacker?)   gold spark burst + star flash + shockwave, layered
		                                                clang whose pitch rises on consecutive parries,
		                                                gold flash + short freeze on the attacker; perfect
		                                                parries add an impact frame for nearby cameras
		Effects.FlashModel(model, color, seconds)       Highlight flash that fades out
		Effects.FreezeModel(model, seconds)             hit-stop every playing track on a character
		Effects.ImpactFrame(position)                   1-2 frame high-contrast "anime" flash if the camera is near
		Effects.HitStop(track, seconds)                 freezes an AnimationTrack briefly
		Effects.Shake(trauma) / Effects.Punch(studs)    forwarded to the camera (SetCameraHooks)
		Effects.SetCameraHooks({ Shake = fn, Punch = fn })   called once by CombatClient
		Effects.Listen()                                called once by CombatClient

	EffectRemote payloads (server -> client):
		("Swing", character, soundName, trailStart, trailDuration)
		("Hit", position)
		("Block", position)
		("Parry" | "PerfectParry", position, attackerModel?)
		("Draw", character, drawn)
		("Sound", parent, soundName)

	See Docs.Combat > "Effects".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Combat = ReplicatedStorage.Combat
local CombatConfig = require(Combat.CombatConfig)
local Sounds = Combat.Assets.Sounds
local HitSparkTemplate = Combat.Assets.VFX.HitSpark

local Effects = {}

local cameraHooks = {}

function Effects.PlaySound(parent: Instance?, soundName: string?, pitchScale: number?)
	local template = soundName and Sounds:FindFirstChild(soundName)
	if not template or not parent then
		return
	end
	local sound = template:Clone()
	if pitchScale then
		sound.PlaybackSpeed = sound.PlaybackSpeed * pitchScale
	end
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, math.max(sound.TimeLength, 2.5) + 0.5)
end

function Effects.SetTrail(character: Model, enabled: boolean)
	local model = character:FindFirstChild(CombatConfig.WeaponModelName)
	local trail = model and model:FindFirstChild("SwingTrail", true)
	if trail then
		trail.Enabled = enabled
	end
end

local function burst(position: Vector3, color: Color3?, countScale: number, soundName: string, pitchScale: number?): Part
	local holder = Instance.new("Part")
	holder.Name = "EffectHolder"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = position
	local spark = HitSparkTemplate:Clone()
	spark.Parent = holder
	holder.Parent = workspace
	for _, emitter in spark:GetChildren() do
		if emitter:IsA("ParticleEmitter") then
			if color then
				emitter.Color = ColorSequence.new(color)
			end
			emitter:Emit(math.ceil((emitter:GetAttribute("EmitCount") or 10) * countScale))
		end
	end
	Effects.PlaySound(holder, soundName, pitchScale)
	Debris:AddItem(holder, 3)
	return holder
end

local PARRY_GOLD = Color3.fromRGB(255, 196, 70)
local PARRY_STREAK_RESET = 1.5 -- seconds without a parry before the clang pitch resets
local PARRY_PITCH_STEP = 0.04 -- each consecutive parry rings this much higher (max 6 steps)
local parryStreak = 0
local lastParryAt = -math.huge

local function randomPitch(range: number): number
	return 1 + (math.random() * 2 - 1) * range
end

local function shockwave(position: Vector3, color: Color3, size: number, duration: number)
	local ring = Instance.new("Part")
	ring.Name = "ParryShockwave"
	ring.Shape = Enum.PartType.Ball
	ring.Material = Enum.Material.ForceField
	ring.Color = color
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Size = Vector3.one * 0.6
	ring.Position = position
	ring.Parent = workspace
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = Vector3.one * size, Transparency = 1 }):Play()
	Debris:AddItem(ring, duration + 0.05)
end

local function starFlash(holder: BasePart, color: Color3, size: number)
	local star = Instance.new("ParticleEmitter")
	star.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	star.LightEmission = 1
	star.LightInfluence = 0
	star.Color = ColorSequence.new(color)
	star.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	star.Lifetime = NumberRange.new(0.14)
	star.Speed = NumberRange.new(0)
	star.Rotation = NumberRange.new(0, 360)
	star.ZOffset = 1
	star.Enabled = false
	star.Parent = holder
	star:Emit(2)
end

function Effects.HitSpark(position: Vector3)
	burst(position, nil, 1, "Hit", randomPitch(0.06))
end

-- Blocks stay deliberately dull (small pale spark, low clunk) so a parry is obvious by ear alone.
function Effects.BlockSpark(position: Vector3)
	burst(position, Color3.fromRGB(200, 215, 230), 0.8, "Block", randomPitch(0.04))
end

function Effects.FlashModel(model: Instance?, color: Color3, seconds: number)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return
	end
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.15
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(highlight, info, { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(highlight, seconds + 0.1)
end

function Effects.FreezeModel(model: Instance?, seconds: number)
	if typeof(model) ~= "Instance" then
		return
	end
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return
	end
	for _, track in animator:GetPlayingAnimationTracks() do
		Effects.HitStop(track, seconds)
	end
end

local impactFrame: ColorCorrectionEffect? = nil
function Effects.ImpactFrame(position: Vector3)
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - position).Magnitude > 60 then
		return
	end
	if impactFrame == nil or impactFrame.Parent ~= camera then
		impactFrame = Instance.new("ColorCorrectionEffect")
		impactFrame.Name = "ImpactFrame"
		impactFrame.Enabled = false
		impactFrame.Parent = camera
	end
	local effect = impactFrame :: ColorCorrectionEffect
	-- frame 1: blown-out white, frame 2: crushed dark, then back to normal
	effect.TintColor = Color3.new(1, 1, 1)
	effect.Saturation = -1
	effect.Contrast = 2
	effect.Brightness = 0.25
	effect.Enabled = true
	task.delay(0.05, function()
		effect.Brightness = -0.3
		effect.Contrast = 3
	end)
	task.delay(0.1, function()
		effect.Enabled = false
	end)
end

function Effects.ParryFlash(position: Vector3, perfect: boolean?, attacker: Instance?)
	local now = os.clock()
	if now - lastParryAt <= PARRY_STREAK_RESET then
		parryStreak = math.min(parryStreak + 1, 6)
	else
		parryStreak = 0
	end
	lastParryAt = now
	local pitch = 1 + parryStreak * PARRY_PITCH_STEP
	if perfect then
		pitch *= 1.08
	end

	local holder = burst(position, PARRY_GOLD, if perfect then 6 else 4, "Parry", pitch)
	Effects.PlaySound(holder, "ParryRing", pitch)
	starFlash(holder, Color3.fromRGB(255, 240, 200), if perfect then 9 else 6)
	shockwave(position, PARRY_GOLD, if perfect then 9 else 6, if perfect then 0.3 else 0.22)

	local freeze = if perfect then CombatConfig.HitStop.PerfectParry else CombatConfig.HitStop.Parry
	Effects.FreezeModel(attacker, freeze)
	Effects.FlashModel(attacker, if perfect then Color3.new(1, 1, 1) else PARRY_GOLD, 0.3)
	if perfect then
		Effects.ImpactFrame(position)
	end
end

function Effects.HitStop(track: AnimationTrack?, seconds: number)
	if not track or not track.IsPlaying or seconds <= 0 then
		return
	end
	local speed = track.Speed
	track:AdjustSpeed(0.05)
	task.delay(seconds, function()
		if track.IsPlaying and track.Speed < 0.1 then
			track:AdjustSpeed(if speed > 0.1 then speed else 1)
		end
	end)
end

function Effects.SetCameraHooks(hooks: { Shake: ((number) -> ())?, Punch: ((number) -> ())? })
	cameraHooks = hooks
end

function Effects.Shake(trauma: number)
	if cameraHooks.Shake then
		cameraHooks.Shake(trauma)
	end
end

function Effects.Punch(studs: number)
	if cameraHooks.Punch then
		cameraHooks.Punch(studs)
	end
end

function Effects.Listen()
	Combat.Remotes.EffectRemote.OnClientEvent:Connect(function(kind: string, ...)
		if kind == "Swing" then
			local character, soundName, trailStart, trailDuration = ...
			if typeof(character) ~= "Instance" then
				return
			end
			Effects.PlaySound(character:FindFirstChild("HumanoidRootPart"), soundName)
			task.delay(trailStart or 0, function()
				Effects.SetTrail(character, true)
				task.delay(trailDuration or 0.2, Effects.SetTrail, character, false)
			end)
		elseif kind == "Hit" or kind == "Block" or kind == "Parry" or kind == "PerfectParry" then
			local position, model = ...
			if typeof(position) == "Vector3" then
				if kind == "Hit" then
					Effects.HitSpark(position)
				elseif kind == "Block" then
					Effects.BlockSpark(position)
				else
					Effects.ParryFlash(position, kind == "PerfectParry", model)
				end
			end
		elseif kind == "Draw" then
			local character, drawn = ...
			if typeof(character) == "Instance" then
				Effects.PlaySound(character:FindFirstChild("HumanoidRootPart"), if drawn then "Draw" else "Sheath")
			end
		elseif kind == "Sound" then
			local parent, soundName = ...
			if typeof(parent) == "Instance" then
				Effects.PlaySound(parent, soundName)
			end
		end
	end)
end

return Effects
