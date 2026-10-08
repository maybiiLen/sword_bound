--[[
	WeaponForge  (dev only, ServerStorage.CombatDev.WeaponForge.Forge)
	Builds the code-defined weapon models in WeaponForge.Specs and installs them in
	ReplicatedStorage.Combat.Assets.WeaponModels with the model convention from Docs.Combat
	(PrimaryPart "Handle" with Grip, SheathGrip, BladeBase, BladeTip attachments and a SwingTrail,
	every other part welded to Handle, physics off, Massless).

	Each material region of a weapon (Blade, Edge, Guard, Grip...) becomes one MeshPart, so
	colors and materials stay editable and a Sword Skill can recolor just the Edge or Fuller.

	Command bar / MCP (Edit mode); clone the whole folder so script.Parent works and Edit's
	require cache doesn't hand back an old version:
		local Forge = require(game.ServerStorage.CombatDev.WeaponForge:Clone().Forge)
		Forge.Stats()                      triangle counts per weapon and region
		Forge.Preview("ForgeSword", cf)    EditableMesh preview in Workspace.ForgePreview (not saved)
		Forge.Install("ForgeSword", true)  publish every region as a Mesh asset with
		                                   AssetService:CreateAssetAsync (Studio beta "CreateAssetAsync
		                                   Lua API"), then build the saved model in WeaponModels
	Install(name, false) builds the model from EditableMeshes only: it shows in Studio but the
	meshes are NOT saved with the place (Roblox never saves editables).

	Published mesh ids are kept as the model attribute ForgeMeshIds (JSON region -> id), so an
	unchanged spec can be rebuilt without uploading again: Forge.Install(name, "reuse").

	See the vault note "Weapons and effects production".
]]

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshKit = require(script.Parent.MeshKit)
local Specs = require(script.Parent.Specs)
local VFX = require(ReplicatedStorage.Combat.VFX)

local WeaponModels = ReplicatedStorage.Combat.Assets.WeaponModels
local SHEATH_ORIENTATION = CFrame.fromOrientation(0, math.rad(-90), math.rad(-145))
local FORGE_VERSION = 1

local Forge = {}

local function regionsOf(spec)
	local all = MeshKit.new()
	for _, data in spec.Build() do
		all:Merge(data)
	end
	local seen = {}
	local names = {}
	for i = 1, #all.faces do
		local region = all.regions[i] or "Blade"
		if seen[region] == nil then
			seen[region] = true
			table.insert(names, region)
		end
	end
	table.sort(names)
	local result = {}
	for _, region in names do
		result[region] = MeshKit.new():Merge(all, region)
	end
	return result, names
end

function Forge.Stats(): string
	local lines = {}
	for _, name in Specs.Order do
		local regions, names = regionsOf(Specs[name])
		local total = 0
		local parts = {}
		for _, region in names do
			local count = regions[region]:TriangleCount()
			total += count
			table.insert(parts, region .. " " .. count)
		end
		table.insert(lines, name .. ": " .. total .. " tris (" .. table.concat(parts, ", ") .. ")")
	end
	return table.concat(lines, "\n")
end

local function applyLook(part: MeshPart, look)
	part.Material = (Enum.Material :: any)[look.Material] or Enum.Material.Metal
	part.Color = Color3.fromHex(look.Color)
	part.Reflectance = look.Reflectance or 0
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = true
end

local function publishMesh(editable, modelName: string, region: string): number
	local result, assetId = AssetService:CreateAssetAsync(editable, Enum.AssetType.Mesh, {
		Name = "SwordBound_" .. modelName .. "_" .. region,
		Description = "Sword Bound weapon mesh built by WeaponForge (" .. modelName .. ", " .. region .. ")",
	})
	if result ~= Enum.CreateAssetResult.Success then
		error(`CreateAssetAsync failed for {modelName}.{region}: {tostring(result)}`)
	end
	return assetId
end

--[[
	mode: false / nil = EditableMesh parts (preview, not saved)
	      true        = publish every region, then use the published meshes
	      "reuse"     = use the ids stored on the existing model (ForgeMeshIds)
]]
local function build(name: string, mode): Model
	local spec = Specs[name]
	assert(spec, "no WeaponForge spec named " .. tostring(name))
	local regions, names = regionsOf(spec)

	local storedIds = {}
	if mode == "reuse" then
		local existing = WeaponModels:FindFirstChild(spec.Model)
		local raw = existing and existing:GetAttribute("ForgeMeshIds")
		if typeof(raw) == "string" then
			storedIds = HttpService:JSONDecode(raw)
		end
	end

	local model = Instance.new("Model")
	model.Name = spec.Model
	local ids = {}
	local partsByRegion = {}
	for _, region in names do
		local look = spec.Materials[region] or { Material = "Metal", Color = "#888888" }
		local editable, center = regions[region]:ToEditableMesh(look.Smooth or 35)
		local content
		if mode == true then
			local assetId = publishMesh(editable, spec.Model, region)
			ids[region] = assetId
			content = Content.fromUri("rbxassetid://" .. assetId)
			editable:Destroy() -- free the editable memory budget; the asset is the source now
		elseif mode == "reuse" then
			-- never fall back to an editable here: it would look fine and be blank after a save
			assert(storedIds[region], `{name}: no published mesh id for region {region}; run Install(name, true)`)
			ids[region] = storedIds[region]
			content = Content.fromUri("rbxassetid://" .. storedIds[region])
			editable:Destroy()
		else
			content = Content.fromObject(editable)
		end
		local part = AssetService:CreateMeshPartAsync(content, {
			CollisionFidelity = Enum.CollisionFidelity.Box,
			RenderFidelity = Enum.RenderFidelity.Precise,
		})
		part.Name = if region == spec.Handle then "Handle" else region
		applyLook(part, look)
		part.CFrame = CFrame.new(center)
		part.Parent = model
		partsByRegion[region] = part
	end

	local handle = partsByRegion[spec.Handle]
	assert(handle, name .. ": Handle region '" .. spec.Handle .. "' produced no geometry")
	model.PrimaryPart = handle
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= handle then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
		end
	end

	-- attachments, placed in weapon space (origin = grip)
	local function attach(attachmentName: string, worldCFrame: CFrame)
		local attachment = Instance.new("Attachment")
		attachment.Name = attachmentName
		attachment.CFrame = handle.CFrame:ToObjectSpace(worldCFrame)
		attachment.Parent = handle
		return attachment
	end
	attach("Grip", CFrame.identity)
	attach("SheathGrip", CFrame.new(spec.Points.Sheath) * SHEATH_ORIENTATION)
	local base = attach("BladeBase", CFrame.new(spec.Points.BladeBase))
	local tip = attach("BladeTip", CFrame.new(spec.Points.BladeTip))

	local template = WeaponModels:FindFirstChild("WeaponTemplate")
	local templateTrail = template and template:FindFirstChild("SwingTrail", true)
	local trail = if templateTrail then templateTrail:Clone() else Instance.new("Trail")
	trail.Name = "SwingTrail"
	trail.Attachment0 = base
	trail.Attachment1 = tip
	trail.Enabled = false
	trail.Parent = handle

	model:SetAttribute("ForgeClass", spec.Class)
	-- bake the class trail look into the template so every client sees it (CombatConfig.ClassTrails)
	VFX.StyleTrail(model)

	model:SetAttribute("ForgeClass", spec.Class)
	model:SetAttribute("ForgeVersion", FORGE_VERSION)
	if next(ids) ~= nil then
		model:SetAttribute("ForgeMeshIds", HttpService:JSONEncode(ids))
	end
	return model
end

-- Anchored preview in Workspace.ForgePreview (EditableMesh, not saved). Returns the model.
function Forge.Preview(name: string, at: CFrame?): Model
	local folder = workspace:FindFirstChild("ForgePreview")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ForgePreview"
		folder.Parent = workspace
	end
	local existing = folder:FindFirstChild(Specs[name].Model)
	if existing then
		existing:Destroy()
	end
	local model = build(name, false)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	-- place so the grip (weapon origin) sits at `at`
	local handle = model.PrimaryPart :: BasePart
	local grip = handle:FindFirstChild("Grip") :: Attachment
	local origin = handle.CFrame * grip.CFrame
	model:PivotTo((at or CFrame.new(0, 50, 0)) * origin:Inverse() * model:GetPivot())
	model.Parent = folder
	return model
end

function Forge.ClearPreview()
	local folder = workspace:FindFirstChild("ForgePreview")
	if folder then
		folder:Destroy()
	end
end

-- Build and put the model in WeaponModels (replacing a model of the same name).
function Forge.Install(name: string, mode): Model
	local model = build(name, mode)
	local existing = WeaponModels:FindFirstChild(model.Name)
	if existing then
		existing:Destroy()
	end
	model.Parent = WeaponModels
	return model
end

return Forge

