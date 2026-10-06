---
type: research
created: 2026-09-29
author: claude
tags:
  - research
  - combat
---

Up: [[Claude]]

Four research passes: dodge/roll design, melee attack feel, Sekiro/Elden Ring defense, and Roblox implementation. Reddit and ResetEra were blocked from the research environment in every pass, so forum sourcing comes from Steam Community, GameFAQs, Nexus Mods, Polycount, Unreal/Unity forums and the Roblox DevForum. Anything marked UNSOURCED is a judgment call, not a cited fact. Frame counts are at 30 fps (1 frame is about 0.033 s) unless noted.

## Our current values (from the code)

- Light1: hit window 0.26 to 0.38 s, chain/roll cancel at 0.5 s, back to guard at 0.72 s, lunge 12 studs/s for 0.12 s at 0.2 s. Strike keys use Linear and In easing. Attacks are Action3 priority.
- Roll: i-frames 0.05 to 0.35 s (about 9 frames), cancel at 0.5 s, dash 30 studs/s for 0.5 s, cost 18. Always turns to face the input and rolls forward, including while locked on.
- Backstep: i-frames 0.02 to 0.22 s, cancel 0.34 s, cost 10.
- Hitstop 0.06 s light, 0.11 s heavy.
- Animations are generated from Specs and only play in Studio. Live servers fall back to the old Roblox ids until the KeyframeSequences are uploaded.

## Rolls and lock-on movement

- Elden Ring has separate forward, back, left and right roll animations for each equip-load tier. They play only when locked on. Without a target the character turns and rolls forward, which is what we do now. [nexusmods.com/eldenring/articles/289]
- Our gap is lock-on. We snap to face the input direction, while Elden Ring keeps facing the target and plays a directional roll. The minimum fix is 3 new clips (back, left, right), picked from the input relative to the character, with movement along the exact input vector (diagonal handling UNSOURCED).
- Elden Ring roll i-frames are 13 to 14 frames (0.43 to 0.47 s) light/medium, 12 to 13 heavy. Recovery after i-frames: roll again 8/8/16 frames, attack 5/7/11 frames. [eldenring.wiki.fextralife.com/Dodging, eldenring.wiki.gg/wiki/Invincibility_Frames]
- Sekiro's step-dodge has 9 frames forward (0.3 s) and 6 frames side/back (0.2 s), because deflect is the main defense. [nexusmods.com/sekiro/mods/417]
- Our 0.30 s roll i-frames match Sekiro, not Elden Ring. Raise toward 0.4 s if rolling is the main defense, keep them if parry is (UNSOURCED judgment).
- Elden Ring's backstep has 0 i-frames by default. Ours has 0.2 s. [eldenring.wiki.gg/wiki/Invincibility_Frames]
- Elden Ring's input queue won't let a newer input replace a queued one, so a spammed attack eats a panic roll. Critics and modders call this a flaw. Let the newest input win. [thegemsbok.com Elden Ring critique, nexusmods.com/eldenring/mods/4714]
- We already do what Elden Ring gets criticized for not doing: dodge on press with sprint on its own key. [nexusmods.com/eldenring/mods/101]
- Lock-on walking needs at least 4 strafe directions blended by velocity in the character's local space. Back diagonals look wrong with only 4 clips. [Unreal forums, blend-space threads] Roblox's `UseStrafingAnimation` gives R15 4-way walk/run, but only if Walk and Run aren't overridden. [devforum 1999236]

## Why the sword feels stiff

Timing isn't the main cause. Elden Ring frame data (from the game's animation events, [github.com/sovietspaceship/elden-ring-frame-data-explorer-data]):

| Attack | Active | Next attack | Roll | Free move | Full anim |
|---|---|---|---|---|---|
| Straight sword 1h R1-1 | 0.43 to 0.53 s | 0.57 s | 0.80 s | 0.97 s | 2.77 s |
| Katana 1h R1-1 | 0.43 to 0.53 s | 0.53 s | 0.80 s | 1.07 s | 3.03 s |

Our hit lands earlier (0.26 s), our active length (0.12 s) matches, and our chain at 0.5 s matches. The differences are elsewhere.

1. **Everything moves together.** Polycount critique of a stiff combo: body parts moved too uniformly with little hip weight transfer. Fix by leading with the hips, then torso, arm, and sword tip last, with breakdown keys between the main poses. [polycount.com/discussion/180753]
2. **No foot step with the lunge.** We push the root about 1.4 studs with planted feet (sliding is UNSOURCED but likely). An indie devlog fixed boring swings with a real step in the animation. [sadogrestudios.itch.io devlog 640263]
3. **Snap back to guard at 0.72 s.** Elden Ring plays 2.5 to 3 s of follow-through while its cancel windows open early. The settle is where weight sells. [frame data above, gamedeveloper.com 12 principles]
4. **One cancel time for everything.** Elden Ring staggers them: next attack first, then roll, then free movement last.
5. **Curves.** A sword swing wants "a fast in but a slow out" (Jonathan Cooper). Action games want hard, committed curves, not over-eased or Linear ones. [gamedeveloper.com, anim.works] A 2020 DevForum report says Cubic In/Out plays reversed on Humanoids; unverified whether it affects CubicV2, which we use. [devforum 449068]
6. **Hitstop.** Ours (0.06 s) is below 2D fighting game values (SFV 0.13/0.20/0.25 s), but 3D games often use less (UNSOURCED). Freeze the victim longer than the attacker, shake the victim during the freeze, and keep camera and particles running. [critpoints.net hitstop, sourcegaming Sakurai column, God of War breakdown]
7. **Sekiro feels more aggressive** because an attack windup can be cancelled into guard or dodge, and a missed deflect still blocks. [GameFAQs Sekiro boards, superjumpmagazine Sekiro]

## Defense (Sekiro and Elden Ring)

- Sekiro deflect window is roughly 0.2 to 0.5 s depending on the source, and shrinks sharply if you spam guard. A missed deflect becomes a block. Posture recovers slower when the enemy's HP is low, so dealing damage speeds up the break. [sekiroshadowsdietwice.wiki.fextralife.com/Deflection, FromSoftware manual]
- Elden Ring parry active frames: 6 (small shield), 4 (dagger), 2 (most weapons), 0.07 to 0.2 s. Guard counter (heavy right after a block) gives blockers an easier offensive option that deals big stance damage. Enemy stance regenerates at 13/s after a delay. [eldenring.wiki.fextralife.com/Parry, eldenring.wiki.gg/wiki/Stance]
- Miyazaki says Sekiro's posture shaped Elden Ring's stance system. [gamesradar]
- Latency: Elden Ring PvP players say parries and backstabs become unreliable above about 250 ms. [Steam Community]

Hybrid recommendation (all numbers UNSOURCED starting points):
- Turn poise into a Sekiro-style posture bar for defense, keep stamina for offense and movement.
- A parry deals posture damage to the attacker instead of an automatic 1.6 s stagger. Only emptying posture gives the long stagger and crit window.
- Parry window about 0.2 s, shrinking to about 0.07 s if block was released in the last 0.4 s.
- Add a guard counter: heavy attack within about 0.4 s of blocking a hit, 1.5x poise damage.
- Posture regen scaled by HP percent, faster while guarding.
- Dedicated deathblow/riposte animation on posture break.

## Roblox-specific

- Animations must be uploaded before any live test. `RegisterKeyframeSequence` only works in Studio. [devforum 2481925]
- Hitstop on Roblox: `AnimationTrack:AdjustSpeed(0)` then resume, on the client that owns the character. [devforum 2133285, 3390106]
- A DevForum stiffness fix was raising the attack to Action4 above idle. [devforum 2947662]
- Roblox has no native root motion. Workarounds read the root joint's Transform each frame. [devforum 1556616, 3843087]
- Hit validation: client hitboxes with server sanity checks are the DevForum consensus. For "I dodged but still got hit", timestamp rolls and hits with `GetServerTimeNow` and check the victim's i-frame/parry state at that time (Rewind module). [devforum 988186, 4160622]
- Dashes: LinearVelocity with high horizontal force launches players up walls. Lower `MaxAxesForce` or raycast ahead and end the dash. [devforum 3159335]
- Heavier movement: `ControllerManager` + `GroundController` exposes acceleration, deceleration and turn speed, with caveats (Humanoid.Died doesn't fire, you feed the ground sensor yourself). Prototype before migrating. [create.roblox.com GroundController, devforum 3092097]
- Deepwoken lets a right-click during a roll cancel its endlag, and feints come from right-clicking in the windup. [deepwoken.fandom.com Combat_Mechanics]
