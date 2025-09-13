local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local Common = require("common")
local TRIGGERS = require("actions.triggers")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Paladin's Amulet")
ITEM.className = "Paladin"
ITEM.classSprite = Vector:new(14, 2)
ITEM.icon = Vector:new(22, 2)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 11.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.35), [Tags.STAT_ABILITY_LIMIT] = 15, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
local FORMAT_1 = "The maximum damage you can take is the current {C:NUMBER}Floor plus %s."
local FORMAT_2 = "Whenever you restore health, deal %s damage to all adjacent enemies."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_LIMIT), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
local TRIGGER = class(TRIGGERS.WHEN_HEALED)
local EXPLOSION_DURATION = 0.5
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion.desaturate = 1
    self.explosion.excludeSelf = true
end

function TRIGGER:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.explosion:setArea(self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND))
    Common.playSFX("EXPLOSION_SMALL", 0.8)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, target)
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToPosition(anchor, target)
    end)
end

local PRE_MOVE = class(TRIGGERS.PRE_MOVE)
function PRE_MOVE:isEnabled()
    return self.entity.body:hasSteppableInstance(self.moveTo, "health_orb")
end

ITEM.decorateIncomingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositive() then
        local limit = abilityStats:get(Tags.STAT_ABILITY_LIMIT) + entity.hitter:getFloor()
        if hit.maxDamage > limit then
            hit:forceResolve()
            if hit.minDamage > limit then
                hit.minDamage = limit
                hit.maxDamage = limit
                hit:decreaseBonusState()
            end

        end

    end

end
ITEM.triggers:push(TRIGGER)
ITEM.triggers:push(PRE_MOVE)
local LEGENDARY = ITEM:createLegendary("Avatar of Justice")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_HOLY
return ITEM

