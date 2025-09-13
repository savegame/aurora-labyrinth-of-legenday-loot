local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local ACTION_CONSTANTS = require("actions.constants")
local GET_KNOCKED_BACK = require("actions.get_knocked_back")
local ActionUtils = require("actions.utils")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Monk's Amulet")
ITEM.className = "Monk"
ITEM.classSprite = Vector:new(10, 2)
ITEM.icon = Vector:new(16, 19)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 18.3, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.3), [Tags.STAT_PUSH_ATTACK] = 1, [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE, [Tags.STAT_ABILITY_POWER] = 2, [Tags.STAT_VIRTUAL_RATIO] = 1.2, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
local FORMAT_1 = "If you're not holding a weapon, you gain the {C:ABILITY_LABEL}Rapid {C:ABILITY_LABEL}Fist ability."
local FORMAT_2 = "Your unarmed {C:KEYWORD}Attacks deal %s damage and move you into your target's space, {C:KEYWORD}Pushing it back {C:NUMBER}1 space."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE))
end
ITEM.postCreate = function(item)
    item.conditionalNonAbilityStat = function(stat, entity, baseStats)
        if not entity.equipment:get(Tags.SLOT_WEAPON) then
                        if stat == Tags.STAT_ATTACK_DAMAGE_MIN then
                return baseStats:get(Tags.STAT_ABILITY_DAMAGE_MIN) - CONSTANTS.BAREHANDED_DAMAGE_MIN
            elseif stat == Tags.STAT_ATTACK_DAMAGE_MAX then
                return baseStats:get(Tags.STAT_ABILITY_DAMAGE_MAX) - CONSTANTS.BAREHANDED_DAMAGE_MAX
            end

        end

        return 0
    end
    item:multiplyStatAndGrowth(Tags.STAT_ABILITY_COOLDOWN, 0)
end
local ABILITY = require("structures.ability_def"):new("Rapid Fist")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
local ABILITY_FORMAT = "{C:KEYWORD}Attack an enemy. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return ABILITY_FORMAT
end
ABILITY.icon = Vector:new(4, 2)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemyAttack
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide)
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("charactertrail")
    self.charactertrail.silhouetteColor = COLORS.STANDARD_WIND
end

local SPEED_MULTIPLIER = 1.35
function ACTION:process(currentEvent)
    local entity = self.entity
    entity.sprite:turnToDirection(self.direction)
    self.charactertrail:start(currentEvent)
    entity.player:multiplyAttackSpeed(SPEED_MULTIPLIER)
    local attackAction = entity.melee:createAction(self.direction)
    attackAction:parallelResolve(currentEvent)
    entity.player:multiplyAttackSpeed(1 / SPEED_MULTIPLIER)
    return attackAction:chainEvent(currentEvent):chainEvent(function()
        self.charactertrail:stop()
    end)
end

local ATTACK = class("actions.base_attack")
ITEM.attackClass = ATTACK
local STEP_DURATION = ACTION_CONSTANTS.WALK_DURATION * 0.65
local BRACE_DISTANCE = ACTION_CONSTANTS.DEFAULT_BRACE_DISTANCE * 2
local BRACE_DURATION = ACTION_CONSTANTS.DEFAULT_BRACE_DURATION * 1.5
function ATTACK:initialize(entity, direction, abilityStats)
    ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self.attackTarget = false
    self:addComponent("tackle")
    self.tackle.forwardDistance = 0
    self.tackle.braceDistance = BRACE_DISTANCE
    self:addComponent("explosion")
    self.explosion.desaturate = 0.5
    self.explosion:setArea(Tags.ABILITY_AREA_SINGLE)
    self:addComponent("move")
    self.speedMultiplier = 1
    self.entityToPush = false
    self.knockbackAction = false
end

function ATTACK:speedMultiply(factor)
    self.speedMultiplier = self.speedMultiplier * factor
end

function ATTACK:createHit(hasKnockback)
    local hit = ATTACK:super(self, "createHit")
    if hasKnockback then
        local abilityStats = self.abilityStats
        hit:setKnockback(abilityStats:get(Tags.STAT_ABILITY_RANGE), self.direction, STEP_DURATION / self.speedMultiplier)
        hit:setKnockbackDamage(abilityStats)
    end

    return hit
end

function ATTACK:parallelResolve(currentEvent)
    local body = self.entity.body
    local entityAt = body:getEntityAt(self.attackTarget)
    if self.entity.buffable:canMove() then
                if body:isPassable(self.attackTarget + Vector[self.direction]) and entityAt and not entityAt.body.cantBeMoved then
            self.attackTarget = self.attackTarget + Vector[self.direction]
            self.entityToPush = entityAt
            self.knockbackAction = entityAt.actor:create(GET_KNOCKED_BACK, self.direction)
            self.knockbackAction.sourceEntity = self.entity
            self.knockbackAction.distance = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
            self.knockbackAction.stepDuration = STEP_DURATION / self.speedMultiplier
            self.knockbackAction:parallelResolve(currentEvent)
            self.entity.sprite:turnToDirection(self.direction)
            self.move:prepare(currentEvent)
        elseif body:isPassable(self.attackTarget) then
            self.entityToPush = true
            self.entity.sprite:turnToDirection(self.direction)
            self.move:prepare(currentEvent)
        end

    end

end

local EXPLOSION_DURATION = 0.5
function ATTACK:process(currentEvent)
    if self.entityToPush then
        self.tackle:createOffset()
        currentEvent = self.tackle:chainBraceEvent(currentEvent, BRACE_DURATION / self.speedMultiplier):chainEvent(function()
            Common.playSFX("DASH_SHORT")
        end)
        self.tackle:chainForwardEvent(currentEvent, STEP_DURATION / self.speedMultiplier)
        currentEvent:chainProgress(STEP_DURATION * 0.5 / self.speedMultiplier):chainEvent(function(_, anchor)
            if self.entityToPush ~= true then
                local hit = self:createHit(false)
                hit:applyToEntity(anchor, self.entityToPush, self.attackTarget)
                self.knockbackAction:chainEvent(anchor)
                self.explosion.source = self.attackTarget - Vector[self.direction] / 2
                self.explosion:chainFullEvent(anchor, EXPLOSION_DURATION)
            end

        end)
        return self.move:chainMoveEvent(currentEvent, STEP_DURATION / self.speedMultiplier)
    else
        local tackleAction = self.entity.actor:create(ATTACK_UNARMED.TACKLE, self.direction)
        tackleAction:speedMultiply(self.speedMultiplier)
        return tackleAction:parallelChainEvent(currentEvent):chainEvent(function(_, anchor)
            local hit = self:createHit(true)
            hit:applyToPosition(anchor, self.attackTarget)
            self.explosion.source = self.attackTarget
            self.explosion:chainFullEvent(anchor, EXPLOSION_DURATION)
        end)
    end

end

local LEGENDARY = ITEM:createLegendary("Transcendence")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_WIND
return ITEM

