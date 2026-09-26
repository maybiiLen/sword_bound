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
		Effects.ParryFlash(position)                    big golden flash + ring
		Effects.HitStop(track, seconds)                 freezes an AnimationTrack briefly
		Effects.Shake(trauma) / Effects.Punch(studs)    forwarded to the camera (SetCameraHooks)
		Effects.SetCameraHooks({ Shake = fn, Punch = fn })   called once by CombatClient
		Effects.Listen()                                called once by CombatClient

	EffectRemote payloads (server -> client):
		("Swing", character, soundName, trailStart, trailDuration)
		("Hit", position)
		("Block", position)
		("Parry", position)
		("Draw", character, drawn)
		("Sound", parent, soundName)

	See Docs.Combat > "Effects".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Combat = ReplicatedStorage.Combat
local CombatConfig = require(Combat.CombatConfig)
local Sounds = Combat.Assets.Sounds
local HitSparkTemplate = Combat.Assets.VFX.HitSpark

local Effects = {}

local cameraHooks = {}

function Effects.PlaySound(parent: Instance?, soundName: string?)
	local template = soundName and Sounds:FindFirstChild(soundName)
	if not template or not parent then
		return
	end
	local sound = template:Clone()
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, math.max(sound.TimeLength, 1) + 0.5)
end

function Effects.SetTrail(character: Model, enabled: boolean)
	local model = character:FindFirstChild(CombatConfig.WeaponModelName)
	local trail = model and model:FindFirstChild("SwingTrail", true)
	if trail then
		trail.Enabled = enabled
	end
end

local function burst(position: Vector3, color: Color3?, countScale: number, soundName: string)
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
	Effects.PlaySound(holder, soundName)
	Debris:AddItem(holder, 1.5)
end

function Effects.HitSpark(position: Vector3)
	burst(position, nil, 1, "Hit")
end

function Effects.BlockSpark(position: Vector3)
	burst(position, Color3.fromRGB(190, 225, 255), 1.4, "Block")
end

function Effects.ParryFlash(position: Vector3)
	burst(position, Color3.fromRGB(255, 205, 90), 2.5, "Parry")
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
		elseif kind == "Hit" or kind == "Block" or kind == "Parry" then
			local position = ...
			if typeof(position) == "Vector3" then
				if kind == "Hit" then
					Effects.HitSpark(position)
				elseif kind == "Block" then
					Effects.BlockSpark(position)
				else
					Effects.ParryFlash(position)
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
