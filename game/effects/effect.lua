local Effect = class()
function Effect:initialize()
    self.toDelete = false
    self.layer = Tags.LAYER_EFFECT_NORMAL
end

function Effect:delete()
    self.toDelete = true
end

function Effect:update(dt)
end

function Effect:draw(managerCoordinates)
end

function Effect:isVisible()
    return true
end

return Effect

