local PLACEHOLDER = ""
local LORE_AMULET_VICTORY = {  }
setmetatable(LORE_AMULET_VICTORY, { __index = function()
    return PLACEHOLDER
end })
LORE_AMULET_VICTORY["amulets.berserker"] = "The amulet grants you unlimited strength, and unlimited anger."
LORE_AMULET_VICTORY["amulets.cryomancer"] = "The amulet grants you the power to extinguish the sun."
LORE_AMULET_VICTORY["amulets.cultist"] = "The amulet grants you the power bring forth the abyss into the world, consuming everything gruesomely."
LORE_AMULET_VICTORY["amulets.firebrand"] = "The amulet grants you the power to call down big fiery rocks anywhere."
LORE_AMULET_VICTORY["amulets.gladiator"] = "The amulet grants you the power to defeat entire armies all by yourself."
LORE_AMULET_VICTORY["amulets.hunter"] = "The amulet grants you the power to see everything in the entire world at once. Absolutely everything."
LORE_AMULET_VICTORY["amulets.invoker"] = "The amulet grants you the power to smite all of the sinners of the world, excluding yourself."
LORE_AMULET_VICTORY["amulets.monk"] = "The amulet grants you the power to calm powerful thunderstorms and angry shopkeepers."
LORE_AMULET_VICTORY["amulets.nomad"] = "The amulet grants you the power to twist the threads of fate."
LORE_AMULET_VICTORY["amulets.paladin"] = "The amulet grants you the power to inflict justice onto people you dislike."
LORE_AMULET_VICTORY["amulets.psion"] = "The amulet grants you absolute power over space and time."
LORE_AMULET_VICTORY["amulets.revenant"] = "The amulet grants you power over life and death, mostly death."
LORE_AMULET_VICTORY["amulets.rogue"] = "The amulet grants you the power to cause death on anyone you desire simply by whispering their name."
LORE_AMULET_VICTORY["amulets.shaman"] = "The amulet grants you the power to create storms, allowing you to ruin anyone's day."
LORE_AMULET_VICTORY["amulets.spellblade"] = "The amulet grants you knowledge of all spells in the world."
LORE_AMULET_VICTORY["amulets.templar"] = "The amulet grants you the power to command reality with just your words."
LORE_AMULET_VICTORY["amulets.warden"] = "The amulet renders you completely indestructible making it impossible for you to die, even if you wanted to."
LORE_AMULET_VICTORY["amulets.warlock"] = "The amulet fills you with the power and the desire to slay gods you've never even heard of before."
LORE_AMULET_VICTORY["amulets.warrior"] = "The amulet grants you the perfect warrior's form. Strong muscles, agile limbs and a chiseled jawline."
LORE_AMULET_VICTORY["amulets.witch"] = "The amulet grants you the power the bring forth horrible and disgusting plagues that can devastate the world."
if DebugOptions.ENABLED then
    local ITEMS = require("definitions.items")
    local MAX_FLOORS = require("logic.constants").MAX_FLOORS
    for itemDef in (ITEMS.BY_SLOT[Tags.SLOT_AMULET]:getResults())() do
        if LORE_AMULET_VICTORY[itemDef.saveKey] == PLACEHOLDER and itemDef.minFloor <= MAX_FLOORS then
            Debugger.warn("amulet victory description missing: " .. itemDef.saveKey)
            break
        end

    end

end

return LORE_AMULET_VICTORY

