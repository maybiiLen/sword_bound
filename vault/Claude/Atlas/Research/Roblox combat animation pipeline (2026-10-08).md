---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - animation
  - roblox
---

Up: [[Claude]] · Used by: [[Weapons and sword skills plan]]

## Forum pass status
Reddit was blocked. WebFetch on reddit.com and old.reddit.com returned SITE_BLOCKED, the proxy refused the connection with a 403, and searches limited to reddit.com were rejected. A Reddit mirror was also unreachable. So none of the r/robloxgamedev, r/animation or r/gamedev findings below come from Reddit itself. The Roblox DevForum was reachable, and most of the forum evidence comes from it.

## 1. Publishing and tools
- Animations only play in experiences whose owner also owns the animation. If you move a game to a group, the group needs its own copies, and the community transfer tool should run in batches of 200 or fewer because it ignores rate limits [https://create.roblox.com/docs/projects/transfer-animations].
- Open Cloud's Create Asset endpoint accepts Animation as .rbxm or .rbxmx. Files edited outside Studio "might not upload or function." Group creators are supported if the API key has group permissions [https://create.roblox.com/docs/en-us/cloud/guides/usage-assets].
- Animation upload through Open Cloud was enabled on Oct 23, 2025. The legacy UploadNewAnimation endpoint is set for deprecation [https://devforum.roblox.com/t/open-cloud-upload-support-for-more-asset-types/4022082].
- Rate limits apply per owner (user or group) and are reported in x-ratelimit headers. Back off on a 429 [https://create.roblox.com/docs/de-de/cloud/reference/rate-limits].
- Asphalt is a CLI that syncs files with KeyframeSequence or CurveAnimation content as animations, and it can target a group creator [https://github.com/jackTabsCode/asphalt].
- Manual uploads in Studio take "up to 14 clicks per animation," and no official bulk workflow existed as of Nov 2025 [https://devforum.roblox.com/t/improve-bulk-animation-upload-workflow/4041759].
- The Animation Clip Editor imports FBX and glTF. The enhanced importer has been generally available since Mar 31, 2026, and it can import several clips from one file [https://devforum.roblox.com/t/4260501].
- The Blender path uses Den_S's addon, which rebuilds the R15 rig in Blender and moves animations back through the clipboard. Clothing is no longer imported automatically, and skinned meshes are unsupported [https://devforum.roblox.com/t/34729].
- On what animators use, DevForum replies in Dec 2025 mostly told people to learn Blender instead of the default editor [https://devforum.roblox.com/t/update-on-the-default-animation-editor/4165825]. Moon Animator 2 is paid (users cite about 1,200 to 1,700 Robux), and opinion splits between it being easy and it being overpriced [https://devforum.roblox.com/t/is-moon-animator-worth-it/2477738]. An Aug 2026 thread called Blender "widely used for Roblox" [https://devforum.roblox.com/t/any-alternatives-to-ma2-moon-animator-2/4770365]. No source says which tool top studios use. UNSOURCED.

## 2. What makes combat animation read well
- Priority order is Idle, Movement, Action, Action2, Action3, Action4, then Core [https://create.roblox.com/docs/reference/engine/enums/AnimationPriority].
- Two tracks at the same priority blend 50/50. Roblox's preferred way to override is a higher priority, so give each attack layer its own priority. Setting a track's weight to 0 can briefly show a default pose, so use 0.0001 instead [https://devforum.roblox.com/t/animation-engine-runtime-changes-and-fixes/1320674/1].
- Play() defaults to a 0.1 s fade [https://create.roblox.com/docs/reference/engine/classes/AnimationTrack].
- AdjustSpeed(0) pauses a track, which gives you hit-stop. Restore the speed afterward [https://devforum.roblox.com/t/pausing-animations/288995].
- Animation Graphs reached full release on Jul 15, 2026. They add Blend1D/2D, Over/Add/Subtract layers, a Mask node (for example upper body only), script parameters, and automatic replication. IK nodes are not shipped yet [https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840/1]. This closes the old gap where Roblox had no additive animation [https://devforum.roblox.com/t/allow-animations-to-be-additive/2067601].
- The older upper-body method plays a weapon-hold track at a higher priority over the walk [https://devforum.roblox.com/t/how-to-make-animations-merge/1544111].
- IKControl handles runtime IK such as feet on slopes and hand reach [https://create.roblox.com/docs/animation/inverse-kinematics].
- Roblox has no root motion. Animating a lunge does not move the HumanoidRootPart, which can trip server sanity checks [https://devforum.roblox.com/t/lunge-animation-doesnt-change-humanoidrootpart-cframe/2337638]. The suggested fix is to move the HRP from script in sync with the animated steps [https://devforum.roblox.com/t/combat-locomotion/1436335]. In general game practice, combo attacks lock the root or have code drive the displacement [https://mocaponline.com/blogs/mocap-news/combat-animation-game-dev-guide].
- Weapon mechanics differ by class [https://mocaponline.com/blogs/mocap-news/combat-animation-game-dev-guide].
  - Greatswords are driven by hip rotation, with deep follow-through and planted-foot pivots.
  - Daggers use tight movement and active footwork.
  - Spears use linear thrusts and sweeps.
  - One-handed swords use shoulder rotation with counterbalance.
- On R6 vs R15, some DevForum users argue R6 suits classic sword fighting, while R15 gives more parts to animate [https://devforum.roblox.com/t/is-r6-even-worth-using-at-all/432833?page=2].
- Smears, overshoot and anticipation get no Roblox-specific source here. UNSOURCED.

## 3. How top games source animation
- One freelancer says they made "most of Deepwoken's recent weapon animations" and charges about 5,000+ Robux or $20+ per animation [https://sites.google.com/view/luluxanimations/home]. That points to Deepwoken using contracted animators.
- I found no sourced production details for TSB, Jujutsu Shenanigans, Type Soul, Blox Fruits or Arcane Odyssey. UNSOURCED.
- Commission prices vary widely.
  - One animator lists a basic animation at $15, a complex combat animation at $30, and an 8-move moveset at $160, with 2 revisions included [https://yahy-portfolio.carrd.co/].
  - A DevForum thread puts amateurs at 300 to 1,000 Robux per animation and established animators at $50 to $100+ [https://devforum.roblox.com/t/am-i-offering-a-good-price-for-animators-per-animation/4071933].
  - None of these sources state a turnaround time. UNSOURCED.
- Mocap options:
  - Roblox's own Animation Capture turns a single-person R15 video clip under 15 s into keyframes [https://create.roblox.com/docs/en-us/animation/capture].
  - Rokoko's free plan includes 30 s of video mocap per month with FBX export [https://www.rokoko.com/pricing].
  - DeepMotion's free tier gives 60 s per month [https://www.fast.io/resources/best-ai-animation-tools-2026.md].
- Mocap "can look too real for stylized games," so keyframe the exaggerated attacks [https://animost.com/tutorials/using-mocap-data-for-game-animation/]. Fast moves smear under mocap, so the usual approach is hybrid, with mocap as the base and hand polish on top [https://mocaponline.com/blogs/mocap-news/combat-animation-game-dev-guide].

## 4. Scaling to many weapon classes
- A common setup keeps locomotion shared and layers attacks over it with per-bone blending, and each attack clip defines its early-exit frames [https://mocaponline.com/blogs/mocap-news/combat-animation-game-dev-guide]. In Roblox this maps to the Animation Graph Mask and Over nodes [https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840/1].
- Markers drive timing through GetMarkerReachedSignal [https://create.roblox.com/docs/animation]. A bug where a marker on the last keyframe failed to fire was fixed in Jul 2026 [https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840/1].
- Retargeting is a Cascadeur Pro feature [https://cascadeur.com/plans].
- These conventions are UNSOURCED inference:
  - Name clips like `Weapon_Action_Variant`.
  - Keep one marker vocabulary across all clips.
  - Read hit timing from the markers rather than hard-coding times in the Specs.
  - Add a CI check that every published clip has HitStart, HitEnd and CancelOpen.

## 5. Tools and licenses
- Cascadeur
  - The Free tier exports only .casc and is non-commercial.
  - Indie ($8/mo annual, $19 monthly, revenue under $100k) adds FBX export.
  - Pro costs $33/mo annual [https://cascadeur.com/plans].
  - It has a built-in "Export to Roblox" command that works on rigs with Cascadeur's control rig. Add an extra end keyframe, because the Animation Editor can cut the last frame [https://cascadeur.com/help/category/280].
- Marketplace packs exist. One battlegrounds pack has 16 animations for $1.99 under a "with attribution" license [https://builtbybit.com/resources/roblox-battlegrounds-animation-pack.95584/]. Creator Store assets only load where the user has explicit permission [https://create.roblox.com/docs/en-us/production/creator-store].

## 6. Recommended pipeline for Sword Bound
The best fit is a hybrid. Keep the procedural Specs for blockout and timing, and hand-polish the final versions. The tool facts behind each step are sourced above, and the overall plan is UNSOURCED synthesis.
1. **Publish now.** Save each generated KeyframeSequence to .rbxm in Studio, then push them to the group with Open Cloud or Asphalt and a group API key. Write a Luau id map like the transfer doc describes [https://create.roblox.com/docs/projects/transfer-animations]. Cost is $0.
2. **Fix the stiff poses in the Specs first.** This covers overshoot keys, hips leading the swing, and the per-weapon mechanics in section 2. Treat this as the prototype layer. UNSOURCED.
3. **Move to Graphs.** Restructure into one shared locomotion graph plus a masked upper-body Over layer per weapon stance, with hit-stop through AdjustSpeed [https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840/1].
4. **Polish in Blender or Cascadeur.** Polish the hero clips (finishers, heavies) in Blender for free or in Cascadeur Indie at $96/yr. Import through the Clip Editor's FBX path [https://devforum.roblox.com/t/4260501]. Then copy the marker names back onto the polished clips.
5. **Commission where needed.** Budget roughly $20 to $30 per clip, which is about $160 per 8-move moveset [https://yahy-portfolio.carrd.co/]. Six classes come to about $1,000 to $1,500 (UNSOURCED estimate). Give contractors your marker spec and the R15 rig file.
6. **Leave mocap optional.** Use it only for reference or for hit reactions [https://animost.com/tutorials/using-mocap-data-for-game-animation/].
