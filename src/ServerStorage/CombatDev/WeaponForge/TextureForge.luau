--[[
	TextureForge  (dev only, ServerStorage.CombatDev.WeaponForge.TextureForge)
	Procedural VFX textures made in Luau with EditableImage, then published as Image assets with
	AssetService:CreateAssetAsync (Studio beta "CreateAssetAsync Lua API"). Every texture is white
	with the shape in alpha, so ParticleEmitter / Beam / Trail Color tints it and it works with
	LightEmission 0 or 1 (VFX research: one white texture serves every damage-type color).

	Recipes follow the VFX cookbook in the vault: glow dot (1 - r)^2.5, Gaussian streak, cross
	flare, ring exp(-((r - 0.72) / 0.07)^2), polar crescent slash with a bright head, an eroded
	smoke flipbook (4x4, OneShot) and a trail strip.

	Command bar / MCP (Edit mode); clone the whole WeaponForge folder so script.Parent works:
		local TF = require(game.ServerStorage.CombatDev.WeaponForge:Clone().TextureForge)
		TF.Preview("Slash")    -> EditableImage on a part in Workspace.ForgePreview
		TF.PublishAll()        -> { Glow = id, ... } (paste into Combat.VFXTextures)
]]

local AssetService = game:GetService("AssetService")

local TextureForge = {}

-- deterministic value noise + fBm (seeded hash, smooth interpolation)
local function hash(x: number, y: number, seed: number): number
	local h = math.sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453
	return h - math.floor(h)
end

local function valueNoise(x: number, y: number, seed: number): number
	local x0 = math.floor(x)
	local y0 = math.floor(y)
	local fx = x - x0
	local fy = y - y0
	fx = fx * fx * (3 - 2 * fx)
	fy = fy * fy * (3 - 2 * fy)
	local a = hash(x0, y0, seed)
	local b = hash(x0 + 1, y0, seed)
	local c = hash(x0, y0 + 1, seed)
	local d = hash(x0 + 1, y0 + 1, seed)
	local top = a + (b - a) * fx
	local bottom = c + (d - c) * fx
	return top + (bottom - top) * fy
end

local function fbm(x: number, y: number, seed: number): number
	local sum = 0
	local amplitude = 0.5
	local total = 0
	local frequency = 4
	for octave = 1, 4 do
		sum += valueNoise(x * frequency, y * frequency, seed + octave) * amplitude
		total += amplitude
		amplitude *= 0.5
		frequency *= 2
	end
	return sum / total
end

local function clamp01(v: number): number
	return math.clamp(v, 0, 1)
end

-- alpha(u, v, px, py) with u, v in -1..1 (v up). Returns a size x size EditableImage.
local function paint(size: number, alpha)
	local image = AssetService:CreateEditableImage({ Size = Vector2.new(size, size) })
	local pixels = buffer.create(size * size * 4)
	for py = 0, size - 1 do
		for px = 0, size - 1 do
			local u = (px + 0.5) / size * 2 - 1
			local v = 1 - (py + 0.5) / size * 2
			local a = clamp01(alpha(u, v, px, py))
			local offset = (py * size + px) * 4
			buffer.writeu8(pixels, offset, 255)
			buffer.writeu8(pixels, offset + 1, 255)
			buffer.writeu8(pixels, offset + 2, 255)
			buffer.writeu8(pixels, offset + 3, math.floor(a * 255 + 0.5))
		end
	end
	image:WritePixelsBuffer(Vector2.zero, Vector2.new(size, size), pixels)
	return image
end

local RECIPES = {}

-- soft glow dot
RECIPES.Glow = function()
	return paint(256, function(u, v)
		local r = math.sqrt(u * u + v * v)
		return clamp01(1 - r) ^ 2.5
	end)
end

-- spark streak, long axis = V (matches VelocityParallel particles)
RECIPES.Streak = function()
	return paint(128, function(u, v)
		return math.exp(-(u / 0.09) ^ 2) * clamp01(1 - math.abs(v)) ^ 1.5
	end)
end

-- four-point cross flare with a hot center
RECIPES.Flare = function()
	return paint(256, function(u, v)
		local r = math.sqrt(u * u + v * v)
		local cross = math.exp(-(u / 0.035) ^ 2) * clamp01(1 - math.abs(v)) ^ 3
			+ math.exp(-(v / 0.035) ^ 2) * clamp01(1 - math.abs(u)) ^ 3
		return cross + clamp01(1 - r * 2.2) ^ 2
	end)
end

-- shockwave ring
RECIPES.Ring = function()
	return paint(256, function(u, v)
		local r = math.sqrt(u * u + v * v)
		return math.exp(-((r - 0.72) / 0.07) ^ 2)
	end)
end

-- crescent slash: thin tail at the bottom, thick bright head at the top, slight grain
RECIPES.Slash = function()
	return paint(512, function(u, v)
		local r = math.sqrt(u * u + v * v)
		local angle = math.atan2(v, u)
		local t = (angle + math.pi) / (math.pi * 2)
		local span = (t - 0.3) / 0.55
		if span < 0 or span > 1 then
			return 0
		end
		local width = 0.012 + 0.12 * math.sin(math.pi * span) ^ 0.7 * (0.35 + 0.65 * span)
		local center = 0.8 - 0.1 * span
		local radial = math.exp(-((r - center) / width) ^ 2)
		local outer = math.max(clamp01((center + width * 0.6 - r) / 0.02), 0.35)
		local intensity = 0.25 + 0.75 * span ^ 1.4
		local headFade = clamp01((1 - span) / 0.06)
		local grain = 0.8 + 0.2 * fbm(u * 0.5 + 0.5, v * 0.5 + 0.5, 3)
		return radial * intensity * headFade * outer * grain
	end)
end

-- 4x4 flipbook of a smoke puff eroding away (64 px frames, OneShot)
RECIPES.Smoke = function()
	return paint(256, function(_u, _v, px, py)
		local frame = math.floor(py / 64) * 4 + math.floor(px / 64)
		local lu = ((px % 64) + 0.5) / 64 * 2 - 1
		local lv = ((py % 64) + 0.5) / 64 * 2 - 1
		local r = math.sqrt(lu * lu + lv * lv)
		local body = clamp01(1 - r) ^ 1.2 * (0.5 + 0.5 * fbm(lu * 0.5 + 0.5, lv * 0.5 + 0.5, 7))
		local threshold = frame / 15 * 0.9
		return clamp01((body - threshold) / 0.15) * clamp01(1 - r)
	end)
end

-- trail strip: bright core line along the trail, soft falloff to both edges (across V)
RECIPES.Trail = function()
	return paint(128, function(_u, v)
		return math.exp(-(v / 0.5) ^ 2) * 0.6 + math.exp(-(v / 0.12) ^ 2) * 0.4
	end)
end

TextureForge.Names = { "Glow", "Streak", "Flare", "Ring", "Slash", "Smoke", "Trail" }

function TextureForge.Make(name: string)
	local recipe = RECIPES[name]
	assert(recipe, "no texture recipe " .. tostring(name))
	return recipe()
end

function TextureForge.Preview(name: string, at: Vector3?)
	local folder = workspace:FindFirstChild("ForgePreview")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ForgePreview"
		folder.Parent = workspace
	end
	local part = Instance.new("Part")
	part.Name = "Texture_" .. name
	part.Anchored = true
	part.Size = Vector3.new(6, 6, 0.2)
	part.Color = Color3.fromRGB(15, 17, 24)
	part.Position = at or Vector3.new(0, 60, 0)
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Front
	decal.TextureContent = Content.fromObject(TextureForge.Make(name))
	decal.Parent = part
	part.Parent = folder
	return part
end

function TextureForge.Publish(name: string): number
	local image = TextureForge.Make(name)
	local result, assetId = AssetService:CreateAssetAsync(image, Enum.AssetType.Image, {
		Name = "SwordBound_VFX_" .. name,
		Description = "Sword Bound procedural VFX texture (" .. name .. "), white with alpha",
	})
	image:Destroy() -- free the editable memory budget
	if result ~= Enum.CreateAssetResult.Success then
		error(`CreateAssetAsync failed for texture {name}: {tostring(result)}`)
	end
	return assetId
end

function TextureForge.PublishAll(): { [string]: number }
	local ids = {}
	for _, name in TextureForge.Names do
		ids[name] = TextureForge.Publish(name)
	end
	return ids
end

return TextureForge

