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
  Docs.Inventory     owned weapons, the Inventory panel, ownership-gated equipping
  Docs.Abilities     ability hotbar (3 slots + ultimate bar), preview mode, how to hook up real abilities
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
  Inventory     Henry     ReplicatedStorage.Inventory, ServerScriptService.Inventory,
                          StarterGui.Main Menu Gui.InventoryItemsController
  Abilities     Henry     ReplicatedStorage.Abilities, StarterGui.AbilityHud
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
  2026-10-08  Henry  Combat Phase 0 (shared rules for new weapon classes): new Combat.CombatRules (pure math,
                     unit tested by ServerStorage.CombatDev.Tests). Damage types Slash/Strike/Pierce, counter
                     hits (target mid-attack: 1.1x, Pierce 1.3x), armor windows (Armor / HyperArmor: no flinch,
                     0.9x damage taken), per-class CritMultiplier and GuardDamage, longest stun wins, stagger
                     immunity (1 s PvE, 3 s PvP), CombatConfig.PvP table, stricter marker checks. The client now
                     obeys the server's Flinch. See Docs.Combat > DAMAGE TYPES, ARMOR, STUN RULES. (via Claude)
  2026-10-05  Henry  New StarterGui.Main Menu Gui.InventoryWeaponDisplay: while the inventory is open the equipped
                     weapon is drawn into the live character's hand (a different weapon you equip is drawn too);
                     closing puts it back as it was. InventoryController calls Enter()/Exit(). See Docs.Inventory >
                     CHARACTER VIEW > WEAPON IN HAND. (via Claude)
  2026-10-04  Henry  Inventory CONTENTS now taper too (small per-element rotations + column stretch; originals
                     saved in Taper* attributes). InventoryController now forces the panel closed at startup
                     (it had been saved visible, so the first open skipped the camera and hid the HUD from the
                     start). See Docs.Inventory > TAPER. (via Claude)
  2026-10-04  Henry  Inventory panels now taper like the reference (a little smaller toward the middle of the
                     screen, taller toward the edges) with slice-built shapes: StatsPanel.Shape and
                     InventoryPanel.RightShape. The earlier rotation was removed (Rotation = 0) and the weapon
                     grid scrolls natively again (PAGED_GRID = false). See Docs.Inventory > TAPER. (via Claude)
  2026-10-03  Henry  Inventory now shows the LIVE character: new StarterGui.Main Menu Gui.InventoryCamera
                     locks the camera onto the real character (left of screen, facing the menu) while the
                     inventory is open, blocks walking input and frees the cursor; InventoryController no
                     longer builds a duplicate in a ViewportFrame. See Docs.Inventory > CHARACTER VIEW.
                     (via Claude)
  2026-10-03  Henry  Inventory layout now matches the reference: character + stats float at the left, the
                     Equipment panel (title, tabs, slot list, detail card, grid) sits at the right with a gap
                     between. New InventoryHudHider script hides all other HUDs/menus (incl. Roblox chat,
                     player list) while the inventory is open and restores them on close. See Docs.Inventory
                     > SCREEN LAYOUT, HUD HIDING. (via Claude)
  2026-10-02  Henry  Inventory screen revamp (dark, SAO-style): character + stats, weapon/armor slot list,
                     detail card with Equip button, categorized grid with Sort. Rebuilt InventoryPanel in
                     place; InventoryItemsController rewritten, InventoryTabController recolored (dark,
                     per-tab title). Armor/stats/MODs are placeholders. See Docs.Inventory > SCREEN LAYOUT.
                     (via Claude)
  2026-10-02  Henry  Ability hotbar HUD: StarterGui.AbilityHud + ReplicatedStorage.Abilities (AbilityConfig,
                     AbilityHudController). 3 ability slots with red cooldown fill and an ultimate bar; no
                     abilities exist yet, so AbilityConfig.PreviewMode fakes cooldowns/charge. See
                     Docs.Abilities. (via Claude)
  2026-10-02  Henry  Inventory icons were invisible: Main Menu Gui uses ZIndexBehavior.Global, so slot icon,
                     name and equipped marker (ZIndex 1/5) drew behind the slots (ZIndex 11). They are now
                     slot.ZIndex + 1/2/3 in InventoryItemsController. See Docs.Inventory > UI NOTES. (via Claude)
  2026-10-01  Henry  Inventory (weapons): DataTemplate.Inventory.Weapons, InventoryService, Inventory panel
                     item grid + Weapon slot (InventoryItemsController); EquipRemote "Equip" now requires
                     ownership and Idle state. See Docs.Inventory. (via Claude)
  2026-10-01  Henry  TestSword (imported mesh) added as a weapon (Weapons/TestSword + WeaponModels/TestSword)
                     and made the default: CombatConfig.DefaultWeapon and DataTemplate.EquippedWeapon.
                     (via Claude)
  2026-10-01  Henry  Directional rolls while locked on (RollBack / RollLeft / RollRight, keep facing the
                     target); same i-frames, cost and cancel timing as Roll. (via Claude)
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

