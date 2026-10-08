---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - animation
---

Up: [[Claude]] · Used by: [[Weapons and effects production]]

Produced by a research agent on 2026-10-08 after Henry decided Claude builds all final meshes, effects and animations itself, and asked for end-to-end research into how artists and animators actually work. Reproduced as the agent returned it, with headings adjusted. Claims marked unsourced or judgment are the agent's own calls.

**Access notes.** Reddit could not be reached. WebFetch on reddit.com returned SITE_BLOCKED, and a WebSearch limited to reddit.com was rejected by the proxy (HTTP 400). So r/animation, r/gameanimation and r/robloxgamedev were not read. For the forum pass I used the Roblox DevForum (6 threads) and Polycount (1 critique thread) instead. **No images were downloaded.** The container's egress proxy returned 403 for upload.wikimedia.org, commons.wikimedia.org, nga.gov, metmuseum.org, wellcomecollection.org, loc.gov and archive.org, and I did not try to get around that. I wrote /mnt/user-data/outputs/vault_images/animation/MANIFEST.md with 10 candidate images whose license I checked on the source page. Most are NGA public-domain Muybridge plates (fencing, pick swing, two-handed hammer, striking, throws), plus the Met's public-domain Meyer 1570 entry. They are ready to download from a machine where those hosts are allowed.


## 1. How professional combat animators work

**Three phases.** Every attack breaks into anticipation, attack and recovery (https://gdkeys.com/keys-to-combat-design-1-anatomy-of-an-attack/). In a Dark Souls 3 teardown, the hitbox is "only active in 2-4 frames". Attack signal plus attack lasts at least 340 ms, an end pose before return lasts at least 170 ms, and the return is usually the longest phase (https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3). GD Keys gives these rules:
- Make the attack phase only a few frames long, even if that bends physics.
- Keep strike paths clean and consistent.
- End recoveries in the idle pose so cancels blend cleanly.
- Make each anticipation "drastically different" from the others.
- Base anticipation time on reaction time (about 0.25 s) plus a buffer (gdkeys).

**Anticipation versus responsiveness.** Jonathan Cooper says too little anticipation leaves a sword swing with "little weight", and too much makes it "feel unresponsive". Enemies can afford longer telegraphs. Follow-through carries fewer gameplay limits, so the engine should let the animator mark "a frame where the player regains control before the end". A sword swing should be "fast in but a slow out" (https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games, an excerpt from Game Anim). He also warns:
- Clean arcs on every body part "can look light or floaty". Break arcs on purpose, for example a head snap.
- Timing follows distance over speed, and faster reads as lighter.
- Keep the level of exaggeration the same across the whole project (same source).

**Pipeline order.**
1. Plan the action.
2. Block key poses in stepped mode.
3. Switch to spline to judge timing and retime.
4. Add follow-through and overlap (https://www.pluralsight.com/resources/blog/software-development/stepped-vs-spline-curves-blocking-animation).

Jason Shum's Gnomon course follows the same order: strong key poses, then breakdowns, arcs and retiming, run as first, second and polish passes (https://framestore.thegnomonworkshop.com/blog/combat-animation-for-games-with-jason-shum). Brad Faucheux's course adds Graph Editor work, motion trails, offset keys, smears and hitstop simulation (https://www.cgchannel.com/2025/07/tutorial-animating-stylized-attacks-in-maya/).

**Reference.** Animation Mentor's sword-fight tutorial says:
- Film reference with props of similar weight, and draw over it to find silhouettes.
- 1:1 reference timing "feels too slow on screen", so retime it snappier.
- Heavier weapons need "extra drag and delay".
- A stab accelerates until it meets resistance. A cut slows through the target and then "accelerates it sharply as it exits" (https://www.animationmentor.com/blog/tutorial-animate-sword-fights-battle-sequences/).

AnimSchool says to push the line of action and silhouette beyond the video reference. The test is whether you can read the action "from looking at the blacked out shape" (https://blog.animschool.edu/tag/line-of-action/).

**Example frame breakdown.** One student blog records a tutorial's timing for a 30 f attack:

| Frame | Pose |
|---|---|
| 0 | Idle |
| 10 | Anticipation |
| 12 | Extreme |
| 13 | Attack |
| 14 | Cushion |
| 20 | Hold |
| 30 | Idle |

It also notes the anticipation pose should sit close to the extreme (https://lucylueng.myblog.arts.ac.uk/2021/12/09/fmp18-animation_attack/).

**Hips lead.** In "successive breaking of joints", motion starts at the shoulder and passes to elbow, wrist and fingers, each one slightly later (https://www.brianlemay.com/Pages/animationschool/animation/1stsemesteranimation/successivebreaking.html). In sports biomechanics the order is pelvis, then trunk, then arms, then implement, "each peak speed being faster but later than the previous one" (https://cdn.site.mytpi.com/articles/biomechanics/kinematic-sequence-revisited). Measured pelvis-to-trunk peak separation in pitching is 32.7 ms (https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2022.1044616/full). That is about 1 frame at 30 fps.

**Forum critique (Polycount).**
- "Loosen up the hips and torso".
- "Cant lift your left foot if your weight is on it."
- Push the arcs, because viewers watch the sword tip.
- Judge from one fixed camera angle (https://polycount.com/discussion/comment/2507079).

**Hit feel.** In God of War, the target snaps to its hit pose and both characters hold that frame briefly. Swings use "very large arcs with powerful follow throughs" (https://blog.playstation.com/?p=370399). The Leviathan Axe recall used frames with "0 tween time" at its key beats (https://www.gamedeveloper.com/design/recalling-the-leviathan-axe). A vendor guide suggests these hitstop lengths and adds 2-3 anticipation frames for jabs and 8-12 for heavies (https://mocaponline.com/blogs/mocap-news/animation-polish-game-feel-guide):

| Attack | Hitstop |
|---|---|
| Jab | 2-3 f |
| Standard | 4-6 f |
| Heavy | 8-10 f |

**Cancel windows.** God of War allows many pre-hit cancels (roll, guard) and post-hit cancels (walk). Kratos had about 4000 cancel branches in GoW2 (https://www.gamedeveloper.com/game-platforms/combat-canceled-i-god-of-war-i-action-game-design).

**Gaps.** I found no public GDC animation talk from FromSoftware, For Honor or Monster Hunter with usable detail. The God of War 2018 talk is members-only (https://gdcvault.com/play/1025836/Animation-Bootcamp-God-of-War). FromSoftware has used the mocap group Katsugekiza on DS3, Sekiro and Elden Ring, and appears to reuse and refine moves across games (https://automaton-media.com/en/news/20220610-13270/).

**Root motion on Roblox.** Animations never move the HumanoidRootPart, so a keyframed lunge is visual only (https://devforum.roblox.com/t/how-does-roblox-reconcile-animations-with-physics/4094572, https://devforum.roblox.com/t/lunge-animation-doesnt-change-humanoidrootpart-cframe/2337638). DevForum advice is to move the HRP with CFrame in code rather than keyframing it (https://devforum.roblox.com/t/sword-swing-animations/1989275). Your Lunge marker fits this approach.

## 2. Weapon-specific body mechanics

**Longsword guards (Liechtenauer's four).**
- Ochs is high with the point forward.
- Pflug is low and to the side.
- Vom Tag is high with the point up.
- Alber is low and central (https://wiktenauer.com/wiki/Vier_Leger).

ARMA adds detail:
- Ochs has the hilt at temple level and the blade diagonal toward the face.
- Pflug has the pommel near the hip, not centered.
- Vom Tag has the hands high or the hilt at the collar, with the blade at about 45 degrees and hanging a little back.
- Alber has the point down between the legs and the arms "stretched in front".
- Moving between guards uses passing steps (https://thearma.org/essays/StancesIntro.htm).

**Sword cut physics.** The sword rotates around a pivot that sits inside the body on full-strength cuts, or between the hands on torque cuts. Linear body motion matters less than angular speed. Filmed fast cuts at 100 fps took "ten or more frames" (https://science-and-fiction.org/swordfighting/cuts.html), which is 0.1 s or more.

**Rapier lunge.** The arm extends fully first. Then the hips drive, the front knee goes past the toes, and the rear foot pivots on the ball while the front foot moves about 12 inches (https://www.guywindsor.net/wp-content/uploads/2013/03/Max-Your-Lunge-2007.pdf). In a lab study, a full lunge from signal to hit took 0.92-0.96 s, with front knee flexion peaking around 82-87 degrees (https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2024.1276025/full).

**Per class (vendor guide, https://mocaponline.com/blogs/mocap-news/sword-melee-animation-guide).**
- One-handed swings take 0.4-0.8 s, with full arm extension at the strike.
- Greatsword heavy recovery is 0.8-1.5 s, both hands stay on the grip, and power comes from trunk rotation.
- At 30 fps, light swings are 6-12 f and heavy swings 12-24 f.
- Peak velocity lands 60-70% of the way through the arc.
- Parry active window is 4-8 f.
- Lunge travel is 2.5-4 m.

**Heavy weapons.** Mace and two-handed axe should have slower anticipation and recovery. Hold the follow-through slightly longer to show mass. Wide arcs read as slow and strong, small arcs as fast and weak (https://slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks). On a DevForum critique, a downward smash read as a "chop" that "suits a hammer or axe", and the fix for a sword was more windup angle and torso twist (https://devforum.roblox.com/t/feedback-on-animation/4006744).

**Dagger.** I found no authoritative dagger animation source. The guidance below on short arcs, minimal hip, and stabs driven from the elbow and shoulder is (unsourced, judgment).

## 3. Roblox specifics

**Easing.** PoseEasingStyle offers Linear, Constant (snap), Elastic, Bounce, CubicV2, and Cubic, which is deprecated (https://create.roblox.com/docs/reference/engine/enums/PoseEasingStyle). The Animation Editor runs at 30 fps and publishes through "Publish to Roblox" (https://create.roblox.com/docs/animation/editor). The PoseEasingDirection docs give no semantics (https://create.roblox.com/docs/reference/engine/enums/PoseEasingDirection), so verify In versus Out by sampling in Studio (unsourced, judgment).

**CurveAnimation.** It is an AnimationClip subtype "consumed by Roblox's animation system". It is built as folders per joint holding Position (Vector3Curve) and Rotation (Euler or RotationCurve) channels, and "you must first upload CurveAnimation instances to Roblox before playing them", the same as KeyframeSequence (https://create.roblox.com/docs/en-us/reference/engine/classes/CurveAnimation.md).

The Curve Editor:
- Converts a KeyframeSequence to a CurveAnimation.
- Supports Linear, Constant and Cubic keys, and only Cubic keys have tangents.
- Makes Bounce and Elastic only by baking them through "Generate Curve".
- Cannot undo a conversion of quaternions to Euler angles (https://create.roblox.com/docs/en-us/animation/curve-editor.md).

FloatCurveKey exposes LeftTangent and RightTangent, but the docs do not state units (https://create.roblox.com/docs/reference/engine/datatypes/FloatCurveKey). AnimationClipProvider's RegisterAnimationClip gives temporary IDs that "cannot be used outside of Studio" (https://create.roblox.com/docs/en-us/reference/engine/classes/AnimationClipProvider.md).

So yes, CurveAnimations can be published and played like KeyframeSequences, but they still need an upload. Keeping KeyframeSequence plus dense baked keys is lower risk (unsourced, judgment).

**Priorities and blending.**
- The order is Action4 > Action3 > Action2 > Action > Movement > Idle > Core.
- Evaluation runs per joint from high to low priority until weight reaches 1.0.
- Tracks at the same priority blend in proportion to weight (https://create.roblox.com/docs/en-us/reference/engine/enums/AnimationPriority.md).
- Play defaults to fadeTime 0.1, weight 1, speed 1.
- Setting speed to 0 freezes a track, which gives you hitstop.
- Markers fire through GetMarkerReachedSignal (https://create.roblox.com/docs/reference/engine/classes/AnimationTrack).

**Weapon Motor6D.** One working setup sets Part0 to the weapon's PrimaryPart and Part1 to the arm, and sets C0 from an attachment. It only played after Part0 and Part1 were swapped (https://devforum.roblox.com/t/weapon-animation-with-motor6d/2818896).

**Joint limits.** Roblox's IK docs suggest a hinge on the elbow and a wrist ball-socket at UpperAngle 80 degrees, "approximately how much the wrist should be able to bend" (https://create.roblox.com/docs/en-us/animation/inverse-kinematics.md). IKControl accepts HingeConstraint, BallSocketConstraint and UniversalConstraint limits, and R15 rig attachments can be reused for them (https://devforum.roblox.com/t/ikcontrol-joint-constraint-beta/2227050). I found no official full table of R15 joint limits.

**Tools.** DevForum users say Moon Animator was worth it when free but not at today's price, and that it is best for multi-rig scenes. Blender is the free, stronger alternative (https://devforum.roblox.com/t/is-moon-animator-worth-it/2477738). The classic Blender path (Den_S rig exporter and addon) samples at 30 fps with a frame step of 1-5 (https://devforum.roblox.com/t/34729).

I found no primary-source interviews with animators from Deepwoken, TSB, JJS or Combat Warriors. Any claim about their tooling would be (unsourced, judgment).

**Avoiding stiffness (DevForum feedback).**
- Author slowly, then use AdjustSpeed to play fast.
- Sync the legs with the upper body.
- Add a hop or settle.
- Blend back to rest through a second clip (https://devforum.roblox.com/t/sword-swing-animations/1989275).
- Mix easing styles rather than using one throughout.
- Look forward rather than at the fist.
- Avoid a lead-in that is as big as the hit (https://devforum.roblox.com/t/starting-my-animating-journey-1/998241).

**Animation Capture.** Roblox can turn a video of one person, under 15 s from a fixed camera, into R15 keyframes. It is a beta feature (https://create.roblox.com/docs/en-us/animation/capture.md). This is a free reference generator if a teammate films themselves.

## 4. Procedural and code-authored quality

**Few keys plus procedural layers.** David Rosen's GDC talk shows "very few key frames" combined with procedural techniques producing fluid animation in Overgrowth (https://www.gameanim.com/?p=15568).

**Springs baked into keys.** Allen Chou's damped spring is

  x'' + 2ζω x' + ω²(x − target) = 0

It has a stable implicit-Euler update. Tune it with ω = 2πf and ζ = ln(p)/(−ω t), where p is the fraction remaining after time t (https://allenchou.net/2015/04/game-math-precise-control-over-numeric-springing). To use it:
1. Run the spring on the weapon and wrist, spine and head at 60 Hz against the key-pose targets.
2. Write the results back as dense keyframes.

Steps 1-2 are (unsourced, judgment).

**Arc and spacing checks.** The pros use motion trails (cgchannel above). In code:
- Sample the weapon tip's world position every 1/60 s.
- Flag direction changes above about 25 degrees between samples outside contact and settle frames.
- Plot speed per frame as a spacing chart. The peak should land 60-70% through the active arc (mocaponline sword guide).

The tip-sampling method and the 25-degree threshold are (unsourced, judgment).

**Mocap licensing.**

| Dataset | License | Notes |
|---|---|---|
| CMU | "May be copied, modified, or redistributed without permission" | http://mocap.cs.cmu.edu/faqs.php. An FBX conversion exists (https://data.4tu.nl/datasets/0448aab2-3332-449f-a8e2-d208cb58c7df), and a 2000-clip repack is free if you don't sell the animations themselves (https://80.lv/articles/extensive-library-of-free-mocap-character-animations). I could not verify CMU sword clips because the search page blocked robots. |
| Mixamo | Royalty free for "Creating video games" | https://helpx.adobe.com/ca/creative-cloud/faq/mixamo-faq.html |
| Bandai Namco dataset | CC BY-NC 4.0 BVH | Unusable in a monetized game (https://github.com/BandaiNamcoResearchInc/Bandai-Namco-Research-Motiondataset/blob/master/README.md) |
| Bath "Touché" VR sword fighting | CC-BY 4.0, CSV joint data | Not BVH (https://researchdata.bath.ac.uk/754) |
| UTS longsword dataset | Closed access | https://opus.lib.uts.edu.au/handle/10453/170846 |

**BVH to R15 in code.** This is feasible (unsourced, judgment).
1. Parse the BVH hierarchy and Euler channels.
2. Map spine, neck, arms and legs onto the 15 R15 parts.
3. Compute each bone's rotation relative to its rest pose, then express it in the R15 Motor6D's C0 frame.
4. Normalize scale and root first.

The one DevForum retarget I found used ripped game data and was "sorta" successful (https://devforum.roblox.com/t/aaa-animation-retarget-to-roblox-tlou2-test/3937995). Avoid ripped data.

## 5. SAO Sword Skill language

**Core mechanic.** A skill fires when the player takes a set stance, the "Pre-Motion". The system recognizes it and "lights up the weapon in the Skill hue", and the skill then has a cooldown (https://otakumode.com/otapedia/anime/sword_art_online/sword_skills_sao).

**Vorpal Strike.**
- Pre-motion folds the sword arm toward the shoulder and slightly twists the body.
- It is one ultra-fast thrust with about twice the blade's reach.
- It has a long post-motion delay (https://swordartonline.fandom.com/wiki/Vorpal_Strike).

**Linear (rapier).**
- The rapier is held in front of the body.
- A single straight thrust ends with a wrist twist.
- It has a "remarkably short post-motion delay" (https://swordartonline.fandom.com/wiki/Linear).

**Horizontal Square.** The blade starts pulled back and to the right, then four alternating horizontal slashes draw a square of light (https://swordartonline.fandom.com/wiki/Horizontal_Square).

**Sonic Leap.** The sword is raised over the shoulder, then the user charges over twice Vertical's distance into a downward slash (https://swordartonline.fandom.com/wiki/Sonic_Leap).

**Starburst Stream.** It has 16 hits in the light novel (21 in the anime). In the anime's Heathcliff rematch, Heathcliff moves to attack Kirito during the post-motion delay (https://swordartonline.fandom.com/wiki/Starburst_Stream).

**Skill chaining in the games.** Alicization Lycoris chains skills through "skill connect": a "flashing star" window after one skill lets you start the next (https://primagames.com/?p=313680).

**Echoes of Aincrad.** Bandai Namco has published only Switch, partner Special Skills and real-time combat. There is no animation detail yet (https://www.bandainamcoent.com/news/echoes-of-aincrad-reveals-combat-system-and-signature-gameplay-features).


## Animation playbook for Sword Bound

Frames are at 30 fps (f). Store times in seconds in Specs. Where a number comes from a source above, the source is named. Everything else is (unsourced, judgment).

**Global rules**
1. **Pose counts per attack.** Use 5-7 key poses: guard, anticipation, cocked extreme, contact, follow-through extreme, settle and return-to-guard (Lueng breakdown). Add 1-2 breakdowns per arc (judgment).
2. **Active window.** HitStart to HitEnd lasts 2-4 f (DS3 teardown).
3. **Hitstop.** Use speed 0 on hit for 2-3 f (dagger), 4-6 f (sword, rapier) or 8-10 f (greatsword, axe) (mocaponline polish guide, implemented with AdjustSpeed).
4. **Easing per segment** (judgment).

   | Segment | Easing |
   |---|---|
   | Guard to anticipation | CubicV2 InOut |
   | Anticipation to cocked extreme | CubicV2 ease into the hold |
   | Cocked extreme to contact | Linear or CubicV2 accelerating ("fast in") |
   | Contact to follow-through | CubicV2 decelerating ("slow out", Cooper) |
   | Follow-through to settle | Spring-baked keys |
   | Settle to guard | CubicV2 InOut |

   Use Constant only for 1-frame smear or snap poses. Do not use Elastic or Bounce on body joints.
5. **Overshoot** (judgment).
   - The weapon and wrist pass the follow-through target by 5-8 degrees for light weapons and 10-15 degrees for heavy ones.
   - The spine counter-rotates 3-5 degrees.
   - Settle within 4-8 f using ζ ≈ 0.35-0.5 at 2-3 Hz (Chou formula).
6. **Hip-to-hand offsets.**
   - LowerTorso leads UpperTorso by 1 f, based on the 32.7 ms pelvis-trunk peak gap.
   - The shoulder and upper arm lag by 1 f, the hand by 1 f more, and the weapon tip by 1-2 f.
   - Total is 3-5 f for light weapons and 5-8 f for heavy (offsets judgment, order sourced).
7. **Foot rules.**
   - Never lift a foot that carries weight (Polycount).
   - The stepping foot lands 1-2 f before contact, and the rear foot pivots on the ball during lunges (Windsor).
   - Feet stay locked during the active frames.
   - Root travel happens in code on the Lunge marker (DevForum), never through keyframes.
8. **Arcs.** The weapon tip follows clean arcs. Break them deliberately only at contact and on the head (Cooper).
9. **Timing.** Author long, then compress by retiming rather than playing 1:1 (Animation Mentor).
10. **Recovery ends in exact guard.** The pose at CancelOpen should already be close to guard (GD Keys).

**Per class.** Totals are anticipation + active + recovery in frames. Recovery for greatsword and axe is anchored to the sourced 0.8-1.5 s heavy figure. The rest is judgment within the sourced light (6-12 f) and heavy (12-24 f) swing ranges.

| Class | Anticip. | Active | Recovery | CancelOpen | Notes |
|---|---|---|---|---|---|
| Dagger | 2-4 | 2 | 6-10 | 60% of recovery | Small arcs, elbow-driven stabs, hips 5-10 degrees of twist |
| 1H sword | 4-6 (0.1-0.2 s, sourced) | 2-3 | 8-14 | 70% (sourced combo window) | Full arm extension at strike, off hand relaxed (mocaponline) |
| Rapier | 3-5 | 2-3 | 8-12 | 60% | Arm fully extended before front foot lands (2-3 f lead). Front knee about 85 degrees in lunge (Frontiers). Linear-style wrist twist on contact |
| Greatsword | 8-12 | 3-4 | 24-40 | 75% | Both hands stay on, guards from Ochs, Vom Tag, Pflug, trunk rotation drives |
| Greataxe | 10-14 + 2-4 hold | 3-4 | 30-45 | 80% | Pick and blacksmith plates as reference, blade carries past target, slowest settle |

**Defense and reactions**
- **Parry.** Active window 4-8 f (mocaponline). The pose snaps in over 2-3 f with Constant or a fast CubicV2.
- **Roll.** IFrameStart around f2. Medium-roll invulnerability in DS3 is 433 ms, about 13 f (DS3 teardown).
- **Hit reaction.** 0.3-0.5 s (mocaponline). Snap to the hit pose on frame 1 (God of War), then spring out.
- **Stagger.** 0.6-1.2 s with a stumble step (judgment).

**Sword Skills**
1. **Pre-motion hold.** The pre-motion pose is held 6-12 f with glow VFX on a marker.
2. **System assist.** The motion is 20-30% faster than the matching normal attack, uses Linear easing between cuts, and keeps the tip path on a clean geometric shape (a square, or a straight line for Linear).
3. **Post-motion delay.** Long for Vorpal Strike (about 30-45 f), short for Linear (about 8-12 f).
4. **Skill connect.** Open a 6-10 f window at the end of the skill.

The numbers in steps 1-4 are judgment. The structure comes from the SAO sources.

**QA checklist** (all judgment except where noted)
1. **Contact sheet.** Render each key pose from the gameplay camera and from the side. Run the silhouette test by filling the character black and checking the action still reads (AnimSchool).
2. **Tip-arc plot.** Draw the weapon tip path at 60 Hz with dots, color-coded by speed. Check that peak speed falls 60-70% into the active arc and that there are no kinks outside contact.
3. **Spacing chart.** Plot speed per frame for each joint and verify the order of peaks is pelvis, then chest, then hand, then tip (TPI).
4. **Foot-lock check.** The foot's world position should drift by less than 0.05 studs while it is weighted.
5. **Joint limits.** Wrist under 80 degrees (Roblox IK docs). Elbow and knee hinge-only, with no hyperextension.
6. **Marker audit.** HitStart to HitEnd lasts 2-4 f, CancelOpen sits after HitEnd, and IFrame markers are inside the roll.
7. **Blend test.** Play each clip with a 0.1 s fade from idle and from every combo predecessor. Check the Action priority stack.


## Sources
- https://gdkeys.com/keys-to-combat-design-1-anatomy-of-an-attack/
- https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3
- https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games
- https://www.gamedeveloper.com/game-platforms/combat-canceled-i-god-of-war-i-action-game-design
- https://www.gamedeveloper.com/design/recalling-the-leviathan-axe
- https://blog.playstation.com/?p=370399
- https://gdcvault.com/play/1025836/Animation-Bootcamp-God-of-War
- https://automaton-media.com/en/news/20220610-13270/
- https://www.pluralsight.com/resources/blog/software-development/stepped-vs-spline-curves-blocking-animation
- https://framestore.thegnomonworkshop.com/blog/combat-animation-for-games-with-jason-shum
- https://www.cgchannel.com/2025/07/tutorial-animating-stylized-attacks-in-maya/
- https://www.animationmentor.com/blog/tutorial-animate-sword-fights-battle-sequences/
- https://blog.animschool.edu/tag/line-of-action/
- https://lucylueng.myblog.arts.ac.uk/2021/12/09/fmp18-animation_attack/
- https://www.brianlemay.com/Pages/animationschool/animation/1stsemesteranimation/successivebreaking.html
- https://cdn.site.mytpi.com/articles/biomechanics/kinematic-sequence-revisited
- https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2022.1044616/full
- https://www.frontiersin.org/journals/bioengineering-and-biotechnology/articles/10.3389/fbioe.2024.1276025/full
- https://mocaponline.com/blogs/mocap-news/animation-polish-game-feel-guide
- https://mocaponline.com/blogs/mocap-news/sword-melee-animation-guide
- https://slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks
- https://polycount.com/discussion/comment/2507079
- https://wiktenauer.com/wiki/Vier_Leger
- https://thearma.org/essays/StancesIntro.htm
- https://science-and-fiction.org/swordfighting/cuts.html
- https://www.guywindsor.net/wp-content/uploads/2013/03/Max-Your-Lunge-2007.pdf
- https://create.roblox.com/docs/reference/engine/enums/PoseEasingStyle
- https://create.roblox.com/docs/reference/engine/enums/PoseEasingDirection
- https://create.roblox.com/docs/animation/editor
- https://create.roblox.com/docs/en-us/reference/engine/classes/CurveAnimation.md
- https://create.roblox.com/docs/en-us/animation/curve-editor.md
- https://create.roblox.com/docs/reference/engine/datatypes/FloatCurveKey
- https://create.roblox.com/docs/en-us/reference/engine/classes/AnimationClipProvider.md
- https://create.roblox.com/docs/en-us/reference/engine/enums/AnimationPriority.md
- https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
- https://create.roblox.com/docs/en-us/animation/inverse-kinematics.md
- https://create.roblox.com/docs/en-us/animation/capture.md
- https://devforum.roblox.com/t/ikcontrol-joint-constraint-beta/2227050
- https://devforum.roblox.com/t/weapon-animation-with-motor6d/2818896
- https://devforum.roblox.com/t/sword-swing-animations/1989275
- https://devforum.roblox.com/t/feedback-on-animation/4006744
- https://devforum.roblox.com/t/starting-my-animating-journey-1/998241
- https://devforum.roblox.com/t/is-moon-animator-worth-it/2477738
- https://devforum.roblox.com/t/34729
- https://devforum.roblox.com/t/lunge-animation-doesnt-change-humanoidrootpart-cframe/2337638
- https://devforum.roblox.com/t/how-does-roblox-reconcile-animations-with-physics/4094572
- https://devforum.roblox.com/t/aaa-animation-retarget-to-roblox-tlou2-test/3937995
- https://www.gameanim.com/?p=15568
- https://allenchou.net/2015/04/game-math-precise-control-over-numeric-springing
- http://mocap.cs.cmu.edu/faqs.php
- https://data.4tu.nl/datasets/0448aab2-3332-449f-a8e2-d208cb58c7df
- https://80.lv/articles/extensive-library-of-free-mocap-character-animations
- https://helpx.adobe.com/ca/creative-cloud/faq/mixamo-faq.html
- https://github.com/BandaiNamcoResearchInc/Bandai-Namco-Research-Motiondataset/blob/master/README.md
- https://researchdata.bath.ac.uk/754
- https://opus.lib.uts.edu.au/handle/10453/170846
- https://otakumode.com/otapedia/anime/sword_art_online/sword_skills_sao
- https://swordartonline.fandom.com/wiki/Vorpal_Strike
- https://swordartonline.fandom.com/wiki/Linear
- https://swordartonline.fandom.com/wiki/Horizontal_Square
- https://swordartonline.fandom.com/wiki/Sonic_Leap
- https://swordartonline.fandom.com/wiki/Starburst_Stream
- https://primagames.com/?p=313680
- https://www.bandainamcoent.com/news/echoes-of-aincrad-reveals-combat-system-and-signature-gameplay-features
- Image candidates (public domain, not downloaded): https://www.nga.gov/artworks/166824-plate-number-349-fencing, https://www.nga.gov/artworks/166856-plate-number-386-miner-using-pick, https://www.nga.gov/collection/art-object-page.166850.html, https://www.nga.gov/collection/art-object-page.166819.html, https://www.nga.gov/collection/art-object-page.166785.html, https://metmuseum.org/art/collection/search/27568

**Files:** /mnt/user-data/outputs/vault_images/animation/MANIFEST.md (candidate list only, no image files).

## Reference image list (not downloaded)

The proxy blocked these hosts, so these are links with verified public-domain status.

### Animation reference images (Sword Bound)

Status on 2026-10-08. No image files were downloaded. The research container's egress proxy refused every image host tried (upload.wikimedia.org, commons.wikimedia.org, en.wikipedia.org, nga.gov, media.nga.gov, metmuseum.org, wellcomecollection.org, loc.gov, archive.org) with HTTP 403 on CONNECT, so per the "never bypass a blocked site" rule nothing was fetched. The list below holds openly licensed candidates whose license was checked on the source page, ready to download from a machine where these hosts are allowed. Save each one into this folder under the suggested file name and keep this table.

| Suggested file | What it shows | Source page URL | Author | License (as stated on source page) |
|---|---|---|---|---|
| muybridge_349_fencing.jpg | Two fencers, 12-frame sequence on a grid backdrop. Use for lunge, parry and recovery spacing. | https://www.nga.gov/artworks/166824-plate-number-349-fencing | Eadweard Muybridge, 1887 | Public domain ("This object's media is free and in the public domain", NGA Open Access) |
| muybridge_350_fencing.jpg | Second fencing plate from Animal Locomotion. | https://www.nga.gov/collection/art-object-page.181213.html | Eadweard Muybridge, 1887 | Public domain, NGA Open Access (verify on page) |
| muybridge_386_miner_pick.jpg | Overhead two-handed pick swing. Closest PD match for a greataxe overhead chop (wind-up, drop, follow-through into ground). | https://www.nga.gov/artworks/166856-plate-number-386-miner-using-pick | Eadweard Muybridge, 1887 | Public domain, NGA Open Access |
| muybridge_378_blacksmith_two_hands.jpg | Two-handed hammer on anvil. Heavy two-handed vertical strike with impact stop. | https://www.nga.gov/collection/art-object-page.166850.html | Eadweard Muybridge, 1887 | Public domain, NGA Open Access |
| muybridge_343_striking_blow_left.jpg | Striking a blow with the left hand. Hip-led strike and weight transfer. | https://www.nga.gov/collection/art-object-page.166819.html | Eadweard Muybridge, 1887 | Public domain, NGA Open Access |
| muybridge_308_throwing_hammer.jpg | Hammer throw. Rotational two-handed swing, good for horizontal greatsword/axe sweeps. | https://www.nga.gov/collection/art-object-page.166785.html | Eadweard Muybridge, 1887 | Public domain, NGA Open Access |
| muybridge_361_throwing_spear.jpg | Spear throw. Proximal-to-distal thrust sequencing for rapier and dagger thrusts. | https://www.nga.gov/collection/art-object-page.166834.html | Eadweard Muybridge, 1887 | Public domain, NGA Open Access (verify on page) |
| muybridge_523_striking_throwing.jpg | Plate 523, A: striking a blow, plus disk throw and stone heave. | https://www.nga.gov/collection/art-object-page.136537.html | Eadweard Muybridge, 1887 | Public domain, NGA Open Access (verify on page) |
| meyer_1570_plates.jpg | Joachim Meyer, Gründtliche Beschreibung (1570), Tobias Stimmer woodcuts of longsword, dussack, rapier guards (ox, plow, roof, fool, wrath, etc.). | https://metmuseum.org/art/collection/search/27568 | Joachim Meyer (text), Tobias Stimmer (woodcuts), 1570 | Public Domain, Met Open Access ("available for unrestricted commercial and noncommercial use") |
| talhoffer_fechtbuch.jpg | Talhoffer Fechtbuch copy, longsword, dagger, mace, judicial combat. | https://artistproject.metmuseum.org/toah/works-of-art/26.236 | Hans Talhoffer (16th c. copy of 1440s work) | Met lists it as Open Access, but the page says download of this image is restricted. Do not download from the Met; look for a PD scan on Wikimedia Commons instead. |

Wikimedia Commons searches to run when the host is reachable (each file page shows its own license, usually PD-old or PD-Art; record it here before saving):
- Joachim Meyer 1570 woodcuts: search "Meyer 1570" in File namespace at https://commons.wikimedia.org
- Capo Ferro 1610 "Gran Simulacro" plates (rapier lunge): search "Capoferro"
- Salvator Fabris 1606 "De lo schermo" plates (rapier guards and lunges): search "Fabris 1606"
- Talhoffer 1467 (Cod.icon. 394a) plates: search "Talhoffer"

Do not save game or anime screenshots (SAO, Elden Ring, Deepwoken, etc.). Link to them instead.
