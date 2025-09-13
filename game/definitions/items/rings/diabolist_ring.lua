local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.item_def"):new("Diabolist Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(18, 16)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 20, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_RANGE] = 2 })
local FORMAT = "Whenever you kill a non-adjacent enemy, restore %s mana"
local FORMAT_LEGENDARY = " {B:STAT_LINE}and reduce the current highest ability cooldown by %s."
ITEM.getPassiveDescription = function(item)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return textStatFormat(FORMAT .. FORMAT_LEGENDARY, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_MODIFIER_VALUE)
    else
        return textStatFormat(FORMAT .. ".", item, Tags.STAT_ABILITY_DAMAGE_MIN)
    end

end
local TRIGGER = class(TRIGGERS.ON_KILL)
function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit:setHealing(self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN), self.abilityStats)
        hit.affectsMana = true
        hit:applyToEntity(anchor, self.entity)
        if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            local highestCooldown = 0
            local highestSlot = false
            local equipment = self.entity.equipment
            for slot in (equipment:getSlotsWithAbilities())() do
                local cooldown = equipment:getCooldownFor(slot)
                if cooldown > highestCooldown then
                    highestCooldown = cooldown
                    highestSlot = slot
                end

            end

            if highestSlot then
                equipment:reduceCooldown(highestSlot, self.abilityStats:get(Tags.STAT_MODIFIER_VALUE))
            end

        end

    end)
end

function TRIGGER:isEnabled()
    if not self.killed:hasComponent("agent") then
        return false
    end

    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    return self.killingHit and self.killingHit:getApplyDistance() >= range
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("The Beholder")
LEGENDARY.strokeColor = COLORS.STANDARD_RAGE
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
return ITEM

