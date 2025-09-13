return function(entity, position, variantIndex)
    entity:addComponent("serializable", variantIndex)
    entity:addComponent("steppable", position, Tags.STEP_EXCLUSIVE_DEBRIS)
    entity:addComponent("sprite")
    entity.sprite.frameType = Tags.FRAME_STATIC
    entity.sprite:setCell(3 + variantIndex, 10)
    entity.sprite.alwaysVisible = true
    entity.sprite.shadowType = false
    entity.sprite.layer = Tags.LAYER_STEPPABLE
end

