-- Shared coordinator so only one HUD panel (Inventory, Settings, Inbox, the dropdown
-- menu, etc.) is ever open at a time. Each panel's controller registers itself here
-- with a name and its own close function, then calls PanelManager.open(name) right
-- before showing itself -- this closes every other registered panel first.

local PanelManager = {}
local panels = {} -- name -> closeFunction

function PanelManager.register(name, closeFn)
	panels[name] = closeFn
end

function PanelManager.open(name)
	for panelName, closeFn in pairs(panels) do
		if panelName ~= name then
			closeFn()
		end
	end
end

return PanelManager
