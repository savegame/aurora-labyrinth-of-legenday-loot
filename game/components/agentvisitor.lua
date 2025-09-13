local AgentVisitor = require("components.create_class")()
local ActionUtils = require("actions.utils")
function AgentVisitor:visit(callback, isRandom, isAlive)
    local entities = self.system.services.agent.entities
    if isRandom then
        entities = entities:shuffle(self.system.services.logicrng)
    else
        entities = entities:clone()
    end

    for entity in entities() do
        if not entity.body.removedFromGrid then
            if not isAlive or ActionUtils.isAliveAgent(entity) then
                local value = callback(entity)
                if value then
                    return value
                end

            end

        end

    end

    return nil
end

function AgentVisitor:getSystemAgent()
    return self.system.services.agent
end

function AgentVisitor.System:initialize()
    AgentVisitor.System:super(self, "initialize")
    self:setDependencies("logicrng", "agent")
end

return AgentVisitor

