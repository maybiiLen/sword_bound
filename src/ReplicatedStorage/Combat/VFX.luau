--[[
	VFX  (client only, ReplicatedStorage.Combat.VFX)
	The layered hit effects: one recipe per damage type (Slash, Strike, Pierce) plus Block,
	counter-hit recoloring, per-class swing trails and quality scaling. Effects calls in here;
	gameplay never does.

	How an impact is built (VFX research: impulse effects start at full intensity, then fall off):
		a flash (soft glow, ~0.1 s), directional sparks or streaks, a crescent for Slash, and for
		Strike a dust puff and a ring. Counter hits recolor every layer red and flash the victim.
	Textures come from Combat.VFXTextures (procedural, made by CombatDev TextureForge).

	API:
		VFX.Impact(position, info)
			info = { DamageType = "Slash" | "Strike" | "Pierce", Counter = boolean?,
			         Weight = "Light" | "Heavy"?, Direction = Vector3? (swing / thrust direction),
			         Target = Model? }
		VFX.Block(position, direction?)
		VFX.CounterFlash(target)            white Highlight that fades over VFX.CounterFlashTime
		VFX.StyleTrail(model, class)        CombatConfig.ClassTrails[class] onto a weapon's SwingTrail
		VFX.QualityScale() -> number         0.3 .. 1, multiplies every Emit count
		VFX.ActiveHolders() -> number        pooled holders currently in use (leak checks)

	Pooling: each recipe keeps a few invisible holder parts with prebuilt emitters (in
	Workspace.CombatVFX); an impact borrows one, emits, and returns it after its longest particle
	lifetime. Tuning lives in CombatConfig.VFX. See Docs.Combat > "Effects".
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Combat = ReplicatedStorage.Combat
local CombatConfig = require(Combat.CombatConfig)
local VFXTextures = require(Combat.VFXTextures)

local Settings = CombatConfig.VFX

local VFX = {}

local function seq(points)
	local keypoints = {}
	for _, p in points do
		table.insert(keypoints, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keypoints)
end

-- Layer recipes (vault: "VFX artist workflow and cookbook").
-- Color = "core" | "glow" | "dust" picks from CombatConfig.VFX.Palette[recipe].
local RECIPES = {
	Slash = {
		{ Name = "Flash", Texture = "Glow", Color = "core", Emit = 1, Lifetime = { 0.1, 0.1 },
			Size = { { 0, 0.6 }, { 0.3, 3 }, { 1, 3.4 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 0, 0 }, ZOffset = 1 },
		{ Name = "Streaks", Texture = "Streak", Color = "glow", Emit = 10, Lifetime = { 0.15, 0.3 },
			Size = { { 0, 0.3 }, { 1, 0 } }, Transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }, Speed = { 25, 45 },
			Drag = 8, Spread = { 40, 10 }, Squash = 2.5, Parallel = true, ZOffset = 0.5 },
		{ Name = "Crescent", Texture = "Slash", Color = "glow", Emit = 1, Lifetime = { 0.14, 0.14 },
			Size = { { 0, 2.2 }, { 1, 3.2 } }, Transparency = { { 0, 0.1 }, { 1, 1 } }, Speed = { 0, 0 },
			Rotation = { 0, 360 }, ZOffset = 0.8 },
	},
	Strike = {
		{ Name = "Flare", Texture = "Flare", Color = "core", Emit = 1, Lifetime = { 0.12, 0.12 },
			Size = { { 0, 1 }, { 0.2, 5 }, { 1, 5.5 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 0, 0 },
			Rotation = { 0, 90 }, ZOffset = 1 },
		{ Name = "Sparks", Texture = "Streak", Color = "glow", Emit = 8, Lifetime = { 0.25, 0.4 },
			Size = { { 0, 0.35 }, { 1, 0 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 15, 30 },
			Drag = 6, Spread = { 70, 70 }, Acceleration = Vector3.new(0, -40, 0), Squash = 1.5, Parallel = true },
		{ Name = "Dust", Texture = "Smoke", Color = "dust", Emit = 3, Lifetime = { 0.4, 0.6 },
			Size = { { 0, 1.2 }, { 1, 3 } }, Transparency = { { 0, 0.6 }, { 1, 1 } }, Speed = { 4, 8 },
			Spread = { 180, 180 }, LightEmission = 0, LightInfluence = 1, Flipbook = true },
		{ Name = "Ring", Texture = "Ring", Color = "glow", Emit = 1, Lifetime = { 0.2, 0.2 },
			Size = { { 0, 1 }, { 1, 6 } }, Transparency = { { 0, 0.2 }, { 1, 1 } }, Speed = { 0, 0 }, ZOffset = 0.6 },
	},
	Pierce = {
		{ Name = "Flash", Texture = "Glow", Color = "core", Emit = 1, Lifetime = { 0.08, 0.08 },
			Size = { { 0, 0.8 }, { 0.3, 2.6 }, { 1, 2.8 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 0, 0 }, ZOffset = 1 },
		-- one long bright spike along the thrust (a tiny velocity gives VelocityParallel its direction)
		{ Name = "Spike", Texture = "Streak", Color = "core", Emit = 1, Lifetime = { 0.1, 0.1 },
			Size = { { 0, 1.4 }, { 1, 0.5 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 0.1, 0.1 },
			Squash = 3, Parallel = true, ZOffset = 1.2 }, -- Squash is clamped to -3..3
		{ Name = "Streaks", Texture = "Streak", Color = "glow", Emit = 8, Lifetime = { 0.1, 0.2 },
			Size = { { 0, 0.3 }, { 1, 0 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 40, 60 },
			Drag = 10, Spread = { 12, 12 }, Squash = 3, Parallel = true, ZOffset = 0.5 },
	},
	Block = {
		{ Name = "Flash", Texture = "Glow", Color = "core", Emit = 1, Lifetime = { 0.08, 0.08 },
			Size = { { 0, 0.5 }, { 0.3, 1.5 }, { 1, 1.6 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 0, 0 }, ZOffset = 1 },
		{ Name = "Sparks", Texture = "Streak", Color = "glow", Emit = 12, Lifetime = { 0.2, 0.35 },
			Size = { { 0, 0.25 }, { 1, 0 } }, Transparency = { { 0, 0 }, { 1, 1 } }, Speed = { 20, 35 },
			Drag = 5, Spread = { 60, 60 }, Acceleration = Vector3.new(0, -50, 0), Squash = 1.5, Parallel = true },
	},
}

-- quality --------------------------------------------------------------------------------

local qualityScale = 1
local qualityCheckedAt = -math.huge

function VFX.QualityScale(): number
	local now = os.clock()
	if now - qualityCheckedAt < 2 then
		return qualityScale
	end
	qualityCheckedAt = now
	local ok, level = pcall(function()
		return (UserSettings():GetService("UserGameSettings") :: any).SavedQualityLevel.Value
	end)
	if not ok or typeof(level) ~= "number" or level <= 0 then
		qualityScale = Settings.AutomaticQualityScale -- "Automatic" doesn't say the real level
	else
		qualityScale = math.clamp(0.3 + 0.07 * level, 0.3, 1)
	end
	return qualityScale
end

-- pool -----------------------------------------------------------------------------------

local pools: { [string]: { BasePart } } = {}
local active = 0
local container: Folder? = nil

local function getContainer(): Folder
	if container == nil or container.Parent == nil then
		local folder = Instance.new("Folder")
		folder.Name = "CombatVFX"
		folder.Parent = workspace
		container = folder
	end
	return container :: Folder
end

local function buildEmitter(layer, parent: Attachment): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = layer.Name
	emitter.Enabled = false
	emitter.Texture = VFXTextures[layer.Texture] or VFXTextures.Glow or ""
	emitter.LightEmission = layer.LightEmission or 1
	emitter.LightInfluence = layer.LightInfluence or 0
	emitter.Brightness = 3
	emitter.Lifetime = NumberRange.new(layer.Lifetime[1], layer.Lifetime[2])
	emitter.Speed = NumberRange.new(layer.Speed[1], layer.Speed[2])
	emitter.Size = seq(layer.Size)
	emitter.Transparency = seq(layer.Transparency)
	emitter.Drag = layer.Drag or 0
	emitter.Acceleration = layer.Acceleration or Vector3.zero
	emitter.ZOffset = layer.ZOffset or 0
	emitter.EmissionDirection = Enum.NormalId.Top
	if layer.Spread then
		emitter.SpreadAngle = Vector2.new(layer.Spread[1], layer.Spread[2])
	end
	if layer.Rotation then
		emitter.Rotation = NumberRange.new(layer.Rotation[1], layer.Rotation[2])
	end
	if layer.Squash then
		emitter.Squash = NumberSequence.new(layer.Squash)
	end
	if layer.Parallel then
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
		-- VelocityParallel lays the texture's width along the velocity; the Streak texture is long
		-- on V, so turn it 90 degrees to point the streaks along their motion (checked in Studio)
		emitter.Rotation = NumberRange.new(90)
	end
	if layer.Flipbook and VFXTextures.SmokeIsFlipbook then
		emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	end
	emitter.Parent = parent
	return emitter
end

local function longestLifetime(recipeName: string): number
	local longest = 0
	for _, layer in RECIPES[recipeName] do
		longest = math.max(longest, layer.Lifetime[2])
	end
	return longest
end

local function borrow(recipeName: string): BasePart
	local pool = pools[recipeName]
	if pool == nil then
		pool = {}
		pools[recipeName] = pool
	end
	local holder = table.remove(pool)
	if holder == nil then
		local part = Instance.new("Part")
		part.Name = "VFX_" .. recipeName
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		local attachment = Instance.new("Attachment")
		attachment.Name = "Emit"
		attachment.Parent = part
		for _, layer in RECIPES[recipeName] do
			buildEmitter(layer, attachment)
		end
		part.Parent = getContainer()
		holder = part
	end
	active += 1
	return holder :: BasePart
end

local function giveBack(recipeName: string, holder: BasePart)
	task.delay(longestLifetime(recipeName) + 0.05, function()
		active -= 1
		local pool = pools[recipeName]
		if #pool < Settings.PoolSize and holder.Parent ~= nil then
			table.insert(pool, holder)
		else
			holder:Destroy()
		end
	end)
end

function VFX.ActiveHolders(): number
	return active
end

-- impacts --------------------------------------------------------------------------------

local function palette(recipeName: string, counter: boolean?)
	local colors = Settings.Palette[recipeName] or Settings.Palette.Slash
	if counter then
		local red = Settings.Palette.Counter
		return { core = Settings.Palette.CounterCore, glow = red, dust = colors.dust or red }
	end
	return colors
end

-- one ColorSequence per hex color, reused by every emit
local colorCache: { [string]: ColorSequence } = {}
local function colorOf(hex: string): ColorSequence
	local cached = colorCache[hex]
	if cached == nil then
		cached = ColorSequence.new(Color3.fromHex(hex))
		colorCache[hex] = cached
	end
	return cached :: ColorSequence
end

local function layerNamed(recipeName: string, name: string)
	for _, layer in RECIPES[recipeName] do
		if layer.Name == name then
			return layer
		end
	end
	return nil
end

local function emit(recipeName: string, position: Vector3, direction: Vector3?, counter: boolean?, scale: number)
	local holder = borrow(recipeName)
	local up = Vector3.yAxis
	if direction and direction.Magnitude > 1e-3 then
		up = direction.Unit
	end
	-- the emitters' Top (+Y) points along the swing / thrust direction
	local helper = if math.abs(up.Y) < 0.95 then Vector3.yAxis else Vector3.xAxis
	local right = helper:Cross(up).Unit
	local back = right:Cross(up).Unit
	holder.CFrame = CFrame.fromMatrix(position, right, up, back)
	local colors = palette(recipeName, counter)
	local quality = VFX.QualityScale()
	local attachment = holder:FindFirstChild("Emit") :: Attachment
	for _, emitter in attachment:GetChildren() do
		if emitter:IsA("ParticleEmitter") then
			local layer = layerNamed(recipeName, emitter.Name)
			if layer then
				local hex = colors[layer.Color] or colors.glow
				emitter.Color = colorOf(hex)
				local count = 1 -- single flashes never scale down to nothing or up to doubles
				if layer.Emit > 1 then
					count = math.max(1, math.floor(layer.Emit * scale * quality + 0.5))
				end
				emitter:Emit(count)
			end
		end
	end
	giveBack(recipeName, holder)
end

function VFX.CounterFlash(target: Instance?)
	if typeof(target) ~= "Instance" or not target:IsA("Model") then
		return
	end
	-- a fresh Highlight per flash, removed right after, so counter flashes never hold a
	-- Highlight slot (shared with parry flashes and the riposte mark)
	local old = target:FindFirstChild("CounterFlash")
	if old then
		old:Destroy()
	end
	local h = Instance.new("Highlight")
	h.Name = "CounterFlash"
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.OutlineTransparency = 1
	h.FillColor = Color3.new(1, 1, 1)
	h.FillTransparency = 0
	h.Adornee = target
	h.Parent = target
	local info = TweenInfo.new(Settings.CounterFlashTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(h, info, { FillTransparency = 1 }):Play()
	Debris:AddItem(h, Settings.CounterFlashTime + 0.05)
end

function VFX.Impact(position: Vector3, info)
	info = info or {}
	local recipeName = info.DamageType
	if recipeName == nil or RECIPES[recipeName] == nil or recipeName == "Block" then
		recipeName = "Slash"
	end
	local scale = if info.Weight == "Heavy" then Settings.HeavyEmitScale else 1
	if info.Counter then
		scale *= Settings.CounterEmitScale
	end
	emit(recipeName, position, info.Direction, info.Counter, scale)
	if info.Counter then
		VFX.CounterFlash(info.Target)
	end
end

function VFX.Block(position: Vector3, direction: Vector3?)
	emit("Block", position, direction, false, 1)
end

-- trails -------------------------------------------------------------------------------------

-- Only WeaponForge models (ForgeClass attribute) are restyled, so hand-made models such as
-- TestSword keep their own trail. Safe to call repeatedly.
function VFX.StyleTrail(model: Instance?, class: string?)
	if typeof(model) ~= "Instance" then
		return
	end
	local forgeClass = model:GetAttribute("ForgeClass")
	if typeof(forgeClass) ~= "string" then
		return
	end
	class = forgeClass
	local trail = model:FindFirstChild("SwingTrail", true)
	local style = CombatConfig.ClassTrails[class or "Sword"] or CombatConfig.ClassTrails.Sword
	if not trail or not trail:IsA("Trail") or not style then
		return
	end
	trail.Lifetime = style.Lifetime
	trail.WidthScale = seq(style.WidthScale)
	trail.Transparency = seq(style.Transparency)
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.FaceCamera = false
	trail.MinLength = 0.05
	trail.TextureMode = Enum.TextureMode.Stretch
	trail.Texture = VFXTextures.Trail or ""
	trail.Color = ColorSequence.new(Color3.fromHex(style.TipColor or style.Color), Color3.fromHex(style.Color))
end

return VFX

