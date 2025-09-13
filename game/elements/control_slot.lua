local ControlSlot = class("elements.list_slot")
local FONT = require("draw.fonts").MEDIUM
local COLORS = require("draw.colors")
local DrawText = require("draw.text")
local TERM_CONTROLS = require("text.terms").CONTROLS
local COLOR_KEY = COLORS.TEXT_COLOR_PALETTE:get("NUMBER")
function ControlSlot:initialize(width, profile, profileField, code)
    ControlSlot:super(self, "initialize", width, true)
    self.profile = profile
    self.profileField = profileField
    self.code = code
    self.label = TERM_CONTROLS[code]
end

function ControlSlot:draw(serviceViewport, timePassed)
    ControlSlot:super(self, "draw", timePassed)
    graphics.wSetFont(FONT)
    graphics.wSetColor(COLOR_KEY)
    local text = self.profile:getKeyName(self.code, self.profileField)
    local textY = (self.rect.height - FONT:getStrokedHeight()) / 2
    DrawText.drawStroked(text, self.rect.width - self.textXNoIcon - FONT:getWidth(text) - 2, textY)
end

return ControlSlot

