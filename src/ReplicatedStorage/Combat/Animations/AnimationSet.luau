--[[
	AnimationSet
	Lazily loads and caches combat AnimationTracks for one Animator, by AnimationLibrary name.
	Used by the local player's weapon behavior and by server-side NPCs alike.

	API:
		AnimationSet.new(animator, isR6?) -> set
		set:Get(name) -> AnimationTrack?           loads on first use
		set:Play(name, fadeTime?, speed?) -> AnimationTrack?
		set:Stop(name, fadeTime?)
		set:StopAll(fadeTime?, keep?: { [name]: true })
		set:Preload({ name })
		set:Destroy()

	See Docs.Combat > "Animation pipeline".
]]

local ContentProvider = game:GetService("ContentProvider")

local AnimationLibrary = require(script.Parent.AnimationLibrary)

local AnimationSet = {}
AnimationSet.__index = AnimationSet

function AnimationSet.new(animator: Animator, isR6: boolean?)
	local self = setmetatable({}, AnimationSet)
	self.Animator = animator
	self.IsR6 = isR6 == true
	self.Tracks = {} :: { [string]: AnimationTrack | false }
	self._animations = {} :: { Animation }
	return self
end

function AnimationSet:Get(name: string): AnimationTrack?
	local cached = self.Tracks[name]
	if cached ~= nil then
		return cached or nil
	end
	local id = AnimationLibrary.GetId(name, self.IsR6)
	if not id then
		self.Tracks[name] = false
		return nil
	end
	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = id
	table.insert(self._animations, animation)
	local ok, track = pcall(self.Animator.LoadAnimation, self.Animator, animation)
	if not ok then
		warn(`[AnimationSet] Failed to load '{name}': {track}`)
		self.Tracks[name] = false
		return nil
	end
	track.Priority = AnimationLibrary.Priority(name)
	track.Looped = AnimationLibrary.IsLooped(name)
	self.Tracks[name] = track
	return track
end

function AnimationSet:Play(name: string, fadeTime: number?, speed: number?): AnimationTrack?
	local track = self:Get(name)
	if track then
		track:Play(fadeTime or 0.1, 1, speed or 1)
	end
	return track
end

function AnimationSet:Stop(name: string, fadeTime: number?)
	local track = self.Tracks[name]
	if track and track.IsPlaying then
		track:Stop(fadeTime or 0.15)
	end
end

function AnimationSet:StopAll(fadeTime: number?, keep: { [string]: boolean }?)
	for name, track in self.Tracks do
		if track and track.IsPlaying and not (keep and keep[name]) then
			track:Stop(fadeTime or 0.15)
		end
	end
end

function AnimationSet:Preload(names: { string })
	local animations = {}
	for _, name in names do
		local track = self:Get(name)
		if track then
			table.insert(animations, track.Animation)
		end
	end
	task.spawn(pcall, ContentProvider.PreloadAsync, ContentProvider, animations)
end

function AnimationSet:Destroy()
	for _, track in self.Tracks do
		if track then
			track:Stop(0)
			track:Destroy()
		end
	end
	table.clear(self.Tracks)
	for _, animation in self._animations do
		animation:Destroy()
	end
	table.clear(self._animations)
end

return AnimationSet
