local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ATTACK_WEAPON = require("actions.attack_weapon")
local TRIGGERS = require("actions.triggers")
local Common = require("common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Umbral Armor")
local ABILITY = require("structures.ability_def"):new("Umbral Guard")
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(14, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 54, [Tags.STAT_MAX_MANA] = 6, [Tags.STAT_ABILITY_POWER] = 4.375, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Whenever you get damaged, deal half of the damage to all adjacent spaces."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(12, 5)
ABILITY.iconColor = COLORS.STANDARD_DEATH
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    castingGuide:indicate(source)
    for direction in DIRECTIONS_AA() do
        castingGuide:indicate(source + Vector[direction])
    end

end
local EXPLOSION_DURATION = 0.5
local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.sortOrder = 2
    self.explosion.desaturate = 0
    self.explosion.excludeSelf = true
end

function TRIGGER:isEnabled()
    return self.hit:isDamagePositiveDirect()
end

function TRIGGER:process(currentEvent)
    self.explosion.source = self.entity.body:getPosition()
    self.explosion:setArea(self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND))
    Common.playSFX("EXPLOSION_SMALL", 0.8)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, target)
        local hit = self.entity.hitter:createHit()
        hit:setDamage(Tags.DAMAGE_TYPE_SPELL, self.hit.minDamage / 2, self.hit.maxDamage / 2)
        hit.slotSource = self:getSlot()
        hit:applyToPosition(anchor, target)
    end)
end

local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.triggerClasses:push(TRIGGER)
    self.expiresAtStart = true
    self.outlinePulseColor = COLORS.STANDARD_DEATH_BRIGHTER
end

local BLOCK_ICON = Vector:new(5, 20)
local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = BLOCK_ICON
    self.color = COLORS.STANDARD_DEATH_BRIGHTER
end

local LEGENDARY_COLOR = Color:new(0.2, 0.0, 0.0)
local LEGENDARY_WAIT = 0.13
local LEGENDARY_STAB_DURATION = 0.18
local LEGENDARY_STAB_BACK_DURATION = 0.13
local LEGENDARY = ITEM:createLegendary("Commander of Shadows")
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 23, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.6) })
local LEGENDARY_ATTACK = class(ATTACK_WEAPON.STAB)
function LEGENDARY_ATTACK:initialize(entity, direction, abilityStats)
    LEGENDARY_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self.swingDuration = LEGENDARY_STAB_DURATION
    self.backDuration = LEGENDARY_STAB_BACK_DURATION
    self.weaponswing:setSilhouetteColor(LEGENDARY_COLOR)
    self.hit = false
end

function LEGENDARY_ATTACK:chainBraceEvent(currentEvent)
    return currentEvent
end

function LEGENDARY_ATTACK:process(currentEvent)
    currentEvent = LEGENDARY_ATTACK:super(self, "process", currentEvent)
    currentEvent = currentEvent:chainEvent(function(_, anchor)
        local target = Common.getPositionComponent(self.entity):getPosition()
        target = target + Vector[self.direction]
        self.hit:applyToPosition(anchor, target)
    end)
    return currentEvent:chainProgress(self.holdDuration + self.backDuration)
end

local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

local WEAPON_ICON = Vector:new(1, 10)
function LEGENDARY_TRIGGER:process(currentEvent)
    local done = currentEvent:createWaitGroup(4)
    local entity = self.entity
    currentEvent = currentEvent:chainProgress(LEGENDARY_WAIT):chainEvent(function(_, anchor)
        for attackDirection in DIRECTIONS_AA() do
            local character = self.entity.sprite:createCharacterCopy()
            character.sprite:turnToDirection(attackDirection)
            character.sprite.layer = Tags.LAYER_BELOW_CHARACTERS
            character.melee.swingIcon = WEAPON_ICON
            character.charactereffects.fillColor = LEGENDARY_COLOR
            character.charactereffects.fillOpacity = 1
            local action = character.actor:create(LEGENDARY_ATTACK, attackDirection)
            action.hit = entity.hitter:createHit()
            action.hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            action:parallelChainEvent(currentEvent):chainEvent(function()
                character:delete()
            end):chainWaitGroupDone(done)
        end

    end)
    return done
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
local LEGENDARY_STAT_LINE = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to deal " .. "%s damage to all adjacent enemies."
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
return ITEM

