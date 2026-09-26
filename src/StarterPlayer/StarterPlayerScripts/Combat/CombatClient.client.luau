--[[
	CombatClient
	Bootstraps the client side of combat + progression. The only LocalScript in this folder;
	everything else is a controller module with :Start().
	See Docs.Combat > "Client".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = require(script.Parent:WaitForChild("InputController"))
local LockOnController = require(script.Parent:WaitForChild("LockOnController"))
local CameraController = require(script.Parent:WaitForChild("CameraController"))
local MovementController = require(script.Parent:WaitForChild("MovementController"))
local WeaponController = require(script.Parent:WaitForChild("WeaponController"))
local ClassHudController = require(script.Parent:WaitForChild("ClassHudController"))
local KnightAnimator = require(script.Parent:WaitForChild("KnightAnimator"))
local Effects = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("Effects"))

Effects.SetCameraHooks({
	Shake = function(trauma)
		CameraController:Shake(trauma)
	end,
	Punch = function(studs)
		CameraController:Punch(studs)
	end,
})
Effects.Listen()
InputController:Start()
LockOnController:Start()
CameraController:Start(LockOnController)
MovementController:Start(LockOnController)
WeaponController:Start(InputController, MovementController, CameraController, LockOnController)
ClassHudController:Start()
KnightAnimator:Start()
