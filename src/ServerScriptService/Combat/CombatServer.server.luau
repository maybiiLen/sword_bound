--[[
	CombatServer
	Bootstraps the server side of combat + progression. The only Script in this folder; every
	other module is a service. Order matters: progression before weapons (equipping sets the
	active class), weapons before combat (combat reads the equipped weapon).
	StaminaService and PoiseService start themselves when first required.

	PlayerData is started by its own loader (ServerScriptService.PlayerData.PlayerDataLoader).
	See Docs.Combat > "Server".
]]

local services = script.Parent

require(services:WaitForChild("StaminaService"))
require(services:WaitForChild("PoiseService"))

for _, name in { "ProgressionService", "WeaponService", "CombatService", "DummyService", "SparringKnightService" } do
	require(services:WaitForChild(name)):Start()
end
