---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - animation
  - combat
---

Up: [[Claude]] · Used by: [[Sword combat feel revision]]

Produced by a research agent on 2026-10-08 after Henry said basic sword combat doesn't feel fun yet and asked for end-to-end research (Reddit, X, Discord and forums). How to compose a one-handed sword moveset so each attack reads differently, with a proposed set. Reproduced as the agent returned it. Claims marked unsourced are the agent's own calls.

Builds on "Combat animator workflow research (2026-10-08)" in the vault (three-phase attack anatomy, DS3 timings, hitstop table, Roblox root motion limits, SAO pre-motion grammar, 30 fps playbook). Those points are only referenced here, not repeated. Everything below is new material or a design proposal. Design proposals and anything without a URL are marked (unsourced).

## Access notes

- Reddit was not reachable. WebFetch on reddit.com returned SITE_BLOCKED. WebSearch with allowed_domains reddit.com was rejected by the proxy (HTTP 400). A plain "site:reddit.com" query ran but returned no reddit.com results at all (the filter was ignored and other forums came back). Some results pointed at third-party Reddit mirrors (lr.in.psf.lt, redlib.hackliberty.org, reddit.rtrace.io). I did not open any of them. No Reddit content is used in this report.
- X/Twitter was partly reachable. WebSearch with allowed_domains x.com returned real post titles and snippets. WebFetch on an x.com post failed with ROBOTS_DISALLOWED, so only search-result snippets were read. Nothing was retried through mirrors.
- Discord was searchable but no Discord content surfaced. A discord.com search returned only server directory and invite pages (Eclipse Animator, RoVFX, Combat Initiation and similar). No message content, guides or pinned posts were indexed. Discord is effectively not publicly indexed.
- Fextralife (Elden Ring wiki) returned ROBOTS_DISALLOWED. I used eldenring.wiki.gg and Bandai Namco's official guide instead.
- The DMC wiki page for Rapid Slash and the SAO wiki "Sword Skill" overview page failed to fetch (CLIENT_ERROR). Not retried.
- The shared web search budget ran out partway through. I could not do dedicated searches for Masahiro Sakurai's "Creating Games" episodes, SAO game sword skill animation breakdowns (Hollow Fragment, Lycoris, Integral Factor), or more Roblox animator interviews. Those gaps are noted where they matter.

## The direct answer to the owner

Yes, use a different animation, and more than that, a different shape. The current running attack is "a leaning version of Light1's forehand, same arc" (combat_brief.md). Players read an attack by its weapon path, its body silhouette and how far the body travels. If those three match Light1, a lean alone will not make it read differently.

- Elden Ring's official guide says a running attack is "a different attack from your normal swing," sometimes with extra reach or quicker execution (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide).
- Smash Bros dash attacks "come out quickly and cover a large horizontal range," inherit momentum from the dash, and have "noticeable ending lag that makes them committal" (https://www.ssbwiki.com/Dash_attack).
- DMC's Stinger "unleashes a powerful thrust after lunging forward" (https://devilmaycry.fandom.com/wiki/Stinger). It travels until it hits an enemy or reaches max distance (https://intothebluesky.com/2019/03/27/devil-may-cry-files-01-stinger/).
- A No Rest for the Wicked player review complains that one running attack "is shared between a lot of Weapons" and that a pause after the stab makes it clunky (https://forum.norestforthewicked.com/t/straight-swords-movesets-can-be-improved/23744).

Proposal (unsourced). Make the running attack a long lunging thrust in the Stinger or Rage Spike family. Pitch the torso about 35 to 45 degrees forward, fully extend the sword arm with the point leading, and move the body 7 to 9 studs. Stop the lunge on contact. A thrust is a line where every light attack is an arc, so it reads differently even from a bad camera angle.

## 1. How action games compose a sword moveset

### Light strings change plane on every hit

- Monster Hunter Wilds Sword and Shield basic combo is Chop, then Side Slash, then Diagonal Rising Slash, then Diagonal Chop. That is four different planes in four hits, and each can move if a direction is held (https://monsterhunterwiki.org/wiki/MHWilds/Sword_and_Shield_Mechanics).
- A mocap vendor's combat guide says "alternating attack directions help telegraph the next hit and prevent the visual monotony of identical swings repeating." It suggests at least 8 directional or positional variants per combo chain (https://mocaponline.com/blogs/mocap-news/combat-animation-games-guide).
- In Elden Ring, one-handed straight sword lights are "wide, horizontal swings," two-handed lights are "more vertical," the rolling light attack is a thrust, and one-handed heavies put "thrusts on every odd" attack (https://eldenring.wiki.gg/wiki/Straight_Swords). So the grip and the context change the plane, not only the button.
- On the Roblox DevForum, reviewer OBCBeeDev advised chaining attacks so each animation's first frame matches the previous one's end (https://devforum.roblox.com/t/r6-sword-system/1944439). In other words the follow-through of hit N is the anticipation of hit N+1. Alternating forehand and backhand swings makes this almost free (unsourced).

### Finishers are longer, multi-hit or whole-body

- Genshin frame data at 60 fps shows the shape of a sword string. Ayaka's hitmarks are N1 8 f, N2 10 f, N3 16 f, N4 three hits at 8, 15 and 22 f, and N5 27 f with 70 f before the next attack (https://library.keqingmains.com/characters/cryo/kamisato-ayaka). Keqing's are N1 10, N2 10, N3 14, N4 two hits at 11 and 22, and N5 22 (https://library.keqingmains.com/characters/electro/keqing). KQM counts frames at 60 fps (https://library.keqingmains.com/combat-mechanics/frames). The pattern is fast short openers, a multi-hit stage, then a slower heavy final.
- Genshin sword normals are described as "up to 5 rapid strikes." The sword charged attack unleashes "2 rapid sword strikes." The plunge "plunges from mid-air to strike the ground below" with AoE on impact (https://genshin-impact.fandom.com/wiki/Normal_Attack).
- Ayaka's N1 lands at 8 f (133 ms) and Keqing's at 10 f (167 ms). Sword Bound's Light1 HitStart is 0.26 s, about 16 f at 60 fps (combat_brief.md). Souls games are slower on purpose, but this gap helps explain why the owner calls the combat slow.
- DMC 4's Red Queen has Combo B, "a strong, but slow finishing blow" reached by pausing between inputs, and Combo D "with a strong finishing blow" (https://www.gamepressure.com/devilmaycry4pc/skills/ze1427). Delay-timed variants give a second finisher without new buttons.
- Monster Hunter Long Sword's Spirit Blade combo ends in a Spirit Roundslash. Its third and fourth hits "require a large amount of commitment" (https://intothebluesky.com/2021/01/25/monster-hunter-rise-longsword-guide/).

### Dash and running attacks

- DMC Stinger is a lunging thrust that travels far, and DMC 3 chains it into Million Stab, a flurry of fast stabs (https://devilmaycry.fandom.com/wiki/Stinger, https://strategywiki.org/wiki/Devil_May_Cry_3:_Dante's_Awakening/Weapons_and_Upgrades).
- Nero's Streak is "a horizontal sweeping slash that rushes forward," closer to Vergil's Rapid Slash than to Stinger (https://devilmaycry.fandom.com/wiki/Stinger). A DMC rush analysis says Rapid Slash "deals knockback across a huge hitbox" (https://intothebluesky.com/2019/04/01/devil-may-cry-files-02-rushes-pt-1/).
- DMC's first game had a problem where Stinger knockback "pushed the enemy away, undermining the point of a closing attack" (https://intothebluesky.com/2019/03/27/devil-may-cry-files-01-stinger/). For a souls-like, a running attack that ends next to the target is better than one that launches it (unsourced).
- Monster Hunter Wilds Advancing Slash is "an upward slash performed while advancing forward" (https://monsterhunterwiki.org/wiki/MHWilds/Sword_and_Shield_Mechanics). That is a valid second running-attack shape if a thrust is not wanted.
- ZZZ treats the dash attack as its own move category. Harumasa's "launch[es] multiple piercing attacks ahead." His alternate dash attack will "rush forwards to the closest X-Marked enemy and execute a powerful slash" (https://www.icy-veins.com/zenless-zone-zero/asaba-harumasa-profile-skills-mindscapes). Miyabi's dash attack "slashes enemies in front" (https://www.prydwen.gg/zenless/characters/miyabi).
- 9 Monkeys of Shaolin's dash attack plays a starting animation, multiplies the player's max speed toward the target, and pauses the animation while the player closes the distance (https://www.unrealengine.com/tech-blog/9-monkeys-of-shaolin-developer-sobaka-studio-shares-how-to-create-a-satisfying-combat-system). This is the "travel pose, then strike" pattern.
- A Construct forum fix ends the dash attack when velocity reaches zero rather than when the clip ends, and reduces speed every tick during the attack (https://construct.net/en/forum/construct-2/how-do-i-18/solved-good-beat-em-125957).

### Jump, heavy, counter and context variants

- DMC Helm Breaker: "Dante drops straight down with a powerful vertical slash." High Time is an uppercut launcher on back plus attack. Prop and Shredder spin the sword (https://strategywiki.org/wiki/Devil_May_Cry_3:_Dante's_Awakening/Weapons_and_Upgrades).
- DMC 4's Split is "a vertical attack from air damaging all the enemies below" (https://www.gamepressure.com/devilmaycry4pc/skills/ze1427).
- Elden Ring jump attacks increase stance damage. Guard counters are a slow, strong swing after a block that "can stance break enemies" (https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide).
- Monster Hunter Long Sword goes straight to the Rising Slash when attacking out of a dodge. Fade Slash moves left, back or right while attacking. Foresight Slash dodges backward and then attacks (https://intothebluesky.com/2021/01/25/monster-hunter-rise-longsword-guide/, https://mhworld.kiranico.com/guide/long-sword?ver=g1).
- Monster Hunter Roundslash lets you "quickly change your direction" during a wide slash (https://monsterhunterwiki.org/wiki/MHWilds/Sword_and_Shield_Mechanics).
- Wuthering Waves sword Rover has a 4-stage basic attack, a stamina heavy, and a mid-air plunge. Tapping attack shortly after landing jumps straight to Basic Attack Stage 4. A dodge counter fires on attack right after a successful dodge (https://genshin-builds.com/en/wuthering-waves/characters/rover_aero). Context moves feed back into the string instead of resetting it.
- ZZZ dodge counters are their own slot. Harumasa's "pierces enemies in front" and Miyabi's "slashes enemies in front" (sources above).

### Roblox anime games

Prior vault research covered TSB, JJS, Deepwoken, Blox Fruits, Arcane Odyssey, Swordburst 3 and Combat Warriors, so they are not repeated here. One new data point is a sold R6 pack with "four M1s per weapon" across five weapons, plus aerial and crit attacks. It has no dash attacks and gives no frame counts (https://builtbybit.com/resources/r6-weapon-combat-animations.112425/updates). A Roblox combat animator's portfolio describes an upper-body M1 chain where "in-game movement blend trees control the lower body until the final M1 finisher" (https://yahy-portfolio.carrd.co/). That suggests M1s 1 to 3 are upper-body only and the finisher is full body (paraphrase of the page).

### SAO canon one-handed sword skills

New in this pass. Vorpal Strike, Horizontal Square, Sonic Leap and Starburst Stream are in the prior vault report.

- Slant is "a single sharp forty-five degree diagonal slash," upper right to lower left from a sword-on-shoulder pre-motion, or upward from a waist-draw stance (https://swordartonline.fandom.com/wiki/Slant).
- Horizontal is a single horizontal slash. The weight goes on the right foot, the sword moves back slightly, and the blade's momentum lifts the left foot as weight shifts left (https://swordartonline.fandom.com/wiki/Horizontal).
- Vertical Arc is two hits forming a "V." It goes top-left to bottom-middle, then a wrist flip goes bottom-middle to top-right. The user is left "rigid" afterward, and Slant can be chained before the delay ends (https://swordartonline.fandom.com/wiki/Vertical_Arc).
- Vertical Square opens with "a powerful stamp." It strikes overhead down, then two upward slashes, then a full-power overhead down. The four hits draw a square (https://swordartonline.fandom.com/wiki/Vertical_Square).
- Rage Spike starts crouched low, torso leaning forward, sword parallel to the right leg. It is "an upward slash from the right" after charging "about ten meters in nearly an instant" along the ground (https://swordartonline.fandom.com/wiki/Rage_Spike).
- Sonic Leap raises the sword "atop one's shoulder." It is "a single top to bottom vertical slash" after charging "over twice the distance," and its trajectory "can be aimed at the sky" (https://swordartonline.fandom.com/wiki/Sonic_Leap).
- One Lycoris review calls early combat "clunky and slow." It says lock-on is "temperamental, occasionally throwing your attacks in the wrong direction" (https://www.thesixthaxis.com/2020/08/19/sword-art-online-alicization-lycoris-review/). That is a warning for Sword Bound's lock-on lunge steering. I found no detailed source on how the SAO games animate sword skills because the search budget ran out.

Rage Spike and Sonic Leap are both gap closers, but they end in opposite arcs, one low-to-high and one high-to-low. That is the same principle this report recommends for the running attack (unsourced observation).

## 2. Readability principles

- Silhouette and line of action. Animation Mentor says to choose "a single clear line of action." For strikes, align that line with the direction of force and extend it. Keep the key action outside the body outline (https://www.animationmentor.com/?p=96066). For a thrust, that means one straight line from the rear heel through the hips to the sword tip (unsourced application). An 80.lv breakdown praises a combo whose silhouette "remains perfectly readable." It says to reduce each move to three poses, anticipation, impact and recovery, and check that those alone read (https://80.lv/articles/breakdown-animating-tiny-character-with-massive-two-handed-weapon).
- Anticipation versus payoff. Player-character anticipation should be shorter than NPC anticipation so controls do not feel delayed. DMC's "actions are big and so easily read" (https://www.gameanim.com/?p=115). "Too much anticipation will give a nasty feeling of input lag" (https://slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks).
- Wide arcs read as slow and strong, and narrow ones as fast and weak. A pure thrust or pure horizontal slash needs more aiming precision than a wide sweep (https://slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks). So the running thrust should have generous steering or a slightly wider hitbox than its look suggests (unsourced).
- Smear frames "connect an object or character from Point A to Point B in as few frames as possible." They are most common "in combat move sets featuring swords," including Genshin Impact (https://www.bloopanimation.com/the-art-of-smear-frames/). "Usually a single smear frame can get the job done" (https://slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks). On Roblox, the practical equivalent is a blade Trail between two attachments (https://create.roblox.com/docs/reference/engine/classes/Trail), plus a one-frame stretched pose (unsourced).
- Holds. Brad Faucheux's Gnomon course covers "holding frames at impact," "longer hold frames," "hitstop simulation" and "spacing for clarity in gameplay" (https://bmc.thegnomonworkshop.com/workshops/animating-stylized-attacks-in-maya). A moving hold lets a character "hold a key pose for a long time without looking dead" by easing in, overshooting slightly and overlapping wrists and head (https://animationmentor.com/blog/why-all-animators-need-to-master-the-moving-hold). Finishers and sword skill post-motion delays are where holds belong (unsourced).
- Hip drive. A Polycount critique of a slow attack asked for "the build up of momentum in the hips, then the drive of power through the hips" (https://polycount.com/discussion/223458/critique). SAO's Horizontal description is the same idea, "power from the legs and waist" (https://swordartonline.fandom.com/wiki/Horizontal).
- Sound and VFX change perception. In 9 Monkeys of Shaolin, "the different set of sounds and effects can dramatically change the perception of an attack" (https://www.unrealengine.com/tech-blog/9-monkeys-of-shaolin-developer-sobaka-studio-shares-how-to-create-a-satisfying-combat-system). Give the running attack its own whoosh and a longer trail (unsourced).

How animators make a dash attack feel fast. Everything here except the Smash and 9 Monkeys points is (unsourced) synthesis.
1. Inherit the sprint velocity instead of stopping and starting. Smash dash attacks carry "a large amount of momentum inherited from the prior dash" (https://www.ssbwiki.com/Dash_attack).
2. Use almost no anticipation. The sprint itself is the windup, so go to the extended pose within 3 to 5 frames at 60 fps.
3. Lean the torso forward and keep the head ahead of the hips.
4. Hold the extended pose while traveling (the 9 Monkeys pattern).
5. Add a stretch or smear frame and a long trail at full extension.
6. Stop the travel on contact, then add a skid and recovery with real end lag so it stays committal (Smash).

## 3. Roblox specifics

### Do top Roblox combat games hand-animate?

The evidence is weak but consistent. X search snippets show a TSB update animator posting "The animations i made for this TSB update #robloxdev #moonanimator #blender" (https://x.com/VeilUnbound/status/1802383367297486976). They also show an animator posting "Dagger Animations I made, Heavy and M1s #Blender #R15 #Roblox #MoonAnimator" (https://x.com/RoseLitAnims/status/2040112795736297671). Only the hashtags were readable because X blocks fetching. A 2019 post by loleris, a well-known Roblox developer, sought an animator "USING EXTERNAL SOFTWARE like blender or cinema 4D" for weapon animations (https://twitter.com/lolerismad/status/1171724232654577664). On the DevForum, Blender is recommended as the main alternative to Moon Animator 2 (https://devforum.roblox.com/t/any-alternatives-to-ma2-moon-animator-2/4770365). I found no public frame counts for M1s in TSB, Deepwoken, JJS or similar games. Any number would be a guess. The closest public frame data comes from Genshin (above).

### Are procedural keyframe specs a reasonable path?

- In Sword Bound, "procedural keyframe specs" are hand-authored poses written as code. That is still keyframing, just without a viewport. Overgrowth showed few keys plus procedural layers can look fluid (prior vault report, https://www.gameanim.com/?p=15568).
- An anim.works article on procedural animation says procedural systems "are not very good at conveying intention and personality." It adds that when a specific pose must land on a specific frame, "you usually want an animator, not a solver." Procedural methods are strongest for foot IK, look-at, hit reactions and secondary motion (https://anim.works/?p=24611).
- In a Polycount discussion of the Overgrowth talk, one poster says procedural animation should "take out the repetitive and draining parts of animation." Another worries that "too much control could be taken away" (https://polycount.com/discussion/comment/2093086).

Where code specs fall short (unsourced, based on the sources above):
- No visual arc feedback, so the tip path ends up kinked or flat.
- Joints tend to start and stop together instead of overlapping, which reads stiff.
- Constant and Linear easing only gives snap or robotic spacing.
- Smear or stretch poses are hard to author blind.

Proposed path (unsourced). Keep code specs for the light string and utility moves. Add offset keys per joint, overshoot and settle, and the tip-arc plot from the prior report. Hand-pose the five hero moves in Blender or Moon Animator, using the code spec as blocking: running attack, finisher, heavy, and two sword skills. Animation Capture from a filmed reference is a free middle ground (prior vault report).

### Bake travel into the animation or use physics lunges?

- Roblox animation does not move the HumanoidRootPart (prior report). A DevForum answer calls the proper fix "convert the root motion in the animation into velocity on the HumanoidRootPart." The hack is to CFrame the root to the end position on the track's Ended event, which "is a mini-teleport" that can clip through walls (https://devforum.roblox.com/t/animation-that-changes-position/2859267).
- Another DevForum answer had the animation take a step forward and back, with the HumanoidRootPart moved in sync with those steps (https://devforum.roblox.com/t/combat-locomotion/1436335). The same thread lists failures of BodyMovers on terrain, Velocity launching players, and CFrame on slopes.
- The mocap guide says "in-place root motion with code-controlled displacement is often more predictable" than authored root motion (https://mocaponline.com/blogs/mocap-news/combat-animation-games-guide).

Recommendation (unsourced). Keep Sword Bound's code-driven LinearVelocity lunge. Give each move its own travel curve (distance, start time, duration, ease, stop-on-hit) stored next to the animation spec and triggered by its Lunge marker. Author the feet in the animation to match that distance so they do not skate. That is the "animation step plus synced root move" pattern from the DevForum answer.

## Proposed Sword Bound one-handed sword moveset (all unsourced design)

Conventions. Times are seconds from the input, matching the existing markers. Studs are body travel from the code lunge (1 stud = 0.28 m per https://create.roblox.com/docs/physics/units). "Plane" is the sword tip path seen from the player's camera. Every move in the set has a unique combination of plane, travel and end pose. That is the rule that fixes "looks the same."

Light string. Each hit's end pose is the next hit's start pose.

| Move | Arc / plane | Body travel | Timing (HitStart / HitEnd / CancelOpen / MoveOpen) | What makes it read differently |
|---|---|---|---|---|
| Light 1 | Forehand horizontal, right to left at chest height, slight downward tilt (Horizontal shape) | 1.5 studs, right foot steps | 0.16 / 0.24 / 0.34 / 0.55 | Flat wide arc, torso twists left, ends with sword on the left hip ready for a backhand |
| Light 2 | Backhand rising diagonal, low-left to high-right | 1.5 studs, left foot steps | 0.14 / 0.22 / 0.32 / 0.55 | Opposite rotation, rising line, ends with sword high over the right shoulder (sets up Light 3) |
| Light 3 | Overhead vertical chop, top to bottom | 2 studs, hips drop on contact | 0.20 / 0.28 / 0.42 / 0.65 | Only vertical light, body compresses down, tip ends low in front |
| Light 4 (finisher) | 360 degree spinning horizontal at waist, one full turn | 2.5 studs during the spin | 0.26 / 0.40 (spin sweeps) / 0.70 / 0.90 | Whole-body rotation, back briefly to camera, wide low end pose held about 0.10 s, 1.5x hitstop, knockback |
| Running attack | Straight thrust, point leading (Stinger or Vorpal line) | 7 to 9 studs, inherits sprint speed, about 40 studs/s, stops on contact | Active 0.10 to 0.30 while traveling / CancelOpen 0.60 / MoveOpen 0.75 | Only light-button move that is a line, torso pitched 35 to 45 degrees, arm fully extended, long trail, skid recovery |
| Jump attack | Plunging vertical slash, two-hand grip | Drops straight down, 1 stud forward | Apex hold 0.08, HitStart on landing, recovery 0.50 | Tucked apex pose, then a fast drop, ground-impact VFX and camera shake (Helm Breaker family) |
| Heavy (charged) | Two-handed diagonal cleave from high over the right shoulder (Slant line, bigger) | Uncharged 1 stud, full charge 2.5 studs with a stamp step | Charge 0.2 to 1.0, then HitStart 0.10 after release / CancelOpen 0.80 | Off hand joins the grip, torso cocked back during charge (biggest anticipation in the set), long hold after contact |
| Roll attack | Low rising slash, from near the ground upward (Monster Hunter Long Sword "Rising Slash out of dodge" logic) | 1.5 studs in the roll direction | 0.12 after roll exit / 0.20 / 0.40 / 0.55 | Starts crouched from the roll, the only attack that begins low, replaces the current Pierce thrust so it no longer copies the running attack |
| Guard counter | Off-hand shove, then backhand horizontal left to right | 0 studs on the shove, 1 stud on the cut | Shove 0.08, cut HitStart 0.18 / 0.26 / 0.50 / 0.65 | Starts from the guard pose, two beats (shove then cut), planted feet, stance-break hit (Elden Ring guard counter role) |

Starter Sword Skills. Each has the SAO grammar of pre-motion pose plus glow, system-assisted motion, and post-motion delay.

| Skill | Pre-motion (sourced pose) | Arc | Body travel | Timing (pre-motion / hits / post-motion delay) | Reads differently because |
|---|---|---|---|---|---|
| Rage Spike (ground gap closer) | Crouched, torso forward, sword parallel to right leg (Rage Spike wiki) | Low-to-high rising slash from the right at the end of the charge | 16 to 20 studs along the ground (canon is about 10 m, about 36 studs, scaled down for melee range) | 0.20 / hit at the end of the charge, about 0.45 / 0.50 | Crouched glow pose, ground-hugging rush, ends in an upward slash, so it is distinct from the running thrust |
| Sonic Leap (air gap closer) | Sword raised atop the shoulder (Sonic Leap wiki) | Top-to-bottom vertical slash after a leaping charge, can be aimed upward at airborne targets | 12 to 16 studs on an arc | 0.25 / hit about 0.50 / 0.55 | Only skill that leaves the ground, high-to-low ending, the mirror of Rage Spike |
| Vertical Arc (2-hit) | Sword high on the left (unsourced pose) | "V" shape, top-left to bottom-middle, wrist flip, bottom-middle to top-right (Vertical Arc wiki) | 1 stud | 0.15 / 0.10 and 0.25 / 0.40, then a skill-connect window into Slant later | Two bright trail strokes forming a V, the rigid end pose matches canon |
| Horizontal Square (4-hit, first unlock after the starters) | Blade pulled back and to the right (prior vault report) | Four alternating horizontal slashes that trace a square of light | Steps around the target, about 1 stud per hit | 0.25 / hits about 0.12 apart / 0.60 | Trail VFX draws a literal square, so it is the most legible skill in the set |

Later unlocks (unsourced). Slant and Vorpal Strike. Vorpal Strike reuses the running thrust's line but gets a long pre-motion hold, twice the reach and a long post-motion delay. Its glow and its stop-and-hold distinguish it from the sprint version.

Why this set avoids sameness (unsourced). Every attack is unique on at least two of these axes.
- Plane: horizontal, rising diagonal, vertical, spin, thrust line, rising low, plunge.
- Start height: high, mid or low.
- Travel: 0 to 20 studs.
- Hands: one or two.
- End pose.

The three gap closers are the running thrust, Rage Spike and Sonic Leap. They share the job but end in a straight, a rising and a falling arc. Those are the three most different endings available.

Implementation notes for the current code (unsourced).
1. Change the running attack's spec to the thrust pose. Raise its lunge scale so it travels 7 to 9 studs. Add stop-on-hit and a 0.10 to 0.15 s travel-hold pose before full extension.
2. Shorten light HitStarts from 0.26 to 0.14-0.20. Turn on Cubic easing for the strike segments, since Constant and Linear only snap or move robotically.
3. Give each move its own travel curve entry.
4. Fix the steering bug the SAO Lycoris review warns about. Only steer the lunge toward a target inside the cone, and never reverse it.
5. Add a blade Trail whose lifetime is longer on the running attack, finisher and skills than on the lights.

## Sources

- https://www.bandainamcoent.com/news/elden-ring-introduction-part-4-combat-guide
- https://eldenring.wiki.gg/wiki/Straight_Swords
- https://www.ssbwiki.com/Dash_attack
- https://devilmaycry.fandom.com/wiki/Stinger
- https://intothebluesky.com/2019/03/27/devil-may-cry-files-01-stinger/
- https://intothebluesky.com/2019/04/01/devil-may-cry-files-02-rushes-pt-1/
- https://strategywiki.org/wiki/Devil_May_Cry_3:_Dante's_Awakening/Weapons_and_Upgrades
- https://www.gamepressure.com/devilmaycry4pc/skills/ze1427
- https://monsterhunterwiki.org/wiki/MHWilds/Sword_and_Shield_Mechanics
- https://intothebluesky.com/2021/01/25/monster-hunter-rise-longsword-guide/
- https://mhworld.kiranico.com/guide/long-sword?ver=g1
- https://genshin-impact.fandom.com/wiki/Normal_Attack
- https://library.keqingmains.com/characters/cryo/kamisato-ayaka
- https://library.keqingmains.com/characters/electro/keqing
- https://library.keqingmains.com/combat-mechanics/frames
- https://genshin-builds.com/en/wuthering-waves/characters/rover_aero
- https://www.icy-veins.com/zenless-zone-zero/asaba-harumasa-profile-skills-mindscapes
- https://www.prydwen.gg/zenless/characters/miyabi
- https://swordartonline.fandom.com/wiki/Slant
- https://swordartonline.fandom.com/wiki/Horizontal
- https://swordartonline.fandom.com/wiki/Vertical_Arc
- https://swordartonline.fandom.com/wiki/Vertical_Square
- https://swordartonline.fandom.com/wiki/Rage_Spike
- https://swordartonline.fandom.com/wiki/Sonic_Leap
- https://www.thesixthaxis.com/2020/08/19/sword-art-online-alicization-lycoris-review/
- https://forum.norestforthewicked.com/t/straight-swords-movesets-can-be-improved/23744
- https://construct.net/en/forum/construct-2/how-do-i-18/solved-good-beat-em-125957
- https://www.unrealengine.com/tech-blog/9-monkeys-of-shaolin-developer-sobaka-studio-shares-how-to-create-a-satisfying-combat-system
- https://mocaponline.com/blogs/mocap-news/combat-animation-games-guide
- https://www.gameanim.com/?p=115
- https://www.gameanim.com/?p=15568
- https://slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks
- https://www.bloopanimation.com/the-art-of-smear-frames/
- https://www.animationmentor.com/?p=96066
- https://animationmentor.com/blog/why-all-animators-need-to-master-the-moving-hold
- https://bmc.thegnomonworkshop.com/workshops/animating-stylized-attacks-in-maya
- https://80.lv/articles/breakdown-animating-tiny-character-with-massive-two-handed-weapon
- https://polycount.com/discussion/223458/critique
- https://polycount.com/discussion/comment/2093086
- https://anim.works/?p=24611
- https://devforum.roblox.com/t/r6-sword-system/1944439
- https://devforum.roblox.com/t/combat-locomotion/1436335
- https://devforum.roblox.com/t/animation-that-changes-position/2859267
- https://devforum.roblox.com/t/any-alternatives-to-ma2-moon-animator-2/4770365
- https://builtbybit.com/resources/r6-weapon-combat-animations.112425/updates
- https://yahy-portfolio.carrd.co/
- https://x.com/VeilUnbound/status/1802383367297486976 (search snippet only)
- https://x.com/RoseLitAnims/status/2040112795736297671 (search snippet only)
- https://twitter.com/lolerismad/status/1171724232654577664 (search snippet only)
- https://create.roblox.com/docs/physics/units
- https://create.roblox.com/docs/reference/engine/classes/Trail
