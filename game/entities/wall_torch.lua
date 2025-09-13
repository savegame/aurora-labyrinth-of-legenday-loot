return function(entity, position, direction)
    entity:addComponent("steppable", position)
    entity:addComponent("sprite")
    entity.sprite:setCell(2, 10)
    entity.sprite.shadowType = false
    entity.sprite.alwaysVisible = true
end

