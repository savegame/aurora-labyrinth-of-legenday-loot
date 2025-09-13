local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local BUFFS = require("definitions.buffs")
local Common = require("common")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local SHADER_SILHOUETTE = require("draw.shaders").SILHOUETTE
local ITEM = require("structures.item_def"):new("Deadly Dagger")
local ABILITY = require("structures.ability_def"):new("Fan of Knives")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(21, 10)
ITEM.attackClass = ATTACK_WEAPON.STAB_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 18, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0), [Tags.STAT_LUNGE] = 1, [Tags.STAT_VIRTUAL_RATIO] = 0.26, [Tags.STAT_ABILITY_POWER] = 2.45, [Tags.STAT_ABILITY_COUNT] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 18, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.0), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Throw %s {C:KEYWORD}Projectiles that deal %s damage each."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_COUNT, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(3, 6)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.directions = function(entity, abilityStats)
    if abilityStats:get(Tags.STAT_ABILITY_COUNT) < 8 then
        return DIRECTIONS_AA
    else
        return false
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide)
    ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, entity.body:getPosition() + Vector[cwDirection(direction)])
    ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, entity.body:getPosition() + Vector[ccwDirection(direction)])
end
local ACTION = class(ACTIONS_FRAGMENT.THROW)
ABILITY.actionClass = ACTION
local CELL = Vector:new(2, 1)
local OFFSET_FROM_CENTER = 0.5
function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        local spawner = self.entity.projectilespawner
        local source = self.entity.body:getPosition()
        spawner:spawnSpecial(anchor, "normal", self.direction, self.abilityStats, CELL, false)
        if self.abilityStats:get(Tags.STAT_ABILITY_COUNT, 0) > 1 then
            local vRight = Vector[cwDirection(self.direction)]
            local vLeft = Vector[ccwDirection(self.direction)]
            local _, projectileEntity1 = spawner:spawnSpecial(anchor, "normal", self.direction, self.abilityStats, CELL, false)
            projectileEntity1.projectile.position = source + vRight
            local offset1 = projectileEntity1.offset:createProfile()
            offset1.body = -vRight * OFFSET_FROM_CENTER
            local _, projectileEntity2 = spawner:spawnSpecial(anchor, "normal", self.direction, self.abilityStats, CELL, false)
            projectileEntity2.projectile.position = source + vLeft
            local offset2 = projectileEntity2.offset:createProfile()
            offset2.body = -vLeft * OFFSET_FROM_CENTER
            anchor:chainProgress(ACTION_CONSTANTS.WALK_DURATION, function(progress)
                offset1.body = -vRight * OFFSET_FROM_CENTER * (1 - progress)
                offset2.body = -vLeft * OFFSET_FROM_CENTER * (1 - progress)
            end):chainEvent(function()
                projectileEntity1.offset:deleteProfile(offset1)
                projectileEntity2.offset:deleteProfile(offset2)
            end)
        end

    end)
end

local LEGENDARY = ITEM:createLegendary("Magebane")
local LEGENDARY_STAT_LINE = "Your {C:KEYWORD}Projectiles deal %s bonus damage against " .. "{C:KEYWORD}Focusing enemies and cancel their {C:KEYWORD}Focus."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 6.5, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.1) })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    if hit:isDamagePositive() and hit.damageType == Tags.DAMAGE_TYPE_RANGED then
        local entity = hit.targetEntity
        if entity and entity:hasComponent("caster") and entity.caster.preparedAction then
            if entity.tank.hasDiedOnce then
                entity.caster:cancelPreparedAction(false)
                entity.buffable:clear()
                entity.tank.delayDeath = false
                entity.tank.currentHealth = 1
            end

            hit.minDamage = hit.minDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
            hit.maxDamage = hit.maxDamage + abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MAX)
            hit.buffs:push(BUFFS:get("CAST_CANCEL"):new())
            hit:increaseBonusState()
        end

    end

end
return ITEM

