--[[
================================================================================
  COMBAT  (owner: Henry)
================================================================================
Soulslike action combat: committed attacks with wind-up and recovery, a shared stamina
pool, rolls with i-frames, blocking, parries, poise/stagger, lock-on and an over-the-
shoulder camera. The acting client predicts everything for instant feel; the server
re-validates every action and is the only place damage, poise and XP happen.

FLOW
  InputController -> WeaponController (state machine) -> WeaponBehaviors.Sword
    -> AnimationSet plays the move, markers open the hit window -> Hitbox -> HitRemote
  MovementController (facing, roll/lunge dashes), CameraController + LockOnController
  Server: CombatService (mirrors the state machine, validates) -> DamageService:ResolveHit
    -> dodge / parry / block / hit -> PoiseService (flinch, stagger) -> ProgressionService

WHERE THINGS ARE
  ReplicatedStorage.Combat
    CombatConfig          keybinds + ALL tuning (timings, stamina, poise, camera, tolerances)
    Types                 Luau types for weapon/attack definitions
    WeaponRegistry        loads + validates Weapons/* (also checks animations exist in Specs)
    Weapons/StarterSword  a weapon definition (pure data)
    WeaponBehaviors/      BaseWeapon (marker timeline, hooks) + Sword (hitbox, trail, hit-stop)
    Hitbox                swept melee hitbox class
    Effects               client cosmetics: sounds, trail, sparks, hit-stop, camera shake
    Animations/Specs      pose + timing data for every combat animation (see ANIMATIONS)
    Animations/AnimationLibrary, AnimationSet    id lookup + per-Animator track cache
    Remotes/              EquipRemote, AttackRemote, ActionRemote, HitRemote, ReactRemote,
                          EffectRemote, LevelUpRemote
    Assets/AnimSaves      KeyframeSequences built from Specs (Studio-only playback until published)
    Assets/WeaponModels   WeaponTemplate (copy me), StarterSword
    Assets/VFX            HitSpark
    Assets/Sounds         Swing, Lunge, HeavySwing, Draw, Sheath, Hit, Block, Parry, Roll, GuardBreak
  ServerScriptService.Combat
    CombatServer (Script, bootstrap), WeaponService, CombatService, DamageService,
    StaminaService, PoiseService, ProgressionService, DummyService, SparringKnightService
  ServerStorage.CombatDev
    AnimationBuilder      turns Specs into KeyframeSequences (IK for hands/feet)
  StarterPlayerScripts.Combat
    CombatClient (LocalScript, bootstrap), InputController, WeaponController,
    MovementController, CameraController, LockOnController, KnightAnimator, ClassHudController

CONTROLS  (CombatConfig.Inputs)
  Light attack      tap Left mouse / R1          (attacking while sheathed draws the weapon)
  Heavy attack      hold Left mouse / R1, release (longer hold = more damage + poise damage)
  Block / parry     hold Right mouse / L1         (a hit within ParryWindow of raising it = parry)
  Roll              Q / B (no movement input = backstep)
  Lock-on           Middle mouse or F / R3;  flick the mouse or right stick to switch target
  Draw / sheath     E / Y
  Free cursor       hold Left Alt (while the weapon is drawn the mouse is locked to the camera)

STATE MACHINE  (WeaponController on the client, mirrored by CombatService on the server)
  Idle | Attacking | Charging | Rolling | Blocking | Staggered
  - Attacks commit: you can't cancel until the animation's CancelOpen marker. Roll and the
    next attack are both allowed from CancelOpen (roll-cancel recovery, no animation cancel
    on wind-up).
  - Input buffer: a press up to InputBufferTime before CancelOpen is remembered and fires the
    moment it opens, so combos feel responsive without mashing.
  - Light combo: Light1 -> Light2 -> Light3 (heavier finisher), resets after ComboResetTime.
  - Flinch: a hit that doesn't break poise interrupts the current action for FlinchTime,
    unless the attack has HyperArmor (heavy attacks do).
  - MoveSpeedMultiplier per state (CombatConfig.MoveSpeedMultipliers) slows you while
    attacking/charging/blocking; SprintServer multiplies WalkSpeed by it.

STAMINA  (StaminaService, shared with sprint)
  Attacks, rolls and blocking hits spend it. An action is allowed while stamina > 0 and can
  push it below the cost (souls-style); at 0 you can't act until it regenerates.
  Regen: SprintConfig.RegenRate after RegenDelay; x BlockRegenMultiplier while blocking.

DEFENSE  (DamageService:ResolveHit, in this order)
  1. IFrames      the roll's IFrameStart..IFrameEnd markers -> the hit is ignored.
  2. Parry        blocking, facing the attacker (BlockAngle), block raised <= ParryWindow ago
                  -> attacker staggered for ParryStaggerTime (crit window).
  3. Block        facing the attacker -> BlockDamageMultiplier chip damage and stamina loss of
                  Damage * BlockStaminaPerDamage * (1 - weapon BlockStability). 0 stamina ->
                  guard break (staggered GuardBreakTime).
  4. Hit          damage (x CritMultiplier if the target is staggered), then poise damage.

POISE  (PoiseService)
  Every Humanoid model has poise (players: PlayerMaxPoise; NPCs: their MaxPoise attribute,
  default 30). Attacks deal PoiseDamage; at 0 the target is staggered (StaggerTime) and takes
  crits. Poise refills after PoiseRegenDelay without taking poise damage. NPCs show a small
  poise bar + "STAGGERED" label.

ANIMATIONS  (Animations/Specs -> AnimationBuilder -> Assets/AnimSaves)
  Each animation is a list of poses (hand/foot targets + torso angles) solved with IK into a
  KeyframeSequence. Markers in Specs (HitStart, HitEnd, CancelOpen, Lunge, IFrameStart,
  IFrameEnd) are the ONLY timing source - client and server both read them.
  Rebuild after editing Specs (Studio command bar):
    require(game.ServerStorage.CombatDev.AnimationBuilder:Clone()).Build(
      require(game.ReplicatedStorage.Combat.Animations.Specs:Clone()))
  In Studio the saves are registered at runtime, so they play in playtests without uploading.
  For live servers: right-click each KeyframeSequence in Assets/AnimSaves -> Save to Roblox
  (or publish via the Animation Editor) and paste the ids into AnimationLibrary's Published
  table. Until then live players fall back to the old Roblox-owned R6/R15 ids.

CAMERA + LOCK-ON
  While the weapon is drawn: over-the-shoulder orbit camera (mouse locked, wheel zoom,
  collision, trauma-based shake, hit-stop punch). Lock-on frames the target, you strafe
  around it facing it, and the diamond marker shows the target. Breaks past LockOnBreakRange.
  Sheathed: normal Roblox camera.

ADDING A NEW SWORD  (no code)
  1. Model: duplicate Assets/WeaponModels/WeaponTemplate, rename it, build your mesh/parts.
  2. Definition: duplicate Weapons/StarterSword, rename it to the SAME name as its Id.
     Set Model = your model name, tweak Damage / Reach / Combo / Heavy / BlockStability.
     Keep Class = "Sword". Reuse the existing animation names or add new ones to Specs.
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

ATTACK DEFINITION FIELDS  (Combo = { attack1, ... }, Heavy = attack)
  Animation         name in Animations/Specs (needs HitStart/HitEnd/CancelOpen markers)
  DamageMultiplier  x weapon Damage
  StaminaCost, PoiseDamage
  Weight            "Light" | "Heavy" (hit-stop + camera shake strength)
  Lunge             forward push multiplier at the Lunge marker
  HyperArmor        true = not interrupted by flinches
  Sound             name in Assets/Sounds
  Heavy only: ChargeAnimation, FullChargeDamageBonus, FullChargePoiseBonus
  Weapon-level: Damage, Reach (studs, validated), ComboResetTime, BlockStability (0-1),
  IdleAnimation, BlockAnimation, Skills.

ADDING A WEAPON TYPE  (Bow, Spear...)
  1. Classes/Definitions/<Type>  (see Docs.Progression) - its own level track.
  2. Combat/WeaponBehaviors/<Type>: subclass BaseWeapon, override only what differs
     (hooks: OnDrawnChanged, OnAttackStart, OnHitWindowOpen, OnHitWindowClose, OnAttackEnd).
     A Bow would fire a projectile in OnHitWindowOpen and report hits with self:ReportHit().
  3. Weapon definitions with Class = "<Type>".
  If the new type hits differently (projectiles), extend CombatService's validation for it.

SERVER VALIDATION  (CombatService)
  Attack/roll/block: alive, weapon drawn (not for rolls), can act (Idle/Blocking or past the
  current action's CancelOpen - ActionTimingTolerance), valid combo step, stamina > 0.
  Heavy: charge ratio measured on the server. Hit: inside HitStart..HitEnd +/-
  HitWindowAllowance, within Reach + ReachTolerance, each target once per swing, PvP rule.
  CombatConfig.DebugValidation = true prints every rejection in Studio.

DAMAGE  (DamageService)
  :ResolveHit({ Attacker = player or NPC model, Target = humanoid, Damage, PoiseDamage,
                Position?, Class?, WeaponId? }) -> (result, damage)
  Player damage scales with class level. Killing blow on a Model with XPReward -> XP.
  Signals: Damaged, Killed, Resolved(attacker, humanoid, result, amount).
  Skills, traps and mobs should call ResolveHit so dodges/blocks/parries apply to them too.

SPARRING KNIGHT  (SparringKnightService + client KnightAnimator)
  Workspace.SparringKnight: R15 NPC tagged "SparringKnight" + "TrainingDummy". Walks up and
  throws a quick wide slash or a slow delayed overhead chop (both hyper armor) - practise
  rolling through, blocking and parrying. Attributes: XPReward, MaxPoise, AggroRange,
  RespawnTime. The server sets KnightAction = "<Animation>|<serial>", clients animate it.

ATTRIBUTES
  Character: EquippedWeapon, WeaponDrawn, CombatState, SprintBlocked, MoveSpeedMultiplier,
             IFrames, BlockStartedAt, Poise, MaxPoise, Stamina, MaxStamina
  Mob/NPC Model: XPReward, MaxPoise, Poise, CombatState;  TrainingDummy: RespawnTime

EFFECTS
  The acting client plays effects locally; the server relays them to everyone else via
  EffectRemote ("Swing", "Hit", "Block", "Parry", "Draw", "Sound"). Reactions to the player
  (Flinch, Stagger, GuardBreak, BlockImpact, ParrySuccess) come through ReactRemote.

TRAINING DUMMY
  Workspace.TrainingDummy, tagged "TrainingDummy", 100 HP, XPReward 50, respawns (DummyService).
  It's R6, so it only shows poise/stagger through its bar (no reaction animations).

PLACEHOLDERS TO REPLACE
  Code-authored animations (publish them, then polish in the Animation Editor), sword model,
  built-in sounds.

NOT BUILT YET (designed for)
  Sword Skills (definition.Skills), ripostes/backstabs, damage numbers, jump attacks,
  inventory (EquipRemote "Equip" currently accepts any registered weapon - gate it on ownership).
]]

return {}
