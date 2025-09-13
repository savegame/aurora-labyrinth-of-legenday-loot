local Caster = require("components.create_class")()
local SparseGrid = require("utils.classes.sparse_grid")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local TILE_SIZE = require("draw.measures").TILE_SIZE
local function getOutlinePulseColor(entity)
    if entity.caster.preparedAction then
        return COLORS.INDICATION_ENEMY_CAST
    else
        return false
    end

end

local function onBuffableApply(entity, buff)
        if buff.disablesAction then
        entity.caster:cancelPreparedAction(true)
    elseif buff.disablesMovement and entity.caster.disabledWithImmobilize then
        entity.caster:cancelPreparedAction(true)
    end

end

function Caster:initialize(entity, skill)
    Caster:super(self, "initialize", entity)
    self._entity = entity
    entity.charactereffects:addOutlinePulseColorSource(getOutlinePulseColor)
    self.skill = skill or false
    self.alignDistance = 1
    self.alignBackOff = true
    self.alignIgnoreBlocking = false
    self.alignWhenNotReady = false
    self.preparedAction = false
    self.disabledWithImmobilize = false
    self.shouldCancel = alwaysFalse
    self.cooldown = 0
    entity.buffable.onApply = onBuffableApply
    entity:callIfHasComponent("serializable", "addComponentPost", "caster")
end

function Caster:toData()
    local preparedDirection = false
    if self.preparedAction then
        preparedDirection = self.preparedAction.direction
    end

    return { cooldown = self.cooldown, preparedDirection = preparedDirection }
end

function Caster:fromDataPost(data)
    self.cooldown = data.cooldown
    if data.preparedDirection then
        self:prepareAction(data.preparedDirection)
    end

end

function Caster:refreshCooldown()
    self.cooldown = 0
end

function Caster:setOnCooldown()
    self.cooldown = self.skill.cooldown + 1
end

function Caster:castPreparedAction()
    local preparedAction = self.preparedAction
    if not self.skill.continuousCast then
        self.preparedAction = false
    end

    self:setOnCooldown()
    return preparedAction
end

function Caster:cancelPreparedAction(shouldSetOnCooldown)
    local preparedAction = self.preparedAction
    if self.preparedAction then
        self.preparedAction = false
        if shouldSetOnCooldown then
            self:setOnCooldown()
        end

        if self._entity.tank.hasDiedOnce then
        end

    end

end

function Caster:endOfTurn(anchor)
    self.cooldown = max(0, self.cooldown - 1)
    local services = self.system.services
    if self:canCast() and self.cooldown <= 0 and not self.preparedAction then
        local entity = self._entity
        if not entity:hasComponent("buffable") or entity.buffable:canAct() then
            if not self.disabledWithImmobilize or entity.buffable:canMove() then
                if services.vision:isVisible(entity.body:getPosition()) then
                    local player = services.player:get()
                    local direction = self.skill.getCastDirection(entity, player, services.logicrng)
                    if direction then
                        self:prepareAction(direction)
                        player.triggers:parallelChainEvent(anchor, TRIGGERS.ON_ENEMY_FOCUS, direction, { focusingEnemy = entity })
                    end

                end

            end

        end

    end

end

function Caster:canCast()
    return not self.system.services.agent.castingPrevented
end

function Caster:prepareAction(direction)
    self.preparedAction = self._entity.actor:create(self.skill.actionClass, direction)
    self._entity.sprite:turnToDirection(direction)
end

function Caster:readyAtEOT()
    return self.cooldown <= 1
end

function Caster.System:initialize()
    Caster.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("logicrng", "player", "vision", "agent", "coordinates")
end

function Caster.System:getReservedGrid()
    local reserved = SparseGrid:new(false)
    for entity in self.entities() do
        if not entity.body.removedFromGrid then
            local caster = entity.caster
            if caster.preparedAction then
                caster.skill.indicateArea(entity, caster.preparedAction.direction, reserved)
            end

        end

    end

    return reserved
end

function Caster.System:drawReservedGrid()
    local reserved = self:getReservedGrid()
    local coordinates = self.services.coordinates
    graphics.wSetColor(1, 0, 0, 0.25)
    for position, _ in reserved() do
        local scPos = coordinates:gridToScreen(position)
        graphics.wRectangle(scPos.x, scPos.y, TILE_SIZE, TILE_SIZE)
    end

end

function Caster.System:hasVisiblePrepared()
    for entity in self.entities() do
        if entity.caster.preparedAction and entity.sprite:isVisible() then
            return true
        end

    end

    return false
end

return Caster

