# Sword Bound

Roblox place `97172972533828`.

## How this repo is used

The team builds live in the shared Team Create place. The place and Roblox's own version history are the source of truth.

This repo is a personal second version history. Changes are synced from Studio into `src/` by hand and committed here. Nothing flows from this repo back into Studio, so editing files here does not change the game.

## What is tracked

| In git (`src/`) | Only in the place (Roblox version history) |
|---|---|
| Scripts, LocalScripts and ModuleScripts | Workspace: map, terrain, models, lighting |
| Docs pages (`ReplicatedStorage/Docs`) | Most UI layouts (only `SAO_HUD` and `SprintGui` are exported) |
| RemoteEvents, Animation references, config | Studio-made assets in ReplicatedStorage (weapon models, VFX, sounds, saved animations) |

## File naming

- `Name.server.luau` is a Script, `Name.client.luau` is a LocalScript, `Name.luau` is a ModuleScript
- Folders mirror the instance tree, for example `src/StarterGui/Main Menu Gui/` holds that ScreenGui's scripts
- `Name.model.json` is any other instance (UI, RemoteEvents, Animations)

## Syncing from Studio

1. Compare each script in the live place against its file in `src/`.
2. Copy over anything changed or new, using the naming above.
3. Review the diff, then commit.
