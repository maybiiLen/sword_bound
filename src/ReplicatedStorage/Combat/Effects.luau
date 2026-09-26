--[[
	Effects  (client only)
	Cosmetic combat effects: sounds, trails, hit sparks. Nothing here affects gameplay.

	The attacking client calls these directly for instant feedback; every OTHER client gets
	the same effects through Combat.Remotes.EffectRemote (fired by the server), handled in
	Effects.Listen(). So the attacker never sees an effect twice.

	API:
		Effects.PlaySound(parent, soundName)            Sound from Combat.Assets.Sounds
		Effects.SetTrail(character, enabled)            the SwingTrail on the character's weapon
		Effects.HitSpark(position)
		Effects.Listen()                                called once by CombatClient

	EffectRemote payloads (server -> client):
		("Swing", character, soundName, trailStart, trailDuration)
		("Hit", position)
		("Draw", character, drawn)

	See Docs.Combat > "Effects".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Combat = ReplicatedStorage.Combat
local CombatConfig = require(Combat.CombatConfig)
local Sounds = Combat.Assets.Sounds
local HitSparkTemplate = Combat.Assets.VFX.HitSpark

local Effects = {}

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

function Effects.HitSpark(position: Vector3)
	local holder = Instance.new("Part")
	holder.Name = "HitSparkHolder"
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
			emitter:Emit(emitter:GetAttribute("EmitCount") or 10)
		end
	end
	Effects.PlaySound(holder, "Hit")
	Debris:AddItem(holder, 1.5)
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
		elseif kind == "Hit" then
			local position = ...
			if typeof(position) == "Vector3" then
				Effects.HitSpark(position)
			end
		elseif kind == "Draw" then
			local character, drawn = ...
			if typeof(character) == "Instance" then
				Effects.PlaySound(character:FindFirstChild("HumanoidRootPart"), if drawn then "Draw" else "Sheath")
			end
		end
	end)
end

return Effects
