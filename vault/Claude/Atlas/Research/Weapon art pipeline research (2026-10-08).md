---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - weapons
  - 3d-art
---

Up: [[Claude]] · Used by: [[Weapons and effects production]]

Produced by a research agent on 2026-10-08 after Henry decided Claude builds all final meshes, effects and animations itself, and asked for end-to-end research into how artists and animators actually work. Reproduced as the agent returned it, with headings adjusted. Claims marked unsourced or judgment are the agent's own calls.

**Images could not be downloaded.** The container's egress proxy blocked these hosts with HTTP 403 (organization policy): upload.wikimedia.org, commons.wikimedia.org, en.wikipedia.org (direct), images.metmuseum.org, collectionapi.metmuseum.org and openaccess-cdn.clevelandart.org. The proxy README says to report a block like this and not route around it, so I did not use the user's device or any mirror to fetch files. I wrote /mnt/user-data/outputs/vault_images/weapons/MANIFEST.md instead. It lists 13 references I checked by hand, covering all 5 classes plus a CC BY-SA sword parts diagram. Each entry has a suggested file name, the source page, the owner, the license and its real measurements. Most are Met and Cleveland Museum Open Access items (Public Domain). Someone on a machine that can reach those hosts can download them in a few minutes.

**Forum pass.** Reddit was not reachable. WebFetch returned SITE_BLOCKED, and a WebSearch limited to reddit.com was rejected by the proxy (HTTP 400). The Roblox DevForum was reachable and is used below. Polycount forum threads were reachable. The Polycount wiki was partly reachable: Texture_Baking loaded, while Face_weighted_normals and Texel_density were refused.


## 1. How professional weapon artists work

**Concept and silhouette.** Artists sketch many loose silhouette thumbnails and compare them before refining one. On Polycount, reviewers told an artist to sketch several silhouettes, and the group picked #4 as the most readable and swingable [P1]. Function drives shape: a curved grip should bend away from the edge, and the blade's width-to-length ratio decides whether it reads as a sword or a dagger [P1].

**Blockout, then model.** The usual pipeline runs blockout, then a high poly (often sculpted in ZBrush), then a game-ready low poly, then UVs, then a bake and texturing in Substance Painter, then presentation in Marmoset [80a]. Stylized hand-painted pieces often skip the high poly entirely. One gothic sword started from an 8 or 16 sided cylinder, kept "the edges that catch strong light," and used no normal map or high poly [80b]. Polycount advice for hand-painted swords is to avoid subdivision, define shape with bevels, keep the mesh as low as possible and put depth in the texture [P2].

**Mid-poly alternative.** Some teams skip the high-to-low bake. They use bevels with extra loops plus face-weighted normals for clean shading, and bake only support masks (edges, thickness, dirt) [80c]. Because 90 degree hard edges no longer need splitting, UV shells can be larger with less padding [80c]. This route suits an AI because there is no bake step.

**Baking (when used).** A cage, an inflated copy of the low poly, controls the ray distance. Split vertex normals can make rays miss the high poly. Triangulating before the bake keeps normals stable, and edge padding prevents seams on UV borders [PW1].

**Polycount.** One stylized hand-painted crystal sword targeted 3K tris [80d]. On the DevForum, a 944-tri Roblox sword was called too heavy, and a reviewer estimated the blade alone could drop under 300, or even 200, tris [DF1]. A low-poly axe handle with only 6 sides still read as round once it had smooth shading plus an Edge Split at about 30 to 50 degrees [DF2].

**UVs and texel density.** Texel density means texture pixels per unit of surface. About 512 px/m is typical for background props and about 1024 px/m for hero assets, and weapons are named as close-inspection items that need higher density [TD1]. Artists mirror symmetric parts to double their UV space [80b][80e] and keep density consistent across a set [80e]. One artist cites 2 to 4 seams per mesh as a rule of thumb [80d].

**Grip, guard, pommel.** A grip is wood or metal, often covered in leather or shagreen and wrapped in a helix of wire [W1]. The pommel is an enlarged end fitting that stops slipping and counterbalances the blade [W1]. A fuller is a lengthwise groove that lightens and stiffens the blade [W2]. Its length varies by type, from about 2/3 of the blade (Oakeshott XIIa) to about 1/4 (XVII) [W3]. Cross-sections are lenticular, diamond or hexagonal, depending on type [W3].

**Texturing, PBR style.** Substance's Metal Edge Wear generator masks the edges most likely to be knocked or scratched. It needs baked position, curvature, AO and world-space normal maps [AD1]. In a curvature map, white is convex (edges), black is concave (cavities) and gray is flat [AD2]. The standard stack is a base metal fill, then edge wear from curvature, then cavity dirt from AO and concave curvature, then a value gradient.

**Texturing, stylized or hand-painted.** Polycount critiques say the same things again and again:
- Push lights and darks further than feels natural [P3].
- Paint light blue highlights on the edge so the blade reads sharp [P3].
- Make shadows cooler [P3].
- Metal diffuse is very dark and the specular carries the color, so keep large metal areas dark and save bright, saturated color for edge highlights [P4].
- A scratch gets a highlight on one side and a shadow on the other [P4].

Common recipes include a light-to-dark gradient running top to bottom [80d], Linear Dodge edge highlights [80d], and a darker base tone with slightly blue highlights on top edges and red or pink on lower edges [80b].

**Anime and toon metal.** NPR shaders fake metal with a matcap or a custom specular highlight [80f]. One Genshin-style shader samples a gradient texture driven by the normal and view direction [AS1]. In practice that means hard-edged bands of light and dark instead of physically based reflections.

## 2. Anime / SAO design language

**What the sources say about SAO swords:**
- **Elucidator.** Pitch black, with gray trim outlining the blade. Its hand guard "drops down on the right side" [S1]. The licensed figure describes it as black chrome with silver trim and a guard with two wing-like extensions [S2].
- **Dark Repulser.** In the light novel it is pale, slightly transparent, white and slender. In the anime it is aqua. The crossguard sits exactly perpendicular and looks like two joined dagger blades, with a large aquamarine gem at the center [S3]. The blade is arrowhead-shaped and changes width along its length, and the guard reads as two diamonds [S2]. MyAnimeList describes a deep aqua blade with "an almost mystical glow" [S4].
- **Night Sky Sword.** Pitch black wood, about 120 cm [S5]. The blade slims to a rounded point and the guard is simple and flares outward [S2].
- **Blue Rose Sword.** A rose at the center of the guard, criss-cross hilt details and a long pointed blade [S2].
- **Lambent Light.** Described as a slim, exceptional thrusting weapon [S4]. I found no sourced color description. It is commonly shown as white and silver with gold accents (unsourced, judgment).

**Proportions from licensed replicas:**

| Weapon | Overall | Blade | Grip | Blade share | Source |
|---|---|---|---|---|---|
| Elucidator | 109 cm | 81 cm | 28 cm | 74% | [S6] |
| Dark Repulser | 109 cm | 81 cm | 28 cm | 74% | [S7] |
| Lambent Light | 107 cm | 71 cm | 36 cm | 66% | [S8] |

Real swords run about 82 to 90% blade. Anime hilts are long and chunky, so they read clearly at a distance.

**Takeaways for an SAO look:**
- Clean planar blades with no wear.
- One dominant color per weapon (black, aqua, white or blue).
- A contrasting thin edge line.
- A single center gem or emblem on a sculptural guard.
- Asymmetric or winged guards on hero weapons.
- A glow kept to the edge or the gem.

All of these are synthesized from the descriptions above (judgment).

**Genshin, HSR and Tower of Fantasy.** Sourcing here is thin. Genshin weapons change design on ascension; Mistsplitter's blade darkens and its handle turns black [G1], and Kagura's Verity "glows" at max ascension [G2]. Gradient-mapped metal, emissive inlays and floating detached parts are common in all three games, but I found no published breakdown to cite (unsourced, judgment).

**Top Roblox games.** Deepwoken sorts its weapons into Light (daggers, rapiers), Medium (swords) and Heavy (greataxes, greatswords) [R1], which maps well onto your five classes. I could not find a sourced breakdown of the texture approach for Deepwoken, Swordburst 3, Arcane Odyssey or Type Soul. From general observation they use low-to-mid poly meshes, flat or lightly gradient colors and few textures, with Neon or particles for glow (unsourced, judgment; worth verifying in-game).

**Copyrighted visual references (links only, nothing saved):**
- https://swordartonline.fandom.com/wiki/Dark_Repulser
- https://swordartonline.fandom.com/wiki/Elucidator
- https://swordartonline.fandom.com/wiki/Night_Sky_Sword
- https://otakumode.com/otapedia/figures_and_merch/merchandise/sword_art_online_swords
- https://adrianmendez.artstation.com/projects/wJZ4Gg
- The 80.lv articles cited below.

## 3. Real-world anatomy per class

**Arming sword.**
- Blade usually 69 to 81 cm. Cruciform guard. Pommels range from brazil-nut and disk to wheel and fishtail [W4].
- Met arming sword (Castillon group): 92.1 cm overall, 75.9 cm blade, 19.1 cm quillons [M1].

**Longsword / hand-and-a-half.**
- 100 to 140 cm overall, 80 to 110 cm blade, 15 to 30 cm grip [W3].
- Met example: 124.8 cm overall, 97.8 cm blade [M2].

**Zweihander.**
- Up to 213 cm overall, with at least 25 cm of hilt. Parrying hooks sit at the top of the ricasso [W5].
- Cleveland example: 170.5 cm overall, 125.6 cm blade, 53.7 cm quillons, 43.2 cm grip, 34.7 cm ricasso [C1].
- A ricasso is the unsharpened length of blade just above the guard [W6].

**Rapier.**
- Blade 104 cm or more and 2.5 cm wide or less. Swept hilt (Italian) or cup hilt (Spanish, early 1600s) [W7].
- Cleveland cup hilt: 123.2 cm overall, 100.9 cm blade, 25.2 cm quillons, 11.8 cm grip [C2].
- Met examples: 124.8 cm with a 113.3 cm blade [M3], and 127 cm with a 112.2 cm blade [M4].

**Daggers.**
- Rondel: blade 30 cm or more with a needle point and a diamond, lenticular or triangular section. Round or octagonal disc guard and a round pommel [W8]. Later examples had two discs, one at each end of the grip [MA1].
- Main gauche: very long straight quillons, about 28 cm tip to tip, and a triangular knuckleguard [W9].
- Met parrying dagger: 40.3 cm overall, 27.9 cm blade, blade 2.7 cm wide [M5].

**Axes.**
- Dane axe: haft 0.9 to 1.2 m (up to 1.7 m), cutting edge 20 to 30 cm, body as thin as 2 mm, with pronounced horns at toe and heel [W10].
- The bearded axe's lower "beard" extends the edge while keeping mass low [W11].
- Met Scandinavian axe head: 18.7 x 19.1 cm [M6].

## 4. Materials on Roblox

**SurfaceAppearance.**
- Supports color, normal, roughness, metalness and emissive maps [RB1].
- Color tint multiplies the ColorMap, so a near-white grayscale map gives the strongest tint [RB1]. One texture set can serve many recolors, which is good for rarity variants (judgment).
- Normal maps must be OpenGL tangent space, and the mesh must include tangents [RB2][RB3].

**Emissive masks.**
- Studio beta started Oct 30, 2025, and went live in published experiences Feb 12, 2026 [RB4].
- The formula is Final = (Mask x EmissiveStrength x EmissiveTint + light) x ColorMap [RB4]. Glowing areas therefore need a bright ColorMap underneath.
- Only the red channel of the mask is used [RB4].
- EmissiveMaskContent can only be set at edit time or through CreateSurfaceAppearance [RB4].
- Marketplace items must keep EmissiveStrength between 0 and 40 [RB1].

**MaterialVariant.** For reusable, tileable materials, with a Studs Per Tile setting. SurfaceAppearance is UV-specific per mesh [RB5].

**Neon and Bloom.** Neon is the all-or-nothing glow that emissive masks improve on [RB4]. BloomEffect's Threshold decides which colors bloom, and at 1 only pure white blooms [RB6].

**Texture sizes.** UV texture maps go up to 1024x1024. As rough guidance, use 256 px for about a 5x5 stud object [RB7].

**Meshes.**
- A mesh can have at most 20,000 tris [RB8].
- EditableMesh allows 60k vertices and 20k tris. Different normals at a shared vertex create a hard edge, and different UVs create a seam. CreateMeshPartAsync turns the result into a MeshPart [RB9].
- EditableMesh fails by default in published games unless an ID-verified creator enables it [RB9].

**DevForum view.** For SurfaceAppearance versus MeshPart textures, the consensus is case by case. SurfaceAppearance is used for gloss and PBR realism, and plain textures are a reasonable default [DF3].

## How Claude should build weapons

1. **Write the silhouette as data.** Define the blade, guard and pommel as 2D profile polylines in studs. Render a front-view thumbnail of 3 to 5 variants per weapon, pick the most readable one, and check it at 64 px tall [P1] (judgment for the 64 px check).
2. **Build the blade as a loft.** Sweep a cross-section along the length with 6 to 10 stations, tapering both width and thickness.
   - Use a lenticular section (6 verts) or a diamond section (4 verts) [W3].
   - Edge thickness about 0.01 studs, spine 0.06 to 0.08 studs at a 5 stud length.
   - Add an extra station where the tip begins, at 85 to 90% of blade length (judgment).
3. **Fuller.** Inset the flat faces and push them in 0.015 to 0.02 studs. Width about 25 to 30% of blade width, over 1/2 to 2/3 of the blade [W3]. Close it to a point before the tip to avoid the bad shading Polycount users hit there [P2] (judgment for the numbers).
4. **Guard and pommel.** Extrude the 2D profiles 0.12 to 0.2 studs deep. Chamfer every visible edge with a 0.015 to 0.03 stud bevel in 1 segment.
   - Use hard normals (separate normal IDs per face, as SetFaceNormals allows [RB9]) on angles over 30 to 40 degrees, and smooth normals elsewhere [DF2][80c].
   - In Blender, use Bevel plus Weighted Normal modifiers (mid-poly approach [80c]).
5. **Grip.** Use a 6 to 8 sided cylinder. Model leather wrap bands as 5 to 8 slightly bulged rings, or a helix of 1.5 to 2 turns, offset 0.01 studs. Add a ferrule ring at each end [W1] (judgment for the counts).
6. **Gem.** Use a 6 to 8 sided bipyramid or a cabochon about 0.15 to 0.25 studs across, centered on the guard [S3].
7. **Tri budgets** (anchored by [DF1], otherwise judgment):

   | Part | Tris |
   |---|---|
   | Blade | 100 to 300 |
   | Guard | 100 to 400 |
   | Grip | 60 to 200 |
   | Pommel | 40 to 150 |
   | Gem | 16 to 48 |
   | Total, one-hand sword | 600 to 1,200 |
   | Total, rapier with swept rings | up to 2,500 |

8. **UVs.** Mirror the blade halves and stack identical parts [80b]. Aim for about 100 px/stud on a single 512x512 atlas per weapon. That is roughly twice Roblox's 256-px-per-5-studs guidance [RB7], to allow for close inspection [TD1] (judgment).
9. **Texture recipe** (stylized, generated in code with EditableImage or Python/PIL):
   - Base: a vertical value gradient, lighter toward the tip [80d].
   - Edge band: a thin 2 to 4 px bright line along the edges, slightly blue-shifted [P3].
   - Cavities: darken from AO or concave curvature [AD2].
   - Wear: almost none, for the SAO look [S1][S2].
   - Hand-painted value rules: dark metal bodies with bright edges [P4].
10. **Materials.**
    - Option A is the easiest. Use plain MeshParts with Color plus Material Metal or SmoothPlastic, and a separate thin Neon edge strip for glow.
    - Option B is the best quality. Use SurfaceAppearance with a near-white ColorMap tinted by Color, roughness 0.3 to 0.5, metalness 1 on metal and 0 on leather, and an emissive mask on the edge line and gem at EmissiveStrength 2 to 8 [RB1][RB4] (judgment for the values).
11. **Pipeline.** The most reliable path is a Blender Python script that writes FBX, then importing it into Studio, which avoids EditableMesh's published-game restrictions [RB9]. EditableMesh plus CreateMeshPartAsync works for prototyping in Studio through MCP. Check whether the meshes persist when saved before relying on them (unsourced).

## Per-class design sheet

Scale: the one-hand sword is 5.0 studs, about 4.6 studs per real meter based on the 109 cm Elucidator replica [S6]. All stud numbers are judgment derived from the cited real ratios.

**One-handed sword (Elucidator / Anneal Blade line)**
- **Parts:** blade, fuller, crossguard, gem, wrapped grip, pommel.
- **Proportions:**
  - Blade 3.7 studs (74% [S6]), 0.36 wide at the base, tip taper over the last 0.5 studs.
  - Guard 1.2 to 1.4 wide (real 21% of length [M1], enlarged).
  - Grip 0.85, pommel 0.3.
- **Signature:** an asymmetric winged or dropping guard [S1][S2].
- **Palette:** black #15161A with gray edge #9AA0A8, or aqua #3FD0C9 with an aquamarine gem #7FFFE0 and silver-blue grip #B8C6D6 [S3].

**Dagger (rondel / main gauche hybrid)**
- **Parts:** needle blade with a diamond section, long straight quillons or a disc guard, faceted grip, round pommel.
- **Proportions:** 2.2 studs total. Blade 1.4 (60 to 69% [M5][MA1]), 0.2 wide. Quillons 0.7 wide (31% [M5]). Grip 0.5.
- **Signature:** twin rondel discs, or a side shell guard [MA1][W9].
- **Palette:** gunmetal #3A3F47, crimson grip #7A1E2B, gold disc trim #C9A54A.

**Rapier (Lambent Light line)**
- **Parts:** long narrow blade, ricasso, swept rings or a cup, knuckle bow, long quillons, slim grip, pommel.
- **Proportions:**
  - 5.5 studs total. Blade 4.3 (about 80% [C2]), 0.16 to 0.2 wide (real 2.5 cm or less [W7], widened for readability).
  - Ricasso 0.25. Quillons 1.1 (20% [C2]). Grip 0.55 [C2].
- **Signature:** 2 to 3 swept rings made from 6-sided tube sweeps, or a single cup [W7].
- **Palette:** white-silver #E8ECF2, pale gold #D9C27A, soft red gem #D9465A (unsourced, judgment).

**Two-handed sword / greatsword (Zweihander line)**
- **Parts:** wide blade, long ricasso with parrying lugs, very wide guard with side rings, long grip with a center bulge, heavy pommel.
- **Proportions:** 7.0 studs total. Blade 5.2 (74% [C1]) including a 1.0 ricasso (20% [C1]), 0.55 to 0.65 wide. Guard 2.0 (31% [C1]). Grip 1.4 (25% [C1]). Pommel 0.35.
- **Signature:** parrying hooks at the top of the ricasso [W5].
- **Palette:** dark steel #4A4E57, blackened guard #1E1F24, emissive ember or blue inlay along the fuller #FF7A2E or #4FA8FF.

**Two-handed axe (Dane / bearded line)**
- **Parts:** haft, socket or eye, thin bearded head with horns, edge band, butt cap, grip wraps on the lower third.
- **Proportions:** 6.5 studs total.
  - Haft 6.2, 0.16 thick (real 0.9 to 1.2 m+ [W10]).
  - Head edge 1.6 to 1.8 (real 20 to 30 cm [W10], enlarged for readability). Head depth 1.2. Beard drops 0.5 below the eye [W11].
  - Head thickness 0.2 at the eye, tapering to 0.03 at the edge band, continuous with no mid fade [DF2].
- **Signature:** a deep crescent beard with sharp horns [W10][W11].
- **Palette:** wood #6B4A2E, iron head #5A5F66, bright edge band #D7DDE4, optional rune emissive #8FE3FF.

## Sources

[P1] https://polycount.com/discussion/comment/1390649
[P2] https://polycount.com/discussion/comment/2565479
[P3] https://polycount.com/discussion/comment/1507026
[P4] https://polycount.com/discussion/comment/1652891
[PW1] http://wiki.polycount.com/wiki/Texture_Baking
[80a] https://80.lv/articles/tutorial-weapon-creation-for-video-games/
[80b] https://80.lv/articles/learn-to-make-hand-painted-gothic-sword-in-blender/
[80c] https://80.lv/articles/creating-assets-within-the-mid-poly-workflow-in-ue5/
[80d] https://80.lv/articles/how-to-make-magical-hand-painted-crystal-sword-in-3d
[80e] https://80.lv/articles/creating-a-stylized-sword-in-blender
[80f] https://80.lv/articles/toon-shader-tutorial-metallic-material-in-blender
[AS1] https://adrianmendez.artstation.com/projects/wJZ4Gg
[TD1] https://rebusfarm.net/blog/texel-density-basics-every-artist-should-know
[AD1] https://experienceleague.adobe.com/en/docs/substance-3d-painter/using/effects/generators/metal-edge-wear
[AD2] https://experienceleague.adobe.com/en/docs/substance-3d/bakers/bakers-settings/curvature
[DF1] https://devforum.roblox.com/t/3d-feedback-on-first-sword/435818
[DF2] https://devforum.roblox.com/t/feedback-low-poly-sword-and-axe/474763
[DF3] https://devforum.roblox.com/t/surfaceappearence-x-mesh-texture-which-one-is-better/2662853
Also read on the DevForum: https://devforum.roblox.com/t/low-poly-cartoony-sword/1483813
[S1] https://swordartonline.fandom.com/wiki/Elucidator
[S2] https://otakumode.com/otapedia/figures_and_merch/merchandise/sword_art_online_swords
[S3] https://swordartonline.fandom.com/wiki/Dark_Repulser
[S4] https://myanimelist.net/featured/650
[S5] https://swordartonline.fandom.com/wiki/Night_Sky_Sword
[S6] https://www.halloweencostumes.com/sword-art-online-kirito-elucidator-sword.html
[S7] https://halloweencostumes.com.au/sword-art-online-kirito-s-dark-repulser-sword.html
[S8] https://www.halloweencostumes.com/sword-art-online-asuna-rapier-sword.html
[G1] https://www.sportskeeda.com/esports/mistsplitter-reforged-genshin-impact
[G2] https://sportskeeda.com/esports/genshin-impact-2-5-leaks-yae-miko-s-idle-animation-changed-kagura-s-verity-gets-ascension-effects
[R1] https://deepwoken.fandom.com/wiki/Weapons
[W1] https://en.wikipedia.org/wiki/Hilt
[W2] https://en.wikipedia.org/wiki/Fuller_(weapon)
[W3] https://en.wikipedia.org/wiki/Longsword
[W4] https://en.wikipedia.org/wiki/Arming_sword
[W5] https://en.wikipedia.org/wiki/Zweih%C3%A4nder
[W6] https://en.wikipedia.org/wiki/Ricasso
[W7] https://en.wikipedia.org/wiki/Rapier
[W8] https://en.wikipedia.org/wiki/Rondel_dagger
[W9] https://en.wikipedia.org/wiki/Main-gauche
[W10] https://en.wikipedia.org/wiki/Dane_axe
[W11] https://en.wikipedia.org/wiki/Bearded_axe
[MA1] https://myarmoury.com/feature_spot_rondel.php
[M1] https://www.metmuseum.org/art/collection/search/35626
[M2] https://metmuseum.org/art/collection/search/27966
[M3] https://www.metmuseum.org/art/collection/search/27404
[M4] https://www.metmuseum.org/art/collection/search/22370
[M5] https://www.metmuseum.org/art/collection/search/27579
[M6] https://www.metmuseum.org/art/collection/search/810926
[C1] https://www.clevelandart.org/art/1919.70
[C2] https://www.clevelandart.org/art/1916.706
[RB1] https://create.roblox.com/docs/art/modeling/surface-appearance
[RB2] https://create.roblox.com/docs/art/modeling/texture-specifications
[RB3] https://create.roblox.com/docs/en-us/reference/engine/classes/SurfaceAppearance.md
[RB4] https://devforum.roblox.com/t/on-hold-emissives/4034414
[RB5] https://create.roblox.com/docs/parts/materials
[RB6] https://create.roblox.com/docs/en-us/reference/engine/classes/BloomEffect.md
[RB7] https://create.roblox.com/docs/art/modeling/texture-specifications
[RB8] https://create.roblox.com/docs/art/modeling/specifications
[RB9] https://create.roblox.com/docs/en-us/reference/engine/classes/EditableMesh.md
Also: https://create.roblox.com/docs/en-us/reference/engine/classes/AssetService (CreateSurfaceAppearanceAsync, CreateMeshPartAsync signatures)

Files:
- /mnt/user-data/outputs/vault_images/weapons/MANIFEST.md (download list with verified licenses; no image files saved because of the proxy block)

## Reference image list (not downloaded)

The proxy blocked the museum and Wikimedia hosts, so these are links with verified licenses. If Henry allows those domains, Claude can save the files into Attachments.

### Weapon reference images (Sword Bound)

Status as of 2026-10-08: NO IMAGE FILES WERE DOWNLOADED.

Why: the research container's egress proxy returned HTTP 403 (organization policy denial) for upload.wikimedia.org, commons.wikimedia.org, en.wikipedia.org (direct curl), images.metmuseum.org, collectionapi.metmuseum.org and openaccess-cdn.clevelandart.org. The proxy rules say not to retry or route around a policy block, so nothing was fetched. The list below is a verified, ready-to-download set: every entry was checked on its source page for a public domain / open access or CC license. Download them from a machine that can reach these hosts and save them under the suggested file names.

How to download each one:
- Met Museum: open the page, click "Download Image" (Public Domain, Met Open Access, free for commercial and noncommercial use).
- Cleveland Museum of Art: open the page, use the download button (Public Domain under the CMA Open Access Initiative).
- Wikimedia Commons: use the direct thumbnail URL given.

| Suggested file name | What it shows | Source page | Author / owner | License | Key measurements (from source) |
|---|---|---|---|---|---|
| anatomy_sword_parts_numbered.png | Numbered diagram of sword and scabbard parts (pommel, grip, cross-guard, fuller, edge, point) | https://commons.wikimedia.org/wiki/File:Sword_parts_numbered.svg (verified via mirror https://c.enwp.org/wiki/File:Sword_parts_numbered.svg). Thumbnail: https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Sword_parts_numbered.svg/1280px-Sword_parts_numbered.svg.png | Wikimedia user Medium69, derived from File:Sword_parts-en.svg | CC BY-SA 3.0 / GFDL 1.2+ (attribution and share-alike required) | n/a |
| onehand_arming_sword_british_ca1500_met27516.jpg | Single-hand sword, British, possibly ca. 1500 | https://www.metmuseum.org/art/collection/search/27516 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 116.2 cm, blade 86.5 cm, W 21.6 cm, 1190.7 g |
| longsword_hand_and_half_ca1400_met27966.jpg | Hand-and-a-half sword, probably German, ca. 1400-1430 | https://metmuseum.org/art/collection/search/27966 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 124.8 cm, blade 97.8 cm, 1560 g |
| greatsword_two_handed_german_cma1919-70.jpg | Two-handed sword (Zweihander type), Germany 1550-1600, with ricasso and parrying lugs | https://www.clevelandart.org/art/1919.70 | Cleveland Museum of Art | Public Domain (CMA Open Access) | L 170.5 cm, blade 125.6 cm, quillons 53.7 cm, grip 43.2 cm, ricasso 34.7 cm, 3.28 kg |
| rapier_cup_hilt_spanish_met27404.jpg | Cup-hilted rapier, Spanish, mid 17th c. | https://www.metmuseum.org/art/collection/search/27404 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 124.8 cm, blade 113.3 cm, 1077.3 g |
| rapier_cup_hilt_cma1916-706.jpg | Cup-hilted rapier, c. 1610-30 | https://www.clevelandart.org/art/1916.706 | Cleveland Museum of Art | Public Domain (CMA Open Access) | L 123.2 cm, blade 100.9 cm, quillons 25.2 cm, grip 11.8 cm, 1.2 kg |
| rapier_german_ca1600_met22370.jpg | Rapier, German (possibly Saxony), ca. 1600 | https://www.metmuseum.org/art/collection/search/22370 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 127 cm, blade 112.2 cm, 1162 g |
| rapier_french_hilt_ca1580_met662372.jpg | Rapier, French hilt ca. 1580 (complex swept-style hilt) | https://www.metmuseum.org/art/collection/search/662372 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 111.1 cm, blade 71.1 cm, hilt W 17.1 cm |
| dagger_parrying_italian_met27579.jpg | Parrying dagger (main gauche family), Italian ca. 1550-75 | https://www.metmuseum.org/art/collection/search/27579 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 40.3 cm, blade 27.9 cm, W 12.7 cm, blade W 2.7 cm |
| dagger_french_late15c_met32684.jpg | Dagger, French, late 15th c. | https://www.metmuseum.org/art/collection/search/32684 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 34.5 cm, W 4.5 cm |
| axe_head_scandinavian_11-12c_met810926.jpg | Ax head, Scandinavian, 11th-12th c. (Viking-era broad/bearded axe head) | https://www.metmuseum.org/art/collection/search/810926 | The Metropolitan Museum of Art | Public Domain (Met Open Access) | L 18.7 cm, W 19.1 cm, 520 g |
| axe_battle_italian_late1500s_cma1916-1599.jpg | Battle axe, Italy, late 16th c., copper rosette inlay | https://clevelandart.org/art/1916.1599 | Cleveland Museum of Art | Public Domain (CMA Open Access) | head 27.3 cm, blade 8.3 cm, 420 g |
| axe_battle_sind_c1800_cma1916-726.jpg | Battle axe, Sind (India) c. 1800, wide sweeping engraved blade (stylized silhouette reference) | https://www.clevelandart.org/art/1916.726 | Cleveland Museum of Art | Public Domain (CMA Open Access) | L 61.6 cm, blade 18 cm |

Checked but NOT usable (no image or no license stated):
- Met 35626 Arming Sword, Castillon group (on loan, no image): https://www.metmuseum.org/art/collection/search/35626 . Measurements still useful: L 92.08 cm, blade 75.88 cm, quillons 19.05 cm, 1293 g.
- Met 27350 and 27347 Two-Handed Swords (no image).
- Met 810939 Medieval Sword (image not downloadable, on loan).
- Detroit Institute of Arts 53.211 Swept-hilt Rapier (no license stated): https://dia.org/collection/swept-hilt-rapier-25444
- Worcester Art Museum Rondel Dagger 55157 (no license stated): https://worcester.emuseum.com/objects/55157/rondel-dagger

Gaps to fill when downloading: a swept-hilt rapier with a clear PD image, a rondel dagger with a clear PD image, and a complete hafted Dane axe. Search the Met and Cleveland collections with the "Open Access" / "Public Domain" filter on.

Copyrighted references (link only, do not save): see the main research report (SAO wiki pages, ArtStation, 80.lv, DevForum).
