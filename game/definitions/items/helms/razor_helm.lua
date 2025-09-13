local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ACTION_CONSTANTS = require("actions.constants")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ActionUtils = require("actions.utils")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Razor Helm")
local ABILITY = require("structures.ability_def"):new("Steel Lotus")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(6, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 36, [Tags.STAT_MAX_MANA] = 4, [Tags.STAT_ABILITY_POWER] = 5.4, [Tags.STAT_ABILITY_DAMAGE_BASE] = 33.29, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.21), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED, [Tags.STAT_ABILITY_COUNT] = 8 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Throw %s {C:KEYWORD}Projectiles in all directions that each deal %s damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_COUNT, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(11, 11)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.directions = false
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    for direction in DIRECTIONS() do
        ActionUtils.indicateProjectile(entity, direction, abilityStats, castingGuide, source)
    end

end
local ACTION = class(ACTIONS_FRAGMENT.ENCHANT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.sound = "WEAPON_CHARGE"
end

function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function(_, anchor)
        Common.playSFX("THROW")
        local spawner = self.entity.projectilespawner
        for direction in DIRECTIONS() do
            local spawnEvent, projectileEntity = spawner:spawnSpecial(anchor, "razor_helm", direction, self.abilityStats)
        end

    end)
end

local LEGENDARY = ITEM:createLegendary("Crown of Blades")
LEGENDARY.abilityExtraLine = "Each {C:KEYWORD}Projectile splits into {C:NUMBER}2 more projectiles upon " .. "collision, dealing the same damage."
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = ITEM.statsBase:get(Tags.STAT_ABILITY_DAMAGE_BASE) / 6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1) })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

