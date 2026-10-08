--[[
	AbilityHudController  (client)
	Drives the ability hotbar in StarterGui.AbilityHud: 3 ability slots (key number, name, red
	cooldown fill) with an ultimate bar above them. It only DISPLAYS state and reports presses;
	whatever ability system exists decides what a press does (server is authoritative).

	API:
		AbilityHudController:Start(gui: ScreenGui)       called by the AbilityHud bootstrap
		AbilityHudController.Activated                   Signal(slot: number)  slot pressed while ready
		AbilityHudController.UltimateActivated           Signal()              ultimate pressed while full
		AbilityHudController:SetAbilityName(slot, name)
		AbilityHudController:StartCooldown(slot, seconds)   fill drains from full to empty
		AbilityHudController:GetCooldownRemaining(slot) -> seconds
		AbilityHudController:SetUltimateCharge(fraction)    0..1
		AbilityHudController:GetUltimateCharge() -> number
	Or set player attributes (names in AbilityConfig.Attributes): Ability<N>CooldownEnd
	(server time) + Ability<N>CooldownTime, and UltimateCharge.

	Keys, names, colors and PreviewMode live in AbilityConfig. Used by: the AbilityHud bootstrap
	LocalScript. See Docs.Abilities.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Config = require(script.Parent.AbilityConfig)

local player = Players.LocalPlayer

type SlotView = {
	button: TextButton,
	cooldown: Frame,
	nameLabel: TextLabel,
	endsAt: number, -- os.clock() when the cooldown finishes (0 = ready)
	total: number,
}

local AbilityHudController = {
	Activated = Signal.new(),
	UltimateActivated = Signal.new(),
}

local trove = Trove.new()
local slots: { SlotView } = {}
local ultimateFill: Frame
local ultimateLabel: TextLabel
local ultimateCharge = 0

local FILL_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function AbilityHudController:SetAbilityName(slot: number, name: string)
	local view = slots[slot]
	if view then
		view.nameLabel.Text = name
	end
end

function AbilityHudController:GetCooldownRemaining(slot: number): number
	local view = slots[slot]
	return view and math.max(0, view.endsAt - os.clock()) or 0
end

function AbilityHudController:StartCooldown(slot: number, seconds: number)
	local view = slots[slot]
	if view and seconds > 0 then
		view.total = seconds
		view.endsAt = os.clock() + seconds
		view.cooldown.Size = UDim2.fromScale(1, 1)
	end
end

function AbilityHudController:GetUltimateCharge(): number
	return ultimateCharge
end

function AbilityHudController:SetUltimateCharge(fraction: number)
	ultimateCharge = math.clamp(fraction, 0, 1)
	local full = ultimateCharge >= 1
	TweenService:Create(ultimateFill, FILL_TWEEN, {
		Size = UDim2.fromScale(ultimateCharge, 1),
		BackgroundColor3 = if full then Config.Colors.RedFull else Config.Colors.Red,
	}):Play()
	ultimateLabel.Text = if full then `<i>{Config.UltimateName}  [{Config.UltimateKey.Name}]</i>` else `<i>{Config.UltimateName}</i>`
end

-- a pressed slot: only counts while the ability is ready
local function press(slot: number)
	local view = slots[slot]
	if not view or AbilityHudController:GetCooldownRemaining(slot) > 0 then
		return
	end
	view.button.BackgroundColor3 = Config.Colors.SlotBackground:Lerp(Color3.new(1, 1, 1), 0.25)
	TweenService:Create(view.button, FILL_TWEEN, { BackgroundColor3 = Config.Colors.SlotBackground }):Play()
	AbilityHudController.Activated:Fire(slot)
	if Config.PreviewMode then
		AbilityHudController:StartCooldown(slot, Config.Slots[slot].PreviewCooldown)
		AbilityHudController:SetUltimateCharge(ultimateCharge + Config.PreviewUltimateGain)
	end
end

local function pressUltimate()
	if ultimateCharge < 1 then
		return
	end
	AbilityHudController.UltimateActivated:Fire()
	if Config.PreviewMode then
		AbilityHudController:SetUltimateCharge(0)
	end
end

-- a real ability system can drive the HUD through player attributes instead of the API
local function readCooldownAttributes(slot: number)
	local endTime = player:GetAttribute(string.format(Config.Attributes.CooldownEnd, slot))
	if typeof(endTime) ~= "number" then
		return
	end
	local remaining = endTime - workspace:GetServerTimeNow()
	if remaining > 0 then
		local total = player:GetAttribute(string.format(Config.Attributes.CooldownTime, slot))
		local view = slots[slot]
		view.total = if typeof(total) == "number" and total > 0 then total else remaining
		view.endsAt = os.clock() + remaining
	end
end

local function readUltimateAttribute()
	local charge = player:GetAttribute(Config.Attributes.UltimateCharge)
	if typeof(charge) == "number" then
		AbilityHudController:SetUltimateCharge(charge)
	end
end

function AbilityHudController:Start(gui: ScreenGui)
	trove:Clean()
	table.clear(slots)

	local ultimateBar = gui.Root.UltimateBar
	ultimateFill = ultimateBar.Fill
	ultimateLabel = ultimateBar.Label
	ultimateLabel.Text = `<i>{Config.UltimateName}</i>`

	for index, definition in Config.Slots do
		local button = gui.Root.Abilities:FindFirstChild("Slot" .. index) :: TextButton
		button.Key.Text = UserInputService:GetStringForKeyCode(definition.Key)
		button.NameLabel.Text = definition.Name
		slots[index] = {
			button = button,
			cooldown = button.Cooldown,
			nameLabel = button.NameLabel,
			endsAt = 0,
			total = 1,
		}
		trove:Connect(button.MouseButton1Click, function()
			press(index)
		end)
		trove:Connect(player:GetAttributeChangedSignal(string.format(Config.Attributes.CooldownEnd, index)), function()
			readCooldownAttributes(index)
		end)
		readCooldownAttributes(index)
	end

	trove:Connect(player:GetAttributeChangedSignal(Config.Attributes.UltimateCharge), readUltimateAttribute)
	readUltimateAttribute()
	if ultimateCharge == 0 then
		AbilityHudController:SetUltimateCharge(0)
	end

	-- keys; gameProcessed skips typing in a text box (e.g. the inventory search)
	trove:Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		for index, definition in Config.Slots do
			if input.KeyCode == definition.Key then
				press(index)
				return
			end
		end
		if input.KeyCode == Config.UltimateKey then
			pressUltimate()
		end
	end)

	-- drain the red cooldown fills
	trove:Connect(RunService.RenderStepped, function()
		local now = os.clock()
		for _, view in slots do
			if view.endsAt > 0 then
				local remaining = view.endsAt - now
				if remaining <= 0 then
					view.endsAt = 0
					view.cooldown.Size = UDim2.fromScale(1, 0)
				else
					view.cooldown.Size = UDim2.fromScale(1, remaining / view.total)
				end
			end
		end
	end)
end

return AbilityHudController
