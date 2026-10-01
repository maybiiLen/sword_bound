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
  Light attack      press Left mouse / R1         (swings on PRESS; does nothing while sheathed, E draws)
  Heavy attack      keep holding Left mouse / R1  (still held at HeavyHoldThreshold 0.2 s = the light
                                                  turns into a heavy charge, stamina refunded; release
                                                  swings; longer hold = more damage + poise damage)
  Sprint attack     Light1 while sprinting        (lunges SprintAttackLungeMultiplier x further)
  Riposte           attack next to a red-highlighted enemy (posture- or guard-broken) = finisher
  Block / parry     hold Right mouse / L1         (a hit within ParryWindow of raising it = parry)
  Roll              Q / B (no movement input = backstep)
  Lock-on           Middle mouse or F / R3;  flick the mouse or right stick to switch target
  Draw / sheath     E / Y
  Free cursor       hold Left Alt (while the weapon is drawn the mouse is locked to the camera)

STATE MACHINE  (WeaponController on the client, mirrored by CombatService on the server)
  Idle | Attacking | Charging | Rolling | Blocking | Staggered
  - Attacks commit, then cancel windows open in order (Elden Ring style):
      CancelOpen  the next attack may start
      RollOpen    a roll/backstep may start (defaults to CancelOpen if the spec has none)
      MoveOpen    the action is over: state goes back to Idle, full move speed
    Light1/Light2 = 0.50 / 0.58 / 0.72 s, Light3 = 0.64 / 0.72 / 0.95 s. No cancel on wind-up.
  - Settle tail: after MoveOpen the attack track keeps playing its follow-through back to
    guard (cosmetic, no gameplay effect). Moving, blocking, charging, rolling or attacking
    fades it out (BaseWeapon:StopSettle), so feet never slide.
  - Input buffer: a press is remembered for InputBufferTime and fires the moment its own
    window opens (a light at CancelOpen, a roll at RollOpen). The newest press replaces an
    older one, so a panic roll is never eaten by a queued attack.
  - Light combo: Light1 -> Light2 -> Light3 (heavier finisher), resets after ComboResetTime.
  - Flinch: a hit that doesn't break poise interrupts the current action for FlinchTime,
    unless the attack has HyperArmor (heavy attacks do).
  - MoveSpeedMultiplier per state (CombatConfig.MoveSpeedMultipliers) slows you while
    attacking/charging/blocking; SprintServer multiplies WalkSpeed by it.
  - Momentum (2026-09-30): attacks no longer stop you dead. The client carries your current
    velocity into the swing and eases it out over MomentumCarryTime; Attacking walk speed is
    0.3 (was 0.15). The Lunge (~2 studs at Lunge 1) steers toward the lock-on target, or the
    nearest living enemy inside LungeAssistAngle in front, within LungeAssistRange, stops
    LungeStopDistance short of it, and is cut the moment the blade connects (weapon.HitLanded).
  - Wind-up cancel: the first WindupCancelTime (0.15 s) of a light can be cancelled into block
    or roll (Sekiro style; the light's stamina is not refunded, so feints cost). Block may also
    cancel an attack's recovery once CancelOpen is reached.

STAMINA  (StaminaService, shared with sprint)
  Attacks, rolls and blocking hits spend it. An action is allowed while stamina > 0 and can
  push it below the cost (souls-style); at 0 you can't act until it regenerates.
  Regen: SprintConfig.RegenRate after RegenDelay; x BlockRegenMultiplier while blocking.

DEFENSE  (DamageService:ResolveHit, in this order)
  1. IFrames      the roll's IFrameStart..IFrameEnd markers -> the hit is ignored.
  2. Parry        blocking, facing the attacker (BlockAngle), block raised <= its parry window ago.
                  Window = ParryWindow (0.3 s), or ParryWindowSpammed (0.07 s) if block was
                  re-raised within ParrySpamLockout (0.4 s) of releasing it (anti-mash), stored
                  on the character as BlockParryWindow. Ping compensation: the block's start
                  time is the client's press time, clamped to at most MaxParryRewind (0.15 s)
                  before the server got it.
                  -> Sekiro-style posture: the attacker loses attack.PoiseDamage x
                  ParryPoiseMultiplier poise (PoiseService:DrainPoise). If that empties it: full
                  stagger (StaggerTime, crit window). Otherwise a short recoil (ParryRecoilTime
                  0.45 s, kind "ParryRecoil", poise NOT refilled) with room for one counter slash.
                  Keep deflecting and the attacker's posture breaks. Raised <= PerfectParryWindow
                  (0.08 s) ago = "PerfectParry": bigger effects + impact frame.
  3. Block        facing the attacker -> BlockDamageMultiplier chip damage and stamina loss of
                  Damage * BlockStaminaPerDamage * (1 - weapon BlockStability). 0 stamina ->
                  guard break (staggered GuardBreakTime).
  4. Hit          damage (x CritMultiplier if the target is staggered), then poise damage.

RIPOSTE  (finisher; 2026-10-01)
  When an enemy's posture breaks ("Stagger") or its guard breaks ("GuardBreak"), it gets a red
  Highlight (CombatConfig.RiposteMarkColor) for whoever is in range, and pressing attack does the
  weapon's Riposte instead of a light. A parry recoil ("ParryRecoil") is NOT open; keep deflecting
  until the posture bar empties.
  - Data: weapon definition field Riposte = { Animation, DamageMultiplier, Range, Weight, Sound }.
    Every weapon of a class inherits it from Combat.ClassDefaults[class] unless it sets its own
    (WeaponRegistry merges class defaults into each definition).
  - Server (CombatService "Riposte", target): validates target alive + StaggerKind Stagger/GuardBreak
    + PoiseService:IsStaggered + within Range + ReachTolerance + can act. Holds the target with a
    "Riposted" stagger for the whole animation (poise untouched), gives the attacker IFrames until
    MoveOpen, and deals Damage x DamageMultiplier at the HitStart marker through
    DamageService:ResolveHit (CritMultiplier applies because the target is staggered). Client
    hitbox reports during a riposte are ignored.
  - Client (WeaponController): findRiposteTarget (lock-on target first, else nearest open enemy in
    front within Range), squares up and closes to ~2.6 studs, plays the animation, impact frame +
    red flash + heavy shake at HitStart, a second burst at the "RipOut" marker.
  - Character attribute StaggerKind (PoiseService) says why something is staggered.
  - Sword riposte: Specs.Riposte (thrust, hold, rip out), 2.5 x Damage (x1.5 crit) = 45 with the
    starter sword, 1.05 s action, i-frames throughout.

POISE  (PoiseService)
  Every Humanoid model has poise (players: PlayerMaxPoise; NPCs: their MaxPoise attribute,
  default 30). Attacks deal PoiseDamage; at 0 the target is staggered (StaggerTime) and takes
  crits. Poise refills after PoiseRegenDelay without taking poise damage. NPCs show a small
  poise bar + "STAGGERED" label.

ANIMATIONS  (Animations/Specs -> AnimationBuilder -> Assets/AnimSaves)
  Each animation is a list of poses (hand/foot targets + torso angles) solved with IK into a
  KeyframeSequence. Markers in Specs (HitStart, HitEnd, CancelOpen, RollOpen, MoveOpen, Lunge,
  IFrameStart, IFrameEnd) are the ONLY timing source - client and server both read them.
  AnimationLibrary.ActionLength(name) = MoveOpen or full length (how long the action lasts for
  gameplay); AnimationLibrary.RollOpenTime(name) = RollOpen, else CancelOpen.
  Light combo recipe (2026-09-30, fixes the stiff swings): anticipation with the weight back,
  hips fire first, then torso, arm and blade; the blade crosses the front on a Linear key,
  the cut ends on Out-eased keys with an overshoot, then a slow settle to guard. The lead
  foot steps in on the Lunge (Specs.stepFeet) so the feet stay planted while the root moves.
  Light2/Light3 start from the previous swing's end pose, so chains flow. KnightSlash and
  KnightDelayedChop still use the old poses.
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
  EffectRemote ("Swing", "Hit", "Block", "Parry", "PerfectParry", "Draw", "Sound"). Reactions to
  the player (Flinch, Stagger, GuardBreak, ParryRecoil, BlockImpact, ParrySuccess(perfect)) come
  through ReactRemote.
  Parry vs block are deliberately different (Sekiro: you can tell them apart by ear):
    Parry  big gold spark burst + star flash + ForceField shockwave, two layered clangs (Parry +
           ParryRing, Pro Sound Effects library) whose pitch rises on consecutive parries,
           gold Highlight flash + short freeze on the attacker, camera shake + punch and a held
           deflect pose for the parrier. PerfectParry adds white flash, bigger burst and a
           1-2 frame high-contrast impact frame for cameras within 60 studs.
    Block  small pale spark and a dull low clunk.
  Hits and blocks get a small random pitch per play so repeats don't sound identical.

TRAINING DUMMY
  Workspace.TrainingDummy, tagged "TrainingDummy", 100 HP, XPReward 50, respawns (DummyService).
  It's R6, so it only shows poise/stagger through its bar (no reaction animations).

PLACEHOLDERS TO REPLACE
  Code-authored animations (publish them, then polish in the Animation Editor), sword model,
  built-in sounds for Swing/Lunge/Hit/Block/Roll (Parry + ParryRing now use Pro Sound Effects
  ids 9125669267 and 9125672551; audition and swap in Combat.Assets.Sounds if they don't fit).

NOT BUILT YET (designed for)
  Sword Skills (definition.Skills), ripostes/backstabs, damage numbers, jump attacks,
  inventory (EquipRemote "Equip" currently accepts any registered weapon - gate it on ownership).
]]

return {}
