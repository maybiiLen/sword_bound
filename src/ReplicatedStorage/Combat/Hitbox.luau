--[[
	Hitbox
	Swept melee hitbox between two attachments (a blade's BladeBase -> BladeTip). Every frame
	while active it:
		1. overlaps a box covering the blade where it is now,
		2. Blockcasts that box from last frame's position to this frame's,
		3. spherecasts the tip and the blade middle along their arcs (swings rotate, boxes don't),
	so fast swings can't skip through a target between frames. Each target (a Model with a
	Humanoid) is reported at most once per Start().

	The hitbox only DETECTS. It runs on the attacking client for instant feel; the server
	re-validates every reported hit (CombatService) before any damage happens.

	API:
		Hitbox.new({ Base = Attachment, Tip = Attachment, Ignore = { Instance }, Thickness = number? })
		hitbox.Hit            Signal(targetModel, hitPart, position)
		hitbox:Start()        clears the per-swing hit list and begins sweeping
		hitbox:Stop()
		hitbox:Destroy()
		Hitbox.Debug = true   draws the swept boxes (Studio testing only)

	Used by: WeaponBehaviors.Sword. See Docs.Combat > "Hitbox".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local MAX_CASTS_PER_SWEEP = 4
local MIN_SWEEP_DISTANCE = 0.05

local Hitbox = {}
Hitbox.__index = Hitbox
Hitbox.Debug = false

local function findTarget(part: BasePart): Model?
	local node = part.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function drawDebug(cf: CFrame, size: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Transparency = 0.7
	p.Material = Enum.Material.Neon
	p.Parent = workspace
	Debris:AddItem(p, 0.25)
end

function Hitbox.new(params: { Base: Attachment, Tip: Attachment, Ignore: { Instance }, Thickness: number? })
	local self = setmetatable({}, Hitbox)
	self.Hit = Signal.new()
	self._base = params.Base
	self._tip = params.Tip
	self._ignore = params.Ignore
	self._thickness = params.Thickness or 0.8
	self._hitTargets = {} :: { [Model]: boolean }
	self._connection = nil :: RBXScriptConnection?
	self._last = nil :: { center: Vector3, cf: CFrame, tip: Vector3, mid: Vector3 }?

	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._overlapParams = OverlapParams.new()
	self._overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	return self
end

function Hitbox:_register(part: BasePart, position: Vector3)
	local target = findTarget(part)
	if not target or self._hitTargets[target] then
		return
	end
	self._hitTargets[target] = true
	self._raycastParams:AddToFilter(target)
	self._overlapParams:AddToFilter(target)
	self.Hit:Fire(target, part, position)
end

-- Hit targets are added to the filter, so recasting finds the next target behind them.
-- World geometry ends the sweep: blades don't pass through walls.
function Hitbox:_cast(fn: () -> RaycastResult?)
	for _ = 1, MAX_CASTS_PER_SWEEP do
		local result = fn()
		if not result or not findTarget(result.Instance :: BasePart) then
			return
		end
		self:_register(result.Instance :: BasePart, result.Position)
	end
end

function Hitbox:_step()
	local base, tip = self._base.WorldPosition, self._tip.WorldPosition
	local length = (tip - base).Magnitude
	if length < 0.01 then
		return
	end
	local center = (base + tip) / 2
	local mid = center
	local cf = CFrame.lookAt(center, tip)
	local thickness = self._thickness
	local size = Vector3.new(thickness, thickness, length)

	for _, part in workspace:GetPartBoundsInBox(cf, size, self._overlapParams) do
		self:_register(part, part.Position)
	end

	local last = self._last
	if last then
		local delta = center - last.center
		if delta.Magnitude > MIN_SWEEP_DISTANCE then
			self:_cast(function()
				return workspace:Blockcast(last.cf, size, delta, self._raycastParams)
			end)
		end
		for _, pair in { { last.tip, tip }, { last.mid, mid } } do
			local travel = pair[2] - pair[1]
			if travel.Magnitude > MIN_SWEEP_DISTANCE then
				self:_cast(function()
					return workspace:Spherecast(pair[1], thickness / 2, travel, self._raycastParams)
				end)
			end
		end
	end

	if Hitbox.Debug then
		drawDebug(cf, size, Color3.fromRGB(255, 60, 60))
	end
	self._last = { center = center, cf = cf, tip = tip, mid = mid }
end

function Hitbox:Start()
	self:Stop()
	table.clear(self._hitTargets)
	self._raycastParams.FilterDescendantsInstances = self._ignore
	self._overlapParams.FilterDescendantsInstances = self._ignore
	self._last = nil
	self:_step()
	self._connection = RunService.Heartbeat:Connect(function()
		self:_step()
	end)
end

function Hitbox:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	self._last = nil
end

function Hitbox:Destroy()
	self:Stop()
	self.Hit:Destroy()
end

return Hitbox
