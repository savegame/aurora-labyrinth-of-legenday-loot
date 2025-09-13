local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local PLAYER_COMMON = require("actions.player_common")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Mind Cloak")
local ABILITY = require("structures.ability_def"):new("Force Field")
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(15, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 60, [Tags.STAT_ABILITY_POWER] = 4, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - At the start and end of your turn, {C:KEYWORD}Push all " .. "adjacent targets %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(11, 7)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    castingGuide:indicate(entity.body:getPosition())
    for direction in DIRECTIONS_AA() do
        castingGuide:indicate(entity.body:getPosition() + Vector[direction])
    end

end
local END_OF_TURN = class(TRIGGERS.END_OF_TURN)
local START_OF_TURN = class(TRIGGERS.START_OF_TURN)
local EXPLOSION_DURATION = 0.45
local STEP_DURATION = 0.15
function END_OF_TURN:initialize(entity, direction, abilityStats)
    END_OF_TURN:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setHueToArcane()
    self.explosion.excludeSelf = true
end

function END_OF_TURN:isEnabled()
    for direction in DIRECTIONS_AA() do
        local source = self.entity.body:getPosition()
        local entityAt = self.entity.body:getEntityAt(source + Vector[direction])
        if entityAt and not entityAt.body.cantBeMoved then
            return true
        end

    end

    return false
end

function END_OF_TURN:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.explosion:setArea(self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND))
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    Common.playSFX("CAST_CHARGE", 1, 0.6)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, target)
        local hit = self.entity.hitter:createHit()
        local direction = Common.getDirectionTowards(self.explosion.source, target)
        hit:setKnockback(range, direction, STEP_DURATION)
        hit:setKnockbackDamage(self.abilityStats)
        hit:applyToPosition(anchor, target)
    end)
end

function START_OF_TURN:initialize(entity, direction, abilityStats)
    START_OF_TURN:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion:setHueToArcane()
    self.explosion.excludeSelf = true
end

START_OF_TURN.isEnabled = END_OF_TURN.isEnabled
START_OF_TURN.process = END_OF_TURN.process
local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.triggerClasses:push(START_OF_TURN)
    self.triggerClasses:push(END_OF_TURN)
    self.expiresAtStart = true
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    Common.playSFX("GLOW_MODAL")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function()
        self.entity.sprite.strokeColor:push(COLORS.STANDARD_PSYCHIC)
    end)
end

function ACTION:setFromLoad()
    self.entity.sprite.strokeColor:push(COLORS.STANDARD_PSYCHIC)
end

function ACTION:deactivate()
    self.entity.sprite.strokeColor:delete(COLORS.STANDARD_PSYCHIC)
end

local LEGENDARY = ITEM:createLegendary("The Indomitable")
LEGENDARY:setToStatsBase({ [Tags.STAT_MAX_MANA] = 60 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_MAX_MANA, Tags.STAT_UPGRADED)
end
return ITEM

