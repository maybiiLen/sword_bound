--[[
	PlayerDataLoader
	Starts PlayerDataService. Nothing else belongs here; other systems require
	PlayerDataService directly and call :WaitForData / :ForEachLoaded. See Docs.PlayerData.
]]

require(script.Parent.PlayerDataService):Start()
