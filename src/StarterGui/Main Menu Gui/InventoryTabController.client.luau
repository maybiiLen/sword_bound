local menuGui = script.Parent
local panel = menuGui:WaitForChild("InventoryPanel")
local tabBar = panel:WaitForChild("TabBar")
local body = panel:WaitForChild("Body") -- Equipment tab content
local mountsBody = panel:WaitForChild("MountsBody") -- Mounts tab content

local WHITE = Color3.fromRGB(255, 255, 255)
local OFFWHITE = Color3.fromRGB(245, 245, 245)
local TEXT_DARK = Color3.fromRGB(40, 40, 40)
local TEXT_MUTED = Color3.fromRGB(120, 120, 120)

local tabs = {
	{ name = "Equipment", content = body },
	{ name = "Mounts", content = mountsBody },
}

local function selectTab(selectedIndex)
	for i, tab in ipairs(tabs) do
		local button = tabBar:FindFirstChild("Tab_" .. tab.name)
		local underline = button and button:FindFirstChild("Underline")
		local active = (i == selectedIndex)

		tab.content.Visible = active
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
