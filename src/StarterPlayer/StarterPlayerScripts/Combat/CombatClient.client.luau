--[[
	CombatClient
	Bootstraps the client side of combat + progression. The only LocalScript in this folder;
	everything else is a controller module with :Start().
	See Docs.Combat > "Client".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = require(script.Parent:WaitForChild("InputController"))
local WeaponController = require(script.Parent:WaitForChild("WeaponController"))
local ClassHudController = require(script.Parent:WaitForChild("ClassHudController"))
local Effects = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Effects"))

Effects.Listen()
InputController:Start()
WeaponController:Start(InputController)
ClassHudController:Start()
