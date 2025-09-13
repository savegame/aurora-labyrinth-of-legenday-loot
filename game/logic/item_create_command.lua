local ItemCreateCommand = class()
local ITEMS = require("definitions.items")
local SUFFIXES = require("definitions.suffixes")
local CONSTANTS = require("logic.constants")
local Hash = require("utils.classes.hash")
local COLORS = require("draw.colors")
local Array = require("utils.classes.array")
local RollTable = require("utils.classes.roll_table")
local ITEMS = require("definitions.items")
local COLORS = require("draw.colors")
local Item = require("structures.item")
local Common = require("common")
local GROWING_STATS = Array:new(Tags.STAT_MAX_HEALTH, Tags.STAT_MAX_MANA, Tags.STAT_ATTACK_DAMAGE_BASE, Tags.STAT_ABILITY_DAMAGE_BASE, Tags.STAT_SECONDARY_DAMAGE_BASE, Tags.STAT_MODIFIER_DAMAGE_BASE)
local DAMAGE_STATS = Array:new(Tags.STAT_ATTACK_DAMAGE_BASE, Tags.STAT_ABILITY_DAMAGE_BASE, Tags.STAT_SECONDARY_DAMAGE_BASE, Tags.STAT_MODIFIER_DAMAGE_BASE)
local FLOAT_STATS = Array:new(Tags.STAT_HEALTH_REGEN, Tags.STAT_MANA_REGEN)
local ItemSlotType = RollTable:new()
ItemSlotType:addResult(1, Tags.SLOT_WEAPON)
ItemSlotType:addResult(1, Tags.SLOT_ARMOR)
ItemSlotType:addResult(1, Tags.SLOT_HELM)
ItemSlotType:addResult(1, Tags.SLOT_GLOVES)
ItemSlotType:addResult(1, Tags.SLOT_BOOTS)
ItemSlotType:addResult(1, Tags.SLOT_RING)
ItemSlotType:addResult(1, Tags.SLOT_AMULET)
for makeFrequentName in DebugOptions.MAKE_ITEMS_FREQUENT() do
    local makeFrequent = ITEMS.BY_ID[makeFrequentName]
    Utils.assert(makeFrequent, "Cannot make non-existent item frequent: %s", makeFrequentName)
    CONSTANTS.ABSOLUTE_MIN_FLOOR[makeFrequent.slot] = 1
    ItemSlotType:addResult(100, makeFrequent.slot)
end

function ItemCreateCommand:initialize(currentFloor)
    self.currentFloor = currentFloor
    self.itemSlot = false
    self.itemDef = false
    self.rollComplex = false
    local MIN_FLOOR = CONSTANTS.MODIFIER_MIN_FLOOR
    if self.currentFloor < MIN_FLOOR then
        self.modifierChance = 0
    else
        local ratio = (self.currentFloor - MIN_FLOOR) / (CONSTANTS.MAX_FLOORS - 1 - MIN_FLOOR)
        self.modifierChance = (CONSTANTS.MODIFIER_CHANCE_HIGHEST - CONSTANTS.MODIFIER_CHANCE_LOWEST) * ratio + CONSTANTS.MODIFIER_CHANCE_LOWEST
    end

    self.modifierDef = false
    self.upgradeLevel = false
    self.bannedModifier = false
end

function ItemCreateCommand:CreateFromData(data)
    local command = ItemCreateCommand:new(1)
    command.itemDef = ITEMS.BY_ID[data.itemDefinition]
        if data.isLegendary then
        command.modifierDef = command.itemDef.legendaryMod
    elseif data.modifier then
        command.modifierDef = SUFFIXES[data.modifier]
    end

    command.upgradeLevel = data.level
    local item = command:create()
    item.scrapSpent = data.scrapSpent
    item.hasBeenSeen = data.hasBeenSeen
    return item
end

function ItemCreateCommand:setItemDefFromID(id)
    self.itemDef = ITEMS.BY_ID[id]
end

function ItemCreateCommand:getRollTableForSlot(rng)
    if self.currentFloor >= CONSTANTS.ABSOLUTE_MIN_FLOOR[self.itemSlot] then
        local rollTable = ITEMS.BY_SLOT[self.itemSlot]
        if not rollTable:isEmpty() then
            return rollTable
        end

    end

    return false
end

function ItemCreateCommand:rollItemSlot(rng)
    while true do
        self.itemSlot = ItemSlotType:roll(rng)
        if self:getRollTableForSlot(rng) then
            return 
        end

    end

end

function ItemCreateCommand:rollItemDef(rng)
    local rollTable = self:getRollTableForSlot(rng)
    if rollTable then
        while true do
            self.itemDef = rollTable:roll(rng)
            if self.currentFloor >= self.itemDef.minFloor then
                if not self.itemDef.isComplex or self.rollComplex then
                    break
                end

            end

        end

    end

end

function ItemCreateCommand:rollModifier(rng)
    local itemDef = self.itemDef
    if itemDef.slot == Tags.SLOT_RING or itemDef.slot == Tags.SLOT_AMULET then
        return 
    end

    if rng:random() < self.modifierChance or self.modifierChance >= 1 then
        local tries = 0
        while not itemDef.suffixTable:isEmpty() and tries < 200 do
            self.modifierDef = itemDef.suffixTable:roll(rng)
            if (self.modifierDef ~= self.bannedModifier and self.currentFloor >= self.modifierDef.minFloor) then
                break
            end

        end

    end

end

local UPGRADE_LOWEST_MIN = CONSTANTS.UPGRADE_LOWEST_MIN
local UPGRADE_LOWEST_MAX = CONSTANTS.UPGRADE_LOWEST_MAX
local UPGRADE_HIGHEST_MIN = CONSTANTS.UPGRADE_HIGHEST_MIN
local UPGRADE_HIGHEST_MAX = CONSTANTS.UPGRADE_HIGHEST_MAX
function ItemCreateCommand:rollUpgradeLevel(rng)
    if self.currentFloor == 1 then
        self.upgradeLevel = 0
    else
        local ratio = (self.currentFloor - 2) / (CONSTANTS.MAX_FLOORS - 3)
        local minValue = (UPGRADE_HIGHEST_MIN - UPGRADE_LOWEST_MIN) * ratio + UPGRADE_LOWEST_MIN
        local maxValue = (UPGRADE_HIGHEST_MAX - UPGRADE_LOWEST_MAX) * ratio + UPGRADE_LOWEST_MAX
        self.upgradeLevel = rng:random() * (maxValue - minValue) + minValue
        if rng:random() < self.upgradeLevel % 1 then
            self.upgradeLevel = floor(self.upgradeLevel) + 1
        else
            self.upgradeLevel = floor(self.upgradeLevel)
        end

    end

end

function ItemCreateCommand:rollMissing(rng)
    if not self.itemDef then
        if not self.itemSlot then
            self:rollItemSlot(rng)
        end

        self:rollItemDef(rng)
    end

    if not self.modifierDef then
        if DebugOptions.ALL_LOOT_LEGENDARY and self.itemDef.legendaryMod then
            self.modifierDef = self.itemDef.legendaryMod
        else
            self:rollModifier(rng)
        end

    end

    if not self.upgradeLevel and not self.itemDef.disableUpgrade then
        self:rollUpgradeLevel(rng)
    end

end

function ItemCreateCommand:applyModifier(item)
    local modifierDef = self.modifierDef
    item.modifierDef = modifierDef
    for stat, value in modifierDef.statsBase() do
        item.stats:add(stat, value, 0)
    end

    if modifierDef.isLegendary then
        item.name = modifierDef.name
        if item:getSlot() == Tags.SLOT_AMULET then
            item.labelColor = COLORS.ITEM_LABEL.LEGENDARY_AMULET
        else
            item.labelColor = COLORS.ITEM_LABEL.LEGENDARY
        end

    else
        item.name = item.name .. " of " .. modifierDef.name
        item.labelColor = COLORS.ITEM_LABEL.ENCHANTED
    end

    Utils.assert(item.level == 0, "Cannot modify an upgraded item")
    modifierDef.modifyItem(item)
    return item
end

function ItemCreateCommand:create()
    local itemDef = self.itemDef
    local item = Item:new(itemDef)
    item.stats = itemDef.statsBase:clone()
    item.name = itemDef.name
    item.extraCostLine = itemDef.extraCostLine
    item.labelColor = COLORS.ITEM_LABEL.NORMAL
    item.triggers = itemDef.triggers:clone()
    if itemDef.onEquip then
        item.onEquipCallbacks:push(itemDef.onEquip)
    end

    if itemDef.onUnequip then
        item.onUnequipCallbacks:push(itemDef.onUnequip)
    end

    item.scrapCost = CONSTANTS.SCRAP_COST_BASE
        if itemDef.slot == Tags.SLOT_AMULET then
        item.labelColor = COLORS.ITEM_LABEL.CLASS_ACCESSORY
        item.scrapCost = CONSTANTS.SCRAP_COST_BASE_ACCESSORY
    elseif itemDef.slot == Tags.SLOT_RING then
        item.labelColor = COLORS.ITEM_LABEL.ACCESSORY
        item.scrapCost = CONSTANTS.SCRAP_COST_BASE_ACCESSORY
    end

    if self.modifierDef then
        self:applyModifier(item)
    end

    if self.itemDef.postCreate then
        self.itemDef.postCreate(item)
    end

    item.stats = item.stats:mapValues(function(value, key)
        if FLOAT_STATS:contains(key) then
            return value
        else
            return round(value)
        end

    end)
    item.stats:set(Tags.STAT_SLOT, item:getSlot())
    if not itemDef.disableUpgrade then
        for i = 1, self.upgradeLevel do
            item:upgrade()
        end

    end

    return item
end

return ItemCreateCommand

