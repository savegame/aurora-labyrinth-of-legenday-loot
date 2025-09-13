local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local BUFFS = require("definitions.buffs")
local Common = require("common")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.amulet_def"):new("Warden's Amulet")
ITEM.className = "Warden"
ITEM.classSprite = Vector:new(12, 3)
ITEM.icon = Vector:new(11, 18)
ITEM:setToStatsBase({ [Tags.STAT_LOCK] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 4.8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.5) })
local FORMAT_1 = "Adjacent enemies cannot move away from you."
local FORMAT_2 = "Whenever an adjacent enemy hits to you, deal %s damage back."
ITEM.getPassiveDescription = function(item)
    return Array:new(FORMAT_1, textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 2
end

function TRIGGER:isEnabled()
    return self.hit:getApplyDistance() <= 1
end

function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit.targetEntity = self.hit.sourceEntity
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:applyToEntity(anchor, self.hit.sourceEntity)
    end)
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Vanguard of the Beyond")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_STEEL
return ITEM

