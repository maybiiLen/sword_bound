--[[
	CombatDev.Tests  (dev only, never required by the game)
	Unit tests for the shared combat rules (Combat.CombatRules), a sanity check of every animation
	spec's markers, and a check that WeaponRegistry merged the class defaults.

	Run in a play test (Server VM) so modules load fresh:
		print(require(game.ServerStorage.CombatDev.Tests).Run())
	From the Edit command bar, require a clone instead (Edit caches old module results):
		print(require(game.ServerStorage.CombatDev.Tests:Clone()).Run())

	Run() returns a report string and the number of failures. Add a test: append to TESTS.
	See the vault note "Phase 0 shared combat systems".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = ReplicatedStorage.Combat
local CombatRules = require(Combat.CombatRules)
local CombatConfig = require(Combat.CombatConfig)
local AnimationLibrary = require(Combat.Animations.AnimationLibrary)
local Specs = require(Combat.Animations.Specs)
local WeaponRegistry = require(Combat.WeaponRegistry)

local EPSILON = 1e-6

local function expectEqual(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(`{label}: expected {tostring(expected)}, got {tostring(actual)}`, 0)
	end
end

local function expectNear(actual: number, expected: number, label: string)
	if math.abs(actual - expected) > EPSILON then
		error(`{label}: expected {expected}, got {actual}`, 0)
	end
end

local function expectTrue(condition: any, label: string)
	if not condition then
		error(label, 0)
	end
end

local TESTS = {}

local function test(name: string, fn: () -> ())
	table.insert(TESTS, { name = name, fn = fn })
end

-- Damage types -----------------------------------------------------------------------------

test("DamageTypeOf: attack wins, then weapon, then Slash", function()
	expectEqual(CombatRules.DamageTypeOf({ DamageType = "Pierce" }, { DamageType = "Strike" }), "Pierce", "attack")
	expectEqual(CombatRules.DamageTypeOf({}, { DamageType = "Strike" }), "Strike", "weapon")
	expectEqual(CombatRules.DamageTypeOf({}, nil), "Slash", "fallback")
	expectEqual(CombatRules.DamageTypeOf(nil, nil), "Slash", "nil attack")
end)

test("IsCounterState: only Attacking and Charging", function()
	expectEqual(CombatRules.IsCounterState("Attacking"), true, "Attacking")
	expectEqual(CombatRules.IsCounterState("Charging"), true, "Charging")
	local others = { "Idle", "Rolling", "Blocking", "Staggered" }
	for _, state in others do
		expectEqual(CombatRules.IsCounterState(state), false, state)
	end
	expectEqual(CombatRules.IsCounterState(nil), false, "nil")
end)

test("CounterMultiplier: Slash 1.1, Strike 1.1, Pierce 1.3, PvP keeps half the bonus", function()
	expectNear(CombatRules.CounterMultiplier("Slash", true), 1.1, "Slash")
	expectNear(CombatRules.CounterMultiplier("Strike", true), 1.1, "Strike")
	expectNear(CombatRules.CounterMultiplier("Pierce", true), 1.3, "Pierce")
	expectNear(CombatRules.CounterMultiplier("Pierce", false), 1, "not a counter")
	expectNear(CombatRules.CounterMultiplier("Pierce", true, true), 1.15, "Pierce PvP")
	expectNear(CombatRules.CounterMultiplier("Unknown", true), 1.1, "unknown type falls back to Slash")
end)

test("GuardStaminaCost: Strike 1.4x and Pierce 0.9x of Slash, GuardDamage scales", function()
	local slash = CombatRules.GuardStaminaCost(20, "Slash", nil, 0.3)
	expectNear(slash, 20 * CombatConfig.BlockStaminaPerDamage * 0.7, "Slash matches the old formula")
	expectNear(CombatRules.GuardStaminaCost(20, "Strike", nil, 0.3), slash * 1.4, "Strike")
	expectNear(CombatRules.GuardStaminaCost(20, "Pierce", nil, 0.3), slash * 0.9, "Pierce")
	expectNear(CombatRules.GuardStaminaCost(20, "Slash", 1.5, 0.3), slash * 1.5, "GuardDamage 1.5")
end)

-- Armor --------------------------------------------------------------------------------------

test("ArmorOf: Armor table, HyperArmor becomes {}, nothing otherwise", function()
	local armor = { Start = 0.1 }
	expectEqual(CombatRules.ArmorOf({ Armor = armor }), armor, "Armor")
	local hyper = CombatRules.ArmorOf({ HyperArmor = true })
	expectTrue(hyper ~= nil and next(hyper) == nil, "HyperArmor -> empty table")
	expectEqual(CombatRules.ArmorOf({}), nil, "no armor")
	expectEqual(CombatRules.ArmorOf(nil), nil, "nil attack")
end)

test("ArmorWindow: explicit Start/End, else markers, else the whole action", function()
	local s, e = CombatRules.ArmorWindow({ Animation = "HeavyRelease", Armor = { Start = 0.05, End = 0.3 } })
	expectNear(s :: number, 0.05, "explicit start")
	expectNear(e :: number, 0.3, "explicit end")
	s, e = CombatRules.ArmorWindow({ Animation = "HeavyRelease", HyperArmor = true })
	local markerStart = AnimationLibrary.MarkerTime("HeavyRelease", "ArmorStart") or 0
	local markerEnd = AnimationLibrary.MarkerTime("HeavyRelease", "ArmorEnd") or AnimationLibrary.ActionLength("HeavyRelease")
	expectNear(s :: number, markerStart, "default start")
	expectNear(e :: number, markerEnd, "default end")
	s, e = CombatRules.ArmorWindow({ Animation = "HeavyRelease" })
	expectEqual(s, nil, "no armor -> no window")
end)

test("ArmorActive: inside the window only", function()
	local attack = { Animation = "HeavyRelease", Armor = { Start = 0.1, End = 0.4 } }
	expectEqual(CombatRules.ArmorActive(attack, 0.05), false, "before")
	expectEqual(CombatRules.ArmorActive(attack, 0.1), true, "start edge")
	expectEqual(CombatRules.ArmorActive(attack, 0.25), true, "inside")
	expectEqual(CombatRules.ArmorActive(attack, 0.4), true, "end edge")
	expectEqual(CombatRules.ArmorActive(attack, 0.41), false, "after")
	expectEqual(CombatRules.ArmorActive({ Animation = "Light1" }, 0.2), false, "no armor")
end)

test("ArmorDamageTaken: 1 without armor, config default, per-attack override, PvP", function()
	expectNear(CombatRules.ArmorDamageTaken({}), 1, "no armor")
	expectNear(CombatRules.ArmorDamageTaken({ HyperArmor = true }), CombatConfig.ArmorDamageTaken, "default")
	expectNear(CombatRules.ArmorDamageTaken({ Armor = { DamageTaken = 0.75 } }), 0.75, "override")
	expectNear(CombatRules.ArmorDamageTaken({ HyperArmor = true }, true), CombatConfig.PvP.ArmorDamageTaken, "PvP")
end)

-- Damage -------------------------------------------------------------------------------------

test("HitDamage: each multiplier and their product, rounded to 0.1", function()
	expectNear(CombatRules.HitDamage({ Base = 24 }), 24, "plain")
	expectNear(CombatRules.HitDamage({ Base = 24, Staggered = true, CritMultiplier = 1.5 }), 36, "crit")
	expectNear(CombatRules.HitDamage({ Base = 24, Staggered = true }), 24 * CombatConfig.CritMultiplier, "crit uses config default")
	expectNear(CombatRules.HitDamage({ Base = 24, Staggered = false, CritMultiplier = 1.5 }), 24, "crit needs a stagger")
	expectNear(CombatRules.HitDamage({ Base = 24, Counter = 1.1 }), 26.4, "counter")
	expectNear(CombatRules.HitDamage({ Base = 20, ArmorTaken = 0.9 }), 18, "armor")
	expectNear(CombatRules.HitDamage({ Base = 20, LevelMultiplier = 1.1, Counter = 1.3, ArmorTaken = 0.9 }), 25.7, "product rounded")
end)

-- Stun rules ---------------------------------------------------------------------------------

test("StaggerUpdate: longest stun wins", function()
	local newEnd, kind = CombatRules.StaggerUpdate(0, nil, 10, 1.2, "Stagger")
	expectNear(newEnd, 11.2, "not staggered -> new end")
	expectEqual(kind, "Stagger", "not staggered -> new kind")
	newEnd, kind = CombatRules.StaggerUpdate(11.2, "Stagger", 10.5, 0.3, "ParryRecoil")
	expectNear(newEnd, 11.2, "shorter one is ignored")
	expectEqual(kind, "Stagger", "shorter one keeps the kind")
	newEnd, kind = CombatRules.StaggerUpdate(10.3, "ParryRecoil", 10, 1.2, "Stagger")
	expectNear(newEnd, 11.2, "longer one replaces")
	expectEqual(kind, "Stagger", "longer one takes the kind")
	newEnd, kind = CombatRules.StaggerUpdate(9, "Stagger", 10, 0.3, "ParryRecoil")
	expectNear(newEnd, 10.3, "expired stun is replaced")
	expectEqual(kind, "ParryRecoil", "expired stun kind is replaced")
end)

test("StaggerUpdate: Riposted takes the kind but never shortens", function()
	local newEnd, kind = CombatRules.StaggerUpdate(12, "Stagger", 10, 1.5, "Riposted")
	expectNear(newEnd, 12, "keeps the longer end")
	expectEqual(kind, "Riposted", "takes the kind")
	newEnd, kind = CombatRules.StaggerUpdate(10.5, "Stagger", 10, 1.5, "Riposted")
	expectNear(newEnd, 11.5, "extends when longer")
	expectEqual(kind, "Riposted", "kind")
end)

test("StaggerImmunity: PvE and PvP times from CombatConfig", function()
	expectNear(CombatRules.StaggerImmunity(false), CombatConfig.StaggerImmunityTime, "PvE")
	expectNear(CombatRules.StaggerImmunity(true), CombatConfig.PvP.StaggerImmunityTime, "PvP")
	expectTrue(CombatConfig.PvP.StaggerImmunityTime >= CombatConfig.StaggerImmunityTime, "PvP immunity is not shorter")
end)

-- Data sanity --------------------------------------------------------------------------------

test("Specs: every hit window is ordered and inside the clip", function()
	for name, spec in Specs do
		local markers = spec.Markers
		if markers and markers.HitStart then
			local length = AnimationLibrary.Length(name)
			expectTrue(markers.HitEnd ~= nil, `{name}: HitStart without HitEnd`)
			expectTrue(markers.HitStart < markers.HitEnd, `{name}: HitStart must be before HitEnd`)
			expectTrue(markers.HitEnd <= length + EPSILON, `{name}: HitEnd after the clip ends`)
			if markers.CancelOpen then
				expectTrue(markers.HitEnd <= markers.CancelOpen, `{name}: CancelOpen before HitEnd`)
			end
		end
		if markers and markers.ArmorStart and markers.ArmorEnd then
			expectTrue(markers.ArmorStart < markers.ArmorEnd, `{name}: ArmorStart must be before ArmorEnd`)
		end
	end
end)

test("WeaponRegistry: Sword weapons get the class stats and thrust types", function()
	local count = 0
	for id, definition in WeaponRegistry.GetAll() do
		if definition.Class == "Sword" then
			count += 1
			expectEqual(definition.DamageType, "Slash", `{id} DamageType`)
			expectTrue(typeof(definition.CritMultiplier) == "number", `{id} CritMultiplier`)
			expectTrue(typeof(definition.GuardDamage) == "number", `{id} GuardDamage`)
			local rollAttack = (definition :: any).RollAttack
			local riposte = (definition :: any).Riposte
			expectEqual(CombatRules.DamageTypeOf(rollAttack, definition), "Pierce", `{id} RollAttack`)
			expectEqual(CombatRules.DamageTypeOf(riposte, definition), "Pierce", `{id} Riposte`)
			expectEqual(CombatRules.DamageTypeOf(definition.Combo[1], definition), "Slash", `{id} Combo[1]`)
		end
	end
	expectTrue(count > 0, "no Sword weapons loaded (did WeaponRegistry reject them? check warnings)")
end)

-- Runner -------------------------------------------------------------------------------------

local Tests = {}

function Tests.Run(): (string, number)
	local lines = {}
	local passed = 0
	local failed = 0
	for _, entry in TESTS do
		local ok, message = pcall(entry.fn)
		if ok then
			passed += 1
			table.insert(lines, "PASS  " .. entry.name)
		else
			failed += 1
			table.insert(lines, "FAIL  " .. entry.name .. "  ->  " .. tostring(message))
		end
	end
	table.insert(lines, `{passed} passed, {failed} failed`)
	return table.concat(lines, "\n"), failed
end

return Tests

