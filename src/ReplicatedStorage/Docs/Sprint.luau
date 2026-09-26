--[[
================================================================================
  SPRINT  (owner: Henry)
================================================================================
Hold Left Shift (gamepad: L3) to sprint. Sprinting drains stamina; empty stamina =
exhausted until it regenerates to MinStaminaToSprint. Speed 16 -> 26, FOV boost, run
animation, and a stamina bar that fades when full.

WHERE
  ReplicatedStorage.Sprint
    SprintConfig     all tuning (speeds, drain/regen, keys, attribute names)
    SprintRemote     client -> server: wantsSprint (bool)
    Animations/      SprintR15, SprintR6
  ServerScriptService.SprintServer          authoritative: owns stamina + WalkSpeed
  StarterPlayerScripts.SprintClient         input, prediction, animation, FOV, bar
  StarterGui.SprintGui                      the stamina bar

HOW IT WORKS
  The client only sends intent. The server decides every frame whether the player is
  actually sprinting (intent, stamina, not exhausted, alive, moving, not blocked), sets
  WalkSpeed, drains/regens stamina and replicates it through character attributes.
  The client predicts briefly (PredictionGrace) so it feels instant.

ATTRIBUTES  (on the character)
  Stamina, MaxStamina, Sprinting, Exhausted   written by SprintServer, read by anyone
  SprintBlocked                                SET BY OTHER SYSTEMS to stop sprinting

BLOCKING SPRINT FROM YOUR SYSTEM  (server)
  character:SetAttribute("SprintBlocked", true)   -- e.g. while attacking, stunned, casting
  character:SetAttribute("SprintBlocked", false)
  Combat's CombatService does this for the duration of every swing. If two systems need
  it at once, coordinate (it's a single flag).

NOTE
  SprintServer sets Humanoid.WalkSpeed. Other systems that change speed (slows, mounts)
  should go through a shared speed API rather than writing WalkSpeed directly - talk to
  Henry before adding one.
]]

return {}
