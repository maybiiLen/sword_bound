---
type: effort
status: round-3-done
created: 2026-10-09
author: claude
tags:
  - effort
  - combat
  - audio
---

Up: [[Sword combat feel revision]] · Daily log: [[2026-10-08]]

On 2026-10-09 Henry said the attacking side was missing key features. He named four:
- Flinching.
- The enemy being pushed back while he pushes forward through a string.
- Super armor for bosses and other enemies, so they don't flinch.
- Sounds that feel "super chopped".

He also wants the fundamentals done fully before building other classes, so every class builds on the same foundation.

Research, 3 agents plus a sound search:
- [[Hit reactions, pushback and armor research (2026-10-09)]]
- [[Combat sound design research (2026-10-09)]]
- [[Melee fundamentals gap audit (2026-10-09)]]: 66 systems checked. 29 exist, 20 are partial and 17 are missing, with a ranked top 10.
- [[Combat sound candidates (2026-10-09)]]: licensed Pro Sound Effects candidates per event.

**Source access.**
- Reddit, X and Discord were blocked or empty again.
- One agent opened a Reddit mirror and an X thread mirror before it knew the sites were blocked. Both are left out of the notes.
- What worked: the DevForum, Steam discussions, Sakurai's column, Game Developer, the PlayStation Blog, and the Elden Ring, Sekiro and DS3 wikis.

## What was built

### Hit reactions (Combat.HitReactions, CombatRules.HitReaction)

Every clean hit on an enemy now plays a reaction. The reaction picks a side from the attack:
- The forehand (Light1) hits the victim's left side.
- The backhand (Light2) hits the right side.
- Everything else hits the front.
- Anything from behind is a back hit.

Light reactions last 0.4 s and heavy reactions 0.7 s. They follow Elden Ring's damage levels, where lights are short staggers and heavies are moderate.

The clip starts on the peak pose, freezes for the hitstop, then eases out. This is the research's "snap into the hit pose" rule.

Reactions run at Action2, so the enemy's next attack or a stagger takes over the moment it starts.

The attacker's client predicts the reaction. The server picks the same one and sends it to everyone else.

When the hit will break poise, no reaction plays, so the Stagger reads cleanly.

Two other enemy types get reactions too:
- The training dummy rocks away from the hit around its base.
- Custom mob rigs tilt their root joint.

### Pushback and attacker step

Every clean hit slides a non-player target:
- 1.0 stud for lights, 1.3 for the overhead chop and 2.0 for heavies.
- 4 studs for the finisher's knockback.

The slide is cut short by walls, and a target slides at most 10 studs per 2 s.

When your hit connects you step in 0.9 studs on lights, never closer than 3 studs. A string stays glued to the enemy, the way God of War pairs small hit translations with pulling the target back in.

In the knight test, the knight and the player each moved 1.31 studs on the second hit, so spacing held at 3.3 studs.

### Armor tiers

| Tier | Who | Behavior |
|---|---|---|
| Fodder | mobs, dummies | always flinch, full slide |
| Elite | Sparring Knight | hyper armor during its own attacks: ArmorTwitch, a white flash, extra hitstop and 25% slide; flinches when idle |
| Boss | names with [BOSS] (Illfang, Snowcap Boar) | super armor: always twitches, never slides, poise still breaks it |

The patterns follow Elden Ring hyper armor, For Honor's white flash, and Genshin's extra hit freeze on unbroken poise. The tier values are judgment (unsourced).

### Combat audio (Combat.CombatAudio)

Layered Pro Sound Effects sounds now replace the legacy swordslash and metal.ogg files. These are licensed for Roblox; ripped uploads were rejected.

- **Events.** SwingLight, SwingHeavy, Thrust, HitFlesh, HitArmor, HitWood, HitHeavy, Block, GuardBreak, Roll, Draw and Sheath.
- **Variants.** 2 to 3 per event, never the same one twice in a row. Each play randomizes pitch by ±0.5 to ±1.5 semitones and volume by ±1.5 dB.
- **Hit layers.** The hit picks its layer by material: the knight is Armor, dummies are Wood, everything else is Flesh. Heavy and counter hits add a body thump layer.
- **Timing.** Whooshes are timed so the variant's measured loudest point lands on the hit frame, the way God of War seeks into its files. NPC whooshes still start at the wind-up, since they are the warning cue.
- **Mix.** A hit ducks the swing group for 0.15 s. Each SoundGroup has a voice cap. Rolloff is real now: your own sounds stay full volume to 20 studs, others fade from 8 to 12 studs, instead of the old 10,000 studs.
- **Levels.** Volumes were levelled from each file's measured PlaybackLoudness peak in a play test, since nobody could listen.

All 7 reaction animations are published for live servers.

## Tests

- Unit tests pass 25 of 25. The new ones cover HitReaction sides, behind, heavy, Push/Knockback, the Elite and Boss tiers, ArmorTierOf, IsFromBehind and that every reaction clip exists.
- Knight 4-hit string: HitLightLeft, then HitLightRight, then HitLightFront, then Stagger on the poise break (no flinch on top). Damage was 112.8.
- Dummy string: the wood hit layers play, and the heavy layer plays on the finisher.
- Sound log on the dummy: the variants changed every hit, and whooshes start about 0.05 s after the press so their peak lands on the hit.
- No console errors.
- The repo matches the live place, 89 of 89, including a teammate's new Growth system.

## Review

A reviewer found 10 issues, and all are fixed:
1. Reaction clips covered the knight's next wind-up. Fixed by moving them to Action2.
2. A flinch played on top of the poise-break stagger. Fixed with CombatRules.PredictsPoiseBreak.
3. Your own hits used the other-player rolloff. Fixed with an Own flag.
4. The duck could fail when hits landed close together. Fixed by cancelling the restore tween.
5. Delayed whooshes escaped the voice cap. Fixed by counting pending sounds.
6. The step could close inside 3 studs on a poise break. Fixed: a poise break now counts as no slide.
7. ArmorTwitch popped at its end. Fixed with an early fade-out.
8. Weak tables keyed by instances. Fixed by switching to strong tables with Destroying cleanup.
9. The riposte's second spark ignored the target's material. Fixed.
10. The knight's whoosh lost its early warning. Fixed by keeping it at the wind-up for NPCs.

## Next fundamentals (from the gap audit, ranked)

1. [x] Enemy hit reactions and pushback (this round)
2. [x] Combat audio pass (this round; footsteps and kill sounds are still to do)
3. [ ] Enemy telegraph language: wind-up hold, weapon glint, rising wind-up sound, a red danger cue for attacks that can't be parried
4. [ ] Group AI: attack tokens, strafing at a distance, no attacks from off-screen, leash
5. [ ] Kill and death feedback: kill hitstop, kill sound, an SAO-style shatter
6. [ ] Player-side feedback: directional flinch, low-health cue, own poise bar, exhaustion cue
7. [ ] Mobile touch controls with stronger aim assist
8. [ ] Hit lag compensation: server position history and rewind
9. [ ] Backstab and attack rebound off walls
10. [ ] Damage numbers and an accessibility settings pass
