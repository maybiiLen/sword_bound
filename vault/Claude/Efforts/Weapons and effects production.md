---
type: effort
status: round-1-done
created: 2026-10-08
author: claude
tags:
  - effort
  - weapons
  - vfx
  - design
---

Up: [[Weapon models and effects plan]] · Daily log: [[2026-10-08]]

Henry decided on 2026-10-08:
- The weapon sizes stay as they are. Swords are about 5 studs, which is anime scale.
- Claude builds every final mesh, effect and animation itself.

This note is the design for the first production round: the effects kit and weapon models for all 5 classes. It follows the same loop as [[Phase 0 shared combat systems]]: research, design, implement, test, review, ship.

## Research behind it

- [[Weapon art pipeline research (2026-10-08)]]: how weapon artists work, plus SAO design language and real proportions
- [[Mesh and texture pipeline for Claude (2026-10-08)]]: how Claude can get meshes and textures into the place, with probe results
- [[VFX artist workflow and cookbook (2026-10-08)]]: pro VFX principles, exact Roblox property values, plus 14 CC0 textures saved in Attachments
- [[Combat animator workflow research (2026-10-08)]]: the animation playbook for the next round
- The earlier [[Weapon models and effects plan]] and its three research notes

## Pipeline decision

Claude's options were checked by hand on 2026-10-08:

| Path | Works now? | Persists? | Notes |
|---|---|---|---|
| EditableMesh built in Studio by `execute_luau` | yes | no | Editables are never saved in places. Good for previews. |
| `AssetService:CreateAssetAsync` (mesh or image upload from Luau) | no, "not available yet" | yes | Needs the Studio beta "CreateAssetAsync Luau API". Henry was asked to enable it. |
| MCP `upload_image` | no | yes | Only trusts certain URLs. GitHub raw, local files and the VM's localhost all failed. |
| Open Cloud API key | not set up | yes | The cloud workspace cannot reach apis.roblox.com. |
| Parts, wedges and unions | yes | yes | Low-poly look only. |
| `generate_mesh` (Roblox AI) | yes | yes | Blobby on thin blades. Blockouts only. |

**Decision.** Weapons are generated in Luau by a new tool, **WeaponForge**, from data specs. This is the same idea as Animations.Specs plus AnimationBuilder: geometry is code, so it is versioned in git and any weapon can be regenerated.
- Without the beta, WeaponForge previews with EditableMesh.
- With the beta, it publishes each part as a mesh asset with CreateAssetAsync, so the models persist.
- Effects use Roblox's built-in rbxasset textures until uploads work, then switch to generated textures and the Kenney CC0 set through one texture table.

## Art direction

From the weapon art research:
- **SAO look.**
  - Clean planar blades with no wear.
  - One dominant color per weapon.
  - A thin contrasting edge line.
  - One gem or emblem on a sculptural guard.
  - Glow limited to the edge, the gem and the fuller.
- **Mid-poly method.** Use bevels and hard or smooth normals by angle instead of baked normal maps, which suits code-built meshes.
- **Materials.** Use one MeshPart per material region, colored with Roblox materials (Metal, SmoothPlastic, Leather or Fabric, Neon, Glass) rather than textures. The glow strip is its own part, so Sword Skills can recolor it at runtime. SurfaceAppearance PBR and emissive come later, once textures can upload.
- **Silhouettes** must read when filled black:
  - Dagger: short.
  - Rapier: thin line plus a ring guard.
  - Sword: winged guard.
  - Greatsword: as tall as a body, with a long grip and parrying lugs.
  - Axe: head mass at the end of a long haft.

### Class sheet

The scale anchor is a one-handed sword at about 5 studs. The other lengths follow the research proportions (judgment, see [[Weapon art pipeline research (2026-10-08)]]).

| Class | Total | Blade or head | Grip | Signature | Palette |
|---|---|---|---|---|---|
| One-handed sword | 5.0 | blade 3.7, 0.36 wide | 0.85 | asymmetric winged guard, gem | black #15161A, edge #9AA0A8, gem cyan |
| Dagger | 2.4 | 1.5 needle blade | 0.55 | twin rondel discs | gunmetal #3A3F47, crimson grip #7A1E2B, gold #C9A54A |
| Rapier | 5.4 | 4.3, 0.18 wide | 0.6 | swept rings plus knuckle bow | silver #E8ECF2, pale gold #D9C27A, red gem #D9465A |
| Two-handed sword | 7.0 | 5.2 incl. 1.0 ricasso | 1.4 | parrying lugs, wide guard | dark steel #4A4E57, black guard, ember fuller #FF7A2E |
| Two-handed axe | 6.5 | head 1.7 edge, bearded | haft 6.2 | crescent beard with horns | wood #6B4A2E, iron #5A5F66, edge #D7DDE4 |

## Effects kit design

Every effect runs on the client. The attacker predicts its own effects, and the server relays them to everyone else. This is how Effects already works.

**Hit payload.** The "Hit" EffectRemote payload gains the target model, damage type, a counter flag and the attack weight. The attacker computes the same values locally: the damage type from CombatRules.DamageTypeOf, and a counter from the target's CombatState attribute.

**Hit sparks by damage type.** Values follow the cookbook in [[VFX artist workflow and cookbook (2026-10-08)]]:
- Slash: a cool white flash plus VelocityParallel streaks along the swing.
- Strike: a warm star flare, chunky gravity sparks, dust and a ring.
- Pierce: a narrow, fast yellow-white cone along the thrust.

**Counter hit.** The hit layers recolored red (#FF3B2F), a 0.1 s white Highlight on the victim, and +0.04 s of hitstop.

**Hitstop.** Hitstop depends on the class and the weight. All hitstop runs on the clients, never on the server.

| Class | Light | Heavy |
|---|---|---|
| Dagger | 0.05 s | 0.08 s |
| Sword | 0.07 s | 0.12 s |
| Rapier | 0.06 s | 0.10 s |
| Greatsword | 0.10 s | 0.16 s |
| Axe | 0.11 s | 0.18 s |

These fall inside both agents' sourced ranges and are capped well under 0.2 s for normal hits.

**Trails per class.** Lifetime and width differ by class (dagger 0.08 s thin, rapier 0.06 s line, sword 0.12 s, axe 0.16 s, greatsword 0.22 s), with a white-to-glow color and a fade.

**Block, parry, perfect parry, riposte.** These keep their current behavior, rebuilt on the kit's layers so they share textures and pooling.

**Performance.**
- Emit counts scale with the graphics quality level, since Emit ignores Roblox's automatic reduction.
- Effect holders are pooled.
- One shared Highlight is used per victim.

## Scope

In:
1. An effects kit with:
   - damage-type sparks
   - counter flash
   - per-class hitstop and trails
   - the extended Hit payload
   - quality scaling and pooling
2. WeaponForge:
   - a mesh toolkit (loft, lathe, chamfered extrude, tube sweep, smoothing by angle)
   - specs for 5 class weapons
   - preview in Studio
   - publish with CreateAssetAsync when the beta is on
3. Vault images of every weapon, captured in Studio.

Out (next rounds):
- Weapon behaviors and definitions for the new classes. That is Phase 3, and only the models are built now.
- Sword Skill glow, which comes with Phase 2.
- Animation polish, which comes with Phase 1, using [[Combat animator workflow research (2026-10-08)]].
- SurfaceAppearance texturing, which needs uploads.

## Acceptance criteria

1. Each damage type shows a different spark on hit (Slash, Strike, Pierce), for the attacker and for other clients.
2. A counter hit shows the red counter flash and lasts longer than a normal hit.
3. Hitstop and trails differ per class and come from config.
4. Emit counts drop at a low graphics quality level, and no effect instances leak after 50 hits.
5. WeaponForge builds all 5 class weapons with:
   - the model convention (Handle PrimaryPart, Grip, SheathGrip, BladeBase, BladeTip, SwingTrail)
   - the parts welded
   - under 3,000 triangles each
   - each weapon reading correctly as its class in a black silhouette
6. With the beta on, published weapons survive a Studio restart.
7. No regressions in combat, and no console errors.

## Test plan

- Studio screenshots of every weapon (front, side, silhouette) and of each spark type, mid-effect, saved to Attachments.
- A client test with CombatTestInput: hit the dummy, the attacking knight, and a blocking target, and check the effect kinds that fire.
- Count leftover effect holders after 50 scripted hits.
- A reviewer agent reads the diff.

## Results, round 1 (2026-10-08)

Henry turned on the Studio beta "CreateAssetAsync Lua API". A test upload succeeded right away, so the publish pipeline is live.

### Weapons (WeaponForge)

![[round1_forge_showcase_studio.jpg]]

| Weapon | Tris | Regions | Notes |
|---|---|---|---|
| ForgeSword | 776 | Blade, Edge, Fuller, Guard, Trim, Grip, Gem | StarterSword now uses it |
| ForgeDagger | 580 | Blade, Edge, Trim, Grip, Gem | gem moved onto the pommel after review |
| ForgeRapier | 1,444 | Blade, Edge, Guard, Trim, Grip, Gem | knuckle bow, side rings, quillons |
| ForgeGreatsword | 1,380 | Blade, Edge, Fuller (neon ember), Guard, Trim, Grip, Gem | parrying lugs, side rings |
| ForgeGreataxe | 832 | Haft, Grip, Head, Edge, Trim | bearded head, bright edge band |

- Every region was published as a Mesh asset. The ids are stored on each model as `ForgeMeshIds`.
- The models sit in ReplicatedStorage.Combat.Assets.WeaponModels with the standard attachments.
- In play, the equipped ForgeSword sits correctly in the hand. The hitbox, trail, riposte and contextual attacks all work with it.

Offline renders from the generated geometry, checked before Studio was reachable again:
- ![[weaponforge_v1_sheet.jpg]]
- [[weaponforge_v1_sword.jpg]]
- [[weaponforge_v1_dagger.jpg]]
- [[weaponforge_v1_rapier.jpg]]
- [[weaponforge_v1_greatsword.jpg]]
- [[weaponforge_v1_greataxe.jpg]]

### Effects (Combat.VFX)

![[round1_vfx_damage_types.jpg]]

The four impacts, left to right:
1. Slash: blue crescent and streaks.
2. Strike: cross flare, ring and gravity sparks.
3. Pierce: spike along the thrust.
4. Slash counter hit: recolored red.

Streak fix, found in testing:
- With VelocityParallel, Roblox lays the texture's width along the velocity, so the streaks were drawn sideways.
- Fixed by rotating parallel particles 90 degrees.
- ![[round1_vfx_streaks_fixed.jpg]]

Textures:
- 7 textures were made in Luau by TextureForge and published: Glow, Streak, Flare, Ring, Slash, a 4x4 Smoke flipbook, and Trail.
- The ids are in Combat.VFXTextures.
- The prototypes were designed in Python first: [[textureforge_v1_prototypes.jpg]].

### Tests

- Unit tests: 14 of 14 pass.
- The dummy combo dealt 12 / 12.6 / 16.8, and the riposte dealt 45 = 12 x 2.5 x 1.5.
- A light into the knight's swing dealt 13.2 (a 1.1x counter). The red counter flash played and was cleaned up afterwards.
- Leak check after many hits:
  - The game's effect folder held 2 pooled holders, under the cap of 6 per recipe.
  - No sound attachments were left.
- No console errors.
- The repo matches the live place, 82 of 82 scripts. That includes two teammate files (Docs.Inventory, InventoryWeaponDisplay) that changed today.

### Review

A reviewer agent read the full diff. It found no crash bugs. Fixed:
1. Counter flashes left a Highlight on every model they touched. Each flash now gets a fresh Highlight that is removed after 0.15 s.
2. The server hit window used a fixed hitstop slack. It is now computed from the largest class hitstop plus the counter bonus, so greataxe multi-hits aren't rejected.
3. The class trail look only showed for the owner, and it overwrote TestSword's trail.
   - The look is now baked into Forge models at build time, and other clients style it on Swing.
   - Only models with ForgeClass are restyled.
4. Other clients saw the hit sparks pointing straight up.
   - The server now sends a direction.
   - The riposte's own spark uses the real damage type.
5. Spike Squash 4 was out of range (the limit is 3), and the streaks were sideways (the rotation fix above).
6. Hex colors are now cached per color instead of rebuilt on every hit.
7. Untagged faces no longer vanish in Merge.
8. Triangulation now warns instead of silently leaving holes.
9. The tube sweep no longer produces NaN on 90-degree bends.
10. Editables are destroyed after publishing.
11. "reuse" mode errors instead of silently falling back to an unsaved editable.
12. The dagger's gem was moved onto the pommel, and the dagger was republished.

### Next

- Animations (Phase 1). Polish the sword moveset in Specs using [[Combat animator workflow research (2026-10-08)]]: hips leading, overshoot, springs, held key poses. Add a contact sheet and tip-arc QA.
- Weapon behaviors and definitions for the new classes (Phase 3), now that their models exist.
- Sword Skill glow on the Edge and Fuller regions (Phase 2).
- SurfaceAppearance texturing with gradient maps and emissive masks, now that image upload works.
