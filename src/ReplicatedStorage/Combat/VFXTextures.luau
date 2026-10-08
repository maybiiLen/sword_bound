--[[
	VFXTextures  (shared data)
	Texture ids for combat effects (Combat.VFX). All are white shapes with alpha so Color tints
	them. Made by ServerStorage.CombatDev.WeaponForge.TextureForge and published 2026-10-08 with
	AssetService:CreateAssetAsync; regenerate with TextureForge.PublishAll() and paste the ids.

	Fallbacks (Roblox built-in textures, used if an id is removed):
		Glow   rbxasset://textures/particles/explosion01_implosion_main.dds
		Flare  rbxasset://textures/particles/sparkles_main.dds
		Ring   rbxasset://textures/particles/explosion01_shockwave_main.dds
		Smoke  rbxasset://textures/particles/smoke_main.dds (set SmokeIsFlipbook = false)
]]

return {
	Glow = "rbxassetid://80702698007042", -- soft dot, 256
	Streak = "rbxassetid://111745707536995", -- spark streak (long axis = V), 128
	Flare = "rbxassetid://74291991629219", -- four-point cross flare, 256
	Ring = "rbxassetid://86374586692925", -- shockwave ring, 256
	Slash = "rbxassetid://75577871167829", -- crescent slash, bright head at the top, 512
	Smoke = "rbxassetid://132182595296880", -- 4x4 eroding smoke flipbook, 256
	Trail = "rbxassetid://132956601545014", -- trail strip, bright core line, 128
	SmokeIsFlipbook = true,
}

