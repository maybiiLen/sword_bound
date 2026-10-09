--[[
	GrowthServer
	Bootstraps the server side of the Growth screen (attribute points). The only Script in this
	folder; GrowthService is a module. PlayerData is started by its own loader.
	See Docs.Growth.
]]

require(script.Parent:WaitForChild("GrowthService")):Start()

