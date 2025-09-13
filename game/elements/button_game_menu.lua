local ButtonGameMenu = class("elements.button")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local DrawCommand = require("utils.love2d.draw_command")
local Common = require("common")
local DrawText = require("draw.text")
local FONT = require("draw.fonts").MEDIUM
local MEASURES = require("draw.measures")
ButtonGameMenu.SIZE = 26
if PortSettings.IS_MOBILE then
    ButtonGameMenu.SIZE = 50
end

local ICON_SIZE = 20
function ButtonGameMenu:initialize(icon)
    ButtonGameMenu:super(self, "initialize", ButtonGameMenu.SIZE, ButtonGameMenu.SIZE)
    self.imageDC = DrawCommand:new("gamemenu")
    self.imageDC.rect = Rect:new(0, 0, ICON_SIZE, ICON_SIZE)
    self.imageDC:setCell(icon)
    self.imageDC:setOriginToCenter()
    if PortSettings.IS_MOBILE then
        self.imageDC.scale = 2
    end

    self.imageDC.position = self.rect:center()
end

function ButtonGameMenu:draw()
    ButtonGameMenu:super(self, "draw")
    local colorSource = self:getColorSource()
    local source = self.imageDC.position
    self.imageDC.position = source
    self.imageDC:draw()
    if not PortSettings.IS_MOBILE and self.input.state == Tags.INPUT_HOVERED then
        local text = Common.getKeyName(self.input.shortcut)
        graphics.wSetFont(FONT)
        local width = FONT:getStrokedWidth(text)
        DrawText.drawStroked(text, self.rect.width / 2 - width / 2, self.rect.height + 4)
    end

end

return ButtonGameMenu

