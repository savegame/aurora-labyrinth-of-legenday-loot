local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Cryomancer's Amulet")
ITEM.className = "Cryomancer"
ITEM.classSprite = Vector:new(14, 1)
ITEM.icon = Vector:new(15, 19)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.07) })
local FORMAT_1 = "Reduce damage taken from {C:KEYWORD}Cold enemies by half."
local FORMAT_2 = "Enemies affected by your {C:KEYWORD}Cold lose %s health every turn."
ITEM.getPassiveDescription = function(item)
    return Array:new(FORMAT_1, textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
local FROSTBITE = BUFFS:define("FROSTBITE", "COLD")
function FROSTBITE:initialize(duration, sourceEntity, abilityStats)
    FROSTBITE:super(self, "initialize", duration)
    self.sourceEntity = sourceEntity
    self.abilityStats = abilityStats
end

function FROSTBITE:getDataArgs()
    return self.duration, self.sourceEntity, self.abilityStats
end

function FROSTBITE:onTurnEnd(anchor, entity)
    local hit = self.sourceEntity.hitter:createHit(entity.body:getPosition())
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_FROSTBITE, self.abilityStats)
    hit:applyToEntity(anchor, entity, entity.body:getPosition())
end

function FROSTBITE:decorateOutgoingHit(hit)
    if hit:isDamagePositiveDirect() then
        hit:multiplyDamage(0.5)
        hit:decreaseBonusState()
    end

end

ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    hit.buffs:mapSelf(function(buff)
        if BUFFS:get("COLD"):isInstance(buff) then
            return FROSTBITE:new(buff.duration, entity, abilityStats)
        else
            return buff
        end

    end)
end
local LEGENDARY = ITEM:createLegendary("Star Eater")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_ICE
return ITEM

