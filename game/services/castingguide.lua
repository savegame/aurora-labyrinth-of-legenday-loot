local CastingGuide = class("services.service")
local Vector = require("utils.classes.vector")
local SparseGrid = require("utils.classes.sparse_grid")
local Common = require("common")
local MEASURES = require("draw.measures")
local TILE_SIZE = MEASURES.TILE_SIZE
local COLORS = require("draw.colors")
local MIN_OPACITY = COLORS.INDICATION_MIN_OPACITY
local MAX_OPACITY = COLORS.INDICATION_MAX_OPACITY
local WEAK_OPACITY_MULT = COLORS.INDICATION_WEAK_OPACITY_MULT
local MOVE_MIN_OPACITY = COLORS.INDICATION_MOVE_MIN_OPACITY
local MOVE_MAX_OPACITY = COLORS.INDICATION_MOVE_MAX_OPACITY
local INDICATION_WEAK = 1
local INDICATION_NORMAL = 2
function CastingGuide:initialize()
    CastingGuide:super(self, "initialize")
    self:setDependencies("timing", "coordinates", "director", "player", "body")
    self.toDelete = false
    self.currentAbility = false
    self.currentAbilityStats = false
    self:clear()
end

function CastingGuide:onDependencyFulfill()
    local director = self.services.director
    director:subscribe(Tags.UI_ABILITY_SELECTED, self)
    director:subscribe(Tags.UI_CAST_TURN, self)
    director:subscribe(Tags.UI_MOUSE_TILE_CHANGED, self)
end

function CastingGuide:clear()
    self.displayArrows = false
    self.indicated = SparseGrid:new(0)
    self._indicateMoveTo = false
    self.indicateModeCancel = false
end

function CastingGuide:indicateMoveTo(position)
    self._indicateMoveTo = position
end

function CastingGuide:getMoveTo()
    return self._indicateMoveTo
end

function CastingGuide:indicate(position)
    if self.services.body:canBePassable(position) then
        self.indicated:set(position, INDICATION_NORMAL)
    end

end

function CastingGuide:getIndication(position)
    return self.indicated:get(position)
end

function CastingGuide:unindicate(position)
    self.indicated:delete(position)
end

function CastingGuide:indicateWeak(position)
    if self.services.body:canBePassable(position) then
        self.indicated:set(position, INDICATION_WEAK)
    end

end

function CastingGuide:drawBelow()
    local pulseOpacity = Common.getPulseOpacity(self.services.timing.timePassed, MIN_OPACITY, MAX_OPACITY)
    local position = self.services.player:get().body:getPosition()
    for gridPosition, indicationColor in self.indicated() do
        if not self.indicateModeCancel or position ~= gridPosition then
            local clip = 1
            if indicationColor == INDICATION_NORMAL then
                graphics.wSetColor(COLORS.INDICATION_PLAYER:expandValues(pulseOpacity))
            else
                clip = 3
                graphics.wSetColor(COLORS.INDICATION_PLAYER:expandValues(pulseOpacity * WEAK_OPACITY_MULT))
            end

            local position = self.services.coordinates:gridToScreen(gridPosition)
            graphics.wRectangle(position.x + clip, position.y + clip, TILE_SIZE - clip * 2, TILE_SIZE - clip * 2)
        end

    end

    if self.indicateModeCancel then
        graphics.wSetColor(COLORS.INDICATION_MODE_CANCEL:expandValues(pulseOpacity))
        local position = self.services.coordinates:gridToScreen(position)
        graphics.wRectangle(position.x + 1, position.y + 1, TILE_SIZE - 2, TILE_SIZE - 2)
    end

end

function CastingGuide:drawAbove()
    local player = self.services.player:get()
    if self.displayArrows then
        local playerPosition = player.body:getPosition()
        local playerDirection = player.sprite.direction
        for direction in DIRECTIONS_AA() do
            local arrow
            graphics.wSetColor(WHITE)
            if self.displayArrows:contains(direction) then
                arrow = Utils.loadImage("casting_guide_arrow")
                if playerDirection == direction then
                    graphics.wSetColor(WHITE:blend(COLORS.INDICATION_PLAYER, 1))
                end

            end

            if arrow then
                local target = playerPosition + Vector[direction]
                local drawPosition = self.services.coordinates:gridToScreen(target)
                graphics.draw(arrow, drawPosition.x + TILE_SIZE / 2, drawPosition.y + TILE_SIZE / 2, playerPosition:angleTo(target), 1, 1, TILE_SIZE / 2, TILE_SIZE / 2)
            end

        end

    end

    if self._indicateMoveTo then
        local timePassed = self.services.timing.timePassed
        local drawCommand = player.sprite:getDrawCommand(timePassed)
        drawCommand.position = self.services.coordinates:gridToScreen(self._indicateMoveTo + MEASURES.SHADOWED_OFFSET) + drawCommand.origin
        drawCommand.opacity = Common.getPulseOpacity(timePassed, MOVE_MIN_OPACITY, MOVE_MAX_OPACITY)
        drawCommand:draw()
    end

end

function CastingGuide:_indicateCurrentAbility()
    local player = self.services.player:get()
    self.displayArrows = Utils.evaluate(self.currentAbility.directions, player, self.currentAbilityStats)
    if self.displayArrows and not self.displayArrows:contains(player.sprite.direction) then
        if self.displayArrows:isEmpty() then
            return 
        else
            local vDirection = Vector[player.sprite.direction]
            player.sprite:turnToDirection(self.displayArrows:minValue(function(a, b)
                return Vector[a]:distance(vDirection) < Vector[b]:distance(vDirection)
            end))
        end

    end

    self.currentAbility.indicate(player, player.sprite.direction, self.currentAbilityStats, self)
end

function CastingGuide:receiveMessage(message, abilityOrPosition, isSlotActive, slot)
            if message == Tags.UI_ABILITY_SELECTED then
        self:clear()
        self.currentAbility = abilityOrPosition
        if abilityOrPosition then
            self.currentAbilityStats = self.services.player:get().equipment:getSlotStats(slot)
            if isSlotActive then
                self.indicateModeCancel = true
            else
                self:_indicateCurrentAbility()
            end

        end

    elseif message == Tags.UI_CAST_TURN then
        if not self.indicateModeCancel and self.currentAbility then
            self:clear()
            self:_indicateCurrentAbility()
        end

    elseif message == Tags.UI_MOUSE_TILE_CHANGED then
        if not self.indicateModeCancel and self.currentAbility and self.displayArrows then
            local player = self.services.player:get()
            local playerPosition = player.body:getPosition()
            local gridPosition = abilityOrPosition
            local dx = abs(playerPosition.x - gridPosition.x)
            local dy = abs(playerPosition.y - gridPosition.y)
            if dx ~= dy then
                local direction = Common.getDirectionTowards(playerPosition, gridPosition)
                if direction ~= player.sprite.direction then
                    player.sprite:turnToDirection(direction)
                    self:clear()
                    self:_indicateCurrentAbility()
                end

            end

        end

    end

end

return CastingGuide

