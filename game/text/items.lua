local TextItems = {  }
local TERMS = require("text.terms")
local CONSTANTS = require("logic.constants")
local Array = require("utils.classes.array")
local Set = require("utils.classes.set")
local textStatFormat = require("text.stat_format")
local function addStat(result, item, statKey, statFormat)
    if item.stats:hasKey(statKey) then
        result:push(textStatFormat(statFormat, item, statKey))
    end

end

local FORMAT_ATTACK = "%s Attack Damage"
local FORMAT_HEALTH = "%s Health"
local FORMAT_MANA = "%s Mana"
local function addHealthManaLines(result, item)
    addStat(result, item, Tags.STAT_MAX_HEALTH, FORMAT_HEALTH)
    addStat(result, item, Tags.STAT_MAX_MANA, FORMAT_MANA)
end

local FORMAT_COOLDOWN_REDUCE = TERMS.FORMAT_COOLDOWN_REDUCE
local FORMAT_COOLDOWN_REDUCE_NON_WEAPON = "{B:STAT_LINE}" .. FORMAT_COOLDOWN_REDUCE
local FORMAT_LUNGE = "{C:KEYWORD}Lunge"
local FORMAT_REACH = "{C:KEYWORD}Reach"
function TextItems.getStatLines(item)
    local result = Array:new()
    local slot = item:getSlot()
    if slot == Tags.SLOT_WEAPON then
        addStat(result, item, Tags.STAT_ATTACK_DAMAGE_MIN, FORMAT_ATTACK)
        addHealthManaLines(result, item)
        addStat(result, item, Tags.STAT_COOLDOWN_REDUCTION, FORMAT_COOLDOWN_REDUCE)
    else
        addHealthManaLines(result, item)
        addStat(result, item, Tags.STAT_ATTACK_DAMAGE_MIN, FORMAT_ATTACK)
        addStat(result, item, Tags.STAT_COOLDOWN_REDUCTION, FORMAT_COOLDOWN_REDUCE_NON_WEAPON)
    end

    if item.stats:get(Tags.STAT_LUNGE, 0) > 0 then
        result:push(FORMAT_LUNGE)
    end

    if item.stats:get(Tags.STAT_REACH, 0) > 0 then
        result:push(FORMAT_REACH)
    end

    return result
end

local NUMBER_TEXT_FORMAT = "{C:NUMBER}%d %s"
function TextItems.numberText(value, text)
    local result = NUMBER_TEXT_FORMAT:format(value, text)
    if value ~= 1 then
        return result .. "s"
    else
        return result
    end

end

return TextItems

