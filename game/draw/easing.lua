local EASING = {  }
EASING.LINEAR = function(x)
    return x
end
EASING.QUAD = function(x)
    return x * x
end
EASING.OUT_QUAD = function(x)
    return x * (2 - x)
end
EASING.CUBIC = function(x)
    return x * x * x
end
EASING.OUT_CUBIC = function(x)
    local x = x - 1
    return x * x * x + 1
end
EASING.IN_OUT_QUAD = function(x)
    x = x * 2
    if x < 1 then
        return x * x / 2
    else
        return (1 - (x - 1) * (x - 3)) / 2
    end

end
EASING.IN_OUT_QUAD_INVERSE = function(x)
    if x < 0.5 then
        return math.sqrt(x / 2)
    else
        return 1 - math.sqrt((1 - x) / 2)
    end

end
EASING.IN_OUT_CUBIC = function(x)
    x = x * 2
    if x < 1 then
        return x * x * x / 2
    else
        x = x - 2
        return (x * x * x + 2) / 2
    end

end
EASING.IN_OUT_QUART = function(x)
    x = x * 2
    if x < 1 then
        return x * x * x * x / 2
    else
        x = x - 2
        return (2 - x * x * x * x) / 2
    end

end
EASING.PARABOLIC_HEIGHT = function(x)
    x = 2 * (x - 0.5)
    return 1 - x * x
end
return EASING

