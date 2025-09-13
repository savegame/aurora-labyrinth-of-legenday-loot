local DrawMethods = {  }
function DrawMethods.point(x, y)
    graphics.wRectangle(x, y, 1, 1)
end

function DrawMethods.lineRect(x, y, width, height)
    if type(x) == "table" then
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    graphics.wRectangle(x, y, width, 1)
    graphics.wRectangle(x, y + 1, 1, height - 2)
    graphics.wRectangle(x + width - 1, y + 1, 1, height - 2)
    graphics.wRectangle(x, y + height - 1, width, 1)
end

function DrawMethods.fillClippedRect(x, y, width, height, clip, excludeTop, excludeBottom)
    if type(x) == "table" then
        clip, excludeTop, excludeBottom = y, width, height
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    local topClip, bottomClip = choose(excludeTop, 0, clip), choose(excludeBottom, 0, clip)
    graphics.wRectangle(x, y + topClip, width, height - topClip - bottomClip)
    for i = 1, clip do
        if not excludeTop then
            graphics.wRectangle(x + clip - i + 1, y + i - 1, width - (clip - i) * 2 - 2, 1)
        end

        if not excludeBottom then
            graphics.wRectangle(x + clip - i + 1, y + height - i, width - (clip - i) * 2 - 2, 1)
        end

    end

end

function DrawMethods.lineClippedRect(x, y, width, height, clip, excludeTop, excludeBottom)
    if type(x) == "table" then
        clip, excludeTop, excludeBottom = y, width, height
        x, y, width, height = x.x, x.y, x.width, x.height
    end

    local topClip, bottomClip = choose(excludeTop, 0, clip), choose(excludeBottom, 0, clip)
    if excludeTop then
        graphics.wRectangle(x + 1, y, width - 2, 1)
    else
        graphics.wRectangle(x + topClip, y, width - topClip * 2, 1)
    end

    if excludeBottom then
        graphics.wRectangle(x + 1, y + height - 1, width - 2, 1)
    else
        graphics.wRectangle(x + bottomClip, y + height - 1, width - bottomClip * 2, 1)
    end

    graphics.wRectangle(x, y + topClip, 1, height - topClip - bottomClip)
    graphics.wRectangle(x + width - 1, y + topClip, 1, height - topClip - bottomClip)
    for i = 1, clip - 1 do
        if not excludeTop then
            DrawMethods.point(x + clip - i, y + i)
            DrawMethods.point(x + width + i - clip - 1, y + i)
        end

        if not excludeBottom then
            DrawMethods.point(x + i, y + height + i - clip - 1)
            DrawMethods.point(x + width - i - 1, y + height + i - clip - 1)
        end

    end

end

function DrawMethods.bar(x, y, width, height, currentValue, maxValue)
    if type(x) == "table" then
        x, y, width, height, currentValue, maxValue = x.x, x.y, x.width, x.height, y, width
    end

    local ratio
    if maxValue then
        ratio = currentValue / maxValue
    else
        ratio = currentValue
    end

    graphics.wRectangle(x, y, ceil(bound(ratio, 0, 1) * width), height)
end

function DrawMethods.getPulseOpacity(timePassed, pulseTime, pulseMin, pulseMax)
    pulseMin = pulseMin or 0.5
    pulseMax = pulseMax or 1
    local hDiff = (pulseMax - pulseMin) / 2
    return (hDiff * (sin(timePassed / pulseTime * math.tau) + 1) + pulseMin)
end

return DrawMethods

