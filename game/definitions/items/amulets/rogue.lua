local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.amulet_def"):new("Rogue's Amulet")
ITEM.className = "Rogue"
ITEM.classSprite = Vector:new(10, 1)
ITEM.icon = Vector:new(14, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 6.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:setGrowthMultiplier({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 2.4 })
local FORMAT_1 = "Whenever you kill an enemy with an {C:KEYWORD}Attack, reduce all ability " .. "cooldowns by %s."
local FORMAT_2 = "If the target of your {C:KEYWORD}Attack has less than %s " .. "health after taking damage, kill it."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_VALUE), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
local TRIGGER = class(PLAYER_TRIGGERS.ATTACK_KILL)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.targetEntity = false
end

function TRIGGER:shouldKill(entityAt)
    return entityAt.tank:getCurrent() < self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
end

function TRIGGER:parallelResolve(currentEvent)
    local entityAt = self.entity.body:getEntityAt(self.attackTarget)
    if ActionUtils.isAliveAgent(entityAt) then
        self.targetEntity = entityAt
    end

end

function TRIGGER:process(currentEvent)
    return TRIGGER:super(self, "process", currentEvent):chainEvent(function()
        if self.targetEntity and self.targetEntity.tank.hasDiedOnce then
            local value = self.abilityStats:get(Tags.STAT_ABILITY_VALUE)
            for slot in (self.entity.equipment:getSlotsWithAbilities())() do
                self.entity.equipment:reduceCooldown(slot, value)
            end

        end

    end)
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Requiem of Annihilation")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_DEATH
return ITEM

