AdvancedTooltips = LibStub("AceAddon-3.0"):NewAddon("AdvancedTooltips", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local libS = LibStub("AceSerializer-3.0")
local libC = LibStub("LibCompress")
local lwin = LibStub("LibWindow-1.1")
local libCE = libC:GetAddonEncodeTable()
local LSM = LibStub("LibSharedMedia-3.0")

ReoriginationArray_Weekly = {}
ReoriginationArray_Weekly[1] = 53568
ReoriginationArray_Weekly[2] = 53569
ReoriginationArray_Weekly[3] = 53570

ReoriginationArray_Stacks = {}
ReoriginationArray_Stacks[1] = 53571
ReoriginationArray_Stacks[2] = 53572
ReoriginationArray_Stacks[3] = 53573
ReoriginationArray_Stacks[4] = 53574
ReoriginationArray_Stacks[5] = 53575
ReoriginationArray_Stacks[6] = 53576
ReoriginationArray_Stacks[7] = 53577
ReoriginationArray_Stacks[8] = 53578
ReoriginationArray_Stacks[9] = 53579
ReoriginationArray_Stacks[10] = 53580

stats = {}
stats[9] = "Critical Strike"
stats[18] = "Haste"
stats[26] = "Mastery"
stats[29] = "Versatility"

tertiary_stats = {}
tertiary_stats[21] = "Avoidance"
tertiary_stats[17] = "Leech"
tertiary_stats[14] = "Speed"


ReoriginationArray_Descriptions = {}
ReoriginationArray_Descriptions[0] = "Reorigination Array Hidden Quest completed for this week."
ReoriginationArray_Descriptions[1] = "Defeat 1 more boss in Uldir this week."
ReoriginationArray_Descriptions[2] = "Defeat 2 more bosses in Uldir this week."
ReoriginationArray_Descriptions[3] = "Defeat 3 more bosses in Uldir this week."

E_CHANCE = 1
E_RPPM = 2
E_NAME = 3
E_ICD = 4
E_AZERITE_POWER = 5
E_SPELLID = 6

-----------------
-- Addon Setup --
-----------------c

local AdvancedTooltips_Version = "1.0.0"

local configDefaults = {
	randomType = true
}

function AdvancedTooltips:GetConfig(key)
	if AdvancedTooltips_Config[key] == nil then
		return configDefaults[key]
	else
		return AdvancedTooltips_Config[key]
	end
end

function AdvancedTooltips:SetConfig(key, value)
	if configDefaults[key] == value then
		AdvancedTooltips_Config[key] = nil
	else
		AdvancedTooltips_Config[key] = value
	end
end

function AdvancedTooltips:RestoreDefaults()
	AdvancedTooltips_Config = {}
	self:UpdateMedia()
	self:UpdateDisplayed()
	LibStub("AceConfigRegistry-3.0"):NotifyChange("AdvancedTooltips")
end

local blizOptionsPanel
function AdvancedTooltips:OnInitialize()
	if AdvancedTooltips_State == nil then
		AdvancedTooltips_State = {  }
	end
	if AdvancedTooltips_Config == nil then AdvancedTooltips_Config = { } end

	local ver = AdvancedTooltips_Version
	if ver:sub(1,1) == "@" then ver = "dev" end
	
	local options = {
		name = "Advanced Tooltips "..ver,
		handler = AdvancedTooltips,
		type = "group",
		args = {
			RandomType = {
				type = "toggle",
				order = 1,
				name = "RandomType",
				desc = "Enables / Disables the showing of the type of a random effect.",
				set = function(info,val) AdvancedTooltips_Config.randomType = val end,
				get = function(inf0) return AdvancedTooltips_Config.randomType end
			},
			help = {
				type = "execute",
				order = 99,
				name = "Help",
				hidden = true,
				func = function()
					LibStub("AceConfigCmd-3.0").HandleCommand(self, "att", "AdvancedTooltips", "")
				end
			},
		}
	}

	self:RegisterChatCommand("att", "ChatCommand")
	LibStub("AceConfig-3.0"):RegisterOptionsTable("AdvancedTooltips", options)

	-- Fill in reorigination array quest text
end

function AdvancedTooltips:ChatCommand(input)
	LibStub("AceConfigCmd-3.0").HandleCommand(self, "att", "AdvancedTooltips", input)
	print(AdvancedTooltips_Config.randomType)
end

function linkToID(itemLink)
	local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	return tonumber(Id)
end

function itemEnchant(itemLink)
	local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	return tonumber(Enchant)
end

local function ProcessItem(itemLink, tooltip)

	if itemLink == nil then return end

    local id = linkToID(itemLink)

    bonusLine = false

    if AdvancedTooltips.Items[id] ~= nil then
        item = AdvancedTooltips.Items[id]
		-- Check each spell possability
		for i=1, 5, 1 do
			-- See if we have info for this item
			if item[i] ~= nil and item[i][E_CHANCE] ~= nil then
				-- Add a spacing line
				if bonusLine == false then
					tooltip:AddLine(" ")
					bonusLine = true
                end
                local strLeft = ""

                -- If we have a spell ID, get the info from the api
                -- otherwise fall back to whatever simc described.
                if item[i][E_SPELLID] ~= nil then
                    strLeft = select(1, GetSpellInfo(item[i][E_SPELLID]))
                else
                    strLeft = item[i][E_NAME]
                end
				local strRight = ""

				-- Check for RPPM
				if item[i][E_RPPM] == 1 then
					strRight = strRight..string.format("RPPM: %.2f (%.2f)", item[i][E_CHANCE], item[i][E_CHANCE] * (1 + UnitSpellHaste("player")/100))
				else
					strRight = strRight..string.format("%.2f%%", item[i][E_CHANCE])
				end
                tooltip:AddDoubleLine(strLeft, strRight, 0, .7, .7, 0, .7, .7)
                if item[i][E_ICD] ~= 0 then
                    tooltip:AddDoubleLine(" ", string.format(" %.1f second ICD", item[i][E_ICD] / 1000), 0, .7, .7, 0, .7, .7)
                end
			end
		end
	end

	-- Heart of Azeroth
	if id == 158075 then
		tooltip:AddLine(" ")
    
        local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
        if azeriteItemLocation ~= nil then
            local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
            
            tooltip:AddDoubleLine("Rank",C_AzeriteItem.GetPowerLevel(azeriteItemLocation), 0,.7,.7,0,.7,.7)
            tooltip:AddDoubleLine("Progress",string.format("%d/%d (%.2f%%)", xp, totalLevelXP, xp/totalLevelXP*100), 0,.7,.7,0,.7,.7)
        end
	end
end

function alreadyAdded(str1, tooltip)
	if str1 == nil then
		return false
	end

	for i = 1,15 do
		local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
		local textRight = _G[tooltip:GetName().."TextRight"..i]
		local text
		local right
		if frame then text = frame:GetText() end
		if text and string.find(text, str1, 1, true) then return true end
		if textRight then right = textRight:GetText() end
		if right and string.find(right, str1, 1, true) then return true end
	  end
end



function AddReoriginationInfo(tooltip)
	tooltip:AddLine(" ")
	-- Check the status of the reorigination count.
	ReoriginationLevel = 10
	while ReoriginationLevel > 0 and IsQuestFlaggedCompleted(ReoriginationArray_Stacks[ReoriginationLevel]) == false  do
		ReoriginationLevel = ReoriginationLevel - 1
	end

	tooltip:AddDoubleLine("Reorigination Stacks: ", ReoriginationLevel.."/10", 0, .7, .7, 0, .7, .7)

	if ReoriginationLevel ~= 10 then
		local WeeklyKills = 3
		while WeeklyKills ~= 0 and IsQuestFlaggedCompleted(ReoriginationArray_Weekly[WeeklyKills]) == false do
			WeeklyKills = WeeklyKills - 1
		end

		-- 0 = Red
		-- 1 or 2 = Yellow
		-- 3 = Green

		colorString = ""
		if WeeklyKills == 0 then
			colorString = "|cffff0000"
		elseif WeeklyKills ~= 3 then
			colorString = "|cffffff00"
		else
			colorString = "|cff00ff00"
		end

		tooltip:AddDoubleLine("Weekly: ", colorString..WeeklyKills.."/3", 0, .7, .7, 0, .7, .7)
	else
		tooltip:AddDoubleLine("Weekly", "|cff00ff00Max", 0, .7, .7, 0, .7, .7)
	end

	-- Grab the secondary stats to give the benefit
	local stat_values = {}
	for i, v in pairs(stats) do
		stat_values[i] = GetCombatRating(i)
    end
    
	-- find the largest
	largest = 9
	for i,v in pairs(stat_values) do
		if stat_values[largest] < stat_values[i] then
			largest = i
		end
	end

    tooltip:AddDoubleLine("Bonus: ", 75 * ReoriginationLevel.." "..stats[largest], 0, .7, .7, 0, .7, .7)
    
    -- Check for Vantus:
    UldirVantus = false
    for i=1, 40, 1 do
        local name = UnitBuff("player", i)
        -- @ todo - localization
        if name ~= nil and string.find(name, "Vantus Rune") then 
            UldirVantus = true
        end
    end

    if UldirVantus == true then
        stat_values[29] = stat_values[29] + 277
        -- Rerun the stat weight calculations with the +277 vers
        largest = 9
        for i,v in pairs(stat_values) do
            if stat_values[largest] < stat_values[i] then
                largest = i
            end
        end

        tooltip:AddDoubleLine("Bonus (Vantus): ", 75 * ReoriginationLevel.." "..stats[largest], 0, .7, .7, 0, .7, .7)
        
    end
end



function GetSpellChanceInfo(rank)
	if AdvancedTooltips.SpellData[rank] == nil then return nil end

	str = ""
	str2 = ""

    data = AdvancedTooltips.SpellData[rank]

	if data[E_CHANCE] ~= nil and data[E_CHANCE] < 100.0 then
		str = select(1, GetSpellInfo(rank))
		if data[E_RPPM] == 1 then
			str2 = "RPPM: "..string.format("%.2f", data[E_CHANCE])

			-- Get haste % to calc "actual" rppm
			local actualRPPM = data[E_CHANCE] * (1 + UnitSpellHaste("player")/100)
			local actualRPPMString = string.format("%.2f", actualRPPM)
			str2 = str2.." ("..actualRPPMString..")"
		else
			str2 = string.format("%.2f%%", data[E_CHANCE])
		end
	end

	itemData = {}
	itemData["proc_name"] = str
    itemData["proc_info"] = str2
    if data[E_ICD] ~= nil and data[E_ICD] ~= 0 then
        itemData["proc_icd"] = string.format("%.1f second ICD", data[E_ICD]/1000)
    else
        itemData["proc_icd"] = ""
    end

	-- 274441 - Barbed Shot has a chance equal to your critical strike chance to grant you 298 Agility for 8 sec.
    if rank == 274441 then
        itemData["proc_name"] = select(1, GetSpellInfo(rank)) 
        itemData["proc_info"] = string.format("%.2f%%", GetCritChance())
	end

	return itemData

end

function AppendStatInfo(frame, frame_text, stat_value, stat_type, stat_name)
	
	-- Note, GetItemStats is NOT used here. This function is useful,
	--but it would be nice to add stat info for Gems and Enchants!

	local stat_array = {
		[9] = AdvancedTooltips.crit_scaling,
		[14] = AdvancedTooltips.speed_scaling,
		[17] = AdvancedTooltips.leech_scaling,
		[18] = AdvancedTooltips.haste_scaling,
		[21] = AdvancedTooltips.avoidance_scaling,
		[26] = AdvancedTooltips.mastery_scaling,
		[29] = AdvancedTooltips.vers_damage_scaling
	}

	rating_coef = stat_array[stat_type][UnitLevel("player")]

	if stat_value == nil then return end

	if stat_type == 26 then
		-- Mastery, special
		mastery = stat_value / rating_coef
		mastery = mastery * select(2, GetMasteryEffect())
		s = string.gsub(frame_text, stat_value.." "..stat_name, string.format("%d %s |cff00b3b3(%.2f%%%%)|r", stat_value, stat_name, mastery))
		s2 = string.gsub(s, stat_name.." by "..stat_value, string.format("%s by %d |cff00b3b3(%.2f%%%%)|r", stat_name, stat_value, mastery))
		frame:SetText(s2)
	else
		s = string.gsub(frame_text, stat_value.." "..stat_name, string.format("%d %s |cff00b3b3(%.2f%%%%)|r", stat_value, stat_name, stat_value / rating_coef))
		s2 = string.gsub(s, stat_name.." by "..stat_value, string.format("%s by %d |cff00b3b3(%.2f%%%%)|r", stat_name, stat_value, stat_value / rating_coef))
		frame:SetText(s2)
	end

end

function scanStats(tooltip)

	for i = 1,15 do
		local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
		local text
		local right
		if frame then text = frame:GetText() end
		if text then
			-- Check Primary Stats, then tertiary
			for k,v in pairs(stats) do
				sdata = string.match(text, "(%d+) "..v)
				if sdata ~= nil then
					AppendStatInfo(frame, text, tonumber(sdata), k, v)
				end

				sdata = string.match(text, v.." by ".."(%d+)")
				if sdata ~= nil then
					AppendStatInfo(frame, text, tonumber(sdata), k, v)
				end

			end

			for k,v in pairs(tertiary_stats) do
				sdata = string.match(text, "(%d+) "..v)
				if sdata ~= nil then
					AppendStatInfo(frame, text, tonumber(sdata), k, v)
				end

				sdata = string.match(text, v.." by ".."(%d+)")
				if sdata ~= nil then
					AppendStatInfo(frame, text, tonumber(sdata), k, v)
				end
			end
		end
	  end
end

function SpellTooltip(rank, tooltip)
	str = ""
	str2 = ""
	if AdvancedTooltips.SpellData[rank] ~= nil then
		local str = GetSpellChanceInfo(rank)["proc_name"]
        local str2 = GetSpellChanceInfo(rank)["proc_info"]
        local str3 = GetSpellChanceInfo(rank)["proc_icd"]
		
		-- work around the talent bug (calls OnSetTooltipSpell twice)
        if str2 ~= "" and alreadyAdded(str2, tooltip) then
			return
		elseif str3 ~= "" and alreadyAdded(str3, tooltip) then
			return
		end

		-- Seperator line, only if we're adding information
		-- don't return here so we can bring in reorigination array below (archive has no proc)
		if (str2~= "" or str3~="") then tooltip:AddLine(" ") end

		if str2 ~= "" then
			tooltip:AddDoubleLine(str, str2, 0, .7, .7, 0, .7, .7)
        end
        
        if str3 ~= "" then
            tooltip:AddDoubleLine(" ", str3, 0, .7, .7, 0, .7, .7)
        end
	end
	
	-- Archive and Laser Matrix
	if rank == 280555 or rank == 280559 then
		AddReoriginationInfo(tooltip)
	end

	-- Try collecting stats
	scanStats(tooltip)
end


function GetAzeriteSpellID(powerID)
	local powerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(powerID)
  	if (powerInfo) then
    	local azeriteSpellID = powerInfo["spellID"]
    	return azeriteSpellID
  	end
end



function ScanForTrait(tooltip, powerName)
	-- AzeriteTooltip replaces the tooltip.
	-- Depending on the order of events (and I have NO idea of the order)
	-- we will get called either first or second, so we need to check for BOTH
	-- forms of the trait.
	-- |cFF00FF00 |T2000853::20:20:0:0:64:64:4:60:4:60|t {Name}|r
	-- is what we're looking for. We will gsub their
	-- \124 characters to \124\124
	local atooltipPattern = "||cFF00FF00%s-||T%d-:20:20:0:0:64:64:4:60:4:60||t%s-"..powerName.."||r"
	for i = 8, tooltip:NumLines() do
		local left = _G[tooltip:GetName().."TextLeft"..i]
		local text = left:GetText()
		if text ~= nil then
			local isATP = gsub(text, "\124", "\124\124"):match("||T%d+") ~= nil
			if text:find(powerName) and isATP == false then
				return true
			elseif gsub(text, "\124", "\124\124"):match(atooltipPattern, 1) then
				return true
			end
		end
    end
end

function AddEnchantInfo(tooltip, itemHeaderAdded, spellID)
	spellData = GetSpellChanceInfo(spellID)
	if spellData ~= nil then
		if itemHeaderAdded == false then
			tooltip:AddLine(" ")
        end
        -- Remove (DND) from some enchant strings.
        tooltip:AddDoubleLine(gsub(spellData["proc_name"], "%(DND%)", ""), spellData["proc_info"], 0, .7, .7, 0, .7, .7)
        if spellData["proc_icd"] ~= "" then
            tooltip:AddDoubleLine(" ", spellData["proc_icd"], 0, .7, .7, 0, .7, .7)
        end
	end
end



function OnTooltip_Item(self, tooltip)
	local isUldirItem = false
	local itemHeaderAdded = false

	local name,link = self:GetItem()

	if link == nil then
		sn,sid = self:GetSpell()
		if sid ~= nil and sid ~= 0 then
			AddEnchantInfo(tooltip, itemHeaderAdded, sid)
		end
		return
	end

	ProcessItem(link, tooltip)

	-- Azerite check
	if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(linkToID(link)) then
        local tierInfo = C_AzeriteEmpoweredItem.GetAllTierInfoByItemID(link, select(3, UnitClass("player")))
        for i=1,4,1 do
            if tierInfo[i] ~= nil then
                for k,v in pairs(tierInfo[i]["azeritePowerIDs"]) do
                    if ScanForTrait(self, select(1, GetSpellInfo(GetAzeriteSpellID(v)))) then
						local spellInfo = GetSpellChanceInfo(GetAzeriteSpellID(v))
						if spellInfo ~= nil then
							-- If we have strings
							if spellInfo["proc_name"] ~= nil and string.len(spellInfo["proc_name"]) > 0 then
								if itemHeaderAdded == false then
									tooltip:AddLine(" ")
									itemHeaderAdded = true
								end
                                tooltip:AddDoubleLine(spellInfo["proc_name"], spellInfo["proc_info"], 0, .7, .7, 0, .7, .7)
							end
						end
					end

					-- Check for Laser Matrix or Archive
					if i == 1 and (v == 485 or v == 483) then
						isUldirItem = true
					end
				end
			end
		end
	end

	if isUldirItem then
		-- Laser matrix or Archive...
		AddReoriginationInfo(tooltip)
	end


	-- Weapon Enchant
	if itemEnchant(link) ~= nil and itemEnchant(link) ~= 0 then
		if AdvancedTooltips.EnchantData[itemEnchant(link)] ~= nil then
			AddEnchantInfo(tooltip, itemHeaderAdded, AdvancedTooltips.EnchantData[itemEnchant(link)])
		end
    end

	-- Logic for looking at weapon enchants items
	if AdvancedTooltips.BackupData[linkToID(link)] ~= nil then
		AddEnchantInfo(tooltip, itemHeaderAdded, AdvancedTooltips.EnchantData[AdvancedTooltips.BackupData[linkToID(link)]])
	end

	-- collect stat data
	scanStats(tooltip)

	tooltip:Show()
end

function OnTooltipSpell(self, tooltip)
	-- Case for linked spell
	local name,rank,id = self:GetSpell()
	if rank ~= nil then
		SpellTooltip(rank, tooltip)
	end
	tooltip:Show()
end


function AdvancedTooltips:OnEnable()
	GameTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltip_Item(..., GameTooltip) end)
	ItemRefTooltip:HookScript("OnTooltipSetItem", function(...) OnTooltip_Item(..., ItemRefTooltip) end)
	ShoppingTooltip1:HookScript("OnTooltipSetItem", function(...) OnTooltip_Item(..., ShoppingTooltip1) end)
	ShoppingTooltip2:HookScript("OnTooltipSetItem", function(...) OnTooltip_Item(..., ShoppingTooltip2) end)
	GameTooltip:HookScript("OnTooltipSetSpell", function(...) OnTooltipSpell(..., GameTooltip) end)
	ItemRefTooltip:HookScript("OnTooltipSetSpell", function(...) OnTooltipSpell(..., ItemRefTooltip) end)
	WorldMapTooltip.ItemTooltip.Tooltip:HookScript('OnTooltipSetItem', function(...) OnTooltip_Item(..., WorldMapTooltip.ItemTooltip.Tooltip) end)
end

function AdvancedTooltips:AfterEnable()

end