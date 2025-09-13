local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_WEAPON = require("actions.attack_weapon")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Dark Sword")
local ABILITY = require("structures.ability_def"):new("Shadow Hold")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_HALF_CONSIDERED)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(1, 10)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 19.8, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.35), [Tags.STAT_VIRTUAL_RATIO] = 0.63, [Tags.STAT_ABILITY_POWER] = 3.45, [Tags.STAT_ABILITY_DAMAGE_BASE] = 13.2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.6), [Tags.STAT_ABILITY_BUFF_DURATION] = 4, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_FULL })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "Target an adjacent enemy. {FORCE_NEWLINE} {C:KEYWORD}Sustain %s - Deal %s damage " .. "to the target. While {C:KEYWORD}Sustaining, the target can't take any actions."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(1, 10)
ABILITY.iconColor = COLORS.STANDARD_DEATH
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = entity.body:getPosition() + Vector[direction]
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    else
        castingGuide:indicate(target)
    end

end
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
local DEBUFF = BUFFS:define("SHADOW_HOLD_DISABLE")
function DEBUFF:initialize(duration)
    DEBUFF:super(self, "initialize", duration)
    self.disablesAction = true
    self.colorTint = Color:new(0, 0, 0, 0.3)
end

local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    self:super(self, "initialize", entity, direction, abilityStats)
    self.targetEntity = false
end

function TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:addBuff(DEBUFF:new(2))
    hit:applyToEntity(currentEvent, self.targetEntity)
    if self.targetEntity.tank.hasDiedOnce and self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local hit = self.entity.hitter:createHit()
        local manaCost = self.entity.equipment:getBaseSlotStat(self:getSlot(), Tags.STAT_ABILITY_MANA_COST)
        hit:setHealing(manaCost, manaCost, self.abilityStats)
        hit.affectsMana = true
        hit:applyToEntity(currentEvent, self.entity)
    end

    return currentEvent
end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.triggerClasses:push(TRIGGER)
    self.expiresImmediately = true
end

function BUFF:onTurnStart(anchor, entity)
    if self.action:shouldDeactivate() then
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.targetEntity = self.action.targetEntity
end

local ACTION = class(ATTACK_WEAPON.STAB)
ABILITY.actionClass = ACTION
local BRACE_MULTIPLIER = 2.4
local SPEED_MULTIPLIER = 0.4
local FORWARD_DISTANCE = 0.1
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("charactertrail")
    self.charactertrail.silhouetteColor = BLACK
    self.jump.height = 0
    self.tackle.braceDistance = self.tackle.braceDistance * BRACE_MULTIPLIER
    self.tackle.forwardDistance = FORWARD_DISTANCE
    self.braceDuration = self.braceDuration * BRACE_MULTIPLIER
    self.holdDuration = 0
    self:speedMultiply(SPEED_MULTIPLIER)
    self:addComponent("outline")
    self.outline.color = COLORS.STANDARD_DEATH_BRIGHTER
    self:addComponent("drain")
    self.drain.color = BLACK
    self.drain.startingRange = 1.5
    self.drain.targetRange = 0.2
    self.drain.speedMin = 0.8
    self.drain.speedMax = 1.4
    self.targetEntity = false
    self.sound = false
end

function ACTION:chainBraceEvent(currentEvent)
    Common.playSFX("WEAPON_CHARGE")
    self.outline:chainFadeIn(currentEvent, self.braceDuration)
    return ACTION:super(self, "chainBraceEvent", currentEvent)
end

function ACTION:chainMainSwingEvent(currentEvent)
    self.outline:chainFadeOut(currentEvent, self.swingDuration)
    return ACTION:super(self, "chainMainSwingEvent", currentEvent)
end

function ACTION:shouldDeactivate()
    if self.targetEntity.tank.hasDiedOnce then
        return true
    end

    return self.targetEntity.body:getPosition():distanceManhattan(self.entity.body:getPosition()) > 1
end

function ACTION:deactivate(anchor)
    anchor:chainEvent(function(_, anchor)
        self.drain:stop()
        self.sound:stop()
        self:chainBackEvent(self:chainHoldEvent(anchor))
        if self.targetEntity.tank:isAlive() then
            self.targetEntity.buffable:delete(anchor, DEBUFF)
        end

    end)
end

function ACTION:playDrain()
    self.sound = Common.playSFX("DRAIN", 0.3, 3)
end

function ACTION:setFromLoad()
    self.targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    self.drain:start(self.targetEntity, self.targetEntity)
    self:playDrain()
    self.weaponswing:createSwingItem()
    self.tackle:createOffset()
    self.tackle:setToForwardOffset()
end

function ACTION:process(currentEvent)
    self.targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    self:prepare()
    self.charactertrail:start(currentEvent)
    currentEvent = self:chainBraceEvent(currentEvent)
    currentEvent = self:chainMainSwingEvent(currentEvent):chainEvent(function(_, anchor)
        Common.playSFX("GENERIC_HIT")
        self.charactertrail:stop()
        self:playDrain()
        self.drain:start(self.targetEntity, self.targetEntity)
    end)
    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Sword of the Archdemon")
local LEGENDARY_EXTRA_LINE = "If this ability kills an enemy, restore %s mana."
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_ABILITY_MANA_COST)
end
return ITEM

