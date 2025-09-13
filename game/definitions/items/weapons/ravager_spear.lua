local Vector = require("utils.classes.vector")
local Set = require("utils.classes.set")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Ravager Spear")
local ABILITY = require("structures.ability_def"):new("Full Sweep")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(6, 17)
ITEM.attackClass = ATTACK_WEAPON.STAB_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 16.0, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.85), [Tags.STAT_REACH] = 1, [Tags.STAT_VIRTUAL_RATIO] = 0.53, [Tags.STAT_ABILITY_POWER] = 2.97, [Tags.STAT_ABILITY_DAMAGE_BASE] = 17.0, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.7), [Tags.STAT_ABILITY_AREA_CLEAVE] = 5 })
ITEM:setGrowthMultiplier({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1.5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to all targets within half of a {C:KEYWORD}Large {C:KEYWORD}Area " .. "around you"
local FORMAT_LEGENDARY = ", {B:STAT_LINE}plus %s for every enemy caught in the area."
ABILITY.getDescription = function(item)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return textStatFormat(FORMAT .. FORMAT_LEGENDARY, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_MODIFIER_DAMAGE_MIN)
    else
        return textStatFormat(FORMAT .. ".", item, Tags.STAT_ABILITY_DAMAGE_MIN)
    end

end
ABILITY.icon = Vector:new(7, 9)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    for position in (ActionUtils.getCleavePositions(source, area, direction))() do
        castingGuide:indicate(position)
        local offset = position - source
        castingGuide:indicate(position + offset:xPart())
        castingGuide:indicate(position + offset:yPart())
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local SWING_DURATION = 0.5
local FORWARD_DURATION = 0.14
local FORWARD_DISTANCE = 0.25
local ORIGIN_OFFSET_NORMAL = 0.5
local ORIGIN_OFFSET_WIND = 0.25
local WIND_SCALE = 2
local SWING_WAIT = 0.1
function ACTION:initialize(entity, direction, abilityStats)
    self:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self.weaponswing:setTrailToLingering()
    self.weaponswing.isOriginPosition = true
    self.weaponswing.itemOffset = Vector.ORIGIN
    self.weaponswing:setSilhouetteColor(ABILITY.iconColor)
    self:addComponentAs("weaponswing", "weaponswingnormal")
    self.weaponswingnormal:setTrailToLingering()
    self.weaponswingnormal.isOriginPosition = true
    self.weaponswingnormal.itemOffset = Vector.ORIGIN
    self:addComponent("cleaveorder")
    self:addComponent("tackle")
    self.tackle.forwardDistance = FORWARD_DISTANCE
    self.bonusMinDamage = 0
    self.bonusMaxDamage = 0
end

function ACTION:affectPosition(anchor, source, position)
    local hit = self.entity.hitter:createHit(source)
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    if self.bonusMinDamage > 0 then
        hit.minDamage = hit.minDamage + self.bonusMinDamage
        hit.maxDamage = hit.maxDamage + self.bonusMaxDamage
        hit:increaseBonusState()
    end

    hit:applyToPosition(anchor, position)
end

function ACTION:process(currentEvent)
    local direction = self.direction
    self.entity.sprite:turnToDirection(direction)
    self.tackle:createOffset()
    self.cleaveorder.area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    self.weaponswing:setAngles(self.cleaveorder:getAngles())
    self.weaponswingnormal:setAngles(self.cleaveorder:getAngles())
    self.tackle:chainForwardEvent(currentEvent, FORWARD_DURATION)
    currentEvent = currentEvent:chainProgress(FORWARD_DURATION / 2):chainEvent(function()
        self.weaponswing:createSwingItem()
        self.weaponswing.swingItem.scale = WIND_SCALE
        self.weaponswing.swingItem.originOffset = ORIGIN_OFFSET_WIND
        self.weaponswingnormal:createSwingItem()
        self.weaponswingnormal.swingItem.originOffset = ORIGIN_OFFSET_NORMAL
        Common.playSFX("WHOOSH_BIG")
    end)
    local source = self.entity.body:getPosition()
    self.bonusMinDamage = 0
    self.bonusMaxDamage = 0
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local enemies = Set:new()
        for position in (ActionUtils.getCleavePositions(source, self.cleaveorder.area, direction))() do
            local entityAt = self.entity.body:getEntityAt(position)
            if entityAt and entityAt:hasComponent("agent") then
                enemies:add(entityAt)
            end

            local offset = position - source
            entityAt = self.entity.body:getEntityAt(position + offset:xPart())
            if entityAt and entityAt:hasComponent("agent") then
                enemies:add(entityAt)
            end

            entityAt = self.entity.body:getEntityAt(position + offset:yPart())
            if entityAt and entityAt:hasComponent("agent") then
                enemies:add(entityAt)
            end

        end

        self.bonusMinDamage = enemies:size() * self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
        self.bonusMaxDamage = enemies:size() * self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
    end

    self.cleaveorder:chainHitEvent(currentEvent, SWING_DURATION, function(anchor, position, nextDuration)
        self:affectPosition(anchor, source, position)
        local offset = position - source
        local nextHit = false
        if offset.x == 0 or offset.y == 0 then
            self:affectPosition(anchor, source, position + offset)
            if nextDuration then
                if offset ~= Vector[direction] then
                    nextHit = position + offset + Vector[direction]
                else
                    nextHit = position + offset + Vector[ccwDirection(direction)]
                end

            end

        else
            local offsetDirection = DIRECTIONS:findOne(function(direction)
                return Vector[direction] == offset
            end)
            nextHit = position + Vector[ccwDirection(offsetDirection, 1)]
        end

        if nextHit then
            anchor:chainProgress(nextDuration / 2):chainEvent(function(_, anchor)
                self:affectPosition(anchor, source, nextHit)
            end)
        end

    end)
    self.weaponswingnormal:chainSwingEvent(currentEvent, SWING_DURATION)
    currentEvent = self.weaponswing:chainSwingEvent(currentEvent, SWING_DURATION):chainProgress(SWING_WAIT)
    return self.tackle:chainBackEvent(currentEvent, FORWARD_DURATION):chainEvent(function()
        self.weaponswing:deleteSwingItem()
        self.weaponswingnormal:deleteSwingItem()
        self.tackle:deleteOffset()
    end)
end

local LEGENDARY = ITEM:createLegendary("Spear of Annihilation")
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 13.5 / 3, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.66) })
LEGENDARY:setGrowthMultiplier({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 2 })
return ITEM

