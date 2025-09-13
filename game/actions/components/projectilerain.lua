local ProjectileRain = class("actions.components.component")
local Vector = require("utils.classes.vector")
local ActionUtils = require("actions.utils")
local PROJECTILE_SIZE = 23
local FALL_DURATION = 0.22
local DROP_GAP = 0.1
local TRAIL_FADE_REPEAT = 0.01
local DISTANCE = 2.5
function ProjectileRain:initialize(action)
    ProjectileRain:super(self, "initialize", action)
    self.source = false
    self.area = Tags.ABILITY_AREA_3X3
    self.projectile = Vector:new(1, 1)
    self.onHitClass = false
    self.sortCompare = false
    self.dropGap = DROP_GAP
end

function ProjectileRain:chainRainEvent(currentEvent)
    local positions = ActionUtils.getAreaPositions(self.action.entity, self.source, self.area)
    positions:shuffleSelf(self.action:getLogicRNG())
    if self.sortCompare then
        positions:stableSortSelf(self.sortCompare)
    end

    local lastEvent = currentEvent
    for i, position in ipairs(positions) do
        local thisPosition = position
        local drop, dropTrail
        currentEvent = currentEvent:chainEvent(function(_, anchor)
            dropTrail = self:createEffect("fade_trail")
            drop = self:createEffect("image", "projectiles_animated")
            drop.cellSize = PROJECTILE_SIZE
            drop.cell = self.projectile
            drop.position = thisPosition - Vector:new(0, DISTANCE)
            drop.direction = DOWN
            dropTrail.effect = drop
            dropTrail.disableFilterOutline = true
            dropTrail.initialOpacity = 0.25
            dropTrail:chainTrailEvent(anchor, TRAIL_FADE_REPEAT)
        end)
        local hitEvent = currentEvent:chainProgress(FALL_DURATION, function(progress)
            drop.position = thisPosition - Vector:new(0, DISTANCE) * (1 - progress)
        end):chainEvent(function()
            drop:delete()
            dropTrail:stopTrailEvent()
        end)
        local hitAction = self.action.entity.actor:create(self.onHitClass, self.action.direction, self.action.abilityStats)
        hitAction.targetPosition = thisPosition
        lastEvent = hitAction:parallelChainEvent(hitEvent)
        local dropGap = Utils.evaluate(self.dropGap, i)
        if dropGap > 0 then
            currentEvent = currentEvent:chainProgress(dropGap)
        end

    end

    return lastEvent
end

return ProjectileRain

