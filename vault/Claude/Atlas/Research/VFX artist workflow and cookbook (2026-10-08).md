---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - vfx
  - roblox
---

Up: [[Claude]] · Used by: [[Weapons and effects production]]

Produced by a research agent on 2026-10-08 after Henry decided Claude builds all final meshes, effects and animations itself, and asked for end-to-end research into how artists and animators actually work. Reproduced as the agent returned it, with headings adjusted. Claims marked unsourced or judgment are the agent's own calls.

Citations are numbered as [n] and point to the Sources list. Anything marked "(unsourced, judgment)" is my own call and should be tuned by eye in Studio.

**Forum pass.**
- **Reddit was not reachable.** The proxy refused www.reddit.com and old.reddit.com, WebFetch returned SITE_BLOCKED, and site:reddit.com searches for r/robloxgamedev and r/vfx returned no Reddit results. Nothing here comes from Reddit.
- **realtimevfx.com and DevForum were reachable** and are used throughout.

**Images.**
- Wikimedia Commons, opengameart.org, kenney.nl, ambientcg and polyhaven were all blocked by the proxy.
- I saved 14 CC0 images plus the license file from Kenney's Particle Pack, using its GitHub mirror [49]. They are in /mnt/user-data/outputs/vault_images/vfx/ with MANIFEST.md.

## 1. How professional VFX artists design an effect

**Three beats.**
- VFX Apprentice calls them wind-up, climax and fall off. The wind-up "makes the viewer expect something", and the fall off reduces intensity gradually for "a pleasant outro" [1].
- Impulse effects skip the wind-up and "start with the action of high intensity" [1]. Impulse effects "come to life in a strong burst, and disappear the same way" [2].
- Hit sparks are impulses. Sword Skill pre-motion is a wind-up.

**Tempo.**
- Pacing faster than about 60 BPM reads as aggressive, so attacks should run faster than that and heals slower [1].
- The Diablo III VFX talk makes the same point: "a fast tempo in an effect helps it to feel aggressive" [8].

**Block-in first.**
- Pros solve timing with grey placeholder shapes before adding color, flipbooks or dissolves. Retiming alone can turn a friendly spell into a damaging one [7][1].
- For Claude this means building each effect in white and grey first and judging the timing before tinting (unsourced, judgment).

**Focus and value.**
- The primary element should carry the highest and lowest values, the highest saturation and the sharpest detail. Everything else is secondary: "If Everything is important, Nothing is important" [5].
- Riot's style guide says to use mid-range values and avoid 0 or 100 saturation [3][4].
- Keep one dominant color with a secondary color [3].
- Keep FX short. "FX aren't supposed to be telling the story" [3], and less time on screen means less clutter [6].

**Hit-spark specifics from realtimevfx feedback.**
- A white flash, then a black flash, then a ramp-down of the other elements gives depth [9].
- High-frequency noise and a high-contrast outer ring compete with the core. Narrow the ring's value range, for example orange and red only [9].
- A color ramp of white, yellow, orange, red gives depth [9].

**Layering.**
- Slash trails are "a collage of different noises layered onto each other with masks", plus particles to emphasize them [10].
- Diablo III style work layers one noise texture at UV scales 0.5, 1 and 2, and avoids octave sets like 0.8/1.0/1.2 because they cause phasing [11].
- Practical stack for Sword Bound: a hot white core, a tinted soft glow, directional sparks or streaks, then optional smoke or dust (unsourced, judgment, consistent with [5][9][10]).

**Motion.**
- Use arcs everywhere, including secondary elements.
- Stretch and smear frames add punch when paired with anticipation [2].
- Directional blur sells speed [3].

## 2. Roblox specifics with numbers

**ParticleEmitter facts**
- LightEmission 0 gives normal blending and 1 gives additive [15].
- With LightEmission above 0, darker colors look more transparent [15].
- LightInfluence 0 means particles ignore world light. It defaults to 1 when inserted in Studio and 0 when created with Instance.new [15].
- Brightness only applies when LightInfluence is 0 [15].
- Squash above 0 makes particles narrower and taller. Below 0 makes them wider and shorter [15].
- Orientation options are FacingCamera, FacingCameraWorldUp, VelocityParallel and VelocityPerpendicular [15].
- Drag is exponential speed decay. Negative values make particles accelerate [15].
- TimeScale 0 freezes particles, which is useful for hitstop [15].
- Emit() defaults to 16 particles [15].
- Lifetime is capped at 20 s [14].
- Higher ZOffset values render closer to the camera [15].

**Roblox's own recipes worth copying**
- **Spark burst** from the official explosion tutorial [22]:
  - Drag 10, Lifetime 0.2 to 0.6, Speed 20 to 40
  - SpreadAngle 180,180, Emit(100)
- **Ember streak** from the official volcano tutorial [23]:
  - Orientation VelocityParallel, Squash 0:-3, 0.323:-0.188, 1:-0.5
  - Size 0.313 shrinking to 0, Speed 5 to 8, Drag 0.8
  - Acceleration (0,10,0), LightEmission 1, LightInfluence 0, Brightness 20, ZOffset 1
- **Flat ground ring** from the same tutorial [23]:
  - Orientation VelocityPerpendicular with Speed 0.01
  - Brightness 15, ZOffset -2
- **Squash sign.** Check visually against the texture's orientation before trusting it (unsourced, judgment).

**VelocityParallel bug.** An open bug report from June 2026 says particles with high Drag vanish early under VelocityParallel or VelocityPerpendicular [35]. Keep spark lifetimes short so particles die before they stop moving (unsourced, judgment).

**Flipbooks**
- Textures must be square powers of two from 8x8 to 1024x1024 [24].
- Layouts are Grid2x2, Grid4x4, Grid8x8 or Custom [14].
- Leave padding between frames [14][24].
- FlipbookFramerate maxes at 30 [14].
- OneShot spreads the frames evenly over each particle's lifetime [14].
- FlipbookStartRandom with framerate 0 gives a random static frame per particle [14].
- Clients drop flipbooks when memory runs low [14].

**Beams**
- A Beam is a cubic Bezier. P1 sits CurveSize0 studs along Attachment0's +X axis, and P2 sits CurveSize1 studs along Attachment1's -X axis [16].
- Segments defaults to 10. You need at least n-1 segments for n color or transparency keypoints [16].
- Brightness defaults to 1 and ranges 0 to 10000 [16].
- TextureSpeed is in cycles per second, and negative values reverse it [16].
- Wrap and Static modes repeat the texture every TextureLength studs. Stretch repeats it TextureLength times [16].
- Width0 and Width1 are in studs [16].
- A DevForum reply claims beams lose curvature at low graphics settings [27]. Roblox also says beam quality changes with settings [50].

**Trails**
- Lifetime ranges 0.01 to 20 and defaults to 2 [17].
- Width equals the distance between the two attachments times WidthScale (0 to 1) [17].
- MaxLength 0 means unlimited [17].
- Stretch mode shrinks the texture inward when the attachments stop moving [17].

**Mesh slashes**
- A DevForum crescent uses a squashed sphere with a texture made with the GIMP Polar Coordinates filter. It puts two Texture objects on the mesh so the mesh itself can stay transparent [27].
- Texture objects tile using StudsPerTileU/V and OffsetStudsU/V [21]. Tweening OffsetStudsU scrolls the texture (unsourced, judgment).
- EditableMesh can build a crescent mesh in code. Published games require 13+ and ID verification plus the "Enable Mesh / Image APIs" toggle, and client memory budgets are strict [44].

**Highlight and post-processing**
- Only 255 Highlights display at once [18].
- Change Highlight properties instead of adding or removing Highlights, which causes geometry rebuilds [18].
- The first Highlight costs up to 1 ms of GPU on mobile [18].
- ColorCorrection Brightness ranges -1 to 1 [19].
- Bloom Threshold 1 blooms only pure white, and 0 blooms everything [20].

**ImpactFrame module [25]**
- White frame: Saturation -1, Contrast 25000. Black frame: Contrast -25000.
- Parts are recolored to Neon in the tint color, with decals hidden.
- Default duration is 0.1 s.
- The author says Highlights fail on mobile. Roblox's docs disagree and say only that low-end devices look more pixelated [18].
- A DevForum impact-frame guide uses 2 frames [26].

**Modules found**
- ImpactFrame module (open source) [25].
- Effect Designer Suite: free, open source, about 5,800 flipbooks and textures, emit count, delay and duration controls [45].
- VFX Forge: paid at $16.67+, includes mesh flipbooks and camera shake [46].
- EZ Camera Shake port [36].
- I found no "RUNUP", "VortexFX" or "ForgeFX" resources.

**Hitstop and shake**
- Capcom's example hitstop is 8, 12 and 16 frames for light, medium and heavy hits at 60 fps, which is 0.133, 0.2 and 0.267 s. Multi-hit moves get shorter hitstop [38].
- Sakurai's notes [39][40]:
  - More damage means longer hitstop, up to a cap.
  - Shake the victim side to side on the ground and up and down in the air, with amplitude decaying over the hitstop.
  - The attacker shakes slightly too.
  - Hurtboxes stay static.
- Hit animations should start from a zero cross-fade and play fast-in, slow-out [41].
- A damage flash of 2 to 3 frames is enough [42].
- To implement in Roblox, use AnimationTrack:AdjustSpeed(0) to pause [43] and ParticleEmitter.TimeScale 0 to freeze particles [15].
- EZ Camera Shake presets use the format CameraShakeInstance.new(magnitude, roughness, fadeIn, fadeOut) [36]:
  - Bump: (2.5, 4, 0.1, 0.75), position influence 0.15, rotation influence 1
  - Explosion: (5, 10, 0, 1.5), rotation influence (4,1,1)
- Trauma model [37]:
  - Shake strength = trauma squared.
  - Trauma decays 0.5 per second.
  - Max angle is 10 degrees, and each hit adds 0.4 trauma.

## 3. Texture authoring

**Texture types.** Trumpler's GDC 2022 talk lists diffuse, LUT, erosion and flow textures, made by painting, photobashing, procedural generation or simulation [12].

**Erosion math** [13]
- Hard edge: alpha = step(threshold, mask).
- Soft edge: smoothstep(t - feather, t + feather, mask). Sweep t from -feather to 1+feather so the shape fully appears and fully erodes.
- Store erosion maps as linear data, not sRGB.
- Roblox has no custom shaders, so bake the erosion into OneShot flipbook frames. Each frame thresholds the same noise mask at a rising t (unsourced, judgment, from [13][14]).

**Recipes in numpy (all unsourced, judgment)**
- **Glow dot:** (1 - r)^2.5 for r from 0 to 1.
- **Spark streak:** a Gaussian across x (sigma about 0.04) times a taper along y. Put the long axis on Y to match VelocityParallel.
- **Cross flare:** two thin Gaussians along the axes times radial falloff, plus a small dot.
- **Ring:** exp(-((r - 0.7) / 0.06)^2).
- **Crescent:** draw horizontal bands in (angle, radius) space, then map to polar coordinates as the GIMP method does [27]. Give it an angular gradient that is bright at the head and fades along the tail, multiplied by fBm noise. Use powers-of-two octaves [11].
- **Smoke sheet:** fBm times a soft dot, eroded over 16 frames into a 4x4 grid of 1024 px (256 px per frame).
- **Lightning:** a midpoint-displacement polyline drawn thin, then Gaussian blurred.

**Backgrounds and tint**
- Roblox recommends PNG with a transparent background. For grayscale art with no alpha, LightEmission 1 hides the dark areas [14].
- Store the shape in alpha with white RGB so one texture works in both blend modes (unsourced, judgment).
- Color tints the texture [15], so one white texture can serve every damage color. Reusing textures saves memory [31].

**Size**
- A 1024x1024 texture uses 4 times the memory of 512x512 [31].
- The decal uploader still downsizes images to 1024x1024 as of a June 2026 bug report [34].
- Use 128 to 256 px for sparks and dots and 512 px for slashes (unsourced, judgment).

## 4. Performance

- **Rate caps.** One emitter can emit at most 400 particles per second, or 100 per second on mobile [14].
- **Rate vs Emit.** Rate is scaled down automatically by graphics quality. Emit() ignores quality [29][30].
  - Scale Emit counts yourself with UserSettings().GameSettings.SavedQualityLevel.Value. Quality runs 1 to 10, and Automatic is 0, which doesn't tell you the real level [29].
  - Under Automatic, use 0.6 times the full count (unsourced, judgment).
- **Fill rate.** Large particles cost more GPU [14].
- **Draw calls.** Particles, decals and textures don't batch, and changing ParticleEmitter properties can hurt performance "dramatically" [31].
- **Overdraw.** Layered transparency is expensive [31].
- **Client side.** Run VFX on clients and replicate with FireAllClients [29].
- **Pooling.** Pool and reuse instances [29]. Pre-build emitters per weapon at equip and only call Emit and Clear [15] (unsourced, judgment).
- **Beam vs mesh.** I found no measured Beam-vs-mesh numbers. My guess is that a Beam with 10 to 20 segments and a crescent MeshPart with 2 Textures are both cheap, and cost is dominated by screen coverage (unsourced, judgment).

## 5. Built-in textures usable without upload

**How they load.** rbxasset:// paths read from the Roblox content folder on the player's device [32].

**Verified files.** These exist in the current client manifest [33]. I downloaded and inspected them for this report only; they are Roblox property and were not saved.

| Path (prefix rbxasset://textures/) | Content | Size |
|---|---|---|
| particles/explosion01_implosion_main.dds | soft glow dot | 256 |
| particles/explosion01_shockwave_main.dds | soft ring | 256 |
| particles/sparkles_main.dds | 8-point star | 128 |
| glow.png | radial starburst flare | 256 |
| sparkle.png | small 4-point star | 32 |
| smallWhiteCircle.png | hard white disc | 64 |
| gradient.png | horizontal soft band, useful for beam or trail strips | 512 |
| particles/smoke_main.dds | smoke puff | 128 |
| particles/explosion01_core_main.dds | fiery puff | 256 |
| particles/fire_sparks_main.dds | tiny spark specks | 64 |
| particles/SquareParticle.png | white square | 256 |

Roblox can change these files at any time, so keep uploaded fallbacks (unsourced, judgment).

## VFX cookbook for Sword Bound

These apply to every entry unless it says otherwise (unsourced, judgment, built on [14][15][22][23]):
- Emitters use LightEmission 1, LightInfluence 0 and Brightness 3.
- Emitters are parented to an Attachment at the hit point, oriented so +Y points along the hit normal.
- Size and Transparency are written as time:value keypoints.
- Every color, timing and count below is unsourced, judgment unless it cites a source.

**Damage-type palette (unsourced, judgment; follows the dominant-plus-secondary rule [3])**
- **Slash:** core #F2FAFF, glow #7FD4FF
- **Strike:** core #FFF0D6, glow #FF9A3C, dust #8A7A66
- **Pierce:** core #FFFFE6, glow #FFD84A
- **Counter:** #FF3B2F
- **Block:** #FFC873
- **Parry:** #FFE38A
- **Perfect parry:** #FFFFFF with ring #6EF3FF
- **Posture break:** #FF6A00
- **Riposte:** #E0103A

**1. Swing trails (one Trail per weapon)**
- Attachment0 sits 25% up the blade and Attachment1 at the tip, so trail width is about 75% of the blade [17].
- Shared settings:
  - FaceCamera false, TextureMode Stretch, Texture gradient.png or a generated strip
  - Transparency 0:0.15, 0.3:0.5, 1:1
  - WidthScale 0:1, 1:0.2, MinLength 0.05
  - Enabled only during active frames
- Lifetime per class:
  - Dagger 0.08 s
  - Rapier 0.06 s, with WidthScale 0:0.5
  - Sword 0.12 s
  - Axe 0.16 s
  - Greatsword 0.22 s
- Color is the damage-type glow color running to the core color at the leading edge.
- Greatsword and axe also spawn a crescent at the hit point:
  - A Beam arc with Width0 3, Width1 3, Segments 20, CurveSize0 = CurveSize1 = 0.55 x radius (Bezier quarter circle)
  - TextureSpeed 2 and Transparency fading out over 0.18 s
  - Or use the EditableMesh crescent [44]

**2. Hit sparks (impulse: 0 s flash, about 0.05 s peak, fade by 0.3 s)**
- **Slash (Slash damage):** horizontal sparks along the swing tangent, cool white.
  - A. Flash: soft dot, Emit 1, Lifetime 0.1, Size 0:0.5, 0.3:3, 1:3.5, Transparency 0:0, 1:1, ZOffset 1.
  - B. Streaks: VelocityParallel, Emit 10, Speed 25 to 45, Drag 8, Lifetime 0.15 to 0.3, SpreadAngle 40,10, Size 0:0.25, 1:0. Squash as in the ember recipe [23].
  - C. Thin crescent sprite: Emit 1, Lifetime 0.12, Rotation matched to the swing.
- **Strike (Strike damage):** star flare, wide cone and dust, warm colors.
  - A. glow.png flare: Emit 1, Lifetime 0.12, Size 0:1, 0.2:5, 1:5.5.
  - B. Chunky sparks: Emit 8, Speed 15 to 30, Drag 6, Acceleration (0,-40,0), Lifetime 0.25 to 0.4, SpreadAngle 70,70.
  - C. Dust: smoke_main, LightEmission 0, LightInfluence 1, Emit 3, Speed 4 to 8, Lifetime 0.4 to 0.6, Transparency 0:0.6, 1:1.
  - D. Ring: Size 1 to 6 over 0.2 s.
- **Pierce (Pierce damage):** narrow and fast, yellow-white.
  - A. Flash: Lifetime 0.07, Size to 2.
  - B. Streaks: Emit 6, Speed 40 to 60, Drag 10, Lifetime 0.1 to 0.2, SpreadAngle 12,12, aimed along the thrust direction and out the back of the target.
  - C. Short Beam line: Width0 0.3, Width1 0, 0.08 s.
- **Normal hits:** hitstop 0.05 to 0.07 s for light hits and 0.1 s for heavy hits. That is shorter than Capcom's example [38] for online play.
- **Camera shake on normal hits:** Bump at magnitude 0.6 to 1.2 [36].

**3. Counter-hit flash**
- Use the normal hit layers recolored to #FF3B2F.
- Add a Highlight on the victim with FillColor #FFFFFF, FillTransparency 0 rising to 1 over 0.1 s, OutlineTransparency 1 [18][42].
- Extra hitstop of +0.04 s.
- Shake the victim 0.15 studs side to side, decaying [39].

**4. Block spark (Block)**
- Orange-white metal sparks from the contact point. Emit 12, Speed 20 to 35, Acceleration (0,-50,0), Lifetime 0.2 to 0.35.
- Small flash Size 1.5.
- No Highlight.
- Shake Bump at magnitude 0.4.

**5. Parry and perfect parry**
- **Parry (Parry):**
  - #FFE38A flash Size 4, Lifetime 0.1.
  - Sparks Emit 16 in a 60 degree cone.
  - shockwave_main ring Size 0:1, 1:7 over 0.25 s.
  - Hitstop 0.1 s.
- **Perfect parry (Perfect parry):** everything in Parry, plus:
  - A white flash with sparkles_main star: Emit 1, Size 0:2, 0.15:8, 1:9, Lifetime 0.18.
  - A second ring in #6EF3FF, flat on the ground with VelocityPerpendicular and Speed 0.01 [23], Size 2 to 12 over 0.35 s.
  - A 2-frame white impact frame: Saturation -1, Contrast 25000, about 0.033 s per frame [25][26].
  - Hitstop 0.15 s and shake Bump at full strength [36].

**6. Stagger and posture break (Posture break)**
- Amber Highlight pulse, 0.15 s.
- Upward shards: VelocityParallel, Emit 14, Speed 15 to 25, Acceleration (0,-60,0), Lifetime 0.4.
- Ground ring.
- Victim shake that decays over the 0.12 s hitstop [39][40].
- Stagger loop: dim star particles circling the head at Rate 6, Lifetime 0.6 (Rate scales with quality [29]).

**7. Riposte finisher (Riposte)**
- Wind-up: 0.2 s of crimson glow on the blade [1].
- Impact: a 2-frame impact frame, first black (Contrast -25000) then white (Contrast 25000) [25][26][9].
- Big crimson crescent plus Strike layers at 1.5 times scale.
- Hitstop 0.25 s, about Capcom's 16-frame heavy example [38], with AdjustSpeed(0) and TimeScale 0 [43][15].
- Explosion-preset shake at magnitude 2 [36].
- Fall off: 0.5 s of drifting embers [23].

**8. Impact frames generally**
- Only for perfect parry, posture break and riposte.
- Use one shared ColorCorrectionEffect and one shared Highlight per character and toggle their properties [18].

**9. Sword Skill glow (SAO style)**
- In SAO, recognizing the pre-motion "lights up the weapon in the Skill hue" [47], and a post-motion delay leaves the user open [48]. Light colors vary by source [51].
- Per-class hues: dagger #3DFF9A, sword #4FA8FF, rapier #B7F3FF, greatsword #FF8A2B, axe #FF3D3D.
- **Pre-motion (wind-up, 0.25 to 0.4 s):**
  - Weapon Highlight with FillTransparency 0.6 and OutlineTransparency 0.2, pulsing at 0.15 s.
  - LockedToPart blade motes at Rate 30, Lifetime 0.3, Size 0.2 [15].
  - A PointLight with Range 8, because LightEmission does not light the world [15].
- **Active:** the trail switches to the hue with Lifetime x2. Each hit adds a Beam arc and a hit-spark set in the hue.
- **Post-motion delay:** tween the Highlight and motes to #7A7A7A while transparency rises to 1 across the delay. Turn the PointLight off and disable the trail.

## Saved reference textures (CC0, Kenney Particle Pack)

All are CC0 1.0, so they may also be used in the game. Source: github.com/Calinou/kenney-particle-pack (mirror of kenney.nl/assets/particle-pack). License: [[kenney_particle_pack_LICENSE.txt]].

![[kenney_circle_05.png|160]] ![[kenney_flare_01.png|160]] ![[kenney_light_01.png|160]] ![[kenney_magic_02.png|160]] ![[kenney_muzzle_02.png|160]] ![[kenney_particle_pack_preview.png|160]] ![[kenney_particle_pack_sample.png|160]] ![[kenney_scratch_01.png|160]] ![[kenney_slash_01.png|160]] ![[kenney_smoke_01.png|160]] ![[kenney_spark_01.png|160]] ![[kenney_star_04.png|160]] ![[kenney_trace_01.png|160]] ![[kenney_twirl_01.png|160]] 

### Manifest

All files below come from Kenney's Particle Pack 1.1 by Kenney Vleugels (Kenney.nl), licensed CC0 1.0 Universal (public domain dedication, http://creativecommons.org/publicdomain/zero/1.0/). Attribution is optional. Retrieved 2026-10-08 from the CC0 mirror repo github.com/Calinou/kenney-particle-pack (master branch, folder addons/kenney_particle_pack/). Original pack page: https://kenney.nl/assets/particle-pack (OpenGameArt listing: https://opengameart.org/content/particle-pack-80-sprites). The full license text is saved as kenney_particle_pack_LICENSE.txt.

Format note: each texture is 512x512 PNG (palette mode with a transparency channel). The shape lives in the alpha channel over light gray/white color, so they work with Roblox LightEmission 0 or 1 and tint through the Color property.

| File | What it shows | Source URL | Author | License |
|---|---|---|---|---|
| kenney_particle_pack_preview.png | Pack preview sheet showing all sprite types | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/preview.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_particle_pack_sample.png | Sample render of the sprites in use | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/sample.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_spark_01.png | Jagged lightning/electric spark streak | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/spark_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_slash_01.png | Thin crescent slash arc, bright center tapering to points | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/slash_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_circle_05.png | Soft glow dot (round falloff) | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/circle_05.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_flare_01.png | Small hot core with thin horizontal anamorphic streak | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/flare_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_star_04.png | Four-point cross/star flare | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/star_04.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_smoke_01.png | Billowy smoke puff | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/smoke_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_trace_01.png | Thin vertical streak (spark/tracer for VelocityParallel particles) | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/trace_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_twirl_01.png | Swirl arc, thick bright head fading along a curved tail | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/twirl_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_light_01.png | Soft concentric glow rings (halo/ring flash) | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/light_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_magic_02.png | Circle of small rings (magic circle / sigil) | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/magic_02.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_scratch_01.png | Three parallel diagonal claw/scratch streaks | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/scratch_01.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_muzzle_02.png | Flame-shaped burst (muzzle flash) | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/addons/kenney_particle_pack/muzzle_02.png | Kenney (Kenney.nl) | CC0 1.0 |
| kenney_particle_pack_LICENSE.txt | License text (not an image) | https://raw.githubusercontent.com/Calinou/kenney-particle-pack/master/LICENSE.txt | Kenney (Kenney.nl) | CC0 1.0 |

Not saved (blocked or not openly licensed): Wikimedia Commons, opengameart.org, kenney.nl, ambientcg.com and polyhaven.com were all refused by the network proxy, so no Commons images were saved. DevForum images and game screenshots were intentionally not saved; they are linked in the report instead. Roblox built-in rbxasset textures were inspected only for description and were not copied here because they are Roblox property, not openly licensed.

## Sources
[1] https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx
[2] https://www.vfxapprentice.com/courses/fx-timing-principles
[3] https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips
[4] https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/
[5] https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-1-creating-areas-of-focus/11614
[6] https://www.vfxapprentice.com/blog/five-artistic-principles-gaming-vfx
[7] https://realtimevfx.com/t/block-ins-and-timing/29830
[8] https://realtimevfx.com/t/useful-free-gdc-talks/219 (Diablo III talk https://www.gdcvault.com/play/1017660/Technical-Artist-Bootcamp-The-VFX ; Blizzard/Riot bootcamp https://youtu.be/-L2JvngkkWw)
[9] https://realtimevfx.com/t/stylised-explosive-and-fiery-hit-spark-looking-for-feedback/11286
[10] https://realtimevfx.com/t/sword-slash-help/9407
[11] https://jangafx.com/insights/diablo-3-vfx-experiments
[12] https://www.gdcvault.com/play/1027741/contactUs
[13] https://vfxdoc.readthedocs.io/en/latest/shaders/alpha-erosion/
[14] https://create.roblox.com/docs/effects/particle-emitters
[15] https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter (full text via https://github.com/Roblox/creator-docs)
[16] https://create.roblox.com/docs/reference/engine/classes/Beam
[17] https://create.roblox.com/docs/reference/engine/classes/Trail
[18] https://create.roblox.com/docs/effects/highlighting and https://create.roblox.com/docs/reference/engine/classes/Highlight
[19] https://create.roblox.com/docs/reference/engine/classes/ColorCorrectionEffect
[20] https://create.roblox.com/docs/reference/engine/classes/BloomEffect
[21] https://create.roblox.com/docs/reference/engine/classes/Texture
[22] https://create.roblox.com/docs/tutorials/use-case-tutorials/vfx/use-particles-for-explosions
[23] https://create.roblox.com/docs/tutorials/use-case-tutorials/vfx/create-volcanoes
[24] https://devforum.roblox.com/t/particles’-flipbook-release/2029388
[25] https://devforum.roblox.com/t/open-source-impactframe-module/2963136
[26] https://devforum.roblox.com/t/advanced-impact-frames/2468478
[27] https://devforum.roblox.com/t/crecent-sword-slash-effect/1113871
[28] https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650
[29] https://devforum.roblox.com/t/performance-considerations-improvements-and-optimizations-when-making-a-game/817499
[30] https://devforum.roblox.com/t/custom-particles-emitting-system/968599
[31] https://create.roblox.com/docs/performance-optimization/improve
[32] https://create.roblox.com/docs/projects/assets
[33] https://github.com/MaximumADHD/Roblox-Client-Tracker (rbxManifest.txt and textures/)
[34] https://devforum.roblox.com/t/decal-uploads-are-still-limited-to-1024x1024/4710639
[35] https://devforum.roblox.com/t/particle-emitters-with-high-drag-disappear-earlier-than-normal-if-the-orientation-is-velocityparallel-or-velocityperpendicular/4646615
[36] https://github.com/Sleitnick/RbxCameraShaker (src/CameraShaker/CameraShakePresets.lua)
[37] https://github.com/bevyengine/bevy/blob/main/examples/camera/2d_screen_shake.rs
[38] https://game.capcom.com/cfn/sfv/column/131545
[39] https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/
[40] https://nintendowire.com/news/2022/12/12/this-week-in-sakurai-12-5-12-11-fine-tuning-hit-stop-and-cheating-the-system/
[41] https://www.gamedeveloper.com/programming/the-role-of-animations-in-hit-effects
[42] https://gamedev.net/shaderlab/36-hit-flash-and-damage-tint/
[43] https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
[44] https://create.roblox.com/docs/reference/engine/classes/EditableMesh
[45] https://devforum.roblox.com/t/effect-designer-suite-%E2%80%94-vfx-tooling-assets-and-more/4754553
[46] https://zilibobi.itch.io/vfx-forge
[47] https://otakumode.com/otapedia/anime/sword_art_online/sword_skills_sao
[48] https://swordartonline.fandom.com/wiki/Starburst_Stream
[49] https://github.com/Calinou/kenney-particle-pack (CC0)
[50] https://create.roblox.com/docs/effects/beams
[51] https://swordartonline.fandom.com/wiki/Sonic_Leap
[52] https://devforum.roblox.com/t/how-do-i-make-a-spark-effect/909188

## Files
- /mnt/user-data/outputs/vault_images/vfx/MANIFEST.md
- 14 CC0 Kenney images, prefixed kenney_ (spark, slash, glow dot, flare, star, smoke, streak, twirl, rings, magic circle, scratch, muzzle, plus pack preview and sample)
- kenney_particle_pack_LICENSE.txt

All in /mnt/user-data/outputs/vault_images/vfx/.

## Worth remembering
In this environment the proxy blocks Reddit, Wikimedia Commons, opengameart, kenney.nl, ambientcg and polyhaven. raw.githubusercontent.com works, including the Roblox/creator-docs mirror for full API text.
