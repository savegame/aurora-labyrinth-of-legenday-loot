local Buff = class()
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local ActionList = require("actions.list")
local COLORS = require("draw.colors")
function Buff:initialize(duration)
    self.expiresAtStart = false
    self.delayTurn = false
    self.flashOnApply = false
    self.disablesAction = false
    self.disablesMovement = false
    self.displayTimerColor = false
    self.forceDelayed = false
    self.colorTint = false
    self.outlinePulseColor = false
    self.duration = duration or 0
    self.triggerClasses = Array:new()
end

function Buff:shouldSerialize()
    return true
end

function Buff:getDataArgs()
    return self.duration
end

function Buff:toData(convertToData)
    return {  }
end

function Buff:fromData(convertFromData)
end

function Buff:getOutlinePulseColor(timePassed)
    if not self.outlinePulseColor then
        return false
    end

    return self.outlinePulseColor:withAlpha(COLORS.MODE_OUTLINE_PULSE_OPACITY)
end

function Buff:getColorTint(timePassed)
    return self.colorTint
end

function Buff:onApply(entity)
end

function Buff:onExpire(anchor, entity)
end

function Buff:onDelete(anchor, entity)
end

function Buff:onTurnStart(anchor, entity)
end

function Buff:onTurnEnd(anchor, entity)
end

function Buff:decorateIncomingHit(hit)
end

function Buff:decorateOutgoingHit(hit)
end

function Buff:isEntityImmune(entity)
    return false
end

function Buff:onCombine(oldBuff)
    self.duration = max(self.duration, oldBuff.duration)
end

function Buff:shouldCombine(oldBuff)
    return true
end

function Buff:decorateTriggerAction(action)
end

function Buff:decorateBasicMove(action)
end

function Buff:getTriggerActions(baseClass, entity, direction, kwargs)
    local result = ActionList:new()
    for triggerClass in self.triggerClasses() do
        if baseClass:isChild(triggerClass) then
            local action = entity.actor:create(triggerClass, direction)
            if kwargs then
                table.assign(action, kwargs)
            end

            self:decorateTriggerAction(action)
            if action:isEnabled() then
                result:push(action)
            end

        end

    end

    return result
end

return Buff

