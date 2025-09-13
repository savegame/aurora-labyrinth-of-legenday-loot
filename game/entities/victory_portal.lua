local Common = require("common")
local Vector = require("utils.classes.vector")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local ICON = Vector:new(3, 5)
return function(entity, position)
    entity:addComponent("serializable")
    entity:addComponent("stepinteractive", position)
    entity.stepinteractive.onInteract = function(entity, director)
        Common.playSFX("TELEPORT")
        director:startTurnWithVictory()
    end
    entity:addComponent("sprite")
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite.shadowType = false
    entity.sprite.layer = Tags.LAYER_STEPPABLE
    entity.sprite:setCell(ICON)
    entity.sprite.alwaysVisible = true
    entity:addComponent("charactereffects")
    entity.charactereffects.outlinePulseMin = 0.1
    entity.charactereffects:addOutlinePulseColorSource(COLORS.STANDARD_GHOST:withAlpha(0.5))
    entity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.STANDARD_GHOST)
end

