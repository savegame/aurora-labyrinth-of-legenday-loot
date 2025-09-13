local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Mystic Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(1, 21)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = -50, [Tags.STAT_MAX_MANA] = 100 })
ITEM:setGrowthMultiplier({ [Tags.STAT_MAX_HEALTH] = 2 / 3, [Tags.STAT_MAX_MANA] = 4 / 3 })
ITEM.postCreate = function(item)
    item:markAltered(Tags.STAT_MAX_HEALTH, Tags.STAT_DOWNGRADED)
end
local LEGENDARY = ITEM:createLegendary("Touch of Madness")
LEGENDARY.strokeColor = COLORS.STANDARD_DEATH
LEGENDARY:setToStatsBase({ [Tags.STAT_COOLDOWN_REDUCTION] = 2 })
LEGENDARY:addPowerSpike({ [Tags.STAT_COOLDOWN_REDUCTION] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_COOLDOWN_REDUCTION] = 1 })
return ITEM

