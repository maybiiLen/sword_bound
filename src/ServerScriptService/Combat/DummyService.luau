--[[
	DummyService  (server only)
	Respawns training dummies. Any Model tagged "TrainingDummy" (CombatConfig.DummyTag) with a
	Humanoid is snapshotted when it appears and replaced by a fresh copy RespawnTime seconds
	after it dies.

	Dummy attributes:
		XPReward     number   XP for the killing blow (read by DamageService, works on any mob)
		RespawnTime  number   seconds, default 4

	To add a dummy: copy Workspace.TrainingDummy anywhere. See Docs.Combat > "Training dummy".
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)

local DEFAULT_RESPAWN_TIME = 4

local DummyService = {}

local registered: { [Instance]: boolean } = {}

local function register(model: Instance)
	if registered[model] or not model:IsA("Model") then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	registered[model] = true

	local parent = model.Parent
	local snapshot = model:Clone()

	humanoid.Died:Once(function()
		task.wait(model:GetAttribute("RespawnTime") or DEFAULT_RESPAWN_TIME)
		registered[model] = nil
		model:Destroy()
		if parent and parent.Parent then
			snapshot.Parent = parent
		end
	end)
	model.Destroying:Once(function()
		registered[model] = nil
	end)
end

function DummyService:Start()
	CollectionService:GetInstanceAddedSignal(CombatConfig.DummyTag):Connect(register)
	for _, model in CollectionService:GetTagged(CombatConfig.DummyTag) do
		register(model)
	end
end

return DummyService
