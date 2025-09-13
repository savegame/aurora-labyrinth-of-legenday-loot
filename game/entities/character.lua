return function(entity, position)
    entity:addComponent("position", position)
    entity:addComponent("sprite")
    entity:addComponent("charactereffects")
    entity:addComponent("offset")
    entity:addComponent("melee")
    entity:addComponent("actor")
end

