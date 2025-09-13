local Projectile = require("components.create_class")()
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local SparseGrid = require("utils.classes.sparse_grid")
local UniqueList = require("utils.classes.unique_list")
local DrawCommand = require("utils.love2d.draw_command")
local TRIGGERS = require("actions.triggers")
local CONSTANTS = require("logic.constants")
local MEASURES = require("draw.measures")
local Common = require("common")
local TILE_CENTER = Vector:new(MEASURES.TILE_SIZE / 2, MEASURES.TILE_SIZE / 2)
function Projectile:initialize(entity, position, direction)
    Projectile:super(self, "initialize")
    self.position = position
    self.direction = direction
    self.targetDirection = false
    self.angle = false
    self.drawBelow = true
    self.hasHit = false
    self.speed = 1
    self.opacity = 1
    self.onHitAction = false
    self.stencilPosition = false
    self.cell = Vector:new(1, 1)
    self.isMagical = false
    self.frozen = false
    self.isVisible = true
    self._entity = entity
    entity:callIfHasComponent("serializable", "addComponent", "projectile")
end

function Projectile:toData()
    return { direction = self.direction }
end

function Projectile:fromData(data)
    self.direction = data.direction
end

function Projectile:getPosition()
    return self.position
end

function Projectile:setToPlayerSpeed()
    self.speed = CONSTANTS.PLAYER_PROJECTILE_SPEED
end

function Projectile:callOnHit(anchor, position, catcher)
    catcher = catcher or false
    if not self.hasHit then
        self.hasHit = true
        self._entity:delete()
        if self.onHitAction then
            self.onHitAction.targetPosition = position
            self.onHitAction.targetEntity = catcher
            self.onHitAction:parallelResolve(anchor)
            anchor = self.onHitAction:chainEvent(anchor)
            if self.onHitAction.entity:hasComponent("triggers") then
                anchor = self.onHitAction.entity.triggers:parallelChainEvent(anchor, TRIGGERS.ON_PROJECTILE_HIT, self.onHitAction.direction, { projectile = self, position = position, catcher = catcher, abilityStats = self.onHitAction.abilityStats })
            end

        end

    end

    return anchor
end

function Projectile:isPassable(position)
    return self.system:isPassable(position)
end

local function isProjectileBelow(entity)
    return entity.projectile.drawBelow
end

function Projectile.System:initialize()
    Projectile.System:super(self, "initialize")
    self.storageClass = UniqueList
    self:setDependencies("body", "coordinates", "effects", "vision", "viewport")
end

function Projectile.System:isPassable(position)
    return self.services.body:isPassableForProjectiles(position)
end

function Projectile.System:draw(isBelow)
    local timePassed = self.services.effects:getTimePassed()
    local vision = self.services.vision
    local frame = Common.getSpriteFrame(timePassed)
    local sineOffset = sin(math.tau * timePassed / MEASURES.FRAME_ANIMATION)
    local iterator
    if isBelow then
        iterator = self.entities:iterateIf(isProjectileBelow)
    else
        iterator = self.entities:iterateUnless(isProjectileBelow)
    end

    local viewport = self.services.viewport
    for entity in iterator do
        local projectile = entity.projectile
        local position = projectile.position
        if vision:isVisibleForDisplay(position:roundXY()) and projectile.isVisible then
            local drawCommand = DrawCommand:new()
            drawCommand.rect = Rect:new(0, 0, MEASURES.PROJECTILE_SIZE, MEASURES.PROJECTILE_SIZE)
            if projectile.isMagical then
                drawCommand.image = "projectiles_animated"
                drawCommand:setCell(projectile.cell.x, projectile.cell.y * 2 - 1 + frame)
            else
                drawCommand.image = "projectiles"
                drawCommand:setCell(projectile.cell)
            end

            drawCommand:setOriginToCenter()
            local direction = projectile.direction
            position = position + entity.offset:getTotal()
            drawCommand.position = self.services.coordinates:gridToScreen(position) + TILE_CENTER + MEASURES.PROJECTILE_OFFSET
            if projectile.isMagical then
                                if direction == LEFT or direction == RIGHT then
                    drawCommand.position = drawCommand.position + Vector:new(0, sineOffset)
                elseif direction == UP or direction == DOWN then
                    drawCommand.position = drawCommand.position + Vector:new(sineOffset, 0)
                else
                    local hypotOff = sineOffset / math.sqrtOf2
                    if direction == UP_RIGHT or direction == DOWN_LEFT then
                        drawCommand.position = drawCommand.position + Vector:new(hypotOff, hypotOff)
                    else
                        drawCommand.position = drawCommand.position + Vector:new(hypotOff, -hypotOff)
                    end

                end

            end

            drawCommand.position = viewport:toNearestScale(drawCommand.position - drawCommand.origin)
            drawCommand.position = drawCommand.position + drawCommand.origin
            if projectile.angle then
                drawCommand.angle = projectile.angle
            else
                drawCommand.angle = Vector.ORIGIN:angleTo(Vector[direction])
            end

            local stencilPosition = projectile.stencilPosition
            if stencilPosition and not projectile.isMagical then
                drawCommand.stencilRectInclude = false
                local rect = Rect:new(stencilPosition.x, stencilPosition.y, 1, 1)
                rect:growDirectionSelf(reverseDirection(direction), -0.5)
                drawCommand.stencilRect = self.services.coordinates:gridToScreenRect(rect)
            end

            drawCommand.opacity = projectile.opacity
            drawCommand:draw()
        end

    end

end

function Projectile.System:catchAt(anchor, catcher, position)
    if not catcher.body.phaseProjectiles then
        for entity in self.entities() do
            if entity.projectile.position == position then
                entity.projectile:callOnHit(anchor, position, catcher)
            end

        end

    end

end

function Projectile.System:getProjectilesAt(position)
    return self.entities:accept(function(entity)
        return entity.projectile.position == position
    end)
end

function Projectile.System:freezeAt(position)
    for projectile in (self:getProjectilesAt(position))() do
        projectile.projectile.frozen = true
    end

end

function Projectile.System:freezeAll()
    for entity in self.entities() do
        entity.projectile.frozen = true
    end

end

function Projectile.System:unfreeze()
    for entity in self.entities() do
        entity.projectile.frozen = false
    end

end

function Projectile.System:getReservedGrid()
    local reserved = SparseGrid:new(false)
    for entity in self.entities() do
        local projectile = entity.projectile
        if projectile.onHitAction and not projectile.onHitAction.entity:hasComponent("player") then
            reserved:set(projectile.position, true)
            if not projectile.frozen then
                for i = 1, projectile.speed do
                    reserved:set(projectile.position + Vector[projectile.direction] * i, true)
                end

            end

        end

    end

    return reserved
end

return Projectile

