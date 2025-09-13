local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Drifter Greaves")
local ABILITY = require("structures.ability_def"):new("Transposition")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(3, 18)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 30, [Tags.STAT_MAX_MANA] = 10, [Tags.STAT_ABILITY_POWER] = 1.75, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Swap places with an enemy. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN)
end
ABILITY.icon = Vector:new(7, 10)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local targetEntity = ActionUtils.indicateEnemyWithinRange(entity, direction, abilityStats, castingGuide)
    if targetEntity then
        castingGuide:indicateMoveTo(targetEntity.body:getPosition())
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local SPEED_MULTIPLIER = 1
function ACTION:process(currentEvent)
    local targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    local moveTo = targetEntity.body:getPosition()
    local moveFrom = self.entity.body:getPosition()
    local playerTeleport = self.entity.actor:create(PLAYER_COMMON.TELEPORT, self.direction)
    playerTeleport.moveTo = moveTo
    playerTeleport:speedMultiply(SPEED_MULTIPLIER)
    targetEntity.tank.drawBar = false
    local enemyTeleport = targetEntity.actor:create(PLAYER_COMMON.TELEPORT, reverseDirection(self.direction))
    enemyTeleport.moveTo = moveFrom
    enemyTeleport:speedMultiply(SPEED_MULTIPLIER)
    enemyTeleport:parallelChainEvent(currentEvent):chainEvent(function()
        targetEntity.tank.drawBar = true
    end)
    return playerTeleport:parallelChainEvent(currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Wanderer of the Infinite")
LEGENDARY.statLine = "{C:KEYWORD}Chance before getting hit to swap places with " .. "on another enemy, making it take the hit."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_RANGE] = 1 })
local LEGENDARY_TRIGGER = class(TRIGGERS.PRE_HIT)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self:addComponent("move")
    self.move:setEasingToLinear()
    self.move.interimSkipTriggers = true
    self.move.interimSkipProjectiles = true
    self:addComponent("outline")
    self.outline:setIsFull()
    self.outline.color = COLORS.STANDARD_PSYCHIC
    self:addComponent("charactereffects")
    self.character = false
    self:addComponentAs("outline", "targetoutline")
    self.targetoutline.color = COLORS.STANDARD_PSYCHIC
end

function LEGENDARY_TRIGGER:isEnabled()
    if self.entity.buffable:isAffectedBy(PLAYER_COMMON.BUFF_TELEPORT_IMMUNE) then
        return false
    end

    if not self.entity.buffable:canMove() then
        return false
    end

    if not self.hit.sourceEntity:hasComponent("agent") then
        return false
    end

    if not self.hit:isDamageOrDebuff() then
        return false
    end

    for direction in DIRECTIONS_AA() do
        local enemy = ActionUtils.getEnemyWithinRange(self.entity, direction, self.abilityStats)
        if enemy and enemy ~= self.hit.sourceEntity then
            return true
        end

    end

    return false
end

local TELEPORT_DURATION = 0.45
function LEGENDARY_TRIGGER:parallelResolve(currentEvent)
    local directionWithDead = false
    local targetEnemy = false
    local deadEnemy = false
    self.direction = false
    for direction in (DIRECTIONS_AA:shuffle(self:getLogicRNG()))() do
        local enemy = ActionUtils.getEnemyWithinRange(self.entity, direction, self.abilityStats)
        if enemy and enemy ~= self.hit.sourceEntity then
            if ActionUtils.isAliveAgent(enemy) then
                self.direction = direction
                targetEnemy = enemy
                break
            else
                directionWithDead = direction
                deadEnemy = enemy
            end

        end

    end

    if not self.direction then
        self.direction = directionWithDead
        targetEnemy = deadEnemy
    end

    if targetEnemy then
        self.hit.targetEntity = targetEnemy
        self.hit.forceFlash = true
        local source = self.entity.body:getPosition()
        local target = targetEnemy.body:getPosition()
        self.move.moveTo = target
        self.move:prepare(currentEvent)
        targetEnemy.body:setPosition(source)
        self.character = self.entity.sprite:createCharacterCopy()
        self.character.sprite.opacity = 0
        self.outline:setEntity(self.character)
        self.outline:setToFilled()
        self.charactereffects.entity = self.character
        self.targetoutline:setEntity(targetEnemy)
        self.targetoutline:setToFilled()
        self.entity.sprite.opacity = 0
    end

end

function LEGENDARY_TRIGGER:process(currentEvent)
    if self.direction then
        Common.playSFX("TELEPORT")
        self.entity.buffable:forceApply(PLAYER_COMMON.BUFF_TELEPORT_IMMUNE:new())
        self.charactereffects:chainFadeInSprite(currentEvent, TELEPORT_DURATION)
        self.targetoutline:chainFadeOut(currentEvent, TELEPORT_DURATION)
        self.outline:chainFadeOut(currentEvent, TELEPORT_DURATION):chainEvent(function()
            self.character:delete()
            self.entity.sprite.opacity = 1
            self.entity.buffable:delete(anchor, PLAYER_COMMON.BUFF_TELEPORT_IMMUNE, true)
        end)
        return self.move:chainMoveEvent(currentEvent, TELEPORT_DURATION)
    else
        return currentEvent
    end

end

LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_RANGE, Tags.STAT_UPGRADED)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

