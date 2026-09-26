--!strict
--[[
	Signal
	Lightweight custom event, used instead of BindableEvents for module-to-module events.
	Handlers run in their own thread, so one erroring handler can't break the others.

	API:
		Signal.new() -> Signal
		signal:Connect(fn) -> Connection    (connection:Disconnect())
		signal:Once(fn) -> Connection
		signal:Fire(...)
		signal:Wait() -> ...
		signal:DisconnectAll()
		signal:Destroy()

	Used by: PlayerDataService, ProgressionService, DamageService, Hitbox, BaseWeapon.
	See Docs.README > "Shared utilities".
]]

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

type Handler = {
	fn: (...any) -> (),
	connection: Connection,
}

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable({} :: { _handlers: { Handler } }, Signal))

function Signal.new(): Signal
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal.Connect(self: Signal, fn: (...any) -> ()): Connection
	local handlers = self._handlers
	local connection = { Connected = true } :: any
	local handler: Handler = { fn = fn, connection = connection }
	function connection.Disconnect(conn: Connection)
		if not conn.Connected then
			return
		end
		conn.Connected = false
		local index = table.find(handlers, handler)
		if index then
			table.remove(handlers, index)
		end
	end
	table.insert(handlers, handler)
	return connection
end

function Signal.Once(self: Signal, fn: (...any) -> ()): Connection
	local connection: Connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)
	return connection
end

function Signal.Fire(self: Signal, ...: any)
	for _, handler in table.clone(self._handlers) do
		if handler.connection.Connected then
			task.spawn(handler.fn, ...)
		end
	end
end

function Signal.Wait(self: Signal): ...any
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal.DisconnectAll(self: Signal)
	for _, handler in table.clone(self._handlers) do
		handler.connection:Disconnect()
	end
end

function Signal.Destroy(self: Signal)
	self:DisconnectAll()
end

return Signal
