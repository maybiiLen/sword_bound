--[[
================================================================================
  COMBAT  (owner: Henry)
================================================================================
Action combat: click to swing, chain a 3-hit combo, hits detected on the attacking
client for instant feel and re-validated on the server, which is the only place damage
and XP happen.

FLOW
  InputController -> WeaponController (combo state machine) -> WeaponBehaviors.Sword
    -> plays animation, opens hit window -> Hitbox detects -> HitRemote
  Server: CombatService validates -> DamageService (level scaling, XPReward on kill)
    -> ProgressionService -> PlayerDataService (saved)

WHERE THINGS ARE
  ReplicatedStorage.Combat
    CombatConfig          keybinds + global tuning (tolerances, attribute names, PvP toggle)
    Types                 Luau types for definitions
    WeaponRegistry        loads + validates Weapons/*
    Weapons/StarterSword  a weapon definition (pure data)
    WeaponBehaviors/      BaseWeapon (shared logic) + one subclass per weapon TYPE (Sword)
    Hitbox                swept melee hitbox class
    Effects               client cosmetic effects (sounds, trail, sparks)
    Remotes/              EquipRemote, AttackRemote, HitRemote, EffectRemote, LevelUpRemote
    Assets/WeaponModels   WeaponTemplate (copy me), StarterSword
    Assets/VFX            HitSpark;  Assets/Sounds: Swing, Lunge, Draw, Sheath, Hit
  ServerScriptService.Combat
    CombatServer (Script, bootstrap), WeaponService, CombatService, DamageService,
    ProgressionService, DummyService
  StarterPlayerScripts.Combat
    CombatClient (LocalScript, bootstrap), InputController, WeaponController, ClassHudController

CONTROLS  (CombatConfig)
  Attack: Left mouse / R2 (attacking while sheathed draws the weapon)
  Draw / sheath: E / Y

ADDING A NEW SWORD  (no code)
  1. Model: duplicate Assets/WeaponModels/WeaponTemplate, rename it, build your mesh/parts.
  2. Definition: duplicate Weapons/StarterSword, rename it to the SAME name as its Id.
     Set Model = your model name, tweak Damage / Reach / Combo. Keep Class = "Sword".
  3. Test: EquipRemote:FireServer("Equip", "<Id>") from a client, or set the player's
     data.EquippedWeapon. WeaponRegistry warns in Output if anything is misnamed.

MODEL CONVENTION  (Assets/WeaponModels/*)
  Model with PrimaryPart "Handle". All parts welded to Handle (WeldConstraint), unanchored,
  CanCollide/CanQuery/CanTouch off, Massless (WeaponService enforces these too).
  Attachments inside Handle:
    Grip        where the right hand holds it. Handle +Y = blade direction.
    SheathGrip  where it sits on BodyBackAttachment when sheathed (rotation included).
    BladeBase   hitbox start (just above the guard)
    BladeTip    hitbox end (the point)
  Trail "SwingTrail" inside Handle between BladeBase and BladeTip, Enabled = false.

ATTACK DEFINITION FIELDS  (Combo = { attack1, attack2, ... })
  Animation / AnimationR6   animation ids (R6 optional)
  Duration                  seconds; animation speed is scaled to fit
  DamageMultiplier          x weapon Damage
  HitWindow = { s, e }      fractions of Duration when the blade can hit (client fallback AND
                            the server's validation window)
  UseMarkers = true         use "HitStart"/"HitEnd" keyframe markers from the animation instead
                            (keep HitWindow covering them; the server still checks it)
  Sound                     name in Assets/Sounds
  Weapon-level: Damage, Reach (studs, validated), ComboResetTime, IdleAnimation(+R6), Skills.

ADDING A WEAPON TYPE  (Bow, Spear...)
  1. Classes/Definitions/<Type>  (see Docs.Progression) - its own level track.
  2. Combat/WeaponBehaviors/<Type>: subclass BaseWeapon, override only what differs:
       local Bow = setmetatable({}, { __index = BaseWeapon }); Bow.__index = Bow
       hooks: OnDrawnChanged, OnAttackStart, OnHitWindowOpen, OnHitWindowClose, OnAttackEnd
       e.g. a Bow fires a projectile in OnHitWindowOpen and reports hits with self:ReportHit()
  3. Weapon definitions with Class = "<Type>".
  If the new type hits differently (projectiles), extend CombatService's validation for it.

COMBO STATE MACHINE  (WeaponController)
  Idle -> Attacking(step 1) -> Recovery -> Attacking(step 2) ... wraps after the last step.
  Press during the last InputBufferTime of a swing = buffered, chains instantly.
  No press within ComboResetTime of Recovery = back to Idle (step 1).

HITBOX  (Combat.Hitbox)
  Per frame during the hit window: box overlap at the blade, Blockcast from last frame's
  blade position, spherecasts along the tip + mid arcs. Each target once per swing.
  World geometry stops the sweep. Hitbox.Debug = true draws it (Studio only).

SERVER VALIDATION  (CombatService)
  Attack: weapon drawn, alive, valid next combo step, not overlapping the previous swing.
  Hit: inside HitWindow +/- HitWindowAllowance, within Reach + ReachTolerance of the
  attacker, living Humanoid, not already hit this swing, PvP rule (CombatConfig.PvPEnabled).
  Listen to CombatService.HitRejected(player, reason) when tuning.

DAMAGE  (DamageService)
  damage = Damage * DamageMultiplier * (1 + (classLevel - 1) * ClassConfig.DamageBonusPerLevel)
  Killing blow on a Model with XPReward -> ProgressionService:AddXP.
  Signals: Damaged(attacker, humanoid, amount, info), Killed(attacker, model, info).
  Other systems that deal damage (skills, traps) should call DamageService:ApplyDamage too.

ATTRIBUTES
  Character: EquippedWeapon, WeaponDrawn, CombatState ("Idle"/"Attacking"), SprintBlocked
  Mob/NPC Model: XPReward;  TrainingDummy: RespawnTime

EFFECTS
  The attacker plays effects locally; the server relays them to everyone else via EffectRemote
  ("Swing", "Hit", "Draw"). Placeholder sounds are built-in rbxasset sounds.

TRAINING DUMMY
  Workspace.TrainingDummy, tagged "TrainingDummy", 100 HP, XPReward 50, respawns (DummyService).

PLACEHOLDERS TO REPLACE
  Sword model, Roblox-owned animations (R15 522635514 slash, 522638767 lunge, 507768375 hold),
  built-in sounds. Real animations: add HitStart/HitEnd markers and set UseMarkers = true.

NOT BUILT YET (designed for)
  Bow behavior, blocking/parry, Sword Skills (definition.Skills), damage numbers, inventory
  (EquipRemote "Equip" currently accepts any registered weapon - gate it on ownership).
]]

return {}
