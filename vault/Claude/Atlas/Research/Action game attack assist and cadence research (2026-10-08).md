---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - combat
  - sword-skills
---

Up: [[Claude]] · Used by: [[Sword combat feel revision]]

Produced by a research agent on 2026-10-08 after Henry said basic sword combat doesn't feel fun yet and asked for end-to-end research (Reddit, X, Discord and forums). Attack magnetism, light attack timing, running attacks and SAO game sword skills. Reproduced as the agent returned it. Claims marked unsourced are the agent's own calls.

Research for Sword Bound on three questions: how light attacks pull the player to the enemy, how fast and cancelable light attacks are, and how SAO games fit sword skills around basic attacks. It builds on the vault notes "Melee animation and slash VFX craft research (2026-10-08)", "Core fighting fundamentals research (2026-10-06)" and "Combat and movement research (2026-09)", and does not repeat their hitstop, VFX and roll findings.

Frame counts are at 60 fps unless a source says otherwise (1 frame is about 16.7 ms). Every factual claim has an inline URL. Anything without a URL is marked "(unsourced)".

## Source access log

- Reddit was blocked. A WebFetch of reddit.com returned SITE_BLOCKED, and WebSearch with a reddit.com domain filter returned HTTP 400 from the proxy. Plain "site:reddit.com" queries returned no reddit.com results at all. Per instructions I did not try mirrors, so this report has no Reddit content.
- X/Twitter was partly reachable. Fetching x.com returned ROBOTS_DISALLOWED. WebSearch with an x.com/twitter.com domain filter did work and returned post snippets, but they were animators showing off sword animations with no numbers or design reasoning, so none are cited. "site:x.com" queries returned no x.com results.
- Discord content did not surface. The only Discord result was a public server listing page for an SAO Progressive community (https://discord.com/servers/yoitsu-sao-progressive-846075078772391986), which has no message content. Discord is not publicly indexed.
- Other blocks: a bot wall (Anubis) blocked the breezewiki mirror of the DMC wiki, so I used the fandom page directly. The GitHub API refused the Elden Ring frame data repo and the TrueDirectionalMovement repo for this session, and GitHub tree pages were robots-disallowed. swordartonline.fandom.com/wiki/Sword_Skill errored, but /wiki/Sword_Skills loaded.
- The shared search budget (200 WebSearch calls per turn) ran out partway through Topic C. Hollow Realization's Skill Connect timing, Integral Factor details and Fatal Bullet melee details could not be searched further. A follow-up message can continue those.
- Steam Community and smaller forums (No Rest for the Wicked, Substack comments) stand in for the missing Reddit pass.

## Topic A: attack magnetism, target assist and motion warping

### What the studios say

**God of War (2018).** Mihir Sheth's GDC 2019 talk "Evolving Combat in God of War for a New Perspective" (https://gdcvault.com/play/1026085/Evolving-Combat-in-God-of) is the most direct source I found. These points come from an AI-generated summary of the talk video (https://videohighlight.com/v/hE5tWF-Ou2k), so check them against the video before quoting them as fact:
- The left stick drives target choice. "Kratos will attack directly forward if no targets are available." Off-screen enemies cannot be targeted.
- An old feature called "suck to target" was brought back. It moves Kratos based on range and distance, and suction shrinks as the angle between Kratos and the target widens. The goal was fewer whiffs on side enemies. No distances or angles are given.
- "Kratos' attacks automatically orient towards any selected target."
- Lock-on was added late, after playtests asked for it, and reuses the melee targets. Players flick the right stick to switch targets.
- "Strike assist" turns hit enemies to face the camera's direction so they stay on screen. Enemy knockback was reduced so Kratos can keep up with them.
- Only two enemies could be aggressive at once.

Separately, Naughty Dog's Christian Wohlwend says God of War's hitstop "pops the target into the hit pose" and holds both characters on that first frame (https://blog.playstation.com/?p=370399).

**God of War cancel rules.** Eric Williams, a former God of War lead combat designer, wrote that "God of War allows almost all of the basic attacks be canceled anywhere, including Pre-hit frame." In his list of cancels out of a Square attack, roll, jump, guard, magic and throw are pre-hit, while walk and weapon swap are post-hit only (https://www.gamedeveloper.com/pc/combat-canceled-i-god-of-war-i-action-game-design). Kratos had "roughly 4000 cancel branches" in God of War 2 (same URL).

**Ghost of Tsushima.** There is no lock-on on purpose. Nate Fox: "If we had a lock-on you wouldn't have been able to move as quickly between the different opponents as they came in at you" (https://www.gamespot.com/articles/why-ghost-of-tsushima-doesnt-have-a-lockon-mechani/1100-6479890). I found no source on how its attacks pick targets. The GDC talk "Honoring the Blade" covers lethality and balance, not targeting (https://gdcvault.com/play/1027184/Honoring-the-Blade-Lethality-and).

**Batman Arkham freeflow.** Rocksteady's public material describes the feel but not the mechanism. Sefton Hill says it began as a rhythm game and was built to make the player feel like a master of hand-to-hand combat, with combos not limited by animations or button sequences (https://www.vidaextra.com/industria/conocemos-como-combate-batman-arkham-assassins-creed-quien-invento-realmente). Tilting the stick toward a goon and pressing strike vaults Batman across the room to him (https://episodiccontentmag.com/2016/03/11/batmanaa_chapter3/). For the mechanism I only have recreations:
- A freeflow prototype casts a sphere in the stick direction and targets what it hits. If nothing is hit, it picks the enemy closest to the end of the cast. With no stick input, it picks the enemy closest to the player (https://kennywei.myportfolio.com/combat-prototypes).
- A UE5 student recreation chose targets with a dot product of facing/movement against the enemy direction, used motion warping because it was "Smoother than teleporting," and chose the attack by distance: "a quick jab up close, a sobat kick at mid-range, or a butterfly kick when further away" (https://www.therookies.co/blog/breakdowns/building-a-cinematic-combat-system-in-unreal-engine-5, https://gradex.staffs.ac.uk/wp-content/uploads/2025/05/5244_Jonny-Renaut-Development-Report.pdf). Neither gives distances.

**Marvel's Spider-Man.** The only GDC talk I reached is the AI postmortem (https://gdcvault.com/play/1025828/-Marvel-s-Spider-Man). It does not cover player targeting, so I have no sourced targeting facts for Spider-Man.

**Assassin's Creed.** Ashraf Ismail's Origins Q&A, as summarized by PCGamesN, says Origins moved to "hitbox-based combat instead of animation-based combat," so "whenever you hit attack in Origins you just swing your weapon," instead of attacker and victim aligning into a paired animation (https://pcgamesn.com/assassins-creed-origins/assassins-creed-origins-game-director-breaks-down-combat-changes). Valhalla lets you evade between attacks, for example heavy, evade, light (https://assassinscreedvalhalla.wiki.fextralife.com/Combat). I found nothing on Ubisoft's magnetism values.

**Elden Ring lock-on.** A UX writer's playtest notes (not official) say lock-on prefers enemies in the character's frontal cone, then the camera view, then the closest, and ignores off-camera enemies unless they are in the cone (https://uxdesign.cc/improving-elden-rings-lock-on-experience-3207035bea28). I found no source for how much Elden Ring, Sekiro or Lies of P let the player turn during windup. Lies of P players say attacks lock them in a few frames longer than Souls games before a dodge comes out (https://jmargaris.substack.com/p/dodging-in-the-lies-of-p-demo-kinda/comments). That is a commenter's impression, not data.

**Wuthering Waves.** Lock-on (middle mouse or R3) grabs "the closest enemy" (https://primagames.com/gaming/how-to-lock-on-counterattack-parry-and-dodge-in-wuthering-waves). How unlocked basic attacks pick targets is not in that source.

**Genshin, Zenless Zone Zero, Honkai Impact 3rd, NieR Automata, Bayonetta, Stellar Blade, DMC5.** I found no published numbers on how their basic attacks home in. What I did find is in Topic B.

### Numbers I could find

| Source | Value | URL |
|---|---|---|
| THE FINALS, old melee | regular attacks pulled you "up to around 3m" to an in-range target | https://www.reachthefinals.com/patchnotes/s11-melee-rework |
| THE FINALS, Season 11 rework | lunge "averages around 4.5m but varies from weapon to weapon", gated by a stamina bar that refills in "around two seconds" or instantly on a precise hit | same |
| True Directional Movement (Skyrim mod) | melee magnetism angle 60 degrees | https://github.com/ersh1/TrueDirectionalMovement/blob/master/src/Settings.h |
| True Directional Movement | attack rotation speed multiplier: windup 5x, mid 1x, after the swing 0x | same |
| True Directional Movement | the mod disables rotation after the swing "to enforce attack commitment" but lets you rotate quickly during windup | https://www.nexusmods.com/skyrimspecialedition/mods/51614 |
| Unreal Motion Warping | `WarpMaxRotationRate` is a "Maximum rotation rate in degrees/sec", also used as the constant rate | https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/MotionWarping/URootMotionModifier_Warp |
| Roblox units | 1 stud = 28 cm | https://create.roblox.com/docs/physics/units |

THE FINALS is a first-person game and TDM is a mod, so treat both as reference points, not AAA third-person values.

### How Unreal Motion Warping does it

Epic's docs describe it as a notify window placed in the attack montage, ending at the strike frame, plus a named warp target that gameplay code sets to the enemy's position each attack (https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-warping-in-unreal-engine):
- Skew Warp bends the animation's own root motion so it ends at the target's location and rotation by the end of the window. Scale just scales the root motion.
- Rotation Type "Facing" turns the character to face the target. Warp Rotation Time Multiplier speeds up the turn, so 0.5 on a 2 s window finishes turning in 1 s.
- Ignore Z Axis keeps vertical motion untouched.
- The API adds rotation methods (Slerp, ConstantRate, Scale) and `bWarpToFeetLocation` (https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/MotionWarping/URootMotionModifier_Warp).

The key idea is that the animation's authored step is stretched or shrunk to fit the real gap, so the feet and body stay in sync with the travel. The engine docs give no recommended maximum warp distance.

## Topic B: light attack cadence, cancels, buffers and dash attacks

### Light attack timing

| Game and move | Startup (to first hit) | Time to next attack | Source |
|---|---|---|---|
| Genshin, Keqing (sword) N1 | 10 f (167 ms) | 15 f (250 ms) | https://library.keqingmains.com/characters/electro/keqing |
| Genshin, Keqing N2 | 10 f | 22 f (367 ms) | same |
| Genshin, Keqing N3 | 14 f | 35 f (583 ms) | same |
| Genshin, Kaeya (sword) N1 | 14 f (233 ms) | 27 f (450 ms) | https://library.keqingmains.com/characters/cryo/kaeya |
| Genshin, Kaeya N2 | 9 f (150 ms) | 27 f | same |
| Genshin, Kaeya N5 (finisher) | 30 f (500 ms) | 74 f | same |
| Elden Ring straight sword 1h R1-1 | active 0.43 to 0.53 s | next attack 0.57 s, roll 0.80 s, free move 0.97 s | vault note "Combat and movement research (2026-09)", from https://github.com/sovietspaceship/elden-ring-frame-data-explorer-data |
| SF6 Ryu standing light punch | 4 f | 7 f recovery | vault note "Melee animation and slash VFX craft research", from https://ultimateframedata.com/sf6/ryu |

KQM measures at 60 fps with macros, says to add about 10 frames per attack for human error, and reports about 2 frames of input lag (https://library.keqingmains.com/combat-mechanics/frames). Genshin sword N1 and N2 hitlag is 0.03 s (same URL).

I could not find sourced frame data for God of War, DMC5, Bayonetta, NieR, Stellar Blade, ZZZ, Wuthering Waves, Honkai Impact 3rd, Sekiro or Lies of P light attacks. The DMC5 Chinese wiki lists inputs and damage only (https://wiki.biligame.com/dmc5/Rebellion%26Devil_Sword_Sparda). I did not make any up.

### Cancel windows

- Genshin: most normal attacks can be cancelled by Skill, Burst, dash, jump or swap, and the earliest cancel can land on the same frame as the hit. Dash takes about 20 frames and jump about 30 (https://library.keqingmains.com/combat-mechanics/frames).
- God of War: basic attacks can roll, jump or guard even before the hit, and walking only after it (https://www.gamedeveloper.com/pc/combat-canceled-i-god-of-war-i-action-game-design).
- DMC: "all Melee attacks are all Post-hit frame cancels." Ninja Gaiden allows no pre-hit cancels at all (same URL).
- NieR Automata: Takahisa Taura says Platinum tunes cancel timing a bit faster or slower to fix attacks that drag, and that in NieR "these sorts of cancel triggers are everywhere so actions become cancellable all the time." That wording is the article writer's paraphrase (https://siliconera.com/?p=781429).
- Bayonetta's Dodge Offset: hold the attack button while dodging, and after the dodge the combo continues from where it was (https://bayonetta.fandom.com/wiki/Dodge_Offset).
- Assassin's Creed Valhalla lets you evade mid-combo, for example heavy, evade, light (https://assassinscreedvalhalla.wiki.fextralife.com/Combat).
- Stellar Blade: director Hyung-tae Kim says the perfect parry and dodge skills have "about a 0.5 second lag" between the press and the visible move. He says this is deliberate because instant movement "would not fit the game's style of animation" (https://automaton-media.com/en/news/stellar-blade-director-explains-games-0-5-second-lag-when-doing-perfect-parries-or-dodging/). Players noticed it and called it input lag, which shows that a visible delay reads as unresponsive even when it is designed in.
- Honkai Impact 3rd: evade has about a 1 s cooldown and about 0.8 s of i-frames, and a perfect evade gives a 0.2 s slowdown (https://houkai3rd.fandom.com/wiki/Combat_system?oldid=8887).

### Input buffering

- Eric Williams separates a "Buffer" cancel, which stores the input until the window opens, from an "Instant" cancel, which only accepts the input while the window is open. He says that in a well-designed game, other commands can override a buffered one before the window opens (https://www.gamedeveloper.com/pc/combat-canceled-i-god-of-war-i-action-game-design).
- Smash Bros: 10 frames in Brawl and Smash 4, and 9 frames in Ultimate. Buffered inputs firing after the character has moved, for example a jab near the ledge turning into an aerial, are a known problem, and worse online (https://www.ssbwiki.com/Buffer).
- King of Fighters XV buffers special-move motions 5 to 8 frames into a normal (https://dgmiwiki.wpi.edu/mechanic/input_buffer).
- Elden Ring players report that a dodge pressed before being hit still comes out afterward, and that Souls inputs fire on button release (https://steamcommunity.com/app/1245620/discussions/0/4361250968410661652). This is player testimony with no frame count.
- No Rest for the Wicked players complain that the buffer queues an extra attack or roll after a knockdown or near ledges, and ask for it to clear within "under a second" (https://forum.norestforthewicked.com/t/combat-input-buffering-queuing-issues/25029).

### How dash and running attacks are made distinct

- Elden Ring's official guide says attacking during a run "triggers a different attack," "sometimes with additional range or faster execution." Backsteps, jumps and crouches also change the next attack (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide).
- DMC Stinger is lock-on plus forward plus attack. In DMC1 it is a long dash that "ends early if it contacts a targeted enemy," and next to an enemy it becomes an instant thrust. DMC2's version was only a one-step lunge (https://devilmaycry.fandom.com/wiki/Stinger). In DMC5, upgrading Stinger only lengthens the lunge (https://wiki.biligame.com/dmc5/Rebellion%26Devil_Sword_Sparda).
- Zenless Zone Zero: pressing basic attack during a dodge gives a Dash Attack. A basic attack after a perfect dodge gives a Dodge Counter with heavy-attack effect (https://mobalytics.gg/blog/zenless-zone-zero/zzz-combat-guide/).
- Wuthering Waves: a basic attack right after a successful dodge becomes a Dodge Counter that deals extra damage (https://wutheringwaves.fandom.com/wiki/Dodge).
- Stellar Blade: holding the heavy button gives Rush, a forward dash attack with a short cooldown. Some combos include "dashes that close on fleeing enemies" (https://www.playstation.com/en-us/editorial/stellar-blade-beginners-guide-to-combat).
- Monster Hunter Wilds Sword and Shield: basic combo attacks move the hunter "if a direction is added to its regular input" (https://monsterhunterwiki.org/wiki/MHWilds/Sword_and_Shield_Mechanics). I found no sourced Monster Hunter sprint attack frame data.
- Genshin: I found no sourced generic sprint attack. Its dash is mainly a cancel tool (https://library.keqingmains.com/combat-mechanics/frames).

In every case above, the dash or running attack has its own animation and its own job (closing distance, a thrust, a counter). None reuses the standing slash's arc.

## Topic C: sword skills in SAO games

### Canon rules the games build on

- A skill starts from a set pre-motion stance. The system recognizes it, lights the weapon in the skill's color, and completes the move faster and stronger than a normal swing (https://swordartonline.fandom.com/wiki/Sword_Skills, https://otakumode.com/otapedia/anime/sword_art_online/sword_skills_sao).
- After the skill, the user is rigid and "made vulnerable to any counter-attacks," and "The higher the level of the Sword Skill used, the longer the «Post-Motion» period is." The used skill then goes on cooldown, but other skills stay available (https://swordartonline.fandom.com/wiki/Sword_Skills).
- A VS Battles forum post claims the delay varies with hit count, and that Kirito's Skill Connect, alternating one-hand skills between hands, cancels the first skill's delay. It cites no light novel passage, so treat it as fan interpretation (https://www.vsbattles.com/threads/revisions-for-kirito.29724/post-942680).

### By game

**Hollow Fragment (2014).**
- Skills have cooldowns. A purple light around Kirito marks a chain window, and a skill used inside it skips the cooldown, so SP is the only limit (https://gematsu.com/2014/03/sword-art-online-hollow-fragment-dates-pseudo-multiplayer-oss-system-more-detailed).
- A well-timed Burst Attack triggers a "Just Attack" at maximum power (same URL).
- Kotaku: skills moved from a pop-up menu to "three sets of button shortcuts" (12 equipped), and the burst gauge "does wonders to speed up" battles. Kotaku still called the battle speed "ponderously, painfully slow" and the trash fights "some of the most boring, monotonous gameplay." Players "mash the burst attack button while you wait for your SP" (https://kotaku.com/the-sword-art-online-game-is-a-boring-slog-unless-you-1578870666).

**Hollow Realization (2016).**
- It builds on Hollow Fragment with four-person parties and a Switch system for chain attacks (https://en.wikipedia.org/wiki/Sword_Art_Online:_Hollow_Realization).
- IGN praised "satisfying, nuanced combat" but criticized "opaque systems." Destructoid called it "mechanically satisfying" (same URL).
- One example skill, Nebula Onslaught (dual wield), costs 300 SP for 22 hits (https://steamcommunity.com/app/607890/discussions/0/1692659769947736348/?ctp=4).
- Its Skill Connect timing could not be researched further because the search budget ran out.

**Lost Song (2015).**
- Regular attacks combo and link into heavy attacks and sword skills. Heavy attacks are finishers. Sword skills only work with the weapon drawn, and magic only with it sheathed. Step and dash use stamina (https://www.siliconera.com/sword-art-online-lost-song-shares-details-on-how-to-fight/).
- GameRevolution liked the "smooth controls, smartly-mapped buttons" and moving smoothly between physical and magic attacks, but found the battles repetitive (https://www.gamerevolution.com/review/69547-sword-art-online-lost-song-review).

**Fatal Bullet (2018).** It is gun-focused, with Kirito's photon sword as a weapon option (https://en.wikipedia.org/wiki/Sword_Art_Online:_Fatal_Bullet). I found no sourced detail on its melee skills.

**Integral Factor (mobile).** Sword skills activate after their cooldown ends. Players equip up to four and chain them with other players in quick succession, which the game calls a Switch (https://en.wikipedia.org/wiki/Sword_Art_Online:_Integral_Factor).

**Alicization Lycoris (2020).**
- Skills go on the four face buttons and fire with RB plus a face button. Most cost 100 SP, which is one of three bars, and normal attacks generate SP. A skill set as "combo finish" fires at the end of a normal combo for 0 SP (https://primagames.com/?p=313680).
- Skill connect: a "flashing star" cue opens a window for a second skill. The Essence of the Blade passive adds an extra second. Skills that take long to land, like Vorpal Strike, are bad for connects (same URL).

**Last Recollection (2023, not on the list but the closest predecessor to Echoes).**
- R1 opens the skill palette. Finisher skills fire at the end of the normal combo and "do not consume any SP." A normal combo can branch into 3 preset skills in a row (https://bandainamcoent.com/news/sword-art-online-last-recollection-101-guide).
- Skill Connect: input the next skill "at the timing of a light blue flash" to cancel the current skill's follow-through. Connects must go from lower to higher priority. Skill Connect EX ignores priority but has a cap, and a failed input shows "a black light" (same URL).
- Players say the base is 3 extra connects, raised to about 6 with passives (https://steamcommunity.com/app/1566880/discussions/0/3879345465238799262).
- Siliconera called Skill Connect "the star of the show" and "incredibly addicting" (https://www.siliconera.com/review-sword-art-online-last-recollection-is-a-fun-action-rpg-mmo-hybrid/).
- A demo player summed up the loop as "spam autos to fill bar then self cast skills into partner skills into party q pretty simple" (Steam thread above). The earlier vault note found players struggled to see the blue window (https://steamcommunity.com/app/1566880/discussions/0/3879345097432704041).

**Echoes of Aincrad (2026).**
- Made by Game Studio Inc and published by Bandai Namco. Launched July 10 on PS5, Xbox Series X|S and PC (https://checkpointgaming.net/features/2026/06/echoes-of-aincrad-hands-on-preview-that-time-i-got-transported-into-a-video-game-again/).
- It is melee only, with six weapon types and no dual wield (https://onemoregame.ph/?p=149265).
- SP is separate from stamina and refilled by landing basic attacks. Up to three skills are equipped, each with a cooldown. There is no dedicated chain input or cue, and skills hit hardest when used to extend a combo after a Parry Slash or Dodge Slash. Each slot is a tradeoff between a gap-closer and a slow, high-damage finisher (https://thegameswiki.com/echoes-of-aincrad/wiki/sword-skills).
- Basic attacks cost stamina (https://gamingtrend.com/reviews/echoes-of-aincrad-review/).
- A blue ring on an enemy attack marks a "reversal slash." The preview found skills cheap in SP with fast cooldowns (Checkpoint URL above).
- Reception:
  - GamingTrend scored it 60 and called combat "the best part of the package": "You can't mash your best move into a boss until the bar empties; you actually have to read the fight" (https://gamingtrend.com/reviews/echoes-of-aincrad-review/).
  - One More Game gave it 6/10 and said "Combat often feels repetitive," with rigid enemy AI (https://onemoregame.ph/?p=149265).
  - RPG Site's preview wanted it "a bit heavier" and said it "lacks the visual impact I was hoping for" (https://www.rpgsite.net/preview/20538-echoes-of-aincrad-pc-hands-on-preview-port-steam-deck-rog-ally).

### Patterns across SAO games

- Basic hits build SP and skills spend it (Lycoris, Echoes).
- A free skill at the end of the basic string is the bridge from M1 to skills (Lycoris, Last Recollection).
- Chaining needs a visible window cue: a purple aura in Hollow Fragment, a flashing star in Lycoris, a light blue flash in Last Recollection.
- What players liked: Skill Connect (Last Recollection) and reading the fight before spending skills (Echoes).
- What players disliked: slow fights where you mash while waiting for SP (Hollow Fragment), a loop of spamming autos to fill the bar (Last Recollection), repetitive fights (Lost Song, Echoes) and weak visual impact (Echoes preview).

## What this means for Sword Bound

### 1. Lunge and magnetism (the biggest gap)

Brief: the lunge is a fixed ~2 studs (4.4 for the running attack), it only steers within 8 studs and a 60 degree cone, it stops 3.2 studs short, reach is 7 studs, and there is no soft rotation when not locked on.

- **Our 60 degree cone matches the TDM default exactly** (https://github.com/ersh1/TrueDirectionalMovement/blob/master/src/Settings.h). The cone is fine. Distance and rotation are what is missing.
- **Our 2 studs is far less pull than the references.** 2 studs is 0.56 m by Roblox's unit (https://create.roblox.com/docs/physics/units). THE FINALS pulled "up to around 3m" before its rework and about 4.5 m after (https://www.reachthefinals.com/patchnotes/s11-melee-rework). Roblox characters are smaller than real people, so scaling by body height is fairer. If a 5-stud R15 character stands for about a 1.8 m human, 3 m is about 8 studs and 4.5 m about 12.5 studs (unsourced, the 1.8 m and 5-stud heights are my assumptions).
- **Make the lunge fit the gap.** Today it is a fixed distance with an 8-stud gate. Do what Motion Warping does and compute the travel as distance to target minus the stop distance, clamped to a per-attack maximum. Then the same animation closes 0.5 studs or 5 studs and always ends at striking range (https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-warping-in-unreal-engine). Starting values: acquire radius 12 studs, max warp 5 studs for Light1 and Light2, 3 for Light3 and 9 for the running attack, and stop at about 4 to 4.5 studs so the 7-stud blade lands mid-blade (unsourced, starting values to playtest).
- **Shrink the pull for enemies off to the side,** as God of War does (https://videohighlight.com/v/hE5tWF-Ou2k). For example, full warp distance at 0 degrees falling to 40% at 60 degrees (unsourced numbers).
- **Add soft rotation when not locked on.** Turn fast toward the chosen target during startup, slower during the active frames, and not at all after HitEnd, following TDM's 5x, 1x, 0x pattern (https://github.com/ersh1/TrueDirectionalMovement/blob/master/src/Settings.h). That keeps commitment while removing whiffs. On Roblox this can be an AlignOrientation on the HumanoidRootPart with its MaxAngularVelocity set per phase (property list at https://create.roblox.com/docs/reference/engine/classes/AlignOrientation; per-phase numbers unsourced). For example, 720 degrees/s in startup, 180 in active and 0 after (unsourced).
- **Pick the target like freeflow recreations do:** cast in the stick or move-input direction first. If that misses, take the enemy nearest the end of the cast. With no input, take the nearest enemy. Skip enemies that are off-screen (https://kennywei.myportfolio.com/combat-prototypes, https://videohighlight.com/v/hE5tWF-Ou2k).
- **Keep explicit lock-on optional.** Ghost of Tsushima left it out so players could flow between enemies (https://www.gamespot.com/articles/why-ghost-of-tsushima-doesnt-have-a-lockon-mechani/1100-6479890). God of War added it late because playtesters asked (https://videohighlight.com/v/hE5tWF-Ou2k). Sword Bound already makes F lock-on opt-in, which fits.
- **Fix the foot slide.** The prior vault note found the lunge slides with planted feet. Once the travel distance varies, author the attack with a real forward step and scale the root velocity to the warp distance, so the step and the travel match (unsourced, judgment).

### 2. Cadence

| | Startup | Hit to next hit |
|---|---|---|
| Sword Bound Light1/2 | 260 ms (about 16 f) | 500 ms |
| Sword Bound Light3 | 340 ms | 640 ms |
| Genshin Keqing N1 | 167 ms | 250 ms |
| Genshin Kaeya N1 | 233 ms | 450 ms |
| Elden Ring straight sword R1-1 | about 430 ms to active | 570 ms |

Sources are in the Topic B table.

- **Our hit-to-hit pace is already souls-like.** At 500 ms we sit between Kaeya and Elden Ring. Elden Ring's next attack at 570 ms and roll at 800 ms are slower than our 500 and 580 ms. So "slow" is probably not mainly the chain timing.
- **The 260 ms startup is the number to cut.** The previous vault table suggested 9 to 13 frames (150 to 217 ms) for one-handed swords. Moving Light1 HitStart from 0.26 to about 0.18 to 0.20 s, with the lunge starting at about 0.06, puts it between Keqing and Kaeya. That is still slower than a fighting game jab, so it stays readable (unsourced, judgment anchored to the KQM numbers).
- **Speed up the chain only when hits connect.** Keep 500 ms on a whiff and drop the next-hit window to about 420 ms on a hit. That rewards connecting without making mashing into empty air faster (unsourced).

### 3. Cancels and buffer

- **Rolling out of the windup matches God of War.** We already let you cancel the windup into roll or block, as God of War allows pre-hit (https://www.gamedeveloper.com/pc/combat-canceled-i-god-of-war-i-action-game-design). Keep it.
- **Our buffer is long.** 0.35 s is 21 frames, against 9 to 10 in Smash (https://www.ssbwiki.com/Buffer) and 5 to 8 for KOF XV special moves (https://dgmiwiki.wpi.edu/mechanic/input_buffer). Long buffers cause the unwanted actions players complain about (https://forum.norestforthewicked.com/t/combat-input-buffering-queuing-issues/25029). Keep 0.35 s for M1 chaining if it feels good, but let a newer roll or block press replace a queued attack, as Williams describes (gamedeveloper URL above). Clear the buffer when the player is hit or staggered (unsourced).
- **Consider holding M1 to continue a combo after a dodge,** like Bayonetta's Dodge Offset (https://bayonetta.fandom.com/wiki/Dodge_Offset). It would let Light2 continue after a roll, but it conflicts with our "hold M1 0.2 s = heavy" input. A buffered-press version that remembers the combo step for about 0.5 s after a roll avoids the conflict (unsourced).

### 4. Make the running attack its own move

The brief says the running attack is a leaning copy of Light1's forehand. Every reference gives it a different animation and job:
- Elden Ring: a different attack, sometimes with more range or speed (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide).
- DMC Stinger: a thrust dash that stops on contact (https://devilmaycry.fandom.com/wiki/Stinger).
- ZZZ's Dash Attack (https://mobalytics.gg/blog/zenless-zone-zero/zzz-combat-guide/).
- Stellar Blade's Rush (https://www.playstation.com/en-us/editorial/stellar-blade-beginners-guide-to-combat).

Recommendation (unsourced, judgment):
- Make it a one-handed thrust or rising cut in a different pose from Light1.
- Make it the longest warp in the kit (about 9 studs max), ending when the blade box touches the target, as DMC1's Stinger stops on contact.
- Give it a short charge-in trail and a forward-facing hit spark. Use 1.5x Light hitstop and posture damage so it reads as an opener.
- Starting it from a roll could also give a ZZZ-style dash attack variant for free.

So yes, use different animations. A new pose and arc matters more than retiming the existing one.

### 5. How sword skills should fit

Grammar suggested by the SAO games (each line cites the game it comes from; the combination is my judgment):
- **SP separate from stamina, filled by landing basic hits.** Echoes and Lycoris both do this (https://thegameswiki.com/echoes-of-aincrad/wiki/sword-skills, https://primagames.com/?p=313680). This also matches the earlier vault plan.
- **A finisher slot.** A skill assigned here replaces Light3 at the end of the M1 string and costs 0 SP or a reduced amount, as in Lycoris and Last Recollection (https://primagames.com/?p=313680, https://bandainamcoent.com/news/sword-art-online-last-recollection-101-guide). This is the cleanest bridge from M1 to skills and answers "how do skills fit."
- **Skill Connect window with a cue.** During a skill's post-motion, show the cue on the weapon and play a sound. Hollow Fragment used a purple aura, Lycoris a flashing star and Last Recollection a light blue flash (gematsu, Prima and Bandai Namco URLs above). Players found the blue flash hard to see, so add audio (https://steamcommunity.com/app/1566880/discussions/0/3879345097432704041). Cap connects at about 2 to 3, as Last Recollection's base of 3 suggests (https://steamcommunity.com/app/1566880/discussions/0/3879345465238799262).
- **Post-motion delay scales with skill tier and is punishable,** as in canon (https://swordartonline.fandom.com/wiki/Sword_Skills). A connect cancels it, which is the reward for skill.
- **Skills hit hardest inside openings.** Echoes reviewers liked spending skills inside parry and dodge openings instead of opening with them (https://gamingtrend.com/reviews/echoes-of-aincrad-review/). Give skills bonus damage on staggered, parried or post-roll targets.
- **Avoid the "spam autos to fill the bar" loop** that players called out (https://steamcommunity.com/app/1566880/discussions/0/3879345465238799262). Have SP also build from parries and perfect rolls, not only from M1 hits (unsourced).
- **Make skills look different from normal attacks.** In canon, skills glow and run faster and stronger than normal swings (https://swordartonline.fandom.com/wiki/Sword_Skills). Echoes was criticized for lacking visual impact (https://www.rpgsite.net/preview/20538-echoes-of-aincrad-pc-hands-on-preview-port-steam-deck-rog-ally). So:
  - Hold a lit pre-motion pose.
  - Play the skill at a faster rate than M1.
  - Use larger arcs.
  - Use the stronger hitstop already proposed in the VFX note.
  - Keep skills on a higher animation priority than M1, as the VFX note suggested.
- **Skills should warp harder than basic attacks.** Echoes builds gap-closer skills into its slot tradeoff (https://thegameswiki.com/echoes-of-aincrad/wiki/sword-skills). Gap-closer skills (Sonic Leap style) can use a much larger warp, for example 14 studs, than basic attacks (unsourced number).

## Gaps

- No published magnetism numbers (snap distance, cone, rotation speed) from any AAA studio. The only numbers are from THE FINALS, a Skyrim mod and engine docs.
- No sourced light attack frame data for God of War, DMC5, Bayonetta, NieR, Stellar Blade, ZZZ, Wuthering Waves, Honkai Impact 3rd, Sekiro or Lies of P.
- No Elden Ring running attack frame data. The data repo and explorer could not be read from here.
- Hollow Realization Skill Connect timing, Integral Factor details and Fatal Bullet melee details were cut short by the search budget.
- No Reddit or Discord content, and no usable X content.
