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
    Assets/AnimSaves      KeyframeSequences built from Specs (published ids in AnimationLibrary.Published)
    Assets/WeaponModels   WeaponTemplate (copy me), StarterSword, TestSword
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
  Heavy attack      keep holding Left mouse / R1  (still held at HeavyHoldThreshold 0.14 s = the light
                                                  turns into a heavy charge, stamina refunded; release
                                                  swings; longer hold = more damage + poise damage)
  Running attack    attack while sprinting        (a lunging one-arm thrust that carries you up to 8 studs
                                                  into the target; weapons without RunningAttack: Light1
                                                  lunges SprintAttackLungeMultiplier x further)
  Jump attack       attack in the air             (plunges down, hyper armor)
  Roll attack       attack out of a roll/backstep (or within RollAttackWindow 0.3 s after it)
  Guard counter     attack within GuardCounterWindow 0.6 s of blocking or parrying a hit
  Riposte           attack next to a red-highlighted enemy (posture- or guard-broken) = finisher
  Block / parry     hold Right mouse / L1         (a hit within ParryWindow of raising it = parry)
  Roll              Q / B (no movement input = backstep). Locked on: you keep facing the target and
                    roll forward / back / left / right by your input (Roll, RollBack, RollLeft,
                    RollRight; the larger input component wins, the dash follows the exact input).
                    Not locked on: turn to the input and roll forward (Elden Ring does the same).
  Lock-on           Middle mouse or F / R3;  flick the mouse or right stick to switch target
  Draw / sheath     E / Y
  Free cursor       hold Left Alt (while the weapon is drawn the mouse is locked to the camera)

STATE MACHINE  (WeaponController on the client, mirrored by CombatService on the server)
  Idle | Attacking | Charging | Rolling | Blocking | Staggered
  - Attacks commit, then cancel windows open in order (Elden Ring style):
      CancelOpen  the next attack may start
      RollOpen    a roll/backstep may start (defaults to CancelOpen if the spec has none)
      MoveOpen    the action is over: state goes back to Idle, full move speed
    Light1/Light2 = 0.42 / 0.48 / 0.62 s, Light3 = 0.54 / 0.62 / 0.80 s (2026-10-08 timing pass:
    lights hit at 0.19 s, the finisher at 0.27 s; Specs.retime maps the old key times).
    No cancel on wind-up except WindupCancelTime below.
  - Settle tail: after MoveOpen the attack track keeps playing its follow-through back to
    guard (cosmetic, no gameplay effect). Moving, blocking, charging, rolling or attacking
    fades it out (BaseWeapon:StopSettle), so feet never slide.
  - Input buffer: a press is remembered for InputBufferTime and fires the moment its own
    window opens (a light at CancelOpen, a roll at RollOpen). The newest press replaces an
    older one, so a panic roll is never eaten by a queued attack.
  - Light combo: Light1 -> Light2 -> Light3 (heavier finisher that knocks non-player targets back
    Knockback = 4 studs, skipped on a staggered target so ripostes stay in range), resets after
    ComboResetTime.
  - Flinch: a hit that doesn't break poise interrupts the current action for FlinchTime,
    unless the attack's armor window is up (HyperArmor / Armor, see "Damage types, armor, stun
    rules"; heavy, jump attack and guard counter have it). The server decides and the client obeys.
  - MoveSpeedMultiplier per state (CombatConfig.MoveSpeedMultipliers) slows you while
    attacking/charging/blocking; SprintServer multiplies WalkSpeed by it.
  - Momentum (2026-09-30): attacks no longer stop you dead. The client carries your current
    velocity into the swing and eases it out over MomentumCarryTime; Attacking walk speed is
    0.3 (was 0.15).
  - Attack aim and warp (2026-10-08, vault "Sword combat feel revision"):
      Target    locked on: the lock target if within LockedWarpRange (16), else none. Not locked:
                the best living enemy (players only with PvP on) inside LungeAssistAngle (60 deg)
                of the aim direction (move input, else camera look) within SoftTargetRange (10;
                longer for long-warp attacks), angle first, distance second.
      Turning   toward that target at SoftTurnRate.Windup (720 deg/s) until HitStart, Active
                (180 deg/s) until HitEnd, then committed (MovementController:SetFacingTarget).
      Warp      on the Lunge marker: travel = distance - WarpStopDistance (3.5), capped at the
                attack's Warp (lights 4, finisher 3, running 8, heavy 3) and scaled down to
                WarpSideScale toward the edge of the cone (CombatRules.WarpDistance). Re-aimed every
                frame until HitStart, stops short of walls, cut when the blade connects.
                No target: the old fixed step (Lunge x ~2 studs) so whiffs still move you.
      Server    a hit beyond Reach + ReachTolerance but inside the attack's warp is measured again
                WarpReachRecheck (0.25 s) later, after the warp replicated, and must then be in reach.
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
                  Damage * BlockStaminaPerDamage * (1 - weapon BlockStability) x damage type
                  GuardStamina x attacker GuardDamage (CombatRules.GuardStaminaCost). 0 stamina ->
                  guard break (staggered GuardBreakTime).
  4. Hit          damage x level x CritMultiplier (attacker's weapon, if the target is staggered)
                  x counter bonus (target Attacking/Charging) x armor DamageTaken (target's armor
                  window up), then poise damage. Math: CombatRules.HitDamage.

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
    DamageService:ResolveHit (the weapon's CritMultiplier applies because the target is
    staggered; sword ripostes are Pierce). Client
    hitbox reports during a riposte are ignored.
  - Client (WeaponController): findRiposteTarget (lock-on target first, else nearest open enemy in
    front within Range), squares up and closes to ~2.6 studs, plays the animation, impact frame +
    red flash + heavy shake at HitStart, a second burst at the "RipOut" marker.
  - Character attribute StaggerKind (PoiseService) says why something is staggered.
  - Sword riposte: Specs.Riposte (thrust, hold, rip out), 2.5 x Damage (x1.5 crit) = 45 with the
    starter sword, 1.05 s action, i-frames throughout.

CONTEXTUAL ATTACKS  (2026-10-01)
  The attack button does one of these instead of Light1 when the situation matches. Priority:
  riposte > guard counter > jump > roll > running > normal light. Never in the middle of a light
  combo (a press during Light1/Light2 always chains the combo), and holding the press never turns
  them into a heavy.
  - Data: weapon definition fields RunningAttack, JumpAttack, RollAttack, GuardCounter, each a
    normal AttackDefinition (Animation, DamageMultiplier, StaminaCost, PoiseDamage, Weight, Lunge,
    HyperArmor, Sound) plus optional Plunge (downward studs/s on the Lunge marker). Swords get
    them from Combat.ClassDefaults.Sword; a weapon can override any field or leave one out.
  - Sword numbers (Light1 = 1.0x damage, 12 poise):
      Running attack  1.3x, 24 poise, 16 stamina, Pierce, Warp 8, lunging one-arm thrust (hits at 0.2 s)
      Jump attack     1.5x, 30 poise, 18 stamina, hyper armor, Warp 2, Plunge 55, overhead chop
      Roll attack     1.1x, 14 poise, 12 stamina, Warp 3, low rising slash out of the crouch (hits at 0.11 s)
      Guard counter   1.6x, 36 poise, 16 stamina, hyper armor, Warp 2.5, rising cut out of the guard
    Ratios follow Elden Ring's stance damage order (running < jump < guard counter) but toned
    down (players call ER's jump attack overtuned). Exact values are judgment calls.
    Research: Project doc claude/worklog.md (2026-10-01 entry).
  - Client (WeaponController.pickContextAttack): GuardCounter if the character's
    GuardCounterUntil attribute (server time) hasn't passed; JumpAttack if Humanoid.FloorMaterial
    is Air; RollAttack if in a roll/backstep or within RollAttackWindow after one; RunningAttack if
    the Sprinting attribute is on and speed >= RunningAttackMinSpeed (20; sprint 26, walk 16).
  - Server (CombatService "Context", name): weapon has the field, can act, stamina, and:
      RunningAttack  Sprinting attribute, or horizontal speed >= RunningAttackMinSpeed - 4
      JumpAttack     a ground raycast from the root finds nothing within HipHeight + half root +
                     1.2 studs, within JumpAttackGrace (0.25 s) before or after the request. The
                     server sees positions ~0.2 s late, so it waits up to the grace for the jump.
                     (Humanoid.FloorMaterial does NOT work on the server for players.)
      RollAttack     in a roll/backstep past its CancelOpen, or RollAttackWindow after it ended
      GuardCounter   GuardCounterUntil not expired. DamageService sets it to now +
                     GuardCounterWindow on a parry or a block that doesn't guard-break; using the
                     counter clears it (one counter per blocked hit).
    Hits then go through HitRemote and the normal hit window / reach checks.
  - Animations: Specs.RunningAttack, JumpAttack, RollAttack, GuardCounter.
  - New weapon type: add its own entries to ClassDefaults[class] (or per weapon).

TESTING  (Studio only)
  Players.<you>.CombatTestInput is a BindableEvent WeaponController creates in Studio. A test
  script can press inputs with exact timing: :Fire("Attack" | "Block" | "Roll", pressed).
  Studio's simulated mouse/keyboard input is too slow (100 ms to 1 s between steps) for windows
  like RollAttackWindow or the parry window.
  Pose check without play testing: ServerStorage.CombatDev.PosePreview.Show({ { "RunningAttack",
  { 0, 0.2 } } }) lays out posed R15 rigs with the sword from the AnimSaves keyframes (see its header).
  Unit tests (2026-10-08): ServerStorage.CombatDev.Tests covers CombatRules, every Specs hit
  window and the WeaponRegistry merge. In a playtest, Server command bar:
    print(require(game.ServerStorage.CombatDev.Tests).Run())
  Run it after changing CombatRules, CombatConfig damage numbers, Specs markers or ClassDefaults.
  Note: the MCP/command-bar Server VM gets its own copies of server modules, so calling
  DamageService there does not touch the game's PoiseService/CombatService state.

POISE  (PoiseService)
  Every Humanoid model has poise (players: PlayerMaxPoise; NPCs: their MaxPoise attribute,
  default 30). Attacks deal PoiseDamage; at 0 the target is staggered (StaggerTime) and takes
  crits. Poise refills after PoiseRegenDelay without taking poise damage. NPCs show a small
  poise bar + "STAGGERED" label. Armor stops flinches, not poise breaks: a big enough hit still
  staggers an armored attacker.

DAMAGE TYPES, ARMOR, STUN RULES  (2026-10-08, Combat.CombatRules + CombatConfig)
  All the math lives in ReplicatedStorage.Combat.CombatRules (pure functions, unit tested).
  - Damage types: an attack's DamageType, else the weapon's, else "Slash".
      Type     counter bonus   guard stamina   used by
      Slash    1.1x            1.0x            sword swings (class default)
      Strike   1.1x            1.4x            future maces / axe heavies
      Pierce   1.3x            0.9x            sword RollAttack and Riposte (thrusts)
    CombatConfig.DamageTypes. Strike +40% guard damage follows Elden Ring's Hammer Talisman; Pierce
    1.3 counters follow ER's +30% vs enemies; the 1.1 base and Pierce 0.9 are judgment calls.
  - Counter hit: the target's CombatState is Attacking or Charging when the hit lands (whole
    action, recovery included). Works on players and the Sparring Knight (it sets CombatState
    Attacking during swings). The ResolveHit info table carries Counter = true.
  - Armor: attack field Armor = { Start?, End?, DamageTaken? } (seconds from the attack's start).
    Start/End default to the animation's ArmorStart/ArmorEnd markers, else the whole action.
    HyperArmor = true is the same as Armor = {}. While the window is up the attack ignores
    flinches and its owner takes x DamageTaken (default CombatConfig.ArmorDamageTaken 0.9).
    Counter and armor both apply: a Slash hit on a player mid-heavy = 1.1 x 0.9 = 0.99x.
    Server: CombatService:GetArmor(player) (DamageService gets it through SetArmorProvider).
  - Weapon class stats (ClassDefaults): CritMultiplier (Sword 1.5) on staggered targets and
    ripostes, GuardDamage (Sword 1.0) x the stamina a blocker loses. CombatConfig.CritMultiplier is
    only the fallback.
  - Longest stun wins: a new stagger never shortens a running one; a shorter one is ignored.
    "Riposted" always takes over the kind (to hold the target) but never shortens either.
  - Stagger immunity: after a full stagger (Stagger, GuardBreak, Riposted) ends, poise can't break
    again for StaggerImmunityTime (PvE 1.0 s, PvP 3.0 s). Poise stops at 1 and the hit flinches
    instead; parry drains give a ParryRecoil instead. Parry recoils give no immunity. Guard breaks
    from stamina are NOT blocked by immunity (open question).
  - PvP (a player hitting a player): CombatConfig.PvP multiplies damage, poise damage, halves the
    counter bonus (CounterBonusScale 0.5), sets armor DamageTaken and the immunity time. PvP is off
    today; these are the balancing hooks.
  - WeaponRegistry now rejects a weapon whose attack animations (combo, heavy, riposte,
    contextual) lack HitStart < HitEnd <= CancelOpen.

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
  In Studio the saves are registered at runtime and win over Published, so playtests always
  show the latest specs. For live servers (2026-10-09: all 24 published to the group):
    require(game.ServerStorage.CombatDev.AnimationBuilder:Clone()).Publish()
  uploads every AnimSaves sequence under the game's group with CreateAssetAsync and rewrites
  AnimationLibrary.Published. Re-publish after Specs changes are final, or live servers keep
  the old motion (timing comes from Specs either way). Publish({ "Light1" }) does just one.

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
  3. Test: EquipRemote:FireServer("Equip", "<Id>") from a client (the player must own it:
     InventoryService:GrantWeapon, or add it to DataTemplate.Inventory.Weapons), or set the player's
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
  HyperArmor        true = armor for the whole action (same as Armor = {})
  Armor             { Start?, End?, DamageTaken? } armor window (see "Damage types, armor, stun rules")
  DamageType        "Slash" | "Strike" | "Pierce" (defaults to the weapon's)
  Sound             name in Assets/Sounds
  Heavy only: ChargeAnimation, FullChargeDamageBonus, FullChargePoiseBonus
  Weapon-level: Damage, Reach (studs, validated), ComboResetTime, BlockStability (0-1),
  IdleAnimation, BlockAnimation, Skills, and class stats DamageType, CritMultiplier, GuardDamage
  (from ClassDefaults unless the weapon sets them).

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
                Position?, Class?, WeaponId?, DamageType?, CritMultiplier?, GuardDamage? })
                -> (result, damage)
  Player damage scales with class level. Killing blow on a Model with XPReward -> XP.
  Signals: Damaged, Killed, Resolved(attacker, humanoid, result, amount).
  Skills, traps and mobs should call ResolveHit so dodges/blocks/parries apply to them too.

SPARRING KNIGHT  (SparringKnightService + client KnightAnimator)
  Workspace.SparringKnight: R15 NPC tagged "SparringKnight" + "TrainingDummy". Walks up and
  throws a quick wide slash or a slow delayed overhead chop (both hyper armor) - practise
  rolling through, blocking and parrying. Attributes: XPReward, MaxPoise, AggroRange,
  RespawnTime. The server sets KnightAction = "<Animation>|<serial>", clients animate it.
  CombatState is "Attacking" during a swing, so hitting it mid-swing is a counter hit.

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
  Hit effects by damage type (2026-10-08, Combat.VFX):
    Slash   white flash, blue streaks along the swing, a crescent slash sprite
    Strike  warm cross flare, gravity sparks, dust flipbook, shockwave ring
    Pierce  flash, one long spike plus a tight cone of streaks along the thrust
    Counter any of the above recolored red + a 0.1 s white flash on the victim (counter hits
            also add CombatConfig.CounterHitStop to the attacker's hitstop)
    The attacker predicts its own (damage type from the attack, counter from the target's
    CombatState); others get EffectRemote ("Hit", position, target, damageType, counter, weight).
    Emitters are pooled per recipe in Workspace.CombatVFX (CombatConfig.VFX.PoolSize) and Emit
    counts scale with the graphics quality level. Colors and tuning: CombatConfig.VFX.
  Hitstop per weapon class and Weight: CombatConfig.ClassHitStop (falls back to HitStop).
  Swing trail look per class: CombatConfig.ClassTrails, applied by Effects.StyleTrail when the
  weapon behavior is built.
  Textures: Combat.VFXTextures (white-with-alpha images made by CombatDev TextureForge).

WEAPONFORGE  (ServerStorage.CombatDev.WeaponForge, dev only, 2026-10-08)
  Weapon models are generated from code, the same way animations come from Specs:
    MeshKit        loft, lathe, chamfered extrude, tube sweep, smoothing by angle -> EditableMesh
    Parts          blade (edge bevels + fuller), grip wraps, gems, plates, rings
    Specs          one entry per weapon: regions + materials + attachment points
    Forge          Preview / Install; Install(name, true) publishes each region as a Mesh asset
                   with AssetService:CreateAssetAsync (Studio beta "CreateAssetAsync Lua API") and
                   builds the model in Assets.WeaponModels with the MODEL CONVENTION below
    TextureForge   procedural VFX textures, PublishAll() -> ids for Combat.VFXTextures
  Use: local wf = game.ServerStorage.CombatDev.WeaponForge:Clone()
       require(wf.Forge).Install("ForgeSword", true)
  Models built so far: ForgeSword (StarterSword uses it), ForgeDagger, ForgeRapier,
  ForgeGreatsword, ForgeGreataxe (580 to 1,444 tris). Each region (Blade, Edge, Fuller, Guard,
  Grip, Trim, Gem) is its own MeshPart, so colors/materials stay editable and a Sword Skill can
  light just the Edge or Fuller. Published mesh ids are stored on the model as ForgeMeshIds.

TRAINING DUMMY
  Workspace.TrainingDummy, tagged "TrainingDummy", 100 HP, XPReward 50, respawns (DummyService).
  It's R6, so it only shows poise/stagger through its bar (no reaction animations).

PLACEHOLDERS TO REPLACE
  Code-authored animations (publish them, then polish in the Animation Editor), sword model,
  built-in sounds for Swing/Lunge/Hit/Block/Roll (Parry + ParryRing now use Pro Sound Effects
  ids 9125669267 and 9125672551; audition and swap in Combat.Assets.Sounds if they don't fit).

NOT BUILT YET (designed for)
  Sword Skills (definition.Skills), ripostes/backstabs, damage numbers, jump attacks,
  (Inventory now exists: EquipRemote "Equip" is gated on ownership, see Docs.Inventory.)
]]

return {}

