local ItemStats = class()
local CONSTANTS = require("logic.constants")
function ItemStats:initialize(data)
    if data then
        self.highestLevelNormal = data.highestLevelNormal
        self.highestLevelLegendary = data.highestLevelLegendary
        self.kills = data.kills
        self.stairs = data.stairs
        self.deaths = data.deaths
        self.wins = data.wins
        self.timesCastedAbility = data.timesCastedAbility
        self.timesSeenNormal = data.timesSeenNormal
        self.timesSeenLegendary = data.timesSeenLegendary
    else
        self.highestLevelNormal = -1
        self.highestLevelLegendary = -1
        self.kills = 0
        self.stairs = 0
        self.deaths = 0
        self.wins = 0
        self.timesCastedAbility = 0
        self.timesSeenNormal = 0
        self.timesSeenLegendary = 0
    end

end

local HIGHEST_LEVEL_FORMAT = "%s / %s"
local FOUND_FORMAT = "%d / %d"
function ItemStats:getStatString(stat)
    local text = tostring(self[stat])
    if stat == "highestLevelNormal" or stat == "highestLevelLegendary" then
        if self[stat] == -1 then
            return "-", "NUMBER"
        end

        text = "+" .. text
        if self[stat] == CONSTANTS.ITEM_UPGRADE_LEVELS then
            return text, "UPGRADED"
        end

    end

    return text, "NUMBER"
end

function ItemStats:discoverItem(item)
    if item:isLegendary() then
        self.highestLevelLegendary = max(self.highestLevelLegendary, item.level)
    else
        self.highestLevelNormal = max(self.highestLevelNormal, item.level)
    end

end

function ItemStats:toData()
    return { highestLevelNormal = self.highestLevelNormal, highestLevelLegendary = self.highestLevelLegendary, kills = self.kills, stairs = self.stairs, deaths = self.deaths, wins = self.wins, timesCastedAbility = self.timesCastedAbility, timesSeenNormal = self.timesSeenNormal, timesSeenLegendary = self.timesSeenLegendary }
end

return ItemStats

