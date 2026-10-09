---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - combat
  - engineering
---

Up: [[Claude]] · Used by: [[Sword combat feel revision]]

Produced by a research agent on 2026-10-08 after Henry said basic sword combat doesn't feel fun yet and asked for end-to-end research (Reddit, X, Discord and forums). How to build lunges, soft aim, lock-on, hitboxes and hitstop on Roblox in 2026. Reproduced as the agent returned it. Claims marked unsourced are the agent's own calls.

Research date 2026-10-08. Scope: how to make Sword Bound's melee attacks carry the character toward a target with good network behavior. Builds on the brief at scratchpad/combat_brief.md (LinearVelocity lunge in MovementController, AlignOrientation facing, opt-in lock-on, client swept blade box validated by server, procedural keyframe animations).

Every factual claim has an inline URL. Anything without one is marked (unsourced) and is my own engineering judgment.

## Source coverage and reachability

- Roblox Creator Docs (create.roblox.com): reachable. Some engine class reference pages (LinearVelocity, AlignPosition, AlignOrientation) rendered only property names without descriptions, so the physics guide pages were used instead.
- DevForum (devforum.roblox.com): reachable and the main source for community practice.
- GitHub: the ShapecastHitbox repo page was reachable via WebFetch. The `gh api` search endpoint was refused (session is bound to configured repos), so no GitHub-wide module search was done.
- Reddit: not reachable. `site:reddit.com` searches for r/robloxgamedev returned only DevForum results, a search restricted to reddit.com was rejected by the search proxy (HTTP 400), and a direct WebFetch of reddit.com returned "SITE_BLOCKED". No Reddit content is used in this report.
- X/Twitter: partially reachable through search only. A domain-restricted search returned a handful of x.com posts, mostly old or off-topic (for example a 2023 hobby post describing "press Q to autolock the nearest sapling ... player orientation is locked on the target", https://x.com/Diptipper/status/1739375703781790146). WebFetch of x.com failed with a robots-disallowed error. A second X pass aimed at 2026 posts (animation graphs, hitstop) could not run because the shared web search budget for this turn ran out. No X content materially shaped the recommendations.
- Discord: no message content surfaced. Only public invite and server listing pages appeared (for example https://discord.com/invite/robloxdevs and https://discord.com/servers/advanced-combat-system-community-827005719454810173). Discord is not publicly indexed.
- Third-party aggregator creation.dev appeared a few times. It is cited once and flagged as secondary.
- Search budget note: the web search budget was used up near the end, so a few planned follow-ups (more TSB/JJS teardown threads, a second X pass) were not run. A follow-up session can continue them.

## 1. Lunges and attack movement

### What changed in 2026 that matters

- Animation Graphs reached full release on July 15, 2026, with blend spaces, select nodes, sequence nodes, masks, and parameters that "replicate automatically in both Server and non-Server Authority modes" (https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840).
- Server Authority reached full release on July 9, 2026, and is opt-in (https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993).
- The Input Action System reached full release on June 11, 2026 (https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416).

### Root motion: still not supported

- The Animation Graphs release post does not mention root motion, and Roblox only says it is "continuing to build out our motion tools by adding more nodes" (https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840).
- The Animation Graph editor docs list Clip, Add, Select, Priority Select, Sequence and Random Sequence nodes and say nothing about root motion (https://create.roblox.com/docs/en-us/animation/graph-editor.md).
- The Animation overview and Animator docs also do not mention root motion (https://create.roblox.com/docs/en-us/animation.md, https://create.roblox.com/docs/en-us/reference/engine/classes/Animator.md).
- Community workarounds: a forum explanation defines root motion as "the ability for an animation track to animate the physics simulation's position of your character," and says the proper method is converting the animated root offset into velocity for the root part. The simpler hack is to snap the root by CFrame after the track ends, which "will be possible in some cases to use the animation to do things like no-clip through walls." For blended tracks you may need to read the LowerTorso "Root" Motor6D Transform each step (https://devforum.roblox.com/t/animation-that-changes-position/2859267).
- Another thread lists two options: keep the torso at the origin in the animation and drive position by script, or extract torso transforms and replay them on the root in script (https://devforum.roblox.com/t/2446417).
- Takeaway for Sword Bound: since Sword Bound's animations are procedural keyframe specs, it already owns a scripted displacement curve per attack. Keeping animations "in place" and driving displacement by script is the documented option 1 above and avoids the noclip risk of the snap hack.

### Mover comparison

| Technique | How it behaves | Tradeoffs | Source |
|---|---|---|---|
| LinearVelocity | Holds an assembly at a target velocity along a Vector, Line, or Plane | Official BodyVelocity replacement. Plane mode controls only the horizontal plane. Must overpower humanoid drag, so needs high force | https://create.roblox.com/docs/physics/mover-constraints, https://devforum.roblox.com/t/trouble-creating-dashroll/2069422 |
| AlignPosition | Pulls an attachment toward a goal position | Better when you care about arriving at a point; can get stuck on obstacles like any mover | https://devforum.roblox.com/t/understanding-custom-movement/3594673 |
| BodyVelocity | Legacy mover | Deprecated; LinearVelocity "satisfies the majority of use cases" | https://create.roblox.com/docs/physics/mover-constraints |
| AssemblyLinearVelocity / ApplyImpulse | One-shot velocity change | Friction and humanoid drag eat it; distance differs between ground and air | https://devforum.roblox.com/t/dash-is-inconsistent/2017959 |
| CFrame tween on HumanoidRootPart | Moves the part outside physics | "Tweening a part's CFrame doesn't correlate into physics at all", anchoring suggested, still shook slightly | https://devforum.roblox.com/t/tweening-a-character-smoothly/946022 |
| Root motion | Not available | See above | https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840 |

Details and values from sources:

- LinearVelocity modes: Line, Plane and Vector replace the old trick of zeroing individual BodyVelocity axes (https://create.roblox.com/docs/physics/mover-constraints). With RelativeTo World, force is applied "in world coordinates, independent of the parent or attachment orientations" (https://create.roblox.com/docs/physics/constraints/linear-velocity).
- Plane mode for dashes: switching a dash to plane mode stopped the "jumping" problem, and keeping MaxForce at zero (or the constraint disabled) outside the dash stops floating (https://devforum.roblox.com/t/trouble-creating-dashroll/2069422).
- A LinearVelocity movement tutorial uses Plane mode with tangent axes X and Z, MaxForce 10000 ("change depending on use"), and lerps velocity with acceleration 4 and deceleration 6 times deltaTime (https://devforum.roblox.com/t/how-to-make-a-linear-velocity-movement-system/3888906).
- A July 2026 attempt to replicate the Ultimate Battlegrounds front dash runs on the client, attaches LinearVelocity to RootAttachment, updates VectorVelocity every Heartbeat, and uses speed 70 forward and 90 sideways, durations 1 s and 0.5 s, and MaxAxesForce 500000 on X and Z (https://devforum.roblox.com/t/help-with-replicating-battleground-front-dash/4731700). This is a hobbyist recreation and not a confirmed teardown of the real game.
- A dash speed decay curve posted on the forum is v = speed * (1 - t/d)^3 (https://devforum.roblox.com/t/how-do-i-make-the-battlegrounds-dashes/4187993). Sword Bound's quadratic ease-out is the same family with a gentler tail.
- AlignPosition: when RigidityEnabled is true "the physics solver reacts as quickly as possible to complete the alignment"; otherwise force comes from MaxForce, MaxVelocity and Responsiveness (https://create.roblox.com/docs/physics/constraints/align-position). One reply suggests MaxForce of "about twice your characters mass" to limit clipping, with a caveat not to rely on it (https://devforum.roblox.com/t/dash-is-inconsistent/2017959).
- Ground vs air: velocity dashes go shorter on the ground because of friction; a small upward velocity was suggested, and the original poster solved clipping with CFrame plus `GetPartsInPart` and cancelled the dash when overlapping (https://devforum.roblox.com/t/dash-is-inconsistent/2017959).
- Wall safety: raycasting ahead and skipping or shortening the dash if a hit is too close was suggested in the same thread (https://devforum.roblox.com/t/dash-is-inconsistent/2017959).
- Body collision during a lunge: a lunging attacker can bounce the target away and cause inconsistent hits. Suggested fixes are NoCollisionConstraints between attacker and target parts, or a characters collision group that does not collide with itself (https://devforum.roblox.com/t/confused-on-making-a-dash-slash/1683248).
- Mover replication bug reported June 2026: reusing one LinearVelocity with different RelativeTo modes, or setting VelocityConstraintMode and RelativeTo then LineDirection in the same frame, produced a stale LineDirection on the client. Adding `task.wait()` after the enum changes fixed it, and a reply advised VectorVelocity for simple dashes (https://devforum.roblox.com/t/linearvelocity-linedirection-will-not-replicate-accurately/4677374). The engine-bug explanation is the poster's hypothesis.

### How TSB and JJS style games do it

- No public, authoritative teardown of The Strongest Battlegrounds or Jujutsu Shenanigans M1 movement was found on DevForum in this pass. The closest is the client-side Heartbeat-updated LinearVelocity recreation above (https://devforum.roblox.com/t/help-with-replicating-battleground-front-dash/4731700).
- The prior vault research already covers how those games feel; this report does not repeat it.

## 2. Target magnetism, soft lock and motion warping

### No native motion warping on Roblox

- Roblox has no motion warping feature in the Animation Graph docs or release post (https://create.roblox.com/docs/en-us/animation/graph-editor.md, https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840).
- Unreal's Motion Warping is a useful model to copy by hand. It uses warp windows placed on the animation timeline, a named warp target updated at runtime, separate toggles for translation and rotation, an option to ignore Z, a Facing rotation mode where the "Character rotates to face the warp target", and a rotation time multiplier that "Modifies how fast the rotation is warped" (https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-warping-in-unreal-engine).
- On Roblox the equivalent is: treat Sword Bound's existing Lunge marker to HitStart span as the warp window, recompute the target point every Heartbeat inside it, and drive LinearVelocity so the remaining displacement lands at the spacing distance (unsourced).

### Rotation toward the target

- Turning a part toward a target with AlignOrientation: "set to OneAttachment and PrimaryAxisLookAt"; the same reply suggests per-frame `CFrame.lookAt` in PostSimulation when physics rotation is not needed (https://devforum.roblox.com/t/align-orientation-issues/3436776).
- AlignType PrimaryAxisLookAt only applies torque "when the primary axes become misaligned", and RigidityEnabled makes it react "as quickly as possible" (https://create.roblox.com/docs/physics/constraints/align-orientation).
- Replication pitfall: setting the root CFrame every frame on the client looked smooth locally but laggy to other players; the fix in that thread was a physics rotator (BodyGyro) limited to the Y axis (https://devforum.roblox.com/t/choppy-lock-on-system-solved/2894349). BodyGyro is deprecated and AlignOrientation is its replacement (https://create.roblox.com/docs/physics/mover-constraints), so Sword Bound's AlignOrientation facing is already the right primitive.
- Humanoid.AutoRotate must be false while you drive facing yourself (https://devforum.roblox.com/t/2539863).
- Yaw only: a lock-on example rotates the root to face the enemy's X and Z while keeping its own height (https://devforum.roblox.com/t/advanced-lock-on-logic/3685500).

### Target acquisition and moving enemies

- Roblox-specific soft-lock sources are thin. The one aim assist thread only suggests snapping the camera toward a hovered character and auto-firing for mobile (https://devforum.roblox.com/t/how-to-make-aim-assist/842957).
- Velocity prediction for moving targets exists in hitbox modules. HitboxClass offsets by `AssemblyLinearVelocity` divided by a multiplier (default 6) (https://devforum.roblox.com/t/hitboxclass-v20-a-powerful-oop-based-hitbox-module/3929512). MuchachoHitbox's author warns "I don't think it's possible to make the hitboxes feel accurate to the characters using velocity prediction alone", and a user reports it lags when a player turns quickly (https://devforum.roblox.com/t/muchachohitbox-an-easy-to-use-spatialquery-based-hitbox-system/3682320). HitQuery left velocity prediction out because it overshoots when velocity changes sign (https://devforum.roblox.com/t/hitquery-%E2%80%94-a-stateful-hitbox-module-powered-by-roblox-spatial-queries/3050810).
- Practical rule: re-aim toward the target's current position every frame during the warp window instead of predicting far ahead (unsourced, but consistent with the prediction warnings above).

### Preventing teleport-like snaps

- Cap the warp distance per attack and cap the angular speed of the facing rotator, so a far target produces a shorter, believable step rather than a jump (unsourced).
- Stop the warp when the target leaves the acquisition range or angle, or when an obstacle is detected by a forward cast (wall cast idea from https://devforum.roblox.com/t/dash-is-inconsistent/2017959).

## 3. Lock-on camera systems

### Camera behavior

- A souls lock-on posted in 2025 keeps the camera centered on the enemy while the player sits slightly off to one side, then follows the player once an offset is exceeded. The author says this "made the camera feel less clunky and made it easier to see and fight." The camera is driven by "the cframe of a part welded to the character" (https://devforum.roblox.com/t/souls-lockon-system/3686359).
- A related "advanced" lock-on uses a Scriptable camera, a part welded at an offset to the player's root, a horizontal dead zone (example 5 studs each side), updates on PreRender only when either root moved, and breaks lock if either humanoid dies, the distance exceeds maxDistance, or a character is missing (https://devforum.roblox.com/t/advanced-lock-on-logic/3685500).
- Ordering bug: a lock-on camera glitched while walking backward because the camera used last frame's root CFrame; the fix is to set the root CFrame first, then update the camera (https://devforum.roblox.com/t/lock-on-camera-system-glitching/3126817).
- A shift-lock style alternative (humanoid faces the camera) made attacks land at odd angles because of the camera offset (https://devforum.roblox.com/t/choppy-lock-on-system-solved/2894349).

### Hard lock vs soft lock and target switching

- No Roblox source compared hard and soft lock or described target switching scoring. The common souls pattern (hard lock toggled by a button, switch by flicking the right stick or mouse past a threshold, choose the candidate with the smallest screen-space angle in the flick direction) is (unsourced).

### Mobile and gamepad

- IAS is fully released. Each InputAction "should have an InputBinding for gamepad, keyboard/mouse, and touch", touch uses a binding's UIButton property, gamepad uses KeyCodes such as ButtonY, Direction2D covers sticks, and Sink on a higher-priority context blocks lower ones. The Controller Emulator tests gamepad input in Studio, and InputActionLabel (beta) shows the right glyph per device (https://create.roblox.com/docs/en-us/input/input-action-system).
- Default PlayerScripts are migrating to IAS: opt-in now through `Workspace.PlayerScriptsUseInputActionSystem`, default enabled in Phase 2 (early 2027), and the property removed in Phase 3 (mid 2027) (https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416). A custom lock-on camera should be tested against the new scripts before early 2027.
- Input Action Manager (Studio beta, July 2026) is a visual editor to build and audit cross-platform mappings (https://devforum.roblox.com/t/weekly-recap-july-13-%E2%80%93-17-animation-graphs-go-live-5%C3%97-more-data-store-storage/4743286).
- Under Server Authority, camera state replication moves to `Player:GetCameraState()`, a breaking change for scripts using `CameraContext.CameraAction` (https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993).

## 4. Network behavior

### Who moves the attacking character

- Movers on a player character should be created on the client. A server-created LinearVelocity dash looked fine to the dasher but laggy and teleport-like to others because "the Server is trying to move the Character with LinearVelocity but the NetworkOwnership is set to the LocalPlayer"; moving creation to the client fixed it (https://devforum.roblox.com/t/weird-lag-on-ability/2399772).
- Client ownership cannot be verified: "Roblox cannot verify physics calculations when a client has ownership", so clients can teleport parts or fake Touched events and the server must check validity (https://create.roblox.com/docs/en-us/physics/network-ownership.md).
- End-of-dash snap for observers (August 2026): a client-driven steerable dash replayed to observers 0.06 s behind showed "a visible pause/snap at the end when control returns to normal Roblox replication." The diagnosis was "transitioning from a player 0.06 seconds in the past directly to the real time player", and the suggested fix was interpolating from the dash end back into normal movement, or a hidden-character render rig lerped over about 0.06 s (https://devforum.roblox.com/t/how-do-i-achieve-smooth-player-velocity-on-all-clients/4776253). Sword Bound uses normal replication for lunges, so it avoids this class of bug unless it adds custom replay (unsourced).

### Server validation (anti-exploit)

- Melee hit distance check: accept if attacker to victim distance is within hitbox length plus 3 studs for latency, tuned by testing (https://devforum.roblox.com/t/hitboxs-dilema-server-or-client/4012087).
- Position history: sample every player's CFrame on Heartbeat every 0.05 to 0.1 s, keep about 2 s, rewind by ping/2, interpolate between samples, skip interpolation after a teleport (https://devforum.roblox.com/t/combat-system-with-rollback/3685525). Another August 2026 thread used ping/2 plus a 0.05 s buffer and was told to validate cooldowns, range, state, and timestamps, reject old timestamps, cap rewind depth, and avoid trusting a full client CFrame: "The server should remain authoritative" (https://devforum.roblox.com/t/am-i-doing-hitbox-replication-right/4773807).
- Lunge distance validation: no source gave a formula. A workable check is that the server-observed root displacement during an attack window must not exceed the attack's max warp distance plus attack-state walk speed times elapsed time plus a latency tolerance (unsourced). The Heartbeat history above supplies the samples.
- Server Authority as an alternative: it "automatically rejects invalid client movement" and predicts inputs locally with rollback and resimulation; custom movement must move into `RunService:BindToSimulation` with InputActions; it requires NextGenerationReplication, IAS player scripts, Deferred signals, StreamingEnabled and fixed simulation; Animators are limited to eight active tracks; remote events are not synchronized with the simulation timeline; synchronized remotes and server-side rewind hit detection are "being examined" and not available (https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993, https://create.roblox.com/docs/en-us/projects/server-authority.md). A July 2026 thread reports camera, attribute and prediction-mode problems with no staff reply (https://devforum.roblox.com/t/server-authority-barely-works-many-issues/4732583).

### NPC targets and knockback

- Laggy knockback on NPCs happens "because it's an NPC and the attacking player isn't the network owner"; options are handing ownership of the NPC root to the attacker for the knockback, or applying on the server and firing all clients to play it too (https://devforum.roblox.com/t/laggy-knockback-linear-velocity/2950780).
- Ownership handoff looked smooth to the attacker but laggy to other players; mover-based knockback on player characters always shows ping delay; ApplyImpulse "feels like the force you would receive from a hit"; setting Massless on the root for about 0.5 s during knockback was suggested (https://devforum.roblox.com/t/how-to-make-proper-knockback-for-a-combat-system/3936670).
- Unanchored parts near a player can be auto-assigned to that player's client; `SetNetworkOwner(nil)` keeps gameplay-critical objects on the server, used "conservatively" because it can make physics jittery for clients (https://create.roblox.com/docs/en-us/physics/network-ownership.md).

## 5. Hitboxes for responsive M1s

### Engine queries

- `GetPartBoundsInBox` "efficiently considers the volume of parts' bounding boxes rather than their actual occupied volume"; `GetPartsInPart` uses "a full geometric collision check"; Blockcast, Spherecast and Shapecast do "not detect BaseParts that initially intersect the shape" (https://create.roblox.com/docs/en-us/reference/engine/classes/WorldRoot.md).
- Shapecasts return the first hit only, max cast length 1024 and max shape size 512 studs, and have no contact margin, so a shape "infinitesimally close will not register as a hit" (https://devforum.roblox.com/t/introducing-shapecasts/2320655).

### Modules

| Module | Method | Notes | Source |
|---|---|---|---|
| ShapecastHitbox v0.2.5 (Apr 2025, MIT) | DmgPoint attachments cast between last and current frame, ray, block or sphere per point | Author: "ideally, always use ShapecastHitbox on the client"; resolution "capped to the user's current frame rate"; misses parts already overlapping at start; OnHit fires per cast so dedupe targets | https://devforum.roblox.com/t/shapecasthitbox-for-all-your-melee-needs-v025/3624241, https://github.com/TeamSwordphin/ShapecastHitbox |
| RaycastHitbox 4.01 | Rays from weapon attachments each frame | Superseded by ShapecastHitbox and no longer supported | https://devforum.roblox.com/t/374482 |
| MuchachoHitbox (Jun 2025) | Spatial query box or sphere, optional velocity prediction | Author recommends "client sided combat with safety checks" | https://devforum.roblox.com/t/muchachohitbox-an-easy-to-use-spatialquery-based-hitbox-system/3682320 |
| HitboxClass v2 (Sep 2025) | Spatial queries, velocity prediction | "Server-side focused" | https://devforum.roblox.com/t/hitboxclass-v20-a-powerful-oop-based-hitbox-module/3929512 |
| Hitbox Module by Salvatore (Sep to Dec 2025) | Parts-in-part queries, can offload to client, reports enter and leave | Server validates | https://devforum.roblox.com/t/hitbox-module-by-salvatore/3913281 |
| HitQuery v0.1.6 (Jan 2026) | GetPartsInPart | Velocity prediction removed due to overshoot | https://devforum.roblox.com/t/hitquery-%E2%80%94-a-stateful-hitbox-module-powered-by-roblox-spatial-queries/3050810 |

- Precision vs forgiveness: RaycastHitbox was recommended for "pinpoint accurate hitboxes" and Muchacho for hitboxes "easier for players to use in gameplay" (https://devforum.roblox.com/t/raycast-hitbox-401-or-muchachohitbox/2697964).

### Hit confirmation latency

- The client can play effects immediately when it thinks it hit, then the server accepts or rejects and may send a confirmation that triggers a second effect (https://devforum.roblox.com/t/hitboxs-dilema-server-or-client/4012087).
- Delaying attacker effects until server validation felt "super delayed and did not feel responsive at all"; the counter-view is that server-side detection input delay is "very, very hard to notice when < 100 ping" (https://devforum.roblox.com/t/responsive-combat/2840397).
- A rollback design plays animation, sound and VFX immediately on the client, then has clients play hit effects only after the server's ConfirmedHit (https://devforum.roblox.com/t/combat-system-with-rollback/3685525).

## 6. Animation playback tricks

### Core API values

- `Play(fadeTime, weight, speed)` default fadeTime is 0.1 s; `Stop(fadeTime)` default 0.1 s; `AdjustSpeed(0)` pauses; weight 0 shows no movement; on equal priority, weights blend; `GetMarkerReachedSignal` fires on named KeyframeMarkers; setting TimePosition requires the track to be playing (https://create.roblox.com/docs/en-us/reference/engine/classes/AnimationTrack.md).
- Priorities from low to high: Core, Idle, Movement, Action, Action2, Action3, Action4, applied per joint (https://create.roblox.com/docs/en-us/reference/engine/enums/AnimationPriority.md).

### Hitstop

- Freeze all playing tracks with `AdjustSpeed(0)` in a loop; a common bug is a `return` inside the loop that stops after the first track (https://devforum.roblox.com/t/adjustspeed-working-inconsistently/2643111).
- AdjustSpeed set on the client was reported not to replicate reliably to the server ("sometimes does not pause at all"), with no confirmed explanation (https://devforum.roblox.com/t/problem-with-animationtrackadjustspeed/2337155). Treat hitstop as a per-client local effect triggered by a hit event, not as something replication will carry (unsourced conclusion from that report).

### Snappy chains and cancels

- The default 0.1 s fade softens chains; the brief's 0.06 s fade-in is already below default. For combo links, stopping the previous swing with a short fade while starting the next one avoids a double pose (unsourced).
- Cancel windows: snapshot a state counter when a move starts and abort at each yield if it changed (https://devforum.roblox.com/t/cancel-system-for-combat-system/3600431). The same thread debates marker events vs `task.wait` timing: one dev measured markers a few frames less accurate, another found them "very accurate".
- `GetMarkerReachedSignal()` now fires for markers on a final keyframe, fixed in the Animation Graphs release (https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840).
- A third-party report says that after a late-April 2026 update, fade times "seem to be ignored entirely" and blends snapped, possibly tied to ClientAnimatorThrottling Phase 3; Roblox had not confirmed a cause (https://www.creation.dev/learn/roblox-animation-blending-broken-april-2026-update). Secondary source; verify in Studio.

### What is new and usable in 2026

- Animation Graphs: Blend1D and Blend2D with phase sync, Select and Priority Select, Mask for upper-body layering, Add and Subtract layers, parameters set by `SetParameter`, existing `LoadAnimation` scripts still work, and graphs replicate automatically. Users are still asking for inertialization, mirroring and nested graphs (https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840). Graph events "propagate upward from their source node", are silenced when weight hits zero, and are observable via `GetMarkerReachedSignal`; under Server authority "the server drives the full graph simulation" with client prediction (https://create.roblox.com/docs/en-us/animation/graph-editor.md).
- IKControl: LookAt, Position, Rotation and Transform types; Weight 0 to 1; SmoothTime default 0.05; higher Priority resolves later; it overrides animation between ChainRoot and EndEffector; avoid using the character root as ChainRoot (https://create.roblox.com/docs/en-us/reference/engine/classes/IKControl.md). A forum LookAt setup uses Torso as ChainRoot and Head as EndEffector, with constraints to limit the neck (https://devforum.roblox.com/t/ikcontrol-for-lookat-motion/4013242).
- Animator throttling: with PreferLodEnabled (default true) the engine "may reduce animation evaluation frequency for remotely-simulated characters", overridable by `Workspace.ClientAnimatorThrottlingMode` (https://create.roblox.com/docs/en-us/reference/engine/classes/Animator.md). Fast swings on other players may look less smooth to observers.
- Replication of client-played tracks: animations started on the client for the local character's Animator "will be replicated to the server and other clients"; the Animator must be created on the server (https://create.roblox.com/docs/en-us/reference/engine/classes/Animator.md).

## Recommended approach for Sword Bound

This section maps the sourced techniques onto the existing code. Numbers here are starting points for playtesting and are (unsourced) unless a URL is given.

### A. Turn the lunge into a warp window (MovementController)

1. Keep LinearVelocity; it is the official mover for this job (https://create.roblox.com/docs/physics/mover-constraints). Create one per character on the client at spawn and toggle `Enabled`, instead of creating and destroying per attack, since a client-created mover avoids the observer lag of server-created ones (https://devforum.roblox.com/t/weird-lag-on-ability/2399772).
2. Use Plane mode with world X and Z tangent axes, so gravity, slopes and jump arcs stay natural during the lunge (https://devforum.roblox.com/t/trouble-creating-dashroll/2069422, https://devforum.roblox.com/t/how-to-make-a-linear-velocity-movement-system/3888906). Do not switch RelativeTo or mode on the same constraint between attacks (https://devforum.roblox.com/t/linearvelocity-linedirection-will-not-replicate-accurately/4677374).
3. Replace "fixed 20 studs/s x scale for 0.15 s" with a distance-targeted warp. At the Lunge marker, compute `desired = clamp(distToTarget - stopDistance, 0, maxWarp)`. Each Heartbeat until HitStart, recompute the remaining distance to the target's current position and set PlaneVelocity so the remaining ease-out curve covers it. This is motion warping done by hand, modeled on Unreal's warp windows (https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-warping-in-unreal-engine).
4. Starting values (unsourced): stopDistance 3.0 to 3.5 studs (current 3.2 is fine with a 7 stud reach); maxWarp light 2.5, Light3 3.5, running attack 6 to 7, heavy release 3; acquisition range 10 studs when locked and 8 when soft-targeting; with no target, fall back to the current fixed lunge so whiffs still move forward.
5. Add a forward Blockcast or `GetPartsInPart` check before and during the warp to shorten it at walls (https://devforum.roblox.com/t/dash-is-inconsistent/2017959).
6. Put characters in a collision group that does not collide with itself during attack windows, or add NoCollisionConstraints to the target, so the lunge does not shove the enemy out of the blade path (https://devforum.roblox.com/t/confused-on-making-a-dash-slash/1683248).
7. Make the running attack read differently by carrying sprint velocity into a longer warp (the existing 2.2 scale becomes a 6 to 7 stud cap) and starting it at the Lunge 0.08 marker with almost no slowdown, then a hard stop at HitStart (unsourced). Pair it with a distinct pose; that is an animation task covered in the prior vault reports.

### B. Soft targeting and facing (AlignOrientation)

1. Keep AlignOrientation in OneAttachment mode with yaw-only facing and AutoRotate off during attacks (https://devforum.roblox.com/t/align-orientation-issues/3436776, https://devforum.roblox.com/t/2539863).
2. When not locked, pick the best candidate at input time from the existing 60 degree cone (score by angle first, distance second), then during windup (attack start to HitStart) rotate toward it with a capped turn rate of about 540 to 720 degrees per second, and commit facing at HitStart as today (unsourced).
3. Fall back to move-input direction if no candidate exists, and drop the soft target if it leaves 1.5x the acquisition range mid-swing (unsourced).
4. Do not predict target velocity more than a frame or two; re-aim every Heartbeat instead (prediction warnings at https://devforum.roblox.com/t/muchachohitbox-an-easy-to-use-spatialquery-based-hitbox-system/3682320 and https://devforum.roblox.com/t/hitquery-%E2%80%94-a-stateful-hitbox-module-powered-by-roblox-spatial-queries/3050810).

### C. Lock-on controller

1. Use a dead-zone camera that keeps the enemy centered while the player drifts within a band, then follows the player (https://devforum.roblox.com/t/souls-lockon-system/3686359, https://devforum.roblox.com/t/advanced-lock-on-logic/3685500). Update facing first, camera second (https://devforum.roblox.com/t/lock-on-camera-system-glitching/3126817).
2. Break lock on death, missing character, distance above a max, or long line-of-sight loss (first three from https://devforum.roblox.com/t/advanced-lock-on-logic/3685500; line of sight is unsourced).
3. Move F/MMB lock, Q roll and M1/M2 into IAS InputActions with keyboard, gamepad and touch bindings, a touch UIButton for lock, and a Direction2D right-stick flick to switch targets (https://create.roblox.com/docs/en-us/input/input-action-system). Test against the IAS PlayerScripts before they become default in early 2027 (https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416).
4. On mobile, consider making soft targeting (section B) stronger and lock-on a single tap toggle, since mobile players aim with a thumb (unsourced).

### D. Network

1. Keep the client-detected, server-validated model. Add a server position history (Heartbeat samples every 0.05 to 0.1 s, about 2 s kept) and validate hits by rewinding the target by ping/2 plus a small buffer (https://devforum.roblox.com/t/combat-system-with-rollback/3685525, https://devforum.roblox.com/t/am-i-doing-hitbox-replication-right/4773807), with a distance tolerance of reach plus about 3 studs to start (https://devforum.roblox.com/t/hitboxs-dilema-server-or-client/4012087).
2. Validate lunge displacement from the same history: during an attack window, server-observed root travel must stay under that attack's maxWarp plus 0.3 x WalkSpeed x elapsed plus a latency tolerance; repeated violations flag, not kick (unsourced).
3. For SparringKnight and other NPCs, keep ownership on the server with `SetNetworkOwner(nil)` during combat so they do not auto-transfer to a nearby player (https://create.roblox.com/docs/en-us/physics/network-ownership.md), apply knockback on the server, and let the attacker's client play the hit reaction animation and sparks immediately (https://devforum.roblox.com/t/laggy-knockback-linear-velocity/2950780). Keep NPC knockback small for light hits so the server delay is not visible (unsourced).
4. Do not migrate to Server Authority now. It requires rewriting movement into BindToSimulation, caps Animators at eight active tracks, and lacks synchronized remotes and server rewind hit detection (https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993). Revisit if exploiting becomes a real problem, and prototype on a copy as Roblox recommends (same source).

### E. Hitbox

1. Keep the swept blade box on the client. At HitStart, also run one `GetPartBoundsInBox` (or `GetPartsInPart` for accuracy) overlap so enemies already inside the blade volume are not missed, because shapecasts skip initial overlaps (https://create.roblox.com/docs/en-us/reference/engine/classes/WorldRoot.md).
2. If you want to drop custom code, ShapecastHitbox is the maintained successor to RaycastHitbox and is meant for client use with server sanity checks; dedupe hits per swing (https://devforum.roblox.com/t/shapecasthitbox-for-all-your-melee-needs-v025/3624241).
3. On local hit detection, play hitstop, sparks, sound and camera shake immediately; apply damage numbers and enemy health changes on server confirmation (https://devforum.roblox.com/t/hitboxs-dilema-server-or-client/4012087, https://devforum.roblox.com/t/responsive-combat/2840397).

### F. Animation

1. Hitstop: on hit, pause every playing track on the attacker and victim with `AdjustSpeed(0)` for the class duration (0.07 light, 0.12 heavy already in code), then restore speed. Run it locally on each client from a hit event, since client AdjustSpeed may not replicate (https://devforum.roblox.com/t/adjustspeed-working-inconsistently/2643111, https://devforum.roblox.com/t/problem-with-animationtrackadjustspeed/2337155). Also pause the lunge LinearVelocity during hitstop so the body freezes with the pose (unsourced).
2. Chains: start the next combo hit at CancelOpen with fadeTime around 0.03 to 0.05 and stop the previous track with the same fade (default is 0.1 s per https://create.roblox.com/docs/en-us/reference/engine/classes/AnimationTrack.md; the shorter values are unsourced). Consider pulling Light1 and Light2 CancelOpen from 0.50 to about 0.40 to tighten the string (unsourced, based on the brief's 500 ms gap).
3. Priorities: locomotion at Movement, attacks at Action2, hit reactions and hitstun at Action3, finishers or Sword Skills at Action4, so the hierarchy is fixed per joint (https://create.roblox.com/docs/en-us/reference/engine/enums/AnimationPriority.md).
4. Animation Graphs: a good fit for locomotion and lock-on strafing (Blend2D on move direction) with a Mask so the sword arm stays in the combat layer; keep attack timing in the existing marker-driven scripts until graphs offer clip restarts and inertialization (https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840).
5. IKControl LookAt on the torso or head toward the locked target, with Weight about 0.5 to 0.7 and the default SmoothTime 0.05, gives a read of intent during windups without fighting the swing (API from https://create.roblox.com/docs/en-us/reference/engine/classes/IKControl.md; weights unsourced). Turn it off during active frames.
6. Root motion is not available, so keep animations in place and let the warp script own displacement (https://devforum.roblox.com/t/2446417).

## Open questions for a follow-up pass

- A real TSB or JJS M1 teardown (search budget ran out before more threads could be checked).
- Whether AdjustSpeed replication behaves differently in 2026 (the report found is from 2023 era).
- Whether the April 2026 blending regression has been fixed (only a secondary source found).
- Reddit and X coverage, which this environment could not reach.
