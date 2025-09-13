local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Sanguine Cloak")
local ABILITY = require("structures.ability_def"):new("Blood Price")
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(11, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 12, [Tags.STAT_MAX_MANA] = 48, [Tags.STAT_ABILITY_HEALTH_COST] = 70, [Tags.STAT_ABILITY_COOLDOWN] = 22, [Tags.STAT_ABILITY_DENOMINATOR] = 4, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_HEALTH_COST] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_HEALTH_COST] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DENOMINATOR] = -1, [Tags.STAT_ABILITY_HEALTH_COST] = 5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_HEALTH_COST] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_HEALTH_COST] = -3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_HEALTH_COST] = -3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_HEALTH_COST] = -3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DENOMINATOR] = -1, [Tags.STAT_ABILITY_HEALTH_COST] = 5 })
local FORMAT = "Restore %s of your max mana. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DENOMINATOR)
end
ABILITY.icon = Vector:new(5, 8)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
end

local FLASH_OPACITY = 1
local GLOW_DURATION = ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION
function ACTION:process(currentEvent)
    Common.playSFX("CAST_CHARGE")
    currentEvent = self.outline:chainFadeIn(currentEvent, GLOW_DURATION):chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        local denominator = self.abilityStats:get(Tags.STAT_ABILITY_DENOMINATOR)
        hit:setHealing(self.entity.mana:getMax() / denominator, self.abilityStats)
        hit.affectsMana = true
        hit:applyToEntity(anchor, self.entity)
        if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            local equipment = self.entity.equipment
            for slot in (equipment:getSlotsWithAbilities())() do
                equipment:resetCooldown(slot)
            end

        end

    end)
    currentEvent = currentEvent:chainProgress(ACTION_CONSTANTS.STANDARD_FLASH_DURATION)
    self.outline:chainFadeOut(currentEvent, GLOW_DURATION)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Red Devotion")
LEGENDARY.abilityExtraLine = "Reset all ability cooldowns."
return ITEM

