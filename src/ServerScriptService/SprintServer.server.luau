--!strict
-- Server-authoritative sprint + stamina.
-- Clients only send intent (true/false); the server decides whether they are actually
-- sprinting, owns the stamina value, and replicates state through character attributes.
-- See Docs.Sprint.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SprintFolder = ReplicatedStorage:WaitForChild("Sprint")
local Config = require(SprintFolder:WaitForChild("SprintConfig"))
local SprintRemote = SprintFolder:WaitForChild("SprintRemote") :: RemoteEvent

local Attr = Config.Attributes

type SprintState = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	intent: boolean,
	sprinting: boolean,
	exhausted: boolean,
	stamina: number,
	lastDrainTime: number,
	lastReplicateTime: number,
	requestWindowStart: number,
	requestCount: number,
}

local states: { [Player]: SprintState } = {}

local function setSprinting(state: SprintState, sprinting: boolean)
	if state.sprinting == sprinting then
		return
	end
	state.sprinting = sprinting
	state.humanoid.WalkSpeed = if sprinting then Config.SprintSpeed else Config.WalkSpeed
	state.character:SetAttribute(Attr.Sprinting, sprinting)
end

local function replicateStamina(state: SprintState, now: number, force: boolean)
	if force or now - state.lastReplicateTime >= Config.StaminaReplicateInterval then
		state.lastReplicateTime = now
		state.character:SetAttribute(Attr.Stamina, state.stamina)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root or character.Parent == nil then
		return
	end

	humanoid.WalkSpeed = Config.WalkSpeed
	character:SetAttribute(Attr.MaxStamina, Config.MaxStamina)
	character:SetAttribute(Attr.Stamina, Config.MaxStamina)
	character:SetAttribute(Attr.Sprinting, false)
	character:SetAttribute(Attr.Exhausted, false)

	local state: SprintState = {
		character = character,
		humanoid = humanoid,
		root = root,
		intent = false,
		sprinting = false,
		exhausted = false,
		stamina = Config.MaxStamina,
		lastDrainTime = 0,
		lastReplicateTime = 0,
		requestWindowStart = 0,
		requestCount = 0,
	}
	states[player] = state

	humanoid.Died:Once(function()
		if states[player] == state then
			setSprinting(state, false)
			states[player] = nil
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player.CharacterRemoving:Connect(function(character)
		local state = states[player]
		if state and state.character == character then
			states[player] = nil
		end
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

SprintRemote.OnServerEvent:Connect(function(player: Player, wantsSprint: unknown)
	if typeof(wantsSprint) ~= "boolean" then
		return
	end
	local state = states[player]
	if not state then
		return
	end

	local now = os.clock()
	if now - state.requestWindowStart >= 1 then
		state.requestWindowStart = now
		state.requestCount = 0
	end
	state.requestCount += 1
	if state.requestCount > Config.MaxRequestsPerSecond then
		return
	end

	state.intent = wantsSprint
end)

RunService.Heartbeat:Connect(function(dt: number)
	local now = os.clock()

	for _, state in states do
		local velocity = state.root.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local moving = horizontalSpeed >= Config.MinMoveSpeed

		local allowed = state.intent
			and not state.exhausted
			and state.stamina > 0
			and state.humanoid.Health > 0
			and state.character:GetAttribute(Attr.Blocked) ~= true

		local staminaBefore = state.stamina
		local exhaustedBefore = state.exhausted

		if allowed and moving then
			state.stamina = math.max(state.stamina - Config.DrainRate * dt, 0)
			state.lastDrainTime = now
			if state.stamina <= 0 then
				state.exhausted = true
				state.intent = false
				allowed = false
			end
		elseif now - state.lastDrainTime >= Config.RegenDelay then
			state.stamina = math.min(state.stamina + Config.RegenRate * dt, Config.MaxStamina)
		end

		if state.exhausted and state.stamina >= Config.MinStaminaToSprint then
			state.exhausted = false
		end

		setSprinting(state, allowed)

		if state.exhausted ~= exhaustedBefore then
			state.character:SetAttribute(Attr.Exhausted, state.exhausted)
		end

		if state.stamina ~= staminaBefore then
			local hitBound = state.stamina == 0 or state.stamina == Config.MaxStamina
			replicateStamina(state, now, hitBound)
		end
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)
