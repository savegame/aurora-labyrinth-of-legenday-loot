local ScreenGameLoading = require("screens.game_loading")
local Global = require("global")
local FLOORS = require("definitions.floors")
return function(entity, position, direction, cell)
    entity:addComponent("stepinteractive", position)
    entity.stepinteractive.onInteract = function(entity, director)
        local player = director:getPlayer()
        if player.tank:isAlive() then
            local currentBGM = FLOORS[director.currentFloor].bgm
            Global:get(Tags.GLOBAL_CURRENT_RUN):increaseFloor()
            if director.currentFloor > 0 then
                player.equipment:recordStairs()
                Global:get(Tags.GLOBAL_PROFILE):saveItemStats()
            end

            if currentBGM ~= FLOORS[director.currentFloor + 1].bgm then
                Global:get(Tags.GLOBAL_AUDIO):fadeoutCurrentBGM()
            end

            director:screenTransition(ScreenGameLoading, false, player.equipment.equipped, player.wallet:get())
        end

    end
    entity:addComponent("sprite")
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite.shadowType = false
    entity.sprite.layer = Tags.LAYER_STEPPABLE
    entity.sprite:setCell(cell)
    entity.sprite:turnToDirection(direction)
    entity.sprite.alwaysVisible = true
    entity:addComponent("indicator", "STAIRS")
end

