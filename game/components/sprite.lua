local Sprite = require("components.create_class")()
local DrawCommand = require("utils.love2d.draw_command")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local MEASURES = require("draw.measures")
local SHADERS = require("draw.shaders")
local COLORS = require("draw.colors")
local TIMER_FONT = require("draw.fonts").MEDIUM
local DrawText = require("draw.text")
local TILE_SIZE = MEASURES.TILE_SIZE + 2
local ORIGIN = Vector:new(TILE_SIZE / 2, 0)
local CRITICAL_RATIO = 0.4
local Common = require("common")
Tags.add("FRAME_STATIC", 1)
Tags.add("FRAME_ANIMATED", 2)
Tags.add("FRAME_WEAPONLESS", 3)
Tags.add("FRAME_TANK_DEPENDENT", 4)
local TYPE_2_SHADOW_OFFSET = Vector:new(0, 2)
local FILENAME_FOR_FRAME = Hash:new({ [Tags.FRAME_STATIC] = "sprites_static", [Tags.FRAME_ANIMATED] = "sprites_animated", [Tags.FRAME_WEAPONLESS] = "sprites_weaponless", [Tags.FRAME_TANK_DEPENDENT] = "sprites_tank_dependent" })
function Sprite:initialize(entity)
    Sprite:super(self, "initialize")
    self._entity = entity
    self.positionSource = Common.getPositionComponent(entity)
    self.direction = RIGHT
    self.cell = false
    self.defaultCell = false
    self.layer = Tags.LAYER_CHARACTER
    self.defaultLayer = Tags.LAYER_CHARACTER
    self.opacity = 1
    self.frameType = Tags.FRAME_ANIMATED
    self.effectProfiles = Array:new()
    self.strokeColor = false
    self.shadowType = 1
    self.alwaysVisible = false
    self.timeStopped = false
    self.cachedDisplay = false
    self.cachedVisibility = false
    self.isRemoved = false
    entity:callIfHasComponent("serializable", "addComponent", "sprite")
end

function Sprite:toData(convertToData)
    return { direction = self.direction, isRemoved = self.isRemoved, opacity = self.opacity, cell = self.cell }
end

function Sprite:fromData(data, convertFromData)
    self.direction = data.direction
    self.isRemoved = data.isRemoved
    self.opacity = data.opacity
    self.cell = convertFromData(data.cell)
end

function Sprite:resetLayer()
    self.layer = self.defaultLayer
end

function Sprite:turnToDirection(direction)
    if direction > 0 then
        self.direction = direction
    end

end

function Sprite:setCell(cx, cy)
    self.cell = Vector:new(cx, cy)
    if not self.defaultCell then
        self.defaultCell = self.cell
    end

end

function Sprite:resetCell()
    self.cell = self.defaultCell
end

function Sprite:getDisplayPosition(excludeJump, excludeBody)
    local position = self.positionSource:getPosition()
    if self.shadowType == 1 then
        position = position + MEASURES.SHADOWED_OFFSET
    else
        position = position - Vector.UNIT_Y / TILE_SIZE
    end

    if self._entity:hasComponent("offset") then
        position = position + self._entity.offset:getTotal(excludeJump, excludeBody)
    end

    return position
end

function Sprite:getDrawCommand(timePassed)
    local drawCommand = DrawCommand:new(FILENAME_FOR_FRAME:get(self.frameType))
    drawCommand.origin = ORIGIN
    drawCommand.opacity = self.opacity
    drawCommand:setRectFromDimensions(TILE_SIZE, TILE_SIZE)
    if self.frameType == Tags.FRAME_TANK_DEPENDENT then
        local frame = 0
        if self._entity:hasComponent("tank") then
            local ratio = self._entity.tank:getRatio()
                        if ratio < CRITICAL_RATIO then
                frame = 2
            elseif ratio < 1 then
                frame = 1
            end

        end

        drawCommand.rect.x = ((self.cell.x - 1) * 3 + frame) * TILE_SIZE
    else
        drawCommand.rect.x = (self.cell.x - 1) * TILE_SIZE
    end

    if self.frameType == Tags.FRAME_ANIMATED or self.frameType == Tags.FRAME_WEAPONLESS then
        local frame = Common.getSpriteFrame(timePassed)
        drawCommand.rect.y = ((self.cell.y - 1) * 2 + frame) * TILE_SIZE
    else
        drawCommand.rect.y = (self.cell.y - 1) * TILE_SIZE
    end

    drawCommand.flipX = MEASURES.FLIPPED_DIRECTIONS:contains(self.direction)
    return drawCommand
end

function Sprite:getStrokeFillCommand(timePassed)
    local strokeColor = self.strokeColor
    if Array:isInstance(strokeColor) then
        strokeColor = strokeColor:last()
    end

    if strokeColor then
        local drawCommand
        if self.frameType == Tags.FRAME_WEAPONLESS then
            drawCommand = DrawCommand:new("sprites_weaponless_stroke")
        else
            drawCommand = DrawCommand:new("sprites_stroke")
        end

        drawCommand.color = strokeColor
        drawCommand.origin = Vector:new(TILE_SIZE / 2 + 1, 0)
        drawCommand.opacity = self.opacity
        drawCommand.rect:setDimensions(TILE_SIZE + 2, TILE_SIZE + 2)
        local frame = Common.getSpriteFrame(timePassed)
        drawCommand.rect.x = (self.cell.x - 1) * (TILE_SIZE + 2)
        drawCommand.rect.y = ((self.cell.y - 1) * 2 + frame) * (TILE_SIZE + 2)
        drawCommand.flipX = MEASURES.FLIPPED_DIRECTIONS:contains(self.direction)
        drawCommand.position = self.cachedDisplay + Vector:new(0.5, -1 / TILE_SIZE)
        return drawCommand
    else
        return false
    end

end

function Sprite:getDrawCommandGrid(timePassed, useCached)
    local drawCommand = self:getDrawCommand(timePassed)
    drawCommand.position = self.cachedDisplay + ORIGIN / TILE_SIZE
    return drawCommand
end

function Sprite:createCharacterCopy()
    local character = self.system:createCharacter(self.positionSource:getPosition())
    character.sprite.cell = self.cell
    character.sprite:turnToDirection(self.direction)
    character.sprite.layer = self.layer
    if self._entity:hasComponent("melee") then
        character.melee.swingIcon = self._entity.melee:evaluateSwingIcon()
    end

    return character
end

function Sprite:isVisible()
    return self.cachedVisibility
end

function Sprite:isPositionVisible(position)
    return self.system.services.vision:isVisibleForDisplay(position)
end

function Sprite.System:initialize()
    Sprite.System:super(self, "initialize")
    self.storageClass = Array
    self:setDependencies("timing", "coordinates", "effects", "createEntity", "vision")
end

function Sprite.System:createCharacter(position)
    return self.services.createEntity("character", position)
end

function Sprite.System:sortEntities(entities)
    entities:stableSortSelf(function(a, b)
        local spriteA, spriteB = a.sprite, b.sprite
        local aY, bY = spriteA.cachedDisplay.y, spriteB.cachedDisplay.y
        if spriteA.shadowType == 1 then
            aY = aY - MEASURES.SHADOWED_OFFSET.y
        end

        if spriteB.shadowType == 1 then
            bY = bY - MEASURES.SHADOWED_OFFSET.y
        end

                if within(spriteA.layer, Tags.LAYER_CHARACTER, Tags.LAYER_ENGULF) and within(spriteB.layer, Tags.LAYER_CHARACTER, Tags.LAYER_ENGULF) then
            if abs(aY - bY) <= 1 / TILE_SIZE then
                return spriteA.layer < spriteB.layer
            else
                return aY < bY
            end

        elseif spriteA.layer == spriteB.layer then
            return aY < bY
        else
            return spriteA.layer < spriteB.layer
        end

    end)
end

function Sprite:checkVisibility(tileWithinChecker, vision)
    if self.isRemoved then
        return false
    end

    if self.cachedDisplay and not tileWithinChecker(self.cachedDisplay) then
        return false
    end

    return self.alwaysVisible or vision:isVisibleForDisplay(self:getDisplayPosition(true, true):roundXY())
end

function Sprite.System:cacheDisplayPositions()
    local vision = self.services.vision
    local coordinates = self.services.coordinates
    for entity in self.entities() do
        entity.sprite.cachedDisplay = entity.sprite:getDisplayPosition()
        local tileWithinChecker = coordinates:getTileWithinScreenChecker()
        entity.sprite.cachedVisibility = entity.sprite:checkVisibility(tileWithinChecker, vision)
    end

end

function Sprite.System:draw(layers)
    local entities = self.entities:accept(function(entity)
        if layers:contains(entity.sprite.layer) then
            return entity.sprite:isVisible()
        else
            return false
        end

    end)
    self:sortEntities(entities)
    local coordinates = self.services.coordinates
    for entity in entities() do
        local timePassed = self.services.effects:getTimePassed()
        if entity:hasComponent("player") then
            timePassed = self.services.timing.timePassed
        end

        if entity.sprite.timeStopped then
            timePassed = 0
        end

        local drawCommand = entity.sprite:getDrawCommandGrid(timePassed)
        drawCommand.position = coordinates:gridToScreen(drawCommand.position)
        if entity.sprite.timeStopped then
            drawCommand.shader = SHADERS.DESATURATE
        end

        local stroke = entity.sprite:getStrokeFillCommand(timePassed)
        if stroke then
            stroke.position = coordinates:gridToScreen(stroke.position)
            stroke:draw()
        end

        drawCommand:draw()
        entity:callIfHasComponent("charactereffects", "draw", drawCommand, timePassed)
        if entity:hasComponent("buffable") then
            local displayTimer, timerColor = entity.buffable:getDisplayTimer()
            if displayTimer then
                graphics.wSetColor(timerColor)
                graphics.wSetFont(TIMER_FONT)
                DrawText.drawStrokedCentered(tostring(displayTimer), drawCommand.position.x, drawCommand.position.y + TILE_SIZE / 2 - TIMER_FONT:getStrokedHeight() / 2)
            end

        end

    end

end

function Sprite.System:drawShadows()
    local drawCommand = DrawCommand:new("shadow")
    drawCommand:setRectFromDimensions(TILE_SIZE - 2, TILE_SIZE - 2)
    local entities = self.entities:accept(function(entity)
        return entity.sprite:isVisible()
    end)
    local coordinates = self.services.coordinates
    for entity in entities() do
        local sprite = entity.sprite
        if sprite.shadowType then
            drawCommand:setCell(sprite.shadowType, 1)
            drawCommand.position = sprite:getDisplayPosition(true) - MEASURES.SHADOWED_OFFSET
            drawCommand.position = coordinates:gridToScreen(drawCommand.position)
            if sprite.shadowType == 2 then
                drawCommand.position = drawCommand.position + TYPE_2_SHADOW_OFFSET
            end

            drawCommand.opacity = sprite.opacity
            drawCommand:draw()
        end

    end

end

return Sprite

