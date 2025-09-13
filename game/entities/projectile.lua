local Vector = require("utils.classes.vector")
local Entity = require("entities.entity")
return function(entity, position, direction)
    entity:addComponent("serializable", direction)
    entity:addComponent("offset")
    entity.offset.defaultDisableModY = true
    entity:addComponent("projectile", position, direction)
    entity.projectile.speed = 2
    entity:addComponent("actor")
end

