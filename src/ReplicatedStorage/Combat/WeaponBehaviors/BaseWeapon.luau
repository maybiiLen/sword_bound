--[[
	BaseWeapon  (client behavior base class)
	Everything every weapon type shares: loading its animations for the rig (R15/R6), the
	drawn idle pose, playing one attack of the combo at the definition's Duration, and
	opening/closing the hit window (from "HitStart"/"HitEnd" animation markers when the attack
	has UseMarkers, otherwise from its HitWindow fractions).

	It does NOT decide when to attack; that's WeaponController's combo state machine.
	It does NOT deal damage; it reports hits to the server with :ReportHit().

	Subclass hooks (override only what differs; see WeaponBehaviors.Sword):
		:OnDrawnChanged(drawn)
		:OnAttackStart(step, attack)
		:OnHitWindowOpen(step, attack)
		:OnHitWindowClose(step, attack)
		:OnAttackEnd(step, attack)

	API (used by WeaponController):
		BaseWeapon.new(definition, character, model) -> weapon
		weapon:SetDrawn(drawn)
		weapon:Attack(step) -> duration
		weapon:CancelAttack()
		weapon:ReportHit(targetModel, position)
		weapon:Destroy()

	Subclass pattern:
		local Bow = setmetatable({}, { __index = BaseWeapon })
		Bow.__index = Bow
		function Bow.new(...) local self = setmetatable(BaseWeapon.new(...), Bow) ... return self end

	See Docs.Combat > "Adding a weapon type".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Trove = require(ReplicatedStorage.Shared.Util.Trove)

local HitRemote = ReplicatedStorage.Combat.Remotes.HitRemote

local IDLE_PRIORITY = Enum.AnimationPriority.Action
local ATTACK_PRIORITY = Enum.AnimationPriority.Action2

local BaseWeapon = {}
BaseWeapon.__index = BaseWeapon

local function loadTrack(animator: Animator, id: string?, priority: Enum.AnimationPriority, looped: boolean, trove): AnimationTrack?
	if not id or id == "" then
		return nil
	end
	local animation = trove:Add(Instance.new("Animation"))
	animation.AnimationId = id
	local track = animator:LoadAnimation(animation)
	track.Priority = priority
	track.Looped = looped
	trove:Add(function()
		track:Stop(0)
		track:Destroy()
	end)
	return track
end

function BaseWeapon.new(definition, character: Model, model: Model)
	local self = setmetatable({}, BaseWeapon)
	self.Definition = definition
	self.Character = character
	self.Model = model
	self.Humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	self.Drawn = false
	self.Trove = Trove.new()
	self._attackToken = 0
	self._currentStep = nil :: number?

	local animator = self.Humanoid:FindFirstChildOfClass("Animator") :: Animator
	local isR6 = self.Humanoid.RigType == Enum.HumanoidRigType.R6
	local function pick(r15: string?, r6: string?)
		return if isR6 then (r6 or r15) else r15
	end

	self.IdleTrack = loadTrack(animator, pick(definition.IdleAnimation, definition.IdleAnimationR6), IDLE_PRIORITY, true, self.Trove)
	self.ComboTracks = {} :: { AnimationTrack }
	for index, attack in definition.Combo do
		self.ComboTracks[index] = loadTrack(animator, pick(attack.Animation, attack.AnimationR6), ATTACK_PRIORITY, false, self.Trove) :: AnimationTrack
	end

	task.spawn(function()
		local toPreload = {}
		for _, track in self.ComboTracks do
			table.insert(toPreload, track.Animation)
		end
		pcall(ContentProvider.PreloadAsync, ContentProvider, toPreload)
	end)

	return self
end

function BaseWeapon:SetDrawn(drawn: boolean)
	if self.Drawn == drawn then
		return
	end
	self.Drawn = drawn
	if not drawn then
		self:CancelAttack()
	end
	if self.IdleTrack then
		if drawn then
			self.IdleTrack:Play(0.2)
		else
			self.IdleTrack:Stop(0.2)
		end
	end
	self:OnDrawnChanged(drawn)
end

function BaseWeapon:Attack(step: number): number
	local attack = self.Definition.Combo[step]
	local track = self.ComboTracks[step]
	self:CancelAttack()

	self._attackToken += 1
	local token = self._attackToken
	self._currentStep = step

	local duration = attack.Duration
	local speed = if track.Length > 0 then track.Length / duration else 1
	track:Play(0.05, 1, speed)
	self:OnAttackStart(step, attack)

	local windowOpen = false
	local function open()
		if token == self._attackToken and not windowOpen then
			windowOpen = true
			self:OnHitWindowOpen(step, attack)
		end
	end
	local function close()
		if token == self._attackToken and windowOpen then
			windowOpen = false
			self:OnHitWindowClose(step, attack)
		end
	end
	self._closeWindow = close

	if attack.UseMarkers then
		local startConn = track:GetMarkerReachedSignal("HitStart"):Connect(open)
		local endConn = track:GetMarkerReachedSignal("HitEnd"):Connect(close)
		self._markerConnections = { startConn, endConn }
	else
		task.delay(attack.HitWindow[1] * duration, open)
		task.delay(attack.HitWindow[2] * duration, close)
	end

	task.delay(duration, function()
		if token == self._attackToken then
			close()
			self:_disconnectMarkers()
			self._currentStep = nil
			self:OnAttackEnd(step, attack)
		end
	end)

	return duration
end

function BaseWeapon:_disconnectMarkers()
	if self._markerConnections then
		for _, connection in self._markerConnections do
			connection:Disconnect()
		end
		self._markerConnections = nil
	end
end

function BaseWeapon:CancelAttack()
	if self._currentStep == nil then
		return
	end
	local step = self._currentStep
	if self._closeWindow then
		self._closeWindow()
		self._closeWindow = nil
	end
	self:_disconnectMarkers()
	self._attackToken += 1
	self._currentStep = nil
	local track = self.ComboTracks[step]
	if track and track.IsPlaying then
		track:Stop(0.1)
	end
end

function BaseWeapon:ReportHit(target: Model, position: Vector3)
	HitRemote:FireServer(target, position)
end

function BaseWeapon:OnDrawnChanged(_drawn: boolean) end
function BaseWeapon:OnAttackStart(_step: number, _attack) end
function BaseWeapon:OnHitWindowOpen(_step: number, _attack) end
function BaseWeapon:OnHitWindowClose(_step: number, _attack) end
function BaseWeapon:OnAttackEnd(_step: number, _attack) end

function BaseWeapon:Destroy()
	self:CancelAttack()
	self.Trove:Destroy()
end

return BaseWeapon
