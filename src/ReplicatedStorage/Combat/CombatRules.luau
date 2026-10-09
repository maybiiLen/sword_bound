--!strict
--[[
	CombatRules  (shared, pure)
	The combat math in one place, with no state and no side effects, so the server, the client and
	the unit tests (ServerStorage.CombatDev.Tests) all use the same rules. Services keep the state;
	this module only answers questions like "how much damage" or "is armor up right now".

	API:
		CombatRules.DamageTypeOf(attack, weapon?) -> "Slash" | "Strike" | "Pierce"
		CombatRules.IsCounterState(combatState) -> boolean        the target was Attacking/Charging
		CombatRules.CounterMultiplier(damageType, isCounter, pvp?) -> number
		CombatRules.GuardStaminaCost(damage, damageType, guardDamage?, stability) -> number
		CombatRules.ArmorOf(attack) -> armor table?               Armor, or {} for HyperArmor = true
		CombatRules.ArmorWindow(attack) -> (start, finish)?       seconds from the attack's start
		CombatRules.ArmorActive(attack, elapsed) -> boolean
		CombatRules.ArmorDamageTaken(attack, pvp?) -> number      1 when the attack has no armor
		CombatRules.HitDamage(parts) -> number                    see the function for the parts
		CombatRules.StaggerUpdate(currentEnd, currentKind, now, duration, kind)
			-> (newEnd, newKind)                                 longest stun wins
		CombatRules.StaggerImmunity(pvp?) -> seconds
		CombatRules.WarpOf(attack) -> studs                       attack.Warp, else CombatConfig.DefaultWarp
		CombatRules.ArmorTierOf(model) -> "Fodder" | "Elite" | "Boss"
		CombatRules.IsFromBehind(victimCFrame, attackerPosition) -> boolean
		CombatRules.PredictsPoiseBreak(target, attack) -> boolean   from the replicated Poise attribute
		CombatRules.HitReaction(attack, tier, targetAttacking, fromBehind)
			-> (reaction animation, slide studs, slide seconds, armored)   see CombatConfig "Hit reactions"
		CombatRules.WarpDistance(distance, angle, maxWarp) -> studs
		                                                         how far an attack travels toward a target
		                                                         `distance` away, `angle` degrees off the aim

	Tuning numbers live in CombatConfig (DamageTypes, ArmorDamageTaken, StaggerImmunityTime, PvP).
	See Docs.Combat > "Damage types, armor, stun rules" and the vault note "Phase 0 shared combat systems".
]]

local CombatConfig = require(script.Parent.CombatConfig)
local AnimationLibrary = require(script.Parent.Animations.AnimationLibrary)

local CombatRules = {}

local EMPTY_ARMOR = table.freeze({})

local function typeInfo(damageType: string?)
	local types = CombatConfig.DamageTypes :: any
	return types[damageType or "Slash"] or types.Slash
end

function CombatRules.DamageTypeOf(attack: any, weapon: any?): string
	if attack and attack.DamageType then
		return attack.DamageType
	end
	if weapon and weapon.DamageType then
		return weapon.DamageType
	end
	return "Slash"
end

function CombatRules.IsCounterState(combatState: any): boolean
	return combatState == "Attacking" or combatState == "Charging"
end

-- x damage for a hit that lands while the target is mid-attack. PvP keeps only part of the bonus.
function CombatRules.CounterMultiplier(damageType: string?, isCounter: boolean, pvp: boolean?): number
	if not isCounter then
		return 1
	end
	local extra = typeInfo(damageType).CounterBonus - 1
	if pvp then
		extra = extra * CombatConfig.PvP.CounterBonusScale
	end
	return 1 + extra
end

-- stamina a blocked hit costs the blocker
function CombatRules.GuardStaminaCost(damage: number, damageType: string?, guardDamage: number?, stability: number): number
	local cost = damage * CombatConfig.BlockStaminaPerDamage * (1 - stability)
	cost = cost * typeInfo(damageType).GuardStamina
	cost = cost * (guardDamage or 1)
	return cost
end

function CombatRules.ArmorOf(attack: any): any?
	if not attack then
		return nil
	end
	if attack.Armor then
		return attack.Armor
	end
	if attack.HyperArmor == true then
		return EMPTY_ARMOR
	end
	return nil
end

-- Armor.Start / Armor.End win, then the animation's ArmorStart / ArmorEnd markers, then the whole
-- action (0 .. ActionLength).
function CombatRules.ArmorWindow(attack: any): (number?, number?)
	local armor = CombatRules.ArmorOf(attack)
	if not armor then
		return nil, nil
	end
	local animation = attack.Animation
	local startTime = armor.Start
	if startTime == nil and animation then
		startTime = AnimationLibrary.MarkerTime(animation, "ArmorStart")
	end
	local endTime = armor.End
	if endTime == nil and animation then
		endTime = AnimationLibrary.MarkerTime(animation, "ArmorEnd")
	end
	if endTime == nil and animation then
		endTime = AnimationLibrary.ActionLength(animation)
	end
	return startTime or 0, endTime or math.huge
end

function CombatRules.ArmorActive(attack: any, elapsed: number): boolean
	local startTime, endTime = CombatRules.ArmorWindow(attack)
	if startTime == nil or endTime == nil then
		return false
	end
	return elapsed >= startTime and elapsed <= endTime
end

-- x damage taken while this attack's armor is up (1 when the attack has no armor)
function CombatRules.ArmorDamageTaken(attack: any, pvp: boolean?): number
	local armor = CombatRules.ArmorOf(attack)
	if not armor then
		return 1
	end
	if armor.DamageTaken then
		return armor.DamageTaken
	end
	if pvp then
		return CombatConfig.PvP.ArmorDamageTaken
	end
	return CombatConfig.ArmorDamageTaken
end

--[[
	parts = {
		Base: number,             the hit's damage before modifiers
		LevelMultiplier: number?, class level scaling for player attackers (1 if nil)
		Staggered: boolean?,      the target is staggered -> x CritMultiplier
		CritMultiplier: number?,  the attacker's weapon class value (CombatConfig.CritMultiplier if nil)
		Counter: number?,         CounterMultiplier result (1 if nil)
		ArmorTaken: number?,      ArmorDamageTaken of the TARGET's current attack (1 if nil)
		PvP: boolean?,            player vs player -> x CombatConfig.PvP.DamageMultiplier
	}
	Rounded to 0.1 like DamageService always did.
]]
function CombatRules.HitDamage(parts: any): number
	local amount = parts.Base
	amount = amount * (parts.LevelMultiplier or 1)
	if parts.Staggered then
		amount = amount * (parts.CritMultiplier or CombatConfig.CritMultiplier)
	end
	amount = amount * (parts.Counter or 1)
	amount = amount * (parts.ArmorTaken or 1)
	if parts.PvP then
		amount = amount * CombatConfig.PvP.DamageMultiplier
	end
	return math.floor(amount * 10 + 0.5) / 10
end

-- Longest stun wins: a new stagger never shortens a running one. "Riposted" always takes over
-- the kind (the finisher must hold its target), but still never shortens the stagger.
function CombatRules.StaggerUpdate(currentEnd: number, currentKind: string?, now: number, duration: number, kind: string): (number, string)
	local proposed = now + duration
	if currentEnd <= now or currentKind == nil then
		return proposed, kind
	end
	if kind == "Riposted" then
		return math.max(currentEnd, proposed), kind
	end
	if proposed >= currentEnd then
		return proposed, kind
	end
	return currentEnd, currentKind :: string
end

-- seconds after a stagger ends during which poise can't break into a new full stagger
function CombatRules.StaggerImmunity(pvp: boolean?): number
	if pvp then
		return CombatConfig.PvP.StaggerImmunityTime
	end
	return CombatConfig.StaggerImmunityTime
end

-- Hit reactions (2026-10-09). Both the attacker's client (prediction) and the server (slide + the
-- reaction everyone else sees) call these, so they always agree.
function CombatRules.ArmorTierOf(model: Instance?): string
	if model then
		local tier = model:GetAttribute("ArmorTier")
		if typeof(tier) == "string" and (CombatConfig.ArmorTiers :: any)[tier] then
			return tier
		end
		if string.find(model.Name, "[BOSS]", 1, true) then
			return "Boss"
		end
	end
	return CombatConfig.DefaultArmorTier
end

-- Will this hit break the target's poise? (client prediction from the replicated Poise attribute;
-- the server decides). A poise-breaking hit plays the stagger, so no reaction, slide or step.
function CombatRules.PredictsPoiseBreak(target: Instance?, attack: any): boolean
	if not target then
		return false
	end
	local poise = target:GetAttribute("Poise")
	if typeof(poise) ~= "number" then
		return false
	end
	return poise - ((attack and attack.PoiseDamage) or 0) <= 0
end

function CombatRules.IsFromBehind(victimCFrame: CFrame, attackerPosition: Vector3): boolean
	local look = victimCFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local offset = attackerPosition - victimCFrame.Position
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	if flatLook.Magnitude < 1e-3 or flatOffset.Magnitude < 1e-3 then
		return false
	end
	local dot = math.clamp(flatLook.Unit:Dot(flatOffset.Unit), -1, 1)
	return math.deg(math.acos(dot)) > CombatConfig.HitReaction.BackAngle
end

-- Which reaction a clean (unblocked) hit plays on a non-player target, and how far it slides.
--   Light hits: HitLight<Front|Left|Right|Back> (attack.HitFrom = the side of the VICTIM the blade
--   comes from, default Front; from behind always Back). Heavy hits: HitHeavy<Front|Back>.
--   Armor (the tier's hyper armor during the target's own attack, or a boss's super armor):
--   ArmorTwitch, a small additive shake, and the slide shrinks to ArmoredPushScale.
--   Slide: attack.Knockback (finishers, over KnockbackTime), else attack.Push, else HitPush[Weight].
function CombatRules.HitReaction(attack: any, tierName: string?, targetAttacking: boolean, fromBehind: boolean): (string, number, number, boolean)
	local tiers = CombatConfig.ArmorTiers :: any
	local tier = tiers[tierName or ""] or tiers[CombatConfig.DefaultArmorTier]
	local weight = (attack and attack.Weight) or "Light"
	local armored = tier.AlwaysArmored or (tier.ArmorWhileAttacking and targetAttacking)

	local slide = 0
	local slideTime = CombatConfig.HitPushTime
	if attack and typeof(attack.Knockback) == "number" and attack.Knockback > 0 then
		slide = attack.Knockback
		slideTime = CombatConfig.KnockbackTime
	elseif attack and typeof(attack.Push) == "number" then
		slide = attack.Push
	else
		slide = (CombatConfig.HitPush :: any)[weight] or 0
	end

	if armored then
		return "ArmorTwitch", slide * tier.ArmoredPushScale, slideTime, true
	end
	slide = slide * tier.PushScale
	if weight == "Heavy" then
		return if fromBehind then "HitHeavyBack" else "HitHeavyFront", slide, slideTime, false
	end
	local side = "Front"
	if fromBehind then
		side = "Back"
	elseif attack and (attack.HitFrom == "Left" or attack.HitFrom == "Right") then
		side = attack.HitFrom
	end
	return "HitLight" .. side, slide, slideTime, false
end

-- Attack warp (see CombatConfig "Attack warp"). The server also uses WarpOf to widen its reach check,
-- because it sees the attacker's position a little late.
function CombatRules.WarpOf(attack: any): number
	if attack and typeof(attack.Warp) == "number" then
		return attack.Warp
	end
	return CombatConfig.DefaultWarp
end

-- Travel toward a target `distance` studs away, `angle` degrees off the aim direction: close the gap
-- to WarpStopDistance, scaled down toward the edge of the cone, never more than maxWarp, never back.
function CombatRules.WarpDistance(distance: number, angle: number, maxWarp: number): number
	local gap = distance - CombatConfig.WarpStopDistance
	if gap <= 0 or maxWarp <= 0 then
		return 0
	end
	local edge = math.clamp(angle / CombatConfig.LungeAssistAngle, 0, 1)
	local scale = 1 - (1 - CombatConfig.WarpSideScale) * edge
	return math.min(gap, maxWarp * scale)
end

return CombatRules

