--[[
	KnightAnimator  (client)
	Plays the SparringKnight's animations locally. The server AI (SparringKnightService) sets
	the model attribute KnightAction = "<AnimationName>|<serial>"; a new serial means "play
	this now" ("" = stop the current action). Also runs a guard idle and Roblox's default R15
	walk so the knight doesn't slide around.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = ReplicatedStorage:WaitForChild("Combat")
local CombatConfig = require(Combat.CombatConfig)
local AnimationSet = require(Combat.Animations.AnimationSet)

local WALK_ANIMATION = "rbxassetid://507777826"

local KnightAnimator = {}

local active: { [Model]: () -> () } = {}

local function attach(model: Instance)
	if active[model] or not model:IsA("Model") then
		return
	end
	local humanoid = model:WaitForChild("Humanoid", 5) :: Humanoid?
	local root = model:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not humanoid or not root or active[model] then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local set = AnimationSet.new(animator, false)
	set:Preload({ "GuardIdle", "KnightSlash", "KnightDelayedChop", "Stagger", "GuardBreak", "Flinch" })
	set:Play("GuardIdle", 0.3)

	local walkAnimation = Instance.new("Animation")
	walkAnimation.AnimationId = WALK_ANIMATION
	local walkTrack = animator:LoadAnimation(walkAnimation)
	walkTrack.Priority = Enum.AnimationPriority.Movement
	walkTrack.Looped = true

	local current: string? = nil
	local function onAction()
		local value = model:GetAttribute("KnightAction")
		if typeof(value) ~= "string" then
			return
		end
		local name = string.split(value, "|")[1]
		if current and current ~= "" then
			set:Stop(current, 0.1)
		end
		current = name
		if name ~= "" then
			set:Play(name, 0.08)
		end
	end

	local connections = {
		model:GetAttributeChangedSignal("KnightAction"):Connect(onAction),
		RunService.Heartbeat:Connect(function()
			local speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
			if speed > 1 and humanoid.Health > 0 then
				if not walkTrack.IsPlaying then
					walkTrack:Play(0.2)
				end
				walkTrack:AdjustSpeed(speed / 14)
			elseif walkTrack.IsPlaying then
				walkTrack:Stop(0.2)
			end
		end),
	}

	local function cleanup()
		for _, connection in connections do
			connection:Disconnect()
		end
		set:Destroy()
		walkTrack:Destroy()
		walkAnimation:Destroy()
		active[model] = nil
	end
	active[model] = cleanup
	humanoid.Died:Once(cleanup)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) and active[model] == cleanup then
			cleanup()
		end
	end)
end

function KnightAnimator:Start()
	CollectionService:GetInstanceAddedSignal(CombatConfig.EnemyTag):Connect(function(model)
		task.spawn(attach, model)
	end)
	for _, model in CollectionService:GetTagged(CombatConfig.EnemyTag) do
		task.spawn(attach, model)
	end
end

return KnightAnimator
