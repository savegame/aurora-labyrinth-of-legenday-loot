local TextSpecial = class()
local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local FONTS = require("draw.fonts")
local DrawText = require("draw.text")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local ICON_SIZE = MEASURES.TEXT_ICON_SIZE
local ICON_SPACE = MEASURES.TEXT_ICON_SPACE
local BYTE_OPENING = ("{"):byte()
local BYTE_CLOSING = ("}"):byte()
local iconDrawCommand = require("utils.love2d.draw_command"):new("text_icons")
iconDrawCommand.rect = Rect:new(0, 0, ICON_SIZE, ICON_SIZE)
local TextCommand = struct("command", "arg")
Tags.add("FORCE_NEWLINE", 1)
function TextSpecial:initialize(font, text, isStroked)
    self.font = font
    self.isStroked = isStroked or false
    self.baseColor = COLORS.NORMAL
    self.currentColor = self.baseColor
    self.tempBaseColor = false
    self.spaceWidth = font:getWidth("a a") - font:getWidth("a") * 2
    if isStroked then
        self.spaceWidth = self.spaceWidth - 2
    end

    self.width = math.huge
    self:setText(text)
end

function TextSpecial:getFontHeight()
    if self.isStroked then
        return self.font:getStrokedHeight()
    else
        return self.font.height
    end

end

function TextSpecial:_getSpaceLine()
    if self.isStroked then
        return self.font.spaceLine
    else
        return self.font.spaceLine + 2
    end

end

function TextSpecial:draw(serviceViewport, x, y)
    graphics.wSetFont(self.font)
    local lineOffset = self:getFontHeight() + self:_getSpaceLine()
    local currentX, currentY = x, y
    self.tempBaseColor = false
    for token in self.tokens() do
        local tokenWidth = self:getTokenWidth(token)
        if (token == Tags.FORCE_NEWLINE) or (currentX > x and currentX - x + tokenWidth > self.width) then
            currentX = x
            currentY = currentY + lineOffset
        end

        if token ~= Tags.FORCE_NEWLINE then
            currentX = self:drawToken(serviceViewport, token, currentX, currentY) + self.spaceWidth
        end

    end

end

function TextSpecial:getTotalHeight()
    local currentX, currentY = 0, 0
    local lineOffset = self:getFontHeight() + self:_getSpaceLine()
    for token in self.tokens() do
        local tokenWidth = self:getTokenWidth(token)
        if (token == Tags.FORCE_NEWLINE) or (currentX > 0 and currentX + tokenWidth > self.width) then
            currentX = 0
            currentY = currentY + lineOffset
        end

        if token ~= Tags.FORCE_NEWLINE then
            currentX = currentX + self:getTokenWidth(token) + self.spaceWidth
        end

    end

    return currentY + self:getFontHeight()
end

function TextSpecial:drawToken(serviceViewport, token, x, y)
    self.currentColor = self.baseColor
    if self.tempBaseColor then
        self.currentColor = self.tempBaseColor
    end

    if Array:isInstance(token) then
        local isFirst = true
        for i, fragment in ipairs(token) do
            self:drawFragment(serviceViewport, fragment, x, y)
            local width = self:getFragmentWidth(fragment, isFirst)
            if width > 0 then
                isFirst = false
            end

            x = x + width
        end

        return x
    else
        self:drawFragment(serviceViewport, token, x, y)
        return x + self:getFragmentWidth(token, true)
    end

end

function TextSpecial:drawFragment(serviceViewport, fragment, x, y)
    if TextCommand:isInstance(fragment) then
                        if fragment.command == "ICON" or fragment.command == "I" then
            local iconX = x + ICON_SPACE
            if not self.isStroked then
                iconX = iconX + 1
            end

            iconDrawCommand.position = serviceViewport:toNearestScale(Vector:new(iconX, y + (self:getFontHeight() - ICON_SIZE) / 2))
            iconDrawCommand:setCell(COLORS.TEXT_ICON_PALETTE:get(fragment.arg))
            iconDrawCommand:draw()
        elseif fragment.command == "COLOR" or fragment.command == "C" then
            if fragment.arg == "BASE" then
                if self.tempBaseColor then
                    self.currentColor = self.tempBaseColor
                else
                    self.currentColor = self.baseColor
                end

            else
                self.currentColor = COLORS.TEXT_COLOR_PALETTE:get(fragment.arg)
                Utils.assert(Color:isInstance(self.currentColor), "Unknown color: %s", fragment.arg)
            end

        elseif fragment.command == "BASE_CHANGE" or fragment.command == "B" then
            if fragment.arg == "BASE" then
                self.tempBaseColor = false
                self.currentColor = self.baseColor
            else
                if self.currentColor == self.tempBaseColor then
                    self.currentColor = self.baseColor
                end

                self.tempBaseColor = COLORS.TEXT_COLOR_PALETTE:get(fragment.arg)
                Utils.assert(Color:isInstance(self.tempBaseColor), "Unknown color: %s", fragment.arg)
                if self.currentColor == self.baseColor then
                    self.currentColor = self.tempBaseColor
                end

            end

        end

    else
        graphics.wSetColor(self.currentColor)
        if self.isStroked then
            DrawText.drawStroked(fragment, x, y)
        else
            DrawText.draw(fragment, x, y)
        end

    end

end

function TextSpecial:getTotalWidth()
    if self.tokens:size() > 0 then
        return self.tokens:map(function(token)
            return self:getTokenWidth(token) + self.spaceWidth
        end):sum() - self.spaceWidth
    else
        return 0
    end

end

function TextSpecial:getTokenWidth(token)
    if Array:isInstance(token) then
        local sum = 0
        local isFirst = true
        for i, fragment in ipairs(token) do
            local width = self:getFragmentWidth(fragment, isFirst)
            if width > 0 then
                isFirst = false
            end

            sum = sum + width
        end

        return sum
    else
        return self:getFragmentWidth(token, true)
    end

end

function TextSpecial:getFragmentWidth(fragment, isFirst)
            if fragment == Tags.FORCE_NEWLINE then
        return 0
    elseif TextCommand:isInstance(fragment) then
        if fragment.command == "ICON" or fragment.command == "I" then
            if self.isStroked then
                return ICON_SPACE * 2 + ICON_SIZE
            else
                return (ICON_SPACE + 1) * 2 + ICON_SIZE
            end

        else
            if isFirst then
                return 0
            else
                return 1
            end

        end

    elseif self.isStroked then
        return self.font:getStrokedWidth(fragment)
    else
        return self.font:getWidth(fragment)
    end

end

local function fragmentCommands(token)
    local fragments = Array:new()
    local starting = 1
    local length = token:len()
    for i = 1, length + 1 do
        local b = token:byte(i)
        if b == BYTE_OPENING or b == BYTE_CLOSING or i == length + 1 then
            if i - 1 >= starting then
                local substr = token:sub(starting, i - 1)
                if b == BYTE_CLOSING then
                    if substr == "FORCE_NEWLINE" then
                        fragments:push(Tags.FORCE_NEWLINE)
                    else
                        local splitted = substr:split(":")
                        fragments:push(TextCommand:new(splitted[1], splitted[2]))
                    end

                else
                    fragments:push(substr)
                end

            end

            starting = i + 1
        end

    end

    if fragments:size() == 1 then
        return fragments[1]
    else
        return fragments
    end

end

function TextSpecial:setText(text)
    self.tokens = text:split(" "):map(function(token)
        return fragmentCommands(token)
    end)
end

return TextSpecial

