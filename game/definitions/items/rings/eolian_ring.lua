local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_WEAPON = require("actions.attack_weapon")
local COLORS = require("draw.colors")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Eolian Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(22, 20)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = 13, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 25, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.63) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Override your {C:KEYWORD}Attack, instead dealing %s damage to " .. "%s in a line front of you."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE)
end
local ACTION = class("actions.base_attack")
ITEM.attackClass = ACTION
local COLOR = COLORS.STANDARD_WIND
local ICON = Vector:new(6, 17)
local ITEM_ANGLE_START = math.tau * 0.0
local BRACE_DURATION = 0.25
local CHARGE_DURATION = 0.2
local SWING_DURATION = 0.18
local HOLD_DURATION = 0.3
local BACK_DURATION = 0.1
local ORIGIN_OFFSET = 0.5
local RANGE_EXTRA_DISTANCE = 0.4
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self.weaponswing:setTrailToLingering()
    self.weaponswing.angleStart = ITEM_ANGLE_START
    self.weaponswing:setSilhouetteColor(COLOR)
    self.weaponswing.icon = ICON
    self:addComponent("tackle")
    self.tackle.braceDistance = ACTION_CONSTANTS.DEFAULT_BRACE_DISTANCE
    self.tackle.forwardDistance = self.tackle.braceDistance
    self.attackTarget = false
    self.swingDuration = SWING_DURATION
    self.braceDuration = BRACE_DURATION
    self.backDuration = BACK_DURATION
    self.holdDuration = HOLD_DURATION
    self.chargeDuration = CHARGE_DURATION
end

function ACTION:speedMultiply(factor)
    factor = 1 - (1 - factor) / 2
    self.swingDuration = self.swingDuration / factor
    self.braceDuration = self.braceDuration / factor
    self.backDuration = self.backDuration / factor
    self.holdDuration = self.holdDuration / factor
    self.chargeDuration = self.chargeDuration / factor
end

function ACTION:getAttackDamage()
    local minDamage = self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
    local maxDamage = self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
    return minDamage, maxDamage
end

local KNOCKBACK_STEP_DURATION = BRACE_DURATION / 2
function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    if self.entity.sprite.layer == Tags.LAYER_CHARACTER and (self.direction == LEFT or self.direction == RIGHT) then
        self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    self.tackle:createOffset()
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local swingItem = self.weaponswing:createSwingItem()
    swingItem.opacity = 0
    swingItem.fillOpacity = 0
    swingItem.scale = range + RANGE_EXTRA_DISTANCE
    swingItem.originOffset = -ORIGIN_OFFSET
    swingItem.filterOutline = true
    local targets = Array:new()
    for i = 1, range do
        local target = self.entity.body:getPosition() + Vector[self.direction] * i
        if not self.entity.body:canBePassable(target) then
            break
        end

        targets:push(target)
    end

    Common.playSFX("WEAPON_CHARGE")
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        for target in targets() do
            if self.entity.body:isPassable(target) then
                for direction in DIRECTIONS_AA() do
                    local pullDirection = reverseDirection(direction)
                    if pullDirection ~= self.direction then
                        local pullTarget = target + Vector[direction]
                        if not targets:contains(pullTarget) then
                            local hit = self.entity.hitter:createHit()
                            hit.sound = false
                            hit:setKnockback(1, pullDirection, KNOCKBACK_STEP_DURATION, false, true)
                            hit:setKnockbackDamage(self.abilityStats)
                            hit:applyToPosition(currentEvent, pullTarget)
                        end

                    end

                end

            end

        end

    end

    self.tackle:chainBraceEvent(currentEvent, self.braceDuration)
    currentEvent = currentEvent:chainProgress(self.braceDuration + self.chargeDuration, function(progress)
        swingItem.fillOpacity = progress
    end):chainEvent(function()
        Common.playSFX("WHOOSH_BIG")
    end)
    self.tackle:chainForwardEvent(currentEvent, self.swingDuration)
    currentEvent:chainProgress(self.swingDuration, function(progress)
        swingItem.originOffset = -ORIGIN_OFFSET * (1 - progress)
    end)
    currentEvent = self.weaponswing:chainSwingEvent(currentEvent, self.swingDuration):chainEvent(function(_, anchor)
        for target in targets() do
            local entityAt = self.entity.body:getEntityAt(target)
            local hit = self.entity.hitter:createHit()
            if target == self.attackTarget then
                hit = self:createHit()
            else
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
            end

            hit:applyToPosition(anchor, target)
        end

        self.entity.equipment:setOnCooldown(self:getSlot(), 1)
        self.entity.equipment:recordCast(self:getSlot())
    end)
    currentEvent:chainProgress(self.holdDuration, function(progress)
        swingItem.fillOpacity = 1 - progress
    end):chainEvent(function()
        self.weaponswing:deleteSwingItem()
    end)
    return self.tackle:chainBackEvent(currentEvent, self.backDuration):chainEvent(function()
        self.tackle:deleteOffset()
    end)
end

local LEGENDARY = ITEM:createLegendary("Vortex")
LEGENDARY.passiveExtraLine = "Before dealing damage, pull targets adjacent to the area into the area."
LEGENDARY.strokeColor = COLORS.STANDARD_WIND
LEGENDARY:setToStatsBase({ [Tags.STAT_KNOCKBACK_DAMAGE_BASE] = CONSTANTS.KNOCKBACK_DAMAGE_BASE, [Tags.STAT_KNOCKBACK_DAMAGE_VARIANCE] = CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE, [Tags.STAT_ABILITY_COOLDOWN] = -2, [Tags.STAT_ABILITY_RANGE] = 1 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_COOLDOWN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_RANGE, Tags.STAT_UPGRADED)
end
return ITEM

