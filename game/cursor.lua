local Cursor = class()
local DEFAULT_CURSOR = "pointer"
local Hash = require("utils.classes.hash")
local MEASURES = require("draw.measures")
local CURSOR_ORIGIN = {  }
CURSOR_ORIGIN["pointer"] = UP_LEFT
CURSOR_ORIGIN["pointer_red"] = UP_LEFT
CURSOR_ORIGIN["typing"] = CENTER
CURSOR_ORIGIN["crosshair"] = CENTER
CURSOR_ORIGIN["crosshair_red"] = CENTER
function Cursor:initialize()
    self._cursorCache = Hash:new()
    self._currentCursor = false
    self.defaultCursor = DEFAULT_CURSOR
end

function Cursor:_createCursor(cursor, scale)
    if PortSettings.IS_MOBILE then
        return false
    end

    Utils.assert(CURSOR_ORIGIN[cursor], "Unknown cursor: %s", cursor)
    local image = graphics.newImage("graphics/cursors/" .. cursor .. ".png")
    local iW, iH = image:getDimensions()
    local scratch = graphics.newCanvas(iW * scale, iH * scale)
    graphics.setCanvas(scratch)
    graphics.push()
    graphics.origin()
    graphics.clear(0, 0, 0, 0)
    graphics.wSetColor(WHITE)
    graphics.scale(scale)
    graphics.draw(image)
    graphics.pop()
    graphics.setCanvas()
    local data = scratch:newImageData(1, 1, 0, 0, iW * scale, iH * scale)
    local alignVector = MEASURES.ALIGNMENT[CURSOR_ORIGIN[cursor]]
    return mouse.newCursor(data, iW * scale * alignVector.x, iH * scale * alignVector.y)
end

function Cursor:updateCursor(cursor, scale)
    scale = floor(scale)
    local key = cursor .. ":" .. scale
    if key ~= self._currentCursor then
        if not self._cursorCache:hasKey(key) then
            self._cursorCache:set(key, self:_createCursor(cursor, scale))
        end

        local cursor = self._cursorCache:get(key)
        if cursor then
            mouse.setCursor(self._cursorCache:get(key))
        end

        self._currentCursor = key
    end

end

return Cursor

