# Sword Bound

Roblox place `97172972533828`. Code and UI live in `src/` and are synced into Studio with [Rojo](https://rojo.space). The map, models and terrain live in the place file itself.

## What lives where

| In git (`src/`) | In the place file (Roblox version history) |
|---|---|
| Scripts, ModuleScripts, RemoteEvents | Workspace: map, terrain, models, lighting |
| UI (`*.model.json`) | Anything created in Studio outside the mapped folders |
| Animation references, config | |

Mapped services (see `default.project.json`): `ReplicatedStorage`, `ServerScriptService`, `StarterGui`, `StarterPlayer.StarterPlayerScripts`. Rojo only replaces instances that exist in `src/`; other things you add to these services in Studio are left alone but are **not** tracked by git.

## Setup (once per machine)

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder to get the pinned Rojo version.
2. Run `rojo plugin install` and restart Studio.

## Daily workflow

1. `git switch -c feature/my-thing`
2. `rojo serve`
3. In Studio: **Plugins → Rojo → Connect**. Files in `src/` now live-sync into Studio.
4. Edit code in `src/` (not in Studio's script editor — Studio edits to synced scripts are overwritten).
5. Playtest in Studio.
6. Commit, push, open a pull request.
7. After merging to `main`: switch to `main`, sync with Rojo, then **File → Publish to Roblox**.

## Layout conventions

- `Name.server.luau` → Script, `Name.client.luau` → LocalScript, `Name.luau` → ModuleScript
- Folders become `Folder` instances
- `Name.model.json` → any other instance (UI, RemoteEvents, Animations)
