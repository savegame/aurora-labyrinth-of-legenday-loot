local graphics = love.graphics
local oldDraw = graphics.draw
local Array = require("utils.classes.array")
local Color = require("utils.classes.color")
function graphics.wSetColor(color,...)
        if not color then
        graphics.wSetColor(Color.WHITE)
    elseif type(color) == "number" then
        local colors = Array:new(color, ...)
        for c in colors() do
            Utils.assert(c <= 1.5, "Colors should be in range 0-1")
        end

        return graphics.setColor(color, ...)
    else
        local colors = Array:new(color.r, color.g, color.b, color.a)
        for c in colors() do
            Utils.assert(c <= 1.5, "Colors should be in range 0-1")
        end

        return graphics.setColor(color:expand())
    end

end

function graphics.wGetColor()
    return Color:new(graphics.getColor())
end

function graphics.wRectangle(rect, y, width, height)
    if type(rect) == "number" then
        graphics.rectangle("fill", rect, y, width, height)
    else
        graphics.rectangle("fill", rect:expand())
    end

end

function graphics.wCircle(circle, y, radius)
    if type(circle) == "number" then
        graphics.circle("fill", circle, y, radius, max(20, ceil(radius / 2)))
    else
        radius = y or circle.radius
        graphics.circle("fill", circle.x, circle.y, radius, max(20, ceil(radius / 2)))
    end

end

function graphics.wDraw(drawable, quad, position, r, scale, offset, shear)
    local arguments = Array:new(drawable)
    if not quad.type or quad:type() ~= "Quad" then
        position, r, scale, offset, shear = quad, position, r, scale, offset
    else
        arguments:push(quad)
    end

    arguments:push(position)
    if r then
        arguments:push(r)
        if scale then
            arguments:pushMultiple(scale.x, scale.y)
            if offset then
                arguments:pushMultiple(offset.x, offset.y)
                if shear then
                    arguments:pushMultiple(shear.x, shear.y)
                end

            end

        end

    end

    graphics.draw(arguments:expand())
end


