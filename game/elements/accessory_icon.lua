local AccessoryIcon = class("elements.element")
local Common = require("common")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local DrawCommand = require("utils.love2d.draw_command")
local DrawMethods = require("draw.methods")
local DrawText = require("draw.text")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local ITEM_SIZE = MEASURES.ITEM_SIZE
local FONT = require("draw.fonts").SMALL_2
local drawIconCommand = DrawCommand:new("items")
drawIconCommand:setRectFromDimensions(ITEM_SIZE, ITEM_SIZE)
drawIconCommand.position = Vector:new(4, 4)
local strokeCommand = DrawCommand:new("items_stroke")
strokeCommand:setRectFromDimensions(ITEM_SIZE + 2, ITEM_SIZE + 2)
strokeCommand.position = Vector:new(3, 3)
AccessoryIcon.SIZE = ITEM_SIZE + 8
local FLASH_DURATION = 0.35
function AccessoryIcon:initialize(slot, player)
    AccessoryIcon:super(self, "initialize")
    self._player = player
    self.slot = slot
    self.rect = Rect:new(0, 0, AccessoryIcon.SIZE, AccessoryIcon.SIZE)
    self.flash = 0
    self:createInput(self.rect)
end

function AccessoryIcon:evaluateIsVisible()
    local item = self._player.equipment:get(self.slot)
    if not item then
        return false
    end

    if item.stats:get(Tags.STAT_ABILITY_COOLDOWN, 0) <= 0 then
        return false
    end

    return AccessoryIcon:super(self, "evaluateIsVisible")
end

function AccessoryIcon:update(dt)
    local alert = self._player.equipment:getAndConsumeAlert(self.slot)
        if alert then
        if alert ~= Tags.ALERT_NO_SOUND then
            Common.playSFX("SLOT_ALERT")
        end

        self.flash = 1
    elseif self.flash > 0 then
        self.flash = max(0, self.flash - dt / FLASH_DURATION)
    end

end

function AccessoryIcon:draw(serviceViewport, timePassed)
    local borderColor = COLORS.ABILITY_ACTIVE
    borderColor = borderColor:blend(COLORS.NORMAL, min(1, self.input:getOpacity(false, true) * 2))
    graphics.wSetColor(COLORS.STROKE)
    DrawMethods.fillClippedRect(self.rect, 2)
    graphics.wSetColor(borderColor)
    DrawMethods.fillClippedRect(self.rect:sizeAdjusted(-1), 1)
    graphics.wSetColor(COLORS.STROKE)
    graphics.wRectangle(self.rect:sizeAdjusted(-2))
    local item = self._player.equipment:get(self.slot)
    if item then
        drawIconCommand:setCell(item:getIcon())
        drawIconCommand:draw()
        local iconStrokeColor = item:getStrokeColor()
        if iconStrokeColor then
            strokeCommand:setCell(item:getIcon())
            strokeCommand.color = iconStrokeColor
            strokeCommand:draw()
        end

    end

    local cooldown = self._player.equipment:getCooldownFor(self.slot)
    if cooldown > 0 or self.flash > 0 then
        local maxCooldown = self._player.equipment:getSlotMaxCooldown(self.slot)
        cooldown = min(maxCooldown, cooldown)
        local coverHeight = ceil(self.rect.height * cooldown / maxCooldown)
        Utils.stencilInclude(function()
            DrawMethods.fillClippedRect(self.rect, 2)
        end)
        if cooldown > 0 then
            graphics.wSetColor(COLORS.COOLDOWN_COVER_1)
            graphics.wRectangle(self.rect)
            graphics.wSetColor(COLORS.COOLDOWN_COVER_2)
            graphics.wRectangle(self.rect.x, self.rect:bottom() - coverHeight, self.rect.width, coverHeight)
        end

        if self.flash > 0 then
            graphics.wSetColor(WHITE:expandValues(self.flash * self.flash))
            graphics.wRectangle(self.rect)
        end

        Utils.stencilDisable()
        if cooldown > 0 then
            graphics.wSetFont(FONT)
            graphics.wSetColor(COLORS.NORMAL)
            local center = self.rect:center()
            local text = tostring(cooldown)
            DrawText.drawStroked(text, center.x - FONT:getStrokedWidth(text) / 2, center.y - FONT:getStrokedHeight() / 2)
        end

    end

end

return AccessoryIcon

