return function(entity, position, item)
    entity:addComponent("serializable", item)
    entity:addComponent("stepinteractive", position)
    entity.stepinteractive.onInteract = function(entity, director)
        director:publish(Tags.UI_CLEAR, false)
        director:publish(Tags.UI_ITEM_STEP, entity.item.item, entity)
    end
    entity:addComponent("item", item)
    entity:addComponent("indicator", "ITEM")
end

