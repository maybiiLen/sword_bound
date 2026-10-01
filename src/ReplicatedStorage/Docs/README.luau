--[[
================================================================================
  SWORD BOUND - TEAM DOCS  (start here)
================================================================================
Everything in ReplicatedStorage.Docs is documentation only: comment blocks, never
require()d. Humans and Cursor agents: read the page for a system BEFORE changing it,
and update it (plus the changelog below) as the last step of every feature.

PAGES
  Docs.Conventions   team rules: folders, ownership, how agents should edit the shared place
  Docs.Combat        swords, combos, hitboxes, server validation, adding weapons
  Docs.Progression   FF14-style classes (weapon type = class), levels 1-20, XP
  Docs.PlayerData    saving (ProfileStore) - how ANY system adds saved fields
  Docs.Sprint        sprint + stamina
  Docs.Roadmap       Floor 1 build list (snapshot of the Google Sheet) + new floor checklist

SYSTEM INDEX
  System        Owner     Locations
  -----------   -------   ---------------------------------------------------------
  Combat        Henry     ReplicatedStorage.Combat, ServerScriptService.Combat,
                          StarterPlayerScripts.Combat, Workspace.TrainingDummy
  Progression   Henry     ReplicatedStorage.Classes, ServerScriptService.Combat.ProgressionService,
                          StarterGui.ClassGui
  PlayerData    Henry     ServerScriptService.PlayerData   (shared: everyone adds fields)
  Sprint        Henry     ReplicatedStorage.Sprint, ServerScriptService.SprintServer,
                          StarterPlayerScripts.SprintClient, StarterGui.SprintGui
  Shared utils  shared    ReplicatedStorage.Shared.Util (Signal, Trove)
  SAO HUD       teammate  StarterGui.SAO_HUD, StarterPlayerScripts.HealthBarController
  (add your system here when you create one)

SHARED UTILITIES  (ReplicatedStorage.Shared.Util)
  Signal   custom events:  local s = Signal.new(); s:Connect(fn); s:Fire(...); s:Once(fn); s:Wait()
  Trove    cleanup bag:    local t = Trove.new(); t:Add(instanceOrConnectionOrFn); t:Connect(sig, fn); t:Clean()
  Use these instead of writing your own; every object that connects events should own a Trove.

QUICK HOW-TOS
  Give a mob XP:              set attribute XPReward = <number> on the mob Model (Docs.Progression)
  Save a new field:           add it to ServerScriptService.PlayerData.DataTemplate (Docs.PlayerData)
  Add a sword:                definition + model, no code (Docs.Combat > "Adding a new sword")
  Stop a player sprinting:    character:SetAttribute("SprintBlocked", true) on the server (Docs.Sprint)
  Read a player's level:      player:GetAttribute("ClassLevel") / ("Level_Sword") anywhere

CHANGELOG  (newest first; one line per change, with your name)
  2026-10-01  Henry  Contextual attacks: running, jump (plunge), roll and guard counter, as weapon fields
                     with Sword defaults in Combat.ClassDefaults; server-validated; Studio-only
                     CombatTestInput hook for timed tests. See Docs.Combat > CONTEXTUAL ATTACKS. (via Claude)
  2026-10-01  Henry  Riposte finisher on posture/guard-broken enemies (red highlight, i-frames, guaranteed
                     damage) + Combat.ClassDefaults (class-wide weapon fields). See Docs.Combat > RIPOSTE.
                     (via Claude)
  2026-10-01  Henry  Parry window 0.2 -> 0.3 s, anti-mash (re-raise within 0.4 s = 0.07 s window),
                     ping compensation via client press time (max 0.15 s rewind). (via Claude)
  2026-09-30  Henry  Combat momentum + deflect pass (via Claude): light swings on press (hold turns it into
                     the heavy, stamina refunded), attacks carry momentum + bigger target-assisted lunge that
                     stops on contact, sprint attack, wind-up cancel into block/roll, Sekiro-style parry
                     (drains attacker poise, short recoil, perfect parry tier), new parry VFX/SFX. See
                     Docs.Combat > Controls / State machine / Defense / Effects.
  2026-09-30  Henry  Combat feel pass (via Claude): reworked Light1-3 (hip-led swings, foot step on the
                     lunge, overshoot, settle tail, combo poses flow into each other) and staggered
                     cancels (RollOpen, MoveOpen markers). Server/client timing unchanged except rolls
                     out of Light1/2 open 0.08 s later. See Docs.Combat > State machine / Animations.
  2026-09-29  Henry  Docs.Combat: attacking while sheathed no longer draws the weapon (matches WeaponController).
  2026-09-29  Henry  Docs.Roadmap added: Floor 1 build list and new floor checklist (via Claude).
  2026-09-26  Henry  Combat framework v1: StarterSword ("Anneal Blade"), 3-hit combo, swept hitbox,
                     server validation, training dummy, class progression (Sword/Bow, Lv 1-20),
                     PlayerData (ProfileStore), ClassGui, these Docs.
  (earlier)   Henry  Sprint system with stamina bar.
]]

return {}
