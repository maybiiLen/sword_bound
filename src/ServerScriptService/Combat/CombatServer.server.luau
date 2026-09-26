--[[
	CombatServer
	Bootstraps the server side of combat + progression. The only Script in this folder; every
	other module is a service with :Start(). Order matters: progression before weapons
	(equipping sets the active class), weapons before combat (combat reads the equipped weapon).

	PlayerData is started by its own loader (ServerScriptService.PlayerData.PlayerDataLoader).
	See Docs.Combat > "Server".
]]

local services = script.Parent

for _, name in { "ProgressionService", "WeaponService", "CombatService", "DummyService" } do
	require(services:WaitForChild(name)):Start()
end
