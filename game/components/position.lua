local Position = require("components.create_class")()
function Position:initialize(entity, position)
    Position:super(self, "initialize")
    self.position = position or false
end

function Position:setPosition(newPosition)
    self.position = newPosition
end

function Position:getPosition()
    return self.position
end

return Position

