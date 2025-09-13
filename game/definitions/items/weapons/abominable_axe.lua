local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local TRIGGERS = require("actions.triggers")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ActionUtils = require("actions.utils")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Abominable Axe")
local ABILITY = require("structures.ability_def"):new("Toxic Cleave")
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NO_EXTEND)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(4, 8)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 21, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1), [Tags.STAT_VIRTUAL_RATIO] = 0.37, [Tags.STAT_ABILITY_POWER] = 3.372, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 4, [Tags.STAT_ABILITY_BUFF_DURATION] = 4, [Tags.STAT_POISON_DAMAGE_BASE] = 8.0 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1, [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1, [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Poison all adjacent enemies, making them lose %s health over %s."
local FORMAT_NORMAL = " {FORCE_NEWLINE} {C:KEYWORD}Buff %s - Whenever a {C:KEYWORD}Poisoned enemy hits you, " .. "it loses twice as much health from {C:KEYWORD}Poison this turn."
ABILITY.getDescription = function(item)
    local description = textStatFormat(FORMAT, item, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) == 0 then
        description = description .. textStatFormat(FORMAT_NORMAL, item, Tags.STAT_ABILITY_BUFF_DURATION)
    end

    return description
end
ABILITY.icon = Vector:new(6, 11)
ABILITY.iconColor = COLORS.STANDARD_POISON
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    for direction in DIRECTIONS_AA() do
        castingGuide:indicate(source + Vector[direction])
    end

end
local DEBUFF = BUFFS:define("POISON_AMPLIFY")
function DEBUFF:initialize(duration)
    DEBUFF:super(self, "initialize", duration)
    self.expiresAtStart = true
end

function DEBUFF:decorateIncomingHit(hit)
    if hit.damageType == Tags.DAMAGE_TYPE_POISON then
        hit:multiplyDamage(2)
        hit:increaseBonusState()
    end

end

local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:isEnabled()
    return ActionUtils.isAliveAgent(self.hit.sourceEntity)
end

function TRIGGER:process(currentEvent)
    local debuff = DEBUFF:new(1)
    self.hit.sourceEntity.buffable:forceApply(debuff)
    return currentEvent
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.expiresAtStart = true
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) == 0 then
        self.triggerClasses:push(TRIGGER)
    end

end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local SWING_DURATION = 0.5
local BRACE_DISTANCE = 0.15
local BRACE_DURATION = 0.2
local BRACE_HOLD = 0.2
local ORIGIN_OFFSET = 0.375
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self.weaponswing:setTrailToLingering()
    self.weaponswing.isOriginPosition = true
    self.weaponswing.itemOffset = Vector.ORIGIN
    self.weaponswing.isDirectionHorizontal = true
    self.weaponswing.trailSilhouette = ABILITY.iconColor
    self:addComponent("cleaveorder")
    self.cleaveorder.area = 4
    self:addComponent("tackle")
    self.tackle.isDirectionHorizontal = true
    self.tackle.braceDistance = BRACE_DISTANCE
    self.tackle.forwardDistance = BRACE_DISTANCE
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self.attackers = false
end

function ACTION:process(currentEvent)
    local direction = MEASURES.toHorizontalDirection(self.direction)
    self.entity.sprite:turnToDirection(direction)
    self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    self.cleaveorder.direction = direction
    self.tackle:createOffset()
    self.weaponswing:setAngles(self.cleaveorder:getAngles())
    self.weaponswing:createSwingItem()
    self.weaponswing.swingItem.originOffset = ORIGIN_OFFSET
    Common.playSFX("WEAPON_CHARGE")
    self.outline:chainFadeIn(currentEvent, BRACE_DURATION + BRACE_HOLD)
    currentEvent = self.tackle:chainBraceEvent(currentEvent, BRACE_DURATION)
    currentEvent = currentEvent:chainProgress(BRACE_HOLD):chainEvent(function()
        Common.playSFX("SPIN")
    end)
    self.weaponswing:chainSwingEvent(currentEvent, SWING_DURATION)
    self.cleaveorder:chainHitEvent(currentEvent, SWING_DURATION, function(anchor, position)
        local hit = self.entity.hitter:createHit()
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
        local poisonDebuff = BUFFS:get("POISON"):new(duration, self.entity, poisonDamage)
        hit:addBuff(poisonDebuff)
        hit.forceFlash = true
        hit:applyToPosition(anchor, position)
    end)
    currentEvent = self.tackle:chainForwardEvent(currentEvent, SWING_DURATION / 2)
    self.outline:chainFadeOut(currentEvent, SWING_DURATION / 2)
    currentEvent = self.tackle:chainBackEvent(currentEvent, SWING_DURATION / 2):chainEvent(function()
        self.tackle:deleteOffset()
        self.weaponswing:deleteSwingItem()
        self.entity.sprite:resetLayer()
    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Anathema")
LEGENDARY.statLine = "Whenever a {C:KEYWORD}Poisoned enemy hits you, it loses twice as " .. "much health from {C:KEYWORD}Poison this turn."
LEGENDARY.modifyItem = function(item)
    item:multiplyStatAndGrowth(Tags.STAT_ABILITY_BUFF_DURATION, 0)
    item.stats:deleteKey(Tags.STAT_ABILITY_BUFF_DURATION)
    item.triggers:push(TRIGGER)
end
return ITEM

