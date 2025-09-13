local Vector = require("utils.classes.vector")
local Hash = require("utils.classes.hash")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Eldritch Crown")
local ABILITY = require("structures.ability_def"):new("Pulsar")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM:setToMediumComplexity()
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NOT_CONSIDERED)
ABILITY:addTag(Tags.ABILITY_TAG_SUSTAIN_CAN_KILL)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(7, 18)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 40, [Tags.STAT_ABILITY_POWER] = 6.7, [Tags.STAT_ABILITY_BUFF_DURATION] = 4, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_MOBILE, [Tags.STAT_ABILITY_DAMAGE_BASE] = 17, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.15), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Sustain %s - Fire {C:NUMBER}4 projectiles that each deal %s damage. " .. "Alternates between straight and diagonal directions. Can move while " .. "{C:KEYWORD}Sustaining."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(3, 10)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    for direction in DIRECTIONS_AA() do
        ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, source)
    end

    for direction in DIRECTIONS_DIAGONAL() do
        ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, source, 0)
    end

end
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.isOrthogonal = true
end

function TRIGGER:process(currentEvent)
    local directions = DIRECTIONS_AA
    if not self.isOrthogonal then
        directions = DIRECTIONS_DIAGONAL
    end

    Common.playSFX("CAST_CHARGE", 1, 0.8)
    local lastEvent = currentEvent
    for direction in directions() do
        lastEvent = self.entity.projectilespawner:spawn(currentEvent, direction, self.abilityStats, Vector:new(1, 2), true)
    end

    return lastEvent
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
    self.expiresImmediately = true
    self.isOrthogonal = true
    self.firstTurn = true
    self.outlinePulseColor = ABILITY.iconColor
end

function BUFF:toData()
    return { isOrthogonal = self.isOrthogonal, firstTurn = self.firstTurn }
end

function BUFF:fromData(data)
    self.isOrthogonal = data.isOrthogonal
    self.firstTurn = data.firstTurn
end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.isOrthogonal = self.isOrthogonal
end

function BUFF:onTurnStart(anchor, entity)
    self.isOrthogonal = not self.isOrthogonal
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        if entity.mana:getCurrent() < self.abilityStats:get(Tags.STAT_MODIFIER_VALUE) then
            self.duration = 0
        end

    end

end

function BUFF:onTurnEnd(anchor, entity)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        if self.firstTurn then
            self.firstTurn = false
        else
            entity.mana:consume(self.abilityStats:get(Tags.STAT_MODIFIER_VALUE))
        end

    end

end

local ACTION = class(ACTIONS_FRAGMENT.GLOW_MODAL)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.sound = "ENCHANT"
end

local LEGENDARY = ITEM:createLegendary("Celestial Majesty")
local LEGENDARY_EXTRA_LINE = "Costs %s mana every turn. If you don't have enough, " .. "cancel this ability."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = CONSTANTS.PRESUMED_INFINITE })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.modifyItem = function(item)
    local originalCost = item.stats:get(Tags.STAT_ABILITY_MANA_COST)
    local buffDuration = item.stats:get(Tags.STAT_ABILITY_BUFF_DURATION) - CONSTANTS.PRESUMED_INFINITE + 2
    local currentCost = floor(originalCost / buffDuration)
    item.stats:set(Tags.STAT_ABILITY_MANA_COST, currentCost)
    item.stats:set(Tags.STAT_MODIFIER_VALUE, currentCost)
    for i = 1, CONSTANTS.ITEM_UPGRADE_LEVELS do
        local growthForLevel = item:getGrowthForLevel(i)
        if growthForLevel:hasKey(Tags.STAT_ABILITY_BUFF_DURATION) then
            buffDuration = buffDuration + growthForLevel:get(Tags.STAT_ABILITY_BUFF_DURATION)
            local newCost = floor(originalCost / buffDuration)
            if not item.extraGrowth:hasKey(i) then
                item.extraGrowth:set(i, Hash:new())
            end

            local extraGrowth = item.extraGrowth:get(i)
            extraGrowth:set(Tags.STAT_ABILITY_MANA_COST, newCost - currentCost)
            extraGrowth:set(Tags.STAT_MODIFIER_VALUE, newCost - currentCost)
            currentCost = newCost
        end

    end

    item:markAltered(Tags.STAT_ABILITY_MANA_COST, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
end
return ITEM

