--[[
================================================================================
  SPRINT  (owner: Henry)
================================================================================
Hold Left Shift (gamepad: L3) to sprint. Sprinting drains stamina; empty stamina =
exhausted until it regenerates to MinStaminaToSprint. Speed 16 -> 26, FOV boost, run
animation, and a stamina bar that fades when full.

WHERE
  ReplicatedStorage.Sprint
    SprintConfig     tuning (speeds, drain/regen, keys, attribute names)
    SprintRemote     client -> server: wantsSprint (bool)
    Animations/      SprintR15, SprintR6
  ServerScriptService.SprintServer          authoritative sprint state + WalkSpeed
  ServerScriptService.Combat.StaminaService owns the stamina pool (shared with combat)
  StarterPlayerScripts.SprintClient         input, prediction, animation, FOV, bar
  StarterGui.SprintGui                      the stamina bar

HOW IT WORKS
  The client only sends intent. The server decides every frame whether the player is
  actually sprinting (intent, stamina, not exhausted, alive, moving, not blocked), sets
  WalkSpeed and drains stamina through StaminaService, which also handles regen and
  replicates it through character attributes. The client predicts briefly
  (PredictionGrace) so it feels instant.

STAMINA IS SHARED
  Sprinting, attacks, rolls and blocked hits all spend the same pool (StaminaService).
  Server code that wants stamina: require(ServerScriptService.Combat.StaminaService)
    :Get(player), :TrySpend(player, amount), :Spend(player, amount), :Drain(player, amount)

ATTRIBUTES  (on the character)
  Stamina, MaxStamina                          written by StaminaService
  Sprinting, Exhausted                         written by SprintServer
  SprintBlocked                                SET BY OTHER SYSTEMS to stop sprinting
  MoveSpeedMultiplier                          SET BY OTHER SYSTEMS to scale WalkSpeed

BLOCKING SPRINT / SLOWING FROM YOUR SYSTEM  (server)
  character:SetAttribute("SprintBlocked", true)        -- e.g. stunned, casting
  character:SetAttribute("MoveSpeedMultiplier", 0.5)   -- final WalkSpeed = base * this
  Combat's CombatService sets both for every combat state (attacking, blocking, rolling...).
  They're single values: coordinate with Henry before a second system writes them.

NOTE
  Don't write Humanoid.WalkSpeed directly - SprintServer/SprintClient overwrite it every
  frame. Use MoveSpeedMultiplier.
]]

return {}
