local OverseerFinalFloor = class("logic.overseer_base")
local Vector = require("utils.classes.vector")
local ARRIVAL_ACTION = require("actions.final_boss").ARRIVAL
local COLORS = require("draw.colors")
local Global = require("global")
local BOSS_POSITION = Vector:new(14, 7)
function OverseerFinalFloor:initialize(...)
    OverseerFinalFloor:super(self, "initialize", ...)
    self.finalBoss = false
end

function OverseerFinalFloor:toData(convertToData)
    local result = OverseerFinalFloor:super(self, "toData", convertToData)
    result.finalBoss = convertToData(self.finalBoss)
    return result
end

function OverseerFinalFloor:fromData(data, convertFromData)
    OverseerFinalFloor:super(self, "fromData", data)
    self.finalBoss = convertFromData(data.finalBoss)
    if self.finalBoss then
        if not self.finalBoss.tank.hasDiedOnce then
            Global:get(Tags.GLOBAL_AUDIO):playBGM("LAST_BOSS")
        end

        self.services.director:createWidget("boss_health", self.finalBoss)
    end

end

function OverseerFinalFloor:checkEvents(anchor)
    local player = self.services.player:get()
    if self.currentTurn > 1 and not self.finalBoss and player.vision:isVisible(BOSS_POSITION) then
        self.finalBoss = self.services.createEntity("enemies.final_boss", BOSS_POSITION, DOWN, "final_boss", self.services.run.difficulty, anchor)
        local arrivalAction = self.finalBoss.actor:create(ARRIVAL_ACTION, self.finalBoss, DOWN)
        arrivalAction.color = COLORS.ELITE_BOSS_RANGED
        arrivalAction:parallelChainEvent(anchor)
        self.services.director:createWidget("boss_health", self.finalBoss)
    end

end

return OverseerFinalFloor

