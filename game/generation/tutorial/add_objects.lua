local Vector = require("utils.classes.vector")
local ITEMS = require("definitions.items")
local ItemCreateCommand = require("logic.item_create_command")
local ITEM_1 = "gloves.force_gloves"
local ITEM_2 = "weapons.holy_sword"
local ITEM_3 = "armors.glacial_armor"
return function(command)
    local level = command.level
    local currentFloor = 1
    for position, value in level.objectPositions() do
                                                                                                                        if value == "%" then
            level:setObject(position, "wall_torch", DOWN)
        elseif value == "b" then
            level:setObject(position, "destructibles.pot", currentFloor, 1)
        elseif value == "c" then
            level:setObject(position, "destructibles.bookshelf", currentFloor, command.rng:random(1, 2))
        elseif value == "s" then
            level:setObject(position, "spikes", currentFloor)
        elseif value == "r" then
            level:setObject(position, "rock", 30)
        elseif value == "h" then
            level:setObject(position, "destructibles.health_pedestal", currentFloor)
        elseif value == "w" then
            level:setObject(position, "destructibles.weapon_rack", currentFloor, command.rng:random(1, 2))
        elseif value == "v" then
            level:setObject(position, "anvil", currentFloor)
        elseif value == "e" then
            level:setObject(position, "enemies.rat", RIGHT, "rat", Tags.DIFFICULTY_NORMAL, false, 0)
        elseif value == "f" then
            level:setObject(position, "enemies.goblin", RIGHT, "goblin", Tags.DIFFICULTY_NORMAL, false, 1)
        elseif value == "g" then
            level:setObject(position, "enemies.wolf", RIGHT, "wolf", Tags.DIFFICULTY_NORMAL, false, 0)
        elseif value == "z" then
            level:setObject(position, "enemies.goblin", RIGHT, "goblin", Tags.DIFFICULTY_NORMAL, "HASTE")
        elseif value == "x" then
            level:setObject(position, "stairs_down", RIGHT, command.stairs)
        elseif value == "p" then
            level:setObject(position, "tutorial_proceed")
        elseif value == "i" or value == "j" or value == "k" then
            local itemCommand = ItemCreateCommand:new(1)
                                    if value == "i" then
                itemCommand.itemDef = ITEMS.BY_ID[ITEM_1]
                itemCommand.upgradeLevel = 0
            elseif value == "j" then
                itemCommand.itemDef = ITEMS.BY_ID[ITEM_2]
                itemCommand.upgradeLevel = 0
            elseif value == "k" then
                itemCommand.itemDef = ITEMS.BY_ID[ITEM_3]
                itemCommand.upgradeLevel = 1
            end

            level:setObject(position, "item", itemCommand:create())
        end

    end

end

