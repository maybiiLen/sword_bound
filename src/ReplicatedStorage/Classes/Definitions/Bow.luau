--[[
	Class: Bow
	Registered so it saves and levels independently; no bow weapon exists yet.
	To add one: a weapon definition with Class = "Bow" plus a WeaponBehaviors.Bow module.
	The module name must equal Id. See Docs.Progression.
]]

return {
	Id = "Bow",
	DisplayName = "Bow",
	Color = Color3.fromRGB(140, 230, 120),
}
