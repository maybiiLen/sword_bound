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

	API:
		:ApplyPoiseDamage(model, amount) -> "Stagger" | "Flinch" | "None"
		:Stagger(model, duration, kind?)          kind = "Stagger" (default) | "GuardBreak"
		:IsStaggered(model) -> boolean
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

local Attr = CombatConfig.Attributes
local DEFAULT_NPC_POISE = 30
local REGEN_RATE = 25 -- poise per second once regen starts

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
	entry = { max = max, poise = max, lastHit = 0, staggerUntil = 0, staggerToken = 0 }
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

-- keepPoise: a short recoil (e.g. being parried) that does not refill poise.
function PoiseService:Stagger(model: Model, duration: number, kind: string?, keepPoise: boolean?)
	local entry = getEntry(model)
	entry.staggerToken += 1
	local myToken = entry.staggerToken
	entry.staggerUntil = os.clock() + duration
	if not keepPoise then
		entry.poise = entry.max
	end
	model:SetAttribute(Attr.CombatState, "Staggered")
	model:SetAttribute(Attr.StaggerKind, kind or "Stagger")
	refresh(model, entry)
	self.Staggered:Fire(model, kind or "Stagger", duration)

	task.delay(duration, function()
		if entries[model] == entry and entry.staggerToken == myToken then
			entry.staggerUntil = 0
			model:SetAttribute(Attr.StaggerKind, nil)
			if model:GetAttribute(Attr.CombatState) == "Staggered" then
				model:SetAttribute(Attr.CombatState, "Idle")
			end
			refresh(model, entry)
			self.StaggerEnded:Fire(model)
		end
	end)
end

-- Removes poise without a flinch (parries use this on the attacker). Returns true if it broke
-- poise, in which case the model is now staggered for the full StaggerTime.
function PoiseService:DrainPoise(model: Model, amount: number): boolean
	local entry = getEntry(model)
	if os.clock() < entry.staggerUntil or amount <= 0 then
		return false
	end
	entry.lastHit = os.clock()
	entry.poise -= amount
	if entry.poise <= 0 then
		self:Stagger(model, CombatConfig.StaggerTime, "Stagger")
		return true
	end
	refresh(model, entry)
	return false
end

function PoiseService:ApplyPoiseDamage(model: Model, amount: number): string
	local entry = getEntry(model)
	if os.clock() < entry.staggerUntil then
		return "None"
	end
	entry.lastHit = os.clock()
	entry.poise -= amount
	if entry.poise <= 0 then
		self:Stagger(model, CombatConfig.StaggerTime, "Stagger")
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
