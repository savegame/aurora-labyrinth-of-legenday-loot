local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local Common = require("common")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Hailstone Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(19, 16)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 9.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.1), [Tags.STAT_ABILITY_RANGE] = 2, [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 2 })
local FORMAT = "Whenever an non-adjacent enemy hits you, " .. "deal %s damage to it "
local FORMAT_LEGENDARY = "{B:STAT_LINE}and all spaces adjacent to it {B:NORMAL}"
local FORMAT_END = "and apply {C:KEYWORD}Cold for %s."
ITEM.getPassiveDescription = function(item)
    local descFormat = FORMAT
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        descFormat = descFormat .. FORMAT_LEGENDARY
    end

    return textStatFormat(descFormat .. FORMAT_END, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToIce()
    self.sound = "EXPLOSION_ICE"
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) == 0 then
        self.soundPitch = 1.5
    end

end

function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
    self.hit:addBuff(BUFFS:get("COLD"):new(duration))
end

function ON_HIT:process(currentEvent)
    currentEvent = ON_HIT:super(self, "process", currentEvent)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
        local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
        local positions = ActionUtils.getAreaPositions(self.entity, self.targetPosition, area, true)
        for position in positions() do
            if position ~= self.entity.body:getPosition() then
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                hit:addBuff(BUFFS:get("COLD"):new(duration))
                hit:applyToPosition(currentEvent, position)
            end

        end

    end

    return currentEvent
end

local TRIGGER = class(TRIGGERS.POST_HIT)
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("projectilerain")
    self.projectilerain.projectile = Vector:new(1, 1)
    self.projectilerain.onHitClass = ON_HIT
    self.projectilerain.area = Tags.ABILITY_AREA_SINGLE
end

function TRIGGER:isEnabled()
    local source = self.hit.sourceEntity
    if ActionUtils.isAliveAgent(source) then
        local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
        return self.hit:getApplyDistance() >= range
    end

    return false
end

function TRIGGER:parallelResolve(anchor)
    self.projectilerain.source = self.hit.sourceEntity.body:getPosition()
end

function TRIGGER:process(currentEvent)
    self.entity.entityspawner:spawn("temporary_vision", self.projectilerain.source)
    return self.projectilerain:chainRainEvent(currentEvent)
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Spiteful Azure")
LEGENDARY.strokeColor = COLORS.STANDARD_ICE
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 1 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DEBUFF_DURATION, Tags.STAT_UPGRADED)
end
return ITEM

