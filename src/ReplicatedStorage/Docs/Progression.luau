--[[
================================================================================
  PROGRESSION  (owner: Henry)
================================================================================
FF14-style: YOUR CLASS IS THE WEAPON TYPE YOU EQUIP. Equip a sword -> you are a Sword and
you level Sword. Switch to a bow -> you're a Bow, starting at Bow Lv 1, while your Sword
level stays saved. Every class levels 1 -> 20 on its own.

WHERE THINGS ARE
  ReplicatedStorage.Classes
    ClassConfig         MaxLevel (20), DamageBonusPerLevel, XP curve numbers, attribute names
    XPCurve             pure math: XPToNext(level), TotalXPForLevel(level), Apply(...)
    ClassRegistry       loads Definitions/*
    Definitions/Sword   { Id, DisplayName, Color }
    Definitions/Bow     defined + saved, no bow weapon yet
  ServerScriptService.Combat.ProgressionService   the only writer of levels/XP
  StarterGui.ClassGui + StarterPlayerScripts.Combat.ClassHudController   the HUD

RULES
  - Active class = Class of the equipped weapon (WeaponService sets it). No weapon = no XP.
  - XP to next level = floor(BaseXP * level ^ Exponent) = 100, 282, 519, 800 ... 8281 (19->20).
    Total to reach 20: 67,128 XP. Tune in ClassConfig.
  - Multiple level-ups from one big XP grant are handled. At level 20 XP stops (shows MAX).
  - Current effect of level: +5% weapon damage per level above 1 (DamageService).
    Sword Skills / skill tree will unlock by level via ProgressionService:GetLevel(player, class).

GRANTING XP
  Easiest: put an XPReward number attribute on any mob Model. Whoever lands the killing
  blow gets it (DamageService). Nothing else to wire.
  From code (server):
    local ProgressionService = require(ServerScriptService.Combat.ProgressionService)
    ProgressionService:AddXP(player, 120, "Quest:Intro")              -- active class
    ProgressionService:AddClassXP(player, "Bow", 50, "Tutorial")      -- specific class
  Listen: ProgressionService.LevelUp(player, classId, newLevel),
          ProgressionService.XPGained(player, classId, amount, source)

READING LEVELS  (anywhere, client or server - replicated Player attributes)
  ActiveClass    "Sword"
  ClassLevel     level of the active class
  ClassXP        XP into the current level
  ClassXPToNext  XP needed for next level (0 at max)
  Level_<Class>  e.g. Level_Sword, Level_Bow  (every class the player has)
  Client event: Combat.Remotes.LevelUpRemote.OnClientEvent(classId, newLevel)
  (The SAO_HUD EXP bar can read ClassXP / ClassXPToNext the same way ClassHudController does.)

ADDING A CLASS
  1. ModuleScript in Classes/Definitions named exactly its Id:
       return { Id = "Spear", DisplayName = "Spear", Color = Color3.fromRGB(...) }
  2. It's saved and levels automatically. To make it playable, add a weapon type
     (Docs.Combat > "Adding a weapon type").

SAVED AS  data.Classes = { Sword = { Level = 2, XP = 100 }, Bow = { Level = 1, XP = 0 } }
  (entries are created the first time a class is used or granted XP)
]]

return {}
