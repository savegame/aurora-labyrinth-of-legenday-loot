local OverseerBase = class("services.service")
function OverseerBase:initialize()
    OverseerBase:super(self, "initialize")
    self.currentTurn = 0
    self:setDependencies("level", "logicrng", "director", "createEntity", "player", "run")
end

function OverseerBase:toData()
    return { currentTurn = self.currentTurn }
end

function OverseerBase:fromData(data)
    self.currentTurn = data.currentTurn
end

function OverseerBase:increaseTurn(anchor)
    self.currentTurn = self.currentTurn + 1
    self:checkEvents(anchor)
end

function OverseerBase:checkEvents(anchor)
end

return OverseerBase

