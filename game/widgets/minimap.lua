local Minimap = class("widgets.widget")
local MEASURES = require("draw.measures")
local FONTS = require("draw.fonts")
function Minimap:initialize(director, level, vision, systemIndicator)
    Minimap:super(self, "initialize")
    local width, height = level:getDimensions()
    local SIZE = MEASURES.MINIMAP_SIZE
    self.alignWidth = width * SIZE
    self.alignHeight = height * SIZE
    if PortSettings.IS_MOBILE then
        self.alignment = UP_LEFT
        self:setPosition(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN * 2 + FONTS.MEDIUM:getStrokedHeight())
    else
        self.alignment = DOWN_RIGHT
        self:setPosition(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN)
    end

    self.minimap = self:addElement("minimap", 0, 0, level, vision, systemIndicator)
    director:subscribe(Tags.UI_REFRESH_EXPLORED, self)
end

function Minimap:refreshCanvas()
    self.minimap:refreshCanvas()
end

function Minimap:receiveMessage(message)
    if message == Tags.UI_REFRESH_EXPLORED then
        self.minimap:refreshCanvas()
    end

end

return Minimap

