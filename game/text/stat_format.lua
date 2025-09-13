local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local CONSTANTS = require("logic.constants")
local TERMS = require("text.terms")
local PREPENDED = Hash:new({ [Tags.STAT_MAX_HEALTH] = "+", [Tags.STAT_MAX_MANA] = "+", [Tags.STAT_COOLDOWN_REDUCTION] = "-", [Tags.STAT_ABILITY_DENOMINATOR] = "1/", [Tags.STAT_MODIFIER_DENOMINATOR] = "1/", [Tags.STAT_ABILITY_BURN_DURATION] = "" })
local function getColorFromAlteration(alteration)
        if alteration > 0 then
        return "UPGRADED"
    elseif alteration < 0 then
        return "DOWNGRADED"
    else
        return "NUMBER"
    end

end

local function getStatColor(item, stat)
    return getColorFromAlteration(item:getStatAlteration(stat))
end

local function statDouble(item, statMin, statMax, hasPlus, isRange)
    local plusString = ""
    if hasPlus then
        plusString = "+"
    end

    local colorMin, colorMax = getStatColor(item, statMin), getStatColor(item, statMax)
    local valueMax = item.stats:get(statMax)
    local valueMin
    if isRange then
        valueMin = item.stats:get(statMin, 1)
    else
        valueMin = item.stats:get(statMin)
    end

            if valueMin == valueMax then
        return ("{C:%s}%s%d"):format(colorMin, plusString, valueMin)
    elseif isRange and valueMax >= CONSTANTS.PRESUMED_INFINITE then
        return ("{C:%s}%s%d+"):format(colorMin, plusString, valueMin)
    elseif colorMin == colorMax then
        return ("{C:%s}%s%d-%d"):format(colorMin, plusString, valueMin, valueMax)
    else
        return ("{C:%s}%s%d{C:NUMBER}-{C:%s}%d"):format(colorMin, plusString, valueMin, colorMax, valueMax)
    end

end

local AREA_FORMAT = "{C:KEYWORD}%s {C:KEYWORD}Area"
local AREA_FORMAT_UPGRADED = "{C:UPGRADED}%s {C:UPGRADED}Area"
return function(textFormat, item, ...)
    local stats = Array:new(...):map(function(stat)
                                                        if stat == Tags.STAT_ATTACK_DAMAGE_MIN then
            return statDouble(item, Tags.STAT_ATTACK_DAMAGE_MIN, Tags.STAT_ATTACK_DAMAGE_MAX, item:getSlot() ~= Tags.SLOT_WEAPON)
        elseif stat == Tags.STAT_ABILITY_DAMAGE_MIN then
            return statDouble(item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_DAMAGE_MAX)
        elseif stat == Tags.STAT_ABILITY_RANGE_MIN then
            return statDouble(item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_RANGE_MAX, false, true)
        elseif stat == Tags.STAT_SECONDARY_DAMAGE_MIN then
            return statDouble(item, Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_SECONDARY_DAMAGE_MAX)
        elseif stat == Tags.STAT_MODIFIER_DAMAGE_MIN then
            return statDouble(item, Tags.STAT_MODIFIER_DAMAGE_MIN, Tags.STAT_MODIFIER_DAMAGE_MAX)
        elseif stat == Tags.STAT_ABILITY_AREA_ROUND or stat == Tags.STAT_MODIFIER_AREA_ROUND then
            local areaFormat = AREA_FORMAT
            if item:getStatAlteration(stat) > 0 then
                areaFormat = AREA_FORMAT_UPGRADED
            end

            return areaFormat:format(TERMS.ABILITY_AREA[item.stats:get(stat)])
        elseif stat == Tags.STAT_ABILITY_AREA_CLEAVE then
            return TERMS.ABILITY_CLEAVE_AREA[item.stats:get(Tags.STAT_ABILITY_AREA_CLEAVE)]
        else
            local color = getStatColor(item, stat)
            local value = item.stats:get(stat)
            local prepended = PREPENDED:get(stat, "")
            if value < 0 then
                prepended = ""
            end

            local result
            if value >= CONSTANTS.PRESUMED_INFINITE then
                result = ("{C:%s}%s"):format(color, prepended) .. TERMS.INFINITE
            else
                result = ("{C:%s}%s%d"):format(color, prepended, value)
            end

                        if stat == Tags.STAT_ABILITY_DEBUFF_DURATION or stat == Tags.STAT_ABILITY_BURN_DURATION or stat == Tags.STAT_MODIFIER_DEBUFF_DURATION then
                if value == 1 then
                    result = result .. " turn"
                else
                    result = result .. " turns"
                end

            elseif stat == Tags.STAT_ABILITY_RANGE or stat == Tags.STAT_SECONDARY_RANGE or stat == Tags.STAT_MODIFIER_RANGE then
                if value == 1 then
                    result = result .. " space"
                else
                    result = result .. " spaces"
                end

            end

            if stat == Tags.STAT_ABILITY_BURN_DURATION then
                result = "{C:KEYWORD}Burn - " .. result
            end

            return result
        end

    end)
    return textFormat:format(stats:expand())
end

