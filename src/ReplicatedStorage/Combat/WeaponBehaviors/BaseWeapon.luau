--[[
	BaseWeapon  (client behavior base class)
	Everything every weapon type shares: the drawn guard pose, the block pose, the heavy charge
	pose, and playing one attack with its timeline. The timeline (hit window open/close, Lunge,
	CancelOpen, end) is driven from the attack animation's markers in Animations.Specs, measured
	on the track's own clock, so hit-stop (slowing the track) delays everything consistently.

	It does NOT decide when to attack; that's WeaponController's state machine.
	It does NOT deal damage; it reports hits to the server with :ReportHit().

	Subclass hooks (override only what differs; see WeaponBehaviors.Sword):
		:OnDrawnChanged(drawn)
		:OnAttackStart(attack)
		:OnHitWindowOpen(attack)
		:OnHitWindowClose(attack)
		:OnAttackEnd(attack)

	API (used by WeaponController):
		BaseWeapon.new(definition, character, model, animationSet) -> weapon
		weapon:SetDrawn(drawn)
		weapon:SetBlocking(blocking)
		weapon:StartCharge() / weapon:StopCharge()
		weapon:PlayAttack(attack, callbacks?) -> AnimationTrack?
			callbacks: { Lunge, HitStart, HitEnd, CancelOpen, RollOpen, MoveOpen, Ended } (all optional)
			Ended fires at the MoveOpen marker (AnimationLibrary.ActionLength). The track keeps
			playing its settle after that; :StopSettle(fade) ends it (moving, blocking, charging,
			a new attack and :CancelAttack() all stop it).
		weapon:GetAttackTrack() -> AnimationTrack?
		weapon:CancelAttack()
		weapon:StopSettle(fadeTime?)
		weapon:HasSettle() -> boolean
		weapon:ReportHit(targetModel, position)   also calls weapon.HitLanded(target) if set
		weapon:Destroy()

	Subclass pattern:
		local Bow = setmetatable({}, { __index = BaseWeapon })
		Bow.__index = Bow
		function Bow.new(...) local self = setmetatable(BaseWeapon.new(...), Bow) ... return self end

	See Docs.Combat > "Adding a weapon type".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local AnimationLibrary = require(ReplicatedStorage.Combat.Animations.AnimationLibrary)

local HitRemote = ReplicatedStorage.Combat.Remotes.HitRemote

local MARKER_ORDER = { "Lunge", "HitStart", "HitEnd", "CancelOpen", "RollOpen" }

local BaseWeapon = {}
BaseWeapon.__index = BaseWeapon

function BaseWeapon.new(definition, character: Model, model: Model, animationSet)
	local self = setmetatable({}, BaseWeapon)
	self.Definition = definition
	self.Character = character
	self.Model = model
	self.Anims = animationSet
	self.Drawn = false
	self.Blocking = false
	self.Trove = Trove.new()
	self._attack = nil
	self._settleTrack = nil

	local names = { definition.IdleAnimation, definition.BlockAnimation, definition.Heavy.ChargeAnimation, definition.Heavy.Animation }
	for _, attack in definition.Combo do
		table.insert(names, attack.Animation)
	end
	if definition.Riposte then
		table.insert(names, definition.Riposte.Animation)
	end
	for _, field in { "RunningAttack", "JumpAttack", "RollAttack", "GuardCounter" } do
		local attack = definition[field]
		if attack then
			table.insert(names, attack.Animation)
		end
	end
	animationSet:Preload(names)
	return self
end

function BaseWeapon:SetDrawn(drawn: boolean)
	if self.Drawn == drawn then
		return
	end
	self.Drawn = drawn
	if drawn then
		self.Anims:Play(self.Definition.IdleAnimation, 0.2)
	else
		self:CancelAttack()
		self:StopCharge()
		self:SetBlocking(false)
		self.Anims:Stop(self.Definition.IdleAnimation, 0.2)
	end
	self:OnDrawnChanged(drawn)
end

function BaseWeapon:SetBlocking(blocking: boolean)
	if self.Blocking == blocking then
		return
	end
	self.Blocking = blocking
	if blocking then
		self:StopSettle(0.1)
		self.Anims:Play(self.Definition.BlockAnimation, 0.12)
	else
		self.Anims:Stop(self.Definition.BlockAnimation, 0.15)
	end
end

function BaseWeapon:StartCharge()
	self:StopSettle(0.1)
	self.Anims:Play(self.Definition.Heavy.ChargeAnimation, 0.15)
end

function BaseWeapon:StopCharge()
	self.Anims:Stop(self.Definition.Heavy.ChargeAnimation, 0.1)
end

function BaseWeapon:GetAttackTrack(): AnimationTrack?
	return self._attack and self._attack.track
end

function BaseWeapon:PlayAttack(attack, callbacks): AnimationTrack?
	self:CancelAttack()
	callbacks = callbacks or {}

	local track = self.Anims:Play(attack.Animation, 0.06)
	-- gameplay ends at MoveOpen; the rest of the track is the settle tail
	local length = AnimationLibrary.ActionLength(attack.Animation)
	local markers = {}
	for _, name in MARKER_ORDER do
		local time = AnimationLibrary.MarkerTime(attack.Animation, name)
		if time then
			table.insert(markers, { name = name, time = time })
		end
	end
	-- any other marker with a callback (e.g. a riposte's cosmetic "RipOut") fires too
	for name in callbacks do
		if name ~= "Ended" and not table.find(MARKER_ORDER, name) then
			local time = AnimationLibrary.MarkerTime(attack.Animation, name)
			if time then
				table.insert(markers, { name = name, time = time })
			end
		end
	end
	table.sort(markers, function(a, b)
		return a.time < b.time
	end)

	local current = { attack = attack, track = track, windowOpen = false }
	self._attack = current

	local function fire(name: string)
		if name == "HitStart" then
			current.windowOpen = true
			self:OnHitWindowOpen(attack)
		elseif name == "HitEnd" then
			if current.windowOpen then
				current.windowOpen = false
				self:OnHitWindowClose(attack)
			end
		end
		local callback = callbacks[name]
		if callback then
			task.spawn(callback)
		end
	end

	local elapsed = 0
	local nextMarker = 1
	current.connection = RunService.Heartbeat:Connect(function(dt)
		local speed = if track and track.IsPlaying then track.Speed else 1
		elapsed += dt * speed
		while markers[nextMarker] and elapsed >= markers[nextMarker].time do
			fire(markers[nextMarker].name)
			nextMarker += 1
			if self._attack ~= current then
				return
			end
		end
		if elapsed >= length then
			self:_finish(current)
			if track and track.IsPlaying then
				self._settleTrack = track
			end
			if callbacks.Ended then
				task.spawn(callbacks.Ended)
			end
		end
	end)

	self:OnAttackStart(attack)
	return track
end

function BaseWeapon:_finish(current)
	if self._attack ~= current then
		return
	end
	self._attack = nil
	if current.connection then
		current.connection:Disconnect()
	end
	if current.windowOpen then
		current.windowOpen = false
		self:OnHitWindowClose(current.attack)
	end
	self:OnAttackEnd(current.attack)
end

function BaseWeapon:StopSettle(fadeTime: number?)
	local track = self._settleTrack
	self._settleTrack = nil
	if track and track.IsPlaying then
		track:Stop(fadeTime or 0.2)
	end
end

function BaseWeapon:HasSettle(): boolean
	local track = self._settleTrack
	if track == nil then
		return false
	end
	if not track.IsPlaying then
		self._settleTrack = nil
		return false
	end
	return true
end

function BaseWeapon:CancelAttack()
	self:StopSettle(0.1)
	local current = self._attack
	if not current then
		return
	end
	self:_finish(current)
	if current.track and current.track.IsPlaying then
		current.track:Stop(0.1)
	end
end

function BaseWeapon:ReportHit(target: Model, position: Vector3)
	HitRemote:FireServer(target, position)
	if self.HitLanded then
		self.HitLanded(target) -- set by WeaponController (stops the lunge on contact)
	end
end

function BaseWeapon:OnDrawnChanged(_drawn: boolean) end
function BaseWeapon:OnAttackStart(_attack) end
function BaseWeapon:OnHitWindowOpen(_attack) end
function BaseWeapon:OnHitWindowClose(_attack) end
function BaseWeapon:OnAttackEnd(_attack) end

function BaseWeapon:Destroy()
	self:CancelAttack()
	self:StopCharge()
	self:SetBlocking(false)
	self.Anims:Stop(self.Definition.IdleAnimation, 0.1)
	self.Trove:Destroy()
end

return BaseWeapon
