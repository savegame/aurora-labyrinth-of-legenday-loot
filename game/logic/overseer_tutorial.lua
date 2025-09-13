local OverseerTutorial = class("logic.overseer_base")
local TUTORIAL_CONTROLLER = require("definitions.tutorial_controller")
function OverseerTutorial:initialize(...)
    OverseerTutorial:super(self, "initialize", ...)
end

function OverseerTutorial:checkEvents(anchor)
    if self.currentTurn == 1 then
        local player = self.services.player:get()
        player.buffable:apply(TUTORIAL_CONTROLLER:new(math.huge))
    end

end

return OverseerTutorial

