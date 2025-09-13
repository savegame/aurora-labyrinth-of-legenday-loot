local DisplayScrap = class("widgets.widget")
local Vector = require("utils.classes.vector")
local LogicMethods = require("logic.methods")
local MEASURES = require("draw.measures")
local MARGIN_SCREEN = MEASURES.MARGIN_SCREEN
local FONT = require("draw.fonts").MEDIUM
local MARGIN = 4 + 1
local FLASH_DURATION = 0.35
function DisplayScrap:initialize(director, wallet, barWidth, floorWidth)
    DisplayScrap:super(self, "initialize")
    self.barWidth = barWidth
    self.floorWidth = floorWidth
    if PortSettings.IS_MOBILE then
        self.alignment = Vector:new(0.0, 0)
        self:setPosition(0, MARGIN_SCREEN)
    else
        self.alignment = DOWN_LEFT
        self:setPosition(MARGIN_SCREEN * 2 + self.barWidth, MARGIN_SCREEN)
    end

    self._wallet = wallet
    self.displayedScrap = wallet:get()
    self.window = self:addElement("window", 0, 0, 32, FONT.height + MARGIN * 2)
    self.window.hasBorder = false
    self.text = self:addElement("text_special", MARGIN - 1, MARGIN, "{ICON:SALVAGE}", FONT)
    self.alignHeight = self.window.rect.height
    self:updateWithDisplayedScrap()
    self.window.flash = 0
end

function DisplayScrap:updateWithDisplayedScrap()
    local text = "{ICON:SALVAGE} " .. tostring(self.displayedScrap)
    self.text:setText(text)
    self.window.rect.width = self.text:getWidth() + MARGIN * 2 + 1
    self.window.flash = 1
end

function DisplayScrap:update(dt, serviceViewport)
    self.window.flash = max(0, self.window.flash - dt / FLASH_DURATION)
    if self.displayedScrap ~= self._wallet:get() then
        self.displayedScrap = self._wallet:get()
        self:updateWithDisplayedScrap()
    end

    if PortSettings.IS_MOBILE and serviceViewport then
        Debugger.drawText("FW", self.floorWidth, self.barWidth)
        local scW, scH = serviceViewport:getScreenDimensions()
        local spaceWidth
        self:setPosition((scW / 2 - self.barWidth - MEASURES.MARGIN_INTERNAL / 2 - (MEASURES.MARGIN_SCREEN + self.floorWidth) - self.window.rect.width) / 2 + MEASURES.MARGIN_SCREEN + self.floorWidth, self.position.y)
    end

end

return DisplayScrap

