local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local RANGED_ATTACK = class("actions.action")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
RANGED_ATTACK.ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function RANGED_ATTACK.ON_HIT:initialize(entity, direction, abilityStats)
    RANGED_ATTACK.ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToDeath()
end

function RANGED_ATTACK.ON_HIT:parallelResolve(anchor)
    RANGED_ATTACK.ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamage(Tags.DAMAGE_TYPE_RANGED, self.entity.stats:getAttack())
end

function RANGED_ATTACK:initialize(entity, direction, abilityStats)
    RANGED_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = COLORS.STANDARD_DEATH
end

function RANGED_ATTACK:checkParallel()
    if self.entity.sprite:isVisible() then
        return false
    end

    local source = self.entity.body:getPosition()
    for i = 1, CONSTANTS.ENEMY_PROJECTILE_SPEED do
        if self.entity.sprite:isPositionVisible(source + Vector[self.direction] * i) then
            return false
        end

    end

    if self.entity.sprite:isPositionVisible(source + Vector[cwDirection(self.direction, 1)]) then
        return false
    end

    if self.entity.sprite:isPositionVisible(source + Vector[ccwDirection(self.direction, 1)]) then
        return false
    end

    return true
end

function RANGED_ATTACK:spawnProjectiles(anchor)
    local spawner = self.entity.projectilespawner
    spawner:spawn(anchor, self.direction)
    local _, projectileEntity1 = spawner:spawn(anchor, cwDirection(self.direction, 1))
    projectileEntity1.projectile.targetDirection = self.direction
    local _, projectileEntity2 = spawner:spawn(anchor, ccwDirection(self.direction, 1))
    projectileEntity2.projectile.targetDirection = self.direction
end

function RANGED_ATTACK:parallelResolve(anchor)
    self.entity.sprite:turnToDirection(self.direction)
    if self.isParallel then
        self:spawnProjectiles(false)
    end

end

function RANGED_ATTACK:process(currentEvent)
    if self.isParallel then
        return currentEvent
    else
        Common.playSFX("CAST_CHARGE", 1.0)
        return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function(_, anchor)
            self:spawnProjectiles(anchor)
        end)
    end

end

return RANGED_ATTACK

