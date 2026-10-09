--[[
	CombatAudio  (client only, 2026-10-09)
	Layered, varied combat sounds. Replaces the one-file-per-event legacy sounds (swordslash.wav,
	metal.ogg...) for swings, hits, blocks, rolls and draw/sheath. Built from the vault note
	"Combat sound design research (2026-10-09)":
		- every event picks a variant with no immediate repeat, and randomizes pitch (semitones) and
		  volume (dB) per play, so a 4-hit string never sounds like the same file four times
		- hits pick their layer by what was hit (model attribute HitMaterial: Flesh | Armor | Wood,
		  default Flesh) and add a heavy body layer on Heavy and counter hits
		- a hit ducks the swing group for a moment, so the impact reads over the whoosh
		- your own sounds keep full volume out to 20 studs (the camera sits 10-15 studs back), other
		  players' fade from 8 studs (InverseTapered), instead of the old 10000-stud max
		- per-group voice caps (oldest stops first)
	All audio is Pro Sound Effects (creator "ProSoundEffects"), licensed for Roblox experiences.
	Volumes were levelled from each file's measured peak PlaybackLoudness; PeakAt is when the
	loudest point lands (s), used to time whooshes onto the hit frame.

	API:
		CombatAudio.Has(event) -> boolean
		CombatAudio.Play(event, at: Instance | Vector3, options?) -> ()
			options = { HitIn = seconds?, PitchScale = number?, Own = boolean? }
			HitIn: the hit frame is this far away; the chosen variant is delayed (or started part
			way in) so ITS loudest point (PeakAt) lands on that frame
		CombatAudio.PlayHit(position, info?)   info = { Target, Weight, Counter, Own } from Effects.HitSpark
		CombatAudio.EventFor(legacySoundName) -> event?   "Swing" -> "SwingLight" etc.

	See Docs.Combat > "Combat audio".
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local CombatAudio = {}

-- Group: SoundGroup + voice cap. Pitch/Db: random range +/- per play. Variants: Id, Volume,
-- PeakAt (s), optional Region = { start, finish } (PlaybackRegion, seconds).
local BANK = {
	SwingLight = {
		Group = "Swing", Pitch = 1.5, Db = 1.5,
		Variants = {
			{ Id = 9126013639, Volume = 0.45, PeakAt = 0.16 }, -- Swish Med High End Sharp Swords 15
			{ Id = 9126014082, Volume = 0.65, PeakAt = 0.1 }, -- same series 22
			{ Id = 9125496394, Volume = 0.55, PeakAt = 0.05 }, -- Dowel Swish Bamboo Thick 13
		},
	},
	SwingHeavy = {
		Group = "Swing", Pitch = 1, Db = 1,
		Variants = {
			{ Id = 9120716870, Volume = 0.3, PeakAt = 0.5 }, -- Whoosh Fast Swish By 4 (long, light rumble)
			{ Id = 9125495498, Volume = 0.8, PeakAt = 0.05, PitchScale = 0.85 }, -- Dowel Swish 5, lowered
		},
	},
	Thrust = {
		Group = "Swing", Pitch = 1, Db = 1.5,
		Variants = {
			{ Id = 9120704709, Volume = 1.2, PeakAt = 0.1 }, -- Whooshes Fast Wipes Quick Airy Slices 2
			{ Id = 9120705229, Volume = 1.0, PeakAt = 0.28 }, -- Whooshes Wipes Airy Slices 2
		},
	},
	HitFlesh = {
		Group = "Hit", Pitch = 1, Db = 1.5,
		Variants = {
			{ Id = 9113484814, Volume = 1.0, PeakAt = 0.03 }, -- Body Hit 5, blade hits gut
			{ Id = 9113484395, Volume = 1.2, PeakAt = 0.03 }, -- Body Hit 3, blade hits chest
			{ Id = 9114485291, Volume = 1.6, PeakAt = 0.2 }, -- Flesh Slash 11, wet knife slash
		},
	},
	HitArmor = {
		Group = "Hit", Pitch = 1, Db = 1.5,
		Variants = {
			{ Id = 9116554681, Volume = 0.75, PeakAt = 0.03, Region = { 0, 0.5 } }, -- Metal Crown Headgear Hit Clang 2
			{ Id = 9113449297, Volume = 0.5, PeakAt = 0.03 }, -- Blade Hits Metal Rod 4
			{ Id = 9116670099, Volume = 1.8, PeakAt = 0.03 }, -- Metal Impact 7, plate
		},
	},
	HitWood = {
		Group = "Hit", Pitch = 1.5, Db = 1.5,
		Variants = {
			{ Id = 9120951616, Volume = 1.3, PeakAt = 0.03 }, -- Wood Pound Two Wood Poles 21
			{ Id = 9114458290, Volume = 2.0, PeakAt = 0.03 }, -- Fist Hit Sofa 7 (padded dummy thump)
		},
	},
	HitHeavy = { -- extra body layer under heavy and counter hits
		Group = "Hit", Pitch = 0.75, Db = 1,
		Variants = {
			{ Id = 9113565575, Volume = 1.4, PeakAt = 0.03 }, -- Boxing Hits 8, bag whump
			{ Id = 9125402982, Volume = 0.35, PeakAt = 0.03, Region = { 0, 0.9 } }, -- Boom Impact Deep Thumping 5
		},
	},
	Block = {
		Group = "Defense", Pitch = 1, Db = 1.5,
		Variants = {
			{ Id = 9113451338, Volume = 0.7, PeakAt = 0.13 }, -- Blade On Blade Metal Shing 5
			{ Id = 9116633328, Volume = 2.5, PeakAt = 0.06 }, -- Metal Grab Hollow Impact 8 (dull clunk)
		},
	},
	GuardBreak = {
		Group = "Defense", Pitch = 0.5, Db = 0,
		Variants = {
			{ Id = 9116673678, Volume = 0.15, PeakAt = 0.03, Region = { 0, 1.0 } }, -- Metal Impact Heavy Clunking 1
			{ Id = 9119074896, Volume = 2.5, PeakAt = 0.03 }, -- Shield Impacts 6
		},
	},
	Roll = {
		Group = "Foley", Pitch = 1.5, Db = 1.5,
		Variants = {
			{ Id = 9120704709, Volume = 0.8, PeakAt = 0.1, PitchScale = 0.75 }, -- quick airy slice, lowered
			{ Id = 9120705229, Volume = 0.7, PeakAt = 0.28, PitchScale = 0.7 },
		},
	},
	Draw = {
		Group = "Foley", Pitch = 0.5, Db = 1,
		Variants = { { Id = 9116197044, Volume = 0.4, PeakAt = 0.03 } }, -- Knife Shing 102, remove from scabbard
	},
	Sheath = {
		Group = "Foley", Pitch = 0.5, Db = 1,
		Variants = { { Id = 9119748925, Volume = 0.6, PeakAt = 0.1, Region = { 0.25, 1.3 } } }, -- Sword Slide Into Scabbard 2
	},
}

local LEGACY = {
	Swing = "SwingLight",
	HeavySwing = "SwingHeavy",
	Lunge = "Thrust",
	Roll = "Roll",
	Block = "Block",
	GuardBreak = "GuardBreak",
	Draw = "Draw",
	Sheath = "Sheath",
}

local GROUPS = { Swing = 6, Hit = 8, Defense = 4, Foley = 6 } -- voice caps
local OWN_ROLLOFF = { 20, 120 }
local OTHER_ROLLOFF = { Swing = { 8, 70 }, Hit = { 10, 110 }, Defense = { 12, 160 }, Foley = { 6, 45 } }
local DUCK_VOLUME = 0.55 -- swing group volume while a hit plays (about -5 dB)
local DUCK_TIME = 0.15

local soundGroups: { [string]: SoundGroup } = {}
local playing: { [string]: { Sound } } = {}
local lastVariant: { [string]: number } = {}
local duckToken = 0
local restoreTween: Tween? = nil

local function groupFor(name: string): SoundGroup
	local group = soundGroups[name]
	if group and group.Parent then
		return group
	end
	local root = SoundService:FindFirstChild("Combat")
	if not root then
		root = Instance.new("SoundGroup")
		root.Name = "Combat"
		root.Parent = SoundService
	end
	local found = root:FindFirstChild(name)
	if not found then
		found = Instance.new("SoundGroup")
		found.Name = name
		found.Parent = root
	end
	soundGroups[name] = found :: SoundGroup
	return found :: SoundGroup
end

local function pickVariant(event: string, count: number): number
	if count <= 1 then
		return 1
	end
	local last = lastVariant[event]
	local index = math.random(1, count)
	if index == last then
		index = index % count + 1 -- never the same file twice in a row
	end
	lastVariant[event] = index
	return index
end

local function isOwn(at: Instance | Vector3): boolean
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	return typeof(at) == "Instance" and character ~= nil and at:IsDescendantOf(character)
end

local function enforceCap(groupName: string, sound: Sound)
	local list = playing[groupName]
	if not list then
		list = {}
		playing[groupName] = list
	end
	local alive = {}
	for _, other in list do
		-- a whoosh waiting for its HitIn delay counts as playing (Pending attribute)
		if other.Parent and (other.IsPlaying or other:GetAttribute("Pending") == true) then
			table.insert(alive, other)
		end
	end
	table.insert(alive, sound)
	local cap = GROUPS[groupName] or 6
	while #alive > cap do
		local oldest = table.remove(alive, 1)
		if oldest then
			oldest:Stop()
		end
	end
	playing[groupName] = alive
end

local function duckSwings()
	duckToken += 1
	local token = duckToken
	local swing = groupFor("Swing")
	if restoreTween then
		restoreTween:Cancel() -- a running restore would drag the volume back up over this duck
		restoreTween = nil
	end
	swing.Volume = DUCK_VOLUME
	task.delay(DUCK_TIME, function()
		if duckToken == token then
			local tween = TweenService:Create(swing, TweenInfo.new(0.12), { Volume = 1 })
			restoreTween = tween
			tween:Play()
		end
	end)
end

function CombatAudio.Has(event: string?): boolean
	return event ~= nil and BANK[event] ~= nil
end

function CombatAudio.EventFor(legacyName: string?): string?
	return if legacyName then LEGACY[legacyName] else nil
end

local function playNow(event: string, at: Instance | Vector3, options: { PitchScale: number?, Own: boolean?, HitIn: number? }?)
	local entry = BANK[event]
	if not entry then
		return
	end
	local parent: Instance
	if typeof(at) == "Vector3" then
		local attachment = Instance.new("Attachment")
		attachment.Name = "CombatSound"
		attachment.WorldPosition = at
		attachment.Parent = workspace.Terrain
		Debris:AddItem(attachment, 3)
		parent = attachment
	else
		if not at.Parent then
			return
		end
		parent = at
	end
	local variant = entry.Variants[pickVariant(event, #entry.Variants)]
	local sound = Instance.new("Sound")
	sound.Name = event
	sound.SoundId = "rbxassetid://" .. variant.Id
	local semitones = (math.random() * 2 - 1) * (entry.Pitch or 0)
	local decibels = (math.random() * 2 - 1) * (entry.Db or 0)
	sound.PlaybackSpeed = (2 ^ (semitones / 12)) * (variant.PitchScale or 1) * ((options and options.PitchScale) or 1)
	sound.Volume = variant.Volume * (10 ^ (decibels / 20))
	if variant.Region then
		sound.PlaybackRegionsEnabled = true
		sound.PlaybackRegion = NumberRange.new(variant.Region[1], variant.Region[2])
	end
	local own = (options and options.Own) or isOwn(at)
	local rolloff = if own then OWN_ROLLOFF else (OTHER_ROLLOFF[entry.Group] or { 8, 70 })
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = rolloff[1]
	sound.RollOffMaxDistance = rolloff[2]
	sound.SoundGroup = groupFor(entry.Group)
	sound.Parent = parent
	-- line the variant's loudest point up with the hit frame
	local hitIn = options and options.HitIn
	local wait = 0
	if hitIn then
		-- PeakAt is file time; real time = file time / PlaybackSpeed
		local offset = hitIn - (variant.PeakAt or 0) / sound.PlaybackSpeed
		if offset > 0 then
			wait = offset
		elseif offset < 0 then
			local start = if variant.Region then variant.Region[1] else 0
			sound.TimePosition = start - offset * sound.PlaybackSpeed -- skip in so the peak is not late
		end
	end
	if wait > 0 then
		sound:SetAttribute("Pending", true)
		task.delay(wait, function()
			sound:SetAttribute("Pending", nil)
			if sound.Parent then
				sound:Play()
			end
		end)
	else
		sound:Play()
	end
	enforceCap(entry.Group, sound)
	Debris:AddItem(sound, 3.5)
	if entry.Group == "Hit" then
		duckSwings()
	end
end

function CombatAudio.Play(event: string, at: Instance | Vector3, options: { HitIn: number?, PitchScale: number?, Own: boolean? }?)
	if not BANK[event] then
		return
	end
	playNow(event, at, options)
end

-- The hit sound: the material layer, plus the heavy body layer on Heavy or counter hits.
function CombatAudio.PlayHit(position: Vector3, info: any?)
	local target = info and info.Target
	local material = "Flesh"
	if typeof(target) == "Instance" then
		local value = target:GetAttribute("HitMaterial")
		if value == "Armor" or value == "Wood" or value == "Flesh" then
			material = value
		end
	end
	-- info.Own: the local player landed it, so it keeps the own-sound rolloff like your whoosh
	local options = if info and info.Own == true then { Own = true } else nil
	playNow("Hit" .. material, position, options)
	local heavy = info and (info.Weight == "Heavy" or info.Counter == true)
	if heavy then
		playNow("HitHeavy", position, options)
	end
end

return CombatAudio

