---
type: system
created: 2026-09-10
author: claude
tags:
  - system
  - movement
---

Up: [[Claude]]

Note: this was built in Place2 for testing. The live game uses its own SprintServer/SprintClient (see Docs.Sprint in the place).

Built in Place2. Four instances, no uploaded animation assets required.

## Where things live

| Instance | Location | Type |
| --- | --- | --- |
| `MovementConfig` | ReplicatedStorage | ModuleScript |
| `MovementController` | StarterPlayer > StarterPlayerScripts | LocalScript |
| `MovementGuard` | ServerScriptService | Script |
| `StaminaGui` | StarterGui | ScreenGui |

All tuning happens in `MovementConfig`. The other three read from it, so you should not need to touch them to change feel.

## How the animation works without asset IDs

**Sprint.** Roblox's default `Animate` script already scales the run animation playback speed by `WalkSpeed / 16`. Raising WalkSpeed from 16 to 26 makes the existing run cycle play at 1.6x on its own. There is nothing to upload and nothing to load at runtime.

**Double jump.** The flip is driven procedurally. The script rotates the character's root joint through a full 360 degrees over `FlipDuration` while the HumanoidRootPart itself stays upright, so the body spins visually and the player keeps full air control.

Roblox has shipped three different root rigs. `resolveRootDriver` detects which one the character uses and drives whichever is present:

- R6, a `Motor6D` named `RootJoint` inside HumanoidRootPart, offset via `C0`
- older R15, a `Motor6D` named `Root` inside LowerTorso, offset via `C0`
- current R15, an `AnimationConstraint` named `Root`, offset via HumanoidRootPart's `RootRigAttachment.CFrame`

The current R15 rig is the one this place uses. The animator writes to the joint's `Transform` property rather than `C0`, so the flip offset composes with whatever animation is playing instead of fighting it.

## Config values

```lua
Config.BaseWalkSpeed = 16
Config.SprintWalkSpeed = 26
Config.SprintFovBoost = 8          -- set to 0 to remove the camera kick

Config.MaxStamina = 100
Config.StaminaDrainPerSecond = 20  -- 5 seconds of continuous sprint
Config.StaminaRegenPerSecond = 15
Config.StaminaRegenDelay = 1
Config.MinStaminaToStartSprint = 10
Config.AirJumpStaminaCost = 0      -- raise above 0 to charge stamina per air jump

Config.MaxAirJumps = 1             -- set to 2 for a triple jump
Config.AllowAirJumpAfterFalling = false
Config.AirJumpPowerMultiplier = 1
Config.AirJumpCooldown = 0.2

Config.FlipEnabled = true
Config.FlipDuration = 0.45
Config.FlipDirection = -1          -- -1 front flip, 1 back flip
```

## Rules the code enforces

Stamina only drains while actually moving on the ground, so holding Shift while standing still costs nothing. Sprint will not start below `MinStaminaToStartSprint` and cancels itself at zero.

The air jump requires having jumped from the ground. Walking off a ledge gives no air jump, which is what `AllowAirJumpAfterFalling = false` means. Flip that to `true` for the forgiving platformer version. The counter resets only on landing, so hovering is not possible.

The stamina bar fades out entirely when the pool is full and fades back in as soon as it drops. The fill turns red below 25 percent.

## Input

Sprint binds through ContextActionService to LeftShift, RightShift, and gamepad L3, and auto-creates a mobile touch button labeled RUN. The air jump listens to `UserInputService.JumpRequest`, which covers spacebar, gamepad A, and the mobile jump button in one event.

## Verification done in Studio

Confirmed in a live playtest:

- no script errors on either client or server
- the sprint action registers with ContextActionService
- the RenderStepped loop is alive, it repaired a deliberately corrupted GUI state within one frame
- jump velocity computes to 53.15 from `sqrt(2 * 196.2 * 7.2)`, matching the place's gravity and JumpHeight
- the air jump impulse gains height while the humanoid is in Freefall
- the flip sweeps a continuous 360 degrees, measured against LowerTorso's up vector in root space, tracking the commanded angle 1:1 with only the freefall animation's own hip pose as offset
- the HumanoidRootPart stays upright throughout the flip, so air control is preserved

Not verified programmatically: real keyboard input. Synthetic key events did not reach the game window during the test, so holding Shift and pressing space twice needs a manual pass.
