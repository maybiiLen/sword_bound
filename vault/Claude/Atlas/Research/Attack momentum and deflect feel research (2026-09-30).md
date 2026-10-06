---
type: research
created: 2026-09-30
author: claude
tags:
  - research
  - combat
---

Up: [[Claude]]

Follow-up to [[Combat and movement research (2026-09)]]. Henry says attacking kills all momentum, left click still feels stiff, and deflecting doesn't feel good. There were three research passes: Sekiro feel, momentum and input, and modern Roblox VFX/SFX. Reddit was blocked in all three passes (SITE_BLOCKED), so forum sourcing comes from Steam, GameFAQs and the Roblox DevForum. Anything marked UNSOURCED is a judgment call.

## What our code does today (from the code)

- An attack sets MoveSpeedMultiplier to 0.15 instantly for the whole attack, and any combat state cancels sprint (SprintBlocked). A sprinting player drops from 26 to about 4 studs/s the moment they swing.
- The light attack fires on mouse release, because holding the same button charges the heavy.
- The lunge is a LinearVelocity that replaces current velocity: 12 studs/s for 0.12 s, about 1 stud.
- Parry: the attacker is staggered 1.6 s. Feedback is a gold particle burst, a placeholder built-in sound, and the same hit-stop size as a hit.

## Momentum and input

- **Firing on release** costs at least 100 ms in practice. The fix is to start the tap action at press and switch to the hold action if the button stays down ("fake it"). [gamedeveloper.com, dealing with designer input latency] Swink puts real-time response under 100 ms. [Game Feel review, lizengland.com]
- **Elden Ring** puts heavy on its own input (Shift+M1 on keyboard). **Sekiro** swings on R1 press and holding charges a thrust. **Deepwoken** has M1 light and a separate critical key. [Fextralife ER Attacking, Steam, Deepwoken wiki]
- **Running attacks** exist in Elden Ring, Deepwoken and Sekiro. Sekiro's sprint attack is a lunge that closes distance. [ER wiki, Deepwoken wiki, Sekiro Fandom]
- **God of War 2018 "suck-to-target"** has each attack define a range, speed and stop distance that pull Kratos toward the target, with range shrinking as the angle widens. [GDC 2019, Mihir Sheth, Evolving Combat]
- **Our exact bug in other engines** is a run attack that drops speed from 600 to 100 because input is disabled. The fix is to keep velocity or play the attack upper-body only. [Unreal forums]
- **Tracking** is strongest early and falls off on a curve. FromSoftware data has a rotation-speed event in degrees per second. [Unity discussions, soulsmodding TAE] Too much tracking reads as unfair. [Steam ER]
- **Stop forward travel on contact** so lunges don't overshoot. [playtank.io, Unity discussions]

## Sekiro deflect feel

- A deflect throws a big spray of orange/gold sparks. A block gives a weak spark or dull shimmer. [Medium, Sekiro and the anatomy of a perfect parry; Steam; GameFAQs]
- A deflect is a louder clang with a different, higher pitch. A block is a low-volume or dull clunk. You can tell them apart by ear alone. [same]
- Deflect sets the rhythm. The ringing of steel is compared to a rhythm game. Miyazaki centres the game on "the clashing of swords". [PCGamesN, Superjump, Dengeki interview]
- A deflect staggers enough for one counter slash, not a long stun. [critpoints.net, GameFAQs]
- Sekiro's R1 windup can be cancelled into guard, dodge or jump. Thrusts and sprint attacks can't be. [GameFAQs, critpoints.net "Sekiro is not a souls-like"]
- Attacks build posture even when blocked, and constant pressure stops posture regen. [FromSoftware manual]
- There is no primary source on deflect hit-stop, camera or rumble. A popular mod adds shake, which suggests the base game has little.

## Modern Roblox effects

- **Impact frames** (the anime look): flip ColorCorrection to black/white or inverted for 1 to 2 frames, plus speed lines. [devforum advanced-impact-frames]
- **White or red flash on the hit character** with a Highlight tweened out. The Highlight limit rose to 255 in Nov 2025, and each one costs a drawcall. [devforum]
- **Other techniques:** camera FOV punch, a red tint on crits, small pitch variation per hit, abrupt stop on contact. [devforum "make my combat more impactful"]
- **ParticleEmitter flipbooks** (Grid2x2/4x4/8x8), Emit() bursts, Squash, LightEmission. [create.roblox.com]
- **Slash meshes** built in Blender with a flipbook texture. [devforum animated slashes]
- **Tools:**
  - Open-source mesh flipbook pack: free, includes shockwaves.
  - VFX Forge: $15, obfuscated code.
  - Sine VFX: $7, 14k assets.
  - "Advanced VFX Plugin": 3,000 Robux, no clear license. Avoid it.
- **Deepwoken:** a parry stuns the attacker and resets the parry cooldown. The posture bar glows red in "shaky" frames. [Deepwoken wiki]

## Sound

- A sword sound has four layers: swing, metallic scrape, hit, enhancers. A parry is "two edges meeting and ringing off". A block has "more thud than ring". [daviddumaisaudio, morphic]
- **Where to get sounds:**
  - Roblox's public SFX library includes 100k+ Pro Sound Effects sounds.
  - Creators can publish SFX under 10 s publicly.
  - Sonniss GDC bundles are royalty-free for commercial games with no attribution, but you can't redistribute the raw files.
  - Freesound: use CC0, avoid CC-BY-NC.
  - [devforum audio privacy update, public SFX uploads, sonniss license, freesound FAQ]
- The new Audio API (AudioPitchShifter, AudioEqualizer, AudioReverb) can build per-hit processing chains. [devforum Audio API beta]

## Performance

- Spawn VFX on each client and have the server send only positions. Pool parts (PartCache). Scale Emit counts by graphics quality yourself. Particle rate scaling by quality was reported broken on Aug 28, 2026. [devforum]
- Test `AdjustSpeed(0)` hit-stop carefully. Several threads report it not pausing. [devforum]

## Proposed changes (ranked; all numbers UNSOURCED starting points)

1. Light attack on press. If the button is still held at 0.2 s (before the 0.26 s hit) cancel into the heavy charge.
2. Replace the instant 0.15 speed cut with a decay. Keep current velocity at attack start and ease to about 0.3 of walk speed over about 0.15 s. Only cancel sprint at the hit, not at the press.
3. Add the lunge on top of the current velocity. Make it about 2.5 studs for lights and 4 for heavies, pull toward a locked target within about 8 studs with a 3-stud stop distance, and stop on contact.
4. Sprint attack: a running lunge that keeps most of the sprint speed. It needs a new animation.
5. Tracking curve: about 720°/s early in the windup, down to 0 at the hit frame.
6. Windup cancel into block or roll until about 0.15 s (Sekiro style).
7. Deflect feedback:
   - Separate parry and block sounds and visuals.
   - A big gold spark burst plus a flipbook star flash.
   - A longer parry freeze (about 0.08 to 0.1 s vs about 0.04 to 0.06 s on a hit).
   - A Highlight flash on the attacker.
   - An impact frame reserved for perfect parries and posture breaks.
   - Clang pitch rising slightly on consecutive deflects.
8. Parry stagger: cut 1.6 s to a short recoil (about 0.4 s) for one counter slash. Keep the long stagger for posture breaks. This ties into the posture rework from the first research doc.
