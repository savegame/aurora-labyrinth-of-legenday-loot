return function(entity, position, duration)
    entity:addComponent("serializable", duration)
    entity:addComponent("steppable", position, false)
    entity:addComponent("visionprovider")
    entity:addComponent("perishable", duration or 1)
end

