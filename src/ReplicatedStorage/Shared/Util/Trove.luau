--!strict
--[[
	Trove
	Collects things that need cleaning up (connections, instances, threads, objects with
	Destroy/Disconnect, plain functions) and cleans them all at once. Give every object that
	connects events or creates instances a Trove, and call trove:Clean() in its Destroy().

	API:
		Trove.new() -> Trove
		trove:Add(item) -> item          (item: Instance | RBXScriptConnection | thread | function | {Destroy}/{Disconnect})
		trove:Connect(signal, fn) -> connection
		trove:Clean()                    (cleans everything, trove stays usable)
		trove:Destroy()                  (alias of Clean)

	Used by: BaseWeapon, Hitbox, WeaponController, services.
	See Docs.README > "Shared utilities".
]]

local Trove = {}
Trove.__index = Trove

export type Trove = typeof(setmetatable({} :: { _items: { any } }, Trove))

function Trove.new(): Trove
	return setmetatable({ _items = {} }, Trove)
end

function Trove.Add<T>(self: Trove, item: T): T
	table.insert(self._items, item)
	return item
end

function Trove.Connect(self: Trove, signal: any, fn: (...any) -> ()): any
	return self:Add(signal:Connect(fn))
end

local function cleanItem(item: any)
	local kind = typeof(item)
	if kind == "function" then
		item()
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "thread" then
		if coroutine.status(item) ~= "dead" then
			pcall(task.cancel, item)
		end
	elseif kind == "table" then
		if typeof(item.Destroy) == "function" then
			item:Destroy()
		elseif typeof(item.Disconnect) == "function" then
			item:Disconnect()
		end
	end
end

function Trove.Clean(self: Trove)
	local items = self._items
	self._items = {}
	for index = #items, 1, -1 do
		cleanItem(items[index])
	end
end

function Trove.Destroy(self: Trove)
	self:Clean()
end

return Trove
