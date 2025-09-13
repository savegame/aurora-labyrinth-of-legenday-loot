local ActionComponent = class()
function ActionComponent:initialize(action)
    self.action = action
end

function ActionComponent:createEffect(effectName,...)
    return self.action:createEffect(effectName, ...)
end

function ActionComponent:cloneEffect(effect)
    return self.action:cloneEffect(effect)
end

return ActionComponent

