local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Scoundrel Gloves")
local ABILITY = require("structures.ability_def"):new("Elusive Throw")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_DISENGAGE_MELEE)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(7, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 12, [Tags.STAT_MAX_MANA] = 28, [Tags.STAT_ABILITY_POWER] = 2.13, [Tags.STAT_ABILITY_RANGE] = 1, [Tags.STAT_ABILITY_DAMAGE_BASE] = 18, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.19), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Throw a {C:KEYWORD}Projectile that deals %s damage. Move %s away."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(7, 5)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide)
    if entity.buffable:canMove() then
        local moveTo = ActionUtils.getDashMoveTo(entity, reverseDirection(direction), abilityStats)
        if moveTo ~= entity.body:getPosition() then
            castingGuide:indicateMoveTo(moveTo)
        end

    end

end
local MOVE_DURATION = ACTION_CONSTANTS.WALK_DURATION
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local ON_HIT = class("actions.hit")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
end

function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("move")
    self:addComponent("charactertrail")
    self.delayed = false
end

function ACTION:spawnProjectile(anchor)
    self.entity.projectilespawner:spawn(anchor, self.direction, self.abilityStats, Vector:new(2, 1), false)
end

function ACTION:process(currentEvent)
    local entity = self.entity
    entity.sprite:turnToDirection(self.direction)
    local moveFrom = entity.body:getPosition()
    local moveTo = ActionUtils.getDashMoveTo(entity, reverseDirection(self.direction), self.abilityStats)
    if not entity.buffable:canMove() or moveTo == moveFrom then
        local action = entity.actor:create(ACTIONS_FRAGMENT.THROW, self.direction)
        currentEvent = action:parallelChainEvent(currentEvent):chainEvent(function(_, anchor)
            self:spawnProjectile(anchor)
        end)
    else
        if not self.delayed then
            self:spawnProjectile(currentEvent)
        end

        local moveDirection = reverseDirection(self.direction)
        self.charactertrail:start(currentEvent)
        self.move.distance = moveTo:distanceManhattan(moveFrom)
        self.move.direction = moveDirection
        self.move:prepare(currentEvent)
        Common.playSFX("DASH_SHORT")
        currentEvent = self.move:chainMoveEvent(currentEvent, MOVE_DURATION):chainEvent(function(_, anchor)
            self.charactertrail:stop()
            if self.delayed then
                Common.playSFX("THROW")
                self:spawnProjectile(anchor)
            end

        end)
    end

    return currentEvent
end

local LEGENDARY = ITEM:createLegendary("Whisperblade's Cunning")
LEGENDARY.statLine = "{C:KEYWORD}Chance before getting hit by a {C:KEYWORD}Melee " .. "{C:KEYWORD}Attack to cast this ability for free towards the attacker."
local LEGENDARY_TRIGGER = class(TRIGGERS.PRE_HIT)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self.hitSource = false
    self.evaded = false
end

function LEGENDARY_TRIGGER:isEnabled()
    if self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() then
        local sourceEntity = self.hit.sourceEntity
        if ActionUtils.isAliveAgent(sourceEntity) then
            local source = sourceEntity.body:getPosition()
            local entityPosition = self.entity.body:getPosition()
            if source.x == entityPosition.x or source.y == entityPosition.y then
                local direction = Common.getDirectionTowards(entityPosition, source)
                return self.entity.body:isPassableDirection(reverseDirection(direction))
            end

        end

    end

end

function LEGENDARY_TRIGGER:parallelResolve(currentEvent)
    self.hitSource = self.hit.sourceEntity
    if self.entity.buffable:canMove() then
        self.hit:clear()
        self.hit.sound = false
        self.evaded = true
    end

end

function LEGENDARY_TRIGGER:process(currentEvent)
    local entity = self.entity
    local source = self.hitSource.body:getPosition()
    local direction = Common.getDirectionTowards(entity.body:getPosition(), source)
    local action = entity.actor:create(ACTION, direction, self.abilityStats)
    action.delayed = self.evaded
    return action:parallelChainEvent(currentEvent)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

