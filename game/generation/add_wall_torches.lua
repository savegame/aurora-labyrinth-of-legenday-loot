local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
return function(command)
    local level = command.level
    for room in command.rooms() do
        local maxWidth, maxHeight = room:getMaxDimensions()
        local upperWall = Array:new()
        local position = room:getPosition()
        for ix = position.x, position.x + maxWidth - 1 do
            local topY = math.huge
            for rect in room.rects() do
                if rect:containsX(ix) then
                    topY = min(topY, rect.y)
                end

            end

            local wallPos = Vector:new(ix, topY - 1)
            if topY < math.huge and level.tiles:get(wallPos).isBlocking then
                upperWall:push(wallPos)
            end

        end

        local currentLeft = 2
        local currentRight = 2
        while upperWall:size() > currentLeft do
            local wallPos = upperWall[currentLeft]
            if level.tiles:get(wallPos + Vector[LEFT]).isBlocking and level.tiles:get(wallPos + Vector[RIGHT]).isBlocking and level.tiles:get(wallPos + Vector[UP]).isBlocking then
                level:setObject(wallPos, "wall_torch", LEFT)
                break
            else
                currentLeft = currentLeft + 1
            end

        end

        while upperWall:size() > currentLeft + currentRight + 1 do
            local wallPos = upperWall[upperWall:size() - currentRight + 1]
            if level.tiles:get(wallPos + Vector[LEFT]).isBlocking and level.tiles:get(wallPos + Vector[RIGHT]).isBlocking and level.tiles:get(wallPos + Vector[UP]).isBlocking then
                level:setObject(wallPos, "wall_torch", RIGHT)
                break
            else
                currentRight = currentRight + 1
            end

        end

    end

end

