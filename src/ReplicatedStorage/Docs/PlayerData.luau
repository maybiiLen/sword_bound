--[[
================================================================================
  PLAYER DATA  (shared by every system; maintainer: Henry)
================================================================================
One save file per player, loaded on join and saved automatically (periodically, on leave
and on server shutdown). Built on ProfileStore by loleris (session-locked: a player can't
be loaded on two servers at once, so no duplication or lost data).

WHERE
  ServerScriptService.PlayerData
    ProfileStore         the library (don't edit)
    DataTemplate         default data + the key ownership table
    PlayerDataService    the API below
    PlayerDataLoader     Script that starts it

USING IT  (server only)
  local PlayerDataService = require(ServerScriptService.PlayerData.PlayerDataService)

  local data = PlayerDataService:WaitForData(player)    -- yields; nil if they left
  if data then
      data.Gold += 25                                   -- mutate directly, it auto-saves
  end

  PlayerDataService:GetData(player)                     -- non-yielding, nil until loaded
  PlayerDataService:ForEachLoaded(function(player, data) ... end)   -- now + future joins
  PlayerDataService.Loaded:Connect(fn)                  -- future joins only
  PlayerDataService.Releasing:Connect(fn)               -- player leaving, last chance to write
  player:GetAttribute("DataLoaded") == true             -- client-visible "ready" flag

ADDING A SAVED FIELD
  1. Add the key + default to DataTemplate, and add a row to its ownership table.
  2. That's it: existing players get the default the next time they join (Reconcile).
  Allowed values: strings, numbers, booleans, and tables of those. NO Instances, Vector3,
  Color3, CFrame, functions. Arrays without gaps; don't mix array + dictionary keys.

DON'T
  - rename or remove existing keys (wipes progress) - talk to the key's owner
  - call DataStoreService directly for player data
  - keep your own copy of data; always read it from PlayerDataService
  - let the client write data: remotes request, the server validates and writes

TESTING SAVES IN STUDIO
  Game Settings > Security > "Enable Studio Access to API Services" must be ON.
  When it's off, Output shows "[PlayerDataService] ... MOCK mode": everything works but
  nothing persists after you stop. Rejoin test: play, earn XP, stop, play again.
]]

return {}
