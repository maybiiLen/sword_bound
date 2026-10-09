---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - combat
  - roblox
---

Up: [[Claude]] · Used by: [[Sword combat feel revision]]

Produced by a research agent on 2026-10-08 after Henry said basic sword combat doesn't feel fun yet and asked for end-to-end research (Reddit, X, Discord and forums). Roblox melee games compared on M1 pace, lock-on, lunges and dash attacks. Reproduced as the agent returned it. Claims marked unsourced are the agent's own calls.

Builds on "Anime Roblox combat games research (2026-10-08)" and "Attack momentum and deflect feel research (2026-09-30)". Facts already in those docs (TSB 4-hit damage split, Deepwoken flourish and parry cooldown, God of War suck-to-target, Sekiro sprint lunge, the 0.4 s / 1.5 s / 2 s battlegrounds template) are only referenced here, not repeated in full.

Anything without a URL is marked (unsourced). Judgment calls are marked (unsourced, judgment).

## Access log

- Reddit: blocked. WebFetch on reddit.com returned SITE_BLOCKED (https://www.reddit.com/r/deepwoken/search/?q=m1). WebSearch queries with "site:reddit.com" (deepwoken m1 feel, type soul m1 clunky, roblox combat clunky, RobloxDevelopers combat lunge) returned zero reddit.com results, and restricting search to reddit.com was refused by the search proxy with HTTP 400. Nothing in this report comes from Reddit.
- X/Twitter: partly reachable. Search results surfaced tweet text in result titles, which is used below. Fetching x.com directly returned ROBOTS_DISALLOWED (https://x.com/deepwoken/status/1582458191610544128). No retry through mirrors was attempted.
- Discord: no Discord content surfaced. No wiki, Trello or DevForum page I loaded quoted or credited a Discord message. Deepwoken wiki patch notes are probably copied from the game's announcements, but the page does not say where they came from, so I don't count them as Discord. A Type Soul tweet only links the Discord server (https://x.com/TypeSoulRoblox/status/2024242532801282087).
- Trello: blocked. trello.com returned ROBOTS_DISALLOWED (https://trello.com/b/sD4hAw4Q/type-soul).
- YouTube: video pages failed to fetch (CLIENT_ERROR). Only titles found through search are used.
- Fandom wikis: intermittent. These pages loaded: Deepwoken Combat Mechanics, Terminology, Version History 2022-2021, Falchion and Great Maul; TSB Basic Combat; Peroxide Game Mechanics; Rogue Lineage Swords. These failed with CLIENT_ERROR: the TSB Techniques and Updates pages and TSB discussion posts, JJS Game Controls, Combat Warriors Keybinds, Blox Fruits pages, GPO pages, Swordburst 3 pages, Arcane Odyssey wiki, Deepwoken Movement and Settings, and Rogue Lineage Melee Combat Tips.
- Roblox DevForum: reachable. Its search.json endpoint is robots-disallowed, so threads were found through web search.
- Search budget: the shared limit of 200 WebSearch calls per turn ran out partway through. Later work used only fetches of URLs I had already found. More searches would need a follow-up turn.
- No source anywhere gives frame-accurate M1 startup for TSB, JJS, Deepwoken, Type Soul, GPO or Peroxide. No numbers below are invented. Where a number is a community recreation rather than the real game's value, I say so.

## Per-game findings

### The Strongest Battlegrounds (TSB)

- M1 count and cadence. Holding M1 throws up to 4 hits for 14% total (3, 3, 4, 4) (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat; https://now.gg/blog/game-guides/combat-techniques-the-strongest-battlegrounds-en.html). The wiki says recovery varies per hit, with "the third punch" having "a much longer recovery than the first" (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat). No ms values are published.
- What ends a combo. The 4th hit always ragdolls. A missed or blocked 4th hit stuns the attacker for "one full second". A ragdolled target can't act for 2 s, then gets 0.5 s of stun immunity and can't evade for 0.2 s (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
- M1 movement. The wiki only says M1 "will punch forward" and that the 4th hit knocks the target forward horizontally (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat). I found no source on M1 magnetism.
- Direction variants. Jump then M1 while falling gives an uppercut with no horizontal knockback. The downslam has no knockback, bypasses block and grounds the target immediately (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
- Dash and running attacks. The forward dash (W+Q) "charges forward". If you reach the opponent shortly after, it "causes an automatic attack" for 4 damage, and a closer forward dash rolls the enemy for 5.3%. The back dash backflips twice with immunity for "the first few frames". The side dash covers "a small amount of range" (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat). The same page gives conflicting cooldowns: "TBA" in one section, and side dash 2 s with forward dash 5 s in another (same URL). So TSB's running attack is a separate gap-closing move with its own hit on contact, not a reskinned M1.
- Wall combo. A forward dash right after a full M1 string against a wall adds 12% with about a 6 s cooldown (https://now.gg/blog/game-guides/combat-techniques-the-strongest-battlegrounds-en.html).
- Lock-on. No native PC lock-on is documented in any source I loaded. The TSB wiki has a discussion titled "Console Lock-On..." (https://the-strongest-battlegrounds-rblx.fandom.com/f/p/4400000000000046448, fetch failed, title only). Third-party exploit sites sell "lockon aimlock" scripts for TSB (https://rscripts.net/script/lockon-aimlock-cWkv; https://scriptblox.com/script/The-Strongest-Battlegrounds-Lock-On-Players-or-Npc-41786). Players also customize the shift-lock cursor (https://www.narcosis-the-game.com/best-shift-lock-ids-for-the-strongest-battlegrounds/). My inference is that PC players aim with shift-lock (unsourced, inference).
- How dashes are built (DevForum recreations, not TSB's real values). Devs say TSB dash speed "progressively slow[s] down" instead of stopping, and the animation weight drops as the dash ends (https://devforum.roblox.com/t/how-can-i-make-a-smoother-side-dash/2883288). One dev believes TSB runs dashes on the client with "some sort of acceleration system rather than just keeping a constant velocity" (https://devforum.roblox.com/t/very-smooth-dash-system-like-strongest-battlegrounds/2590353). Another uses a cubic falloff, v = speed * (1 - t/d)^3 (https://devforum.roblox.com/t/how-do-i-make-the-battlegrounds-dashes/4187993). Recreation configs use 70-100 studs/s for 1 s forward and 75-90 studs/s for 0.5 s sideways (https://devforum.roblox.com/t/how-can-i-make-a-smoother-side-dash/2883288; https://devforum.roblox.com/t/help-with-replicating-battleground-front-dash/4731700). One recreation steers a dash every frame from the camera yaw (https://devforum.roblox.com/t/help-with-replicating-battleground-front-dash/4731700).
- Sword skills chaining. Techs chain 3-4 M1s into a shove, uppercut or ability. "Delayed M1s" slow the string to buy cooldown time (https://bloxodes.com/wiki/the-strongest-battlegrounds/techniques). A comparison site calls dash canceling "the foundation": "a dash, which cancels into another ability, which cancels into M1s" (https://dungeonpath.com/posts/pillar/roblox-fighting-games-compared/).
- Praise and complaints. A guide site calls the combat "flashy and satisfying" and says "every fight gives immediate feedback" (https://www.exitlag.com/blog/the-strongest-battlegrounds-overview/). There is also a YouTube video titled "Why TSB's Combat Feels So Good (And Why It's Addictive)" (https://www.youtube.com/watch?v=6g0sNoB7xrk, title only). Sportskeeda notes "hit stun deterioration" makes long combos harder (https://sportskeeda.com/roblox-news/the-strongest-battlegrounds-a-beginner-s-guide).

### Jujutsu Shenanigans (JJS)

- M1 count. One fan wiki says most combos use 3-4 M1s before a skill. Tapping gives single hits, while holding gives strings that "end in launchers or downslams". The downslam is the "4th or 5th hit in a string" (https://jujutsu-shenanigans.wiki/guides/how-to-play/). A guide site says the 4th M1 becomes a downslam or uppercut "depending on your variant", with a cooldown before a new chain (https://sabertoothgames.com/how-to-chain-combos-per-character-in-jujutsu-shenanigans/). The same site claims "green" combos leave a 3-8 frame gap and that combos drop above 150 ms ping. This is a low-quality guide site and it contradicts itself on which M1 is the launcher, so treat these numbers as unverified.
- Dash. Q plus a direction dashes. In stun, holding M1 toward the attacker makes it a ragdoll cancel (https://jujutsu-shenanigans.wiki/guides/how-to-play/). No distances or cooldowns were found.
- Lock-on. Not documented. A beginner guide only says the mouse is used to "look around and aim" (https://www.sportskeeda.com/roblox-news/jujutsu-shenanigans-guide).
- Patch cadence. The JJS team posts version notes on X, for example v1.76 Naoya projection-meter changes (https://x.com/shenanigansJJS/status/2055746623741850021) and v1.79 through v1.82 news posts (https://x.com/ShenanigansNews/status/2079360708269990142). None of the tweet text found mentions M1 timing.

### Deepwoken (closest to a souls-like)

- M1 count and ender. Four uninterrupted swings trigger a Flourish that kicks the target away, with small endlag that a Mantra cast can bypass (https://deepwoken.fandom.com/wiki/Combat_Mechanics). A Flourish uses "the fourth or otherwise final attack in your weapon's attack cycle" (https://deepwoken.fandom.com/wiki/Terminology_(game)).
- Cadence. Deepwoken gives speed as a per-weapon multiplier, not in seconds. Examples are Battleaxe 0.6x to 0.62x, Canorian Axe 0.6x to 0.62x, Enforcer's Axe 0.55x to 0.57x, Alloyed Tanto 0.88 to 0.87, and Skyreap Blade 0.7x to 0.68x (https://deepwoken.fandom.com/wiki/Version_History/2022-2021). Great Maul is 0.85x (https://deepwoken.fandom.com/wiki/Great_Maul). Daggers got "a small amount endlag on their M1's; this should decrease their ability to combo incredibly fast" (https://deepwoken.fandom.com/wiki/Version_History/2022-2021). The base swing time behind the multiplier isn't published (unsourced gap).
- Windup reference numbers, all for heavier moves, not M1s. Fang and Coil critical has 0.25 s windup (https://deepwoken.fandom.com/wiki/Terminology_(game)). Enforcer Axe critical windup went from 0.5 s to 0.6 s. Mantra windups were cut to 0.2 s (Ice Lasers), 0.4 s (Tacet Drop Kick) and 0.5 s (Flame Repulsion) (https://deepwoken.fandom.com/wiki/Version_History/2022-2021).
- M1 movement. Double-tapping W during an M1 "moves you closer to the opponent" (stepping), and it can accidentally trigger a Running Attack (https://deepwoken.fandom.com/wiki/Combat_Mechanics). The uppercut "drives you forward" (same URL).
- Running attack. M1 while running "strafes forward with increased range" but adds endlag and slightly more windup. Against a target facing away, you "charge with a gust of wind". A Chase Attack, a running attack used while chasing, "closes large distances" on a short cooldown (https://deepwoken.fandom.com/wiki/Combat_Mechanics).
- Direction variants. Ctrl+M1 is an uppercut. Its windup is the same for every weapon, it has a wide front hitbox, it can't be blocked, it has tighter parry timing, and it immobilizes you if it misses (https://deepwoken.fandom.com/wiki/Combat_Mechanics; https://progameguides.com/roblox/all-controls-for-roblox-deepwoken/). Aerial M1s exist. Heavy aerials have a 2.5 s cooldown versus 2 s for regular aerials and a +0.2x speed bonus, and in Oct 2022 they got their own animation (https://deepwoken.fandom.com/wiki/Version_History/2022-2021). The Deepwoken account tweeted that greataxes and greathammers were underperforming and that "the heavy aerial M1 update this week" might help (https://x.com/deepwoken/status/1582458191610544128, text from the search result title).
- Feint and cancel. M2 during windup feints, and holding M2 feints as soon as possible (https://deepwoken.fandom.com/wiki/Combat_Mechanics). DevForum devs recreate this with a PreparingM1 flag cleared by a DealDamage animation marker, which cuts the hitbox if a cancel arrives first (https://devforum.roblox.com/t/how-do-i-make-m1-cancelling-like-deepwoken/3014458).
- Lock-on. No lock-on control appears in the controls list (https://progameguides.com/roblox/all-controls-for-roblox-deepwoken/). Players report shift-lock issues to the dev bug tracker (https://app.betahub.io/projects/pr-8346521607/issues/148, title only). My inference is that Deepwoken uses shift-lock aiming (unsourced, inference).
- How skills chain. The final M1 of a downslam route can be swapped for a mantra or critical (https://itemlevel.net/deepwoken-heavy-weapon-guide-combos-instant-uppercut/). Feints and uppercuts count as M1s in the 4-hit cycle (same URL).
- Complaints. One player says the listed Range stat "is a FRAUD" because the hitbox shape matters more (https://x.com/DearLadyMaria/status/1952438041064390767, search result title).

### Type Soul

- Controls. Dash is Q, Flash Step is Shift+Q and gives brief immunity, Critical is R, and Shift-lock is Left Alt ("camera mode, not lock-on"). On gamepad, attack is RT, critical LT and block RB, and Flash Step is stick forward plus RT (https://progameguides.com/roblox/type-soul-controls-roblox/). No lock-on key was found.
- I found no M1 count, cadence or lunge data. The type-soul.wiki and Trello pages were robots-disallowed.

### Blox Fruits (sword styles)

- Dark Blade's tap M1 "executes 3 slashes" and "ends with a 4th dash attack", so the ender itself travels (https://www.gamersberg.com/blox-fruits/wiki/swords/dark-blade). Its Z skill in held V2 mode "dashes forward with the slashes". An Aug 6, 2026 balance pass cut Z end-lag 30% and raised charge speed 10% (same URL).
- Dashing is a double-tap in any direction and gives i-frames. Combos run "C move (stun) → X move → V move → Sword M1s → Fighting style moves", and dashing between moves speeds up combos (https://bloxfruit.io/guides/pvp-guide/).
- I found no M1 cadence numbers. Fandom pages failed to load.

### Grand Piece Online (GPO)

- Basic attack is left click, special attack is right click, block is Q, and dash or sprint is Shift (https://grandpieceonlinegame.wiki/guide/controls/). I found no M1 count, cadence or lock-on data. The fandom pages failed.

### Peroxide

- Light attack strings are 4 to 6 hits depending on weapon type. The last hit used to guard-break, but "as of an update, m1/light attacks will no longer block break" (https://peroxide-roblox.fandom.com/wiki/Game_Mechanics).
- "Most skills can be started while winding up M1s". Light attacks have "false stun no matter what weapon you use". Holding dash chains several flash steps (same URL).
- I found no lock-on or timing numbers.

### Swordburst 3 (closest MMO/floor-structure peer)

- Weapon speeds are described only in words. Knife is fast, greatsword is slow, sickle is between sword and greatsword, and katana is like a sword. Mobility comes from skills: knife has "many rushes" on a 2 s cooldown, greatsword has "one lunge", and katana has a teleport (https://en.namu.wiki/w/Swordburst%203).
- Skills ("Burst") sit on top of basic attacks. A katana rotation guide runs "Katana Lunge > Slashing Flurry > Flurry > Regular Attacks > REPEAT". Katana Lunge costs 20 SP and "allows you to move incredible fast" (https://itemlevel.net/sword-burst-3-complete-katana-guide/).
- Complaints. Showing enemy attack ranges for normal attacks "made it too easy to avoid attacks", and critics said "the skill quality is not good" (https://en.namu.wiki/w/Swordburst%203). Before launch, players on the Arcane Odyssey forum called SB1 and SB2 "incredibly slow and boring" and SB2 "ultimately just grinding with m1s", and hoped SB3 "won't end up as just another M1 fest" (https://forum.arcaneodyssey.dev/t/swordburst-3/112799). YouTube titles include "SWORDBURST 3 SUCKS" (https://www.youtube.com/watch?v=_eAYrSrUyHA) and "The Problem With Sword Burst 3..." (https://www.youtube.com/watch?v=jo8nrgpIDDI) (titles only).
- I found no lock-on information.

### Combat Warriors

- Per-swing cooldowns (wiki numbers). Katana 0.59 s with 33 damage (https://wiki.combatwarriors.gg/books/katana). Light weapons run 0.48 s (Sickle) to 0.56 s (Baton), with Dual Daggers 0.51 s and Khopesh 0.52 s. Heavy weapons run 1.4 s (Bo Staff) to 2.4 s (Yoru), with Longsword 1.7 s (https://en.namu.wiki/w/Combat%20Warriors/%EB%AC%B4%EA%B8%B0).
- Combo shape. Heavy swords go cut, cut, then a stab whose hitbox widens if you turn the camera during it. One-handed light swords do wide cuts with a final stab. Batons alternate left, right, left (same URL).
- Movement. Roll (E) is a forward roll, and combining it with a slide "properly doubles your speed". Sprint stamina "lasts about 8 seconds" (https://en.namu.wiki/w/Combat%20Warriors).
- Lock-on. There is none. Ctrl toggles a fixed camera, "Same function as Shift Lock in other Roblox games" (same URL).
- Feel. Comparison writers call it "slower and more deliberate than anime battlegrounds games" and "positional rather than combo-based" (https://dungeonpath.com/posts/pillar/roblox-fighting-games-compared/). The wiki says animation was "significantly improved" over its predecessor Mortem Metallum, and criticizes weapon balance (https://en.namu.wiki/w/Combat%20Warriors).

### Rogue Lineage

- String length by weapon. Base swords have a "five strike combo". Katana has 4 hits, rapier 4 quick pokes plus a knockback slash, greatswords 3 hits, and the scythe 3 hits whose last one teleports behind the target (https://rogue-lineage.fandom.com/wiki/Swords).
- Lunge. The sword M2 makes you "lunge forward and move very rapidly across the ground damaging anyone you touch". The Abyssal Greatsword M2 flips forward and slams, covering "a bit more distance than a regular sword M2 but less than a dash" (same URL).
- I found no timing numbers.

### Arcane Odyssey

- Aiming. Attacks "are based off of the player camera angle instead of being cursor aimed", which makes moves hit walls in front of your view. Players note NPCs "have auto-aim" (https://forum.arcaneodyssey.dev/t/arcane-odysseys-combat-problem/97410).
- Commitment. "Using most moves will lock you in place", and latency stretches the lock. A defender calls it "the entire basis of the game's combat" (same URL).

### SAO-inspired Roblox titles

- World of Aincrad has been discontinued. Only four floors shipped and "Floor 5 cancelled" (https://www.roblox.com/games/9682835938/World-of-Aincrad). Sword skills unlock through sword mastery levels (same URL; https://theclashify.com/world-of-aincrad-trello/). Its beginner guide advises dodging a kobold's swing, then landing "M1 Twice" before the next one (https://theclashify.com/world-of-aincrad-trello/).
- Sword Art: Eternity (MOTE Games) offers first- and third-person views and a permadeath mode. The store page has no combat details (https://www.roblox.com/games/13725495850/Sword-Art-Eternity).
- Other titles found in search, with no combat data: Sword Art Online: Aincrad Origins (https://www.roblox.com/games/8056417483/Sword-Art-Online-Aincrad-Origins), Sword Art Online: Project Eternity (https://www.roblox.com/games/195971254/Sword-Art-Online-Project-Eternity), and an old Sword Art Online Burst thread (https://devforum.roblox.com/t/sword-art-online-burst-floor-8/12473). A YouTube video is titled "This NEW Roblox SAO RPG is INSANE!" (https://www.youtube.com/watch?v=UfInDEC_zDw, title only). None of these is known for its combat feel. The SAO niche on Roblox seems to have no strong melee benchmark (unsourced, inference from the thin results).
- Echoes of Aincrad (the 2026 console game, for context). A review calls combat "fast and frenetic", with light and heavy attacks, an omnidirectional dodge, a shield parry and 3 sword skill slots. It also mentions "sluggish animations" in its pacing section (https://checkpointgaming.net/reviews/2026/07/echoes-of-aincrad-review-sword-art-offline/).

### 2025-2026 sword and melee games praised for feel

- Gakuran and The Forge are covered in the prior doc. No new 2025-2026 sword game came up in this pass with specific praise for M1 feel. List articles only gave genre-level praise: Combat Warriors for accessibility, and Super Power Fighting Simulator criticized as "floaty" with hitboxes that "feel imprecise" (https://dungeonpath.com/posts/pillar/roblox-fighting-games-compared/).

### DevForum notes on M1 feel (cross-game)

- Choppy M1 chains. Repliers suggest blending clips with a fade time of about 0.2 s (`oldAnim:Stop(0.2)`, `newAnim:Play(0.2)`, another said 0.21) plus an input buffer (https://devforum.roblox.com/t/how-to-make-my-m1-attacks-look-more-fluid-less-choppy/4700793).
- "Does not FEEL good" compared with battlegrounds games. Advice was to add hit pauses, briefly anchor the attacker so swings feel committed, "speed up the animations, like a lot", maybe teleport the player on some moves, and add camera shake (https://devforum.roblox.com/t/help-with-combat/3844625).
- Lock-on. An open-source lock-on resource argues that shift-lock combat makes camera positioning most of the skill, and that lock-on makes 3D melee more deliberate (https://devforum.roblox.com/t/open-source-lock-on-combat-in-3d/1458506). A basic recreation searches 100 studs and offsets the camera by CFrame (3,1,0) (https://devforum.roblox.com/t/how-to-make-an-camera-target-lock-system-for-a-fight-game/2172268).
- Generic hitbox timing. Example pseudocode starts the hitbox at 0.25 s (https://devforum.roblox.com/t/how-do-i-make-m1-cancelling-like-deepwoken/3014458). This is placeholder code, not a game value.

## Cross-game patterns

1. String length is 3 to 5 hits for light and medium weapons and 3 for heavy ones, ending in a hit that sends the target away. Examples: TSB 4 (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat), Deepwoken 4 plus Flourish (https://deepwoken.fandom.com/wiki/Combat_Mechanics), JJS 4-5 (https://jujutsu-shenanigans.wiki/guides/how-to-play/), Peroxide 4-6 (https://peroxide-roblox.fandom.com/wiki/Game_Mechanics), Rogue Lineage 5, 4 or 3 by weapon (https://rogue-lineage.fandom.com/wiki/Swords), Combat Warriors 3 motions (https://en.namu.wiki/w/Combat%20Warriors/%EB%AC%B4%EA%B8%B0).
2. The ender is a different action from the earlier hits. It knocks the target away, ragdolls them or travels. Missing it costs you: TSB's whiffed 4th hit stuns you for 1 s, and Deepwoken's Flourish has endlag (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat; https://deepwoken.fandom.com/wiki/Combat_Mechanics). In Blox Fruits, Dark Blade's ender is a dash (https://www.gamersberg.com/blox-fruits/wiki/swords/dark-blade).
3. The running or dash attack is its own move with its own travel, not a leaned version of M1. TSB's forward dash hits on contact (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat). Deepwoken's running attack "strafes forward" with more range, and its chase attack "closes large distances" (https://deepwoken.fandom.com/wiki/Combat_Mechanics). Rogue Lineage's sword M2 lunges "very rapidly across the ground" (https://rogue-lineage.fandom.com/wiki/Swords).
4. Gap-closing is a player action, not hidden magnetism. Deepwoken has double-tap W stepping (https://deepwoken.fandom.com/wiki/Combat_Mechanics), TSB forward dash, and SB3 lunge skills (https://itemlevel.net/sword-burst-3-complete-katana-guide/). I found no source describing hidden M1 magnetism in any of these Roblox games (unsourced gap).
5. Shift-lock is the norm and hard lock-on is rare. Combat Warriors uses Ctrl shift-lock (https://en.namu.wiki/w/Combat%20Warriors), Type Soul uses Left Alt shift-lock (https://progameguides.com/roblox/type-soul-controls-roblox/), and Arcane Odyssey aims by camera (https://forum.arcaneodyssey.dev/t/arcane-odysseys-combat-problem/97410). TSB and Deepwoken have no documented lock-on. So in these games the character always faces where the camera points while attacking (unsourced, inference from shift-lock behavior).
6. Abilities cancel into and out of M1s. Peroxide skills can start during M1 windup (https://peroxide-roblox.fandom.com/wiki/Game_Mechanics). Deepwoken mantras bypass Flourish endlag and can replace the last M1 (https://deepwoken.fandom.com/wiki/Combat_Mechanics; https://itemlevel.net/deepwoken-heavy-weapon-guide-combos-instant-uppercut/). TSB and JJS go 3 M1s into a skill (https://bloxodes.com/wiki/the-strongest-battlegrounds/techniques; https://jujutsu-shenanigans.wiki/guides/how-to-play/).
7. Direction and air variants are usually 1 or 2 per game, not a full moveset. TSB has jump+M1 uppercut and a downslam (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat). Deepwoken has Ctrl+M1 uppercut, aerial M1 and running attack (https://deepwoken.fandom.com/wiki/Combat_Mechanics).
8. Movement fades out instead of stopping. Recreations of TSB dashes taper speed and animation weight (https://devforum.roblox.com/t/how-can-i-make-a-smoother-side-dash/2883288).
9. The main complaints are "slow and boring" and "M1 fest" for Swordburst (https://forum.arcaneodyssey.dev/t/swordburst-3/112799), "floaty" with imprecise hitboxes (https://dungeonpath.com/posts/pillar/roblox-fighting-games-compared/), being locked in place by casts (https://forum.arcaneodyssey.dev/t/arcane-odysseys-combat-problem/97410), and swings that feel weightless without hit pauses (https://devforum.roblox.com/t/help-with-combat/3844625).

## What this means for Sword Bound's sword

### Is 260 ms startup and 500 ms per hit slow?

- Cadence of 500 ms per hit is normal. Combat Warriors light weapons swing every 0.48 to 0.59 s, and the katana every 0.59 s (https://en.namu.wiki/w/Combat%20Warriors/%EB%AC%B4%EA%B8%B0; https://wiki.combatwarriors.gg/books/katana). The battlegrounds template uses 0.4 s between hits (https://devforum.roblox.com/t/battleground-modulepack-ragdoll-stun-direction-cooldown/3488881). So Sword Bound's 0.5 s cadence for Light1 and Light2 sits between the template and Combat Warriors' lights. It isn't the cause of the stiffness.
- The whole string is slow for what it delivers. Sword Bound needs about 1.64 s for 3 hits (brief). The template's 4 hits at 0.4 s is about 1.6 s (https://devforum.roblox.com/t/battleground-modulepack-ragdoll-stun-direction-cooldown/3488881). So Sword Bound delivers 3 hits in the time a battlegrounds string delivers 4. Light3 doesn't release movement until 0.95 s, which is long for a non-finisher that has no knockback or travel of its own (unsourced, judgment).
- Startup of 260 ms is on the slow side for a light. No source gives real M1 startup for these games. The closest published numbers are Deepwoken's windups for heavier moves: 0.25 s for a critical (https://deepwoken.fandom.com/wiki/Terminology_(game)) and 0.2 to 0.6 s for mantras and crits (https://deepwoken.fandom.com/wiki/Version_History/2022-2021). Sword Bound's basic light starts about as slowly as a Deepwoken critical. My judgment is that Light1 should land sooner than the game's heavier tools. Since there is no source for real M1 startup, this is a comparison by analogy, not a measured gap (unsourced, judgment).
- The bigger problems are probably not the numbers (unsourced, judgment from the brief):
  - The lunge is only about 2 studs and only activates within 8 studs.
  - Unlocked attacks face the move-input direction with no soft targeting, while the comparable games aim with shift-lock.
  - The running attack reuses Light1's arc.
  - Attack fade-in is 0.06 s, where DevForum advice for smooth M1 chains is about 0.2 s (https://devforum.roblox.com/t/how-to-make-my-m1-attacks-look-more-fluid-less-choppy/4700793).

### Suggested changes (all values are unsourced judgment starting points)

1. Make Light1 and Light2 HitStart about 0.16 to 0.20 s and keep 0.5 s cadence. Leave Light3 slower but make it a real ender: push the target back about 3 to 5 studs, like a Flourish (https://deepwoken.fandom.com/wiki/Combat_Mechanics). A whiff of the ender should cost extra recovery, as in TSB's 1 s whiff stun (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
2. Add soft targeting when not locked. At attack start, rotate toward the nearest enemy within about 60 degrees and about 10 to 12 studs. Fill the gap that shift-lock fills in other Roblox games, and keep hard lock opt-in for duels and bosses. The open-source lock-on post supports offering lock-on for deliberate 1v1 melee (https://devforum.roblox.com/t/open-source-lock-on-combat-in-3d/1458506).
3. Make the lunge close the gap instead of moving a fixed 2 studs. Travel the distance to target minus the 3.2 stud stop distance, capped around 4 to 5 studs for lights. Keep Deepwoken-style stepping as a manual extension, such as forward input during an M1 adding about 1.5 studs (https://deepwoken.fandom.com/wiki/Combat_Mechanics).
4. Rebuild the running attack as its own move.
   - Give it a new animation, such as a thrust or a rising slash rather than the leaning forehand.
   - Keep most of the sprint speed and travel about 6 to 8 studs, tapering it off the way the TSB dash recreations do (https://devforum.roblox.com/t/how-can-i-make-a-smoother-side-dash/2883288).
   - Accept slightly more windup and endlag as the price, like Deepwoken's running attack (https://deepwoken.fandom.com/wiki/Combat_Mechanics).
   - Optionally add a TSB-style automatic hit on contact (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
   - Yes, use different animations for this. The reference games all treat it as a distinct move.
5. Blend chained M1s with a 0.12 to 0.2 s fade, keep the 0.06 s fade-in from idle for responsiveness, and keep the 0.35 s input buffer (https://devforum.roblox.com/t/how-to-make-my-m1-attacks-look-more-fluid-less-choppy/4700793).
6. Add one directional variant, not a full moveset. A Ctrl+M1 or back+M1 rising cut that opens guard fits a souls-like better than juggles, modeled on Deepwoken's unblockable uppercut with tighter parry timing (https://deepwoken.fandom.com/wiki/Combat_Mechanics). The prior doc already recommends avoiding TSB-style juggles.
7. Sword Skills.
   - Allow a Sword Skill from the CancelOpen of any light, and let it replace Light3, the way Deepwoken mantras replace the last M1 (https://itemlevel.net/deepwoken-heavy-weapon-guide-combos-instant-uppercut/).
   - Optionally allow starting one during the M1 windup, as Peroxide does (https://peroxide-roblox.fandom.com/wiki/Game_Mechanics).
   - Keep the SAO post-motion delay as the punish, consistent with Echoes of Aincrad's 3-slot, SP-gated design (https://checkpointgaming.net/reviews/2026/07/echoes-of-aincrad-review-sword-art-offline/).
   - At least one skill per weapon should be a mobility lunge (SB3 Katana Lunge, https://itemlevel.net/sword-burst-3-complete-katana-guide/). That avoids Swordburst's "M1 fest" complaint (https://forum.arcaneodyssey.dev/t/swordburst-3/112799).
8. Avoid the Swordburst 3 mistake of showing enemy attack ranges on normal attacks, which players said made fights trivial (https://en.namu.wiki/w/Swordburst%203).
