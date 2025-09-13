local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local COLORS = require("draw.colors")
local Common = require("common")
local textStatFormat = require("text.stat_format")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.item_def"):new("Tremor Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(3, 17)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 10.6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.84), [Tags.STAT_ABILITY_VALUE] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 1 })
local FORMAT = "Your {C:KEYWORD}Attacks deal %s damage to %s spaces " .. "behind the target."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_VALUE)
end
local TRIGGER = class(TRIGGERS.ON_ATTACK)
local EXPLOSION_DURATION = 0.4
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -1
    self:addComponent("explosion")
    self.explosion.excludeSelf = true
    self.explosion:setArea(Tags.ABILITY_AREA_3X3)
    self.explosion:setHueToEarth()
end

function TRIGGER:process(currentEvent)
    self.explosion.source = self.attackTarget
    self.explosion.extraExclude = function(position, size)
        if self.abilityStats:get(Tags.STAT_ABILITY_VALUE) == 5 then
            local rect = Rect:new(position.x - size, position.y - size, size * 2, size * 2)
            rect:growDirectionSelf(self.direction, -size)
            graphics.wRectangle(rect)
        else
            for direction in DIRECTIONS_AA() do
                if direction ~= self.direction then
                    local p2 = position + Vector[ccwDirection(direction, 1)] * size
                    local p3 = position + Vector[cwDirection(direction, 1)] * size
                    graphics.polygon("fill", position.x, position.y, p2.x, p2.y, p3.x, p3.y)
                end

            end

        end

    end
    local directions = Array:new(ccwDirection(self.direction, 1), self.direction, cwDirection(self.direction, 1))
    if self.abilityStats:get(Tags.STAT_ABILITY_VALUE) > 3 then
        directions:pushFirst(ccwDirection(self.direction))
        directions:push(cwDirection(self.direction))
    end

    local positions = directions:map(function(direction)
        return self.attackTarget + Vector[direction]
    end)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        if positions:contains(position) then
            local hit = self.entity.hitter:createHit()
            local damageType = Tags.DAMAGE_TYPE_SPELL
            hit:setDamageFromAbilityStats(damageType, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end

    end)
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("The Voice Beneath the Earth")
LEGENDARY.strokeColor = COLORS.STANDARD_EARTH
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = ITEM.statsBase:get(Tags.STAT_ABILITY_DAMAGE_BASE) / 4, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.84), [Tags.STAT_ABILITY_VALUE] = 2 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_VALUE, Tags.STAT_UPGRADED)
end
return ITEM

