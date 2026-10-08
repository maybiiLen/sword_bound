--[[
	WeaponForge.Parts  (dev only)
	Reusable weapon parts built on MeshKit. Weapon space: origin = where the right hand grips,
	+Y = toward the tip, Z = blade width (the edges face +Z / -Z), X = blade thickness.
	This matches the existing WeaponModels convention (Handle +Y = blade direction).

	Parts.Blade(p)    lofted blade with edge bevels and an optional fuller; regions
	                  "Blade" (flats), "Edge" (bevel bands), "Fuller" (groove)
		p = { BaseY, Length, TipStart (0..1 of Length where the point begins), Bevel (edge band
		      width), Stations = { { t, halfWidth, halfThick, fullerHalfWidth?, fullerDepth? } } }
	Parts.Grip(p)     lathe grip with wrap bumps: { Bottom, Top, Radius, Wraps, Bulge, Sides }
	Parts.Lathe(profile, sides, region, phase?)      tagged lathe
	Parts.Gem(center, radius, height, axis, sides)   bipyramid gem along an axis ("X" | "Y" | "Z")
	Parts.Plate(polygon, depth, chamfer, centerY, region, depthAt?)   extruded guard/head shape
	Parts.Tube(path, radius, sides, closed, region)
	Parts.Tag(data, region)   tag every face of a MeshData with a region
]]

local MeshKit = require(script.Parent.MeshKit)

local Parts = {}

function Parts.Tag(data, region: string)
	for i = 1, #data.faces do
		data.regions[i] = region
	end
	return data
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- station values at fraction t (linear between the listed stations)
local function sample(stations, t: number)
	if t <= stations[1][1] then
		return stations[1]
	end
	for i = 1, #stations - 1 do
		local a = stations[i]
		local b = stations[i + 1]
		if t <= b[1] then
			local f = (t - a[1]) / (b[1] - a[1])
			return {
				t,
				lerp(a[2], b[2], f),
				lerp(a[3], b[3], f),
				lerp(a[4] or 0, b[4] or 0, f),
				lerp(a[5] or 0, b[5] or 0, f),
			}
		end
	end
	return stations[#stations]
end

-- 14-point blade section. Order: E-, front (x > 0) from -Z to +Z, E+, back from +Z to -Z.
local function bladeSection(y: number, w: number, th: number, bevel: number, fw: number, fd: number): { Vector3 }
	local flat = math.max(w - bevel, 0.004)
	if fw > flat - 0.004 then
		fw = math.max(flat - 0.004, 0)
	end
	fd = math.min(fd, th * 0.6)
	local inner = fw * 0.55
	local front = {
		Vector3.new(th, y, -flat),
		Vector3.new(th, y, -fw),
		Vector3.new(th - fd, y, -inner),
		Vector3.new(th - fd, y, inner),
		Vector3.new(th, y, fw),
		Vector3.new(th, y, flat),
	}
	local ring = { Vector3.new(0, y, -w) }
	for i = 1, 6 do
		table.insert(ring, front[i])
	end
	table.insert(ring, Vector3.new(0, y, w))
	for i = 6, 1, -1 do
		local p = front[i]
		table.insert(ring, Vector3.new(-p.X, p.Y, p.Z))
	end
	return ring
end

local BLADE_REGIONS = {
	"Edge", "Blade", "Fuller", "Fuller", "Fuller", "Blade", "Edge",
	"Edge", "Blade", "Fuller", "Fuller", "Fuller", "Blade", "Edge",
}

function Parts.Blade(p)
	local stations = p.Stations
	local rings = {}
	local ts = {}
	-- one ring per listed station up to TipStart, plus extra rings so long blades stay smooth
	for _, s in stations do
		if s[1] <= p.TipStart then
			table.insert(ts, s[1])
		end
	end
	if ts[#ts] < p.TipStart then
		table.insert(ts, p.TipStart)
	end
	for _, t in ts do
		local s = sample(stations, t)
		local y = p.BaseY + p.Length * t
		table.insert(rings, bladeSection(y, s[2], s[3], p.Bevel, s[4] or 0, s[5] or 0))
	end
	local tip = Vector3.new(0, p.BaseY + p.Length, 0)
	return MeshKit.Loft(rings, {
		capStart = true,
		tipEnd = tip,
		region = function(i: number)
			return BLADE_REGIONS[i]
		end,
		capRegion = "Blade",
	})
end

function Parts.Lathe(profile, sides: number, region: string, phase: number?)
	local data = MeshKit.Lathe(profile, sides, { phase = phase or math.pi / sides })
	return Parts.Tag(data, region)
end

-- Grip with leather wrap bumps (Wraps bands, each bulging out by Bulge).
function Parts.Grip(p)
	local profile = {}
	local length = p.Top - p.Bottom
	local band = length / p.Wraps
	table.insert(profile, { p.Radius, p.Bottom })
	for k = 0, p.Wraps - 1 do
		local y0 = p.Bottom + band * k
		table.insert(profile, { p.Radius + p.Bulge, y0 + band * 0.3 })
		table.insert(profile, { p.Radius + p.Bulge, y0 + band * 0.7 })
		table.insert(profile, { p.Radius, y0 + band })
	end
	return Parts.Lathe(profile, p.Sides or 8, p.Region or "Grip")
end

-- Bipyramid gem: radius across, height tip to tip, along `axis` through `center`.
function Parts.Gem(center: Vector3, radius: number, height: number, axis: string, sides: number?, region: string?)
	local data = MeshKit.Lathe({
		{ 0, -height / 2 },
		{ radius, -height * 0.12 },
		{ radius, height * 0.12 },
		{ 0, height / 2 },
	}, sides or 6, { phase = 0 })
	local rotation = CFrame.identity
	if axis == "X" then
		rotation = CFrame.Angles(0, 0, -math.pi / 2)
	elseif axis == "Z" then
		rotation = CFrame.Angles(math.pi / 2, 0, 0)
	end
	data:Transform(CFrame.new(center) * rotation)
	return Parts.Tag(data, region or "Gem")
end

-- Extruded plate: polygon in (u = Z, v = Y relative to centerY), extruded along X.
function Parts.Plate(polygon: { Vector2 }, depth: number, chamfer: number, centerY: number, region: string, depthAt)
	local shifted = {}
	for _, point in polygon do
		table.insert(shifted, Vector2.new(point.X, point.Y + centerY))
	end
	local data = MeshKit.Extrude(shifted, depth, chamfer, {
		region = region,
		depthAt = depthAt,
	})
	return data
end

function Parts.Tube(path: { Vector3 }, radius: number, sides: number, closed: boolean?, region: string)
	return MeshKit.Tube(path, radius, sides, closed, region)
end

-- Points on a circle (for ring guards): center, radius, plane axes a and b.
function Parts.Circle(center: Vector3, radius: number, axisA: Vector3, axisB: Vector3, count: number): { Vector3 }
	local points = {}
	for i = 0, count - 1 do
		local angle = i / count * math.pi * 2
		table.insert(points, center + (axisA * math.cos(angle) + axisB * math.sin(angle)) * radius)
	end
	return points
end

-- Smooth curve through control points (Catmull-Rom), `steps` samples per segment.
function Parts.Curve(controls: { Vector3 }, steps: number): { Vector3 }
	local points = {}
	local count = #controls
	for i = 1, count - 1 do
		local p0 = controls[math.max(i - 1, 1)]
		local p1 = controls[i]
		local p2 = controls[i + 1]
		local p3 = controls[math.min(i + 2, count)]
		for s = 0, steps - 1 do
			local t = s / steps
			local t2 = t * t
			local t3 = t2 * t
			local point = (p1 * 2 + (p2 - p0) * t + (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2 + (p1 * 3 - p0 - p2 * 3 + p3) * t3) * 0.5
			table.insert(points, point)
		end
	end
	table.insert(points, controls[count])
	return points
end

return Parts

