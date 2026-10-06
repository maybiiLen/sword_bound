---
type: system
created: 2026-10-01
author: claude
tags:
  - system
  - workflow
---

Up: [[Claude]]

How Claude posts dev updates to the team's Discord channel.

- Posting goes through a Discord webhook. The webhook URL is a secret, kept only in the cloud session's scratchpad. It is never put in git, game scripts or this vault.
- It works because Henry set his cloud environment's network access to Custom with discord.com allowed (environment selector above the message box, gear icon).
- Claude posts after each finished feature, with a short plain description and a screenshot strip.
- Screenshots: Studio's screen_capture saves a JPG that works in play mode. Animation frames are posed:
  - the target is anchored and frozen on the server
  - the player gets IFrames so AI can't kill them
  - the animation plays on the client at speed 0 with a set TimePosition
  - a side camera is held with a RenderStep binding that runs after CameraController
  - Effects.HitSpark can be looped for a hit frame
- Frames are cropped and joined with PIL, then posted as one multipart attachment.
- Real GIFs aren't practical, since capture is about one frame per second.
- Strips posted so far are in the `Attachments` folder, embedded in the daily notes.

History: [[2026-10-01]].
