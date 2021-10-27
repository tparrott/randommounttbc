local MAJOR, MINOR = "RandomMount-0", 9
local RandomMount = LibStub:NewLibrary(MAJOR, MINOR)

if not RandomMount then
    return -- already loaded and no upgrade necessary
end

-- -------------
-- Configuration
-- -------------

local useSpellMounts = false

-- -------------
-- Internal code
-- -------------

-- item ids for mounts
local slowAndFastGroundItems = { 184865 }
local slowGroundItems = {
    29221, 8632, 28481, 29743, 29744, 8629, 29222, 5656, 2411, 5665, 15277, 5655,
    28927, 29220, 8631, 2414, 33224, 1132, 13331, 8588, 5864, 12327, 5668, 8591,
    13333, 13332, 5872, 15290, 33976, 8592, 12325, 12326, 8595, 5873, 8563,
    13322, 13321, 13325, 37827, 13324, 13323
}
local fastGroundItems = {
    35906, 34129, 19029, 29471, 29472, 19030, 13086, 29468, 29466, 29467, 29469,
    29470, 35513, 33225, 29465, 19902, 18766, 29223, 29745, 18242, 29746, 13335,
    28936, 18902, 29224, 18767, 29747, 37012, 18246, 18790, 18776, 18778, 18797,
    12303, 18789, 18793, 19872, 18798, 13334, 18777, 18791, 29103, 37828, 18245,
    18796, 12302, 18785, 18795, 37719, 29228, 18788, 18248, 18773, 18794, 29229,
    38576, 31830, 13317, 18241, 18772, 18787, 12353, 8586, 31829, 37598, 12330,
    18768, 28915, 18786, 31835, 18247, 29227, 18243, 18244, 12351, 12351, 28482,
    13329, 33977, 12354, 13327, 31832, 13326, 29104, 15293, 15292, 23193, 31831,
    31836, 13328, 18774, 29102, 29105, 29230, 29231, 31833, 31834, 32768, 30480,
    33809
}
local slowFlyingItems = {
    34060, 25470, 25472, 25471, 25474, 25475, 25476, 35225
}
local fastFlyingItems = {
    32458, 34061, 33999, 30609, 34092, 32858, 37676, 32857, 25473, 35226, 32319,
    25533, 32317, 32859, 32860, 25477, 25529, 32316, 32314, 32861, 25527, 32862,
    25531, 32318, 25528, 25532
}
-- mounts that have ground and flying versions (Outlands+Azeroth)
local adaptiveItems = {
	37011
}

-- spell ids for warlock, paladin and druid mounts
local slowGroundSpells = { 5784, 13819, 34769 }
local fastGroundSpells = { 23161, 23214, 34767 }
local slowFlyingSpells = { 33943 }
local fastFlyingSpells = { 40120 }

local RnM_Core = CreateFrame("Frame", "RnM_Core", UIParent)
local RnM_Button = CreateFrame("Button", "RnM_Button", nil, "SecureActionButtonTemplate")

-- known mount spells
local slowGroundSpellbookSpells = {}
local fastGroundSpellbookSpells = {}
local slowFlyingSpellbookSpells = {}
local fastFlyingSpellbookSpells = {}

-- mounts contained in bags
local slowGroundBagItems = {}
local fastGroundBagItems = {}
local slowFlyingBagItems = {}
local fastFlyingBagItems = {}
local adaptiveBagItems = {}

-- total number of mounts
local numMounts = 0
local numSlowGroundMounts = 0
local numFastGroundMounts = 0
local numSlowFlyingMounts = 0
local numFastFlyingMounts = 0
local numAdapativeMounts = 0

-- riding skill
local ridingSkill = 0

local firstScan = true

local function RnM_Contains(table, val)
    local i
    for i=1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

local function RnM_ClearKnownMounts()
    slowGroundSpellbookSpells = {}
    fastGroundSpellbookSpells = {}
    slowFlyingSpellbookSpells = {}
    fastFlyingSpellbookSpells = {}
    slowGroundBagItems = {}
    fastGroundBagItems = {}
    slowFlyingBagItems = {}
    fastFlyingBagItems = {}
	adaptiveBagItems = {}
end

local function RnM_CheckKnownSpells(candidates, known)
    local num = 0
    local name, idx, spell
    for idx, spell in ipairs(candidates) do
        if IsSpellKnown(spell) then
            name = select(1, GetSpellInfo(spell))
            table.insert(known, name)
            num = num + 1
            --print("spell", name)
        end
    end
    return num
end

local function RnM_FindRidingSkill()
    ridingSkill = 0
    local skillIndex, data
    for skillIndex = 1, GetNumSkillLines() do
        data = {GetSkillLineInfo(skillIndex)};
        if data[1] == "Riding" then
            ridingSkill = data[4]
        end
    end
end

local function RnM_Scan()
    RnM_FindRidingSkill()
    RnM_ClearKnownMounts()

    local newNumMounts = 0

    local newNumSlowGroundMounts = 0
    local newNumFastGroundMounts = 0
    local newNumSlowFlyingMounts = 0
    local newNumFastFlyingMounts = 0
	local newNumAdaptiveMounts = 0

    local bag, slot, item, name, itype

    -- check for mounts in bags
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            item = GetContainerItemID(bag, slot)
            if item ~= nil then
                itype = select(3, GetItemInfoInstant(item))
                if (itype == "Mount" or itype == "Devices") and C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bag, slot)) then
                    name = select(1, GetItemInfo(item))
                    if RnM_Contains(slowAndFastGroundItems, item) then
                        -- insert into both slow and fast
                        newNumSlowGroundMounts = newNumSlowGroundMounts + 1
                        newNumFastGroundMounts = newNumFastGroundMounts + 1
                        newNumMounts = newNumMounts + 1
                        table.insert(slowGroundBagItems, name)
                        table.insert(fastGroundBagItems, name)
                    elseif RnM_Contains(slowGroundItems, item) then
                        newNumSlowGroundMounts = newNumSlowGroundMounts + 1
                        newNumMounts = newNumMounts + 1
                        table.insert(slowGroundBagItems, name)
                    elseif RnM_Contains(fastGroundItems, item) then
                        newNumFastGroundMounts = newNumFastGroundMounts + 1
                        newNumMounts = newNumMounts + 1
                        table.insert(fastGroundBagItems, name)
                    elseif RnM_Contains(slowFlyingItems, item) then
                        newNumSlowFlyingMounts = newNumSlowFlyingMounts + 1
                        newNumMounts = newNumMounts + 1
                        table.insert(slowFlyingBagItems, name)
                    elseif RnM_Contains(fastFlyingItems, item) then
                        newNumFastFlyingMounts = newNumFastFlyingMounts + 1
                        newNumMounts = newNumMounts + 1
                        table.insert(fastFlyingBagItems, name)
					elseif RnM_Contains(adaptiveItems, item) then
						newNumAdaptiveMounts = newNumAdaptiveMounts + 1
						newNumMounts = newNumMounts + 1
						table.insert(adaptiveBagItems, name)
                    elseif itype == "Mount" then
                        print("|cffdd1111RandomMount|r |cffff0000Unknown mount, please report a bug with the following information|r", item, name)
                    end
                end
            end
        end
    end

    -- check for mounts in spell book
    if useSpellMounts then
        local numSpellMounts

        numSpellMounts = RnM_CheckKnownSpells(slowGroundSpells, slowGroundSpellbookSpells)
        newNumSlowGroundMounts = newNumSlowGroundMounts + numSpellMounts
        newNumMounts = newNumMounts + numSpellMounts

        numSpellMounts = RnM_CheckKnownSpells(fastGroundSpells, fastGroundSpellbookSpells)
        newNumFastGroundMounts = newNumFastGroundMounts + numSpellMounts + numAdaptiveMounts
        newNumMounts = newNumMounts + numSpellMounts

        numSpellMounts = RnM_CheckKnownSpells(slowFlyingSpells, slowFlyingSpellbookSpells)
        newNumSlowFlyingMounts = newNumSlowFlyingMounts + numSpellMounts
        newNumMounts = newNumMounts + numSpellMounts

        numSpellMounts = RnM_CheckKnownSpells(fastFlyingSpells, fastFlyingSpellbookSpells)
        newNumFastFlyingMounts = newNumFastFlyingMounts + numSpellMounts +numAdaptiveMounts
        newNumMounts = newNumMounts + numSpellMounts
    end

    if firstScan or newNumMounts ~= numMounts then
        numMounts = newNumMounts
        numSlowGroundMounts = newNumSlowGroundMounts
        numFastGroundMounts = newNumFastGroundMounts
        numSlowFlyingMounts = newNumSlowFlyingMounts
        numFastFlyingMounts = newNumFastFlyingMounts
		numAdaptiveMounts = newNumAdaptiveMounts

        firstScan = false
        print("|cffdd1111RandomMount|r", numMounts, "mounts found")
    end
end

local function RnM_OnEvent(self, event, ...)
    local args = {...}
    if event == "PLAYER_ENTERING_WORLD" or event == "BAG_UPDATE" or event == "SPELLS_CHANGED" then
        RnM_Scan()
    elseif event == "SKILL_LINES_CHANGED" then
        RnM_FindRidingSkill()
    end
end

RnM_Core:RegisterEvent("PLAYER_ENTERING_WORLD")
RnM_Core:RegisterEvent("BAG_UPDATE")
RnM_Core:RegisterEvent("SPELLS_CHANGED")
RnM_Core:RegisterEvent("SKILL_LINES_CHANGED")
RnM_Core:SetScript("OnEvent", RnM_OnEvent)

local function RnM_RandomizeMounts(items, spells, adaptive)
    local numItems = #items + #adaptive
    local total = numItems
    if useSpellMounts then
        total = total + #spells
    end
    if total == 0 then
        return false
    end
    local selected = math.random(1, total)
    --print("hey", no, numMounts)
    if selected <= numItems then
        RnM_Button:SetAttribute("type", "item")
        RnM_Button:SetAttribute("item", items[selected])
    else
        RnM_Button:SetAttribute("type", "spell")
        RnM_Button:SetAttribute("spell", spells[selected - numItems])
    end
    return true
end

function RnM_Randomize()
    if UnitAffectingCombat("player") or not IsOutdoors() or numMounts == 0 or ridingSkill == 0 then
        return
    end

    -- do we have the flying skill and is flying available?
    if IsFlyableArea() and ridingSkill > 150 then
        if ridingSkill > 225 and numFastFlyingMounts > 0 then
            -- prefer fast flying mounts
            if RnM_RandomizeMounts(fastFlyingBagItems, fastFlyingSpellbookSpells, adaptiveBagItems) then
                return
            end
        end
        if numSlowFlyingMounts > 0 then
            -- slow flying mount if flying is available
            if RnM_RandomizeMounts(slowFlyingBagItems, slowFlyingSpellbookSpells) then
                return
            end
        end
    end
    if ridingSkill >= 150 and numFastGroundMounts > 0 then
        -- prefer fast ground mounts
        if RnM_RandomizeMounts(fastGroundBagItems, fastGroundSpellbookSpells, adaptiveBagItems) then
            return
        end
    end
    if numSlowGroundMounts > 0 then
        -- slow ground mount
        RnM_RandomizeMounts(slowGroundBagItems, slowGroundSpellbookSpells)
    end
end
