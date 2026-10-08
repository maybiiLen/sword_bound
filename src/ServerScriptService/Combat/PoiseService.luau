--[[
	PoiseService  (server only)
	Poise is a hidden "stagger meter" on every Humanoid model (players and NPCs). Hits subtract
	the attack's PoiseDamage; at 0 the model is staggered (can't act, takes CritMultiplier damage)
	and poise refills. Poise regenerates after PoiseRegenDelay seconds without poise damage.
	Hits that don't break poise cause a flinch (interrupts actions without HyperArmor).

	Max poise: the model's MaxPoise attribute if set (e.g. on an NPC in Studio), else
	CombatConfig.PlayerMaxPoise for players and DEFAULT_NPC_POISE for everything else.

	Replication: model attributes Poise, MaxPoise, CombatState = "Staggered" while staggered.
	NPCs (not players) also get a small poise bar billboard with a STAGGERED label.

	Stun rules (2026-10-08, CombatRules):
		Longest stun wins: a new stagger never shortens a running one (CombatRules.StaggerUpdate).
		"Riposted" always takes over the kind so the finisher holds its target.
		Stagger immunity: for CombatRules.StaggerImmunity(pvp) seconds after a full stagger
		(Stagger, GuardBreak, Riposted) ends, poise damage and parry drains can't break poise again.
		Poise stops at 1 and the hit is a flinch instead. A ParryRecoil gives no immunity.

	API:
		:ApplyPoiseDamage(model, amount, pvp?) -> "Stagger" | "Flinch" | "None"
		:DrainPoise(model, amount, pvp?) -> brokePoise
		:Stagger(model, duration, kind?, keepPoise?, pvp?) -> applied   kind = "Stagger" (default) |
		                                          "GuardBreak" | "ParryRecoil" | "Riposted"
		:IsStaggered(model) -> boolean
		:IsStaggerImmune(model) -> boolean
		.Staggered     Signal(model, kind, duration)
		.StaggerEnded  Signal(model)
		.Flinched      Signal(model)

	See Docs.Combat > "Poise".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)
local CombatRules = require(ReplicatedStorage.Combat.CombatRules)

local Attr = CombatConfig.Attributes
local DEFAULT_NPC_POISE = 30
local REGEN_RATE = 25 -- poise per second once regen starts
-- staggers that start stagger immunity when they end (a parry recoil is too short to count)
local IMMUNITY_KINDS = { Stagger = true, GuardBreak = true, Riposted = true }

local PoiseService = {
	Staggered = Signal.new(),
	StaggerEnded = Signal.new(),
	Flinched = Signal.new(),
}

type Entry = {
	max: number,
	poise: number,
	lastHit: number,
	staggerUntil: number,
	staggerToken: number,
	staggerKind: string?,
	staggerPvP: boolean,
	immuneUntil: number,
	bar: Frame?,
	label: TextLabel?,
}

local entries: { [Model]: Entry } = {}

local function createBar(model: Model, entry: Entry)
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not head or not head:IsA("BasePart") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "PoiseBar"
	gui.Size = UDim2.fromOffset(90, 22)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = 60
	gui.Adornee = head

	local back = Instance.new("Frame")
	back.AnchorPoint = Vector2.new(0.5, 1)
	back.Position = UDim2.fromScale(0.5, 1)
	back.Size = UDim2.new(1, 0, 0, 5)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BackgroundTransparency = 0.3
	back.BorderSizePixel = 0
	back.Parent = gui

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(235, 200, 90)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, -7)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "STAGGERED"
	label.TextColor3 = Color3.fromRGB(255, 205, 90)
	label.TextStrokeTransparency = 0.3
	label.Visible = false
	label.Parent = gui

	gui.Parent = model
	entry.bar = fill
	entry.label = label
end

local function refresh(model: Model, entry: Entry)
	model:SetAttribute(Attr.Poise, math.floor(entry.poise + 0.5))
	if entry.bar then
		entry.bar.Size = UDim2.fromScale(math.clamp(entry.poise / entry.max, 0, 1), 1)
	end
	if entry.label then
		entry.label.Visible = os.clock() < entry.staggerUntil
	end
end

local function getEntry(model: Model): Entry
	local entry = entries[model]
	if entry then
		return entry
	end
	local isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
	local max = model:GetAttribute(Attr.MaxPoise)
	if typeof(max) ~= "number" then
		max = if isPlayer then CombatConfig.PlayerMaxPoise else DEFAULT_NPC_POISE
	end
	entry = {
		max = max,
		poise = max,
		lastHit = 0,
		staggerUntil = 0,
		staggerToken = 0,
		staggerKind = nil,
		staggerPvP = false,
		immuneUntil = 0,
	}
	entries[model] = entry
	model:SetAttribute(Attr.MaxPoise, max)
	if not isPlayer then
		createBar(model, entry)
	end
	model.Destroying:Once(function()
		entries[model] = nil
	end)
	refresh(model, entry)
	return entry
end

function PoiseService:IsStaggered(model: Model): boolean
	local entry = entries[model]
	return entry ~= nil and os.clock() < entry.staggerUntil
end

function PoiseService:IsStaggerImmune(model: Model): boolean
	local entry = entries[model]
	return entry ~= nil and os.clock() < entry.immuneUntil
end

-- keepPoise: a short recoil (e.g. being parried) that does not refill poise.
-- pvp: the stagger came from a player hitting a player (picks the PvP immunity time).
-- Returns false when a longer stun was already running and nothing changed.
function PoiseService:Stagger(model: Model, duration: number, kind: string?, keepPoise: boolean?, pvp: boolean?): boolean
	local entry = getEntry(model)
	local now = os.clock()
	local requestedKind = kind or "Stagger"
	local currentKind = nil
	if now < entry.staggerUntil then
		currentKind = entry.staggerKind
	end
	local newEnd, newKind = CombatRules.StaggerUpdate(entry.staggerUntil, currentKind, now, duration, requestedKind)
	if currentKind ~= nil and newEnd == entry.staggerUntil and newKind == currentKind then
		return false -- longest stun wins: the running one already lasts longer
	end

	entry.staggerToken += 1
	local myToken = entry.staggerToken
	entry.staggerUntil = newEnd
	entry.staggerKind = newKind
	entry.staggerPvP = pvp == true
	if IMMUNITY_KINDS[newKind] then
		-- counted from the stagger's end, set now so there is no gap between the stun ending and
		-- the delayed callback below running; never shortened by a later stagger (e.g. a riposte)
		entry.immuneUntil = math.max(entry.immuneUntil, newEnd + CombatRules.StaggerImmunity(entry.staggerPvP))
	end
	if not keepPoise then
		entry.poise = entry.max
	end
	local remaining = newEnd - now
	model:SetAttribute(Attr.CombatState, "Staggered")
	model:SetAttribute(Attr.StaggerKind, newKind)
	refresh(model, entry)
	self.Staggered:Fire(model, newKind, remaining)

	task.delay(remaining, function()
		if entries[model] == entry and entry.staggerToken == myToken then
			entry.staggerUntil = 0
			entry.staggerKind = nil
			model:SetAttribute(Attr.StaggerKind, nil)
			if model:GetAttribute(Attr.CombatState) == "Staggered" then
				model:SetAttribute(Attr.CombatState, "Idle")
			end
			refresh(model, entry)
			self.StaggerEnded:Fire(model)
		end
	end)
	return true
end

-- Removes poise without a flinch (parries use this on the attacker). Returns true if it broke
-- poise, in which case the model is now staggered for the full StaggerTime. During stagger
-- immunity poise stops at 1 and this returns false.
function PoiseService:DrainPoise(model: Model, amount: number, pvp: boolean?): boolean
	local entry = getEntry(model)
	local now = os.clock()
	if now < entry.staggerUntil or amount <= 0 then
		return false
	end
	entry.lastHit = now
	entry.poise -= amount
	if entry.poise <= 0 then
		if now < entry.immuneUntil then
			entry.poise = 1
			refresh(model, entry)
			return false
		end
		self:Stagger(model, CombatConfig.StaggerTime, "Stagger", false, pvp)
		return true
	end
	refresh(model, entry)
	return false
end

function PoiseService:ApplyPoiseDamage(model: Model, amount: number, pvp: boolean?): string
	local entry = getEntry(model)
	local now = os.clock()
	if now < entry.staggerUntil then
		return "None"
	end
	entry.lastHit = now
	entry.poise -= amount
	if entry.poise <= 0 and now < entry.immuneUntil then
		entry.poise = 1 -- stagger immunity: the hit can only flinch
	end
	if entry.poise <= 0 then
		self:Stagger(model, CombatConfig.StaggerTime, "Stagger", false, pvp)
		return "Stagger"
	end
	refresh(model, entry)
	self.Flinched:Fire(model)
	return "Flinch"
end

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.1 then
		return
	end
	local step = accumulator
	accumulator = 0
	local now = os.clock()
	for model, entry in entries do
		if entry.poise < entry.max and now - entry.lastHit >= CombatConfig.PoiseRegenDelay and now >= entry.staggerUntil then
			entry.poise = math.min(entry.poise + REGEN_RATE * step, entry.max)
			refresh(model, entry)
		end
	end
end)

return PoiseService

