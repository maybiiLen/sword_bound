--[[
	MobRigService  (server only)
	Runtime upkeep for every model tagged "MobRig" (an invisible HumanoidRootPart + Humanoid driving a
	single welded mesh, e.g. the generated models in Workspace.Mobs).

	- Server owns the physics, so a nearby player's client can't jitter or shove the mob.
	- Tipping states are switched off so hits and knockback can't topple a mob; the Humanoid keeps
	  it upright. (Real knockback/stagger should be done with velocity or animation, not ragdolling.)

	To make another mob stand the same way: give it a HumanoidRootPart, a Humanoid (RequiresNeck off)
	and add the "MobRig" tag. The idle sway is in StarterPlayerScripts.MobIdle.
]]

local CollectionService = game:GetService("CollectionService")

local TAG = "MobRig"

local DISABLED_STATES = {
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.Seated,
}

local function setup(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local humanoid = model:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = model:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		warn(("[MobRigService] %s is tagged %s but has no Humanoid/HumanoidRootPart"):format(model:GetFullName(), TAG))
		return
	end

	for _, state in DISABLED_STATES do
		humanoid:SetStateEnabled(state, false)
	end

	if not root.Anchored then
		local ok = pcall(function()
			root:SetNetworkOwner(nil)
		end)
		if not ok then
			warn(("[MobRigService] could not set network owner on %s"):format(model:GetFullName()))
		end
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(setup)
for _, model in CollectionService:GetTagged(TAG) do
	task.spawn(setup, model)
end
