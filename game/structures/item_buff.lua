local ItemBuff = class("structures.buff")
function ItemBuff:initialize(duration, abilityStats)
    ItemBuff:super(self, "initialize", duration)
    self.abilityStats = abilityStats
    self.action = false
    self.expiresImmediately = false
end

function ItemBuff:rememberAction()
    return false
end

function ItemBuff:shouldSerialize()
    return false
end

function ItemBuff:decorateTriggerAction(action)
    action.abilityStats = self.abilityStats
end

function ItemBuff:getSustainMode()
    return self.abilityStats:get(Tags.STAT_ABILITY_SUSTAIN_MODE, Tags.SUSTAIN_MODE_NONE)
end

function ItemBuff:getSustainSpecialAction(direction)
    return false
end

return ItemBuff

