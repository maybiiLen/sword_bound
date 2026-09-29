--[[
================================================================================
  ROADMAP  (owner: Henry)
================================================================================
Snapshot of the Google Sheet "Floor 1 MMORPG Build List", copied 2026-09-29.
THE SHEET IS THE SOURCE OF TRUTH. Tick boxes there; refresh this page when it drifts.
  https://docs.google.com/spreadsheets/d/1YRKda26_jc5A7cRp01cDvw5nhTO0E9NhXP_DCsVIH1U/edit?gid=921768821

Goal: Floor 1 end to end, with every core system reusable so later floors only add
new bosses, enemies, loot and the occasional mechanic (see NEW FLOOR CHECKLIST).
Scope tags:  [E] Engine, built once   [F1] Floor 1 content
At snapshot: 6 / 101 done (Engine 5 / 87, Floor 1 content 1 / 14).

ALREADY BUILT
  [x]   1  [E]  Running animation and run script
  [x]   2  [E]  Health bar and EXP bar UI
  [x]   3  [F1] First sword model
  [x]   4  [E]  Basic sword attack
  [x]   5  [E]  Dodge, first pass
  [x]   6  [E]  Parry, first pass

CORE ARCHITECTURE
  [ ]   7  [E]  Player saves on ProfileStore with session locking and autosave
                  (ProfileStore https://github.com/MadStudioRoblox/ProfileStore)
  [ ]   8  [E]  Save schema: per-weapon levels and XP, inventory, equipped gear, currency,
                floors cleared, quests, mounts owned, settings, plus a schema version number
                for migrations  (FF14 forum https://forum.square-enix.com/ffxiv/threads/209629)
  [ ]   9  [E]  Save migration code that upgrades old saves when new fields are added
  [ ]  10  [E]  Config ModuleScripts for Weapons, Skills, Mobs, Bosses, Items, LootTables,
                Quests, Mounts and Floors, so a new floor is mostly new data
  [ ]  11  [E]  Floor template: every floor uses the same folder layout
                (Town, Gate, MobZones, Dungeon, BossArena, Spawns)
  [ ]  12  [E]  Server-authoritative combat: client plays the swing instantly, server
                validates and deals damage
                  (Combat guide https://kitsblox.com/blog/how-to-make-combat-system-roblox)
  [ ]  13  [E]  Validate every RemoteEvent (range, cooldown, weapon state) and rate limit them
                  (Combat guide, same link)
  [ ]  14  [E]  Shared damage and stat formula module used by players, mobs and bosses
  [ ]  15  [E]  Status effect framework (buffs, debuffs, damage over time, stun, slow)
  [ ]  16  [E]  Combat state flag (in combat or not) that swaps, mounts and regen all read
                  (FF14 forum)

CHARACTER AND STATS
  [ ]  17  [E]  Stats: HP, SP, stamina, attack, defense, crit, derived from weapon level and gear
  [ ]  18  [E]  XP curve per weapon type, stored in config  (FF14 forum)
  [ ]  19  [E]  HP and SP regen out of combat
  [ ]  20  [E]  Death, respawn at town, and a decided death penalty
  [ ]  21  [E]  Character appearance (hair, face, outfit) saved separately from gear stats,
                so a glamour system can come later

COMBAT
  [ ]  22  [E]  Server hitboxes: GetPartBoundsInBox for swings, raycasts for thrusts
                  (Combat guide)
  [ ]  23  [E]  Parry: tight timing window plus a reward (stagger or counter)
                  (Echoes of Aincrad https://en.bandainamcoent.eu/sword-art-online/news/echoes-of-aincrad-gameplay-mechanics-explained)
  [ ]  24  [E]  Dodge: invulnerability frames and stamina cost, checked on the server
  [ ]  25  [E]  Basic attack combo chain defined per weapon type
  [ ]  26  [E]  Sword skills that spend SP, so spamming leaves you open  (Echoes of Aincrad)
  [ ]  27  [E]  Skill hotbar with cooldowns
  [ ]  28  [E]  Hit feedback: hitstop, sound, VFX, damage numbers
  [ ]  29  [E]  Lock-on camera
  [ ]  30  [E]  Aggro table on enemies (who they are attacking and why)  (Echoes of Aincrad)

ARMOURY (WEAPON IS CLASS)
  [ ]  31  [E]  Equipping a weapon switches class, moveset and skill bar
                  (FF14 wiki https://ffxiv.gamerescape.com/wiki/Armoury)
  [ ]  32  [E]  Weapon swaps only allowed out of combat  (FF14 forum)
  [ ]  33  [E]  Armoury menu showing every weapon type and its level  (FF14 forum)
  [ ]  34  [E]  Keep switching free, no rare reset items
                  (AO forum, why players quit https://forum.arcaneodyssey.dev/t/for-those-who-quit-arcane-odyssey-possible-player-feedback-for-vetex/161402)
  [ ]  35  [F1] Second weapon type on Floor 1 to prove the system (spear, greatsword or similar)

ENEMIES AND AI
  [ ]  36  [E]  Mob AI states: idle, patrol, aggro, chase, attack, leash back and reset
  [ ]  37  [E]  Spawn zones with population caps and respawn timers
                  (Aincrad reference https://otakumode.com/otapedia/anime/sword_art_online/aincrad_sao)
  [ ]  38  [E]  Telegraph system (wind-ups and ground markers) shared by mobs and bosses
  [ ]  39  [E]  Nameplates with level and HP bar
  [ ]  40  [F1] Floor 1 mob roster, each type with its own mechanic instead of just more HP
                  (AO forum, why players quit)
  [ ]  41  [F1] Floor 1 field boss (mini boss out in the world)

BOSSES
  [ ]  42  [E]  Boss framework: phases by HP %, multiple HP bars, attack patterns read from config
  [ ]  43  [E]  Boss arena with entry door and full reset on wipe
  [ ]  44  [E]  Boss instances for parties using ReserveServer and TeleportPartyAsync
                  (DevForum https://devforum.roblox.com/t/teleporting-a-party-using-teleportpartyasync-not-sure-how-to-teleport-them-to-a-reserved-server/2224900)
  [ ]  45  [E]  Last Attack bonus drop for the killing blow
                  (Integral Factor https://en.wikipedia.org/wiki/Sword_Art_Online:_Integral_Factor)
  [ ]  46  [E]  Loot for everyone who contributed to the fight
  [ ]  47  [E]  Clearing a floor boss unlocks the next floor for that player  (Aincrad reference)
  [ ]  48  [F1] Floor 1 boss built on the framework

ITEMS, LOOT AND GEAR
  [ ]  49  [E]  Item database with rarity tiers
  [ ]  50  [E]  Unique ID on every item instance, for trade logs, dupe checks and rollbacks
  [ ]  51  [E]  Loot tables per mob and boss, rolled on the server, loot per player
                  (Aincrad reference)
  [ ]  52  [E]  Inventory with slots, stacking and sorting
  [ ]  53  [E]  Equipment slots: weapon, armor pieces, accessory
  [ ]  54  [E]  Gear stats and item level
  [ ]  55  [E]  Weapon and armor upgrades using materials
  [ ]  56  [E]  Consumables such as potions, with a shared cooldown
  [ ]  57  [F1] Floor 1 loot set: weapons, armor, materials

ECONOMY
  [ ]  58  [E]  Currency dropped by mobs and bosses  (Aincrad reference)
  [ ]  59  [E]  NPC shop to buy and sell
  [ ]  60  [E]  Crafting or smithing from mob materials
  [ ]  61  [E]  Player trading with a two-sided confirm, only after session locking works
                  (ProfileStore)
  [ ]  62  [E]  Currency sinks so money keeps value (upgrades, repairs, fees)

WORLD AND TRAVEL
  [ ]  63  [E]  Town hub with shops, NPCs and a teleport gate  (Aincrad reference)
  [ ]  64  [E]  Teleport gate menu listing only floors you cleared  (Aincrad reference)
  [ ]  65  [E]  Safe zone in town (no damage)
  [ ]  66  [E]  Map, minimap and waypoints
  [ ]  67  [E]  StreamingEnabled tuned so large floors load on low-end devices
  [ ]  68  [F1] Floor 1 map: town, fields with level bands, dungeon leading to the boss room

MOUNTS
  [ ]  69  [E]  Mount framework: summon, dismiss, ride, move speed from config
                  (DevForum https://devforum.roblox.com/t/best-way-to-create-a-mount-system/2507288)
  [ ]  70  [E]  Mounts only usable out of combat, and taking a hit dismounts you
  [ ]  71  [E]  Server checks mount speed so it can't be used as a speed hack
                  (Roblox server authority https://create.roblox.com/docs/projects/server-authority)
  [ ]  72  [E]  Mount animations and camera while riding
  [ ]  73  [E]  Mounts owned saved in player data
  [ ]  74  [E]  Mount collection menu
  [ ]  75  [F1] First mount earned from a Floor 1 quest

QUESTS AND NPCS
  [ ]  76  [E]  Quest framework: kill, collect, talk and boss objectives from config
  [ ]  77  [E]  Dialogue system for NPCs
  [ ]  78  [E]  Quest tracker in the HUD
  [ ]  79  [E]  Repeatable quests or bounties for replay value  (AO forum, why players quit)
  [ ]  80  [F1] Floor 1 main quest chain ending at the boss
  [ ]  81  [F1] Floor 1 side quests
  [ ]  82  [E]  Titles and achievements triggered by quest and boss events

SOCIAL
  [ ]  83  [E]  Party system: invite, shared XP, party HP frames
                  (Roblox discovery docs https://create.roblox.com/docs/discovery)
  [ ]  84  [E]  Switch mechanic to hand aggro to a partner  (Echoes of Aincrad)
  [ ]  85  [E]  Join a friend's server  (Roblox discovery docs)
  [ ]  86  [E]  Chat and player list showing weapon and level
  [ ]  87  [E]  Guilds
  [ ]  88  [E]  Opt-in duels (PvP)

UI AND CONTROLS
  [ ]  89  [E]  HUD: HP, SP, EXP, skill bar, party frames, target frame
  [ ]  90  [E]  Menus: inventory, equipment, armoury, quests, map, mounts, settings
  [ ]  91  [E]  Inventory HUD
  [ ]  92  [E]  Settings HUD
  [ ]  93  [E]  Mobile and controller controls
  [ ]  94  [E]  Settings: keybinds, camera, audio
  [ ]  95  [F1] Floor 1 tutorial that teaches attack, dodge, parry and skills

ANTI-EXPLOIT AND ADMIN
  [ ]  96  [E]  Server checks for movement speed and teleporting  (Roblox server authority)
  [ ]  97  [E]  Admin commands: give item, spawn boss, kick, ban
  [ ]  98  [E]  Logs for drops, trades and currency changes

FLOOR 1 FINISH
  [ ]  99  [F1] Performance budget for mobs and effects, tested on a phone
                  (AO forum, performance https://forum.arcaneodyssey.dev/t/what-makes-arcane-odyssey-dead/123940?page=2)
  [ ] 100  [F1] Audio and VFX pass across the floor
  [ ] 101  [F1] Full loop playtest with friends: town, fields, dungeon, boss, next floor unlocks

NEW FLOOR CHECKLIST  (repeat for every floor after Floor 1)
  Map       New biome: town, teleport gate, fields, dungeon and boss room, using the floor template
  Enemies   New mob roster in the Mobs config, each type with its own mechanic
  Enemies   New field boss
  Boss      New floor boss in the Bosses config, with its own phases
  Loot      New loot tables, weapon and armor set, and materials
  Quests    Main quest chain and side quests in the Quests config
  Mechanic  One new mechanic for this floor (optional)
  Mounts    New mount as a reward (optional)
  Balance   Level band, XP values and drop rates checked against the previous floor
  Test      Full loop playtest of the new floor
]]

return {}
