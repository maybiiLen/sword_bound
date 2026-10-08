---
type: effort
status: draft
created: 2026-10-08
author: claude
tags:
  - effort
  - combat
  - weapons
  - skills
  - animation
---

Up: [[Claude]] · Replaces items 5 to 7 of [[Core fighting plan]] with a bigger roadmap

This is the plan for the base of the game: animations, sword skills and melee weapon classes. It was drafted 2026-10-08 from five parallel research passes:
- [[Echoes of Aincrad and SAO action games (2026-10-08)]]
- [[Souls melee weapon class design (2026-10-08)]]
- [[Sword Skill system design (2026-10-08)]]
- [[Roblox combat animation pipeline (2026-10-08)]]
- [[Weapon class progression and switching (2026-10-08)]]

Earlier context: [[Core fighting fundamentals research (2026-10-06)]].

Reddit was blocked in every pass, so forum evidence comes from Steam, GameFAQs, official forums and the DevForum. Sources live in the research notes. Anything marked (judgment) is my call, not a sourced fact.

## Principles (what the research agrees on)

1. **Each weapon gets one defining mechanic.** Echoes reviewers said its six weapons "feel distinct rather than reskins". MH's producer says a new weapon type must "add something new" and not overlap.
2. **Skills are the punish, not the opener.** Echoes skills were strongest after Parry Slash and Dodge Slash. Players also asked for skills with riders (buffs, breaks), not standalone damage.
3. **Normalize resources per weapon.** Echoes had to cut SP gain for fast, many-hit weapons in patch 1.0.5. Award SP per damage dealt, not per hit.
4. **No mobility skill beats the roll.** Bloodhound's Step dominated Elden Ring PvP until it was nerfed.
5. **Separate PvE and PvP numbers from day one.** Elden Ring added PvP-only scaling in 1.07 and PvP poise cuts in 1.08.
6. **Don't grind or inflate HP.** Players hated Hollow Realization's 10,000-use mastery and Echoes' and Lycoris' boss HP inflation. Echoes' flat leveling, with all skills by proficiency 10, was praised.
7. **Loud, readable cues.** Last Recollection's Skill Connect window was hard to see. Canon pre-motion lights the weapon in the skill's color.

Models and effects have their own plan: [[Weapon models and effects plan]].

## Phase 0. Shared systems first (before any new weapon)

Building these once means every weapon class after them is mostly data plus animations.

- [ ] **Publish animations.** Upload all 24 AnimSaves to the group through Open Cloud (enabled Oct 2025) or the Asphalt CLI, then write the ids into AnimationLibrary.Published. Right now nothing plays on live servers.
- [x] (done 2026-10-08, [[Phase 0 shared combat systems]]) **Damage types.** Slash, Strike and Pierce tags on attacks. Pierce gets a counter-hit bonus (Elden Ring: +30% PvE, +15% PvP). Strike gets a bonus to guard and stamina damage.
- [x] **Protection windows per attack.** Replace the single HyperArmor flag with:
  - a time window inside each attack
  - a level (none, flinch-proof, full)
  - damage taken during armor
  - Elden Ring varies this by class.
- [ ] **Charge levels** as a generic attack field. The greatsword needs them, following the MH Hammer style.
- [x] **Per-class multipliers:** reach, crit/riposte (dagger 1.3 to 1.4x), and guard stamina damage.
- [x] **Stun manager.** Stuns never stack and the longest wins, plus a short immunity window after a stagger (from the fundamentals research).
- [x] **PvE/PvP multiplier tables.** Empty at first, so that balancing later is just data.
- [x] **One marker vocabulary checked automatically.** Every attack clip must have HitStart, HitEnd and CancelOpen. WeaponRegistry fails loudly otherwise (judgment).

## Phase 1. Fix up the animations (sword first)

- [ ] **Polish the sword moveset in Specs:** overshoot, hips leading, smears. Use the rule that one-handed swords swing from shoulder rotation with counterbalance.
- [ ] **Move to Animation Graphs** (full release Jul 2026). Use one shared locomotion graph, then an upper-body masked layer per weapon stance. This fixes walking while guarding, blocking or charging.
- [ ] **Hybrid pipeline from here on:**
  - Procedural Specs stay the blockout and timing source.
  - Hero clips (finishers, heavies, skills) get hand-polished in Blender (free) or Cascadeur Indie ($96/yr, has an Export to Roblox command), then imported through the Clip Editor's FBX path.
  - Commissions run about $20 to $30 a clip, or about $160 per 8-move set, if you'd rather pay an animator for some.
- [ ] **Animation sanity tool:** a Studio command that renders posed frames of every clip into a contact sheet (the Discord strip method, automated), so bad poses get caught fast.

## Phase 2. Sword Skill framework (built on the sword)

The spec merges your existing plan with the research. Numbers are starting points (judgment) unless noted.

- **SP**
  - 3 segments, and a skill costs 1 to 3.
  - Filled by damage you deal, plus a bonus on perfect parries and ripostes (Lies of P, Wo Long, Lycoris all fill from fighting).
  - No passive regen. SP decays slowly out of combat.
- **Cooldown per skill** of 4 to 12 s on top of SP (SAO canon has per-skill cooldowns).
- **Activation:** any light hit can cancel into a skill (your plan, matches Echoes).
- **Pre-motion** of at least 0.2 s with the weapon glowing in the skill's color (canon). This is what lets opponents read and parry skills.
- **Post-motion delay** scales with cost: about 0.3, 0.5 and 0.8 s (canon says bigger skills freeze longer). Only a Skill Connect exits it early. A roll does not (judgment, to keep skills committal).
- **Skill Connect**
  - At most 2 skills.
  - Shown with a loud cue: sound plus a flash plus a brief slow-down.
  - The connected skill skips its cooldown but still costs SP (Hollow Fragment).
- **Hyper armor** only on 3-segment skills. Never in PvP on a skill that also guard-breaks (BDO's lesson).
- **Kit per class at launch:** 6 skills, 3 equipped.
  - Categories: counter, posture/guard break, gap closer, multi-hit finisher, AoE, buff or utility. MH Rise uses 6 per weapon.
  - Each skill gets a rider (bleed, guard damage, buff, SP refund), not just damage.
- **Bonus vs broken targets:** skills deal extra damage to staggered or posture-broken enemies (makes skills the punish).
- **Sword kit from canon names:**
  - Slant (1 hit)
  - Vertical Arc (2, V shape)
  - Horizontal Square (4)
  - Sonic Leap (gap closer)
  - Rage Spike (leap)
  - Vorpal Strike (long-reach finisher)

## Phase 3. Weapon classes, one at a time, end to end

Each class ships complete before the next: data, animations, behavior, 6 skills, sounds, docs, Discord post.

The research disagrees on the roster, so this is a decision for you (see below).
- Echoes' official six: sword, rapier, dagger, mace, 2H sword, 2H axe.
- The souls pass cut the axe as a reskin risk and merged rapier into spear.
- The progression pass suggests launching with 5 or 6.

My recommended launch five, each with one hook:

| Class | Hook | New shared system it proves |
|---|---|---|
| One-handed sword (have) | Baseline, shield later | none |
| Dagger | Fastest swings and parry, highest crit/riposte, near-zero poise damage | crit multiplier, short hitbox |
| Rapier | Long thrust reach, counter-thrust, Pierce counter bonus | Pierce type, thrust hitbox |
| Two-handed sword (longsword/greatsword) | Charged heavies with hyper armor, long reach, sweeping | charge levels, armor windows |
| Two-handed axe | Big horizontal sweeps that hit several targets, guard break | Strike-like guard damage, multi-target |

Build order: dagger (smallest change), then two-handed sword (biggest contrast), then rapier, then axe.

Later updates, one per update like Throne and Liberty and FF14: katana (bleed plus iai counter meter), spear, mace, curved sword. Dual Blades come as an earned Unique Skill, never sold.

## Phase 4. Progression and switching

- [ ] **Per-weapon level** gates that weapon's skills. All 6 unlock by about level 10 (Echoes did this and players liked it).
- [ ] **Skill proficiency** with low star thresholds, no reset when you unslot a skill, and free early respecs.
- [ ] **Switching** out of combat only (FF14). No mid-combo swaps, since souls-style commitment depends on it.
- [ ] **Catch-up:** +100% XP for weapons below your highest (FF14 Armoury Bonus).

## Phase 5. Fold in the earlier backlog

- [ ] Attack sounds (old item 5), done per class as each one ships, plus a shared flesh hit.
- [ ] Healing flask (old item 6), before PvE content.
- [ ] Enemy telegraphs and NPCs following player rules (fundamentals #1 and #7).
- [ ] Switch party mechanic (fundamentals #2).

## How to use the Max plan for this

- **Parallel research.** Several agents research at once, like the five passes behind this plan.
- **Long autonomous build runs.** With your Mac awake and the place open in Studio, I can do a whole phase end to end (edit, playtest, commit, Discord post) without stopping.
- **Workflows.** Say "use a workflow" and I can orchestrate many agents at once, for example one agent per weapon class drafting its moveset and skill data in parallel, then a reviewer agent. This costs a lot of usage, so only when you ask.
- **Scheduled tasks.** For example, a weekly check that the repo matches the live place, or a Discord progress digest.

## Decisions needed from Henry

1. Launch roster (the five above, Echoes' six, or your own list).
2. Can a roll cancel a skill's post-motion delay? I recommend no.
3. Animation polish: by hand in Blender/Cascadeur, commissioned, or procedural only for now.
