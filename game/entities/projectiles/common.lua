return function(entity, position, direction, cell, isMagical)
    entity:addComponent("offset")
    entity.offset.defaultDisableModY = true
    entity:addComponent("actor")
    entity:addComponent("projectile", position, direction)
    entity.projectile.cell = cell
    entity.projectile.isMagical = isMagical
end

