--[[
	ClassHudController  (client)
	Drives StarterGui.ClassGui (our own ScreenGui, placed under the SAO_HUD, which we don't
	edit): active class name, "Lv. N", XP bar, and a level-up banner + flash.

	Reads only replicated Player attributes (ClassConfig.Attributes: ActiveClass, ClassLevel,
	ClassXP, ClassXPToNext) and Combat.Remotes.LevelUpRemote(classId, newLevel). Any other UI
	(e.g. the SAO_HUD EXP bar) can read the same attributes the same way.

	API: ClassHudController:Start()
	See Docs.Progression > "UI".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClassConfig = require(ReplicatedStorage.Classes.ClassConfig)
local ClassRegistry = require(ReplicatedStorage.Classes.ClassRegistry)
local Effects = require(ReplicatedStorage.Combat.Effects)

local Attr = ClassConfig.Attributes
local player = Players.LocalPlayer

local ClassHudController = {}

local gui, frame, classLabel, levelLabel, fill, xpText, banner, stroke
local bannerToken = 0

local function refresh()
	local classId = player:GetAttribute(Attr.ActiveClass)
	local definition = classId and ClassRegistry.Get(classId)
	if not definition then
		frame.Visible = false
		return
	end
	frame.Visible = true

	local level = player:GetAttribute(Attr.Level) or 1
	local xp = player:GetAttribute(Attr.XP) or 0
	local toNext = player:GetAttribute(Attr.XPToNext) or 0

	classLabel.Text = string.upper(definition.DisplayName)
	classLabel.TextColor3 = definition.Color
	stroke.Color = definition.Color
	levelLabel.Text = "Lv. " .. level

	local ratio = if toNext > 0 then math.clamp(xp / toNext, 0, 1) else 1
	xpText.Text = if toNext > 0 then string.format("%d / %d XP", xp, toNext) else "MAX"
	TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()
end

local function playLevelUp(classId: string, newLevel: number)
	local definition = ClassRegistry.Get(classId)
	local name = definition and definition.DisplayName or classId
	bannerToken += 1
	local token = bannerToken

	banner.Text = string.format("LEVEL UP!  %s Lv. %d", string.upper(name), newLevel)
	banner.TextColor3 = definition and definition.Color or banner.TextColor3
	banner.Visible = true
	banner.TextTransparency = 1
	banner.TextStrokeTransparency = 1
	banner.Position = UDim2.new(0.5, 0, 0, 110)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextStrokeTransparency = 0.2,
		Position = UDim2.new(0.5, 0, 0, 90),
	}):Play()

	stroke.Thickness = 3
	stroke.Transparency = 0
	TweenService:Create(stroke, TweenInfo.new(0.8), { Thickness = 1, Transparency = 0.4 }):Play()
	Effects.PlaySound(gui, "Draw")

	task.delay(2.2, function()
		if token ~= bannerToken then
			return
		end
		local fade = TweenService:Create(banner, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

function ClassHudController:Start()
	gui = player:WaitForChild("PlayerGui"):WaitForChild("ClassGui")
	frame = gui:WaitForChild("ClassFrame")
	classLabel = frame:WaitForChild("ClassLabel")
	levelLabel = frame:WaitForChild("LevelLabel")
	fill = frame:WaitForChild("XPBarBack"):WaitForChild("Fill")
	xpText = frame.XPBarBack:WaitForChild("XPText")
	stroke = frame:WaitForChild("UIStroke")
	banner = gui:WaitForChild("LevelUpBanner")

	for _, name in { Attr.ActiveClass, Attr.Level, Attr.XP, Attr.XPToNext } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	ReplicatedStorage.Combat.Remotes.LevelUpRemote.OnClientEvent:Connect(playLevelUp)
	refresh()
end

return ClassHudController
