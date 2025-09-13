local BossHealth = class("widgets.widget")
local NAME = require("text.terms").ENEMIES["final_boss"]
local BAR_HEIGHT = require("elements.resource_bar").HEIGHT
local MEASURES = require("draw.measures")
function BossHealth:initialize(entity)
    BossHealth:super(self, "initialize")
    self.entity = entity
    self.alignment = UP
    self:setPosition(0, MEASURES.MARGIN_SCREEN)
    if PortSettings.IS_MOBILE then
        self:setPosition(0, MEASURES.MARGIN_SCREEN * 2 + BAR_HEIGHT)
    else
        self:setPosition(0, MEASURES.MARGIN_SCREEN)
    end

    self.barHealth = self:addElement("resource_bar", 0, 0, MEASURES.WIDTH_RESOURCE_BAR_BOSS, self.entity.tank, true)
    self.barHealth.textOverride = ""
    self.barHealth.getStrokeColor = function()
        return entity.sprite.strokeColor
    end
    self.barHealth.isVisible = function()
        return entity.tank:isAlive()
    end
    self.alignWidth = MEASURES.WIDTH_RESOURCE_BAR_BOSS
end

return BossHealth

