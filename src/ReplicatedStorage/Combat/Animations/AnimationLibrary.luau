--[[
	AnimationLibrary
	Resolves combat animation names ("Light1", "Roll"...) to animation ids, and exposes timing
	from Animations.Specs so gameplay code never hard-codes seconds.

	Id resolution:
		1. Published[name] if set (the real asset; required for live servers).
		2. In Studio only: registers Combat.Assets.AnimSaves[name] (the KeyframeSequence made by
		   AnimationBuilder) with KeyframeSequenceProvider for a temporary id, so playtests work
		   before publishing.
		3. R6 rigs use R6Fallback (old Roblox clips), since the specs are R15.

	Publishing: right-click Combat.Assets.AnimSaves.<Name> > Save to Roblox (upload under the group
	that owns the game), then paste "rbxassetid://<id>" into Published below.

	API:
		AnimationLibrary.GetId(name, isR6?) -> string?
		AnimationLibrary.Spec(name) -> spec?
		AnimationLibrary.Length(name) -> seconds
		AnimationLibrary.MarkerTime(name, marker) -> seconds?
		AnimationLibrary.Priority(name) -> Enum.AnimationPriority
		AnimationLibrary.IsLooped(name) -> boolean

	See Docs.Combat > "Animation pipeline".
]]

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local RunService = game:GetService("RunService")

local Specs = require(script.Parent.Specs)

local AnimSaves = script.Parent.Parent:WaitForChild("Assets"):WaitForChild("AnimSaves")

local Published: { [string]: string } = {
	GuardIdle = "",
	Light1 = "",
	Light2 = "",
	Light3 = "",
	HeavyCharge = "",
	HeavyRelease = "",
	Roll = "",
	Backstep = "",
	BlockIdle = "",
	BlockImpact = "",
	Parry = "",
	GuardBreak = "",
	Stagger = "",
	Flinch = "",
	KnightSlash = "",
	KnightDelayedChop = "",
}

local R6Fallback: { [string]: string } = {
	GuardIdle = "rbxassetid://182393478",
	Light1 = "rbxassetid://129967390",
	Light2 = "rbxassetid://129967390",
	Light3 = "rbxassetid://129967478",
	HeavyRelease = "rbxassetid://129967478",
	KnightSlash = "rbxassetid://129967390",
	KnightDelayedChop = "rbxassetid://129967478",
}

local PRIORITY = {
	Idle = Enum.AnimationPriority.Idle,
	Movement = Enum.AnimationPriority.Movement,
	Action = Enum.AnimationPriority.Action,
	Action2 = Enum.AnimationPriority.Action2,
	Action3 = Enum.AnimationPriority.Action3,
	Action4 = Enum.AnimationPriority.Action4,
}

local registered: { [string]: string } = {}
local warned: { [string]: boolean } = {}

local AnimationLibrary = {}

function AnimationLibrary.GetId(name: string, isR6: boolean?): string?
	if isR6 then
		return R6Fallback[name]
	end
	local published = Published[name]
	if published and published ~= "" then
		return published
	end
	if registered[name] then
		return registered[name]
	end
	if RunService:IsStudio() then
		local sequence = AnimSaves:FindFirstChild(name)
		if sequence and sequence:IsA("KeyframeSequence") then
			local ok, id = pcall(KeyframeSequenceProvider.RegisterKeyframeSequence, KeyframeSequenceProvider, sequence)
			if ok then
				registered[name] = id
				return id
			end
		end
	end
	if not warned[name] then
		warned[name] = true
		warn(`[AnimationLibrary] No animation for '{name}'. Publish Combat.Assets.AnimSaves.{name} and set its id in AnimationLibrary.Published.`)
	end
	return nil
end

function AnimationLibrary.Spec(name: string)
	return Specs[name]
end

function AnimationLibrary.Length(name: string): number
	local spec = Specs[name]
	return if spec then spec.Keyframes[#spec.Keyframes].T else 0
end

function AnimationLibrary.MarkerTime(name: string, marker: string): number?
	local spec = Specs[name]
	return spec and spec.Markers and spec.Markers[marker]
end

function AnimationLibrary.Priority(name: string): Enum.AnimationPriority
	local spec = Specs[name]
	return spec and PRIORITY[spec.Priority] or Enum.AnimationPriority.Action
end

function AnimationLibrary.IsLooped(name: string): boolean
	local spec = Specs[name]
	return spec ~= nil and spec.Loop == true
end

return AnimationLibrary
