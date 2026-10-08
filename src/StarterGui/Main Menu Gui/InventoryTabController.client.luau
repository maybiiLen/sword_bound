local menuGui = script.Parent
local panel = menuGui:WaitForChild("InventoryPanel")
local tabBar = panel:WaitForChild("TabBar")
local body = panel:WaitForChild("Body") -- Equipment tab content
local mountsBody = panel:WaitForChild("MountsBody") -- Mounts tab content

-- dark theme (inventory revamp): active tab is lighter with white text, inactive is dark with muted text
local WHITE = Color3.fromRGB(46, 52, 60)
local OFFWHITE = Color3.fromRGB(28, 31, 36)
local TEXT_DARK = Color3.fromRGB(255, 255, 255)
local TEXT_MUTED = Color3.fromRGB(140, 148, 156)

local tabs = {
	{ name = "Equipment", content = body, title = "Equipment", subtitle = "Change your weapons and armor." },
	{ name = "Mounts", content = mountsBody, title = "Mounts", subtitle = "Choose your mount." },
}

local titleBar = panel:WaitForChild("TitleBar")

local function selectTab(selectedIndex)
	for i, tab in ipairs(tabs) do
		local button = tabBar:FindFirstChild("Tab_" .. tab.name)
		local underline = button and button:FindFirstChild("Underline")
		local active = (i == selectedIndex)

		tab.content.Visible = active
		if active then
			titleBar.TitleLabel.Text = tab.title
			titleBar.Subtitle.Text = tab.subtitle
		end
		if button then
			button.BackgroundColor3 = active and WHITE or OFFWHITE
			button.TextColor3 = active and TEXT_DARK or TEXT_MUTED
		end
		if underline then
			underline.BackgroundTransparency = active and 0 or 1
		end
	end
end

for i, tab in ipairs(tabs) do
	local button = tabBar:FindFirstChild("Tab_" .. tab.name)
	if button then
		button.MouseButton1Click:Connect(function()
			selectTab(i)
		end)
	end
end

selectTab(1) -- Equipment tab open by default
