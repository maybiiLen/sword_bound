--[[
	WeaponForge.MeshKit  (dev only)
	Small procedural modeling toolkit for code-built weapons. Geometry is plain data (a MeshData:
	positions + triangles) so it can be transformed, merged, measured and finally turned into an
	EditableMesh with smoothing-by-angle normals (hard edges where faces meet at a sharp angle,
	smooth shading elsewhere: the "mid-poly" method from the weapon art research).

	Winding: every primitive is built so triangle normals (b - a):Cross(c - a) point outward.
	MeshData:SignedVolume() > 0 for a closed, outward-facing mesh (used by the tests).

	Primitives (all return a MeshData):
		MeshKit.Loft(rings, options)        connect rings of points; options.capStart/capEnd = "fan",
		                                     options.tipStart/tipEnd = Vector3 to close to a point,
		                                     options.closed = true to join the last ring to the first,
		                                     options.region(i) -> name tags each side segment i
		MeshKit.Lathe(profile, sides, options)   profile = { {radius, y}, ... } (either direction)
		MeshKit.Extrude(polygon, depth, chamfer, options)   polygon = { Vector2(u = z, v = y) } CCW;
		                                     options.depthAt(u, v) -> depth for tapered extrudes
		MeshKit.Tube(path, radius, sides, closed)   sweep a circle along a path of Vector3
	Ring convention (Loft): ring points go around the axis so that, with the loft running toward
	+up, point i to i+1 turns from the ring's X-like axis toward its Z-like axis (x = cos, z = sin).

	See the vault note "Weapons and effects production".
]]

local AssetService = game:GetService("AssetService")

local MeshData = {}
MeshData.__index = MeshData

local MeshKit = {}

function MeshKit.new()
	local self = setmetatable({}, MeshData)
	self.positions = {}
	self.faces = {}
	self.regions = {} -- face index -> region name (optional)
	return self
end

function MeshData:AddVertex(position: Vector3): number
	table.insert(self.positions, position)
	return #self.positions
end

function MeshData:AddTri(a: number, b: number, c: number, region: string?)
	local pa = self.positions[a]
	local pb = self.positions[b]
	local pc = self.positions[c]
	local area = (pb - pa):Cross(pc - pa).Magnitude
	if area < 1e-9 then
		return -- degenerate (collapsed fuller, tip seams)
	end
	table.insert(self.faces, { a, b, c })
	self.regions[#self.faces] = region
end

-- a, b, c, d go around the quad so that (b - a):Cross(c - a) points outward
function MeshData:AddQuad(a: number, b: number, c: number, d: number, region: string?)
	self:AddTri(a, b, c, region)
	self:AddTri(a, c, d, region)
end

function MeshData:Transform(cframe: CFrame)
	for i = 1, #self.positions do
		self.positions[i] = cframe * self.positions[i]
	end
	return self
end

function MeshData:Mirror(axis: string)
	-- mirror across a plane through the origin, then flip winding so normals stay outward
	for i = 1, #self.positions do
		local p = self.positions[i]
		if axis == "X" then
			self.positions[i] = Vector3.new(-p.X, p.Y, p.Z)
		elseif axis == "Y" then
			self.positions[i] = Vector3.new(p.X, -p.Y, p.Z)
		else
			self.positions[i] = Vector3.new(p.X, p.Y, -p.Z)
		end
	end
	self:Flip()
	return self
end

function MeshData:Flip()
	for i = 1, #self.faces do
		local f = self.faces[i]
		self.faces[i] = { f[1], f[3], f[2] }
	end
	return self
end

-- Append another MeshData (optionally only its faces tagged with `region`).
function MeshData:Merge(other, region: string?)
	local remap = {}
	for faceIndex = 1, #other.faces do
		local tag = other.regions[faceIndex]
		-- untagged faces count as "Blade" (same default as Forge), so nothing is dropped silently
		if region == nil or (tag or "Blade") == region then
			local face = other.faces[faceIndex]
			local ids = {}
			for corner = 1, 3 do
				local old = face[corner]
				if remap[old] == nil then
					remap[old] = self:AddVertex(other.positions[old])
				end
				ids[corner] = remap[old]
			end
			table.insert(self.faces, ids)
			self.regions[#self.faces] = tag
		end
	end
	return self
end

function MeshData:TriangleCount(): number
	return #self.faces
end

function MeshData:Bounds(): (Vector3, Vector3)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = -minV
	for _, face in self.faces do
		for corner = 1, 3 do
			local p = self.positions[face[corner]]
			minV = minV:Min(p)
			maxV = maxV:Max(p)
		end
	end
	return minV, maxV
end

-- > 0 when a closed mesh's triangles face outward
function MeshData:SignedVolume(): number
	local volume = 0
	for _, face in self.faces do
		local a = self.positions[face[1]]
		local b = self.positions[face[2]]
		local c = self.positions[face[3]]
		volume += a:Dot(b:Cross(c)) / 6
	end
	return volume
end

-- Make a closed primitive face outward (cheap safety net for hand-built shapes).
function MeshData:OrientOutward()
	if self:SignedVolume() < 0 then
		self:Flip()
	end
	return self
end

--[[
	EditableMesh with smoothing by angle: a face corner's normal averages the (area weighted)
	normals of the faces around that vertex that are within `smoothAngle` degrees of this face.
	Vertices are shared, so the mesh stays watertight; hard edges come from split normals.
	The mesh is centered on its bounds; returns (editableMesh, center) so the caller can place
	the MeshPart at `center` in weapon space.
]]
function MeshData:ToEditableMesh(smoothAngle: number?)
	local threshold = math.cos(math.rad(smoothAngle or 35))
	local minV, maxV = self:Bounds()
	local center = (minV + maxV) / 2

	local faceNormals = {}
	local vertexFaces = {}
	for faceIndex, face in self.faces do
		local a = self.positions[face[1]]
		local b = self.positions[face[2]]
		local c = self.positions[face[3]]
		local n = (b - a):Cross(c - a) -- length = 2 x area (area weighting)
		faceNormals[faceIndex] = n
		for corner = 1, 3 do
			local v = face[corner]
			if vertexFaces[v] == nil then
				vertexFaces[v] = {}
			end
			table.insert(vertexFaces[v], faceIndex)
		end
	end

	local mesh = AssetService:CreateEditableMesh()
	local vertexIds = {}
	for v, p in self.positions do
		if vertexFaces[v] then
			vertexIds[v] = mesh:AddVertex(p - center)
		end
	end

	local normalIds = {} -- "vertex|x|y|z" -> normal id (shares equal normals)
	local function normalId(v: number, n: Vector3): number
		local key = v .. "|" .. math.round(n.X * 1000) .. "|" .. math.round(n.Y * 1000) .. "|" .. math.round(n.Z * 1000)
		local id = normalIds[key]
		if id == nil then
			id = mesh:AddNormal(n)
			normalIds[key] = id
		end
		return id
	end

	for faceIndex, face in self.faces do
		local own = faceNormals[faceIndex].Unit
		local faceId = mesh:AddTriangle(vertexIds[face[1]], vertexIds[face[2]], vertexIds[face[3]])
		local ids = {}
		for corner = 1, 3 do
			local v = face[corner]
			local sum = Vector3.zero
			for _, other in vertexFaces[v] do
				local n = faceNormals[other]
				if n.Unit:Dot(own) >= threshold then
					sum += n
				end
			end
			local normal = if sum.Magnitude > 1e-9 then sum.Unit else own
			ids[corner] = normalId(v, normal)
		end
		mesh:SetFaceNormals(faceId, ids)
	end
	return mesh, center
end

-- Primitives ---------------------------------------------------------------------------------

local function ringOf(radius: number, y: number, sides: number, phase: number?): { Vector3 }
	local ring = {}
	for i = 0, sides - 1 do
		local angle = (phase or 0) + i / sides * math.pi * 2
		table.insert(ring, Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius))
	end
	return ring
end
MeshKit.Ring = ringOf

--[[
	rings: { { Vector3 } } all with the same point count, ordered from start to end.
	options: capStart, capEnd ("fan"), tipStart, tipEnd (Vector3), closed (boolean),
	         region(i) -> string? tags side segment i (between ring point i and i + 1).
]]
function MeshKit.Loft(rings, options)
	options = options or {}
	local data = MeshKit.new()
	local ids = {}
	for k, ring in rings do
		ids[k] = {}
		for i, p in ring do
			ids[k][i] = data:AddVertex(p)
		end
	end
	local n = #rings[1]
	local function regionOf(i: number): string?
		return if options.region then options.region(i) else nil
	end
	local last = #rings
	local ringCount = if options.closed then last else last - 1
	for k = 1, ringCount do
		local k2 = k % last + 1
		for i = 1, n do
			local i2 = i % n + 1
			data:AddQuad(ids[k][i], ids[k2][i], ids[k2][i2], ids[k][i2], regionOf(i))
		end
	end
	if not options.closed then
		local function fan(k: number, startSide: boolean, tip: Vector3?)
			local center: Vector3
			if tip then
				center = tip
			else
				center = Vector3.zero
				for _, p in rings[k] do
					center += p
				end
				center /= n
			end
			local c = data:AddVertex(center)
			for i = 1, n do
				local i2 = i % n + 1
				local region = if tip then regionOf(i) else (options.capRegion or regionOf(i))
				if startSide then
					data:AddTri(c, ids[k][i], ids[k][i2], region)
				else
					data:AddTri(c, ids[k][i2], ids[k][i], region)
				end
			end
		end
		if options.tipStart or options.capStart then
			fan(1, true, options.tipStart)
		end
		if options.tipEnd or options.capEnd then
			fan(last, false, options.tipEnd)
		end
	end
	return data
end

-- profile: { {radius, y}, ... } from bottom to top. radius 0 at an end closes it to a point.
function MeshKit.Lathe(profile, sides: number, options)
	options = options or {}
	if profile[1][2] > profile[#profile][2] then
		-- listed top to bottom: reverse so the rings run bottom to top (keeps normals outward)
		local reversed = {}
		for i = #profile, 1, -1 do
			table.insert(reversed, profile[i])
		end
		profile = reversed
	end
	local rings = {}
	local tipStart, tipEnd = nil, nil
	for index, entry in profile do
		local radius, y = entry[1], entry[2]
		if radius <= 0 and index == 1 then
			tipStart = Vector3.new(0, y, 0)
		elseif radius <= 0 and index == #profile then
			tipEnd = Vector3.new(0, y, 0)
		else
			table.insert(rings, ringOf(radius, y, sides, options.phase))
		end
	end
	return MeshKit.Loft(rings, {
		tipStart = tipStart,
		tipEnd = tipEnd,
		capStart = tipStart == nil,
		capEnd = tipEnd == nil,
		region = options.region,
	})
end

-- 2D helpers for Extrude -------------------------------------------------------------------

local function cross2(a: Vector2, b: Vector2): number
	return a.X * b.Y - a.Y * b.X
end

local function signedArea(polygon: { Vector2 }): number
	local area = 0
	for i = 1, #polygon do
		local a = polygon[i]
		local b = polygon[i % #polygon + 1]
		area += cross2(a, b)
	end
	return area / 2
end
MeshKit.SignedArea = signedArea

local function pointInTriangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2): boolean
	local d1 = cross2(b - a, p - a)
	local d2 = cross2(c - b, p - b)
	local d3 = cross2(a - c, p - c)
	return d1 > 1e-12 and d2 > 1e-12 and d3 > 1e-12
end

-- Ear clipping for a simple CCW polygon. Returns index triples into the polygon (CCW).
local function triangulate(polygon: { Vector2 }): { { number } }
	local indices = {}
	for i = 1, #polygon do
		table.insert(indices, i)
	end
	local result = {}
	local guard = 0
	while #indices > 3 and guard < 10000 do
		guard += 1
		local clipped = false
		for k = 1, #indices do
			local ia = indices[(k - 2) % #indices + 1]
			local ib = indices[k]
			local ic = indices[k % #indices + 1]
			local a, b, c = polygon[ia], polygon[ib], polygon[ic]
			if cross2(b - a, c - b) > 1e-12 then -- convex corner
				local isEar = true
				for _, other in indices do
					if other ~= ia and other ~= ib and other ~= ic and pointInTriangle(polygon[other], a, b, c) then
						isEar = false
						break
					end
				end
				if isEar then
					table.insert(result, { ia, ib, ic })
					table.remove(indices, k)
					clipped = true
					break
				end
			end
		end
		if not clipped then
			warn(`[MeshKit] triangulate gave up with {#indices} corners left (self-intersecting or degenerate polygon)`)
			break -- stop instead of looping forever
		end
	end
	if #indices == 3 then
		table.insert(result, { indices[1], indices[2], indices[3] })
	end
	return result
end
MeshKit.Triangulate = triangulate

-- Move every vertex of a CCW polygon inward by `amount` along its corner bisector (mitered).
local function inset(polygon: { Vector2 }, amount: number): { Vector2 }
	local result = {}
	local count = #polygon
	for i = 1, count do
		local prev = polygon[(i - 2) % count + 1]
		local p = polygon[i]
		local nextP = polygon[i % count + 1]
		local e1 = (p - prev).Unit
		local e2 = (nextP - p).Unit
		local n1 = Vector2.new(e1.Y, -e1.X) -- outward normal for CCW
		local n2 = Vector2.new(e2.Y, -e2.X)
		local miter = n1 + n2
		local denominator = 1 + n1:Dot(n2)
		if denominator < 0.2 then
			denominator = 0.2 -- very sharp corner: limit the miter
		end
		miter = miter / denominator
		table.insert(result, p - miter * amount)
	end
	return result
end
MeshKit.Inset = inset

--[[
	Extrude a 2D polygon (u = Z, v = Y) along X, centered on X = 0, with a chamfer around both
	faces. polygon must be simple; it is made CCW automatically.
	options.depthAt(u, v) -> number overrides the depth per vertex (tapered axe heads).
	options.region: name for every face (default nil); options.faceRegion: name for the two flat
	faces only; options.chamferRegion: name for the chamfer bands only.
]]
function MeshKit.Extrude(polygon: { Vector2 }, depth: number, chamfer: number, options)
	options = options or {}
	local poly = {}
	for _, p in polygon do
		table.insert(poly, p)
	end
	if signedArea(poly) < 0 then
		local reversed = {}
		for i = #poly, 1, -1 do
			table.insert(reversed, poly[i])
		end
		poly = reversed
	end
	local inner = if chamfer > 0 then inset(poly, chamfer) else poly
	local data = MeshKit.new()
	local function half(p: Vector2): number
		local d = if options.depthAt then options.depthAt(p.X, p.Y) else depth
		return d / 2
	end
	local count = #poly
	local fo, fi, bo, bi = {}, {}, {}, {}
	for i = 1, count do
		local p = poly[i]
		local q = inner[i]
		local hp = half(p)
		local hq = half(q)
		local outerHalf = if chamfer > 0 then math.max(hp - chamfer, hp * 0.35) else hp
		fo[i] = data:AddVertex(Vector3.new(outerHalf, p.Y, p.X))
		bo[i] = data:AddVertex(Vector3.new(-outerHalf, p.Y, p.X))
		if chamfer > 0 then
			fi[i] = data:AddVertex(Vector3.new(hq, q.Y, q.X))
			bi[i] = data:AddVertex(Vector3.new(-hq, q.Y, q.X))
		else
			fi[i] = fo[i]
			bi[i] = bo[i]
		end
	end
	local sideRegion = options.region
	local faceRegion = options.faceRegion or options.region
	local chamferRegion = options.chamferRegion or options.region
	for i = 1, count do
		local i2 = i % count + 1
		data:AddQuad(bo[i], fo[i], fo[i2], bo[i2], sideRegion)
		if chamfer > 0 then
			data:AddQuad(fo[i], fi[i], fi[i2], fo[i2], chamferRegion)
			data:AddQuad(bi[i], bo[i], bo[i2], bi[i2], chamferRegion)
		end
	end
	for _, tri in triangulate(inner) do
		-- CCW in (u, v) faces -X, so the front (+X) face uses the reversed order
		data:AddTri(fi[tri[1]], fi[tri[3]], fi[tri[2]], faceRegion)
		data:AddTri(bi[tri[1]], bi[tri[2]], bi[tri[3]], faceRegion)
	end
	return data
end

-- Sweep a circle along a path (parallel transport frames). closed = true joins the ends.
function MeshKit.Tube(path: { Vector3 }, radius: number, sides: number, closed: boolean?, region: string?)
	local count = #path
	local tangents = {}
	for i = 1, count do
		local prev = path[if i > 1 then i - 1 else (if closed then count else 1)]
		local nextP = path[if i < count then i + 1 else (if closed then 1 else count)]
		tangents[i] = (nextP - prev).Unit
	end
	-- first normal: any vector perpendicular to the first tangent
	local t0 = tangents[1]
	local helper = if math.abs(t0.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
	local normal = t0:Cross(helper).Unit
	local rings = {}
	for i = 1, count do
		local t = tangents[i]
		local projected = normal - t * normal:Dot(t) -- transport: remove the tangent component
		if projected.Magnitude < 1e-4 then
			-- the path turned 90 degrees onto the old normal: pick any perpendicular instead
			local fallback = if math.abs(t.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
			projected = t:Cross(fallback)
		end
		normal = projected.Unit
		local binormal = normal:Cross(t) -- normal x binormal = -tangent (Loft ring convention)
		local ring = {}
		for s = 0, sides - 1 do
			local angle = s / sides * math.pi * 2
			table.insert(ring, path[i] + (normal * math.cos(angle) + binormal * math.sin(angle)) * radius)
		end
		table.insert(rings, ring)
	end
	return MeshKit.Loft(rings, {
		closed = closed,
		capStart = not closed,
		capEnd = not closed,
		region = function()
			return region
		end,
		capRegion = region,
	})
end

return MeshKit

