--[[
	WeaponService  (server only)
	Owns which weapon each player has and where it is on their body.
		- Equip: clones the weapon model into the character as "WeaponModel", attaches it to the
		  back (sheathed) with a RigidConstraint, saves data.EquippedWeapon and makes the weapon's
		  Class the player's active class (ProgressionService).
		- Draw/sheath: moves the RigidConstraint between the back and the right hand.
		- Re-equips the saved weapon on every respawn.

	Character attributes written: EquippedWeapon (weapon id), WeaponDrawn (bool).

	Remote: Combat.Remotes.EquipRemote
		client -> server ("Toggle")            draw if sheathed, sheath if drawn
		client -> server ("Equip", weaponId)   NOTE: any registered weapon for now; gate this on
		                                       inventory ownership once inventory exists

	API:
		:Equip(player, weaponId) -> boolean
		:Unequip(player)
		:SetDrawn(player, drawn) -> boolean
		:GetEquipped(player) -> (definition?, model?)
		:IsDrawn(player) -> boolean

	See Docs.Combat > "Equip".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Combat = ReplicatedStorage.Combat
local CombatConfig = require(Combat.CombatConfig)
local WeaponRegistry = require(Combat.WeaponRegistry)
local PlayerDataService = require(ServerScriptService.PlayerData.PlayerDataService)
local ProgressionService = require(script.Parent.ProgressionService)

local Attr = CombatConfig.Attributes
local EquipRemote = Combat.Remotes.EquipRemote
local EffectRemote = Combat.Remotes.EffectRemote

local WeaponService = {}

type Equipped = {
	definition: any,
	model: Model,
	constraint: RigidConstraint,
	character: Model,
	lastToggle: number,
}

local equipped: { [Player]: Equipped } = {}

-- Only the rig's own body parts; accessories carry attachments with the same names.
local function findRigAttachment(character: Model, name: string): Attachment?
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") then
			local attachment = child:FindFirstChild(name)
			if attachment and attachment:IsA("Attachment") then
				return attachment
			end
		end
	end
	return nil
end

local function fireOthers(player: Player, ...)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			EffectRemote:FireClient(other, ...)
		end
	end
end

function WeaponService:Unequip(player: Player)
	local current = equipped[player]
	equipped[player] = nil
	if current then
		current.model:Destroy()
		if current.character.Parent then
			current.character:SetAttribute(Attr.EquippedWeapon, nil)
			current.character:SetAttribute(Attr.WeaponDrawn, nil)
		end
	end
	ProgressionService:SetActiveClass(player, nil)
end

function WeaponService:Equip(player: Player, weaponId: string): boolean
	local definition = WeaponRegistry.Get(weaponId)
	local template = WeaponRegistry.GetModel(weaponId)
	local character = player.Character
	if not definition or not template or not character then
		return false
	end
	local back = findRigAttachment(character, CombatConfig.BackAttachment)
	if not back then
		warn(`[WeaponService] {player.Name}'s rig has no {CombatConfig.BackAttachment}`)
		return false
	end

	self:Unequip(player)

	local model = template:Clone()
	model.Name = CombatConfig.WeaponModelName
	model:SetAttribute("WeaponId", weaponId)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
		end
	end
	local handle = model.PrimaryPart :: BasePart
	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "WeaponAttach"
	constraint.Attachment0 = back
	constraint.Attachment1 = handle:FindFirstChild("SheathGrip") :: Attachment
	constraint.Parent = handle
	model:PivotTo(back.WorldCFrame * (constraint.Attachment1 :: Attachment).CFrame:Inverse())
	model.Parent = character

	equipped[player] = {
		definition = definition,
		model = model,
		constraint = constraint,
		character = character,
		lastToggle = 0,
	}
	character:SetAttribute(Attr.EquippedWeapon, weaponId)
	character:SetAttribute(Attr.WeaponDrawn, false)

	local data = PlayerDataService:GetData(player)
	if data then
		data.EquippedWeapon = weaponId
	end
	ProgressionService:SetActiveClass(player, definition.Class)
	return true
end

function WeaponService:SetDrawn(player: Player, drawn: boolean): boolean
	local current = equipped[player]
	if not current or current.character:GetAttribute(Attr.WeaponDrawn) == drawn then
		return false
	end
	local handle = current.model.PrimaryPart :: BasePart
	local attachment = findRigAttachment(current.character, if drawn then CombatConfig.HandAttachment else CombatConfig.BackAttachment)
	local grip = handle:FindFirstChild(if drawn then "Grip" else "SheathGrip") :: Attachment
	if not attachment or not grip then
		return false
	end
	current.constraint.Attachment0 = attachment
	current.constraint.Attachment1 = grip
	current.character:SetAttribute(Attr.WeaponDrawn, drawn)
	fireOthers(player, "Draw", current.character, drawn)
	return true
end

function WeaponService:GetEquipped(player: Player): (any, Model?)
	local current = equipped[player]
	if current and current.character == player.Character then
		return current.definition, current.model
	end
	return nil, nil
end

function WeaponService:IsDrawn(player: Player): boolean
	local current = equipped[player]
	return current ~= nil and current.character:GetAttribute(Attr.WeaponDrawn) == true
end

local function onCharacterAdded(player: Player, character: Model)
	if not player:HasAppearanceLoaded() then
		local loaded = false
		local connection = player.CharacterAppearanceLoaded:Once(function()
			loaded = true
		end)
		local deadline = os.clock() + 10
		while not loaded and os.clock() < deadline and character.Parent do
			task.wait(0.1)
		end
		connection:Disconnect()
	end
	if player.Character ~= character or not character.Parent then
		return
	end
	local data = PlayerDataService:GetData(player)
	local weaponId = data and data.EquippedWeapon or CombatConfig.DefaultWeapon
	if not WeaponService:Equip(player, weaponId) then
		WeaponService:Equip(player, CombatConfig.DefaultWeapon)
	end
end

function WeaponService:Start()
	PlayerDataService:ForEachLoaded(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		equipped[player] = nil
	end)

	EquipRemote.OnServerEvent:Connect(function(player: Player, action: unknown, weaponId: unknown)
		if action == "Toggle" then
			local current = equipped[player]
			local now = os.clock()
			if not current or now - current.lastToggle < CombatConfig.ToggleCooldown then
				return
			end
			if current.character:GetAttribute(Attr.CombatState) == "Attacking" then
				return
			end
			current.lastToggle = now
			WeaponService:SetDrawn(player, not WeaponService:IsDrawn(player))
		elseif action == "Equip" and typeof(weaponId) == "string" then
			WeaponService:Equip(player, weaponId)
		end
	end)
end

return WeaponService
