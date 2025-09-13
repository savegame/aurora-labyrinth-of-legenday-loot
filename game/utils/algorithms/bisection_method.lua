return function(targetFX, startingX, startingOffset, fn, epsilon)
    epsilon = epsilon or 0.00001
    local currentX, currentOffset = startingX, startingOffset
    local lastSign = 0
    while true do
        local fx = fn(currentX)
        if abs(fx - targetFX) <= epsilon then
            return currentX
        end

        local signDiff = sign(targetFX - fx)
        currentX = currentX + signDiff * currentOffset
        if lastSign ~= signDiff then
            lastSign = signDiff
            currentOffset = currentOffset / 2
        end

    end

end

