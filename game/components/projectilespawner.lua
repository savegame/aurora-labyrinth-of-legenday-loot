local ProjectileSpawner = require("components.create_class")()
local Vector = require("utils.classes.vector")
local ACTIONS_BASIC = require("actions.basic")
local CONSTANTS = require("logic.constants")
function ProjectileSpawner:initialize(entity)
    ProjectileSpawner:super(self, "initialize", entity)
    self._entity = entity
    self.cell = false
    self.isMagical = false
    self.keepAlive = 0
end

function ProjectileSpawner:setCell(cx, cy)
    self.cell = Vector:new(cx, cy)
end

function ProjectileSpawner:_processSpawn(anchor, projectileEntity, direction, speed)
    local projectile = projectileEntity.projectile
    if anchor then
        projectile.frozen = true
        projectile.isVisible = false
        anchor = anchor:chainEvent(function()
            projectile.isVisible = true
        end)
        local moveAction = projectileEntity.actor:create(ACTIONS_BASIC.MOVE_PROJECTILE, direction)
        if speed then
            moveAction.speed = speed
        end

        return moveAction:parallelChainEvent(anchor), projectileEntity
    else
        projectile.frozen = false
        return false, projectileEntity
    end

end

function ProjectileSpawner:spawn(anchor, direction, abilityStats, cell, isMagical)
    local projectileEntity = self.system.services.createEntity("projectiles.normal", self._entity.body:getPosition(), self._entity, direction, abilityStats or false, cell or self.cell, isMagical or self.isMagical)
    return self:_processSpawn(anchor, projectileEntity, direction)
end

function ProjectileSpawner:spawnSpecial(anchor, prefab, direction,...)
    local projectileEntity = self.system.services.createEntity("projectiles." .. prefab, self._entity.body:getPosition(), self._entity, direction, ...)
    return self:_processSpawn(anchor, projectileEntity, direction)
end

function ProjectileSpawner:spawnChild(anchor, prefab, source, direction,...)
    local projectileEntity = self.system.services.createEntity("projectiles." .. prefab, source, self._entity, direction, ...)
    return self:_processSpawn(anchor, projectileEntity, direction, CONSTANTS.PRODUCED_PROJECTILE_SPEED)
end

function ProjectileSpawner:isVisible(position)
    return self.system:isVisible(position)
end

function ProjectileSpawner.System:isVisible(position)
    return self.services.vision:isVisible(position)
end

function ProjectileSpawner.System:initialize()
    ProjectileSpawner.System:super(self, "initialize")
    self:setDependencies("createEntity", "vision")
end

return ProjectileSpawner

