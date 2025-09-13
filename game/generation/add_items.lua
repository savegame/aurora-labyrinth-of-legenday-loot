local Vector = require("utils.classes.vector")
local Set = require("utils.classes.set")
local ItemCreateCommand = require("logic.item_create_command")
local CONSTANTS = require("logic.constants")
local function invalidPosition(level, position)
    return (level.tiles:get(position).isBlocking or level:getObjects():get(position) or level.startPosition == position or (not level.tiles:get(position).isRoom))
end

local function getValidRoomPosition(command, room)
    local level, rng = command.level, command.rng
    local positions = room:getAllPositionsNonDoor()
    positions:rejectSelf(function(position)
        return invalidPosition(level, position)
    end)
    positions:shuffleSelf(rng)
    return positions:minValue(function(a, b)
        local aInvalid = 0
        local bInvalid = 0
        for direction in DIRECTIONS() do
            if invalidPosition(level, a + Vector[direction]) then
                aInvalid = aInvalid + 1
            end

            if invalidPosition(level, b + Vector[direction]) then
                bInvalid = bInvalid + 1
            end

        end

        return aInvalid < bInvalid
    end)
end

local function getScrapPileReward(rng, currentFloor)
    local minValue = floor((currentFloor + 6) * 0.5)
    local maxValue = ceil((currentFloor + 6) * 1.0)
    return rng:random(minValue, maxValue)
end

return function(command)
    local legendaryItem = command.specialFields:get(Tags.FLOOR_LEGENDARY, false)
    local anvils = command.specialFields:get(Tags.FLOOR_ANVIL, 0)
    local takenItems = Set:new()
    takenItems:add(false)
    local currentFloor = command.currentFloor
    local hasHealthShrine = (command.rooms:size() < 5)
    local hasScrapPile = (command.currentFloor == 1)
    local guaranteedSlot = CONSTANTS.GUARANTEED_SLOTS[command.currentFloor]
    local toGuarantee = CONSTANTS.GUARANTEED_SLOTS_COUNT
    if guaranteedSlot == Tags.SLOT_AMULET then
        toGuarantee = CONSTANTS.GUARANTEED_SLOTS_COUNT_AMULET
    end

    local rooms = command.rooms:shuffle(command.rng)
    rooms = rooms:reject(function(room)
        return room.isStart
    end)
    for room in rooms() do
        local position = room.itemHolder
        if not position then
            position = getValidRoomPosition(command, room)
        end

        if position then
                                                if anvils > 0 then
                command.level:setObject(position, "anvil", currentFloor)
                anvils = anvils - 1
            elseif not hasHealthShrine then
                hasHealthShrine = true
                command.level:setObject(position, "destructibles.health_pedestal", currentFloor)
            elseif legendaryItem == "golden_anvil" then
                command.level:setObject(position, "anvil", currentFloor, true)
                legendaryItem = false
            elseif not hasScrapPile then
                hasScrapPile = true
                command.level:setObject(position, "scrap_pile", getScrapPileReward(command.rng, command.currentFloor))
            else
                local itemCommand = ItemCreateCommand:new(currentFloor)
                itemCommand.rollComplex = command.unlockComplex
                if legendaryItem then
                    itemCommand:setItemDefFromID(legendaryItem)
                    itemCommand.modifierDef = itemCommand.itemDef.legendaryMod
                    legendaryItem = false
                    itemCommand:rollUpgradeLevel(command.rng)
                else
                    if guaranteedSlot and toGuarantee > 0 then
                        toGuarantee = toGuarantee - 1
                        itemCommand.itemSlot = guaranteedSlot
                    end

                    while takenItems:contains(itemCommand.itemDef) do
                        itemCommand.itemDef = false
                        itemCommand.modifierDef = false
                        itemCommand.upgradeLevel = false
                        itemCommand:rollMissing(command.rng)
                    end

                end

                takenItems:add(itemCommand.itemDef)
                command.level:setObject(position, "item", itemCommand:create())
            end

        end

    end

end

