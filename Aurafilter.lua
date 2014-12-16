--[[--------------------------------------------------------------------
	Credits to Phanx for this aura filter.
	(Phanx < addons@phanx.net >)
--]]--------------------------------------------------------------------

local _, ns = ...
local _, playerClass, classId = UnitClass("player")

local isPhysicalUser = ns.MultiCheck(classId, 1, 2, 3, 4, 6, 7, 10, 11)
local isSpellUser = ns.MultiCheck(classId, 5, 7, 8, 9, 11)

--[[ Default Aura Filter ]]
local BaseAuras = {
	-- Useless
	[63501] = 3, -- Argent Crusade Champion's Pennant
	[60023] = 3, -- Scourge Banner Aura (Boneguard Commander in Icecrown)
	[63406] = 3, -- Darnassus Champion's Pennant
	[63405] = 3, -- Darnassus Valiant's Pennant
	[63423] = 3, -- Exodar Champion's Pennant
	[63422] = 3, -- Exodar Valiant's Pennant
	[63396] = 3, -- Gnomeregan Champion's Pennant
	[63395] = 3, -- Gnomeregan Valiant's Pennant
	[63427] = 3, -- Ironforge Champion's Pennant
	[63426] = 3, -- Ironforge Valiant's Pennant
	[63433] = 3, -- Orgrimmar Champion's Pennant
	[63432] = 3, -- Orgrimmar Valiant's Pennant
	[63399] = 3, -- Sen'jin Champion's Pennant
	[63398] = 3, -- Sen'jin Valiant's Pennant
	[63403] = 3, -- Silvermoon Champion's Pennant
	[63402] = 3, -- Silvermoon Valiant's Pennant
	[62594] = 3, -- Stormwind Champion's Pennant
	[62596] = 3, -- Stormwind Valiant's Pennant
	[63436] = 3, -- Thunder Bluff Champion's Pennant
	[63435] = 3, -- Thunder Bluff Valiant's Pennant
	[63430] = 3, -- Undercity Champion's Pennant
	[63429] = 3, -- Undercity Valiant's Pennant
}

do
	local l = ns.AuraList
	for _, list in pairs({l.Stun, l.CC, l.Silence, l.Taunt}) do
		for i = 1, #list do
			BaseAuras[list[i]] = 0
		end
	end
end

------------------------------------------------------------------------
--	Magic Vulnerability

if isSpellUser then
	BaseAuras[1490]  = 0 -- Curse of the Elements (warlock)
	BaseAuras[34889] = 0 -- Fire Breath (hunter dragonhawk)
	BaseAuras[24844] = 0 -- Lightning Breath (hunter wind serpent)
	BaseAuras[93068] = 0 -- Master Poisoner (rogue)
end

------------------------------------------------------------------------
--	Physical Vulnerability

if isPhysicalUser then
	BaseAuras[55749] = 0 -- Acid Rain (hunter worm)
	BaseAuras[35290] = 0 -- Gore (hunter boar)
--	BaseAuras[81326] = 0 -- Physical Vulnerability (death knight, paladin, warrior)
	BaseAuras[50518] = 0 -- Ravage (hunter ravager)
	BaseAuras[57386] = 0 -- Stampede (hunter rhino)
	BaseAuras[113746]= 0 -- Weakened Armor
	BaseAuras[64382] = 0 -- Shattering Throw
end


------------------------------------------------------------------------

local genFilter, arenaFilter, bossFilter = {}, {}, {}
local auraFilters = {genFilter, arenaFilter, bossFilter}

function oUFAbu:UpdateAuraLists()
	--wipe em
	for _,list in ipairs(auraFilters) do
		wipe(list)
	end
	-- General Filter - These don't show in the aura editor
	for aura, filter in pairs(BaseAuras) do
		genFilter[aura] = filter
	end
	for aura, filter in pairs(oUFAbu:GetAuraSettings()['general']) do
		genFilter[aura] = filter
	end
	--	Arena Filter
	for aura, filter in pairs(oUFAbu:GetAuraSettings()['arena']) do
		arenaFilter[aura] = filter
	end
	-- Boss Filter
	for aura, filter in pairs(oUFAbu:GetAuraSettings()['boss']) do
		bossFilter[aura] = filter
	end
	
	for _, obj in pairs(oUF.objects) do
		if obj.Auras then
			obj.Auras:ForceUpdate()
		end
		if obj.Buffs then
			obj.Buffs:ForceUpdate()
		end
		if obj.Debuffs then
			obj.Debuffs:ForceUpdate()
		end
	end
end

--[[--------------------------------------------------------------------
Filters:
	General (both):	On Players:Show all
	'Blacklist'			0	 = Show All (override default)
						1 	 = Show only mine
						2 	 = Hide on friendly
						3 	 = Hide all
					On NPC's:  Show only mine
						0	 = Show Always ( Even when not Mine )
						1 	 = Show only mine - no effect.
						2 	 = Hide on friendly
						3 	 = Hide Mine

	Arena (buff):	true = whitelisted
	'Whitelist'

	Boss (debuff):	0	 = Whitelisted
	'Whitelist'		1 	 = Only show own
--]]-------------------------------------------------------------------

local IsInInstance, UnitCanAttack, UnitIsFriend, UnitIsUnit, UnitPlayerControlled, UnitIsPlayer
	= IsInInstance, UnitCanAttack, UnitIsFriend, UnitIsUnit, UnitPlayerControlled, UnitIsPlayer

local isPlayer = { player = true, pet = true, vehicle = true }

local filters = {
	[0] = function(self, unit, caster) return true end,--
	[1] = function(self, unit, caster) return isPlayer[caster] end,--
	[2] = function(self, unit, caster) return UnitCanAttack("player", unit) end, 
	[3] = function(self, unit, caster) return false end,						
}

ns.CustomAuraFilters = {
	pet = function(self, unit, iconFrame, name, rank, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, ...)
		return (caster and isPlayer[caster]) and (not genFilter[spellId] == 3)
	end,
	target = function(self, unit, iconFrame, name, rank, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, ...)
		local v = genFilter[spellId]
		if v and filters[v] then 					-- [[ In Filters ]]--
			return filters[v](self, unit, caster)
		elseif UnitPlayerControlled(unit) then 		-- [[	Player   ]]--
			if UnitCanAttack("player", unit) then 	-- [[   Hostile  ]]--
				return true
			else 									-- [[  Friendly  ]]--
				return (not shouldConsolidate) or (canApplyAura)
			end
		else 										-- [[ 	NPC 	 ]]--
			-- Always show BUFFS, Show boss debuffs, aura cast by the unit, or auras cast by the player's vehicle.
			return (iconFrame.filter == "HELPFUL") or (isBossDebuff) or (isPlayer[caster]) or (caster == unit) 
		end
	end,
	party = function(self, unit, iconFrame, name, rank, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, ...)
		local v = genFilter[spellId]
		return v and v ~= 3 or true
	end,
	arena = function(self, unit, iconFrame, name, rank, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, ...)
		return arenaFilter[spellId]
	end,
	boss = function(self, unit, iconFrame, name, rank, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, ...)
		local v = bossFilter[spellId]
		if v == 1 then
			return isPlayer[caster]
		elseif v == 0 then
			return true
		else
			return isBossDebuff
		end
	end,
}