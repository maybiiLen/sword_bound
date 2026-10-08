--[[
	AbilityHudClient  (bootstrap LocalScript)
	Starts AbilityHudController on this ScreenGui. All logic lives in
	ReplicatedStorage.Abilities.AbilityHudController. See Docs.Abilities.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityHudController = require(ReplicatedStorage:WaitForChild("Abilities"):WaitForChild("AbilityHudController"))
AbilityHudController:Start(script.Parent)
