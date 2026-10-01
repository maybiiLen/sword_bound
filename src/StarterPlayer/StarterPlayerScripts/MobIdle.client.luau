--[[
	MobIdle  (client only)
	A gentle "breathing" idle for single-mesh mobs: a slow lift, a small forward/back rock and a touch
	of twist, pivoting around the feet so nothing sinks into the floor. Runs on the client by driving the
	mob's BodyJoint Motor6D, so it costs no network traffic.

	Applies to models tagged "MobRig" that have HumanoidRootPart.BodyJoint (Motor6D) and a "Body" mesh.
	Once a mob gets real animations, drop its "MobRig" tag or remove BodyJoint here and let the Animator drive it.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "MobRig"

local BREATH_PERIOD = 3.6   -- seconds per breath
local BOB_FRACTION = 0.006  -- lift, as a fraction of the mesh height
local PITCH_DEGREES = 0.9   -- forward/back rock
local YAW_DEGREES = 1.1     -- slow twist
local MAX_DISTANCE = 300    -- skip mobs farther than this from the camera

type Rig = {
	model: Model,
	root: BasePart,
	joint: Motor6D,
	halfHeight: number,
	halfDepth: number,
	bob: number,
	phase: number,
}

local rigs: { [Model]: Rig } = {}

local function register(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local root = model:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	local body = model:WaitForChild("Body", 10) :: BasePart?
	local joint = root and root:WaitForChild("BodyJoint", 10) :: Motor6D?
	if not root or not body or not joint or not joint:IsA("Motor6D") then
		return
	end

	rigs[model] = {
		model = model,
		root = root,
		joint = joint,
		halfHeight = body.Size.Y / 2,
		halfDepth = body.Size.Z / 2,
		bob = body.Size.Y * BOB_FRACTION,
		phase = (#model.Name * 1.7) % (math.pi * 2), -- so mobs don't breathe in lockstep
	}
end

local function unregister(model: Instance)
	local rig = rigs[model :: Model]
	if rig then
		pcall(function()
			rig.joint.Transform = CFrame.identity
		end)
		rigs[model :: Model] = nil
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(model)
	task.spawn(register, model)
end)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(unregister)
for _, model in CollectionService:GetTagged(TAG) do
	task.spawn(register, model)
end

local pitchMax = math.rad(PITCH_DEGREES)
local yawMax = math.rad(YAW_DEGREES)
local omega = (math.pi * 2) / BREATH_PERIOD

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local t = os.clock()

	for model, rig in rigs do
		if not model:IsDescendantOf(workspace) or not rig.joint.Parent then
			rigs[model] = nil
			continue
		end
		if camera and (rig.root.Position - camera.CFrame.Position).Magnitude > MAX_DISTANCE then
			continue
		end

		local wave = math.sin(t * omega + rig.phase)
		local pitch = wave * pitchMax
		local yaw = math.sin(t * omega * 0.5 + rig.phase) * yawMax

		-- rise with the breath, plus enough to keep the low edge of the rocking mesh above the floor
		local lift = rig.bob * (0.5 + 0.5 * wave) + rig.halfDepth * math.abs(math.sin(pitch))

		local feet = CFrame.new(0, -rig.halfHeight, 0)
		rig.joint.Transform = CFrame.new(0, lift, 0) * feet * CFrame.Angles(pitch, yaw, 0) * feet:Inverse()
	end
end)
