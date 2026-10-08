---
type: effort
status: draft
created: 2026-10-08
author: claude
tags:
  - effort
  - weapons
  - vfx
  - animation
---

Up: [[Weapons and sword skills plan]] · Daily log: [[2026-10-08]]

Henry asked for a plan for weapon models and effects, built from deep research into big anime Roblox games and fighting games, so we can copy how they design animation and hit feel. Three research agents ran in parallel:
- [[Anime Roblox combat games research (2026-10-08)]]: TSB, JJS, Deepwoken, Gakuran, The Forge, Blox Fruits, Arcane Odyssey, Swordburst 3, Combat Warriors
- [[Melee animation and slash VFX craft research (2026-10-08)]]: Guilty Gear, Street Fighter 6, souls games, Monster Hunter, SAO and HoYoverse slash VFX
- [[Weapon models and VFX pipeline research (2026-10-08)]]: Roblox mesh limits, attaching weapons, silhouettes, rarity, the VFX toolset, sourcing

Reddit was blocked in all three (SITE_BLOCKED and a proxy 403). One agent read three Reddit threads through read-only mirrors. Everything else came from the DevForum, realtimevfx, polycount, wikis, GDC material and dev interviews. None of the big Roblox studios has published its animation pipeline or hitstop numbers, so the Roblox game findings are player-facing mechanics plus other devs reverse-engineering them.

## What the research agrees on

1. **Animations play on the owning client right away. The server validates and relays.** Effects are made on each client, never on the server. We already do this.
2. **Markers are the only timing source.** Hitbox windows, VFX, sounds and hitstop all hang off GetMarkerReachedSignal. KeyframeReached is deprecated. We already do this, and Phase 0 now enforces HitStart < HitEnd <= CancelOpen.
3. **Hitstop runs per client.** AnimationTrack Speed is not replicated, so each client pauses the attacker and victim tracks itself. Heavy weapons depend on hitstop the most: Monster Hunter Wilds cut it in the beta, players complained, and Capcom put it back.
4. **Weight shows in recovery more than startup.** Dark Souls keeps startup equal within a class and adds about 6 frames of recovery to slow weapons. Player wind-ups stay short so the swing follows the button, and enemy telegraphs stay long so they can be read.
5. **Held key poses read as power.** Guilty Gear Xrd made every frame a key with no interpolation. On Roblox, `PoseEasingStyle.Constant` gives that hold. Use it on anticipation and impact poses only, and keep the swing itself smooth.
6. **Effects are short and have one clear shape.** Riot's VFX rules: one primary shape, size scales with power, effects fade fast so group fights stay readable.

## Decisions to make (Henry)

- [ ] **Weapon size.** Our swords are 5.0 to 5.4 studs long, roughly the height of the character. The research sizes a one-handed sword at about 3.6 studs and a greatsword at about 5.2 studs (real blade lengths at about 32 cm per stud on a 5.5 stud avatar, plus about 15% anime stretch). Recommendation: shrink one-handed swords toward 4 studs so the two-handed classes look bigger. That stretch number is judgment, so look at it in Studio before deciding.
- [ ] **Who builds the final meshes and VFX.** The options are commissioned artists, a teammate, or Claude building greybox and code-driven effects. The price data is old (2019 to 2021 DevForum posts: about $20 to $40 per weapon or VFX move, R$2.5k to 3.5k per animation) and 2026 hiring posts are mostly revenue share. AI meshes from Roblox's generator have messy topology, so use them for blockouts only.
- [ ] **Animation polish tool.** Blender with the free R15 FK/IK rig (April 2025) and Den_S's importer, or Moon Animator 2 (paid). Either way the markers get re-added in Studio after import.

## Weapon model spec

Shared by every class (from the pipeline research):
- A Model with MeshPart "Handle" (grip at the origin), then "Blade" or "Head".
- Attachments TrailTop and TrailBottom, LeftGrip (two-handers only) and SheathPoint. These map onto our current Grip, SheathGrip, BladeBase and BladeTip convention (Docs.Combat > MODEL CONVENTION).
- Mount with a Motor6D from RightHand to Handle so animations can move the weapon. We already weld to the hand, so check whether the current joint is animatable before changing it.
- Physics: Massless, CanCollide, CanTouch and CanQuery all off, CollisionFidelity Box. WeaponService already enforces the first four.
- Surface: SurfaceAppearance PBR plus an emissive mask on the edge. Emissives went live on Feb 12 2026, and EmissiveStrength can change at runtime, which is how a Sword Skill lights the blade.

| Class | Length (studs) | Tri budget | Textures | Grip and sheath |
|---|---|---|---|---|
| One-handed sword | 3.6 (blade 2.8) | 1,500 | Color 512, others 256 | RightHand; left hip |
| Dagger | 1.5 (blade 1.0) | 1,000 | all 256 | RightHand; back of waist |
| Rapier | 4.0 (blade 3.3, round guard) | 1,500 | Color 512, others 256 | RightHand; left hip |
| Two-handed sword | 5.2 (grip 1.0) | 2,500 | Color 512, others 256 | RightHand plus IKControl LeftHand; back |
| Two-handed axe | 4.8 haft, head 1.4 x 1.2 | 2,500 | Color 512, others 256 | RightHand plus IKControl LeftHand; back |

Hard ceiling 4,000 tris for legendary variants. The Roblox limit is 20k per mesh, and the whole default R15 body is about 10.7k. The lengths and budgets are judgment anchored to the cited numbers.

Silhouettes must read in black at gameplay distance: rapier as a thin line plus a cup guard, dagger as short, greatsword as body height with a long grip, axe as head mass at the end. (judgment)

Rarity: WoW colors (gray, white, green, blue, purple, orange) in the UI. On the model, use a SurfaceAppearance.Color tint, then a faint aura from +7 and a stronger one at +10, following Lineage 2. Keep auras subtle, because strong glows hurt parry reads.

## Feel targets per class

These are starting numbers to tune in playtests. Two agents gave different hitstop ranges, so both are shown. Our current values are HitStop Light 0.06 s, Heavy 0.11 s, Parry 0.1 s, PerfectParry 0.14 s.

| Class | Startup | Recovery | Hitstop (agent 2) | Hitstop (agent 1) |
|---|---|---|---|---|
| Dagger | 83 to 133 ms | 10 to 14 f | 50 to 83 ms | 40 to 60 ms |
| Rapier | 117 to 167 ms | 12 to 16 f | 67 to 100 ms | 60 to 80 ms |
| One-handed sword | 150 to 217 ms | 16 to 20 f | 100 to 133 ms | 60 to 80 ms |
| Two-handed sword | 267 to 367 ms | 24 to 32 f | 133 to 183 ms | 100 to 140 ms |
| Two-handed axe | 333 to 433 ms | 28 to 36 f | 167 to 200 ms | 100 to 140 ms |

- Two-handed startups stay near or above 340 ms, the Dark Souls 3 readability floor, so they can be parried on reaction.
- Cap hitstop at about 0.2 s for normal hits. The research puts the sweet spot at 0.1 to 0.2 s, with discomfort near 0.54 s. Sword Skill finishers and counters can go to about 0.3 to 0.45 s, like Guilty Gear's counter hits.
- Shorten hitstop when more than two fighters are in a fight (Sakurai: a long freeze lets a third player hit you).
- Victim shake: shake the visual (not the hitbox) side to side on the ground and up and down in the air, decaying over the freeze, while the attacker creeps forward slightly (Sakurai).

## VFX kit

All client-side, pooled (ObjectCache), fired with :Emit, and scaled to the graphics level, because :Emit skips Roblox's automatic particle reduction.

- [ ] **Swing trails per class.** Toggled on the HitStart and HitEnd markers, with Clear() at swing start, LightEmission 1 and FaceCamera on. Lifetimes: dagger 0.10 s, one-handed 0.15 s, rapier 0.08 s (thin line), two-handers 0.25 s (wide, tapering). (judgment)
- [ ] **Hit sparks per damage type.** This uses the Phase 0 damage types directly.
  - Slash: white-gold streak sparks, 8 to 12 particles.
  - Pierce: a narrow forward cone plus a small ring flipbook.
  - Strike: a dust burst, a 4x4 impact flipbook and camera shake.
- [ ] **Counter-hit flash.** New with Phase 0: a 1 to 3 frame white Highlight on the victim plus a slightly longer hitstop, so players learn that hitting someone mid-swing pays. The info table already carries Counter = true. (judgment)
- [ ] **Parry and perfect parry.** These already exist (Effects.ParryFlash). Rebuild them on the kit once the hit sparks are done.
- [ ] **Stagger.** A ring flipbook plus a looping daze particle over the head.
- [ ] **Riposte.** These already exist (red flash, impact frame). Add a heavy slash Beam arc.
- [ ] **Impact frames** (ColorCorrection to black or white for about 0.1 s) only on parries, guard breaks, finishers and Sword Skill finishers, never on normal hits. Highlights don't work on mobile, so use a Neon recolor fallback there.
- [ ] **Sword Skill grammar**, from SAO canon and the research:
  - Pre-motion: the blade lights up in the skill color the moment the stance is recognized (emissive ramp). Hold the stance with Constant easing so it is the readable startup.
  - Execution: a mesh or Beam slash matched to the swing direction, shown for 1 to 2 frames as a smear, plus the trail during active frames.
  - Impact: a one-frame impact flash, a flipbook burst and a victim Highlight.
  - Post-motion delay: the glow fades to gray. This is the punish window from SAO canon.
  - Colors: one hue per class (one-handed blue, rapier silver, dagger green, greatsword orange, axe red-orange), red reserved for unparryable, blue for reversal or parry windows. All are judgment except Vorpal Strike crimson and rapier silver (novel).

Slashes can be built two ways: a Blender slash rendered to a 4x4 sheet and played as a OneShot flipbook (cheapest), or a crescent mesh with a scrolling Texture. DevForum authors say particles are lighter than mesh slashes.

## What to copy from the Roblox games

- **Deepwoken's defensive kit** is the closest match to ours:
  - Front-only block that builds posture.
  - Posture break into a stun.
  - Parry on a cooldown that resets on success.
  - Feints with end lag.
  - Roll i-frames.
  - A 4-hit chain whose last hit pushes the target away so the chain ends itself.
- **Echoes of Aincrad's structure**:
  - One stamina bar shared by attack, dodge and guard.
  - Sword Skills as SP-costly commits that leave you open.
  - Perfect guard, parry and dodge as punish openers.
- **TSB lunges.** Animate in place, drive lunges with LinearVelocity on the owning client, and use AlignPosition against snapback. Never hand off network ownership on every hit.
- **Avoid**:
  - Ragdoll juggles, uppercut and downslam loops.
  - True stun-lock chains that only a 30 s ragdoll cancel escapes.
  - M1 trading where whoever lands last wins.
  - Unblockable M1s.
  - Long impact frames on normal hits.
  - Server-side VFX.
  - Ragdoll as the default hit reaction.

## Animation pipeline

- Locomotion and guard stance move to Animation Graphs (full release July 15 2026: blend spaces, masks for upper-body guard while walking, automatic replication). Attack clips stay as directly played tracks, because graphs have no marker-driven logic yet.
- Priorities: Action for locomotion overlays, Action2 for basic attacks, Action3 for Sword Skills, Action4 for stagger and hit reactions. (judgment)
- Attack starts use a 0 to 0.05 s fade, not the default 0.1 s.

## Build order

1. [ ] Greybox meshes for all 5 classes at the lengths above, with the attachments, the joint and the physics flags. Decide the sword size here.
2. [ ] Per-class trail presets on markers (port SwingTrail).
3. [ ] The three damage-type hit sparks, the counter-hit flash and a pooling module.
4. [ ] Per-client hitstop table per class and the victim shake.
5. [ ] Parry, stagger and riposte effects moved onto the kit.
6. [ ] Final one-handed sword mesh plus SAO-style hero variants (PBR and emissive).
7. [ ] Two-handed IK grip and sheath swap. This comes with the greatsword phase.
8. [ ] Sword Skill glow and grammar. This comes with Phase 2.
9. [ ] Rarity tints and +N auras. This comes with Phase 4.
10. [ ] Mobile pass: Emit counts at low quality, draw calls in the Shift+F2 view.

Steps 1 to 5 can start now in parallel with Phase 1 (animations), since they don't need uploaded animations.
