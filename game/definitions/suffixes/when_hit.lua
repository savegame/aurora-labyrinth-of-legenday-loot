local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local ModifierDef = require("structures.modifier_def")
local EASING = require("draw.easing")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local TRIGGERS = require("actions.triggers")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local textStatFormat = require("text.stat_format")
local EVASION = ModifierDef:new("Evasion")
EVASION.statLine = "{C:KEYWORD}Chance to avoid {C:KEYWORD}Melee {C:KEYWORD}Attacks."
EVASION.modifyItem = function(item)
    item.triggers:push(PLAYER_TRIGGERS.DODGE)
end
EVASION.canRoll = function(itemDef)
    if itemDef.slot == Tags.SLOT_WEAPON then
        return itemDef.statsBase:get(Tags.STAT_LUNGE, 0) > 0
    end

    return not itemDef:isSlotOffensive()
end
local MENDING = ModifierDef:new("Mending")
MENDING:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.52) })
local MENDING_FORMAT = "{C:KEYWORD}Chance when hit to restore %s health."
MENDING.statLine = function(item)
    return textStatFormat(MENDING_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
MENDING.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_WEAPON
end
local MENDING_TRIGGER = class(TRIGGERS.POST_HIT)
function MENDING_TRIGGER:initialize(entity, direction, abilityStats)
    MENDING_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function MENDING_TRIGGER:process(currentEvent)
    local entity = self.entity
    local hit = entity.hitter:createHit()
    hit:setHealing(self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX), self.abilityStats)
    hit:applyToEntity(currentEvent, entity)
    return currentEvent
end

MENDING.modifyItem = function(item)
    item.triggers:push(MENDING_TRIGGER)
end
local INSIGHT = ModifierDef:new("Insight")
local INSIGHT_FORMAT = "{C:KEYWORD}Chance when hit to reduce this ability's cooldown by %s turns."
INSIGHT:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 3 })
INSIGHT:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
INSIGHT:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
INSIGHT:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
INSIGHT.statLine = function(item)
    return textStatFormat(INSIGHT_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
INSIGHT.canRoll = function(itemDef)
    return true
end
INSIGHT.modifyItem = function(item)
    item.triggers:push(PLAYER_TRIGGERS.HIT_REDUCE_COOLDOWN)
end
local INSPIRATION = ModifierDef:new("Inspiration")
local INSPIRATION_FORMAT = "Picking up {C:KEYWORD}Health {C:KEYWORD}Orbs reduces this ability's cooldown by %s turns."
INSPIRATION:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 3 })
INSPIRATION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
INSPIRATION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
INSPIRATION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
INSPIRATION.statLine = function(item)
    return textStatFormat(INSPIRATION_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
INSPIRATION.canRoll = function(itemDef)
    return true
end
local INSPIRATION_TRIGGER = class(TRIGGERS.WHEN_HEALED)
function INSPIRATION_TRIGGER:isEnabled()
    return self.hit.damageType == Tags.DAMAGE_TYPE_HEALTH_ORB
end

function INSPIRATION_TRIGGER:process(currentEvent)
    local equipment = self.entity.equipment
    local value = self.abilityStats:get(Tags.STAT_MODIFIER_VALUE)
    equipment:reduceCooldown(self:getSlot(), value)
    return currentEvent
end

INSPIRATION.modifyItem = function(item)
    item.triggers:push(INSPIRATION_TRIGGER)
end
local SORCERY = ModifierDef:new("Sorcery")
local SORCERY_FORMAT = "{C:KEYWORD}Health {C:KEYWORD}Orbs also restore %s mana."
SORCERY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 8, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
SORCERY.statLine = function(item)
    return textStatFormat(SORCERY_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
SORCERY.canRoll = function(itemDef)
    if itemDef.slot == Tags.SLOT_WEAPON then
        return itemDef.statsBase:get(Tags.STAT_COOLDOWN_REDUCTION, 0) > 0
    end

    return true
end
local SORCERY_TRIGGER = class(PLAYER_TRIGGERS.MANA_ON_HEAL)
function SORCERY_TRIGGER:isEnabled()
    return self.hit.damageType == Tags.DAMAGE_TYPE_HEALTH_ORB and not self.hit.affectsMana
end

function SORCERY_TRIGGER:getHealValue()
    return self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
end

SORCERY.modifyItem = function(item)
    item.triggers:push(SORCERY_TRIGGER)
end
local VITALITY = ModifierDef:new("Vitality")
local VITALITY_FORMAT = "{C:KEYWORD}Health {C:KEYWORD}Orbs restore %s bonus health."
VITALITY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 4, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
VITALITY.statLine = function(item)
    return textStatFormat(VITALITY_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
VITALITY.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_WEAPON
end
local VITALITY_TRIGGER = class(TRIGGERS.WHEN_HEALED)
function VITALITY_TRIGGER:isEnabled()
    return self.hit.damageType == Tags.DAMAGE_TYPE_HEALTH_ORB
end

function VITALITY_TRIGGER:parallelResolve(currentEvent)
    local value = self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
    self.hit.minDamage = self.hit.minDamage - value
    self.hit.maxDamage = self.hit.maxDamage - value
end

function VITALITY_TRIGGER:process(currentEvent)
    return currentEvent
end

VITALITY.modifyItem = function(item)
    item.triggers:push(VITALITY_TRIGGER)
end
local DEFENSE = ModifierDef:new("Defense")
local DEFENSE_FORMAT = "{C:KEYWORD}Chance to reduce damage taken by %s."
DEFENSE:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 10, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
DEFENSE.statLine = function(item)
    return textStatFormat(DEFENSE_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
DEFENSE.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_WEAPON
end
DEFENSE.decorateIncomingHit = function(entity, hit, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    if entity.playertriggers.proccingSlot == slot and hit:isDamagePositiveDirect() then
        hit:reduceDamage(abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN))
        hit.sound = "HIT_BLOCKED"
        hit:decreaseBonusState()
    end

end
local DEFLECTION = ModifierDef:new("Deflection")
local DEFLECTION_FORMAT = "{C:KEYWORD}Resist %s against {C:KEYWORD}Projectiles."
DEFLECTION:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
DEFLECTION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
DEFLECTION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
DEFLECTION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
DEFLECTION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
DEFLECTION:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
DEFLECTION.statLine = function(item)
    return textStatFormat(DEFLECTION_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
DEFLECTION.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_GLOVES
end
DEFLECTION.decorateIncomingHit = function(entity, hit, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_RANGED then
        hit:reduceDamage(abilityStats:get(Tags.STAT_MODIFIER_VALUE))
        hit:decreaseBonusState()
    end

end
local VENDETTA = ModifierDef:new("Vengeance")
VENDETTA.statLine = "{B:STAT_LINE}{C:KEYWORD}Chance when hit by a {C:KEYWORD}Melee " .. "{C:KEYWORD}Attack to counter {C:KEYWORD}Attack."
VENDETTA.canRoll = function(itemDef)
    return itemDef.slot == Tags.SLOT_ARMOR or itemDef.slot == Tags.SLOT_WEAPON or itemDef.slot == Tags.SLOT_GLOVES
end
local VENDETTA_TRIGGER = class(PLAYER_TRIGGERS.COUNTER_ATTACK)
function VENDETTA_TRIGGER:initialize(entity, direction, abilityStats)
    VENDETTA_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function VENDETTA_TRIGGER:isEnabled()
    if not self.hit:isDamageAnyMelee() then
        return false
    end

    return VENDETTA_TRIGGER:super(self, "isEnabled")
end

VENDETTA.modifyItem = function(item)
    item.triggers:push(VENDETTA_TRIGGER)
end
local FAITH = ModifierDef:new("Faith")
FAITH.abilityExtraLine = "Restore mana equal to half of the health restored."
FAITH.canRoll = function(itemDef)
    return itemDef.ability:hasTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
end
FAITH.modifyItem = function(item)
    item.triggers:push(PLAYER_TRIGGERS.MANA_ON_HEAL)
end
local RETRIBUTION = ModifierDef:new("Retribution")
RETRIBUTION.statLine = "{C:KEYWORD}Chance when damaged to deal back the same amount of damage."
RETRIBUTION.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_HELM
end
local RETRIBUTION_TRIGGER = class(TRIGGERS.POST_HIT)
function RETRIBUTION_TRIGGER:initialize(entity, direction, abilityStats)
    RETRIBUTION_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self.sortOrder = 1
end

function RETRIBUTION_TRIGGER:isEnabled()
    return self.hit:isDamagePositiveDirect()
end

function RETRIBUTION_TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.hit.minDamage, self.hit.maxDamage)
    hit.slotSource = self:getSlot()
    hit:applyToEntity(currentEvent, self.hit.sourceEntity)
    return currentEvent
end

RETRIBUTION.modifyItem = function(item)
    item.triggers:push(RETRIBUTION_TRIGGER)
end
local BACKFIRE = ModifierDef:new("Backfire")
local BACKFIRE_FORMAT = "{C:KEYWORD}Chance when hit to {C:KEYWORD}Burn the attacker. " .. " {FORCE_NEWLINE} {C:KEYWORD}Burn - {C:NUMBER}%s turns, %s health lost per turn."
BACKFIRE:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 8.2, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.71), [Tags.STAT_MODIFIER_VALUE] = 3 })
BACKFIRE:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
BACKFIRE.statLine = function(item)
    return textStatFormat(BACKFIRE_FORMAT, item, Tags.STAT_MODIFIER_VALUE, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
BACKFIRE.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_WEAPON
end
local BACKFIRE_TRIGGER = class(TRIGGERS.POST_HIT)
function BACKFIRE_TRIGGER:initialize(entity, direction, abilityStats)
    BACKFIRE_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function BACKFIRE_TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    local abilityStats = self.abilityStats
    hit.sound = "BURN_DAMAGE"
    hit:setSpawnFire(abilityStats:get(Tags.STAT_MODIFIER_VALUE), abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN), abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX))
    hit.slotSource = self:getSlot()
    hit:applyToEntity(currentEvent, self.hit.sourceEntity)
    return currentEvent
end

function BACKFIRE_TRIGGER:isEnabled()
    if not self.hit.sourceEntity:hasComponent("agent") then
        return false
    end

    return BACKFIRE_TRIGGER:super(self, "isEnabled")
end

BACKFIRE.modifyItem = function(item)
    item.triggers:push(BACKFIRE_TRIGGER)
end
return { EVASION = EVASION, MENDING = MENDING, INSIGHT = INSIGHT, INSPIRATION = INSPIRATION, SORCERY = SORCERY, VITALITY = VITALITY, DEFENSE = DEFENSE, VENDETTA = VENDETTA, DEFLECTION = DEFLECTION, FAITH = FAITH, RETRIBUTION = RETRIBUTION, BACKFIRE = BACKFIRE }

