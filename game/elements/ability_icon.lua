local AbilityIcon = class("elements.element")
local Rect = require("utils.classes.rect")
local Vector = require("utils.classes.vector")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local Global = require("global")
local DrawMethods = require("draw.methods")
local DrawText = require("draw.text")
local COLORS = require("draw.colors")
local FONTS = require("draw.fonts")
local FONT_SHORTCUT = FONTS.SMALL
local FONT_COOLDOWN = FONTS.MEDIUM_2
if PortSettings.IS_MOBILE then
    FONT_COOLDOWN = FONTS.LARGE_2
end

local MEASURES = require("draw.measures")
local ABILITY_SIZE = MEASURES.ABILITY_SIZE
local drawIconCommand = require("utils.love2d.draw_command"):new("abilities")
drawIconCommand:setRectFromDimensions(ABILITY_SIZE, ABILITY_SIZE)
drawIconCommand.position = Vector:new(4, 4)
drawIconCommand.shader = require("draw.shaders").FILTER_OUTLINE
if PortSettings.IS_MOBILE then
    drawIconCommand.scale = 2
    drawIconCommand.position = Vector:new(6, 6)
end

local FLASH_DURATION = 0.35
function AbilityIcon:GetSize()
    if PortSettings.IS_MOBILE then
        local profile = Global:get(Tags.GLOBAL_PROFILE)
        return 60 + ceil(profile.controlSize * 3.5) - 21
    else
        return ABILITY_SIZE + 8
    end

end

function AbilityIcon:GetMargin()
    if PortSettings.IS_MOBILE then
        return MEASURES.MARGIN_BUTTON + ceil(Global:get(Tags.GLOBAL_PROFILE).controlSize / 2) - 3
    else
        return MEASURES.MARGIN_BUTTON
    end

end

function AbilityIcon:initialize(slot, player, key)
    AbilityIcon:super(self, "initialize")
    self._player = player
    self.slot = slot
    self.key = key
    self.rect = Rect:new(0, 0, AbilityIcon:GetSize(), AbilityIcon:GetSize())
    self.isActivated = false
    self.flash = 0
    self:createInput(self.rect)
    self.input.shortcut = key
    self.input.triggerSound = "CONFIRM"
end

function AbilityIcon:evaluateIsActivated()
    return Utils.evaluate(self.isActivated, self, self.parent)
end

function AbilityIcon:getAbility()
    return self._player.equipment:getAbility(self.slot)
end

function AbilityIcon:update(dt)
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

function AbilityIcon:drawDurationText(duration)
    if duration < 1 then
        return 
    end

    local text = tostring(duration)
    local font = FONT_COOLDOWN
    if Global:get(Tags.GLOBAL_PROFILE).controlSize <= 3 then
        font = FONTS.MEDIUM_2
    end

    if duration > CONSTANTS.PRESUMED_INFINITE then
        if font == FONTS.LARGE_2 then
            text = " "
        else
            text = "¢"
        end

    end

    graphics.wSetFont(font)
    graphics.wSetColor(COLORS.NORMAL)
    local center = self.rect:center()
    if PortSettings.IS_MOBILE then
        center = center + Vector.UNIT_X * 2
    end

    DrawText.drawStroked(text, center.x - font:getStrokedWidth(text) / 2, center.y - font:getStrokedHeight() / 2)
end

function AbilityIcon:draw(serviceViewport, timePassed)
    local shortcutText = tostring(Common.getKeyName(self.key))
    local shortcutRect = Rect:new(-3, -3, FONT_SHORTCUT.height + 6, FONT_SHORTCUT.height + 6)
    local displayShortcut = not PortSettings.IS_MOBILE
    local textWidth = FONT_SHORTCUT:getWidth(shortcutText)
    if textWidth > FONT_SHORTCUT.height then
        shortcutRect.width = textWidth + 6
        if shortcutRect.width > self.rect.width + 6 then
            displayShortcut = false
        end

    end

    local borderColor
    local ability = self:getAbility()
    local bgColor = COLORS.STROKE
    local abilityColor = COLORS.NORMAL
    local isSlotActive = self._player.equipment:isSlotActive(self.slot)
    if ability then
        abilityColor = ability.iconColor or COLORS.NORMAL
        local isActivated = self:evaluateIsActivated()
        if isActivated then
            if isSlotActive then
                borderColor = COLORS.ABILITY_MODE_DEACTIVATE
            else
                borderColor = COLORS.NORMAL
            end

            graphics.wSetColor(borderColor)
            if displayShortcut then
                DrawMethods.fillClippedRect(shortcutRect:sizeAdjusted(1), 3)
            end

            DrawMethods.fillClippedRect(self.rect:sizeAdjusted(1), 3)
        else
            local item = self._player.equipment:get(self.slot)
            local sustained = self._player.equipment:getSustainedSlot()
                                    if isSlotActive then
                if sustained == self.slot then
                    borderColor = COLORS.ABILITY_MODE_SUSTAINED
                else
                    borderColor = COLORS.ABILITY_MODE_ACTIVE
                end

            elseif sustained then
                borderColor = COLORS.ABILITY_DISABLED
                abilityColor = COLORS.ABILITY_DISABLED
            elseif not self._player.equipment:hasResourcesForSlot(self.slot) then
                borderColor = COLORS.INSUFFICIENT_MANA
                abilityColor = COLORS.INSUFFICIENT_MANA
            else
                borderColor = COLORS.ABILITY_ACTIVE
            end

            borderColor = borderColor:blend(COLORS.NORMAL, min(1, self.input:getOpacity(false, true) * 2))
        end

        if isSlotActive then
            local pulseOpacity = Common.getPulseOpacity(timePassed, COLORS.SELECTED_MIN_OPACITY, COLORS.SELECTED_MAX_OPACITY)
            bgColor = bgColor:blend(borderColor, pulseOpacity / 4)
        end

    else
        borderColor = COLORS.DISABLED.NORMAL
    end

    graphics.wSetColor(COLORS.STROKE)
    DrawMethods.fillClippedRect(self.rect, 2)
    if ability and displayShortcut then
        DrawMethods.fillClippedRect(shortcutRect, 2)
    end

    graphics.wSetColor(borderColor)
    DrawMethods.fillClippedRect(self.rect:sizeAdjusted(-1), 1)
    graphics.wSetColor(bgColor)
    graphics.wRectangle(self.rect:sizeAdjusted(-2))
    if isSlotActive then
        local pulseOpacity = Common.getPulseOpacity(timePassed, COLORS.SELECTED_MIN_OPACITY, COLORS.SELECTED_MAX_OPACITY)
        graphics.wSetColor(borderColor:expandValues(pulseOpacity))
        DrawMethods.lineRect(self.rect:sizeAdjusted(-2))
        graphics.wSetColor(borderColor:expandValues(pulseOpacity / 2))
        DrawMethods.lineRect(self.rect:sizeAdjusted(-3))
        if displayShortcut then
            DrawMethods.fillClippedRect(shortcutRect:right() - 6, shortcutRect:bottom() - 6, 6, 6, 2)
        end

    end

    if not ability then
        return 
    end

    graphics.wSetColor(borderColor)
    if displayShortcut then
        DrawMethods.fillClippedRect(shortcutRect:sizeAdjusted(-1), 1)
        graphics.wSetColor(bgColor)
        graphics.wRectangle(shortcutRect:sizeAdjusted(-2))
        graphics.wSetFont(FONT_SHORTCUT)
        graphics.wSetColor(COLORS.NORMAL)
        DrawText.draw(shortcutText, shortcutRect:center().x - textWidth / 2, 0)
        Utils.stencilExclude(function()
            DrawMethods.fillClippedRect(shortcutRect, 1)
        end)
    end

    drawIconCommand.color = abilityColor
    drawIconCommand:setCell(ability.icon)
    if PortSettings.IS_MOBILE then
        local controlSize = Global:get(Tags.GLOBAL_PROFILE).controlSize
        local drawOffset = 6 + ceil(controlSize / 3) - 2
        drawIconCommand.position = Vector:new(drawOffset, drawOffset)
        local iconSize = self.rect.width - drawOffset * 2
        drawIconCommand.scale = iconSize / ABILITY_SIZE
        Debugger.drawText("drdr", drawOffset, drawIconCommand.scale)
    end

    drawIconCommand:draw()
    if displayShortcut then
        Utils.stencilDisable()
    end

    local cooldown = self._player.equipment:getCooldownFor(self.slot)
    if cooldown > 0 or self.flash > 0 then
        local maxCooldown = self._player.equipment:getSlotMaxCooldown(self.slot)
        local coverHeight = ceil(self.rect.height * cooldown / maxCooldown)
        if cooldown >= maxCooldown then
            cooldown = maxCooldown
            coverHeight = coverHeight - shortcutRect.y
        end

        Utils.stencilInclude(function()
            if displayShortcut then
                DrawMethods.fillClippedRect(shortcutRect, 2)
            end

            DrawMethods.fillClippedRect(self.rect, 2)
        end)
        if cooldown > 0 then
            graphics.wSetColor(COLORS.COOLDOWN_COVER_1)
            graphics.wRectangle(shortcutRect.x, shortcutRect.y, self.rect.width - shortcutRect.x, self.rect.height - shortcutRect.y - coverHeight)
            graphics.wSetColor(COLORS.COOLDOWN_COVER_2)
            graphics.wRectangle(shortcutRect.x, self.rect.y + self.rect.height - coverHeight, self.rect.width - shortcutRect.x, coverHeight)
        end

        if self.flash > 0 then
            graphics.wSetColor(WHITE:expandValues(self.flash * self.flash))
            graphics.wRectangle(shortcutRect.x, shortcutRect.y, self.rect.width - shortcutRect.x, self.rect.height - shortcutRect.y)
        end

        Utils.stencilDisable()
        if cooldown > 0 then
            self:drawDurationText(cooldown)
        end

    end

    if isSlotActive then
        self:drawDurationText(self._player.equipment:getDuration(self.slot))
    end

end

return AbilityIcon

