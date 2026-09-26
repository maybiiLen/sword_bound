--!strict
-- Server-authoritative sprint.
-- Clients only send intent (true/false); the server decides whether they are actually
-- sprinting and replicates state through character attributes. The stamina pool itself is
-- owned by Combat.StaminaService (shared with combat actions); WalkSpeed is scaled by the
-- MoveSpeedMultiplier attribute that combat sets during attacks, blocks and rolls.
-- See Docs.Sprint.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local SprintFolder = ReplicatedStorage:WaitForChild("Sprint")
local Config = require(SprintFolder:WaitForChild("SprintConfig"))
local SprintRemote = SprintFolder:WaitForChild("SprintRemote") :: RemoteEvent
local StaminaService = require(ServerScriptService:WaitForChild("Combat"):WaitForChild("StaminaService"))

local Attr = Config.Attributes

type SprintState = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	intent: boolean,
	sprinting: boolean,
	exhausted: boolean,
	requestWindowStart: number,
	requestCount: number,
}

local states: { [Player]: SprintState } = {}

local function setSprinting(state: SprintState, sprinting: boolean)
	if state.sprinting == sprinting then
		return
	end
	state.sprinting = sprinting
	state.character:SetAttribute(Attr.Sprinting, sprinting)
end

local function applyWalkSpeed(state: SprintState)
	local multiplier = state.character:GetAttribute(Attr.SpeedMultiplier)
	local base = if state.sprinting then Config.SprintSpeed else Config.WalkSpeed
	local speed = base * (if typeof(multiplier) == "number" then multiplier else 1)
	if state.humanoid.WalkSpeed ~= speed then
		state.humanoid.WalkSpeed = speed
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root or character.Parent == nil then
		return
	end

	humanoid.WalkSpeed = Config.WalkSpeed
	character:SetAttribute(Attr.Sprinting, false)
	character:SetAttribute(Attr.Exhausted, false)

	local state: SprintState = {
		character = character,
		humanoid = humanoid,
		root = root,
		intent = false,
		sprinting = false,
		exhausted = false,
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
	for player, state in states do
		local velocity = state.root.AssemblyLinearVelocity
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		local moving = horizontalSpeed >= Config.MinMoveSpeed
		local stamina = StaminaService:Get(player)
		local exhaustedBefore = state.exhausted

		if stamina <= 0 then
			state.exhausted = true
		elseif state.exhausted and stamina >= Config.MinStaminaToSprint then
			state.exhausted = false
		end

		local allowed = state.intent
			and not state.exhausted
			and stamina > 0
			and state.humanoid.Health > 0
			and state.character:GetAttribute(Attr.Blocked) ~= true

		if allowed and moving then
			StaminaService:Drain(player, Config.DrainRate * dt)
			if StaminaService:Get(player) <= 0 then
				state.exhausted = true
				state.intent = false
				allowed = false
			end
		end

		setSprinting(state, allowed)
		applyWalkSpeed(state)

		if state.exhausted ~= exhaustedBefore then
			state.character:SetAttribute(Attr.Exhausted, state.exhausted)
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
