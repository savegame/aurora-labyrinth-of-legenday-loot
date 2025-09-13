local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Impulse Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(17, 16)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_ABILITY_COOLDOWN] = 43, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -2 })
local FORMAT = "When you get hit by a {C:KEYWORD}Melee {C:KEYWORD}Attack, prevent " .. "the damage and push the attacker %s."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE)
end
local TRIGGER = class(TRIGGERS.PRE_HIT)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 13
    self:addComponent("explosion")
    self.explosion:setArea(Tags.ABILITY_AREA_SINGLE)
    self.explosion:setHueToArcane()
end

local KNOCKBACK_STEP_DURATION = 0.12
local EXPLODE_DURATION = 0.35
function TRIGGER:isEnabled()
    local entity = self.entity
    if entity.equipment:isReady(self:getSlot()) then
        local hit = self.hit
        if hit.damageType == Tags.DAMAGE_TYPE_MELEE and hit:isDamagePositive() then
            local sourceEntity = self.hit.sourceEntity
            if sourceEntity then
                return sourceEntity:hasComponent("agent")
            end

        end

    end

    return false
end

function TRIGGER:parallelResolve(currentEvent)
    self.hit:clear()
    self.hit.sound = "HIT_BLOCKED"
end

function TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local direction = Common.getDirectionTowardsEntity(self.entity, self.hit.sourceEntity)
    hit:setKnockback(range, direction, KNOCKBACK_STEP_DURATION)
    hit:setKnockbackDamage(self.abilityStats)
    hit:applyToEntity(currentEvent, self.hit.sourceEntity)
    self.entity.equipment:setOnCooldown(self:getSlot())
    self.entity.equipment:recordCast(self:getSlot())
    self.explosion.source = self.entity.body:getPosition() + Vector[direction] / 2
    Common.playSFX("EXPLOSION_SMALL", 2.4, 0.8)
    return self.explosion:chainFullEvent(currentEvent, EXPLODE_DURATION)
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Untouchable")
LEGENDARY.strokeColor = COLORS.STANDARD_PSYCHIC
LEGENDARY.passiveExtraLine = "While this ring is not on cooldown, your base mana regeneration is doubled."
LEGENDARY:setToStatsBase({  })
LEGENDARY.modifyItem = function(item)
    item.conditionalNonAbilityStat = function(stat, entity, baseStats)
        if stat == Tags.STAT_MANA_REGEN and entity.equipment:isReady(ITEM.slot) then
            return CONSTANTS.MANA_PER_TURN
        else
            return 0
        end

    end
end
return ITEM

