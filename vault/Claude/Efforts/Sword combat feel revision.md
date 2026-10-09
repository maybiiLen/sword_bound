---
type: effort
status: round-1-done
created: 2026-10-08
author: claude
tags:
  - effort
  - combat
  - animation
  - sword-skills
---

Up: [[Weapons and sword skills plan]] · Daily log: [[2026-10-08]]

Henry, 2026-10-08: basic sword combat doesn't feel fun yet. Is it too slow? Other games move you when you attack, lock on, and lunge you at the target, so it feels fluid. The dash attack looks the same as a normal slash. Should we use different animations? How do sword skills fit? He asked for end-to-end research including Reddit, X and Discord threads.

Four research agents ran in parallel:
- [[Roblox sword combat feel research (2026-10-08)]]: TSB, JJS, Deepwoken, Type Soul, Blox Fruits, GPO, Peroxide, Swordburst 3, Combat Warriors, Rogue Lineage, Arcane Odyssey, SAO-themed Roblox games
- [[Action game attack assist and cadence research (2026-10-08)]]: God of War, Ghost of Tsushima, THE FINALS, Unreal Motion Warping, Genshin and Elden Ring timing, DMC, ZZZ, Stellar Blade, and the SAO games' sword skill systems including Echoes of Aincrad
- [[Roblox attack movement implementation research (2026-10-08)]]: movers, soft aim, lock-on, network, hitboxes, hitstop and animation tricks on Roblox in 2026
- [[Sword moveset and animation readability research (2026-10-08)]]: how sword movesets vary arcs, how dash attacks are animated, a proposed moveset

**Source access.** Reddit was blocked in every pass (SITE_BLOCKED on fetch, HTTP 400 on a reddit-only search). No mirrors or caches were used, so there is no Reddit content. X was reachable only as search snippets, since x.com refused page fetches; the snippets had no numbers worth citing. No Discord content surfaced anywhere (only invite pages). Trello was refused by robots.txt. The Roblox DevForum, Creator Docs, wikis, Steam discussions and studio posts worked. The shared search budget ran out before TSB/JJS teardowns and some SAO game details were finished.

Spot checks by Claude: THE FINALS lunge (about 3 m before the rework, about 4.5 m average after) and Combat Warriors katana (0.59 s swing cooldown) both match their source pages.

## Short answer

The pace between hits is fine. The stiffness comes from four other things:
1. **Attacks barely move you.** A light lunge is a fixed ~2 studs (about 0.56 m), and only inside 8 studs.
2. **Attacks don't aim for you unless you lock on.** Without lock-on they face your move direction.
3. **The first hit starts slowly.** 260 ms startup.
4. **The dash attack has the same arc as Light1**, so it can't read as a different move.

On top of that, there are no Sword Skills yet, so a fight is only M1 and heavy.

## Where we stand vs the references

| | Startup to hit | Hit to next hit | Source |
|---|---|---|---|
| Sword Bound Light1/2 | 260 ms | 500 ms | code audit |
| Sword Bound Light3 | 340 ms | 640 ms (move at 950 ms) | code audit |
| Genshin Keqing N1 | 167 ms | 250 ms | https://library.keqingmains.com/characters/electro/keqing |
| Genshin Kaeya N1 | 233 ms | 450 ms | see research note |
| Elden Ring straight sword R1 | about 430 ms | 570 ms | see research note |
| Combat Warriors light weapons | n/a | 480 to 590 ms | https://wiki.combatwarriors.gg/books/katana |
| Roblox battlegrounds template | n/a | 400 ms, 4 hits | https://devforum.roblox.com/t/battleground-modulepack-ragdoll-stun-direction-cooldown/3488881 |

| Attack travel | Distance | Source |
|---|---|---|
| Sword Bound light | ~2 studs fixed, gated at 8 studs | code audit |
| Sword Bound running attack | ~4.4 studs | code audit |
| THE FINALS melee lunge | about 3 m, then about 4.5 m average after its rework | https://www.reachthefinals.com/patchnotes/s11-melee-rework |
| True Directional Movement (Skyrim mod) | 60 degree cone, turn 5x in windup, 1x mid swing, 0x after | https://github.com/ersh1/TrueDirectionalMovement/blob/master/src/Settings.h |

What the Roblox games do (details and links in the research note):
- Strings are 3 to 5 hits and end with a hit that sends the target away. TSB's 4th hit ragdolls, and Deepwoken ends on a kick.
- Running and dash attacks are always their own move. Deepwoken's running attack "strafes forward" with more range, and TSB's dash hits on arrival.
- Most Roblox games close distance with a player action (dash, step, lunge skill) and aim with shift-lock. No source describes hidden M1 magnetism in them.
- Skills chain from M1s. Peroxide skills start during an M1 windup, Deepwoken spells can replace the last hit, and TSB/JJS go 3 hits into a skill.
- Common complaints: "slow and boring M1 fest" (Swordburst 1 and 2), "floaty" hitboxes, being rooted in place.

What AAA does:
- God of War sizes the pull to the target by angle and lets the stick pick the target.
- Unreal Motion Warping bends an attack's travel so it ends at the target.
- Ghost of Tsushima has no lock-on on purpose, so players move between enemies.

## Recommendations

### 1. Make attacks travel to the target (biggest win)

Replace the fixed lunge with a distance-fitted warp, modeled on Unreal Motion Warping (https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-warping-in-unreal-engine).
- Travel = distance to target minus a stop distance, clamped to a per-attack maximum.
- Re-aim every frame from the Lunge marker to HitStart, so a moving target is still reached.
- With no target, keep a small forward step so whiffs still move.
- Starting maximums, all unsourced and to tune in playtest:
  - lights 4 studs
  - finisher 3
  - running attack 8
  - heavy 3
  - gap-closer skills 14 or more
- Stop distance about 3.5 studs, so the 7 stud blade lands mid blade.
- Scale the pull down for enemies off to the side, like God of War. For example, full warp at 0 degrees falling to 40% at 60 degrees (unsourced).
- Shorten the warp at walls with a forward cast. Stop the lunge from shoving the enemy out of the blade path with a collision group (DevForum sources in the implementation note).

### 2. Aim attacks without lock-on

Soft targeting picks the best enemy in the 60 degree cone, scored by angle then distance, within about 10 studs.
- Rotate toward it fast in the windup, slower in the active frames, and not at all after HitEnd. That is the TDM pattern with 720, 180 and 0 degrees/s (rates unsourced).
- F lock-on stays optional.
- Mobile gets stronger soft aim (unsourced).
- A review of SAO Alicization Lycoris warns its lock-on threw "attacks in the wrong direction", so never steer more than the cone allows.

### 3. Faster first hit, same rhythm

- Move Light1/2 HitStart from 0.26 to about 0.18 to 0.20 s. That is between Keqing and Kaeya and still readable.
- Keep about 500 ms between hits on a whiff. Allow the next hit about 80 ms sooner when the hit connects (unsourced), so landing hits feels fast without making air mashing faster.
- Light3 frees movement at 0.95 s today, which is long for a hit with no payoff.

### 4. A real finisher

- The last hit of the string knocks the target back 3 to 5 studs, with longer hitstop. This follows TSB and Deepwoken.
- Optional: go to 4 hits with a spinning finisher, as in the proposed moveset. This is a decision for Henry.

### 5. Different animations where the job is different

- **Running attack.** A straight thrust (DMC Stinger, SAO Rage Spike line) with a 35 to 45 degree lean, full arm extension, sprint speed carried in, about 8 studs of travel, and a stop on contact. Every reference makes it a separate move (Elden Ring guide, DMC, ZZZ, Stellar Blade).
- **Roll attack.** Becomes a low rising slash, so it stops copying the thrust.
- **Guard counter.** Becomes a shove plus a backhand.
- **Light hits.** Already change direction: forehand, then backhand, then overhead. Keep that.
- **Showcase moves.** The running thrust, finisher and sword skills deserve hand-posed keys (Moon Animator or Blender) or a much richer procedural spec, because "procedural systems are not very good at conveying intention" (anim.works, cited in the moveset note).
- Full proposed table is in [[Sword moveset and animation readability research (2026-10-08)]] (all unsourced design).

### 6. Sword Skills as the payoff

This builds on [[Sword Skill system design (2026-10-08)]]:
- SP is separate from stamina and fills from landed hits, parries and perfect rolls. Echoes of Aincrad and Lycoris fill it from hits. Filling it from defense too avoids the "spam autos to fill the bar" loop players complained about in Last Recollection.
- **A finisher slot.** A skill assigned there replaces the last M1 of the string at reduced or no SP cost, which is how Lycoris and Last Recollection bridge basic attacks into skills.
- Skill Connect with a visual plus audio cue, capped at 2 or 3. Players found Last Recollection's blue flash hard to see.
- Post-motion delay grows with skill tier and is punishable, as in canon.
- Skills hit hardest inside openings (stagger, parry, after a roll), which Echoes reviewers liked.
- Starter set (unsourced design):
  - Rage Spike: ground rush into a rising slash
  - Sonic Leap: leap into a downward slash
  - Vertical Arc: a two-hit V
  - Horizontal Square: four hits that trace a square, as a later unlock
- Skills must look different from M1s: a lit pre-motion pose, faster playback, bigger arcs, stronger hitstop. Echoes of Aincrad was criticized for lacking visual impact.

### 7. Smaller fixes

- The input buffer is 0.35 s (21 frames). Smash uses about 9 frames. Let a newer roll or block press replace a queued attack, and clear the buffer when hit.
- Attack fade-in 0.06 s is fine. DevForum advice ranges from 0.03 to 0.2 s.
- During hitstop, also pause the lunge mover so the body freezes with the pose.
- At HitStart, add one overlap check so an enemy already inside the blade isn't missed. Shapecasts skip parts that start inside them.

## Build order (proposal)

1. [x] Warp lunge plus soft targeting (MovementController, WeaponController), with server travel validation
2. [x] Light timing pass (faster first hit) and finisher knockback. Speeding up the next hit when a hit lands is not done yet.
3. [x] New running attack thrust and roll attack animations. The guard counter is unchanged.
4. [x] Buffer and hitstop. The buffer already let a newer press replace an older one, and the warp already stops on a hit, so no change was needed.
5. [ ] Sword Skill framework (SP bar, finisher slot, connect) with Rage Spike and Sonic Leap first
6. [ ] Playtest against the dummy and the knight, with a recording for Discord

Acceptance criteria:
- From 8 studs, clicking with no lock-on reaches and hits a dummy in front of you.
- The running attack is visibly a thrust that travels about 8 studs.
- The first hit lands in 200 ms or less.
- No new console errors or server rejections in the debug log.

## Decisions

Henry, 2026-10-08: treat the references as inspiration, not a checklist, and continue the build. Claude picked the open choices:
- Kept the 3-hit string. Light3 became a real finisher with knockback. A 4th hit can come later.
- Soft aim is on by default. Lock-on stays optional.
- Claude writes the showcase animations as procedural specs, checked with the new PosePreview tool.

## Results (round 1, 2026-10-08 to 10-09)

What changed in the game:
- **Attack warp.** With a target, the Lunge marker becomes a warp that ends 3.5 studs from the enemy.
  - It covers up to 4 studs on light hits, 3 on the finisher and heavy, and 8 on the running attack.
  - It re-aims every frame, stops at walls and stops when the blade connects.
  - With no target, the old 2-stud step still happens so whiffs move you.
  - Code: CombatRules.WarpDistance, MovementController:Warp, WeaponController.lunge.
- **Soft aim.** Without lock-on, an attack picks the enemy in a 60 degree cone around where you steer or where the camera looks. It turns you toward that enemy at 720 degrees/s in the windup and 180 degrees/s mid swing, then commits. Other players are ignored while PvP is off.
- **Timing.** Light1 and Light2 hit at 0.19 s (was 0.26) and chain every 0.42 s (was 0.5). The finisher hits at 0.27 s. Specs.retime maps the old keyframe times, so no pose was re-keyed by hand. The hold-to-heavy threshold moved from 0.2 s to 0.14 s so it stays before the hit.
- **Finisher.** Light3 pushes non-player enemies back 4 studs, and the heavy pushes them back 3. There is no push on a staggered enemy, so a riposte stays in range.
- **Running attack.** It is now a lunging one-arm thrust (Pierce) with a deep lean, inspired by DMC's Stinger and SAO's Rage Spike. It carries the sprint up to 8 studs and hits at 0.2 s.
- **Roll attack.** It is now a low rising slash out of the crouch, so the thrust belongs only to the running attack.
- **Server.** A hit beyond reach but inside the attack's warp allowance is checked again 0.25 s later, after the warp has replicated. A test that fired a hit from 15 studs while standing still was rejected.
- **New dev tool.** CombatDev.PosePreview lays out posed rigs from the generated keyframes, so poses can be checked in Edit mode. It works with the 2026 AnimationConstraint rigs.

![[combatfeel_running_thrust_poses.jpg]]
Running thrust keyframes 0, 0.1, 0.2, 0.36 and 0.55 s, from right to left. The first version pointed the blade down at 45 degrees during the lean. It was fixed by tilting the blade in torso space by the lean angle.

![[combatfeel_roll_attack_poses.jpg]]
Roll attack keyframes, crouch to high finish, from right to left.

### Tests (Studio play test, 2026-10-09)

- Unit tests: 19 of 19 pass. New tests cover WarpDistance, WarpOf, the timing pass, the finisher knockback and HeavyHoldThreshold being below every light HitStart.
- From 8 studs, facing the dummy: moved 4.6 studs, ended 3.4 studs away, and the hit landed.
- From 9 studs, 35 degrees off: turned to face the target, moved 4.1 studs, and the hit landed.
- From 14 studs (no target in range): only the small step, no hit.
- Running attack fired at 10.8 studs: about 7 studs of travel, and it hit for 1.3x damage.
- Knight 3-hit combo: 24, then 25.2, then 33.6 damage, and the finisher pushed the knight 4.6 studs.
- Holding M1 from idle starts a heavy charge again, and a charged heavy hit for 61.
- A faked far hit (15.8 studs) was rejected with "out of reach after warp".
- No console errors.

### Review

A reviewer agent found 6 issues, and all are fixed:
1. Holding to heavy was broken by the faster HitStart. Fixed by moving the threshold to 0.14 s and adding a test.
2. The reach widening allowed far hits while standing still. Fixed with the delayed recheck.
3. Knockback pushed staggered enemies out of riposte range. It now skips staggered targets.
4. Soft aim could pick allies while PvP is off. It now ignores other players.
5. While locked on to a far target, the warp could go toward a different enemy. Locked-on attacks now only go for the lock target.
6. If the soft target was removed mid swing, AutoRotate came back. Facing now stays committed.

### Live servers had no sword animations (fixed 2026-10-09)

AnimationLibrary.Published was empty, so the combat animations were only registered inside Studio and live R15 players had none. All 24 AnimSaves sequences are now uploaded to the group with CreateAssetAsync, using the new AnimationBuilder.Publish(), and their ids are in Published. A play test loaded the Light1, RunningAttack and RollAttack assets at the right lengths. Studio play tests still use the local sequences first, so spec edits show without publishing.

### Not done yet

- Making the next hit come sooner when a hit lands.
- A new guard counter (shove plus backhand).
- Sword Skills (Rage Spike and Sonic Leap first), which comes next.
