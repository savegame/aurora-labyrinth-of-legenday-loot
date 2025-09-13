local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Brutal Axe")
local ABILITY = require("structures.ability_def"):new("Brutal Cleave")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(7, 8)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 21, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1), [Tags.STAT_VIRTUAL_RATIO] = 0.11, [Tags.STAT_ABILITY_POWER] = 3.39, [Tags.STAT_ABILITY_DAMAGE_BASE] = 21, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 40, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_BUFF_DURATION] = 1, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_AUTOCAST })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Focus - Deal %s damage to all adjacent targets, plus %s " .. "if that target hit you while {C:KEYWORD}Focusing."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(2, 3)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    for direction in DIRECTIONS_AA() do
        castingGuide:indicate(source + Vector[direction])
    end

end
local MAIN_ACTION = class("actions.action")
local BUFF = class(BUFFS.FOCUS)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats, action)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.attackers = Array:new()
    self.mainActionClass = MAIN_ACTION
end

function BUFF:decorateIncomingHit(hit)
    if hit:isDamageOrDebuff() then
        self.attackers:push(hit.sourceEntity)
    end

end

function BUFF:decoratePostFocusAction(action)
    action.attackers = self.attackers
end

local ACTION = class(ACTIONS_FRAGMENT.GLOW_MODAL)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.sound = "ENCHANT"
end

local SWING_DURATION = 0.5
local BRACE_DISTANCE = 0.15
local BRACE_DURATION = 0.2
local BRACE_HOLD = 0.2
local ORIGIN_OFFSET = 0.375
function MAIN_ACTION:initialize(entity, direction, abilityStats)
    MAIN_ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self.weaponswing:setTrailToLingering()
    self.weaponswing.isOriginPosition = true
    self.weaponswing.itemOffset = Vector.ORIGIN
    self.weaponswing.isDirectionHorizontal = true
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

function MAIN_ACTION:process(currentEvent)
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
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        local entityAt = self.entity.body:getEntityAt(position)
        if entityAt then
            if self.attackers:contains(entityAt) then
                hit.minDamage = hit.minDamage + self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
                hit.maxDamage = hit.maxDamage + self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX)
                hit:increaseBonusState()
            end

            hit:applyToEntity(anchor, entityAt, position)
        end

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

local LEGENDARY = ITEM:createLegendary("Executioner's Cleaver")
LEGENDARY.statLine = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to instantly kill a " .. "non-{C:KEYWORD}Elite enemy."
local LEGENDARY_TRIGGER = class(PLAYER_TRIGGERS.ATTACK_KILL)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.iconflash.color = COLORS.STANDARD_RAGE
    self.activationType = Tags.TRIGGER_CHANCE
end

function LEGENDARY_TRIGGER:isEnabled()
    local entityAt = self.entity.body:getEntityAt(self.attackTarget)
    return not Common.isElite(entityAt)
end

function LEGENDARY_TRIGGER:shouldKill(entityAt)
    return not Common.isElite(entityAt)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

