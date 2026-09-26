--!strict
--[[
	StaminaService  (server only)
	The one stamina pool per character, shared by sprinting and combat. Sprinting drains it
	continuously (SprintServer); attacks, rolls and blocked hits spend chunks (CombatService,
	DamageService). Regenerates SprintConfig.RegenRate/s after SprintConfig.RegenDelay seconds
	without spending (slower while blocking: CombatConfig.BlockRegenMultiplier).

	Soulslike rule: an action is allowed while stamina > 0 and may take it to 0 (TrySpend).

	Replication (character attributes, unchanged from the Sprint system so existing UI works):
		Stamina, MaxStamina

	API:
		:Get(player) -> number
		:TrySpend(player, amount) -> boolean     fails only if stamina is already 0
		:Spend(player, amount) -> number         forced (e.g. blocking); returns what's left
		:Drain(player, amount)                   continuous drain (sprint), clamps at 0

	Starts itself on first require. See Docs.Combat > "Stamina" and Docs.Sprint.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SprintConfig = require(ReplicatedStorage:WaitForChild("Sprint"):WaitForChild("SprintConfig"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatConfig"))

local SprintAttr = SprintConfig.Attributes
local CombatAttr = CombatConfig.Attributes

type State = {
	character: Model,
	stamina: number,
	lastSpend: number,
	lastReplicate: number,
}

local StaminaService = {}

local states: { [Player]: State } = {}

local function replicate(state: State, now: number, force: boolean)
	if force or now - state.lastReplicate >= SprintConfig.StaminaReplicateInterval then
		state.lastReplicate = now
		state.character:SetAttribute(SprintAttr.Stamina, state.stamina)
	end
end

local function stateFor(player: Player): State?
	local state = states[player]
	if state and state.character == player.Character then
		return state
	end
	return nil
end

local function onCharacterAdded(player: Player, character: Model)
	states[player] = {
		character = character,
		stamina = SprintConfig.MaxStamina,
		lastSpend = 0,
		lastReplicate = 0,
	}
	character:SetAttribute(SprintAttr.MaxStamina, SprintConfig.MaxStamina)
	character:SetAttribute(SprintAttr.Stamina, SprintConfig.MaxStamina)
end

function StaminaService:Get(player: Player): number
	local state = stateFor(player)
	return if state then state.stamina else 0
end

function StaminaService:Spend(player: Player, amount: number): number
	local state = stateFor(player)
	if not state then
		return 0
	end
	local now = os.clock()
	state.stamina = math.max(state.stamina - amount, 0)
	state.lastSpend = now
	replicate(state, now, true)
	return state.stamina
end

function StaminaService:TrySpend(player: Player, amount: number): boolean
	local state = stateFor(player)
	if not state or state.stamina <= 0 then
		return false
	end
	self:Spend(player, amount)
	return true
end

function StaminaService:Drain(player: Player, amount: number)
	local state = stateFor(player)
	if not state then
		return
	end
	local now = os.clock()
	state.stamina = math.max(state.stamina - amount, 0)
	state.lastSpend = now
	replicate(state, now, state.stamina == 0)
end

local started = false
local function start()
	if started then
		return
	end
	started = true

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		for _, state in states do
			if state.stamina < SprintConfig.MaxStamina and now - state.lastSpend >= SprintConfig.RegenDelay then
				local rate = SprintConfig.RegenRate
				if state.character:GetAttribute(CombatAttr.BlockStartedAt) ~= nil then
					rate *= CombatConfig.BlockRegenMultiplier
				end
				state.stamina = math.min(state.stamina + rate * dt, SprintConfig.MaxStamina)
				replicate(state, now, state.stamina == SprintConfig.MaxStamina)
			end
		end
	end)
end

start()

return StaminaService
