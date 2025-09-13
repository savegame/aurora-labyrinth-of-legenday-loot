local DrawCommands = class("elements.element")
local DrawCommand = require("utils.love2d.draw_command")
function DrawCommands:initialize(commands)
    DrawCommands:super(self, "initialize")
    self.commands = commands or false
end

function DrawCommands:draw()
    local commands = Utils.evaluate(self.commands, self)
    if DrawCommand:isInstance(commands) then
        commands:draw(0, 0)
    else
        for command in commands() do
            command:draw(0, 0)
        end

    end

end

return DrawCommands

