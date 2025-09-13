local TUTORIAL = {  }
local Common = require("common")
local Array = require("utils.classes.array")
local ARROW_FORMAT = "Press {B:NUMBER}%s, %s, %s {C:NORMAL}or %s {B:BASE}"
local FIRST_LINE_2 = "to move."
local SECOND_LINE_2 = "to attack objects or enemies in the way."
local TURN_BASED_1 = "This game is {C:KEYWORD}Turn-Based. Enemies do not move until "
local TURN_BASED_2 = "you do. You can press {B:NUMBER}%s {B:BASE}to wait {C:NUMBER}1 turn."
local PROJECTILES_1 = "{C:KEYWORD}Projectiles travel at a constant speed"
local PROJECTILES_2 = "every turn and can be avoided."
local FOCUS_1 = "When an enemy is glowing red, it is {C:KEYWORD}Focusing an ability."
local FOCUS_2 = "It will cast the ability next turn, but you can avoid it."
local HEALTH_ORB_1 = "Enemies sometimes drop {C:KEYWORD}Health {C:KEYWORD}Orbs when killed."
local HEALTH_ORB_2 = "Health orbs restore your health when you pick them up."
local HEALTH_ORB_ELITE_1 = "{C:KEYWORD}Elite enemies drop silver {C:KEYWORD}Health {C:KEYWORD}Orbs."
local HEALTH_ORB_ELITE_2 = "Besides restoring health, they also give " .. "{ICON:SALVAGE}{C:KEYWORD}Scrap when picked up."
local SCRAP_ENOUGH_1 = "You now have enough {ICON:SALVAGE}{C:KEYWORD}Scrap to upgrade your equipment."
local SCRAP_ENOUGH_2 = "Press {B:NUMBER}%s {B:BASE}to access your equipment."
local HEALTH_PEDESTAL_1 = "A health pedestal will drop"
local HEALTH_PEDESTAL_2 = "a {C:KEYWORD}Health {C:KEYWORD}Orb when destroyed."
local ANVIL_1 = "Anvils can enchant your equipment, making it stronger."
local ANVIL_2 = "It is destroyed after one use."
local ELITE_1 = "Enemies with a colored border are {C:KEYWORD}Elite enemies."
local ELITE_2 = "They are stronger than normal enemies, and have special bonuses."
local UPGRADE_1 = "Press {B:NUMBER}%s {C:NORMAL}or %s {B:NORMAL}to select the item you want to upgrade."
local UPGRADE_2 = "Press {B:NUMBER}%s {B:BASE}on {C:COMMON_NOUN}Upgrade to upgrade the selected item."
local STAIRS_1 = "You've found the stairs! Going down the stairs will save your progress and fully"
local STAIRS_2 = "restore your health and mana. If your health is low, run for the stairs!"
local ITEM_1_1 = "You found a new item! Press {B:NUMBER}%s {B:BASE}on {C:COMMON_NOUN}Equip to equip it."
local ITEM_1_2 = "Most items give you an ability when you equip it."
local ITEM_2_1 = "To cast this ability, Press {B:NUMBER}%s."
local ITEM_2_2 = "Choose a direction, then press {B:NUMBER}%s {B:BASE}to cast it."
local ITEM_3_1 = "Abilities cost mana, indicated by the blue bar."
local ITEM_3_2 = "Mana regenerates every turn."
local ITEM_4_1 = "You found a new weapon!"
local ITEM_4_2 = "Press {B:NUMBER}%s {B:BASE}on {C:COMMON_NOUN}Equip to equip this weapon."
local ITEM_5_1 = "Highlight {C:COMMON_NOUN}Salvage by pressing {B:NUMBER}%s {B:BASE}or {B:NUMBER}%s."
local ITEM_5_2 = "Press {B:NUMBER}%s {B:BASE}on {C:COMMON_NOUN}Salvage to turn your old weapon into " .. "{ICON:SALVAGE}{C:KEYWORD}Scrap."
local ITEM_6_1 = "Words marked in {C:KEYWORD}Purple have special meaning that can be found"
local ITEM_6_2 = "in the game terms menu. You can press {B:NUMBER}%s {B:BASE}to access it."
local DESTRUCTIBLE_1 = "Destructibles like pots, shelves, and"
local DESTRUCTIBLE_2 = "weapon racks do not contain items."
if PortSettings.IS_MOBILE then
    ARROW_FORMAT = "Press %s %s %s or %s"
    ITEM_1_1 = "You found a new item! Press {C:COMMON_NOUN}Equip to equip it."
    ITEM_2_1 = "To cast this ability, Press the ability icon on the right side."
    ITEM_2_2 = "Choose a direction, then press the icon again to cast it."
    ITEM_4_2 = "Press {C:COMMON_NOUN}Equip to equip this weapon."
    ITEM_5_1 = "You can only equip one weapon at a time."
    ITEM_5_2 = "Press {C:COMMON_NOUN}Salvage to turn your old weapon into " .. "{ICON:SALVAGE}{C:KEYWORD}Scrap."
    UPGRADE_1 = "Press to select the item you want to upgrade."
    UPGRADE_2 = "Press {C:COMMON_NOUN}Upgrade to upgrade the selected item."
end

local function getArrowFormat()
    local b1 = Common.getKeyName(Tags.KEYCODE_UP)
    local b2 = Common.getKeyName(Tags.KEYCODE_DOWN)
    local b3 = Common.getKeyName(Tags.KEYCODE_LEFT)
    local b4 = Common.getKeyName(Tags.KEYCODE_RIGHT)
    return ARROW_FORMAT:format(b1, b2, b3, b4)
end

function TUTORIAL.getLines(index)
                                        if index == 1 then
        return getArrowFormat(), FIRST_LINE_2
    elseif index == 3 then
        return getArrowFormat(), SECOND_LINE_2
    elseif index == 5 then
        return TURN_BASED_1, TURN_BASED_2:format(Common.getKeyName(Tags.KEYCODE_WAIT))
    elseif index == 8 then
        return PROJECTILES_1, PROJECTILES_2
    elseif index == 11 then
        return FOCUS_1, FOCUS_2
    elseif index == 12 then
        return HEALTH_PEDESTAL_1, HEALTH_PEDESTAL_2
    elseif index == 14 then
        return ANVIL_1, ANVIL_2
    elseif index == 16 then
        return ELITE_1, ELITE_2
    elseif index == 17 then
        return STAIRS_1, STAIRS_2
    elseif index == 18 then
        return DESTRUCTIBLE_1, DESTRUCTIBLE_2
    end

    return false, false
end

function TUTORIAL.getItemLines(index)
    if PortSettings.IS_MOBILE then
                                if index == 1 then
            return ITEM_1_1, ITEM_1_2
        elseif index == 2 then
            return ITEM_2_1, ITEM_2_2
        elseif index == 4 then
            return ITEM_4_1, ITEM_4_2
        elseif index == 5 then
            return ITEM_5_1, ITEM_5_2
        end

    end

                            if index == 1 then
        return ITEM_1_1:format(Common.getKeyName(Tags.KEYCODE_CONFIRM)), ITEM_1_2
    elseif index == 2 then
        return ITEM_2_1:format(Common.getKeyName(Tags.KEYCODE_ABILITY_2)), ITEM_2_2:format(Common.getKeyName(Tags.KEYCODE_CONFIRM))
    elseif index == 3 then
        return ITEM_3_1, ITEM_3_2
    elseif index == 4 then
        return ITEM_4_1, ITEM_4_2:format(Common.getKeyName(Tags.KEYCODE_CONFIRM))
    elseif index == 5 then
        return ITEM_5_1:format(Common.getKeyName(Tags.KEYCODE_LEFT), Common.getKeyName(Tags.KEYCODE_RIGHT)), ITEM_5_2:format(Common.getKeyName(Tags.KEYCODE_CONFIRM))
    elseif index == 6 then
        return ITEM_6_1, ITEM_6_2:format(Common.getKeyName(Tags.KEYCODE_KEYWORDS))
    elseif index == 7 then
        return UPGRADE_1:format(Common.getKeyName(Tags.KEYCODE_UP), Common.getKeyName(Tags.KEYCODE_DOWN)), UPGRADE_2:format(Common.getKeyName(Tags.KEYCODE_CONFIRM))
    end

end

function TUTORIAL.getHealthOrbLines(index)
            if index == 1 then
        return HEALTH_ORB_1, HEALTH_ORB_2
    elseif index == 2 then
        return HEALTH_ORB_ELITE_1, HEALTH_ORB_ELITE_2
    elseif index == 3 then
        return SCRAP_ENOUGH_1, SCRAP_ENOUGH_2:format(Common.getKeyName(Tags.KEYCODE_EQUIPMENT))
    end

end

return TUTORIAL

