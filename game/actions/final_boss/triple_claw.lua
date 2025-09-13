local SKILL = require("structures.skill_def"):new()
local BUFFS = require("definitions.buffs")
local Common = require("common")
local ACTIONS_COMMON = require("actions.common")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local Vector = require("utils.classes.vector")
local BUFF = BUFFS:define("TRIPLE_CLAW_DIRECTOR")
SKILL.cooldown = 6
SKILL.getCastDirection = function(entity, player)
    local entityPos = entity.body:getPosition()
    local playerPos = player.body:getPosition()
    if entityPos:distanceManhattan(playerPos) ~= 1 then
        return false
    end

    return Common.getDirectionTowards(entityPos, playerPos)
end
SKILL.indicateArea = function(entity, direction, indicateGrid)
    local position = entity.body:getPosition()
    local area = 3
    local buff = entity.buffable:findOneWithClass(BUFF)
    if buff then
        area = buff.area
        direction = buff.direction or direction
    end

    if area >= 5 and entity.body:isPassable(position + Vector[direction]) and entity.buffable:canMove() then
        position = position + Vector[direction]
    end

    for targetPosition in (ActionUtils.getCleavePositions(position, area, direction))() do
        indicateGrid:set(targetPosition, true)
    end

end
function BUFF:initialize(duration)
    BUFF:super(self, "initialize", duration)
    self.direction = false
    self.area = 3
end

function BUFF:toData()
    return { area = self.area, direction = self.direction }
end

function BUFF:fromData(data)
    self.area = data.area
    self.direction = data.direction
end

function BUFF:onTurnEnd(anchor, entity)
        if self.area == 3 then
        self.area = 5
    elseif self.area == 5 then
        self.area = 8
    else
    end

    local source = entity.body:getPosition()
    local target = entity.agent:getPlayer().body:getPosition()
    local directions = Common.getDirectionTowardsMultiple(source, target)
    self.direction = directions[1]
    for direction in directions() do
        if entity.body:isPassable(source + Vector[direction]) then
            self.direction = direction
            break
        end

    end

end

SKILL.continuousCast = true
local CLAW_DURATION_3 = 0.25
local CLAW_DURATION_5 = 0.33
local CLAW_DURATION_8 = 0.45
local SKILL_ACTION = class(ACTIONS_COMMON.AREA_CLAW)
SKILL.actionClass = SKILL_ACTION
function SKILL_ACTION:initialize(entity, direction, abilityStats)
    SKILL_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.duration = CLAW_DURATION_3
    self.area = 3
end

function SKILL_ACTION:castMainSkill(anchor)
    anchor = SKILL_ACTION:super(self, "process", anchor)
    if self.area > 7 then
        return anchor:chainEvent(function()
            self.entity.caster:cancelPreparedAction(true)
        end)
    else
        return anchor
    end

end

function SKILL_ACTION:process(currentEvent)
    local entity = self.entity
    if not entity.buffable:isAffectedBy(BUFF) then
        entity.buffable:forceApply(BUFF:new(3))
    end

    local buff = entity.buffable:findOneWithClass(BUFF)
    self.area = buff.area
        if self.area == 5 then
        self.duration = CLAW_DURATION_5
    elseif self.area == 8 then
        self.duration = CLAW_DURATION_8
    end

    if buff.direction then
        self.direction = buff.direction
    end

    entity.sprite:turnToDirection(self.direction)
    if self.area > 3 and entity.body:isPassable(entity.body:getPosition() + Vector[self.direction]) and entity.buffable:canMove() then
        local moveAction = entity.actor:create(ACTIONS_FRAGMENT.TRAIL_MOVE, self.direction)
        moveAction.disableSound = true
        moveAction.stepDuration = 0.15
        moveAction:parallelChainEvent(currentEvent)
        return currentEvent:chainProgress(0.05):chainEvent(function(_, anchor)
            anchor = self:castMainSkill(anchor)
        end)
    else
        return self:castMainSkill(currentEvent)
    end

end

return SKILL

