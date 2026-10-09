---
type: research
created: 2026-10-09
author: claude
tags:
  - research
  - combat
  - audit
---

Up: [[Claude]] · Used by: [[Hit feel round 3]]

Produced by a research agent on 2026-10-09 after Henry said attacks are missing key features (flinching, enemies pushed back while you push forward, super armor for bosses, sounds that feel chopped) and that the fundamentals must be done before other classes. 66 melee fundamentals checked against Docs.Combat (HAS, PARTIAL, MISSING) with a ranked top 10. Reproduced as the agent returned it. Claims marked unsourced are the agent's own calls.

Scope. This checks the sword against the fundamentals that strong melee action games and souls-likes share, so every future weapon class sits on a finished base. Status comes only from the docs: `ReplicatedStorage/Docs/Combat.luau` and `Docs/README.luau` in sync16, plus the 2026-10-09 UPDATE in the combat brief. "HAS" means the docs describe it working. "PARTIAL" means some of it exists. "MISSING" means the docs never mention it or list it as not built.

Two doc problems turned up during the audit:
- The "NOT BUILT YET" block at the bottom of Docs.Combat is stale. It still lists ripostes and jump attacks, and both now exist. Backstabs and damage numbers really are missing.
- The docs and the brief disagree on hit sounds. Docs.Combat says "Hits and blocks get a small random pitch per play". The brief says sounds play at a fixed pitch with no variation. I treated audio as PARTIAL either way.

## Source access

- **Reddit was not reachable.** WebFetch on reddit.com returned SITE_BLOCKED. A WebSearch limited to reddit.com was rejected by the proxy (HTTP 400). `site:reddit.com` searches for r/gamedesign, r/soulslikes, r/robloxgamedev and r/truegaming returned no reddit.com URLs, only third-party mirrors. Per the rules I did not open the mirrors, so this report has no Reddit content.
- **X was not reachable.** `site:x.com` and `site:twitter.com` searches returned no X posts, and WebFetch on x.com failed with ROBOTS_DISALLOWED.
- **Discord had no usable content.** `site:discord.com` searches returned only server directory pages (for example a "Souls Combat Community" listing), with no discussion text.
- **What worked.** Forum-style sourcing came from the Roblox DevForum, Steam Community discussions, gamedev.net-style articles and wikis. GDC Vault returned only the session abstract for the God of War combat talk, so God of War details come from developer quotes on the PlayStation Blog.

## Checklist

### Attacker side

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Fast, readable startup and cadence | Swink defines game feel as "realtime control of virtual objects in a simulated space, with interactions emphasised by polish" (https://en.wikipedia.org/wiki/Game_feel). Genshin's Keqing N1 lands in about 167 ms (https://library.keqingmains.com/characters/electro/keqing). | HAS | Lights hit at 0.19 s and chain about every 0.42 s (2026-10-08 timing pass). |
| Input buffer | Smash Ultimate buffers 9 frames and Brawl buffers 10, so inputs don't have to be frame-perfect (https://www.ssbwiki.com/Buffering). | HAS | InputBufferTime is 0.35 s, the newest press replaces older ones, and each press fires when its window opens. The 0.35 s length is long next to Smash's roughly 150 ms. |
| Cancel windows and animation cancels | Elden Ring-style committed attacks with ordered cancels (described in Docs.Combat). Sekiro-style wind-up cancels act as feints (vault research). | HAS | CancelOpen, then RollOpen, then MoveOpen. WindupCancelTime is 0.15 s into block or roll, and block can cancel recovery after CancelOpen. |
| Attack travel to target (motion warping) | Unreal Motion Warping bends root motion so the attack ends at the target (https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-warping-in-unreal-engine). | HAS | Warps up to 4 studs (running attack 8) and stops 3.5 studs short. It re-aims until HitStart and stops short of walls. |
| Soft aim and facing without lock-on | True Directional Movement uses a 60 degree cone and turns faster in wind-up than in the active frames (https://github.com/ersh1/TrueDirectionalMovement/blob/master/src/Settings.h). | HAS | 60 degree cone within 10 studs. Turns at 720 deg/s in wind-up and 180 deg/s while active, then commits. |
| String finisher with a payoff | Roblox battleground templates use 4-hit M1 strings that end in a launcher or knockback (https://devforum.roblox.com/t/battleground-modulepack-ragdoll-stun-direction-cooldown/3488881). | HAS | Light4 is a spinning finisher with 4 studs of knockback on non-player targets. The full string breaks a 60-poise enemy. |
| Charged heavy | Souls-likes use a held heavy as the slow, high-stance-damage option (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide). | HAS | Hold past 0.14 s to charge, up to 1.0 s for full charge, with hyper armor. |
| Contextual attacks (running, jump, roll, guard counter) | Elden Ring teaches guard counter, jump attack and stance break as core verbs (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide). | HAS | All four exist, have their own animations and are validated on the server. |
| Backstab | Elden Ring lets you critical from directly behind (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide). DS3 plays a solo stab that turns into the backstab only if the target stays in range (https://critpoints.net/2017/06/10/the-majesty-of-dark-souls-3s-backstab/). | MISSING | "NOT BUILT YET: ... ripostes/backstabs". Ripostes now exist, backstabs don't. |
| Riposte or critical on a broken enemy | Elden Ring: a stance-broken enemy is "briefly exposed to a critical attack" (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide). | HAS | Red highlight, 2.5x damage times 1.5 crit, i-frames for the whole animation. |
| Hyper armor and protection windows | Elden Ring's hyper armor adds temporary poise during some actions (https://eldenring.wiki.gg/wiki/Stance). | HAS | Armor windows with HyperArmor, Armor and DamageTaken 0.9. |
| Attack rebound off guards or walls | Elden Ring's hidden Hardness stat makes some one-handed lights bounce off guards (https://eldenring.wiki.gg/wiki/Hardness). | MISSING | The warp stops short of walls, but no swing recoils off a wall or a guard. |
| Jump and air combat | In souls-likes air combat is the plunging jump attack, which deals extra stance damage and ends in a crouch (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide). | HAS (genre scope) | Jump attack with plunge, hyper armor and a server ground check. There is no aerial combo, which fits the genre. |
| Healing with commitment (flask) | Dark Souls 3's Estus Flask has limited charges that refill at bonfires (https://darksouls3.wiki.fextralife.com/Estus+flask). | MISSING | The combat docs have no heal action. |
| Status effects (buildup meters) | Elden Ring statuses fill a hidden meter, trigger when it is full and decay over a few seconds (https://gamertagmythras.com/blog/elden-ring/elden-ring-status-effects-guide). | MISSING | Only damage types exist (Slash, Strike, Pierce). |

### Defender side

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Roll with i-frames, directional when locked on | A core souls verb (https://darksouls3.wiki.fextralife.com/Combat). | HAS | IFrameStart and IFrameEnd markers, four directions when locked on, backstep with no input. |
| Block with stamina cost scaled by stability | In DS3, shield stability sets how much stamina a block costs (https://darksouls3.wiki.fextralife.com/Combat). | HAS | Uses BlockStability, GuardStamina and GuardDamage. At 0 stamina the guard breaks. |
| Parry with a tight window and anti-mash | Sekiro-style deflects (https://sekiroshadowsdietwice.wiki.fextralife.com/Combat). | HAS | 0.3 s window (0.07 s when spammed), perfect parry at 0.08 s, drains the attacker's posture. |
| Distinct block vs parry feedback | Sekiro deflects sound different from blocks (https://sekiroshadowsdietwice.wiki.fextralife.com/Combat, user note). | HAS | Parry: gold burst, two layered clangs, pitch rises on consecutive parries. Block: small pale spark and a dull clunk. |
| Guard counter | Elden Ring guard counter (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide). | HAS | Attack within 0.6 s of a block or parry, 1.6x damage, hyper armor. |
| Anti-stunlock rules | A central stun manager where the longest stun wins (https://devforum.roblox.com/t/stun-handler-v2/1072859). | HAS | Longest stun wins, plus stagger immunity of 1 s in PvE and 3 s in PvP. |
| Player hit reactions (variety, direction, knockdown) | Hit animations should match the attack direction and start from the hit pose with a zero-length crossfade (https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects). | PARTIAL | Players play one 0.35 s Flinch clip. There are no directional reactions and no heavy-hit knockback or knockdown. |
| Player posture HUD | Sekiro puts the posture bar in the middle of the screen (https://sekiroshadowsdietwice.wiki.fextralife.com/Combat). | PARTIAL | Players have Poise and MaxPoise attributes, but the docs only describe an NPC poise bar. |
| Stamina UI and exhaustion cue | Stamina gates every action in souls-likes (https://darksouls3.wiki.fextralife.com/Combat). | PARTIAL | A sprint stamina bar exists (README: "Sprint system with stamina bar"). The docs describe no cue for hitting 0 in combat, when you can't act. |

### Enemy side

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Enemy hit reactions tiered by attack weight | Nijman's Nuclear Throne breakdown: enemies get a material sound, a push in the hit direction and a get-hit animation that starts on a white frame (https://infovore.org/?p=5275). God of War enemies "break reality with huge pose changes" (https://blog.playstation.com/?p=370399). | PARTIAL | The Knight has Flinch, Stagger (1.1 s) and GuardBreak. Dummies are anchored and do nothing. Reactions are the same for light and heavy hits and have no direction. |
| Per-hit pushback | In Street Fighter every attack has its own pushback that grows with strength, and the attacker is pushed back instead when the defender is in the corner (https://game.capcom.com/cfn/sfv/column/131545?lang=en). | PARTIAL | Only the finisher knocks back (4 studs). Normal hits have no pushback and the attacker has no recoil. |
| Hitstun scaled by attack weight | Smash hitlag and reactions grow with damage (https://www.ssbwiki.com/Hitlag). | PARTIAL | Flinch is a fixed duration. Stagger exists only as a poise break. |
| Enemy telegraphs and readability | Enemies "always have a tell", stronger attacks have more obvious tells, and color, effects or sound often back up the animation (https://gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems). Sekiro flashes a red "Danger" kanji (https://sekiroshadowsdietwice.wiki.fextralife.com/Combat). Lost Ark gives counterable attacks a blue glow (https://vulkk.com/2022/02/11/how-to-use-advanced-combat-mechanics-in-lost-ark/). | PARTIAL | The Knight has a quick wide slash and a slow delayed chop. There is no glint, sound tell or danger marker, and perilous attacks were deferred. |
| Attack tokens or attacker limit | Doom 2016 demons "request a token" to attack and return it afterwards (https://www.gamedeveloper.com/design/cyber-demons-the-ai-of-doom-2016-). The battle circle caps simultaneous attackers at 1 or 2 (https://code.tutsplus.com/battle-circle-ai-let-your-player-feel-like-theyre-fighting-lots-of-enemies--gamedev-13535t). | MISSING | There is one AI enemy (the Sparring Knight) and no coordination between enemies. |
| Spacing, strafing, preferred distance | Many games keep an inner zone around the player clear. In Aztez each enemy type keeps its own preferred distance (https://gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems). | MISSING | The Knight "walks up and throws" its attacks. No circling or backing off is described. |
| Enemies wait out their own stagger before attacking | Enemies usually wait to recover from the previous hit before attacking again (https://gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems). | PARTIAL | Stagger stops the Knight, but its flinch rules and attack cooldowns aren't documented. |
| Aggro, chase limit, leash | A WoW mob leashes: past a maximum chase distance it clears aggro and returns to spawn without attacking anyone (https://warcraft.wiki.gg/wiki/Leash). | PARTIAL | The Knight has an AggroRange attribute. No leash or reset is described. |
| Off-screen attack rules or indicators | Many games stop off-screen enemies from attacking, or use directional indicators (https://signalsandlight.substack.com/p/how-do-enemy-attacks-work-with-the). Melee enemies "almost never attack you off screen" (https://gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems). | MISSING | Not described. |
| Enemy armor on attacks | Elden Ring hyper armor and super armor (https://eldenring.wiki.gg/wiki/Stance). | PARTIAL | Both Knight swings have hyper armor, but enemies have no general armor-window system besides poise (brief UPDATE). |
| NPCs follow player rules | Arcane Odyssey players call NPCs that block or parry mid-attack unfair (https://forum.arcaneodyssey.dev/t/arcane-odysseys-combat-problem/97410). | HAS | The Knight sets CombatState, takes counter hits and can be riposted. |
| Practice targets that react | (unsourced) Training targets teach the feel of hits only if they show reactions. | PARTIAL | The R6 training dummy only shows its poise bar and plays no reaction animations. |

### Camera

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Over-the-shoulder camera with collision | God of War moved to a close, player-controlled camera that changes how combat plays (https://gdcvault.com/play/1026423/Evolving-Combat-in-God-of). | HAS | Orbit camera with collision, zoom and shake. |
| Lock-on framing and target switching | Lock-on without a way to choose the target can grab the wrong one (https://tvtropes.org/pmwiki/pmwiki.php/Main/CameraLockOn). | HAS | F or middle mouse to lock, flick to switch, a diamond marker, breaks past LockOnBreakRange. |
| Lock-on in tight spaces | Assassin's Creed II's lock-on keeps framing the target regardless of surroundings, which causes trouble in "enclosed spaces" (https://tvtropes.org/pmwiki/pmwiki.php/Main/CameraLockOn). | PARTIAL | Only collision is described. No pull-in, occluder fade or lock-on handling near walls. |
| Keeping several threats in view | God of War's pulled-back camera made multiple targets easier to track, and its camera shake was reduced (https://blog.playstation.com/?p=370399). | PARTIAL | No multi-enemy framing. Only one AI enemy exists today, so this hasn't been tested. |

### Feedback and juice

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Hitstop scaled by weight | Sakurai: the more damage an attack does, the longer the hitstop (https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/). Monster Hunter Wilds hitstop varies by weapon and by the body part hit (https://deltiasgaming.com/?p=113987). | HAS | ClassHitStop is 0.07 s for sword lights and 0.12 s for heavies, and counter hits add CounterHitStop. |
| Victim shake during hitstop, attacker drift | Sakurai: the victim vibrates to sell the shock, horizontally on the ground and vertically in the air, and the attacker keeps moving slightly (https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/), (https://nintendowire.com/news/2022/12/12/this-week-in-sakurai-12-5-12-11-fine-tuning-hit-stop-and-cheating-the-system/). | MISSING | Not described. Hitstop is a freeze plus a camera punch. |
| Camera shake scaled by weight | Shake should scale with attack strength (https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects). | HAS | Trauma-based shake keyed to attack Weight. |
| Hit flash and sparks by damage type | Nijman: a get-hit animation that starts on a white frame (https://infovore.org/?p=5275). | HAS | Slash, Strike and Pierce VFX, a red counter recolor and a 0.1 s white flash. |
| Kill and death feedback | Nijman's screenshake talk ends with "permanence" and an enemy death explosion as finishing layers (https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects). Doom 2016 glory kills make the player invulnerable and block new AI attacks until the kill finishes (https://www.gamedeveloper.com/design/cyber-demons-the-ai-of-doom-2016-). | MISSING | The killing blow grants XP and the dummy respawns. No death animation, shatter, kill hitstop or kill sound is described. |
| Low-health feedback | Doom 2016 shows a red border and "LOW HEALTH" at 25 HP, and DMC5 muffles the music on its last bar (https://tvtropes.org/pmwiki/pmwiki.php/Main/CriticalAnnoyance). | MISSING | Not described. A teammate's HealthBarController exists, with no low-health cue documented. |
| Damage numbers | Damage numbers show exact damage and often sit next to an enemy health bar (https://giantbomb.com/wiki/Concepts/Damage_Numbers). In Monster Hunter World, orange numbers mark weak-spot hits and grey numbers mark hard spots (https://steamcommunity.com/app/582010/discussions/0/1735462352466166513). | MISSING | Listed under "NOT BUILT YET". |
| Crit and weak-hit feedback | Monster Hunter World flags crits with a small orange arrow on the number (https://steamcommunity.com/app/582010/discussions/0/1735462352466166513). | PARTIAL | Counter hits are recolored red and ripostes get an impact frame. Crits on staggered targets have no separate cue. |

### Audio

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Layered, varied impacts by result and material | Conan's melee audio used "content level variation, pitch and volume randomization, and elemental layering", switched by weapon and surface material, with separate Hit Light, Hit Heavy, Blocked, Parried and Deflect events (https://designingsound.org/2009/12/01/audio-implementation-on-star-wars-the-force-unleashed-and-conan/). God of War's axe impact is a low-end slam ending in a high-frequency slash (https://blog.playstation.com/?p=370399). | PARTIAL | Legacy built-ins play one sound per event, and the owner says they sound "super chopped". Parry is layered. The docs claim a small random pitch on hits and blocks, which conflicts with the brief. |
| Swing whooshes per attack, synced to animation | DevForum advice is to fire swing sounds from AnimationEvents so they line up with each swing (https://devforum.roblox.com/t/2311359). | PARTIAL | Only Swing, Lunge and HeavySwing assets exist. Sounds aren't described as tied to markers or varied per combo hit. |
| Distinct parry and block audio | Sekiro deflects can be told apart by ear (https://sekiroshadowsdietwice.wiki.fextralife.com/Combat). | HAS | Two-layer parry clang with rising pitch, and a dull block clunk. |
| Audio tells for enemy attacks and danger | Important information should use at least two channels, such as distinct sounds plus visuals (https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/103). | MISSING | The Knight has no wind-up or danger sounds. |

### UI readability

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Enemy HP and poise display | Sekiro shows separate vitality and posture bars (https://sekiroshadowsdietwice.wiki.fextralife.com/Combat). | PARTIAL | NPCs show a small poise bar and a "STAGGERED" label. Enemy HP display is in the teammate's SAO HUD, which isn't documented here. |
| Lock-on marker | Covered under lock-on framing above. | HAS | Diamond marker. |
| Riposte-open cue | Elden Ring signals stance break with enemies falling to their knees or slumping over (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide). | HAS | Red Highlight plus the Stagger clip. |

### Netcode

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Client prediction, server authority | Ping is a top complaint on the Arcane Odyssey forum (https://forum.arcaneodyssey.dev/t/arcane-odysseys-combat-problem/97410). | HAS | The client predicts everything. The server checks hit windows, reach, state and stamina. |
| Parry ping compensation | Same source. | HAS | Uses the client's press time, clamped to MaxParryRewind 0.15 s. |
| Hit lag compensation (target rewind) | DevForum rollback: log each player's CFrame every 0.05 to 0.1 s, keep about 2 s, rewind by about ping/2 (https://devforum.roblox.com/t/combat-system-with-rollback/3685525). | PARTIAL | Only ReachTolerance and WarpReachRecheck (re-measured 0.25 s later). Targets have no position history. |
| Smooth knockback replication | DevForum: LinearVelocity and BodyVelocity knockback moved attacker and target at different times because of ping and network ownership (https://devforum.roblox.com/t/how-to-make-proper-knockback-for-a-combat-system/3936670). | PARTIAL | The finisher uses server LinearVelocity on the NPC root. Smoothness for the attacking client isn't described. |

### Accessibility and controls

| System | Why it matters (source) | Status | Evidence in docs |
|---|---|---|---|
| Gamepad bindings | Standard for the genre. | HAS | R1, L1, B, R3 and Y are mapped in CombatConfig.Inputs. |
| Mobile touch controls | About 80% of Roblox daily users played on mobile in 2024 (https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue). | MISSING | No touch layout, mobile buttons or mobile aim assist is described. |
| Rumble and haptics | Roblox has HapticService motor control for gamepads (https://create.roblox.com/docs/reference/engine/classes/HapticService) and a newer HapticEffect API with GameplayCollision presets (https://devforum.roblox.com/t/3606858), (https://create.roblox.com/docs/reference/engine/classes/HapticEffect). | MISSING | Not described. |
| Player key remapping | XAG 107: "Games provide in-game remapping of all controls" (https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/107). | MISSING | Keybinds live in CombatConfig, a developer file. No player-facing remap. |
| Hold vs toggle options | Offer toggles for held inputs and let players choose (https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/). | MISSING | Block, heavy charge and free cursor (Left Alt) are hold-only. Lock-on is already a toggle. |
| Cues that don't rely on color alone | "No cue depend on color alone" (https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/103). | PARTIAL | Parry has its own sound. The riposte-open red highlight, red counter hits and the gold vs pale parry and block sparks are color-led. |
| Screen shake and flash settings | Diablo 4 has a "Screen Shake Effects" toggle (https://www.gfinityesports.com/guides/diablo-4-turn-off-screen-shake). A Unity hit-feedback primer advises exposing shake intensity as a setting (https://uhiyama-lab.com/en/notes/unity/unity-game-feel-hit-feedback/). | MISSING | Shake, the perfect-parry high-contrast impact frame and flashes have no player setting. |

## Top 10 missing or partial fundamentals, by impact on feel

1. **Enemy hit reactions that sell the hit.** This is the biggest gap. Every connected swing currently ends in the same Flinch, the dummies don't move, and normal hits don't push. Build a reaction table keyed by attack Weight and hit direction: light front, light left, light right, heavy, and a knockdown or launch for finishers and charged heavies. Snap into each reaction with a zero-length crossfade, which matches the Game Developer advice above. During hitstop, shake the victim's root horizontally (vertically if airborne) with a decaying amplitude and let the attacker creep forward slightly, which is Sakurai's recipe. Give every hit a small server-applied pushback of about 0.5 studs for lights and 1.5 for heavies. If the target is against a wall, push the attacker back instead, the Street Fighter corner rule. Swap the R6 dummy for an R15 dummy that plays the same table. The reaction set, push distances and dummy swap are my judgment (unsourced).

2. **A real combat audio pass.** The owner already flags the sound as "chopped", and audio is half of impact. Replace the legacy built-ins with sets of 3 to 5 variations each for whoosh light, whoosh heavy, flesh hit, armor hit, blocked, guard break, kill, footstep scuffs on lunges and the roll cloth swish. Trigger the whoosh from a Swing marker in Specs so it peaks with the blade arc. Layer impacts as a low thump, a mid body hit and a high slice, following the God of War and Conan layering above. Pick the variation and add plus or minus 5% pitch and volume per play. Fix the docs and brief mismatch about pitch randomization at the same time. The set list and the 5% range are my judgment (unsourced).

3. **An enemy telegraph language.** Readable attacks make a souls-like feel fair. Today the Knight relies on animation timing alone. Add a standard tell layer to every enemy attack: a wind-up pose held long enough to read, a brief weapon glint, and a wind-up sound whose pitch rises toward the hit. Add a separate red danger icon plus a unique sound for attacks that can't be parried, which matches Sekiro's kanji and the XAG two-channel rule. Scale tell length with attack strength, since stronger attacks need more obvious tells. Exact timings and colors are my judgment (unsourced).

4. **Group AI fundamentals before floor mobs ship.** One Sparring Knight hides this, but Floor 1 packs will gang up without it. Add a per-player attack token pool (1 or 2 melee tokens, as in Doom and the battle circle). Make enemies without a token strafe at their preferred distance outside an inner ring, let them attack only after recovering from their own hit reaction, and stop them attacking from behind the camera unless they hold a token. Add a leash that resets aggro and walks the mob home when the player drags it past a set range. Token counts, ring radius and leash distance are my judgment (unsourced).

5. **Kill and death feedback.** A kill currently gives XP and nothing else, so the most rewarding moment is the flattest. On the killing blow, add extra hitstop (about 1.5x the attack's), a distinct kill sound and a death reaction or ragdoll. Then add an SAO-style shatter into glowing fragments as the signature death effect. That shatter is my reading of the SAO source material, not a cited claim (unsourced). Leave a brief mark on the ground for permanence, as in Nijman's list. Player death needs its own sting and screen treatment that ties into the planned town respawn. The specifics are my judgment (unsourced).

6. **Player-side hit and danger feedback.** Players get the same single flinch as everything else and get no warning near death. Reuse the item 1 table for players: directional flinch, heavy-hit stagger, knockdown from big enemy attacks. Add a low-health state below 25%, with a red vignette pulse, a heartbeat and slightly muffled music, as in Doom and DMC5. Show the player's own poise bar near the stamina bar, the way Sekiro centers posture. Make the stamina bar flash and play a short "exhausted" sound when it hits 0. Thresholds are my judgment (unsourced).

7. **Mobile touch controls with stronger assist.** About 80% of Roblox players are on mobile, and the docs describe no touch layout. Add ContextActionService buttons for attack (tap for light, hold for heavy), block, roll, lock-on and draw, plus a lock-on cycle button. Turn soft aim up on touch, with a wider cone and longer range, as the earlier feel revision already suggested. Add haptics through HapticEffect GameplayCollision on hit, parry and guard break, with an option to turn it off. Button set and assist values are my judgment (unsourced). Check HapticEffect's production status before relying on it, since the DevForum post describes it as a Studio beta.

8. **Hit lag compensation and smooth knockback.** Under ping, hits that looked clean get rejected, which reads as "my sword went through him". Add server position history (every 0.05 to 0.1 s, about 2 s kept) and rewind targets by an estimated ping/2 when validating hits, per the DevForum rollback post. Keep WarpReachRecheck as a second check. For finisher knockback, play the push locally on the attacking client for instant feel and let the server confirm it, so the NPC doesn't stutter. The client-side knockback approach is my judgment (unsourced).

9. **Positional play: backstab and attack rebound.** Without these, circling an enemy earns nothing and swinging into a wall costs nothing. Add a backstab: a light attack inside a rear cone of about 60 degrees at close range plays a solo stab, which becomes the joint backstab only if the target is still in range, as in DS3. Give it critical damage below riposte. Add a recoil when a swing's blade hits world geometry before reaching an enemy: a short bounce animation, a spark and an opening for the enemy. The cone and the recoil are my judgment (unsourced). Elden Ring's Hardness rebound off guards is the sourced precedent for recoil.

10. **Damage numbers, crit cues and the accessibility settings pass.** Numbers make progress and crits readable in an MMORPG. Show numbers that can be toggled off, sized by Weight. Use one color for normal hits and another for crits or counters, and add an icon so the meaning doesn't depend on color, as in Monster Hunter World's numbers and XAG 103. In the same settings pass, add a screen shake slider, an option to turn off the impact frame or flash, hold or toggle for block, player key remapping, and a shape or icon on the riposte-open highlight. Exact options are my judgment (unsourced).

**Also missing, lower priority for feel:** a healing flask with a commit animation, status-effect buildup meters, lock-on and camera handling in tight spaces, and an InputBufferTime review (0.35 s against Smash's roughly 150 ms).
