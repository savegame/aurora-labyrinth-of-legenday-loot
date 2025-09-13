local Viewport = class("services.service")
local Vector = require("utils.classes.vector")
local WINDOW_LIMITS = require("window_limits")
function Viewport:initialize()
    Viewport:super(self, "initialize")
    self:refreshScreenDimensions()
end

function Viewport:getScale()
    return self._scale
end

function Viewport:getCenter()
    return self._center
end

function Viewport:refreshScreenDimensions()
    local totalWidth, totalHeight = graphics.getDimensions()
    self._scale = max(1, min(floor(totalWidth / WINDOW_LIMITS.WIDTH), floor(totalHeight / WINDOW_LIMITS.HEIGHT)))
    self.screenWidth = ceil(totalWidth / self._scale)
    self.screenHeight = ceil(totalHeight / self._scale)
    self._center = Vector:new(self.screenWidth / 2, self.screenHeight / 2)
    Debugger.log("Screen Dimensions:", self.screenWidth, self.screenHeight)
end

function Viewport:getScreenDimensions()
    return self.screenWidth, self.screenHeight
end

function Viewport:getMousePosition()
    local mx, my = mouse.getPosition()
    local dpiScale = 1
    return Vector:new(mx / self._scale * dpiScale, my / self._scale * dpiScale)
end

function Viewport:graphicsScale()
    graphics.scale(self._scale)
end

function Viewport:toNearestScale(position)
    if type(position) == "number" then
        return round(position * self._scale) / self._scale
    else
        return (position * self._scale):roundXY() / self._scale
    end

end

if PortSettings.IS_MOBILE then
    function Viewport:toNearestScale(position)
        return position
    end

end

function Viewport:drawCover(cover)
    graphics.wSetColor(0, 0, 0, cover)
    graphics.wRectangle(-1, -1, self.screenWidth + 2, self.screenHeight + 2)
end

return Viewport

