---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - animation
  - vfx
  - roblox
---

Up: [[Claude]] · Used by: [[Weapon models and effects plan]]

Produced by a research agent on 2026-10-08 for Henry's request to research big anime Roblox games and fighting games so their animation and effects design can be replicated. Reproduced as the agent returned it, with headings adjusted. Claims marked unsourced or judgment are the agent's own calls.

Access note. Reddit was BLOCKED in this environment. WebFetch on reddit.com returned SITE_BLOCKED, direct HTTPS to reddit.com and old.reddit.com was refused by the egress proxy, a Redlib mirror was refused by robots.txt, and reddit-only web searches returned no Reddit results. So nothing in this report comes from Reddit. The Roblox DevForum WAS reachable and is the main forum source here. Most Fandom wikis (TSB, JJS, Type Soul, GPO, Deepwoken subpages) returned HTTP 402, so per-game data relies on guide sites and on the Deepwoken wiki pages that did load. YouTube was unreachable, so no devlog videos were reviewed.

Big caveat. None of the top studios (Yielding Arts/TSB, the JJS team, Type Soul, Deepwoken, Gamer Robot, GPO) has published a public breakdown of their animation pipeline or hitstop numbers that I could find. What exists is (a) player-facing mechanics on wikis and guide sites, (b) DevForum threads where other devs reverse-engineer these games, and (c) general tooling posts. I mark below which claims are observed or speculative.



## 1. PER-GAME FINDINGS

### The Strongest Battlegrounds (TSB, Yielding Arts)
- M1 chain is 4 hits. Hits 1-2 do 3% each, hit 3 does 4%, and hit 4 does 5% and launches. Holding M1 loops it. Jump plus click on the finisher gives an uppercut, and jump plus click gives a downslam that ignores block and pins into ragdoll. You can't downslam the same target twice in one ragdoll window. [games.gg TSB combat guide]
- Block (F) is front-only, attacks from behind always land, and some moves are unblockable. Ragdoll cancel by side or back dash has a 30 s cooldown. [games.gg]
- Community tech says 3 M1s then cancel into an ability, 4th M1 launches, and there is a 0.5 s no-stun window after getting up. Many techs are listed as "ping-based". [allthings.how burst guide; bloxodes tech catalog, 176 techs]
- Animation and VFX (observed by other devs, not confirmed by Yielding Arts): one VFX artist's breakdown says TSB ring effects are two cloned meshes named "Start" and "End" that the ability tweens between. That artist keyframed in Moon Animator, played the animation on both rigs at once, and drove a camera cutscene at a fixed 1/60 s step with FOV set per frame. [DevForum RUNUP VFX breakdown part 4]
- Impact frames. The DevForum cites a hand-drawn impact frame made for TSB's KJ character. Common recreations use ColorCorrection to black or white plus a Highlight recolor plus speed-line particles. [DevForum Advanced impact frames]
- Networking (speculation by a DevForum dev). TSB likely does not change network ownership on punches or ragdoll, only on grabs. Ragdoll state is probably set on the client, and knockback uses LinearVelocity or BodyVelocity. Swapping ownership on every hit causes snapback. [DevForum network ownership thread]
- Lunges that start fast and then slow down are built with LinearVelocity/BodyVelocity or an Out-eased tween. Root snapback is fixed with AlignPosition (community fixes, not confirmed TSB code). [DevForum smooth ability movement; snap back thread]

### Jujutsu Shenanigans (JJS)
- In March 2026 it had roughly 150k-263k concurrent players, in the top 10 overall. [rowatcher March 2026]
- Block is front-facing only. Neutral is decided by M1 trading and punishing endlag. Ragdoll cancel (Q while holding M1 toward the enemy) breaks stun, and if you miss it you eat the full combo. Each hit of a multi-hit grab restores your evasive. Mobility moves usually have no armor. [games.gg JJS guide]
- The DevForum shows devs copying its voxel destruction and its "camera follows head" option (CameraSubject set to Head, or a Humanoid.CameraOffset tied to head position, which can break shift-lock). [DevForum JJS camera thread; destruction thread]
- I could not source an exact M1 count or Black Flash timing. Search results for those were spam sites.

### Deepwoken (closest to Sword Bound's souls-like goal)
- Four swings end in a "Flourish" that launches the target away and has a little end-lag, so the chain ends itself. Parry has a 1.4 s cooldown. A successful parry resets that cooldown and gives brief auto-parry frames. Block only covers the front and raises posture instead of costing HP. When posture overflows, the next blocked hit guard-breaks and stuns. Feint has slight end-lag and briefly disables attacking. Rolls give i-frames, and roll-cancel grants an extra roll. Running attacks have more range and windup and extra end-lag. Some criticals give hyperarmor. The Shocked status adds 0.1 s hitstun. [Deepwoken wiki Combat Mechanics]
- Chip damage example is 75% through block, parried attacks don't chip, and guard break happens past 100% posture. One critical has a 0.25 s windup. [Deepwoken wiki Terminology]
- The parry window is "about 0.35 s" according to user answers only, so treat it as unverified. [Playbite Q&A]
- DevForum consensus is that Deepwoken's posture model comes from Sekiro and parrying restores posture. [DevForum What makes good combat]

### Gakuran (2025-26 breakout street-fighting "timing-based brawler")
- M1 chains up to 4, and the 4th is a finisher with extra knockback. M2 deals 1.7x an M1, is unblockable, and must be parried or dodged. Dodge has a very short cooldown with brief i-frames. Each blocked hit drains posture. A parry costs no damage, chip or posture and stuns the attacker. Guardbreak stuns for about 2 s. When both fighters use the same attack tier at nearly the same time, they clinch. Taller characters hit harder but swing slower. [allthings.how Gakuran guide]

### The Forge (2025-26 breakout melee PvE crafting game)
- Block (F, requires shift-lock) reduces damage but does not negate it, and holding it too long drains stamina. A perfect-timed F press is a parry that stuns the enemy. Light attack is LMB, heavy is R or RMB, dash is Q. [thespike.gg The Forge]

### Blox Fruits
- Each M1 staggers briefly, and whoever lands the last M1 starts the combo. Instinct auto-dodges about 6-9 attacks, and each M1 consumes one dodge. Combos are built as opener, extender, finisher. [bloxmeta PvP guide]

### Arcane Odyssey (Vetex)
- Block is a timed G press with no meter, and a well-timed block makes the enemy stumble. [ggrecon]
- The community debates "move-casting stun" (you are locked in place while casting), which gets worse with ping. Players defend it as the core risk/reward. [AO forum Combat Problem thread]

### Swordburst 3
- Weapon classes are sword, greatsword, katana, dual wield and scythe. Each weapon has its own skill tree, and you equip 4 skills. Greatsword is slow and you have to time hits. Multi-hit skills do less damage per hit. [primagames SB3 skill tree]
- I found no animation or hit-feel data.

### Combat Warriors (major Roblox melee PvP game, extra)
- The lead dev hired an R6 animator at $35/hr (or R$10K/hr). The job required Blender or other external software and asked for a "realistic/fluid" style. [DevForum hiring post, 2021]
- Parry is a held F that stuns the attacker for a few seconds and costs stamina. [progameguides]

No usable primary info found for: Type Soul (the guide only says the parry window is "very short"), Grand Piece Online, Rogue Lineage, Peroxide, Project Slayers, Anime Battlegrounds or Heroes Battlegrounds. Their wikis returned 402 and the search results were spam.

### SAO Echoes of Aincrad (the inspiration, released July 2026)
- Its weapons are sword and shield, dagger, rapier, mace, two-handed sword and two-handed axe, almost exactly Sword Bound's list. Attack, dodge and guard all draw from one stamina bar. Perfect guard, parry and dodge open punish windows. Sword Skills drain SP, and spamming them leaves you open. [allthings.how Echoes of Aincrad]



## 2. CROSS-GAME PATTERNS: TOOLS AND PIPELINE

- Authoring tools. Moon Animator 2 (a paid Creator Store plugin) and Blender dominate. For Blender, use Den_S's rig exporter/animation importer: export the rig as .obj, rebuild the armature, keyframe, then paste the data through "Load large animation". mrXen0o released a free R15 Blender 4.0+ rig with FK/IK switching in April 2025. [DevForum Den_S exporter; R15 FK/IK rig; MA2 alternatives thread]
- Moon does not export particles, parts or properties. Only Motor6D animation exports. Devs time VFX with animation markers (GetMarkerReachedSignal) and script it, or use tools like Moon VFX Exporter to replay part CFrame tweens. [DevForum Moon not exporting particles; Moon VFX Exporter]
- Animate in place and move the root with physics or tweens instead of baking travel into the clip. [same thread]
- Engine facts. Default Play and Stop fadeTime is 0.1 s. AdjustSpeed(0) freezes a track. Speed and TimePosition are tagged Not Replicated, so any hitstop done with AdjustSpeed has to run on every client. KeyframeReached is deprecated in favor of markers. [Roblox AnimationTrack API] Priorities run Idle 0, Movement 1, Action 2 through Action4 5, and Core 1000. [AnimationPriority enum]
- Animation Graphs went fully live on July 15, 2026. They offer Blend1D/2D, Select/Priority Select, Over/Add/Subtract layering, a Mask node for upper-body-only motion, and parameters set through AnimationTrack:SetParameter. Graphs replicate automatically. There is no marker-driven graph logic and no nested graphs yet. [DevForum Animation Graphs full release]
- Replication pattern. The client plays its own attack animation right away (server-side animations feel bad, and normal latency is about 0.2 s). [DevForum animations and replication] Hitboxes are detected on the client, and the server validates with a magnitude check plus an optional dot product. Avoid .Touched. [DevForum smooth out combat; Basics of Combat Games: Hitboxes] For VFX, the initiating client plays the effect immediately and the server relays it to the other clients only. Server-side VFX adds load and lag once 10+ players use moves together. [DevForum Client Replication 101 and replies]

## 3. VFX CONSTRUCTION

- Slashes are built two ways. One is a Blender mesh with Voronoi and gradient shaders rendered to a 4x4 sprite sheet, played as a one-shot ParticleEmitter flipbook. [DevForum animated slash effects in Blender] The other is mesh flipbooks, which cycle textures or mesh IDs by script since there is no native support. pewpewagent released an open-source pack in May 2025 that uses VortexFX. [DevForum mesh flipbook pack; What are mesh flipbooks]
- Stacked Beams with scrolling textures fake 3D meshes cheaply. Glass material plus a disabled Highlight gives a distortion sphere. [RUNUP part 4]
- Hit flash uses a white Highlight with FillTransparency tweened to 1 (the example uses 0.75 s). [DevForum flash white] Highlights don't work on mobile, so one ImpactFrame module uses Neon recolor plus ColorCorrection, with a default duration of 0.1 s. [DevForum ImpactFrame module]
- Camera shake. Devs use the EZ Camera Shake port, or a directional offset with jitter that decays. [DevForum camera shake for combat]
- Pricing (all old data, and I found no Talent Hub figures). One anime game paid $25-40 USD per VFX move in 2021. Combat animations went for R$2.5-3.5K each in 2019. [DevForum hiring and pricing posts] Many 2026 hiring posts are revenue-share only. [DevForum Jujutsu Annals 2026]

## 4. HITSTOP AND PARRY REFERENCE NUMBERS FROM OUTSIDE ROBLOX

- Guilty Gear Xrd hitstop by attack level is 11/12/13/14/15 frames at 60 fps, about 0.18-0.25 s. Counter hits go up to 27 frames. [Dustloop GGXrd Attack Attributes]
- Sakurai's rules for hitstop:
  - Attacker and victim freeze for the same duration.
  - Longer hitstop for bigger hits, with a cap.
  - Shorter hitstop in free-for-alls, because a third player can act during the freeze.
  - The victim shakes side to side on the ground and up and down in the air, and the shake decays.
  - The attacker creeps forward slightly during the freeze.
  - Hurtboxes stay still while the visuals shake.
  - Source: [Source Gaming Famitsu column; Nintendo Wire summary]
- In a VR sword study, the average "pleasant" hitstop was about 370-390 ms and discomfort started around 540-550 ms. That was single-player VR, so treat it as an upper bound. [Tomizawa and Ishikawa, VISIGRAPP 2024]
- Elden Ring parry active frames at 30 fps: most tools 6 frames (about 0.2 s), daggers 5, curved swords 4, Golden Parry 3. [Elden Ring wiki.gg Parrying]
- Sekiro deflect is 30 frames by default and drops to 7 frames if you released guard recently, which is the spam penalty. These are user-wiki numbers, so verify before relying on them. [Fextralife Sekiro Deflection]



## 5. WHAT SWORD BOUND SHOULD COPY (prioritized)

1. Play attacks on the owning client immediately, keep KeyframeSequence markers as the single source of timing, and validate on the server. The HitStart, HitEnd and CancelOpen markers are already the right design. Drive hitbox windows, VFX spawns and SFX from GetMarkerReachedSignal. Do not use KeyframeReached. [AnimationTrack API; Moon export thread]
2. Run hitstop per client. Broadcast the hit event, and each client sets AdjustSpeed(0) on both the attacker and victim tracks, then restores speed. Speed is not replicated, so this can't be done once on the server. [AnimationTrack API] Suggested durations (unsourced, judgment, scaled down from GG's 0.18-0.25 s and Sakurai's FFA advice):
   - dagger 0.04-0.06 s
   - sword and rapier 0.06-0.08 s
   - 2H sword and axe 0.10-0.14 s
   - parry or deflect 0.12-0.18 s
   - cap 0.2 s
   - shorten it when more than 2 players are in the fight
3. Use Sakurai's victim shake. Shake the victim's visual (not the hitbox) side to side, decaying over the hitstop, and let the attacker creep forward slightly. [Sakurai column]
4. Stack these at the HitStart marker, all on the client:
   - white Highlight flash for about 0.08-0.12 s (judgment, since the 0.75 s example is too long), with a Neon fallback on mobile [ImpactFrame module]
   - short directional camera shake toward the hit [camera shake thread]
   - mesh slash or flipbook slash [slash and flipbook threads]
   - 2-3 layered SFX (judgment)
   - Save ColorCorrection impact frames (0.1 s default) for parries, guard breaks and finishers only, not every hit (judgment).
5. Use a Deepwoken-style defensive kit:
   - front-only block that fills posture
   - posture break into a stun
   - parry on a 1.4 s cooldown that resets on success
   - feint with end-lag
   - roll with i-frames
   - 4-hit chains where the last hit pushes the target away so the chain ends itself
   - Source: [Deepwoken wiki]
6. Parry window: aim for a 0.2-0.3 s client-timestamped window. That is wider than Elden Ring's 0.13-0.2 s to absorb the ~0.2 s Roblox latency, plus a Sekiro-style shrink when the button is spammed (judgment, built on [Elden Ring wiki.gg; DevForum replication; Fextralife Sekiro]).
7. M1 chain lengths by weapon (judgment), with an input buffer from CancelOpen:
   - dagger 4-5 hits
   - sword and rapier 3-4 hits
   - 2H weapons 2-3 hits
   - For reference, battlegrounds-genre default timings are about 0.4 s between hits, 1.5 s before the combo resets and 2 s cooldown after the finisher. [DevForum Battleground Modulepack defaults]
8. Root motion. Animate in place, drive lunges with LinearVelocity on the owning client, and use AlignPosition to avoid snapback. Don't swap network ownership on every hit. [DevForum TSB threads]
9. Use Animation Graphs for locomotion and guard stance (Mask node for upper-body guard while walking). Keep attack clips as directly loaded tracks, because graphs lack marker-driven logic. [Animation Graphs release]
10. Pipeline for hand polish. Move from code-built keyframes to Blender with the R15 FK/IK rig and Den_S importer, or to Moon Animator 2. In either case, re-add markers in Studio after import. [R15 rig; Den_S exporter]
11. Follow the Echoes of Aincrad structure:
   - one stamina bar shared by attack, dodge and guard
   - Sword Skills as SP-costly commits that leave you open
   - perfect guard, parry and dodge as punish openers
   - Source: [allthings.how EoA]

AVOID for a souls-like (judgment unless cited):
- ragdoll juggles, uppercut and downslam loops, and wall combos (TSB/JJS)
- 4-hit true stun-locks that only end through a 30 s ragdoll-cancel meta [games.gg TSB]
- M1-trading neutral where whoever lands last wins [bloxmeta; games.gg JJS]
- unblockable M1s
- infinite-stagger instinct systems
- long cinematic impact frames on normal hits
- server-side VFX
- ragdoll as the default hit reaction (use authored stagger clips, and keep ragdoll for death or guard-break finishers)



## Sources
- <https://games.gg/roblox/guides/the-strongest-battlegrounds-combat-guide/>
- <https://allthings.how/how-to-do-burst-damage-in-the-strongest-battlegrounds/>
- <https://bloxodes.com/wiki/the-strongest-battlegrounds/techniques>
- <https://devforum.roblox.com/t/runup-vfx-breakdown-part-4/3669430>
- <https://devforum.roblox.com/t/advanced-impact-frames/2468478>
- <https://devforum.roblox.com/t/unsolved-combat-system-network-ownership-problem/3217564>
- <https://devforum.roblox.com/t/smooth-ability-movement-like-the-strongest-battlegrounds/3022755>
- <https://devforum.roblox.com/t/how-can-i-make-that-the-animations-dont-snap-back-to-the-original-pos-like-the-strongest-battlegrounds/2530158>
- <https://rowatcher.com/news/top-10-roblox-games-by-players-march-2026-data-breakdown>
- <https://games.gg/roblox/guides/jujutsu-shenanigans-beginners-guide/>
- <https://devforum.roblox.com/t/jujutsu-shenanigans-jjs-camera-follow-head-how/4153881>
- <https://devforum.roblox.com/t/how-could-i-make-destruction-like-jujutsu-shenanigans-or-realm-rampage/3127398>
- <https://deepwoken.fandom.com/wiki/Combat_Mechanics>
- <https://deepwoken.fandom.com/wiki/Terminology_(game)>
- <https://www.playbite.com/q/how-long-is-the-deepwoken-parry-window>
- <https://devforum.roblox.com/t/what-makes-good-combat/1999076>
- <https://allthings.how/gakuran-combat-system-guide-all-mechanics-explained/>
- <https://www.thespike.gg/roblox/the-forge/how-to-block-and-parry>
- <https://bloxmeta.gg/games/blox-fruits/guides/pvp-combat-guide>
- <https://www.ggrecon.com/guides/arcane-odyssey-block>
- <https://forum.arcaneodyssey.dev/t/arcane-odysseys-combat-problem/97410>
- <https://primagames.com/?p=326318>
- <https://itemlevel.net/type-soul-complete-combat-guide/>
- <https://devforum.roblox.com/t/35hr-or-r10khr-looking-for-r6-animator-for-combat-warriors/1398374>
- <https://progameguides.com/roblox/how-to-parry-in-combat-warriors-roblox/>
- <https://allthings.how/how-combat-weapons-and-leveling-work-in-echoes-of-aincrad/>
- <https://devforum.roblox.com/t/blender-rig-exporteranimation-importer/34729>
- <https://devforum.roblox.com/t/r15-rig-for-blender-40-fkik-switching/3606878>
- <https://devforum.roblox.com/t/any-alternatives-to-ma2-moon-animator-2/4770365>
- <https://devforum.roblox.com/t/moon-animator-not-exporting-particle-or-impact-frame-effect/2927891>
- <https://devforum.roblox.com/t/moon-vfx-exporter-export-animations-that-cannot-be-exported-from-moon-animator/1787797>
- <https://create.roblox.com/docs/reference/engine/classes/AnimationTrack>
- <https://create.roblox.com/docs/reference/engine/enums/AnimationPriority>
- <https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840>
- <https://devforum.roblox.com/t/questions-regarding-animations-and-replication/2737956>
- <https://devforum.roblox.com/t/how-can-you-smooth-out-combat/3394308>
- <https://devforum.roblox.com/t/the-basics-of-combat-games-hitboxes/3002930>
- <https://devforum.roblox.com/t/client-replication-101-the-guide-to-replicating-effects-to-clients/1789487>
- <https://devforum.roblox.com/t/how-to-make-animated-slash-effects-with-only-blender/1794034>
- <https://devforum.roblox.com/t/open-source-mesh-flipbook-pack/3635032>
- <https://devforum.roblox.com/t/what-are-mesh-flipbooks/2656999>
- <https://devforum.roblox.com/t/how-could-i-make-the-player-flash-white/2608914>
- <https://devforum.roblox.com/t/open-source-impactframe-module/2963136>
- <https://devforum.roblox.com/t/camera-shake-for-combat/2317381>
- <https://devforum.roblox.com/t/battleground-modulepack-ragdoll-stun-direction-cooldown/3488881>
- <https://devforum.roblox.com/t/how-to-implement-hitstop/2133285>
- <https://devforum.roblox.com/t/25-40-usd-per-move-hiring-fx-ability-maker/1457972>
- <https://devforum.roblox.com/t/how-should-i-price-my-animations/228161>
- <https://devforum.roblox.com/t/jujutsu-annals-looking-for-a-vfx-artist-animator/4710007>
- <https://dustloop.com/w/GGXRD/Attack_Attributes>
- <https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/>
- <https://nintendowire.com/news/2022/12/12/this-week-in-sakurai-12-5-12-11-fine-tuning-hit-stop-and-cheating-the-system/>
- <https://www.scitepress.org/Papers/2024/124614/124614.pdf>
- <https://eldenring.wiki.gg/wiki/Parrying>
- <https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection>
