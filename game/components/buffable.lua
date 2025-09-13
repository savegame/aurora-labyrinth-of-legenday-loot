local Buffable = require("components.create_class")()
local BUFFS = require("definitions.buffs")
local Set = require("utils.classes.set")
local Array = require("utils.classes.array")
local UniqueList = require("utils.classes.unique_list")
local ActionList = require("actions.list")
local Buff = require("structures.buff")
local COLORS = require("draw.colors")
local function getTint(entity, timePassed)
    return entity.buffable:getTint(timePassed)
end

local function getOutlinePulseColor(entity, timePassed)
    return entity.buffable:getOutlinePulseColor(timePassed)
end

function Buffable:initialize(entity)
    Buffable:super(self, "initialize")
    self._entity = entity
    entity.charactereffects.tint = getTint
    entity.charactereffects:addOutlinePulseColorSource(getOutlinePulseColor)
    self._immunities = Set:new()
    self._activeBuffs = UniqueList:new()
    self._delayedBuffs = Array:new()
    self.delayAllNonStart = false
    self.onApply = doNothing
    self:clear()
    entity:callIfHasComponent("serializable", "addComponentPost", "buffable")
end

function Buffable:toData(convertToData)
    local buffs = Array:new()
    for buff in self._activeBuffs() do
        if buff:shouldSerialize() then
            local buffData = buff:toData(convertToData)
            buffData._name = BUFFS:findName(buff)
            buffData._args = Array:new(buff:getDataArgs()):map(convertToData)
            buffs:push(buffData)
        end

    end

    return { activeBuffs = buffs }
end

function Buffable:fromDataPost(data, convertFromData)
    local buffsData = Array:Convert(data.activeBuffs)
    for buffData in buffsData() do
        local args = Array:Convert(buffData._args)
        args = args:map(convertFromData)
        local buff = BUFFS:get(buffData._name):new(args:expand())
        buff:fromData(buffData, convertFromData)
        local buffClass = buff:getClass()
        local oldBuff = self:findOneWithClass(buffClass)
        if oldBuff and buff:shouldCombine(oldBuff) then
            self._activeBuffs:delete(oldBuff)
        end

        buff:onApply(self._entity)
        self.onApply(self._entity, buff)
        self._activeBuffs:push(buff)
    end

end

function Buffable:addImmunity(buffClass)
    self._immunities:add(buffClass)
end

function Buffable:clear()
    self._activeBuffs:clear()
    self._delayedBuffs:clear()
end

function Buffable:removeExpired(anchor)
    for buff in self._activeBuffs() do
        if buff.duration <= 0 then
            buff:onExpire(anchor, self._entity)
            buff:onDelete(anchor, self._entity)
            self._activeBuffs:delete(buff)
        end

    end

end

function Buffable:delete(anchor, buffClass, once)
    Utils.assert(not Buff:isInstance(anchor), "buffable:delete takes anchor and buffClass args")
    for buff in self._activeBuffs() do
        if buff:getClass() == buffClass then
            buff:onDelete(anchor, self._entity)
            self._activeBuffs:delete(buff)
            if once then
                return 
            end

        end

    end

    self._delayedBuffs:rejectSelf(function(buff)
        if buff:getClass() == buffClass then
            if once then
                buffClass = false
            end

            return true
        else
            return false
        end

    end)
end

function Buffable:startOfTurn(anchor)
    self.delayAllNonStart = true
    for buff in self._activeBuffs() do
        buff:onTurnStart(anchor, self._entity)
        if buff.expiresAtStart then
            buff.duration = buff.duration - 1
        end

    end

    self:removeExpired(anchor)
end

function Buffable:endOfTurn(anchor)
    for buff in self._activeBuffs() do
        buff:onTurnEnd(anchor, self._entity)
        if not buff.expiresAtStart then
            buff.duration = buff.duration - 1
        end

    end

    self.delayAllNonStart = false
    self:applyDelayedBuffs()
    self:removeExpired(anchor)
end

function Buffable:getTint(timePassed)
    for buff in self._delayedBuffs:reverseIterator() do
        local tint = buff:getColorTint(timePassed)
        if tint then
            return tint
        end

    end

    for buff in self._activeBuffs:reverseIterator() do
        local tint = buff:getColorTint(timePassed)
        if tint then
            return tint
        end

    end

    return false
end

function Buffable:getOutlinePulseColor(timePassed)
    for buff in self._delayedBuffs:reverseIterator() do
        local pulseColor = buff:getOutlinePulseColor(timePassed)
        if pulseColor then
            return pulseColor
        end

    end

    for buff in self._activeBuffs:reverseIterator() do
        local pulseColor = buff:getOutlinePulseColor(timePassed)
        if pulseColor then
            return pulseColor
        end

    end

    return false
end

function Buffable:findOneWithClass(buffClass)
    return self._activeBuffs:findOne(function(buff)
        return buffClass:isInstance(buff)
    end)
end

function Buffable:getRemainingDuration(buffClass)
    local buff = self:findOneWithClass(buffClass)
    if not buff then
        return 0
    else
        return buff.duration
    end

end

function Buffable:isAffectedBy(buffClass)
    return toBoolean(self:findOneWithClass(buffClass))
end

function Buffable:isOrWillBeAffectedBy(buffClass)
    if self:isAffectedBy(buffClass) then
        return true
    end

    return self._delayedBuffs:findOne(function(buff)
        return buffClass:isInstance(buff)
    end)
end

function Buffable:forceApply(buff)
    local buffClass = buff:getClass()
    if not self._immunities:contains(buffClass) and not buff:isEntityImmune(self._entity) then
        if buff.flashOnApply then
            self._entity.charactereffects.negativeOverlay = 1
        end

        local oldBuff = self:findOneWithClass(buffClass)
        self._activeBuffs:push(buff)
        if oldBuff then
            if buff:shouldCombine(oldBuff) then
                buff:onCombine(oldBuff)
                self._activeBuffs:delete(oldBuff)
                return 
            end

        end

        buff:onApply(self._entity)
        self.onApply(self._entity, buff)
    end

end

function Buffable:apply(buff)
    if (self.delayAllNonStart or buff.forceDelayed) and not buff.expiresAtStart and buff.duration > 0 then
        self:delayedApply(buff)
    else
        self:forceApply(buff)
    end

end

function Buffable:delayedApply(buff)
    local buffClass = buff:getClass()
    if not self._immunities:contains(buffClass) then
        if buff.flashOnApply then
            buff.flashOnApply = false
            self._entity.charactereffects.negativeOverlay = 1
        end

        self._delayedBuffs:push(buff)
    end

end

function Buffable:applyDelayedBuffs()
    for delayedBuff in self._delayedBuffs() do
        self:forceApply(delayedBuff)
    end

    self._delayedBuffs:clear()
end

function Buffable:extend(buffClass, extendDuration)
    local buff = self:findOneWithClass(buffClass)
    if buff then
        buff.duration = buff.duration + extendDuration
    end

end

function Buffable:decorateIncomingHit(hit)
    for buff in self._activeBuffs() do
        buff:decorateIncomingHit(hit)
    end

    return hit
end

function Buffable:hasDelayTurn()
    for buff in self._activeBuffs() do
        if Utils.evaluate(buff.delayTurn, buff, self._entity) then
            return true
        end

    end

    return false
end

function Buffable:decorateOutgoingHit(hit)
    for buff in self._activeBuffs() do
        buff:decorateOutgoingHit(hit)
    end

    return hit
end

function Buffable:canMove()
    return not self._activeBuffs:hasOne(function(buff)
        return buff.disablesMovement
    end)
end

function Buffable:canAct()
    return not self._activeBuffs:hasOne(function(buff)
        return buff.disablesAction
    end)
end

function Buffable:canAttack()
    return self:canAct()
end

function Buffable:isImmuneTo(buffClass)
    return self._immunities:contains(buffClass)
end

function Buffable:getTriggerActions(baseClass, direction, kwargs)
    local result = ActionList:new()
    for buff in self._activeBuffs() do
        result:concat(buff:getTriggerActions(baseClass, self._entity, direction, kwargs))
    end

    return result
end

function Buffable:decorateBasicMove(moveAction)
    for buff in self._activeBuffs() do
        buff:decorateBasicMove(moveAction)
    end

end

local MIN_TIMER_VALUE = 1000
function Buffable:getDisplayTimer()
    local minValue = MIN_TIMER_VALUE
    local color = false
    for buff in self._activeBuffs() do
        if buff.displayTimerColor and buff.duration < minValue then
            color = buff.displayTimerColor
            minValue = buff.duration
        end

    end

    if minValue < MIN_TIMER_VALUE then
        return minValue, color
    else
        return false
    end

end

return Buffable

