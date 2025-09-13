local CharacterEffects = class("actions.components.component")
function CharacterEffects:initialize(action)
    CharacterEffects:super(self, "initialize", action)
    self.fillColor = false
    self.fillOpacity = 1
    self.fadeoutOpacity = 0
    self.entity = false
end

function CharacterEffects:setEntity(entity)
    self.entity = entity
end

function CharacterEffects:getEntity()
    return self.entity or self.action.entity
end

function CharacterEffects:chainFadeOutSprite(currentEvent, duration)
    return currentEvent:chainProgress(duration, function(progress)
        self:getEntity().sprite.opacity = 1 - progress * (1 - self.fadeoutOpacity)
    end)
end

function CharacterEffects:chainFadeInSprite(currentEvent, duration)
    return currentEvent:chainProgress(duration, function(progress)
        self:getEntity().sprite.opacity = self.fadeoutOpacity + progress * (1 - self.fadeoutOpacity)
    end)
end

function CharacterEffects:chainFillIn(currentEvent, duration)
    return currentEvent:chainEvent(function()
        self:getEntity().charactereffects.fillColor = self.fillColor
    end):chainProgress(duration, function(progress)
        self:getEntity().charactereffects.fillOpacity = progress * self.fillOpacity
    end)
end

function CharacterEffects:chainFillOut(currentEvent, duration)
    return currentEvent:chainProgress(duration, function(progress)
        self:getEntity().charactereffects.fillOpacity = (1 - progress) * self.fillOpacity
    end)
end

return CharacterEffects

