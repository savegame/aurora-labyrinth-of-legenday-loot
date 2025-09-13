local BUFFS = {  }
local COLORS = require("draw.colors")
local Hash = require("utils.classes.hash")
local Buff = require("structures.buff")
local nameToClass = Hash:new()
local classToName = Hash:new()
function BUFFS:define(name, parent)
    Utils.assert(not nameToClass:hasKey(name), "Buff '%s' already exists", name)
    local buffClass
    if parent then
        buffClass = class(BUFFS:get(parent))
    else
        buffClass = class(Buff)
    end

    nameToClass:set(name, buffClass)
    classToName:set(buffClass, name)
    return buffClass
end

function BUFFS:findName(buff)
    if not classToName:hasKey(buff:getClass()) then
        Utils.assert(false, "Unknown buff: %s", Utils.toString(buff))
    end

    return classToName:get(buff:getClass())
end

function BUFFS:get(name)
    return nameToClass:get(name)
end

BUFFS.PLACEHOLDER = class("structures.item_buff")
function BUFFS.PLACEHOLDER:onCombine(oldBuff)
    Utils.assert(false, "Placeholder buff should not stack")
end

BUFFS.DEACTIVATOR = class("structures.item_buff")
function BUFFS.DEACTIVATOR:rememberAction()
    return true
end

function BUFFS.DEACTIVATOR:onDelete(anchor)
    self.action:deactivate(anchor)
end

BUFFS.FOCUS = class("structures.item_buff")
function BUFFS.FOCUS:initialize(duration, abilityStats, action)
    BUFFS.FOCUS:super(self, "initialize", duration, abilityStats, action)
    self.mainActionClass = false
end

function BUFFS.FOCUS:rememberAction()
    return true
end

function BUFFS.FOCUS:getOutlinePulseColor(timePassed)
    return COLORS.INDICATION_ENEMY_CAST
end

function BUFFS.FOCUS:onExpire(anchor, entity)
    local action = entity.actor:create(self.mainActionClass, self.action.direction, self.abilityStats)
    self:decoratePostFocusAction(action)
    return action:parallelChainEvent(anchor)
end

function BUFFS.FOCUS:decoratePostFocusAction(action)
end

return BUFFS

