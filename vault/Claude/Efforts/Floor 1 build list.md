---
type: effort
status: active
created: 2026-09-29
author: claude
source: Google Sheet (source of truth)
tags:
  - effort
  - roadmap
---

Up: [[Claude]] · Combat work: [[Core fighting plan]]

Snapshot of the Google Sheet "Floor 1 MMORPG Build List", copied 2026-09-29. The sheet is the source of truth; tick boxes there.
Sheet: https://docs.google.com/spreadsheets/d/1YRKda26_jc5A7cRp01cDvw5nhTO0E9NhXP_DCsVIH1U/edit?gid=921768821#gid=921768821

Scope key: Engine = built once and reused by every floor. Floor 1 = content specific to Floor 1.

## Progress at snapshot

6 of 101 done (6%). Engine 5 of 87, Floor 1 content 1 of 14. Only "Already built" is complete; every other area is at 0.

## Floor 1 build

| Done | # | Area | Task | Scope | Source |
| --- | --- | --- | --- | --- | --- |
| x | 1 | Already built | Running animation and run script | Engine | |
| x | 2 | Already built | Health bar and EXP bar UI | Engine | |
| x | 3 | Already built | First sword model | Floor 1 | |
| x | 4 | Already built | Basic sword attack | Engine | |
| x | 5 | Already built | Dodge, first pass | Engine | |
| x | 6 | Already built | Parry, first pass | Engine | |
| | 7 | Core architecture | Player saves on ProfileStore with session locking and autosave | Engine | [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) |
| | 8 | Core architecture | Save schema: per-weapon levels and XP, inventory, equipped gear, currency, floors cleared, quests, mounts owned, settings, plus a schema version number for migrations | Engine | [FF14 forum](https://forum.square-enix.com/ffxiv/threads/209629) |
| | 9 | Core architecture | Save migration code that upgrades old saves when new fields are added | Engine | Our call |
| | 10 | Core architecture | Config ModuleScripts for Weapons, Skills, Mobs, Bosses, Items, LootTables, Quests, Mounts and Floors, so a new floor is mostly new data | Engine | Our call |
| | 11 | Core architecture | Floor template: every floor uses the same folder layout (Town, Gate, MobZones, Dungeon, BossArena, Spawns) | Engine | Our call |
| | 12 | Core architecture | Server-authoritative combat: client plays the swing instantly, server validates and deals damage | Engine | [Combat guide](https://kitsblox.com/blog/how-to-make-combat-system-roblox) |
| | 13 | Core architecture | Validate every RemoteEvent (range, cooldown, weapon state) and rate limit them | Engine | [Combat guide](https://kitsblox.com/blog/how-to-make-combat-system-roblox) |
| | 14 | Core architecture | Shared damage and stat formula module used by players, mobs and bosses | Engine | Our call |
| | 15 | Core architecture | Status effect framework (buffs, debuffs, damage over time, stun, slow) | Engine | Our call |
| | 16 | Core architecture | Combat state flag (in combat or not) that swaps, mounts and regen all read | Engine | [FF14 forum](https://forum.square-enix.com/ffxiv/threads/209629) |
| | 17 | Character and stats | Stats: HP, SP, stamina, attack, defense, crit, derived from weapon level and gear | Engine | Our call |
| | 18 | Character and stats | XP curve per weapon type, stored in config | Engine | [FF14 forum](https://forum.square-enix.com/ffxiv/threads/209629) |
| | 19 | Character and stats | HP and SP regen out of combat | Engine | Our call |
| | 20 | Character and stats | Death, respawn at town, and a decided death penalty | Engine | Our call |
| | 21 | Character and stats | Character appearance (hair, face, outfit) saved separately from gear stats, so a glamour system can come later | Engine | Our call |
| | 22 | Combat | Server hitboxes: GetPartBoundsInBox for swings, raycasts for thrusts | Engine | [Combat guide](https://kitsblox.com/blog/how-to-make-combat-system-roblox) |
| | 23 | Combat | Parry: tight timing window plus a reward (stagger or counter) | Engine | [Echoes of Aincrad](https://en.bandainamcoent.eu/sword-art-online/news/echoes-of-aincrad-gameplay-mechanics-explained) |
| | 24 | Combat | Dodge: invulnerability frames and stamina cost, checked on the server | Engine | Our call |
| | 25 | Combat | Basic attack combo chain defined per weapon type | Engine | Our call |
| | 26 | Combat | Sword skills that spend SP, so spamming leaves you open | Engine | [Echoes of Aincrad](https://en.bandainamcoent.eu/sword-art-online/news/echoes-of-aincrad-gameplay-mechanics-explained) |
| | 27 | Combat | Skill hotbar with cooldowns | Engine | Our call |
| | 28 | Combat | Hit feedback: hitstop, sound, VFX, damage numbers | Engine | Our call |
| | 29 | Combat | Lock-on camera | Engine | Our call |
| | 30 | Combat | Aggro table on enemies (who they are attacking and why) | Engine | [Echoes of Aincrad](https://en.bandainamcoent.eu/sword-art-online/news/echoes-of-aincrad-gameplay-mechanics-explained) |
| | 31 | Armoury (weapon is class) | Equipping a weapon switches class, moveset and skill bar | Engine | [FF14 wiki](https://ffxiv.gamerescape.com/wiki/Armoury) |
| | 32 | Armoury (weapon is class) | Weapon swaps only allowed out of combat | Engine | [FF14 forum](https://forum.square-enix.com/ffxiv/threads/209629) |
| | 33 | Armoury (weapon is class) | Armoury menu showing every weapon type and its level | Engine | [FF14 forum](https://forum.square-enix.com/ffxiv/threads/209629) |
| | 34 | Armoury (weapon is class) | Keep switching free, no rare reset items | Engine | [AO forum, why players quit](https://forum.arcaneodyssey.dev/t/for-those-who-quit-arcane-odyssey-possible-player-feedback-for-vetex/161402) |
| | 35 | Armoury (weapon is class) | Second weapon type on Floor 1 to prove the system (spear, greatsword or similar) | Floor 1 | Our call |
| | 36 | Enemies and AI | Mob AI states: idle, patrol, aggro, chase, attack, leash back and reset | Engine | Our call |
| | 37 | Enemies and AI | Spawn zones with population caps and respawn timers | Engine | [Aincrad reference](https://otakumode.com/otapedia/anime/sword_art_online/aincrad_sao) |
| | 38 | Enemies and AI | Telegraph system (wind-ups and ground markers) shared by mobs and bosses | Engine | Our call |
| | 39 | Enemies and AI | Nameplates with level and HP bar | Engine | Our call |
| | 40 | Enemies and AI | Floor 1 mob roster, each type with its own mechanic instead of just more HP | Floor 1 | [AO forum, why players quit](https://forum.arcaneodyssey.dev/t/for-those-who-quit-arcane-odyssey-possible-player-feedback-for-vetex/161402) |
| | 41 | Enemies and AI | Floor 1 field boss (mini boss out in the world) | Floor 1 | Our call |
| | 42 | Bosses | Boss framework: phases by HP %, multiple HP bars, attack patterns read from config | Engine | Our call |
| | 43 | Bosses | Boss arena with entry door and full reset on wipe | Engine | Our call |
| | 44 | Bosses | Boss instances for parties using ReserveServer and TeleportPartyAsync | Engine | [DevForum, party teleport](https://devforum.roblox.com/t/teleporting-a-party-using-teleportpartyasync-not-sure-how-to-teleport-them-to-a-reserved-server/2224900) |
| | 45 | Bosses | Last Attack bonus drop for the killing blow | Engine | [Integral Factor (Wikipedia)](https://en.wikipedia.org/wiki/Sword_Art_Online:_Integral_Factor) |
| | 46 | Bosses | Loot for everyone who contributed to the fight | Engine | Our call |
| | 47 | Bosses | Clearing a floor boss unlocks the next floor for that player | Engine | [Aincrad reference](https://otakumode.com/otapedia/anime/sword_art_online/aincrad_sao) |
| | 48 | Bosses | Floor 1 boss built on the framework | Floor 1 | Our call |
| | 49 | Items, loot and gear | Item database with rarity tiers | Engine | Our call |
| | 50 | Items, loot and gear | Unique ID on every item instance, for trade logs, dupe checks and rollbacks | Engine | Our call |
| | 51 | Items, loot and gear | Loot tables per mob and boss, rolled on the server, loot per player | Engine | [Aincrad reference](https://otakumode.com/otapedia/anime/sword_art_online/aincrad_sao) |
| | 52 | Items, loot and gear | Inventory with slots, stacking and sorting | Engine | Our call |
| | 53 | Items, loot and gear | Equipment slots: weapon, armor pieces, accessory | Engine | Our call |
| | 54 | Items, loot and gear | Gear stats and item level | Engine | Our call |
| | 55 | Items, loot and gear | Weapon and armor upgrades using materials | Engine | Our call |
| | 56 | Items, loot and gear | Consumables such as potions, with a shared cooldown | Engine | Our call |
| | 57 | Items, loot and gear | Floor 1 loot set: weapons, armor, materials | Floor 1 | Our call |
| | 58 | Economy | Currency dropped by mobs and bosses | Engine | [Aincrad reference](https://otakumode.com/otapedia/anime/sword_art_online/aincrad_sao) |
| | 59 | Economy | NPC shop to buy and sell | Engine | Our call |
| | 60 | Economy | Crafting or smithing from mob materials | Engine | Our call |
| | 61 | Economy | Player trading with a two-sided confirm, only after session locking works | Engine | [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) |
| | 62 | Economy | Currency sinks so money keeps value (upgrades, repairs, fees) | Engine | Our call |
| | 63 | World and travel | Town hub with shops, NPCs and a teleport gate | Engine | [Aincrad reference](https://otakumode.com/otapedia/anime/sword_art_online/aincrad_sao) |
| | 64 | World and travel | Teleport gate menu listing only floors you cleared | Engine | [Aincrad reference](https://otakumode.com/otapedia/anime/sword_art_online/aincrad_sao) |
| | 65 | World and travel | Safe zone in town (no damage) | Engine | Our call |
| | 66 | World and travel | Map, minimap and waypoints | Engine | Our call |
| | 67 | World and travel | StreamingEnabled tuned so large floors load on low-end devices | Engine | Our call |
| | 68 | World and travel | Floor 1 map: town, fields with level bands, dungeon leading to the boss room | Floor 1 | Our call |
| | 69 | Mounts | Mount framework: summon, dismiss, ride, move speed from config | Engine | [DevForum, mount system](https://devforum.roblox.com/t/best-way-to-create-a-mount-system/2507288) |
| | 70 | Mounts | Mounts only usable out of combat, and taking a hit dismounts you | Engine | Our call |
| | 71 | Mounts | Server checks mount speed so it can't be used as a speed hack | Engine | [Roblox server authority](https://create.roblox.com/docs/projects/server-authority) |
| | 72 | Mounts | Mount animations and camera while riding | Engine | Our call |
| | 73 | Mounts | Mounts owned saved in player data | Engine | Our call |
| | 74 | Mounts | Mount collection menu | Engine | Our call |
| | 75 | Mounts | First mount earned from a Floor 1 quest | Floor 1 | Our call |
| | 76 | Quests and NPCs | Quest framework: kill, collect, talk and boss objectives from config | Engine | Our call |
| | 77 | Quests and NPCs | Dialogue system for NPCs | Engine | Our call |
| | 78 | Quests and NPCs | Quest tracker in the HUD | Engine | Our call |
| | 79 | Quests and NPCs | Repeatable quests or bounties for replay value | Engine | [AO forum, why players quit](https://forum.arcaneodyssey.dev/t/for-those-who-quit-arcane-odyssey-possible-player-feedback-for-vetex/161402) |
| | 80 | Quests and NPCs | Floor 1 main quest chain ending at the boss | Floor 1 | Our call |
| | 81 | Quests and NPCs | Floor 1 side quests | Floor 1 | Our call |
| | 82 | Quests and NPCs | Titles and achievements triggered by quest and boss events | Engine | Our call |
| | 83 | Social | Party system: invite, shared XP, party HP frames | Engine | [Roblox discovery docs](https://create.roblox.com/docs/discovery) |
| | 84 | Social | Switch mechanic to hand aggro to a partner | Engine | [Echoes of Aincrad](https://en.bandainamcoent.eu/sword-art-online/news/echoes-of-aincrad-gameplay-mechanics-explained) |
| | 85 | Social | Join a friend's server | Engine | [Roblox discovery docs](https://create.roblox.com/docs/discovery) |
| | 86 | Social | Chat and player list showing weapon and level | Engine | Our call |
| | 87 | Social | Guilds | Engine | Our call |
| | 88 | Social | Opt-in duels (PvP) | Engine | Our call |
| | 89 | UI and controls | HUD: HP, SP, EXP, skill bar, party frames, target frame | Engine | Our call |
| | 90 | UI and controls | Menus: inventory, equipment, armoury, quests, map, mounts, settings | Engine | Our call |
| | 91 | UI and controls | Inventory HUD | Engine | Our call |
| | 92 | UI and controls | Settings HUD | Engine | Our call |
| | 93 | UI and controls | Mobile and controller controls | Engine | Our call |
| | 94 | UI and controls | Settings: keybinds, camera, audio | Engine | Our call |
| | 95 | UI and controls | Floor 1 tutorial that teaches attack, dodge, parry and skills | Floor 1 | Our call |
| | 96 | Anti-exploit and admin | Server checks for movement speed and teleporting | Engine | [Roblox server authority](https://create.roblox.com/docs/projects/server-authority) |
| | 97 | Anti-exploit and admin | Admin commands: give item, spawn boss, kick, ban | Engine | Our call |
| | 98 | Anti-exploit and admin | Logs for drops, trades and currency changes | Engine | Our call |
| | 99 | Floor 1 finish | Performance budget for mobs and effects, tested on a phone | Floor 1 | [AO forum, performance](https://forum.arcaneodyssey.dev/t/what-makes-arcane-odyssey-dead/123940?page=2) |
| | 100 | Floor 1 finish | Audio and VFX pass across the floor | Floor 1 | Our call |
| | 101 | Floor 1 finish | Full loop playtest with friends: town, fields, dungeon, boss, next floor unlocks | Floor 1 | Our call |

## New floor checklist

Repeat for every floor after Floor 1. All sourced as "Our call".

| Area | Task |
| --- | --- |
| Map | New biome: town, teleport gate, fields, dungeon and boss room, using the floor template |
| Enemies | New mob roster in the Mobs config, each type with its own mechanic |
| Enemies | New field boss |
| Boss | New floor boss in the Bosses config, with its own phases |
| Loot | New loot tables, weapon and armor set, and materials |
| Quests | Main quest chain and side quests in the Quests config |
| Mechanic | One new mechanic for this floor (optional) |
| Mounts | New mount as a reward (optional) |
| Balance | Level band, XP values and drop rates checked against the previous floor |
| Test | Full loop playtest of the new floor |
