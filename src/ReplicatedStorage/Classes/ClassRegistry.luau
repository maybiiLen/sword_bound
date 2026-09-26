--!strict
--[[
	ClassRegistry
	Loads every class definition in Classes.Definitions (one ModuleScript per class).
	Adding a class = add a ModuleScript there; nothing else needs registering.

	API:
		ClassRegistry.Get(classId) -> ClassDefinition?
		ClassRegistry.GetAll() -> { [classId]: ClassDefinition }

	See Docs.Progression > "Adding a class".
]]

local Types = require(script.Parent.Parent.Combat.Types)

local definitions: { [string]: Types.ClassDefinition } = {}

for _, module in script.Parent.Definitions:GetChildren() do
	if module:IsA("ModuleScript") then
		local def = (require :: any)(module)
		assert(def.Id == module.Name, `Class definition {module.Name} has Id '{def.Id}'; they must match`)
		definitions[def.Id] = table.freeze(def)
	end
end

local ClassRegistry = {}

function ClassRegistry.Get(classId: string): Types.ClassDefinition?
	return definitions[classId]
end

function ClassRegistry.GetAll(): { [string]: Types.ClassDefinition }
	return definitions
end

return ClassRegistry
