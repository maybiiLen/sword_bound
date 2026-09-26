--!strict
--[[
	WeaponRegistry
	Loads every weapon definition in Combat.Weapons (one ModuleScript per weapon) and checks
	each one references a real class, model and behavior. Adding a sword = drop a definition
	ModuleScript in Combat.Weapons and a model in Combat.Assets.WeaponModels; nothing else.

	API:
		WeaponRegistry.Get(weaponId) -> WeaponDefinition?
		WeaponRegistry.GetAll() -> { [weaponId]: WeaponDefinition }
		WeaponRegistry.GetModel(weaponId) -> Model?        the template (clone it)
		WeaponRegistry.GetBehavior(weaponId) -> behavior class (WeaponBehaviors.<Class>)

	Used by: WeaponService, CombatService, WeaponController. See Docs.Combat.
]]

local Types = require(script.Parent.Types)

local Combat = script.Parent
local WeaponModels = Combat.Assets.WeaponModels
local Behaviors = Combat.WeaponBehaviors
local ClassDefinitions = Combat.Parent.Classes.Definitions

local definitions: { [string]: Types.WeaponDefinition } = {}

for _, module in Combat.Weapons:GetChildren() do
	if not module:IsA("ModuleScript") then
		continue
	end
	local def: Types.WeaponDefinition = (require :: any)(module)
	local ok = true
	local function check(condition: any, message: string)
		if not condition then
			warn(`[WeaponRegistry] {module.Name}: {message}`)
			ok = false
		end
	end
	check(def.Id == module.Name, `Id '{def.Id}' must equal the module name`)
	check(ClassDefinitions:FindFirstChild(def.Class), `Class '{def.Class}' has no Classes.Definitions module`)
	check(Behaviors:FindFirstChild(def.Class), `Class '{def.Class}' has no WeaponBehaviors module`)
	check(WeaponModels:FindFirstChild(def.Model), `Model '{def.Model}' not found in Assets.WeaponModels`)
	check(#def.Combo > 0, "Combo is empty")
	if ok then
		definitions[def.Id] = table.freeze(def)
	end
end

local WeaponRegistry = {}

function WeaponRegistry.Get(weaponId: string): Types.WeaponDefinition?
	return definitions[weaponId]
end

function WeaponRegistry.GetAll(): { [string]: Types.WeaponDefinition }
	return definitions
end

function WeaponRegistry.GetModel(weaponId: string): Model?
	local def = definitions[weaponId]
	return def and WeaponModels:FindFirstChild(def.Model) :: Model?
end

function WeaponRegistry.GetBehavior(weaponId: string): any
	local def = definitions[weaponId]
	local module = def and Behaviors:FindFirstChild(def.Class)
	return module and (require :: any)(module)
end

return WeaponRegistry
