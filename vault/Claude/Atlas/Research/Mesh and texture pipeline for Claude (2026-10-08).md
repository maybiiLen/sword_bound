---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - pipeline
  - roblox
---

Up: [[Claude]] · Used by: [[Weapons and effects production]]

Produced by a research agent on 2026-10-08 after Henry decided Claude builds all final meshes, effects and animations itself, and asked for end-to-end research into how artists and animators actually work. Reproduced as the agent returned it, with headings adjusted. Claims marked unsourced or judgment are the agent's own calls.

## Forum pass status

Forum and Reddit pass: Reddit could not be reached. WebFetch on reddit.com returned "SITE_BLOCKED", and WebSearch limited to reddit.com was rejected by the proxy. The forum pass therefore covers DevForum only (announcement threads, help threads, and replies). The container's own curl also cannot reach create.roblox.com or apis.roblox.com, because the egress proxy returns 403 on CONNECT. Everything below was read with WebFetch, plus one local Blender test.

## 1. EditableMesh and EditableImage

API
- Creation uses AssetService:CreateEditableMesh(options?) and CreateEditableImage(options?). The default image is 512x512, and a Size option changes it. CreateEditableMeshAsync(content, {FixedSize}) and CreateEditableImageAsync load existing assets. Each one returns nil once the editable memory budget is used up. [AssetService.md]
- Mesh building methods are AddVertex(p), AddTriangle(v0,v1,v2), AddNormal(n?), AddUV(uv), SetFaceNormals(faceId, ids) and SetFaceUVs(faceId, ids). Giving a shared vertex different normal IDs makes a hard edge, and different UV IDs makes a seam. [EditableMesh.md]
- To display a mesh, call AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh), {CollisionFidelity=...}), or call MeshPart:ApplyMesh() on an existing part. [EditableMesh.md, AssetService.md]
- An EditableImage works in any image Content property, such as ImageLabel.ImageContent or MeshPart.TextureContent, set to Content.fromObject(img). WritePixelsBuffer takes an RGBA buffer of Size.X*Size.Y*4 bytes. [EditableImage.md]

Limits
- Meshes cap at 60,000 vertices and 20,000 triangles. [EditableMesh.md]
- Images cap at 1024x1024 and cannot be resized. [EditableImage.md]
- Memory budgets are strict on clients only. The docs say "server, Studio, and plugins" have unlimited memory. [EditableMesh.md, EditableImage.md]
- To use these APIs in a published experience, the owner must be 13+ age verified and ID verified, then turn on "Enable Mesh / Image APIs" in the Creator Dashboard. [EditableMesh.md]

Persistence (the key question)
- An EditableMesh or EditableImage made in edit mode does NOT persist. Staff wrote that they "are never saved in places, packages, or model files," even when Archivable is true, and that they do not replicate. [DevForum 2725284]
- A MeshPart built from Content.fromObject(editableMesh) therefore has nothing to save its geometry from. My judgment is that it comes back empty or broken after a save and reopen (unsourced, judgment). A 2026 thread confirms that clients see a checkerboard box because an EditableMesh does not replicate. [DevForum 4566101]
- AssetService:CreateDataModelContentAsync, a Studio beta from March 2026 that reached live games in May 2026, also does not help here. It bakes editables into content "scoped to the lifetime of the current data model session" that is "not persisted in the cloud." [DevForum 4541898]
- Conclusion: the mesh has to be uploaded as an asset.

Publishing from Luau
- AssetService:CreateAssetAsync(object, assetType, params) supports Model, Plugin, Mesh (from an EditableMesh root) and Image (from an EditableImage root). [AssetService.md]
- CreateAssetVersionAsync updates an existing asset. The beta post says updates only work for Model and Plugin. [DevForum 3294134]
- Docs: "Currently, this method can only be used in locally loaded plugins and uploads assets without prompting first." In plugin context it defaults to the logged-in Studio user as creator. You can pass CreatorId and CreatorType for a group. It returns (Enum.CreateAssetResult, assetId). [AssetService.md]
- The beta post says to turn on the Studio beta feature "CreateAssetAsync Luau API" and then call it from a local plugin or the command bar. [DevForum 3294134]
- A March 2025 reply answered the error "CreateAssetAsync ... not available yet" with "Have you enabled the beta feature?" [DevForum 3294134 page 3]
- I found no post saying it left beta.
- Other context rules [DevForum 3294134]:
  - It does not work in published games.
  - It does not work from plugins installed from the Creator Store.
  - Open Cloud Luau Execution tasks can call it, but must pass CreatorId and CreatorType.
  - Uploads are moderated the same way as normal Studio uploads.
- No ID verification is documented for CreateAssetAsync itself. The 13+/ID rule applies to the in-experience Mesh/Image API toggle. [AssetService.md, EditableMesh.md]
- Whether the Studio MCP execute_luau counts as "locally loaded plugin" context is undocumented. The MCP docs only say it "Runs Luau code in Studio." [studio/mcp.md] Claude should test it directly (unsourced, judgment).

Turning an asset ID into a saved MeshPart
- MeshPart.MeshId and MeshContent are write-locked ("NotAccessibleSecurity"), so use AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://ID")). [MeshPart.md]
- TextureID and TextureContent are writable at security None. [MeshPart.md]
- A MeshPart that points at an rbxassetid saves normally (standard behavior, unsourced, judgment).

## 2. Open Cloud Assets API

- Endpoint: POST https://apis.roblox.com/assets/v1/assets, as multipart with a "request" JSON part (assetType, displayName, creator.userId or groupId) and a "fileContent" part. It returns operations/{id}. Poll GET /assets/v1/operations/{id} until done=true, then read moderationResult.moderationState. [cloud/guides/usage-assets, cloud/reference/features/assets.md]
- Supported uploads [usage-assets]:
  - Model: .fbx, .gltf, .glb, .rbxm, .rbxmx. This "Imports custom 3D models as a Model container containing one or more MeshPart objects," stored as packages.
  - Decal/Image: .png, .jpeg, .bmp, .tga, under 8000x8000.
  - Mesh: not uploadable directly ("Only content downloaded from Asset delivery API is accepted").
  - .obj is not listed for Model.
- Files go up to 20 MB. [usage-assets]
- Permissions: OAuth scopes are asset:read and asset:write. An API key needs the Assets permission with Read and Write. [usage-assets, assets.md]
- Ownership: use a user ID, or a group ID for a group-owned asset. [usage-assets]
- Rate limits: create is 120/min per key owner, and polling is 300/min. [assets.md]
- Moderation delay is not quantified in the docs. In practice the operation can report done before moderation finishes (unsourced, judgment).
- Blocker: this container cannot reach apis.roblox.com (verified, proxy 403). Calls would have to run from Henry's machine via device_bash, if its allowlist permits it, or from Studio HttpService. Whether HttpService may call apis.roblox.com from edit mode is unverified (unsourced, judgment).

## 3. Options that persist with no upload

- GeometryService:UnionAsync, SubtractAsync and IntersectAsync accept Parts, PartOperations and MeshParts. Results have no Parent until you set one, and inputs with MeshParts give MeshPart results. [GeometryService.md]
- Results are simplified to 20,000 triangles, or the call errors. Inputs must be watertight. Mesh CSG needs the "Solid Modeling On Meshes" beta. UsePartColor makes the whole result one color. [parts/solid-modeling.md]
- Neither page says whether script-made unions save in edit mode. Studio unions do save, and plugin-made ones should too (unsourced, judgment). Claude should save, close and reopen to confirm.
- Quality: DevForum users say Roblox CSG "is horrid at optimising how many triangles are generated," and recommend Hull or Box collision and subtracting instead of adding parts. [DevForum 2638232]
- Triangle cost for a small weapon: a box is 12 triangles and a wedge is about 8. A 15-part sword built from parts and wedges stays well under 300 triangles (unsourced, judgment).
- Look: parts and wedges give a clean low-poly or "Roblox classic" style, with Material Metal or Foil and a Neon edge strip. They cannot give a smooth double bevel, a fuller groove, or curved quillons without unions (unsourced, judgment).
- SpecialMesh offers only built-in shapes (Brick, Wedge, Cylinder, Sphere and similar) unless it uses a MeshId, so it adds little here (unsourced, judgment).

## 4. Headless Blender in this container (tested)

- The container runs Python 3.11.15. PyPI lists bpy 5.2.2 as latest, which requires Python ==3.13.* and ships a manylinux_2_28 x86_64 wheel. [pypi.org/project/bpy]
- pip on Python 3.11 still finds bpy 5.0.1 and 4.5.x. I ran `pip install bpy==4.5.14` in a venv, and `import bpy` reports "4.5.14 LTS". apt offers Blender 4.0.2 as an alternative.
- Test script: /tmp/claude-0/-home-claude/6fff6184-d394-5467-8fdb-42c0ecfd8ce7/scratchpad/sword_test.py, with outputs in .../scratchpad/out/. It does the following:
  - Builds a tapered diamond-section blade with bmesh, from rings plus a tip.
  - Applies a Bevel modifier.
  - Runs bpy.ops.uv.smart_project.
  - Writes a gradient straight into image pixels, with no Cycles bake needed.
  - Exports FBX, GLB and OBJ.
  - The result is 92 triangles.
- Mirror, Solidify and Subdivision modifiers apply the same way through modifiers.new plus modifier_apply. Baking real AO or curvature would need Cycles on CPU, which is slow but works headless (unsourced, judgment).
- Roblox's documented Blender FBX settings are Path Mode = Copy with Embed Textures, Apply Scalings = "FBX Unit Scale", Add Leaf Bones off, and Bake Animation off. [art/modeling/export-requirements.md]
- Mesh rules [art/modeling/specifications.md]:
  - At most 20,000 triangles per mesh.
  - Watertight.
  - Not zero thickness.
  - Quads where possible.
- Textures [texture-specifications.md]:
  - The page cites both 4096 and 1024 as maximum sizes.
  - Normal maps must be OpenGL tangent space.
  - Formats are png, jpg, tga and bmp.
  - Roblox may downsample textures.
- Getting the file into Studio: the Studio 3D Importer is the normal path, and Claude cannot click it. The workable route is to move the vertex, UV and triangle arrays out as Luau literals or JSON, rebuild them as an EditableMesh through execute_luau, then CreateAssetAsync(Mesh) (unsourced, judgment).

5. Roblox AI generation (generate_mesh, Cube 3D)

- generate_mesh in the Studio MCP "Generates a textured 3D mesh from a text prompt using AI." [studio/mcp.md]
- The March 2026 Assistant update uses GenerateModelAsync with an optional max triangle count that defaults to 10,000. It recommends "100s to 1K" for simple objects. A selected part's size and position act as a bounding box. [DevForum 4527258]
- GenerateModelAsync has only two schemas, Car5 and Body1 (a single MeshPart). [parts/model-generation.md]
- The June 2026 segmented-model preview says "results depend on the mesh's topology." [DevForum 4678458]
- Controllability is limited to the prompt, a bounding box, and a triangle cap. There is no control over blade profile, edge thickness or proportions beyond that. [DevForum 4527258, model-generation.md]
- Thin blades: no source covers them. From experience with similar models, expect thick, blobby or warped blades and lumpy edges. The mesh rules also forbid zero-thickness geometry (unsourced, judgment).
- Users in the announcement thread call output "a template/temporary solution, useful for rapid testing and prototyping." [DevForum 4527258]
- Persistence: the runtime LoadGeneratedMeshAsync returns "a Model with a single MeshPart containing an EditableMesh," so that path does not persist. [GenerationService.md]
- A 2025 Assistant thread implies the Studio flow publishes the mesh when it is inserted ("Publishing and inserting the mesh"). [DevForum 3585893]
- No doc confirms what the MCP generate_mesh leaves behind. Claude should run inspect_instance on the result and check that MeshId starts with rbxassetid:// before trusting it (unsourced, judgment).
- Licensing and ownership of generated output: not addressed in the docs. The generative-AI page only covers moderation of inputs and outputs. [generative-AI.md]

## 6. Textures (slashes, flipbooks, gradient ramps)

- EditableImage to Image asset: build the image in Luau (WritePixelsBuffer), then CreateAssetAsync(img, Enum.AssetType.Image), under the same plugin or command-bar rules. Size caps at 1024x1024. [AssetService.md, EditableImage.md]
- Staff suggested calling the API twice if a Decal is also needed. [DevForum 3294134]
- An EditableImage on its own never persists. [DevForum 2725284]
- The MCP upload_image "Uploads a batch of images from HTTP URLs to the Roblox asset server" and returns asset IDs. Ownership is not documented. [studio/mcp.md]
  - The container has no public URL. A private claude.ai artifact URL probably cannot be fetched by Roblox (unsourced, judgment).
  - The image would need to sit at a public URL, for example a public GitHub raw URL (unsourced, judgment).
- Open Cloud Image/Decal upload takes png/jpeg/bmp/tga under 8000x8000 and is moderated. [usage-assets]
- Flipbooks: ParticleEmitter.FlipbookLayout supports Grid2x2, Grid4x4, Grid8x8 and Custom. "The flipbook texture size must be an exact multiple of the flipbook layout size." [ParticleEmitter.md] A 1024 sheet at 8x8 gives 128 px frames.

## Recommended pipeline for Claude (ranked)

### Rank 1. Blender in the container, rebuilt as an EditableMesh in Studio, then CreateAssetAsync
- What Henry needs to do:
  - Turn on the Studio beta "CreateAssetAsync Luau API" (File > Beta Features) if the call errors as "not available".
  - Be the creator. Uploads go to his user account, or pass the group's CreatorId and CreatorType.
  - Nothing else: no key and no clicks.
- Steps:
  1. pip install bpy==4.5.14, which is tested here.
  2. Script each weapon in bmesh: profile rings, a fuller cut via Boolean, guard, grip and pommel. Then mirror, bevel, triangulate, smart_project UVs, and paint gradient or edge-wear pixels. Keep under 5k triangles.
  3. Dump positions, UVs, normals and triangle indices, plus the texture as raw RGBA, to Luau literals. Chunk large payloads across several execute_luau calls into a buffer held in _G or a ModuleScript (unsourced, judgment, since the payload limit is undocumented).
  4. In execute_luau, build the EditableMesh and EditableImage, then call CreateAssetAsync for each (Mesh, then Image).
  5. Call CreateMeshPartAsync(Content.fromUri("rbxassetid://"..meshId)), set TextureContent to the image asset, and parent it.
  6. Save, reopen and inspect to confirm it persisted.
  7. Run the same flow for slash, ramp and flipbook images.
- Risk: execute_luau might not count as plugin context. If so, fall back to Rank 2.

### Rank 2. Open Cloud key
- What Henry needs to do:
  - Create an API key at create.roblox.com > Open Cloud with Assets Read and Write for his user or group.
  - Allow apis.roblox.com on the Cowork device allowlist, or run the uploads himself.
- Steps:
  1. Export FBX or GLB as Model and PNG as Image.
  2. POST to /assets/v1/assets from device_bash.
  3. Poll the operation and wait for MODERATION_STATE_APPROVED.
  4. Use insert_asset with the model ID, which arrives as a package of MeshParts.
  5. Set Image IDs on Beams and ParticleEmitters.
- Alternative: a key with Luau Execution permission lets cloud Luau call CreateAssetAsync with CreatorId set.

### Rank 3. upload_image for textures only
- What Henry needs to do: provide a public host, such as a public GitHub repo, for the PNGs.
- Steps: Claude pushes the PNGs, calls upload_image with the raw URLs, and gets asset IDs.

### Rank 4. Parts plus GeometryService unions in edit mode
- What Henry needs: nothing.
- Steps: build blade, guard and grip from wedges and blocks, SubtractAsync the fuller, and UnionAsync per component with UsePartColor off. Save and reopen to verify. Good for a stylized low-poly look and acceptable as final art only in that style.

### Rank 5. generate_mesh
- What Henry needs: nothing.
- Use it only for blockout or bulky items such as an axe head, with a bounding-box part and a cap of 1,500 to 3,000 triangles. Verify MeshId is an rbxassetid. Avoid it for rapier and dagger blades (unsourced, judgment).

## Claude's own probe results (2026-10-08, after this report)

- `AssetService:CreateEditableImage` and `CreateEditableMesh` work from the MCP `execute_luau` in Edit.
- `AssetService:CreateAssetAsync` from `execute_luau` returned "CreateAssetAsync and CreateAssetVersionAsync are not available yet". This matches the beta post: it needs the Studio beta feature "CreateAssetAsync Luau API". Henry was asked to turn it on.
- The MCP `upload_image` tool:
  - It rejects raw.githubusercontent.com with "Image Url is not trusted".
  - It rejects local file paths with "Only http/https URLs are supported".
  - A `localhost` URL served from the Cowork Linux VM fails with "Unable to read file". The VM's localhost is not the Mac's.
  - So `upload_image` is only usable with URLs Studio trusts, such as Figma asset URLs or a server on Henry's Mac.
- Decision: Rank 1 (Blender here, EditableMesh in Studio, CreateAssetAsync) once the beta is on. Until then, build and test with parts, built-in rbxasset textures and EditableMesh previews.

## Sources
- https://create.roblox.com/docs/en-us/reference/engine/classes/AssetService.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/EditableMesh.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/EditableImage.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/MeshPart.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/GeometryService.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/GenerationService.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md
- https://create.roblox.com/docs/en-us/parts/solid-modeling.md
- https://create.roblox.com/docs/en-us/parts/model-generation.md
- https://create.roblox.com/docs/en-us/art/modeling/specifications.md
- https://create.roblox.com/docs/en-us/art/modeling/export-requirements.md
- https://create.roblox.com/docs/en-us/art/modeling/texture-specifications.md
- https://create.roblox.com/docs/cloud/guides/usage-assets
- https://create.roblox.com/docs/en-us/cloud/reference/features/assets.md
- https://create.roblox.com/docs/en-us/studio/mcp.md
- https://create.roblox.com/docs/en-us/generative-AI.md
- https://devforum.roblox.com/t/beta-lua-asset-creation-for-creator-tooling-with-createassetasync/3294134
- https://devforum.roblox.com/t/2725284 (Mesh and Image APIs Studio Beta)
- https://devforum.roblox.com/t/4541898 (CreateDataModelContent)
- https://devforum.roblox.com/t/editablemesh-restrictions/4566101
- https://devforum.roblox.com/t/assistant-updates-mesh-generation-new-mcp-server-tools-screenshot-tool-and-more/4527258
- https://devforum.roblox.com/t/assistant-mesh-generation-ux-problems/3585893
- https://devforum.roblox.com/t/early-preview-generate-3d-models-segmented-into-multiple-parts/4678458
- https://devforum.roblox.com/t/unions-vs-meshparts-2023/2638232
- https://about.roblox.com/newsroom/2025/03/introducing-roblox-cube
- https://pypi.org/project/bpy/

Worth remembering for Henry's Roblox project:
- Editables never persist, so meshes need a CreateAssetAsync or Open Cloud upload.
- The container cannot reach apis.roblox.com or create.roblox.com.
- bpy 4.5.14 works in the container on Python 3.11.
