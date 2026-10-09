---
type: research
created: 2026-10-09
author: claude
tags:
  - research
  - combat
---

Up: [[Claude]] · Used by: [[Hit feel round 3]]

Produced by a research agent on 2026-10-09 after Henry said attacks are missing key features (flinching, enemies pushed back while you push forward, super armor for bosses, sounds that feel chopped) and that the fundamentals must be done before other classes. How games design hit reactions, per-hit pushback with attacker step, and enemy and boss armor tiers. Reproduced as the agent returned it. Claims marked unsourced are the agent's own calls.

Scope: why Sword Bound hits feel weak on the receiving end. Enemies barely flinch, nobody slides back per hit, the attacker does not travel with the string, and big enemies have no super armor. This builds on the 2026-10-08 vault notes (anime Roblox combat, melee animation craft, Roblox attack movement) and does not repeat their hitstop, lunge and warp findings.

Rule used below: every factual claim carries a URL. Anything marked (unsourced) is my judgment. Where a game's frame data could not be found, I say so and give no numbers.

## Source access this run

- Reddit: blocked. WebFetch on reddit.com returned "SITE_BLOCKED". `site:reddit.com` searches returned no reddit.com results at all (the search tool swaps in other sites). One search result pointed at a third-party Reddit mirror (pol1.lr.ggtyler.dev). I opened it once before I knew Reddit was blocked, then left its content out of this report, and I did not use any other mirror.
- X/Twitter: blocked. WebFetch on x.com returned "ROBOTS_DISALLOWED". `site:x.com` and `site:twitter.com` searches returned no X results. A copy of one X thread surfaced on a thread-mirror site; it is left out because X itself was blocked.
- Discord: no usable content. `site:discord.com` searches only returned server-directory pages with no discussion text. Discord message content is not indexed, so I found nothing to cite.
- Also blocked or unreadable: glossary.infil.net JSON (robots disallowed), wiki.supercombo.gg (bot-protection "Access Denied"), devilmaycry.fandom.com/wiki/Dante_Must_Die (client error), and the Steam DMC5 threads (no post text came back). I did not retry any of them another way.
- Forum material that did load came from Steam Community discussions, the Roblox DevForum, Enshrouded's feature-upvote board and a Gcores user post.

## 1. Hit reactions

### Hitstun and flinch are two different things

- Smash Bros. treats flinching as the animation and hitstun as the lockout: "The length of the flinch animation is correlated to the attack's hitstun, which itself is directly determined by knockback" (https://www.ssbwiki.com/Flinching).
- Smash also uses tiers. A medium flinch needs at least 12 frames of hitstun (15 in Ultimate), a heavy flinch at least 21 frames, and tumbling at least 32 frames (https://www.ssbwiki.com/Flinching).
- Guilty Gear Strive standing hitstun runs 12, 14, 16, 19 and 21 frames for attack levels 0 to 4. Crouching adds 1 frame (https://dustloop.com/w/GGST/Mechanics).
- Granblue Fantasy Versus Rising ground hitstun runs 14, 16, 18, 20 and 22 frames for levels 0 to 4 (https://dustloop.com/w/GBVSR/Mechanics).
- So in 2D fighters, light-to-heavy hitstun covers about 0.2 to 0.37 s at 60 fps. That is the "you can't act" window, and the visible flinch is tuned to match it.

### Reaction ladders by attack weight

- Elden Ring gives every attack a "Damage Level" that picks the victim's reaction (https://eldenring.wiki.gg/wiki/Damage_Level):
  - 8, very short stagger: dagger and thrusting sword lights.
  - 1, short stagger: straight sword and axe lights.
  - 2, moderate stagger: greatsword lights and straight sword heavies.
  - 3, long stagger: colossal weapon lights.
  - 5, push and long stagger: Kick.
  - 4, 7 and 11: knockdowns.
  - 6: faceplant.
  - 9: tossed into the air.
- Under that table, Sword Bound's sword lights sit at Damage Level 1, its heavy at Level 2, and a finisher that shoves sits at Level 5 (https://eldenring.wiki.gg/wiki/Damage_Level).
- Genshin Impact uses "impulse types" (https://library.keqingmains.com/combat-mechanics/poise):
  - Level 1: shake, no displacement.
  - Level 2: light, 200 horizontal.
  - Level 3: heavy, 200 horizontal.
  - Level 4: heavy, 800 horizontal.
  - Levels 5 to 9: air launches with 480 to 1200 horizontal and 600 to 900 vertical.
  - The units are internal, but the ratios are useful.
- In Genshin, lighter targets fly farther and ground drag cuts displacement, so the same hit can land at a lower level on a grounded target (https://library.keqingmains.com/combat-mechanics/poise).
- Commercial reaction packs follow the same grid. One mocap pack ships Front, Back, Left, Right, Up and Down directions at Light, Medium, Heavy and Explosion strength, plus "partial hits, knockdowns, falls, launch reactions, combo impacts" (https://www.fab.com/listings/0c79e08b-0440-4dfc-9321-79ba4a9dcbe3).

### Directional reactions

- Reactions should follow the direction the energy comes from. Directional hit animations should play to match the incoming attack's direction (https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects).
- One indie implementation uses a dot product of the hit against the victim's forward vector to get front and back, then extends it to left and right, giving 8 directions plus centre (https://swearsoft.itch.io/jackmclantern/devlog/76709/direction-based-hit-reaction).
  - It puts the 8 poses on a separate layer with an upper-body mask, so enemies keep walking while they react.

### Additive and partial reactions, and reacting while attacking

- Enemy attack animations often can't be cancelled, so the player sees no reaction. The fix is additive "shakes" on top of the current pose. That clip is "animated from reference pose so it can be added on different animation poses" (https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects).
- The same article says hits landing mid-attack, between two points t1 and t2, should trigger different reactions from normal hits. It also says the cross fade into a hit reaction "should be equal to zero" (https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects).
- Unreal tools sell the same idea as procedural spring motion. Hits are "applied procedurally over the character's existing animation", with impact location, direction, bone and strength supplied by gameplay (https://forums.unrealengine.com/t/kettunen-easy-procedural-hit-reactions/2741781).
- Souls bosses don't flinch while attacking. Steam players describe Malenia as staggering while walking toward you, but "when she attacks, she has hyper-armor". Poise damage still lands, and a break during the attack resets instead of staggering her (https://steamcommunity.com/app/1245620/discussions/0/3833171151459461498).
- Sekiro players report bosses whose "attacks have armor so he doesn't flinch" (https://steamcommunity.com/app/814380/discussions/0/1815422173030675856).
- God of War Ragnarok's official refresher says light attacks "ont moins de chances d'interrompre les attaques ennemies" (are less likely to interrupt enemy attacks), while heavy attacks can stun (https://www.playstation.com/fr-ca/games/god-of-war-ragnarok/god-of-war-combat-refresher-course/).
- Players notice when this goes wrong in both directions:
  - A God of War PC player complained "Even the most simple draugr will refuse to flinch when you hit him" (https://steamcommunity.com/app/1593500/discussions/0/3721692409830254234).
  - Enshrouded players asked that enemies "hit by the heavy attacks flinched in a way that their attacks were disrupted", "Excluding big bosses of course" (https://enshrouded.featureupvote.com/suggestions/708680/enemies-should-flinch-when-being-hit-by-heavy-attacks).
  - Other Enshrouded players asked for the opposite on the player side, with interruption reserved for big hits (https://enshrouded.featureupvote.com/suggestions/678209/comment/750674).

### Animation craft for flinches

- Start on the hit pose with no anticipation. God of War's hit stop "pops the target to the hit pose and holds both Kratos and the target in that first frame" (Christian Wohlwend, https://blog.playstation.com/?p=370399).
- Use a fast-in, slow-out shape. The animation should "start very quick but ends slowly", with safe blend-out intervals in the recovery so the reaction can be cancelled cleanly (https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects).
- God of War allows "huge pose changes, flips, and even air juggling" in reactions (https://blog.playstation.com/?p=370399).
- Procedural animation suits hit reactions. The anim.works article cited in the earlier vault note says procedural methods are strongest for things like hit reactions and secondary motion (https://anim.works/?p=24611). That fits Sword Bound's procedural keyframe specs.
- I could not get the text of Mike Jungbluth's hit-reaction article. Only the gameanim.com landing page loaded (https://www.gameanim.com/2017/03/27/anatomy-hit-reaction/).

### Game by game

- Elden Ring:
  - Reactions come from Damage Level (above).
  - Hyper armor "adds an extra amount of Poise for a certain part of those actions", and super armor gives "practically an infinite amount of Poise" (https://eldenring.wiki.gg/wiki/Poise, https://eldenring.wiki.gg/wiki/Super_Armor).
  - Grabs and certain damage levels go through both (https://eldenring.wiki.gg/wiki/Super_Armor).
- Sekiro:
  - Attacks deal posture damage whether blocked or not. Low vitality slows posture recovery.
  - A broken posture opens a deathblow, shown by a red marker (official manual, https://www.fromsoftware.jp/manual/sekiroshadowsdietwice/stadia/mechanics.html).
- Lies of P:
  - A white border on the HP bar means the enemy can be staggered (groggy).
  - Charged attacks and perfect guards build it, and a full stagger opens a Fatal Attack (https://liesofp.wiki.fextralife.com/New+Player+Help).
- Monster Hunter World:
  - Players describe each part as having its own HP bar. Depleting it causes a flinch, a head depletion causes a knockout and a leg depletion causes a trip (https://steamcommunity.com/app/582010/discussions/0/2979655949473804881).
  - I found no exact thresholds.
  - Wilds raised flinch resistance. Director Tokuda: "Elements like flinch resistance are also higher" (https://gamingbolt.com/monster-hunter-wilds-will-have-monsters-with-higher-health-and-flinch-thresholds-than-world).
  - Destroying a wound in Wilds makes the monster flinch (https://mobalytics.gg/mhw/guides/wounds-explained).
- God of War (2018):
  - A stun meter under the health bar fills from hits, and full stun opens a finisher (https://twinfinite.net/guides/god-of-war-stun-enemies-how/).
- DMC:
  - On Dante Must Die, enemies enter Devil Trigger. "they exude a dark fiery aura and their eyes turn red", deal more and take less damage, and "have increased resistance to flinching from hits and being knocked down or launched" (https://devilmaycry.fandom.com/wiki/Devil_Trigger).
  - DMC5's DMD enemies have "twice the amount of health" (https://gamewith.net/devil-may-cry-5/article/show/8242).
- Genshin:
  - Hidden poise. Enemies flinch only once poise is broken ("vulnerable"), and a stagger can be overridden by a new hit (https://library.keqingmains.com/combat-mechanics/poise).
- Wuthering Waves:
  - A Vibration Strength bar under bosses. Emptying it staggers them "unable to attack for a period of time" (https://twinfinite.net/guides/wuthering-waves-vibration-meter-explained/).
- ZZZ:
  - A Daze bar under HP fills from hits and stuns the enemy when full (https://www.sportskeeda.com/esports/zenless-zone-zero-zzz-combat-explained-elements-fighting-styles-daze-mechanism).
- Roblox, The Strongest Battlegrounds (TSB):
  - Any damage stuns the victim.
  - The 4th M1 always ragdolls and knocks the target forward.
  - A ragdolled player can't act for exactly 2 s and gets 0.5 s of stun immunity on getting up.
  - A whiffed or blocked 4th M1 stuns the attacker for 1 s (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
- Roblox, Deepwoken:
  - Heavy weapons such as the Zweihander and Warmonger get "Hyperarmor for the first 1 second of the attack's windup, ending just before your weapon comes down" on their critical (https://deepwoken.fandom.com/wiki/Zweihander, https://deepwoken.fandom.com/wiki/Warmonger).
- Roblox, Jujutsu Shenanigans (JJS):
  - The guide I could read gives no M1 stun or knockback numbers. It covers ragdoll cancel and directional block (https://games.gg/roblox/guides/jujutsu-shenanigans-beginners-guide/).

## 2. Pushback in combos

### Fighting-game rules

- Every attack has its own pushback. Capcom's SF seminar: "fundamentally you can think that every attack has its own unique pushback distance". Stronger attacks push farther (https://game.capcom.com/cfn/sfv/column/131545?lang=en).
- Corner rule: "if they happen to be in the corner, then the pushback will be applied to the attacker." Projectiles are the exception (https://game.capcom.com/cfn/sfv/column/131545?lang=en).
- Guilty Gear Strive does the same "making sure that the net pushback both characters experience is the same regardless of screen positioning" (https://dustloop.com/w/GGST/Mechanics).
- GBVSR numbers (https://dustloop.com/w/GBVSR/Mechanics):
  - Default pushback on hit is 125 at all attack levels.
  - On ground block it is 80, 75, 70, 65 and 60 for levels 0 to 4.
  - So hits push farther than blocks, and every hit pushes the same distance by default.
- SF6 values: I could not reach a source with per-move pushback distances. SuperCombo blocked me and Reddit was blocked, so I give no SF6 numbers.
- Wall and knockdown timings:
  - GGST wall stick recovers on its own after 59 frames. A soft knockdown lasts 30 frames and a hard knockdown 55 (https://dustloop.com/w/GGST/Mechanics).
  - GBVSR hard knockdown lasts 53 frames and ground recovery 32 (https://dustloop.com/w/GBVSR/Mechanics).

### Action games: keeping the attacker attached

- God of War 2018 started with "significant backward translation during hit reactions", which pushed enemies off screen.
  - The team cut hit-reaction translation while keeping impact, then added "strike assist", where "successive attacks pull targets closer into view".
  - They also gave reactions invisible collision so knocked enemies hit other enemies.
  - Source: a videohighlight.com summary of the GDC talk "Evolving Combat in God of War for a New Perspective" (https://videohighlight.com/v/hE5tWF-Ou2k). The GDC Vault entry is https://gdcvault.com/play/1026423/Evolving-Combat-in-God-of.
- The 2026-10-08 vault note already records that God of War cut enemy knockback "so Kratos can keep up with them", and that DMC1's Stinger pushed enemies away and undercut a closing move (see the vault3 Research notes).
- Elden Ring separates short push (Level 5, Kick) from long knockback (Level 4) and launch (Level 9) (https://eldenring.wiki.gg/wiki/Damage_Level).
- Genshin's light and heavy impulses share a 200 horizontal value, and only the strong heavy goes to 800 (https://library.keqingmains.com/combat-mechanics/poise). So most hits in a string barely move the target, and the big shove is saved for one strong hit.
- TSB M1 strings end by knocking the opponent forward on the 4th hit (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat). A Roblox fighting template likewise ends combos with "a finisher that has knockback" (https://www.creation.dev/templates/fighting-template).
- Nobody published a "victim slides X metres per light hit" number for a 3D action game that I could reach. Treat the per-hit stud values below as unsourced.

### Finishers, launches and walls

- TSB variants:
  - Jump plus the 4th M1 gives an uppercut with no horizontal knockback.
  - The downslam has no knockback, beats block and grounds the target (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
- God of War lets reactions "break reality with huge pose changes, flips, and even air juggling" (https://blog.playstation.com/?p=370399).
- It also caps how high enemies float above Kratos so they stay readable (https://videohighlight.com/v/hE5tWF-Ou2k).

## 3. Super armor, hyper armor and poise

### Terms

- For Honor developer UbiJurassic separates the two:
  - Hyper armor lets a hero finish an attack without being interrupted, and damage still applies.
  - "Super Armor only allows a hero to take a single hit without being interrupted by an attack."
  - "you can tell that a enemy has hyper armor by the white flash" on the model.
  - Players note hyper armor often "Kicks in" mid animation (https://steamcommunity.com/app/304390/discussions/0/1727575977572515975).
- Elden Ring defines hyper armor as extra poise during part of an action. Super armor is near-infinite poise, often on leaping skills (https://eldenring.wiki.gg/wiki/Super_Armor).
- GGST armor takes 50% damage and lets the move continue, and Overdrives ignore it (https://dustloop.com/w/GGST/Mechanics).
- SF6 Drive Impact absorbs at least 2 hits. An analysis suggests 3 hits beat it, and absorbing a hit causes slowdown (https://words.infil.net/w03-sf6beta-p2.html).
- A Gcores user post argues that continuous souls-style poise makes it "harder for players to tell whether their attack will interrupt", compared with binary armor in DMC and MH (https://www.gcores.com/talks/702375, translated, opinion).

### Numbers by game

- Elden Ring enemy poise (https://eldenring.wiki.gg/wiki/Poise):
  - Normal enemies have 15 to 65 and bosses 80 to 120. Radahn is the outlier at 200.
  - Some bosses take reduced poise damage: Night's Cavalry about 400 effective and Ancient Dragons about 600.
  - Regen is 13 poise per second, starting after base poise divided by 13 seconds. That is 5 s for 65 poise and 9.2 s for 120.
  - A break stuns "for a significant amount of time" and opens a riposte that resets poise. No exact stun duration was given.
- Elden Ring player side (https://eldenring.wiki.gg/wiki/Poise):
  - Practically all enemy attacks deal 50, 100 or much more poise damage.
- Dark Souls 1 enemy poise (https://darksouls.wiki.fextralife.com/Poise):
  - Silver Knight 45, Black Knight 80, Chaos Eater 90.
  - Chained Prisoner 80, and it "wont get staggered by light hitstun".
  - Artorias 130 or 90 while buffing.
  - Poise refills fully after 5 s without being hit.
- Monster Hunter: per-part flinch bars (above). No public numbers found. Wilds raised resistance.
- DMC: Dante Must Die adds aura-signalled flinch and launch resistance (above).
- Sekiro: posture instead of poise. Bosses need a posture break per health bar (https://sekiroshadowsdietwice.wiki.fextralife.com/Posture).
- God of War: I could not find a source for a yellow or orange enemy armor bar. Official cues are attack rings (https://www.playstation.com/fr-ca/games/god-of-war-ragnarok/god-of-war-combat-refresher-course/):
  - Yellow ring: parryable, but a plain block breaks your guard.
  - Red ring: unblockable.
  - Blue ring: interruptible by shield bash.
- God of War hard-counter enemies use "readable feedback when the discouraged tools aren't having an effect", for example axes bouncing off (Jason de Heras, https://www.thegamer.com/respawn-design-director-god-of-war-enemies-combat-mechanics/).

### Armor still needs feedback

- In Genshin, against enemies with unbroken poise you "add 0.06s to the attack's hitlag". Armored targets get more hit freeze, not less (https://library.keqingmains.com/combat-mechanics/frames).
- The GBVSR and GGST hitstop tables apply on hit regardless of armor, and SF6 armor absorption causes slowdown (https://words.infil.net/w03-sf6beta-p2.html).
- Visual cues that sources confirm:
  - For Honor: white flash.
  - DMC Devil Trigger: dark fiery aura and red eyes.
  - Lies of P: white HP-bar border when staggerable.
  - Sekiro: red deathblow marker.
  - Wuthering Waves: golden "Weakness Halo" for counter windows (https://twinfinite.net/guides/wuthering-waves-vibration-meter-explained/).

## 4. Roblox implementation notes

- Priority is evaluated per joint, from high to low. "When the track weight sum reaches or exceeds 1.0 for a joint, evaluation stops", and "Higher priority animation will override lower priority ones per joint" (https://create.roblox.com/docs/en-us/reference/engine/enums/AnimationPriority.md).
  - So an upper-body-only flinch at Action4 with weight 0.4 leaves 0.6 of the joint to the attack track underneath. That works as a cheap additive flinch on an enemy that keeps attacking (inference from the doc, unsourced as a tested technique).
  - Joints the flinch doesn't key keep playing the attack (inference).
- Same-priority tracks blend by weight. Play and AdjustWeight fade over fadeTime, default 0.1 s (https://create.roblox.com/docs/en-us/reference/engine/classes/AnimationTrack.md). Pass fadeTime 0 for hit reactions, following the zero-crossfade advice above.
- Replication (https://create.roblox.com/docs/en-us/reference/engine/classes/Animator.md):
  - For an Animator outside a player character, "its animations must be loaded and started on the server to replicate".
  - Player-character animations started on the owning client replicate to everyone.
  - So an NPC reaction played on the attacker's client stays local, which suits prediction.
- DevForum advice:
  - Play animations locally for responsiveness and use the server only for hit validation. "server replicate animation data and effects at same time" (https://devforum.roblox.com/t/combat-animation-desynchronization-with-high-ping/4073377).
  - Client-triggered reactions that wait on a server event always carry a delay (https://devforum.roblox.com/t/delayed-player-hit-animation/2592740).
- Knockback on NPC Humanoids:
  - Humanoids "have a custom physics system when the player is on the ground". Freefall and FallingDown can clear applied forces.
  - ApplyImpulse users scale by AssemblyMass (https://devforum.roblox.com/t/2686023).
  - LinearVelocity with math.huge force misbehaves on wall contact, so use a large finite cap. One developer needed 15,000 or more to get a consistent 10 studs over 0.5 s at 20 studs/s.
  - The same thread notes ground friction reduces travel and suggests setting the network owner to nil during knockback (https://devforum.roblox.com/t/trying-to-find-a-way-to-do-smooth-knockback-correctly/4736134).
  - Server-applied knockback on server-owned rigs was reported to jitter, and setting NPC network ownership to nil was the main suggestion (https://devforum.roblox.com/t/how-to-avoid-using-server-scripts-for-rigs-as-doing-this-makes-linear-velocity-jitter/2583215).
  - Ownership handoff to the attacker looked smooth to them but laggy to others. Massless on the root for about 0.5 s was offered as a partial fix (https://devforum.roblox.com/t/how-to-make-proper-knockback-for-a-combat-system/3936670).
  - For knockdowns, play an animation rather than relying on the Ragdoll state, which "won't really trip somebody" (https://devforum.roblox.com/t/knockback-humanoid-state-help/3318715).
- Preventing chains:
  - TSB gives 0.5 s of stun immunity after a ragdoll (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
  - A popular DevForum stun module keeps the longer of two overlapping stuns instead of stacking them (https://devforum.roblox.com/t/stun-handler-v2/1072859).
  - Dark Souls refills poise after 5 s without being hit (https://darksouls.wiki.fextralife.com/Poise). Elden Ring regen waits poise/13 s (https://eldenring.wiki.gg/wiki/Poise).

## What Sword Bound should build

All values here are (unsourced) judgment unless a URL is attached. They assume the current light string: hits at 0.19 s, a chain every ~0.42 s, a warp that stops 3.5 studs away and 7-stud reach.

### Reaction set (procedural keyframe specs are fine)

- Light flinch, 4 directions (front, back, left, right). Clip 0.40 s. (unsourced)
  - Peak pose on the first keyframe with fadeTime 0 (https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects).
  - Hold through hitstop, then ease out over the last 0.25 s.
  - Torso twist 15 to 20 degrees away from the hit, head snap 20 to 25 degrees, back foot slides. (unsourced)
- Heavy flinch, front and back. Clip 0.70 s, with a bigger torso fold and a stumble step. (unsourced)
- Stagger (poise break). Keep 1.1 s for the Sparring Knight and use 1.6 to 2.0 s for bosses. A riposte prompt is valid during it, matching the Elden Ring and Sekiro pattern (https://eldenring.wiki.gg/wiki/Poise, https://www.fromsoftware.jp/manual/sekiroshadowsdietwice/stadia/mechanics.html).
- Knockdown (finisher on fodder only). Fall plus get-up, about 1.5 s total, then 0.5 s of hit-reaction immunity like TSB (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
- Armor twitch (additive). 0.20 to 0.25 s, upper-body joints only.
  - Play at Action4 with weight 0.35 to 0.5 so the attack keeps playing underneath (https://create.roblox.com/docs/en-us/reference/engine/enums/AnimationPriority.md).

### Picking direction

- Proposed mapping (unsourced):
  - Forehand (right to left from the attacker) plays the victim's "hit from right" reaction.
  - Backhand plays the opposite side.
  - The overhead chop plays a heavy front reaction.
  - The spinning finisher plays the heavy back reaction plus the push.
- If the hit comes from behind (dot of victim forward against direction to attacker below -0.5), use the back reaction (https://swearsoft.itch.io/jackmclantern/devlog/76709/direction-based-hit-reaction).

### Hitstun timers (drive AI lockout separately from the clip)

- Fodder light hitstun 0.45 s, so a 0.42 s chain holds them through the string. Heavy 0.75 s. (unsourced)
- This is longer than fighting-game hitstun (12 to 22 frames, https://dustloop.com/w/GGST/Mechanics) because Sword Bound's cadence is slower.
- The AI can't act until the hitstun ends. The clip can blend out early when the AI acts.

### Pushback per hit and attacker step (unsourced)

| Hit | Victim slide | Over | Attacker step on hit | Net spacing change |
|---|---|---|---|---|
| Light 1 to 3 | 1.0 stud | 0.12 s | 0.9 stud (forward during active frames) | about +0.1 |
| Overhead (light 3) | 1.3 studs | 0.14 s | 1.1 studs | about +0.2 |
| Finisher spin | 4 to 5 studs (keep the current 4 for the Sparring Knight) | 0.20 s | 0 (plants) | +4 |
| Charged heavy | 2.5 studs, or knockdown on fodder | 0.18 s | 0.8 stud | +1.7 |

- Over a full 4-hit string the victim travels about 7 to 8 studs and the attacker about 3. Spacing stays at roughly 3.5 to 4.5 studs until the finisher opens it to about 8. That copies God of War's fix of small translations plus pulling the target in (https://videohighlight.com/v/hE5tWF-Ou2k).
- Push the attacker only when the hit connects, so whiffs don't over-commit.
- Wall rule: raycast behind the victim before pushing. If a wall is within the slide distance, cut the victim's slide and move the attacker backward by the leftover, like the SF and GG corner rule (https://game.capcom.com/cfn/sfv/column/131545?lang=en, https://dustloop.com/w/GGST/Mechanics).
- Armored or hyperarmored enemies get 25% of the slide, and bosses get 0 on lights. The attacker step still applies, so the player reads that the enemy didn't budge. (unsourced)

### Armor tiers (unsourced values, sourced patterns)

| Tier | Poise | Reaction to lights | Hyperarmor | Break result | Cue |
|---|---|---|---|---|---|
| Fodder (mobs, dummies) | 0 to 20 | Full directional flinch every hit, slide every hit | None | Knockdown on finisher | none |
| Soldier | 30 to 40 | Full flinch when idle or moving, armor twitch during attack windup after its commit point | From windup commit to end of active frames | Heavy flinch | brief white flash on armored hit (https://steamcommunity.com/app/304390/discussions/0/1727575977572515975) |
| Elite (Sparring Knight) | 60 (current) | Armor twitch during any attack, full flinch only when not attacking | Whole attack | Stagger 1.1 s plus riposte | white flash, heavier metal clank |
| Boss | 100 to 140, regen delay poise/13 s (https://eldenring.wiki.gg/wiki/Poise) | Armor twitch only, never flinch from lights | Always (super armor vs lights), heavies still deal poise | Stagger 1.6 to 2.0 s plus riposte | enrage phase aura like DMC (https://devilmaycry.fandom.com/wiki/Devil_Trigger) |

- The tier poise numbers sit inside Elden Ring's ranges (15 to 65 normal, 80 to 120 bosses) (https://eldenring.wiki.gg/wiki/Poise).
- Armored hits keep full hitstop plus about 0.03 to 0.06 s extra, sparks and camera shake, following Genshin's +0.06 s on unbroken poise (https://library.keqingmains.com/combat-mechanics/frames). Only the reaction clip and the slide shrink.

### Roblox wiring (unsourced unless linked)

1. The attacker client predicts immediately. On a local hit it plays hitstop, sparks and a locally loaded reaction track on the NPC's Animator at Action4, fadeTime 0. Because it was loaded on a client, it stays local (https://create.roblox.com/docs/en-us/reference/engine/classes/Animator.md).
2. The server validates the hit and fires one remote to the other clients with the NPC, the reaction id and the direction. They play the same local track. Don't play reactions on the server, so the attacker never sees a duplicate.
3. Keep the NPC's attacks played on the server, so they replicate (https://create.roblox.com/docs/en-us/reference/engine/classes/Animator.md).
4. The server owns NPC roots with SetNetworkOwner(nil) (https://devforum.roblox.com/t/how-to-avoid-using-server-scripts-for-rigs-as-doing-this-makes-linear-velocity-jitter/2583215).
5. Slide with one reusable LinearVelocity per NPC. Use a finite MaxForce, around 20,000 to 60,000, tuned for the rig (https://devforum.roblox.com/t/trying-to-find-a-way-to-do-smooth-knockback-correctly/4736134).
   - Overwrite the velocity on each new hit instead of adding a second mover.
   - Disable it after the slide time.
6. During hitstun:
   - Stop AI MoveTo and set WalkSpeed to 0, so the Humanoid's ground controller doesn't fight the slide (https://devforum.roblox.com/t/2686023).
   - Set AutoRotate false so the NPC doesn't snap to face the player mid-slide.
   - Restore all three when hitstun ends.
7. Chain limits:
   - Each hit can push once.
   - Cap total pushback at 10 studs per 2 s window.
   - Give 0.5 s reaction immunity after a knockdown (https://the-strongest-battlegrounds-rblx.fandom.com/wiki/Basic_Combat).
   - Keep the longer of overlapping stuns rather than stacking (https://devforum.roblox.com/t/stun-handler-v2/1072859).
8. Players as victims own their own characters. Apply their slide through the victim's client, keep it small, and accept the ping delay that DevForum users describe (https://devforum.roblox.com/t/how-to-make-proper-knockback-for-a-combat-system/3936670).

### Build order (unsourced)

1. Hitstun timer separate from the clip, plus the 4 directional light flinches on fodder and the Sparring Knight.
2. Per-hit slide and attacker step with the wall rule.
3. The armor twitch track and the tier table, starting with the Sparring Knight as Elite.
4. Boss tier when a boss exists, with the enrage cue.
