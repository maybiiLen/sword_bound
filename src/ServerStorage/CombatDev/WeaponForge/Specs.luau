--[[
	WeaponForge.Specs  (dev only)
	One entry per forged weapon model. Each entry:
		Model        name of the model created in Combat.Assets.WeaponModels
		Class        weapon class it is for (Sword, Dagger, Rapier, Greatsword, Greataxe)
		Materials    region -> { Material, Color (hex), Reflectance?, Smooth? (degrees) }
		Handle       region whose MeshPart becomes the model's PrimaryPart "Handle"
		Build()      -> { MeshData, ... } tagged with regions (see WeaponForge.Parts)
		Points       weapon-space positions: BladeBase, BladeTip (hitbox + trail), Sheath (where
		             it sits on the back; SheathGrip orientation is shared)
	Weapon space: origin = right-hand grip, +Y toward the tip, edges face +Z / -Z.

	Designs (2026-10-08) follow the vault note "Weapons and effects production" class sheet:
	clean SAO-style shapes, one dominant color, thin contrasting edge, a gem or emblem. The
	shapes are original; proportions come from real weapons scaled to the 5-stud sword.
]]

local Parts = require(script.Parent.Parts)

local V2 = Vector2.new
local V3 = Vector3.new

local function mirrorU(points)
	-- right half (u >= 0, listed bottom to top) -> full CCW polygon
	local polygon = {}
	for i = 1, #points do
		table.insert(polygon, points[i])
	end
	for i = #points, 1, -1 do
		local p = points[i]
		if p.X > 1e-6 then
			table.insert(polygon, V2(-p.X, p.Y))
		end
	end
	return polygon
end

local Specs = {}

-- One-handed sword: dark blade with a light edge line, swept winged guard, cyan gem. ~5.0 studs.
Specs.ForgeSword = {
	Model = "ForgeSword",
	Class = "Sword",
	Handle = "Grip",
	Materials = {
		Blade = { Material = "Metal", Color = "#1E2127", Reflectance = 0.15, Smooth = 25 },
		Edge = { Material = "Metal", Color = "#B4BDC8", Reflectance = 0.2, Smooth = 25 },
		Fuller = { Material = "SmoothPlastic", Color = "#26344A", Smooth = 25 },
		Guard = { Material = "Metal", Color = "#2B2F36", Reflectance = 0.1, Smooth = 30 },
		Trim = { Material = "Metal", Color = "#8E99A8", Reflectance = 0.15, Smooth = 50 },
		Grip = { Material = "Leather", Color = "#1B1511", Smooth = 60 },
		Gem = { Material = "Neon", Color = "#2FC6E8", Smooth = 10 },
	},
	Points = { BladeBase = V3(0, 0.85, 0), BladeTip = V3(0, 4.2, 0), Sheath = V3(0.45, 1.8, 0) },
	Build = function()
		local list = {}
		table.insert(list, Parts.Blade({
			BaseY = 0.6,
			Length = 3.68,
			TipStart = 0.86,
			Bevel = 0.06,
			Stations = {
				{ 0.0, 0.19, 0.045, 0.0, 0.0 },
				{ 0.06, 0.2, 0.045, 0.04, 0.016 },
				{ 0.35, 0.19, 0.04, 0.04, 0.016 },
				{ 0.62, 0.18, 0.036, 0.03, 0.012 },
				{ 0.74, 0.17, 0.033, 0.0, 0.0 },
				{ 0.86, 0.155, 0.03, 0.0, 0.0 },
			},
		}))
		-- swept guard: wings droop at the tips, a raised center plate holds the gem
		local guard = mirrorU({
			V2(0, -0.17),
			V2(0.13, -0.07),
			V2(0.46, -0.06),
			V2(0.68, -0.16),
			V2(0.64, -0.01),
			V2(0.5, 0.06),
			V2(0.17, 0.08),
			V2(0.09, 0.2),
			V2(0, 0.22),
		})
		table.insert(list, Parts.Plate(guard, 0.22, 0.03, 0.47, "Guard"))
		table.insert(list, Parts.Gem(V3(0, 0.49, 0), 0.075, 0.34, "X", 6, "Gem"))
		table.insert(list, Parts.Grip({ Bottom = -0.42, Top = 0.36, Radius = 0.072, Wraps = 6, Bulge = 0.012 }))
		-- ferrules (Trim) at both ends of the grip
		table.insert(list, Parts.Lathe({ { 0.09, 0.33 }, { 0.1, 0.36 }, { 0.1, 0.4 }, { 0.085, 0.42 } }, 8, "Trim"))
		table.insert(list, Parts.Lathe({ { 0.085, -0.47 }, { 0.1, -0.45 }, { 0.1, -0.41 }, { 0.09, -0.39 } }, 8, "Trim"))
		-- faceted pommel
		table.insert(list, Parts.Lathe({ { 0.07, -0.47 }, { 0.13, -0.53 }, { 0.145, -0.6 }, { 0.11, -0.68 }, { 0, -0.74 } }, 8, "Guard"))
		return list
	end,
}

-- Dagger: needle blade, twin rondel discs, crimson grip, gold fittings. ~2.4 studs.
Specs.ForgeDagger = {
	Model = "ForgeDagger",
	Class = "Dagger",
	Handle = "Grip",
	Materials = {
		Blade = { Material = "Metal", Color = "#454B55", Reflectance = 0.15, Smooth = 25 },
		Edge = { Material = "Metal", Color = "#C9D0D8", Reflectance = 0.2, Smooth = 25 },
		Fuller = { Material = "Metal", Color = "#454B55", Smooth = 25 },
		Trim = { Material = "Metal", Color = "#C9A54A", Reflectance = 0.2, Smooth = 50 },
		Grip = { Material = "Leather", Color = "#6E1A27", Smooth = 60 },
		Gem = { Material = "Neon", Color = "#E04A5E", Smooth = 10 },
	},
	Points = { BladeBase = V3(0, 0.42, 0), BladeTip = V3(0, 1.85, 0), Sheath = V3(0.35, 0.6, 0) },
	Build = function()
		local list = {}
		table.insert(list, Parts.Blade({
			BaseY = 0.33,
			Length = 1.58,
			TipStart = 0.7,
			Bevel = 0.07,
			Stations = {
				{ 0.0, 0.095, 0.042 },
				{ 0.25, 0.1, 0.04 },
				{ 0.7, 0.075, 0.032 },
			},
		}))
		-- rondel discs at both ends of the grip
		local disc = { { 0.05, -0.04 }, { 0.2, -0.03 }, { 0.215, 0 }, { 0.2, 0.03 }, { 0.05, 0.04 } }
		local top = Parts.Lathe(disc, 12, "Trim")
		top:Transform(CFrame.new(0, 0.32, 0))
		table.insert(list, top)
		local bottom = Parts.Lathe(disc, 12, "Trim")
		bottom:Transform(CFrame.new(0, -0.3, 0))
		table.insert(list, bottom)
		table.insert(list, Parts.Grip({ Bottom = -0.27, Top = 0.29, Radius = 0.062, Wraps = 4, Bulge = 0.01 }))
		-- small ball pommel with a gem
		table.insert(list, Parts.Lathe({ { 0.05, -0.34 }, { 0.09, -0.38 }, { 0.09, -0.44 }, { 0, -0.49 } }, 10, "Trim"))
		-- gem through the pommel ball, showing on both sides
		table.insert(list, Parts.Gem(V3(0, -0.41, 0), 0.045, 0.22, "X", 6, "Gem"))
		return list
	end,
}

-- Rapier: slim silver blade with a ricasso, quillons, knuckle bow, side rings, red gem. ~5.4 studs.
Specs.ForgeRapier = {
	Model = "ForgeRapier",
	Class = "Rapier",
	Handle = "Grip",
	Materials = {
		Blade = { Material = "Metal", Color = "#D5DCE4", Reflectance = 0.25, Smooth = 25 },
		Edge = { Material = "Metal", Color = "#F2F5F8", Reflectance = 0.3, Smooth = 25 },
		Fuller = { Material = "Metal", Color = "#D5DCE4", Smooth = 25 },
		Guard = { Material = "Metal", Color = "#E3E8EE", Reflectance = 0.25, Smooth = 55 },
		Trim = { Material = "Metal", Color = "#D4B96A", Reflectance = 0.25, Smooth = 55 },
		Grip = { Material = "Leather", Color = "#ECE6DA", Smooth = 60 },
		Gem = { Material = "Neon", Color = "#D9465A", Smooth = 10 },
	},
	Points = { BladeBase = V3(0, 0.75, 0), BladeTip = V3(0, 4.7, 0), Sheath = V3(0.45, 1.95, 0) },
	Build = function()
		local list = {}
		-- ricasso (narrow, unsharpened) then the blade
		table.insert(list, Parts.Blade({
			BaseY = 0.42,
			Length = 4.38,
			TipStart = 0.9,
			Bevel = 0.035,
			Stations = {
				{ 0.0, 0.055, 0.034 },
				{ 0.07, 0.055, 0.034 },
				{ 0.09, 0.085, 0.032 },
				{ 0.5, 0.075, 0.028 },
				{ 0.9, 0.055, 0.022 },
			},
		}))
		-- quillons with ball finials
		table.insert(list, Parts.Tube({ V3(0, 0.43, -0.58), V3(0, 0.45, 0), V3(0, 0.43, 0.58) }, 0.032, 8, false, "Guard"))
		local finial = { { 0, -0.06 }, { 0.055, -0.03 }, { 0.055, 0.03 }, { 0, 0.06 } }
		local leftBall = Parts.Lathe(finial, 8, "Trim")
		leftBall:Transform(CFrame.new(0, 0.43, -0.62))
		table.insert(list, leftBall)
		local rightBall = Parts.Lathe(finial, 8, "Trim")
		rightBall:Transform(CFrame.new(0, 0.43, 0.62))
		table.insert(list, rightBall)
		-- center block with the gem
		table.insert(list, Parts.Lathe({ { 0.05, 0.36 }, { 0.085, 0.4 }, { 0.085, 0.5 }, { 0.05, 0.54 } }, 8, "Trim"))
		table.insert(list, Parts.Gem(V3(0, 0.45, 0), 0.05, 0.24, "X", 6, "Gem"))
		-- knuckle bow: from the right quillon root, around the hand, to the pommel
		local bow = Parts.Curve({
			V3(0, 0.44, 0.22),
			V3(0, 0.3, 0.42),
			V3(0, 0.0, 0.47),
			V3(0, -0.3, 0.32),
			V3(0, -0.4, 0.1),
		}, 5)
		table.insert(list, Parts.Tube(bow, 0.026, 6, false, "Guard"))
		-- side rings on both faces of the ricasso
		for _, side in { 1, -1 } do
			local ring = Parts.Circle(V3(0.13 * side, 0.6, 0), 0.15, Vector3.yAxis, Vector3.zAxis, 16)
			table.insert(list, Parts.Tube(ring, 0.022, 6, true, "Guard"))
		end
		table.insert(list, Parts.Grip({ Bottom = -0.32, Top = 0.33, Radius = 0.058, Wraps = 9, Bulge = 0.008 }))
		-- pear pommel
		table.insert(list, Parts.Lathe({ { 0.05, -0.33 }, { 0.1, -0.38 }, { 0.11, -0.46 }, { 0.08, -0.54 }, { 0, -0.6 } }, 10, "Trim"))
		return list
	end,
}

-- Greatsword: wide dark blade with an ember fuller, long ricasso with parrying lugs, wide guard.
-- ~7.0 studs.
Specs.ForgeGreatsword = {
	Model = "ForgeGreatsword",
	Class = "Greatsword",
	Handle = "Grip",
	Materials = {
		Blade = { Material = "Metal", Color = "#474B54", Reflectance = 0.12, Smooth = 25 },
		Edge = { Material = "Metal", Color = "#B8C0CA", Reflectance = 0.2, Smooth = 25 },
		Fuller = { Material = "Neon", Color = "#FF6A21", Smooth = 25 },
		Guard = { Material = "Metal", Color = "#1E1F24", Reflectance = 0.1, Smooth = 30 },
		Trim = { Material = "Metal", Color = "#6D727C", Reflectance = 0.15, Smooth = 50 },
		Grip = { Material = "Leather", Color = "#2B1E16", Smooth = 60 },
		Gem = { Material = "Neon", Color = "#FF7A2E", Smooth = 10 },
	},
	Points = { BladeBase = V3(0, 1.9, 0), BladeTip = V3(0, 5.75, 0), Sheath = V3(0.5, 2.5, 0) },
	Build = function()
		local list = {}
		-- ricasso (narrow, thick, no edge) then the wide blade
		table.insert(list, Parts.Blade({
			BaseY = 0.78,
			Length = 5.12,
			TipStart = 0.87,
			Bevel = 0.08,
			Stations = {
				{ 0.0, 0.16, 0.065, 0.0, 0.0 },
				{ 0.2, 0.16, 0.065, 0.0, 0.0 },
				{ 0.215, 0.32, 0.068, 0.0, 0.0 },
				{ 0.26, 0.33, 0.066, 0.07, 0.024 },
				{ 0.6, 0.3, 0.058, 0.065, 0.022 },
				{ 0.78, 0.28, 0.052, 0.0, 0.0 },
				{ 0.87, 0.25, 0.048, 0.0, 0.0 },
			},
		}))
		-- hooked parrying lugs just below where the blade widens (ricasso half width 0.16)
		local lug = { V2(0, -0.06), V2(0.14, -0.04), V2(0.24, 0.08), V2(0.13, 0.03), V2(0, 0.05) }
		for _, side in { 1, -1 } do
			local points = {}
			for _, p in lug do
				table.insert(points, V2(side * (0.13 + p.X), p.Y))
			end
			table.insert(list, Parts.Plate(points, 0.12, 0.02, 1.7, "Guard"))
		end
		-- wide guard with flared ends
		local guard = mirrorU({
			V2(0, -0.1),
			V2(0.75, -0.08),
			V2(1.0, -0.16),
			V2(1.04, 0.0),
			V2(0.98, 0.09),
			V2(0.75, 0.06),
			V2(0.2, 0.09),
			V2(0, 0.12),
		})
		table.insert(list, Parts.Plate(guard, 0.24, 0.035, 0.74, "Guard"))
		table.insert(list, Parts.Gem(V3(0, 0.75, 0), 0.08, 0.36, "X", 6, "Gem"))
		-- side rings on the guard
		for _, side in { 1, -1 } do
			local ring = Parts.Circle(V3(0.13 * side, 0.95, 0), 0.17, Vector3.yAxis, Vector3.zAxis, 16)
			table.insert(list, Parts.Tube(ring, 0.03, 6, true, "Guard"))
		end
		-- long two-hand grip with a raised center band
		table.insert(list, Parts.Grip({ Bottom = -0.75, Top = -0.05, Radius = 0.082, Wraps = 5, Bulge = 0.012 }))
		table.insert(list, Parts.Grip({ Bottom = 0.05, Top = 0.66, Radius = 0.082, Wraps = 4, Bulge = 0.012 }))
		table.insert(list, Parts.Lathe({ { 0.085, -0.06 }, { 0.11, -0.03 }, { 0.11, 0.03 }, { 0.085, 0.06 } }, 8, "Trim"))
		table.insert(list, Parts.Lathe({ { 0.085, 0.64 }, { 0.105, 0.66 }, { 0.105, 0.69 }, { 0.09, 0.7 } }, 8, "Trim"))
		-- heavy faceted pommel
		table.insert(list, Parts.Lathe({ { 0.09, -0.75 }, { 0.17, -0.82 }, { 0.19, -0.92 }, { 0.15, -1.02 }, { 0, -1.1 } }, 8, "Guard"))
		return list
	end,
}

-- Two-handed axe: long wooden haft, bearded crescent head with a bright edge band. ~6.5 studs.
local AXE_EDGE = {
	V2(1.1, 2.95),
	V2(1.25, 3.2),
	V2(1.32, 3.6),
	V2(1.33, 4.0),
	V2(1.28, 4.4),
	V2(1.2, 4.65),
}
local AXE_BAND = 0.14

local function axeDepth(u: number, _v: number): number
	if u < 0.2 then
		return 0.24
	end
	local f = math.clamp((u - 0.2) / 1.1, 0, 1)
	return 0.24 - 0.2 * f
end

Specs.ForgeGreataxe = {
	Model = "ForgeGreataxe",
	Class = "Greataxe",
	Handle = "Haft",
	Materials = {
		Haft = { Material = "Wood", Color = "#6B4A2E", Smooth = 50 },
		Grip = { Material = "Leather", Color = "#3A2618", Smooth = 60 },
		Head = { Material = "Metal", Color = "#555A62", Reflectance = 0.1, Smooth = 30 },
		Edge = { Material = "Metal", Color = "#D7DDE4", Reflectance = 0.25, Smooth = 30 },
		Trim = { Material = "Metal", Color = "#3B3E44", Reflectance = 0.1, Smooth = 50 },
	},
	Points = { BladeBase = V3(0, 2.6, 0.2), BladeTip = V3(0, 4.55, 1.25), Sheath = V3(0.5, 2.3, 0) },
	Build = function()
		local list = {}
		-- haft (octagonal, thicker near the head)
		table.insert(list, Parts.Lathe({
			{ 0.08, -1.62 },
			{ 0.082, 0.0 },
			{ 0.088, 2.8 },
			{ 0.095, 4.4 },
		}, 8, "Haft"))
		-- leather wraps where the hands go
		table.insert(list, Parts.Grip({ Bottom = -1.35, Top = 0.75, Radius = 0.086, Wraps = 7, Bulge = 0.012, Region = "Grip" }))
		-- butt cap and top spike
		table.insert(list, Parts.Lathe({ { 0.07, -1.78 }, { 0.11, -1.72 }, { 0.11, -1.62 }, { 0.09, -1.58 } }, 8, "Trim"))
		table.insert(list, Parts.Lathe({ { 0.1, 4.38 }, { 0.11, 4.42 }, { 0.07, 4.55 }, { 0, 4.72 } }, 8, "Trim"))
		-- langet ring under the head
		table.insert(list, Parts.Lathe({ { 0.093, 3.55 }, { 0.115, 3.58 }, { 0.115, 3.66 }, { 0.093, 3.69 } }, 8, "Trim"))
		-- head body: outline with the cutting edge replaced by the inner band line
		local inner = {}
		for _, p in AXE_EDGE do
			table.insert(inner, V2(p.X - AXE_BAND, p.Y))
		end
		local head = {
			V2(-0.14, 3.8),
			V2(0.14, 3.75),
			V2(0.35, 3.7),
			V2(0.7, 3.5),
			V2(0.92, 3.22),
		}
		for _, p in inner do
			table.insert(head, p)
		end
		for _, p in {
			V2(0.92, 4.5),
			V2(0.6, 4.38),
			V2(0.2, 4.38),
			V2(-0.14, 4.38),
			V2(-0.24, 4.33),
			V2(-0.3, 4.15),
			V2(-0.3, 3.95),
			V2(-0.24, 3.82),
		} do
			table.insert(head, p)
		end
		table.insert(list, Parts.Plate(head, 0.24, 0.025, 0, "Head", axeDepth))
		-- bright edge band: outer edge up, inner line back down
		local band = {}
		for _, p in AXE_EDGE do
			table.insert(band, p)
		end
		for i = #inner, 1, -1 do
			table.insert(band, inner[i])
		end
		table.insert(list, Parts.Plate(band, 0.06, 0.012, 0, "Edge", axeDepth))
		return list
	end,
}

Specs.Order = { "ForgeSword", "ForgeDagger", "ForgeRapier", "ForgeGreatsword", "ForgeGreataxe" }

return Specs

