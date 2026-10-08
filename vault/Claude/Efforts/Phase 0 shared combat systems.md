---
type: effort
status: done
created: 2026-10-08
author: claude
tags:
  - effort
  - combat
  - design
---

Up: [[Weapons and sword skills plan]] · Daily log: [[2026-10-08]]

The first iteration of the roadmap. It builds the shared rules every new weapon class needs before any new weapon exists, so each class after this is mostly data and animations.

## Process for every iteration

1. **Research.** Facts come from the research notes, and the existing code is read before designing.
2. **Design.** This note covers scope, design, acceptance criteria and a test plan.
3. **Implement.**
   - Small, targeted edits in Studio.
   - Pure rules go in one shared module so they can be unit tested.
   - Live-place changes are synced to the repo, and the repo is checked to match the live place before each commit.
4. **Test.**
   - Unit tests (`ServerStorage.CombatDev.Tests`) for the rules.
   - Playtests in Studio for behavior, using CombatTestInput for exact timing.
   - Every acceptance criterion gets a pass or fail.
5. **Review.** A separate reviewer agent reads the diff for bugs. Findings are fixed and retested.
6. **Ship.**
   - In-game Docs and changelog.
   - A repo commit.
   - A vault daily note.
   - A Discord post.

## Baseline

On 2026-10-08 the repo was behind the live place. Teammates had added the inventory system and an ability hotbar HUD. The repo was synced first as its own commit, 9e99e4a, and now matches the live place on all 73 scripts.

Notes for later phases:
- The ability HUD already has 3 slots (keys 1, 2, 3), an ultimate bar, and attributes for cooldowns. Phase 2 (Sword Skills) should drive this HUD instead of building a new one.
- TestSword damage is now 24.

## Scope

In:
1. Damage types and counter hits
2. Armor windows (replaces the HyperArmor on/off flag)
3. Per-class multipliers (crit, guard damage)
4. Stun rules (longest stun wins, short stagger immunity)
5. PvE / PvP tables
6. Stricter marker validation, plus a unit test runner

Out (later iterations):
- **Charge levels.** Moved to the two-handed sword phase, the first weapon that needs them.
- **Uploading animations.** This needs Henry: an Open Cloud API key for the group, or manual Save to Roblox.
- **Animation Graphs.** Phase 1.

## Design

### 1. Damage types and counter hits

- Attacks get `DamageType`: "Slash", "Strike" or "Pierce".
  - Default is the weapon's `DamageType`, else "Slash".
  - Sword thrusts (RollAttack, Riposte) are Pierce.
- A **counter hit** is a hit that lands while the target's CombatState is Attacking or Charging.
  - Damage is multiplied by the type's counter bonus: Slash and Strike 1.1, Pierce 1.3.
  - The research found +30% vs enemies and +15% in PvP for Pierce counters (an Elden Ring item effect). The 1.1 base bonus is a judgment call.
- Strike multiplies guard stamina damage by 1.4 (Elden Ring Hammer Talisman, +40%). Pierce multiplies it by 0.9 (judgment).
- The Sparring Knight sets CombatState Attacking during its swings, so counter hits work on it.

### 2. Armor windows

- Attacks get `Armor = { Start?, End?, DamageTaken? }`.
  - Start and End are seconds from the attack's start. They default to the animation markers ArmorStart / ArmorEnd, else the whole action.
  - `HyperArmor = true` keeps working and is normalized to `Armor = {}`.
- While the window is active:
  - Flinches are ignored (same as HyperArmor today).
  - Damage taken is multiplied by `DamageTaken` (default CombatConfig.ArmorDamageTaken 0.9; Elden Ring PvP negation is 7.5 to 17.5% by class).
- Server: `CombatService:GetArmor(player)` returns the active armor or nil. DamageService asks through a provider function that CombatService registers, which avoids a circular require.
- Client: `WeaponController` uses the same shared rule to decide whether to ignore a flinch.

### 3. Per-class multipliers

- Weapon definitions (class defaults) get:
  - `CritMultiplier`, used for crits on staggered targets and ripostes. Sword 1.5, today's global value.
  - `GuardDamage`, multiplying the stamina a blocked hit costs the blocker. Sword 1.0.
- Later classes set their own values, for example the dagger's higher crit.

### 4. Stun rules (PoiseService)

- **Longest stun wins.** A new stagger never shortens a running one. A Riposted hold is the exception and always applies, because it must hold the target for the finisher.
- **Stagger immunity.** For `StaggerImmunityTime` after a stagger ends (PvE 1.0 s, PvP 3.0 s), poise damage and parry drains can't trigger a new full stagger. Poise stays at 1 instead, though flinches still happen. This stops parties (and later PvP) from chain-staggering a target forever.
- Sources:
  - The "longest wins, no stacking" stun handler pattern is from the DevForum.
  - BDO gives 5 s of CC immunity in PvP.
  - The PvE number is a judgment call.

### 5. PvE / PvP tables

- `CombatConfig.PvP` holds multipliers that apply only when a player hits a player:
  - Damage 1.0
  - Poise 1.0
  - CounterBonusScale 0.5 (halves the counter bonus, following Elden Ring's 30% to 15%)
  - ArmorDamageTaken 0.9
  - StaggerImmunityTime 3.0
- PvP is off today, so these are the hook for balancing later.

### 6. Validation and tests

- WeaponRegistry fails a weapon whose attack animations lack HitStart, HitEnd or CancelOpen. Every attack it ships today already has them.
- The new shared module `ReplicatedStorage.Combat.CombatRules` holds the pure math:
  - `HitDamage`
  - `CounterMultiplier`
  - `ArmorActive`
  - `GuardStaminaCost`
  - `StaggerEnd`
  - `NormalizeAttack`
- The new `ServerStorage.CombatDev.Tests` is a tiny test runner with unit tests for CombatRules, a check of every Specs marker, and a WeaponRegistry merge check. Run it from the command bar.

## Acceptance criteria

1. All unit tests pass.
2. A light that lands while the knight is mid-swing deals 1.1x (Slash). A Pierce roll attack mid-swing deals 1.3x.
3. A Strike attack against a blocking player drains 1.4x the stamina of the same Slash hit.
4. The heavy, jump attack and guard counter ignore flinches only inside their armor window, and take 0.9x damage there.
5. A target staggered twice keeps the longer stagger. For 1.0 s after a stagger ends, poise can't break again (poise stops at 1).
6. Riposte damage uses the weapon's CritMultiplier.
7. No regressions: the light combo, heavy, parry, riposte and the four contextual attacks behave as before. No console errors.
8. The repo matches the live place, and the docs and changelog are updated.

## Test plan

- **Unit:** `require(game.ServerStorage.CombatDev.Tests:Clone()).Run()` in Edit.
- **Integration (play mode):**
  - Server-side DamageService calls against a blocking or attacking dummy and the knight (as in the guard counter test).
  - CombatTestInput for timing.
  - Read attributes, health and stamina for each criterion.

## Risks

- Counter hits make trading hits stronger. Judgment-call numbers live in CombatConfig, so tune them later.
- Stagger immunity could make the riposte harder to set up in a party. It only blocks a *new* full stagger, not a riposte during the current one.

## Results (2026-10-08)

Shipped in the live place and synced to the repo (75 of 75 scripts match).

**Unit tests:** 14 of 14 pass (`ServerStorage.CombatDev.Tests`, run in the play Server VM).

**Acceptance criteria:**
1. Unit tests pass. **Pass.**
2. Counter hits. **Pass.**
   - Live: a light on the knight mid-swing dealt 26.4, and the same light while it was idle dealt 24.0 (1.100x).
   - Server-side: Pierce on an attacking target dealt 31.2 (1.3x).
3. Guard stamina by damage type. **Pass.** A blocked 20-damage hit cost 16.0 stamina for Slash, 22.4 for Strike (1.40x) and 14.4 for Pierce (0.90x).
4. Armor windows. **Pass.**
   - Live: a knight slash landed during my heavy, and the heavy kept going (state stayed Attacking until it ended at 1.45 s, no flinch).
   - Damage taken was 9.9, which is 10 x 1.1 (counter) x 0.9 (armor).
   - A light in the same spot flinched as expected.
   - The delayed chop (42 poise) still broke 40 poise and staggered me, because armor stops flinches but not poise breaks. That is intended.
5. Stun rules. **Pass.**
   - A shorter ParryRecoil during a Stagger is ignored.
   - Riposted takes over the kind without shortening the stun.
   - On the first frame after a stagger, a 999-poise hit only flinches (poise stays at 1), and a parry drain doesn't break.
   - After 1.0 s the same hit staggers.
   - A ParryRecoil gives no immunity.
6. Riposte uses the weapon's CritMultiplier. **Pass.** 90 = 24 x 2.5 x 1.5.
7. No regressions. **Pass.**
   - Checked: the light combo (24 / 25.2 / 33.6), charged heavy, roll attack, jump attack, parry (knight ParryRecoil), guard counter and riposte.
   - The console showed no errors.
   - The running attack was not retested. Its code path did not change.
8. Repo and docs. **Pass.**
   - Docs.Combat has a new section, "DAMAGE TYPES, ARMOR, STUN RULES".
   - The README changelog is updated.

**Bug found by the integration test:**
- Stagger immunity was first set in the stagger's end callback, which left a one-frame gap where a hit could re-stagger.
- Fixed by setting `immuneUntil = staggerEnd + immunity` when the stagger starts.

**Code review** (a separate reviewer agent read the full diff). Fixed:
- The client ignored a server Flinch whenever its own armor check passed. The client's clock runs about one ping ahead of the server's, so with a future ArmorStart the two could disagree and the swing would whiff silently. The client now obeys the server's Flinch, since the server already checked armor.
- The riposte did not pass the PvP flag. Later staggers could also shorten immunity, which now uses `math.max`.
- The knight kept CombatState "Attacking" if it died mid-swing. It is now reset to Idle on death.
- RiposteDefinition gained a DamageType field, and two comments wrongly said the target's CritMultiplier applies.

Kept as designed, flagged for Henry:
- **Counter and armor stack.** A Pierce counter into an armored heavy is 1.3 x 0.9 = 1.17x.
- **Counter window length.** Counter hits count during the whole action, recovery included.
- **Knight armor.** The knight has no armor damage reduction.
- **Guard breaks during immunity.** Guard breaks from stamina are not blocked by stagger immunity.
- **CancelOpen strictness.** WeaponRegistry now rejects a weapon whose attack animation lacks CancelOpen, where before it fell back to the clip length.

**Test method note:** execute_luau's Server VM loads its own copies of server modules. Calling DamageService there tests the real rules on real models, but it does not touch the game's PoiseService state. Live checks have to go through the client with CombatTestInput, reading health and attributes.
