---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - weapons
  - vfx
  - roblox
---

Up: [[Claude]] · Used by: [[Weapon models and effects plan]]

Produced by a research agent on 2026-10-08 for Henry's request to research big anime Roblox games and fighting games so their animation and effects design can be replicated. Reproduced as the agent returned it, with headings adjusted. Claims marked unsourced or judgment are the agent's own calls.

## Forum pass status
 Reddit was blocked. WebFetch to reddit.com and old.reddit.com returned SITE_BLOCKED, and a WebSearch restricted to reddit.com was rejected by the proxy. So r/robloxgamedev and r/blender could not be read, and nothing below comes from Reddit. The forum pass used the Roblox DevForum (many threads read) and polycount (two weapon-budget threads read). realtimevfx.com showed up in search results but I did not read it.

## 1. Weapon models on Roblox

### Limits and textures
- Roblox's mesh spec says individual meshes can't go over 20,000 triangles [1]. The old 10,000 cap shows up in a 2022 DevForum thread [2]. A May 2026 feature request asks for 60k to 200k, so 20k is still the limit [3]. One vendor blog (Nilo) claims about 10k for batch import and 21k for single import [4]. Treat that as unverified and use the official 20k.
- For comparison, the whole default R15 body is budgeted at 10,742 triangles across 15 meshes, and each arm (upper, lower, hand) gets 1,248 [5]. A weapon that costs more triangles than the whole body is out of proportion.
- Polycount veterans put third-person weapons at "400 to 2k tris" [6] and "500-5,000 depending on the size and complexity" [7]. They also note that big textures cost more frame time than extra triangles [7].
- Textures. UV texture maps go up to 1024x1024 [8]. The PBR budget is 256x256 for every 2x2x2 studs an asset fills, and 256 is the "maximum budget for non-albedo maps" on rigid accessories [8]. Roblox's performance guide says a 1024 texture uses 4x the memory of a 512 one, and most images need 512 or less [9].
- SurfaceAppearance supports Color, Normal (OpenGL tangent space), Roughness, Metalness and an Emissive mask [10]. SurfaceAppearance.Color tints the color map with no performance cost, so one texture can serve many color variants [10].
- Emissive masks shipped to live experiences on Feb 12, 2026 [11]. EmissiveStrength and EmissiveTint can be changed from scripts at runtime, and the sample place uses that for flicker and glow. The mask texture itself can only be set in edit mode [11]. Emissives also show at every quality level and don't fade with distance [11]. This is the cleanest way to make a sword skill light up the blade.
- MaterialVariant is for tileable materials reused across many parts. SurfaceAppearance is for one UV-mapped mesh [12]. Use SurfaceAppearance for weapons.
- Batching. Meshes with the same mesh content and identical SurfaceAppearances can render in one draw call [9]. I couldn't confirm whether different tint colors break that batching (unsourced, judgment).

### Import
- The 3D Importer takes .fbx, .obj and .gltf. Only .fbx and .gltf carry PBR textures and hierarchies. It has a Merge Meshes option and a Scale Unit setting [13].
- Blender FBX export settings from the docs: Apply Scalings set to "FBX Unit Scale", Path Mode set to Copy, Embed Textures on, Add Leaf Bones off [14].

### Physics settings for a weapon
- Set Massless = true. A massless part welded to a part with mass adds no mass. A massless part should never become the assembly root [15].
- Set CanCollide = false and CanTouch = false. Turning both off gives "a small performance gain" [15].
- Set CanQuery = false so your hitbox queries and camera raycasts skip the blade. It only takes effect when CanCollide is false [15].
- Set CollisionFidelity = Box. The docs recommend Box for small or non-interactive meshes as the cheapest option [16].
- A DevForum answer from Oct 2025 suggests the same combination for tool parts that disturb character physics [17].
- Keep combat hitboxes separate from the visual mesh (unsourced, judgment).

## 2. Attaching and animating weapons

- The standard method is a Motor6D with Part0 = RightHand and Part1 = the weapon's Handle or root. Then include the Handle in the animation keyframes [18][19].
- A Feb 2024 thread got this backwards (Part0 set to the weapon) and fixed it by swapping the two [19].
- A Dec 2024 thread broke because a Weld sat between the same two parts as the Motor6D. Removing the Weld fixed it [18].
- Use Action priority or higher for these animations [18].
- The long-running Headstackk tutorial uses a "BodyAttach" root part with a Motor6D created by a server script, plus a client copy so the weapon appears instantly. It says connecting to the torso lets the weapon animate independently of the arms, while connecting to the arm makes it follow the arm [20].
- RigidConstraint joins two Attachments with zero offset [21]. It works for static attachment points, but the Animator does not drive it (unsourced, judgment). That is why Motor6D is the right choice for anything that swings.
- Two-handed grips. Default tool animations have no left-arm data, so the left hand only moves if you animate it [22]. You can keyframe the left hand onto the grip. Or you can add an IKControl with EndEffector LeftHand, ChainRoot LeftUpperArm, and Target set to a "LeftGrip" Attachment on the weapon [23]. IKControl can be added by script at runtime [23]. Pinning the hand to the weapon is a judgment call on my part. The docs' example is a doorknob.
- Sheathing. DevForum suggestions are a WeldConstraint to the torso with a CFrame offset [24], or an accessory-style attachment [25]. My recommendation is simpler: keep one Motor6D and, on sheathe, change Part0 to UpperTorso (back) or LowerTorso (hip) with a C0 taken from a torso Attachment. The draw animation can keyframe that same joint (unsourced, judgment).
- I found no first-party write-ups on how Deepwoken or other top sword games attach weapons. One detail: Deepwoken's wiki says an enchant's visual effect carries over to a sidearm [26].

## 3. Silhouette and readability per class

- Scale. 1 stud = 0.28 m in Roblox physics units [27]. Avatars are about 5 to 6 studs tall [28], and the classic body range is 3.6 to 9.1 studs [5]. Because avatars are stylized, size weapons against a 5.5-stud character, not real meters (unsourced, judgment). At 5.5 studs for a 1.75 m person, 1 stud is about 32 cm.
- Real-world references:
  - Arming sword blade: 70 to 80 cm [29], about 2.3 to 2.5 studs.
  - Rapier blade: 104 cm or more, about 1 kg [30], so about 3.3 studs.
  - Zweihänder: at least 1.4 m and up to 2.13 m overall, 2 to 4 kg [31], so 4.4 to 6.7 studs.
- Elden Ring sorts weapons into separate classes such as Straight Swords, Greatswords and Colossal Swords [32]. Each class has its own damage profile:
  - Straight swords and axes deal Standard damage.
  - Thrusting swords deal Pierce.
  - Hammers and many colossal weapons deal Strike [33].
  - Greataxes are mostly Standard damage, with slow overhead smashes and horizontal sweeps on heavies [34].
  - Thrusting swords have subtle, hard-to-read windups [35].
- I found no FromSoftware source on silhouette design specifically. The practical rule is that the class should read from a black silhouette at gameplay distance (unsourced, judgment):
  - Rapier reads by a thin line plus a cup guard.
  - Dagger reads as short.
  - Greatsword reads as body height with a long grip.
  - Greataxe reads by its head mass at the end of the haft.
- An 80.lv weapon art guide recommends "one or two things pop" for silhouette interest, plus clear value contrast between planes [36].
- SAO references:
  - Elucidator is pitch black with a gray outline. Its hand guard drops down on the right side, and it was a Floor 50 boss drop [37].
  - Dark Repulser is a pale, slightly translucent white blade in the novels. In the anime it is aqua, with a guard shaped like two dagger blades around an aquamarine gem. It was forged from a crystal ingot [38].
  - Lambent Light is Asuna's Lisbeth-forged rapier [39]. Prop builders describe a round, basket-style guard in teal and silver [40].

## 4. Rarity and upgrade visuals

- WoW's quality colors are the de facto MMO standard: Poor gray #9d9d9d, Common white, Uncommon green #1eff00, Rare blue #0070dd, Epic purple #a335ee, Legendary orange #ff8000 [41].
- Lineage 2 gives weapons a dim aura starting at +4 that grows with each enchant level [42].
- In the same thread, players argue that strong glows hurt visibility in combat [42]. That matters for a parry-timing game.
- Deepwoken shows enchants mainly through on-attack effects, not a constant glow. For example, Umbral Knight adds a delayed red slash on hit [26].
- SAO has upgrade numbers like Elucidator +45 and Lambent Light +32 [37][39], but I found no canon visual for plus levels.

## 5. Effects pipeline (2025-2026)

- Trails. A Trail draws between two Attachments. Lifetime runs 0.01 to 20 s (default 2). WidthScale is a 0 to 1 multiplier sequence. LightEmission 1 means additive blending. MaxLength 0 means no length cap. FaceCamera is available, and Clear() wipes all segments instantly [43][44].
- DevForum practice is to toggle Enabled on animation markers such as SwingStart and SwingEnd, and to handle cancelled swings [45].
- Beams draw a texture along a Bezier curve between two Attachments, with CurveSize0/1 and Width0/1 [46]. Using them for slash arcs is my inference, not a documented use case.
- Flipbooks. Grid2x2, Grid4x4 and Grid8x8 layouts, square power-of-two textures from 8 up to 1024 px, released Oct 2022 [47]. Modes are Loop, OneShot, PingPong and Random, capped at 30 fps [48]. Squash, LockedToPart, ZOffset and Orientation (including VelocityParallel) are all available [48].
- Mesh slashes are built from slash meshes and textures made in Blender. A DevForum tutorial author says particle emitters are "less heavy" than mesh slashes [49].
- Highlight. The per-place limit went from about 31 to 255 on Nov 10, 2025. Each highlighted object costs a draw call, plus a post-processing cost whenever one is on screen [50].
- No dedicated new Roblox VFX editor turned up in my searches (unsourced).
- Performance, from the docs:
  - Create VFX on clients. The server only needs the location [9].
  - Particles add draw calls [9].
  - Stacked transparency causes overdraw [9].
- Performance, from the DevForum community:
  - Particle Rate is automatically lowered at lower graphics quality, but :Emit() bypasses that, so scale Emit counts yourself [51][52].
  - Neon and ForceField materials are expensive [52].
- Pooling. ObjectCache (Aug 2024) batches moves with workspace:BulkMoveTo and is reported faster than PartCache [53].

## 6. Asset sourcing

- Creator Store. Assets are for public use in games. You can't resell composites that contain Restricted assets you didn't make. Roblox warns that free models can load "virus" assets at runtime, and you can insert them with Disable Scripts [54].
- Commission prices. Every data point I found is dated, from 2020-2021 DevForum posts unless noted:
  - $20 to $25 per melee weapon model, as a buyer's offer [55].
  - A modeler asking about 2k to 15k Robux per model [56].
  - About 7,500 Robux for a detailed weapon [57].
  - VFX at 1,000 to 3,000 R$ per effect, about $3.50 to $10.50 [58].
  - A current, undated portfolio asking 60k+ Robux per effect [59].
  - Treat all of these as outdated anchors.
- Talent Hub is the official job board. Roblox takes no responsibility for payment disputes, and it isn't open to under-13 users [60].
- I found no reliable sources for Twitter/X or Discord commission markets (unsourced).
- AI meshes. Cube launched in beta in March 2025, and "complex" objects were listed as future work [61]. In GenerationService, GenerateMeshAsync treats SuggestedSize as approximate only, and GenerateModelAsync has a MaxTriangles cap [62]. A vendor reports AI meshes have dense, messy topology that needs retopology and texture atlasing [4].
- I found no sourced review of Cube on weapons. My view is to use it for blockouts only, because thin blades and crisp edges are its weak spot (unsourced, judgment).

## Proposed plan for Sword Bound

### Shared spec for every class
- Hierarchy: Model containing MeshPart "Handle" (grip at origin), MeshPart "Blade" or "Head", Attachments "TrailTop" and "TrailBottom", "LeftGrip" (two-handers only) and "SheathPoint".
- Mount with one Motor6D "WeaponGrip": Part0 = RightHand, Part1 = Handle, created on the server with a client mirror [18][20].
- Physics: Massless, CanCollide/CanTouch/CanQuery all false, CollisionFidelity Box [15][16].
- Surface: SurfaceAppearance PBR plus an emissive mask painted on the edge or fuller [10][11].

Lengths are scaled from the real-world figures above at about 32 cm per stud on a 5.5-stud avatar. The roughly +15% anime stretch is my judgment.

| Class | Overall length | Tri budget | Textures | Mount and sheath |
|---|---|---|---|---|
| One-handed sword | 3.6 studs (blade 2.8) | 1,500 | Color 512, other maps 256 | RightHand; left hip |
| Dagger | 1.5 studs (blade 1.0) | 1,000 | All maps 256 | RightHand; back of waist |
| Rapier | 4.0 studs (blade 3.3, width 0.08 or less, round guard about 0.5) | 1,500 | Color 512, other maps 256 | RightHand; left hip |
| Two-handed sword | 5.2 studs (grip 1.0) | 2,500 | Color 512, other maps 256 | RightHand plus IKControl LeftHand to LeftGrip; diagonal on back |
| Two-handed axe | 4.8 studs haft, head about 1.4 x 1.2 | 2,500 | Color 512, other maps 256 | RightHand plus IKControl; on back |

- Hard ceiling: 4,000 triangles for legendary variants. That stays far under the 20k cap and below about 40% of a full body [1][5].

### Rarity and upgrades
- Use WoW colors for rarity on the UI and nameplate [41].
- On the model, use SurfaceAppearance.Color tints on trim and a small emissive accent. Turn on a faint aura only from +7, and a stronger one at +10, echoing Lineage 2's thresholds [42].
- Keep the aura subtle so parry reads stay clean [42].

### VFX kit (all client-side, pooled through ObjectCache, effects fired with Emit and scaled to quality level) [9][51][53]
- Swing trails, one Trail per class. Toggle on animation markers and call Clear() at swing start [44][45]. LightEmission 1, white-to-transparent fade, FaceCamera on [43].
  - Dagger: Lifetime 0.10 s, thin.
  - One-handed sword: 0.15 s.
  - Rapier: 0.08 s, very thin line.
  - Greatsword and greataxe: 0.25 s, wide, WidthScale tapering from 1 to 0.
  - These values are judgment. Tune them in Studio.
- Hit sparks by damage type, mapped like Elden Ring [33]:
  - Slash (sword, dagger, greatsword): white-gold streak sparks, 8 to 12 particles, VelocityParallel.
  - Pierce (rapier, dagger thrusts): a narrow forward cone plus a small ring flipbook.
  - Strike (greataxe, greatsword heavies): dust burst, 4x4 impact flipbook and camera shake.
- Parry: orange spark burst. Perfect parry: white flash flipbook, a 0.1 s Highlight on the attacker [50], and brief hit-stop.
- Stagger or posture break: a ring flipbook and a looping daze particle over the head.
- Riposte: a red tint flash on the target and a heavy blood-or-light slash Beam arc.
- Sword skill glow: EmissiveStrength ramp at runtime [11] plus a recolored Trail. Glow colors:
  - One-handed sword: blue by default; Vorpal Strike crimson, matching the novel (the anime shows yellow) [63].
  - Rapier: silver, matching Linear in the novel [64].
  - Dagger: green.
  - Greatsword: orange.
  - Greataxe: red-orange.
  - All except Vorpal Strike and the rapier's silver are judgment calls.

### Build order
1. Blocked-out greybox meshes for all 5 classes at the lengths above, with Attachments, the Motor6D and the physics flags.
2. Port the existing SwingTrail to per-class Trail presets driven by markers.
3. The hit spark set (3 types) plus a pooling module.
4. Parry, perfect parry, stagger and riposte effects.
5. Final meshes, starting with the one-handed sword and its SAO-style hero variants, with PBR and emissive masks.
6. Two-handed IK grips and the sheath swap.
7. Sword skill emissive glow.
8. Rarity tints and +N auras.
9. A mobile pass: test Emit counts at low quality, and check draw calls with Shift+F2 [9].

## Sources
[1] https://create.roblox.com/docs/art/modeling/specifications
[2] https://devforum.roblox.com/t/exceed-10000-triangle-limit/1760555
[3] https://devforum.roblox.com/t/increase-the-max-triangle-limit/4650221
[4] https://nilo.io/articles/fix-messy-ai-roblox-assets
[5] https://create.roblox.com/docs/en-us/avatar/character-bodies/specifications.md
[6] https://polycount.com/discussion/comment/1553865
[7] https://polycount.com/discussion/comment/981812/
[8] https://create.roblox.com/docs/art/modeling/texture-specifications
[9] https://create.roblox.com/docs/performance-optimization/improve
[10] https://create.roblox.com/docs/art/modeling/surface-appearance
[11] https://devforum.roblox.com/t/on-hold-emissives/4034414
[12] https://create.roblox.com/docs/en-us/parts/materials.md
[13] https://create.roblox.com/docs/art/modeling/3d-importer
[14] https://create.roblox.com/docs/art/modeling/export-requirements
[15] https://create.roblox.com/docs/en-us/reference/engine/classes/BasePart.md
[16] https://create.roblox.com/docs/workspace/collisions
[17] https://devforum.roblox.com/t/issue-with-roblox-tool-physics/3973788
[18] https://devforum.roblox.com/t/sword-animation-with-motor6d/3365294
[19] https://devforum.roblox.com/t/weapon-animation-with-motor6d/2818896
[20] https://devforum.roblox.com/t/topic/359484/1
[21] https://create.roblox.com/docs/physics/constraints/rigid
[22] https://devforum.roblox.com/t/dual-wielding-swords/1878472
[23] https://create.roblox.com/docs/animation/inverse-kinematics
[24] https://devforum.roblox.com/t/sword-placed-on-hip/1377931
[25] https://devforum.roblox.com/t/sheath-tool-system/1788834
[26] https://deepwoken.fandom.com/wiki/Enchantments
[27] https://create.roblox.com/docs/en-us/physics/units.md
[28] https://progameguides.com/roblox/how-tall-is-a-roblox-character
[29] https://en.wikipedia.org/wiki/Arming_sword
[30] https://en.wikipedia.org/wiki/Rapier
[31] https://en.wikipedia.org/wiki/Zweih%C3%A4nder
[32] https://eldenring.wiki.gg/wiki/Greatsword
[33] https://eldenring.wiki.gg/wiki/Damage_Types
[34] https://eldenring.wiki.gg/wiki/Greataxes
[35] https://eldenring.wiki.gg/wiki/Thrusting_Swords
[36] https://80.lv/articles/weapon-art-tips-for-design-texturing-and-presentation
[37] https://swordartonline.fandom.com/wiki/Elucidator
[38] https://swordartonline.fandom.com/wiki/Dark_Repulser
[39] https://swordartonline.fandom.com/wiki/Lambent_Light
[40] https://stormthecastle.com/how-to-make-a/make-the-lambent-light.htm
[41] https://wowpedia.fandom.com/wiki/Quality
[42] https://enshrouded.featureupvote.com/suggestions/670918/comment/755617
[43] https://create.roblox.com/docs/effects/trails
[44] https://create.roblox.com/docs/en-us/reference/engine/classes/Trail.md
[45] https://devforum.roblox.com/t/i-need-help-with-making-trail/1555571
[46] https://create.roblox.com/docs/effects/beams
[47] https://devforum.roblox.com/t/particles’-flipbook-release/2029388
[48] https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md
[49] https://devforum.roblox.com/t/how-to-make-animated-slashes-20/1880010
[50] https://devforum.roblox.com/t/lights-camera-more-highlights/4061534
[51] https://devforum.roblox.com/t/how-could-i-bypass-this/1994624
[52] https://devforum.roblox.com/t/performance-considerations-improvements-and-optimizations-when-making-a-game/817499
[53] https://devforum.roblox.com/t/objectcache-a-modern-blazing-fast-model-and-part-cache/3104112
[54] https://create.roblox.com/docs/production/creator-store
[55] https://devforum.roblox.com/t/1kusd-or-r300k-looking-for-3d-melee-weapon-modeler/1219112
[56] https://devforum.roblox.com/t/open-3d-blender-modeler-portfolio-weapon-commissions-only-make-sure-to-have-good-references/1250012
[57] https://devforum.roblox.com/t/duckrealm-high-detail-3d-modeller-weapon-artist-open/1338109
[58] https://devforum.roblox.com/t/1000-3000r-per-effect-iron-seas-hiring-particleeffects-artists/851657
[59] https://fir3scomms.carrd.co/
[60] https://en.help.roblox.com/hc/en-us/articles/4404630280980-Parental-guidance-on-Talent-Hub
[61] https://techcrunch.com/2025/03/17/roblox-releases-its-open-source-model-that-can-create-3d-objects-using-ai/
[62] https://create.roblox.com/docs/en-us/reference/engine/classes/GenerationService.md
[63] https://swordartonline.fandom.com/wiki/Vorpal_Strike
[64] https://swordartonline.fandom.com/wiki/Linear
