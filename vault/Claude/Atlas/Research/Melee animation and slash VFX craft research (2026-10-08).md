---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - animation
  - vfx
  - fighting-games
---

Up: [[Claude]] · Used by: [[Weapon models and effects plan]]

Produced by a research agent on 2026-10-08 for Henry's request to research big anime Roblox games and fighting games so their animation and effects design can be replicated. Reproduced as the agent returned it, with headings adjusted. Claims marked unsourced or judgment are the agent's own calls.

All frame counts are at 60 fps unless a source says otherwise (1 frame is about 16.7 ms). Every claim has a source number from the list at the bottom. Anything I could not source is marked "(unsourced, judgment)".

## Reddit and forum pass

Reddit itself was blocked. Fetching reddit.com and old.reddit.com returned SITE_BLOCKED, and WebSearch rejected a reddit.com domain filter with HTTP 400. I reached some Reddit threads through read-only mirrors (lr.vern.cc, lr.psf.lt, reddit.fabiomanganiello.com) and used three of them: r/darksouls [10], r/GranblueFantasyVersus [6] and r/MonsterHunter [14].

I found no usable r/gamedev, r/Fighters, r/Kappa, r/Unity3D or r/vfx threads on these exact topics. The other forums I did use are realtimevfx.com [22][23], the Roblox DevForum [27][28][31][33][34][35] and the Ultra-Combo forum [8]. SuperCombo and srk.shib.live pages were also unreachable because a bot wall (Anubis) blocked them, so I could not confirm Street Fighter 6 hitstop values.

## 1. Fighting game animation craft

**Guilty Gear Xrd and Strive.** Motomura's GDC 2015 material says the team tried full animation first and it "felt too 3D," so they removed interpolation entirely [1][2]. "Every frame now is a key frame, and the animator poses the character in the best way possible," which he compares to stop motion [3]. Other details from that material:
- Characters have around 500 bones so animators can adjust every feature frame by frame [3].
- The team built its own scale-animation system for squash, stretch and exaggeration [3].
- The rule was "deform the mesh every key frame, to add imperfection" [3].
- A video breakdown of the talk adds that some body parts hold still while hair or cloth keep moving [4].
- Smears are "smooth, stretched solid shapes," and hit effects and speed lines are 2D textures [4].

A forum discussion (Reddit mirror) says Strive mixes animation intervals inside one character, with some parts on 4s and some on 3s. Commenters there call Strive harder to read than Granblue because of its sparse keys and heavy motion blur [6]. That is the cost of the style: held poses read as powerful, but too few keys plus blur hurts clarity.

**Frame data vocabulary.** Startup is the frames before the hitbox is active, active is the hit window, and recovery is the frames until you can act again [7]. Street Fighter 6 Ryu is a clean light/medium/heavy ladder [9]:

| Ryu move | Startup | Active | Recovery |
|---|---|---|---|
| Standing light punch | 4 | 3 | 7 |
| Standing medium punch | 6 | 4 | 11 |
| Standing heavy punch | 10 | 5 | 18 |
| Standing heavy kick | 12 | 4 | 20 |

Heavier attacks cost roughly 2.5x the startup and recovery of lights.

**Hitstop numbers.** Guilty Gear Xrd's attack levels run Lv0 to Lv4 [5]:
- Hitstop goes 11, 12, 13, 14, 15 frames.
- Counter-hit hitstop on the receiver goes 11, 14, 17, 22, 27.
- Standing hitstun goes 10, 12, 14, 17, 19.

So stronger hits add only about 1 frame of hitstop per level, while counter hits roughly double it at the top level.

Sakurai's rules from his Famitsu column and video [11][12]:
- More damage means longer hitstop, with a hard cap so huge attacks do not freeze forever.
- Projectiles get less hitstop.
- Hitstop is kept shorter in multiplayer because a long freeze lets a third player strike.
- The victim shakes, horizontally on the ground and vertically in the air. The shake decays over the freeze and scales with camera distance.
- Hurtboxes stay still during the shake.
- The attacker keeps drifting very slightly during the freeze.

A forum thread argues hitstop should vary per move to sell weight: a jab is quick and an uppercut lingers [8].

**Making startup readable.** ZZZ's producer says they studied how Street Fighter gives "clear information" every frame. ZZZ also uses one-frame anime "impact frames" like Spider-Verse and Street Fighter [24].

## 2. Souls and action RPG melee

**Telegraphing.**
- Anatomy of a Dark Souls 3 enemy attack [15]:
  - Opening pose, then attack signal plus the attack itself, lasting at least **340 ms** (longer for unfamiliar moves).
  - The hitbox is active for only **2 to 4 frames**.
  - End pose lasts at least 240 ms if used as bait, or 170 ms otherwise.
  - Then a long return to idle that is the punish window.
  - The author puts human reaction at about 100 ms to perceive, 70 ms to think and 70 ms to act.
  - Signals cut below 340 ms are used sparingly because they become hard to dodge.
- Sekiro:
  - The deflect window is 30 frames by default and shrinks to 7 frames if guard was just released, which punishes mashing [17].
  - Perilous attacks get a red kanji [17].
  - An animator's thread describes Sekiro attacks as fixed "riffs" telegraphed by a huge anticipation, sometimes held over a second [16].
- Elden Ring parries (measured at 30 fps) [18]:
  - Most parry tools are 3 to 4 frames startup, 6 active, 13 recovery.
  - Curved swords are 3/4/14 and Golden Parry is 4/3/16.
  - The game gives no cue for which attacks are parryable.

**Weight within a class.** In Dark Souls, slow weapons in the same class (for example Stone Greatsword versus Claymore) have the same startup but about **6 frames (0.1 s) more recovery** per attack (r/darksouls via mirror) [10]. FromSoftware tunes weight inside a class through recovery and keeps startup the same.

**Player versus enemy timing.**
- Game Anim (Jonathan Cooper): player wind-ups should be short so the action follows the button press closely, while NPC wind-ups can be longer [19]. Set a baseline anticipation early and tune other moves relative to it, because some unresponsiveness reads as weight but too much feels sluggish [19].
- Pixel art guidance [20]:
  - Heavier weapons need slower anticipation and recovery.
  - One smear frame is often enough.
  - Holding the follow-through a little longer sells weight.
  - Freeze frames should be subtle.

**Cancels.** God of War splits attacks into pre-hit and post-hit frames. In the example, a 60-frame swing hits on frames 15 to 20 and can be cancelled from frame 21 [21]. Devil May Cry melee attacks are all post-hit cancels, and Ninja Gaiden allows no pre-hit cancels [21]. This maps directly to the existing CancelOpen and MoveOpen markers.

**Monster Hunter.**
- Producer Tsujimoto and director Tokuda said World's hitstop was too strong, so the Wilds beta used lighter hitstop. Players asked for stronger hits, and the team promised more hitstop plus sound for release [13].
- Community comparisons (r/MonsterHunter via mirror, MP1st) list Greatsword, Hammer, Charge Blade and Switch Axe as the weapons that felt hollow without hitstop. They also blame weaker camera shake, zoom and sound [14][25].
- One report says a Greatsword True Charged Slash gets "two to three freeze frames" [26]. That is weak sourcing.

The lesson is that heavy weapons depend most on hitstop, and players notice right away when it is cut.

**Hitstop research.**
- An IEICE study found the best hitstop was about **0.1 to 0.2 s**, and slow motion about 0.2 to 0.4 s [30].
- A VISIGRAPP 2024 VR study found mean "pleasant" hitstop around 0.37 to 0.39 s, with discomfort starting near **0.54 s**. Longer was generally more uncomfortable [29].

**Ghost of Tsushima, DMC and Black Myth Wukong.** I found no technical animation numbers. The GDC talk on Ghost of Tsushima is about lethality and balance [36], and VFX Voice covers only blood and wind particles [37]. Black Myth Wukong coverage was general mocap interviews. Treat these as not researched.

## 3. Anime and SAO slash VFX

**Riot's VFX style guide principles** [38][39]:
- One clear primary shape per effect.
- Size and intensity scale with power, so a basic attack must not look like an ultimate.
- Mostly mid-range values, with no pure black or white and no 0% or 100% saturation.
- One dominant color plus a complementary secondary.
- Motion blur along the travel path.
- Timing in three beats: anticipation, impact, resolution.
- Keep effects short so they do not clutter combat.

**Slash timing.** On realtimevfx, a reviewer told a slash artist that the effect felt "linear and slow," needed an explosive key moment and had to match the animation's swing direction. A slash spawning top to bottom on a bottom-to-top swing reads as wrong [22].

**SAO sword skill language.**
- A sword skill starts from a preset stance ("pre-motion"). The system recognizes it and **lights the weapon in the skill's hue**, then "system assist" performs the attack faster than a human could [40]. After the skill there is a cooldown [40]. The wiki's Starburst Stream entry describes Heathcliff slashing Kirito during the **post-motion delay**, so that recovery is canonically punishable [41].
- Colors are inconsistent across media. Sonic Leap is described as green, yellow-green or blue depending on the source [42], so Sword Bound can define its own scheme.
- Alicization Lycoris:
  - Skills cost SP.
  - A "flashing star" cue opens a skill-connect window into a second skill, and a passive extends it by about 1 s [43].
  - Long-windup skills like Vorpal Strike are bad for connects [43].
- Echoes of Aincrad:
  - It has the same weapon list Sword Bound uses: swords, rapiers, axes, daggers, two-handed swords and two-handed axes [44].
  - A **blue ring cue** signals a "reversal slash" [44].
  - Parry slashes trigger a cinematic camera cut [45].
  - Daggers give up shield parrying [44].
  - RPG Site's hands-on said combat "lacks the visual impact" and should feel "heavier" [45]. That is the gap Sword Bound can beat.
- Punishing Gray Raven: a perfect dodge triggers "Matrix," which slows time around the player [46].

## 4. Translating to Roblox

**Stepped animation.**
- `PoseEasingStyle.Constant` "does not blend" and snaps to the keyframe [47]. Code-built KeyframeSequences can set Pose.EasingStyle per pose to get Xrd-style holds.
- A practical mix (unsourced, judgment): Constant on the anticipation hold and the impact pose, and Linear or CubicV2 only on the fast swing frames. That gives readable held poses without making the swing itself choppy.
- Xrd's per-bone scaling for smears probably has no direct Roblox equivalent (unsourced, judgment). Use a 1 to 2 frame slash or smear mesh instead.

**Hitstop.** `AnimationTrack:AdjustSpeed(0)` pauses a track, and calling AdjustSpeed again resumes it [27][48]. Speed and TimePosition are flagged "Not Replicated" in the API docs, though the AdjustSpeed method is not [48].

DevForum advice is to drive animations on the client for smoothness and let the Animator handle replication [33]. One developer had to write custom replication because client playback mismatched across clients [34].

Recommendation (unsourced, judgment): when a hit is confirmed, fire an event and let **each client** apply hitstop locally to the attacker and victim tracks, plus the victim shake. Never pause world time in an MMO, which matches Sakurai's point about multiplayer freezes [11].

**Markers and blending.**
- `GetMarkerReachedSignal` covers HitStart, HitEnd, CancelOpen and MoveOpen [48].
- Priorities run Idle, Movement, Action, Action2, Action3, Action4, Core [49]. One layering option (unsourced, judgment): Action for locomotion overlays, Action2 for basic attacks, Action3 for sword skills, Action4 for stagger and hit reactions.
- `Play()` and `Stop()` default to a 0.1 s fade [48]. Pass 0 to 0.05 for snappy attack starts (unsourced, judgment).

**Trails.**
- Trail spans two attachments at the blade base and tip [50].
- Use WidthScale and Transparency sequences to taper it.
- Toggle Enabled between HitStart and HitEnd, then call `Clear()` [50].

**Beams.**
- CurveSize0/1 plus Segments bend a beam into an arc [51].
- TextureSpeed scrolls the texture [51].
- LightEmission 1 gives additive glow [51].

**Mesh slashes.**
- The DevForum crescent tutorial uses a squashed-sphere mesh with UVs, a polar-coordinates crescent texture, and **Texture objects** in place of the MeshPart TextureId so the mesh can be transparent [31].
- Texture `OffsetStudsU/V` can be tweened with TweenService to scroll [52]. I found no source saying SurfaceAppearance supports offset animation.
- DevForum commenters note particles are lighter on performance than mesh slashes [32].

**Particles.**
- Flipbooks support Grid2x2, Grid4x4 and Grid8x8 layouts [53].
- Textures must be square powers of two, up to 1024 [53].
- Modes are Loop, OneShot, PingPong and Random [54]. Use `Emit(n)` for impact bursts [55].

**Highlights.** Highlight has FillColor, OutlineColor, FillTransparency and DepthMode, with up to 255 shown per client. A disabled Highlight still uses a slot, so destroy it when finished [56]. Use it for a 1 to 3 frame white hit flash on the victim, and for the colored weapon glow during pre-motion (unsourced, judgment).

**Post effects and camera.**
- BloomEffect exposes Intensity, Size and Threshold [57]. A brief Bloom or ColorCorrection spike on sword skill impacts is my suggestion (unsourced, judgment).
- For camera shake, DevForum suggests a decaying random `Humanoid.CameraOffset` or the EZ Camera Shake module [35].
- An FOV punch of a few degrees on heavy hits is my suggestion (unsourced, judgment).

## What Sword Bound should do

**1. Lock one timing table and tune relative to it** [19]. Proposed player attack ranges by weapon (unsourced, judgment, built from the SF6 light/medium/heavy ratios [9], the DS3 340 ms readability floor [15] and the Dark Souls rule that weight shows up in recovery [10]):

| Weapon | Startup | Active | Recovery | Hitstop |
|---|---|---|---|---|
| Dagger | 5 to 8 f (83 to 133 ms) | 2 to 3 f | 10 to 14 f | 3 to 5 f (50 to 83 ms) |
| Rapier (thrust) | 7 to 10 f | 2 to 3 f | 12 to 16 f | 4 to 6 f |
| One-handed sword | 9 to 13 f | 3 to 4 f | 16 to 20 f | 6 to 8 f (100 to 133 ms) |
| Two-handed sword | 16 to 22 f (267 to 367 ms) | 4 to 6 f | 24 to 32 f | 8 to 11 f |
| Two-handed axe | 20 to 26 f (333 to 433 ms) | 4 to 6 f | 28 to 36 f | 10 to 12 f (167 to 200 ms) |

- Two-handed startups sit near or above 340 ms so they stay reactable in PvP and against parries [15].
- Hitstop sits inside the IEICE 0.1 to 0.2 s sweet spot for medium and heavy weapons [30]. Daggers go below it because they hit many times.
- Within a class, make "slow" variants differ by about 6 frames of recovery and keep startup the same [10].

**2. Sword skill hitstop.**
- Normal sword skill hits use 1.5x the class hitstop (unsourced, judgment).
- Finishers and counter or reversal hits jump toward Xrd's counter-hit levels, 17 to 27 frames (0.28 to 0.45 s) [5].
- Hard cap at about 0.5 s, below the ~0.54 s discomfort line [29], which also follows Sakurai's cap [11].
- Use Sakurai's shake rules on the victim [11][12].

**3. Sword skill VFX grammar.**
- **Pre-motion.** The weapon glows in the skill's color the moment the stance is recognized [40]. Hold that pose with Constant easing so it doubles as the readable startup [47][15].
- **Execution.** Use a mesh slash or Beam arc matched to the swing direction [22], shown for 1 to 2 frames as a smear, plus a Trail during active frames only [50].
- **Impact.**
  - Add a one-frame impact flash in the ZZZ style [24].
  - Add a flipbook burst [53].
  - Flash the victim's Highlight [56].
- **Post-motion delay.** Dim the weapon glow to gray and make it punishable, as in SAO canon [41]. If you add skill connects, show a flashing cue for the connect window, as Lycoris does [43].
- **Color coding** (unsourced, judgment, following Riot's tiering [38]): one hue per weapon class so opponents can read the weapon, with brightness and size scaling by skill tier. Reserve red for unparryable and blue for reversal or parry windows, matching Sekiro's red kanji [17] and Echoes of Aincrad's blue ring [44].
- **Keep it short.** Effects fade within about 0.3 s after impact so they do not clutter group fights [38] (unsourced, judgment for the exact number).

**4. Per-weapon VFX feel** (unsourced, judgment):
- Daggers get thin, fast trails and small sparks.
- Rapiers get a straight thrust streak plus a point flash.
- One-handed swords get the classic crescent.
- Two-handed swords get a wide, thick arc with a lingering ember tail.
- Two-handed axes get a short, heavy chunk arc plus ground debris, camera shake and an FOV punch.

Heavy weapons are where players notice missing hitstop and shake first [13][14].

**5. Netcode.** Keep animation, hitstop and VFX on the client, with the server confirming hits [33][34]. Never use global time stops [11].

## Sources
1. https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The
2. https://www.arcsystemworks.com/guilty-gear-xrd-art-talk-at-game-developers-conference-2015/
3. https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf
4. https://amara.org/videos/bDmpkclvfB5I/info/the-animation-of-guilty-gear-xrd-dragon-ball-fighterz
5. https://dustloop.com/w/GGXRD/Attack_Attributes
6. https://lr.psf.lt/r/GranblueFantasyVersus/comments/1kabyl7/gran_blue_rising_and_guilty_gear_animations (Reddit mirror)
7. https://esports.gg/guides/tekken-8/tekken-8-frame-data-beginners-guide/
8. https://forums.ultra-combo.com/t/why-isnt-hitstop-duration-standardized/24838
9. https://ultimateframedata.com/sf6/ryu
10. https://lr.vern.cc/r/darksouls/comments/bl6al8/comprehensive_list_of_attack_speed_differences (Reddit mirror)
11. https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/
12. https://nintendowire.com/news/2022/12/12/this-week-in-sakurai-12-5-12-11-fine-tuning-hit-stop-and-cheating-the-system/
13. https://gamingbolt.com/monster-hunter-wilds-weapon-hitstops-will-be-closer-to-what-people-are-looking-forward-to/amp
14. https://reddit.fabiomanganiello.com/r/MonsterHunter/comments/1gj4oqu/hitstop_in_mh_wilds_comparison_to_previous_games (Reddit mirror)
15. https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3
16. https://threadreaderapp.com/thread/1116028893125677057.html
17. https://sekiroshadowsdietwice.wiki.fextralife.com/Deflection
18. https://eldenring.wiki.gg/wiki/Parrying
19. https://www.gameanim.com/?p=115
20. https://slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks
21. https://www.gamedeveloper.com/pc/combat-canceled-i-god-of-war-i-action-game-design
22. https://realtimevfx.com/t/sword-slash-combo-advice-are-really-welcome/9379
23. https://realtimevfx.com/t/unity-air-slash-cut-vfx/13011
24. https://www.3djuegos.com/juegos/zenless-zone-zero/noticias/one-piece-spider-man-han-convertido-tendencia-street-fighter-parte-su-adn-ahora-zenless-zone-zero-quiere-llevarlo-paso-alla
25. https://mp1st.com/news/monster-hunter-wilds-combat-feeling-off-its-because-of-hitstops
26. https://opencritic.com/news/8376/monster-hunter-wilds-players-miss-the-hit-stop-from-world
27. https://devforum.roblox.com/t/pausing-animations/288995
28. https://devforum.roblox.com/t/particles’-flipbook-release/2029388
29. https://www.scitepress.org/Papers/2024/124614/124614.pdf
30. https://ken.ieice.org/ken/paper/20230315OCSt/eng/
31. https://devforum.roblox.com/t/crecent-sword-slash-effect/1113871
32. https://devforum.roblox.com/t/how-to-make-animated-slashes-20/1880010
33. https://devforum.roblox.com/t/latency-with-animtrackadjustspeed-on-serverscripts/405141
34. https://devforum.roblox.com/t/animation-replication-does-not-match-between-clients/1892776
35. https://devforum.roblox.com/t/2317381
36. https://gdcvault.com/play/1027184/Honoring-the-Blade-Lethality-and
37. https://vfxvoice.com/creating-the-way-of-the-warrior-for-ghost-of-tsushima/
38. https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips
39. https://gdcvault.com/play/1023943/Visual-Effects-Bootcamp-Artistic-Principles
40. https://otakumode.com/otapedia/anime/sword_art_online/sword_skills_sao
41. https://swordartonline.fandom.com/wiki/Starburst_Stream
42. https://swordartonline.fandom.com/wiki/Sonic_Leap
43. https://primagames.com/?p=313680
44. https://checkpointgaming.net/features/2026/06/echoes-of-aincrad-hands-on-preview-that-time-i-got-transported-into-a-video-game-again/
45. https://www.rpgsite.net/preview/20538-echoes-of-aincrad-pc-hands-on-preview-port-steam-deck-rog-ally
46. https://grayravens.com/wiki/Guides/Glossary
47. https://create.roblox.com/docs/reference/engine/enums/PoseEasingStyle
48. https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
49. https://create.roblox.com/docs/reference/engine/enums/AnimationPriority
50. https://create.roblox.com/docs/reference/engine/classes/Trail
51. https://create.roblox.com/docs/reference/engine/classes/Beam
52. https://create.roblox.com/docs/parts/textures-decals
53. https://devforum.roblox.com/t/particles’-flipbook-release/2029388
54. https://create.roblox.com/docs/reference/engine/enums/ParticleFlipbookMode
55. https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
56. https://create.roblox.com/docs/reference/engine/classes/Highlight
57. https://create.roblox.com/docs/reference/engine/classes/BloomEffect

## Research gaps
- No Street Fighter 6 or Tekken 8 hitstop values (bot walls).
- No Elden Ring per-class attack startup data.
- No HoYoverse, Kuro or SAO-game VFX artist breakdowns with technique detail. The 80.lv pieces I found were showcases without breakdowns.
- No technical animation numbers for Ghost of Tsushima, DMC, Bayonetta or Black Myth Wukong.
- The per-weapon timing table is my judgment anchored to the cited numbers, so it should be playtested.
