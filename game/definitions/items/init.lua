local ITEMS = {  }
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local RollTable = require("utils.classes.roll_table")
local SUFFIXES = require("definitions.suffixes")
local CONSTANTS = require("logic.constants")
ITEMS.SLOTS = Array:new(Tags.SLOT_WEAPON, Tags.SLOT_GLOVES, Tags.SLOT_HELM, Tags.SLOT_ARMOR, Tags.SLOT_BOOTS, Tags.SLOT_RING, Tags.SLOT_AMULET)
ITEMS.SLOTS_WITH_ABILITIES = ITEMS.SLOTS:subArray(1, 5)
ITEMS.SLOTS_WITH_LEGENDARIES = ITEMS.SLOTS:subArray(1, 6)
ITEMS.BY_SLOT = {  }
for slot in ITEMS.SLOTS() do
    ITEMS.BY_SLOT[slot] = RollTable:new()
end

ITEMS.BY_ID = {  }
local function addItem(filename)
    if DebugOptions.BANNED_ITEMS:contains(filename) then
        return 
    end

    local itemDef = require("definitions.items." .. filename)
    if type(itemDef) ~= "table" then
        Debugger.warn("itemDef missing: " .. filename)
        return 
    end

    itemDef.saveKey = filename
    local itemFrequency = 1
    if DebugOptions.MAKE_ITEMS_FREQUENT:contains(filename) then
        itemFrequency = 100
    end

    if itemDef.minFloor > CONSTANTS.MAX_FLOORS then
        itemFrequency = 0
    end

    itemDef:calculateCostsIfHasPower()
    itemDef:extrapolate()
    ITEMS.BY_SLOT[itemDef.slot]:addResult(itemFrequency, itemDef)
    if itemDef.slot ~= Tags.SLOT_AMULET then
        if itemDef.legendaryMod then
            itemDef.legendaryMod:extrapolate()
        end

        if itemDef.slot ~= Tags.SLOT_RING then
            for modifierDef in (itemDef.suffixTable:getResults())() do
                modifierDef:extrapolate()
            end

            for modifierDef in SUFFIXES.ORDERED() do
                local modFrequency = modifierDef.frequency
                if DebugOptions.MAKE_SUFFIX_FREQUENT then
                    if modifierDef.name:lower() == DebugOptions.MAKE_SUFFIX_FREQUENT:lower() then
                        modFrequency = 1000
                    end

                end

                if itemFrequency > 0 then
                    if modifierDef.canRoll(itemDef) then
                        itemDef.suffixTable:addResult(modFrequency, modifierDef)
                    end

                end

            end

        end

    end

    ITEMS.BY_ID[filename] = itemDef
end

local function addItems(folder)
    local filenames = Array:Convert(filesystem.getDirectoryItems("definitions/items/" .. folder)):map(function(filename)
        return filename:split(".")[1]
    end):stableSort()
    for filename in filenames() do
        addItem(folder .. "." .. filename)
    end

end

addItems("weapons")
addItems("armors")
addItems("helms")
addItems("gloves")
addItems("boots")
addItems("rings")
addItems("amulets")
if DebugOptions.ENABLED then
    require("definitions.items.debug_report")(ITEMS)
end

return ITEMS

