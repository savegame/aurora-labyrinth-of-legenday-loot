local DrawText = {  }
local Color = require("utils.classes.color")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local FONTS = require("draw.fonts")
function DrawText.draw(str, x, y)
    x, y = x or 0, y or 0
    local offset = FONTS.get().offset
    graphics.print(str, x + offset.x, y + offset.y)
end

function DrawText.drawStroked(str, x, y)
    local colorMain = Color:new(graphics.getColor())
    graphics.wSetColor(COLORS.STROKE:expandValues(colorMain.a))
    for ix, iy in Utils.gridIterator(0, 2, 0, 2) do
        DrawText.draw(str, x + ix, y + iy)
    end

    graphics.wSetColor(colorMain)
    DrawText.draw(str, x + 1, y + 1)
end

function DrawText.drawStrokedCentered(str, x, y)
    local font = FONTS.get()
    DrawText.drawStroked(str, x - font:getStrokedWidth(str) / 2, y)
end

function DrawText.splitToLines(str, font, width, isStroked)
    local getWidth
    if isStroked then
        getWidth = font.getStrokedWidth
    else
        getWidth = font.getWidth
    end

    local words = str:split(" "):reversed()
    local currentLine, lineTest = "", ""
    local result = Array:new()
    while words.n > 0 do
        local word = words:pop()
        if currentLine ~= "" then
            lineTest = currentLine .. " " .. word
            if getWidth(font, lineTest) <= width then
                currentLine = lineTest
            else
                result:push(currentLine)
                currentLine = word
            end

        else
            currentLine = word
        end

    end

    if currentLine ~= "" then
        result:push(currentLine)
    end

    return result
end

return DrawText

