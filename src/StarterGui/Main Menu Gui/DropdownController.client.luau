local TweenService = game:GetService("TweenService")

local menuGui = script.Parent
local PanelManager = require(menuGui:WaitForChild("PanelManager"))
local glow = menuGui:WaitForChild("Main Menu")
local button = glow:WaitForChild("Main menu Button")
local dropdown = menuGui:WaitForChild("DropdownMenu")

local GAP_PX = 10
local STAGGER = 0.03 -- seconds between each button starting its sequence
local SLIDE_TIME = 0.14
local FADE_TIME = 0.1
local SLIDE_STYLE = Enum.EasingStyle.Back

local circleNames = { "Inventory Button", "Upgrades Button", "Quests Button", "Trade Button", "Social Button", "Settings Button" }

-- Each entry: { wrap = CanvasGroup (position + fade), button = actual clickable ImageButton }
local circles = {}
for i, name in ipairs(circleNames) do
	local wrap = dropdown:FindFirstChild("Wrap_" .. name)
	local button_ = wrap and wrap:FindFirstChild(name)
	if wrap and button_ then
		circles[i] = { wrap = wrap, button = button_ }
	end
end

local activeTweens = {}

local function cancelTweens()
	for _, tween in ipairs(activeTweens) do
		tween:Cancel()
	end
	table.clear(activeTweens)
end

-- The "tucked under the button" position every wrapper starts/ends at when closed.
local function homePosition()
	return UDim2.new(glow.Position.X.Scale, 0, glow.Position.Y.Scale, 0)
end

-- Each wrapper's fully open resting position, stacked below the button.
local function slotPosition(i: number)
	local h = glow.AbsoluteSize.Y
	return UDim2.new(
		glow.Position.X.Scale, 0,
		glow.Position.Y.Scale, (h + GAP_PX) * i
	)
end

-- Snap every wrapper to its slot instantly (used on resize while closed, so nothing
-- animates from a stale position the next time it opens).
local function layoutCircles()
	for i, entry in ipairs(circles) do
		entry.wrap.AnchorPoint = glow.AnchorPoint
		entry.wrap.Position = slotPosition(i)
	end
end

layoutCircles()
glow:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if not dropdown.Visible then
		layoutCircles()
	end
end)
glow:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	if not dropdown.Visible then
		layoutCircles()
	end
end)

local isOpen = false

local function closeDropdown()
	if not isOpen then
		return
	end
	isOpen = false

	cancelTweens()

	local home = homePosition()
	local lastFinish = 0
	for i, entry in ipairs(circles) do
		-- Reverse stagger: the bottom button goes first.
		local delay = (#circles - i) * STAGGER
		task.delay(delay, function()
			if isOpen then
				return -- reopened before this fired; abandon
			end
			-- Fade out first...
			local fadeOut = TweenService:Create(
				entry.wrap,
				TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ GroupTransparency = 1 }
			)
			table.insert(activeTweens, fadeOut)
			fadeOut:Play()
			-- ...then slide back under the main button while invisible.
			task.delay(FADE_TIME, function()
				if isOpen then
					return
				end
				local slideIn = TweenService:Create(
					entry.wrap,
					TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = home }
				)
				table.insert(activeTweens, slideIn)
				slideIn:Play()
			end)
		end)
		lastFinish = math.max(lastFinish, delay + FADE_TIME + SLIDE_TIME)
	end

	task.delay(lastFinish + 0.02, function()
		if not isOpen then
			dropdown.Visible = false
		end
	end)
end

local function openDropdown()
	if isOpen then
		return
	end
	-- Opening the dropdown itself no longer closes other HUD panels -- only actually
	-- picking one of the 6 items inside it does (each item's own controller calls
	-- PanelManager.open for itself, which also closes this dropdown in the process).
	isOpen = true
	cancelTweens()

	local home = homePosition()
	dropdown.Visible = true
	for i, entry in ipairs(circles) do
		entry.wrap.AnchorPoint = glow.AnchorPoint
		entry.wrap.Position = home -- start tucked under the main button
		entry.wrap.GroupTransparency = 1 -- fully invisible while it's still near the button
		local target = slotPosition(i)
		local delay = (i - 1) * STAGGER
		task.delay(delay, function()
			if not isOpen then
				return -- closed again before this fired; abandon
			end
			-- Slide into place first, while still invisible...
			local slideOut = TweenService:Create(
				entry.wrap,
				TweenInfo.new(SLIDE_TIME, SLIDE_STYLE, Enum.EasingDirection.Out),
				{ Position = target }
			)
			table.insert(activeTweens, slideOut)
			slideOut:Play()
			-- ...then fade in once it's reached its slot.
			task.delay(SLIDE_TIME, function()
				if not isOpen then
					return
				end
				local fadeIn = TweenService:Create(
					entry.wrap,
					TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ GroupTransparency = 0 }
				)
				table.insert(activeTweens, fadeIn)
				fadeIn:Play()
			end)
		end)
	end
end

-- Toggling only happens via the main button itself, so the rest of the
-- screen stays fully interactive while the dropdown is open.
PanelManager.register("Dropdown", closeDropdown)

button.MouseButton1Click:Connect(function()
	if isOpen then
		closeDropdown()
	else
		openDropdown()
	end
end)

for i, entry in ipairs(circles) do
	entry.button.MouseButton1Click:Connect(function()
		print(circleNames[i] .. " clicked")
		-- TODO: hook up each button to its menu action (inventory, map, settings, etc.)
		closeDropdown()
	end)
end
