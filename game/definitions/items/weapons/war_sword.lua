local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ABILITY = require("structures.ability_def"):new("Into the Fray")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
local ITEM = require("structures.item_def"):new("War Sword")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(10, 10)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 20.2, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.6), [Tags.STAT_VIRTUAL_RATIO] = 0.05, [Tags.STAT_ABILITY_POWER] = 3.6, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_AREA_CLEAVE] = 5, [Tags.STAT_ABILITY_DAMAGE_BASE] = 20.2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.6), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 7, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = 0 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_CLEAVE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Move up to %s forward and deal %s damage to %s, " .. "plus %s damage for every space you moved."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_CLEAVE, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(5, 6)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = entity.body:getPosition()
    if entity.buffable:canMove() then
        moveTo = ActionUtils.getDashMoveTo(entity, direction, abilityStats)
        if moveTo ~= entity.body:getPosition() then
            castingGuide:indicateMoveTo(moveTo)
        end

    end

    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    for position in (ActionUtils.getCleavePositions(moveTo, area, direction))() do
        castingGuide:indicate(position)
    end

end
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.expiresAtStart = true
end

function BUFF:decorateIncomingHit(hit)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and self.duration > 0 then
        if hit:isDamagePositiveDirect() then
            hit:multiplyDamage(0.5)
            hit:decreaseBonusState()
        end

    end

end

local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.7
local SWING_DURATION_3 = 0.2
local SWING_DURATION_5 = 0.3
local SWING_DURATION_7 = 0.4
local BACK_DURATION = 0.14
local FORWARD_DISTANCE = 0.3
local ORIGIN_OFFSET = 0.45
local SWING_WAIT = 0.1
local NO_DASH_DURATION = 0.14
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self.weaponswing:setTrailToLingering()
    self.weaponswing.itemOffset = Vector.ORIGIN
    self:addComponent("cleaveorder")
    self:addComponent("tackle")
    self.tackle.forwardDistance = FORWARD_DISTANCE
    self:addComponent("move")
    self:addComponent("charactertrail")
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    local swingDuration = SWING_DURATION_3
    self.cleaveorder.area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
        if self.cleaveorder.area == 5 then
        swingDuration = SWING_DURATION_5
    elseif self.cleaveorder.area == 7 then
        swingDuration = SWING_DURATION_7
    end

    self.weaponswing:setAngles(self.cleaveorder:getAngles())
    self.weaponswing:createSwingItem()
    self.weaponswing.swingItem.originOffset = ORIGIN_OFFSET
    local moveTo = self.entity.body:getPosition()
    if self.entity.buffable:canMove() then
        moveTo = ActionUtils.getDashMoveTo(self.entity, self.direction, self.abilityStats)
    end

    self.move.distance = self.entity.body:getPosition():distanceManhattan(moveTo)
    self.tackle:createOffset()
    local moveDuration = self.move.distance * STEP_DURATION
    if self.move.distance > 0 then
        self.charactertrail:start(currentEvent)
        self.move:prepare(currentEvent)
        Common.playSFX(self.move:getDashSound())
        self.move:chainMoveEvent(currentEvent, moveDuration):chainEvent(function()
            self.charactertrail:stop()
        end)
        self.tackle:chainForwardEvent(currentEvent, moveDuration)
        currentEvent = currentEvent:chainProgress(moveDuration - STEP_DURATION * 0.25)
    else
        currentEvent = self.tackle:chainForwardEvent(currentEvent, NO_DASH_DURATION)
    end

    local bonusDamage = self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX) * self.move.distance
    currentEvent:chainEvent(function()
        Common.playSFX("CLEAVE", SWING_DURATION_7 / swingDuration)
    end)
    self.cleaveorder:chainHitEvent(currentEvent, swingDuration, function(anchor, position)
        local hit = self.entity.hitter:createHit(moveTo)
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit.minDamage = hit.minDamage + bonusDamage
        hit.maxDamage = hit.maxDamage + bonusDamage
        if bonusDamage > 0 then
            hit:increaseBonusState()
        end

        hit:applyToPosition(anchor, position)
        if hit.targetEntity and self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            if hit.targetEntity:hasComponent("agent") then
                self.entity.equipment:extendSlotBuff(self.abilityStats:get(Tags.STAT_SLOT), 1)
            end

        end

    end)
    currentEvent = self.weaponswing:chainSwingEvent(currentEvent, swingDuration)
    currentEvent = currentEvent:chainProgress(SWING_WAIT)
    return self.tackle:chainBackEvent(currentEvent, BACK_DURATION):chainEvent(function()
        self.weaponswing:deleteSwingItem()
        self.tackle:deleteOffset()
    end)
end

local LEGENDARY = ITEM:createLegendary("Blademaster's Fortress")
LEGENDARY.abilityExtraLine = "Reduce all damage taken by half. Lasts for {C:NUMBER}1 turn times the number of enemies hit."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = -4, [Tags.STAT_ABILITY_BUFF_DURATION] = 0 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_COOLDOWN, Tags.STAT_UPGRADED)
end
return ITEM

