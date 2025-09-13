local KEYWORDS = {  }
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local Keyword = struct("name", "description")
local CONSTANTS = require("logic.constants")
KEYWORDS.LIST = Array:new()
KEYWORDS.LINK_TO_KEYWORD = Hash:new()
function KEYWORDS.add(name, matchingLinks, description)
    local entry = Keyword:new(name, description)
    for link in matchingLinks() do
        if KEYWORDS.LINK_TO_KEYWORD:hasKey(link) then
            local conflict = KEYWORDS.LINK_TO_KEYWORD:get(link)
            Utils.assert(false, "Link conflict: %s: %s & %s", link, conflict.name, name)
        end

        KEYWORDS.LINK_TO_KEYWORD:set(link, entry)
    end

    KEYWORDS.LIST:push(entry)
end

KEYWORDS.add("Attack", Array:new("Basic", "Attack", "Attacks"), "{C:KEYWORD}Attacks are strikes made with your weapon. " .. "It deals damage based on your {C:KEYWORD}Attack {C:KEYWORD}Damage stat. Whenever you " .. "press a directional button and an enemy or object is " .. "in the way, you {C:KEYWORD}Attack it. ")
KEYWORDS.add("Lunge", Array:new("Lunge"), "Whenever you move and there's an enemy in front after you move, " .. "{C:KEYWORD}Attack it. Abilities that let you do an " .. "{C:KEYWORD}Attack make you move one space forward first if possible.")
KEYWORDS.add("Reach", Array:new("Reach"), "If there's an enemy {C:NUMBER}2 spaces away from you in a direction, pressing that " .. "directional button will make you {C:KEYWORD}Attack that enemy. Some abilities that " .. "let you do an {C:KEYWORD}Attack will let you hit an enemy {C:NUMBER}2 spaces away.")
KEYWORDS.add("Projectile", Array:new("Projectile", "Projectiles"), "{C:KEYWORD}Projectiles do not travel instantly and can be avoided. " .. "{C:KEYWORD}Projectiles produced by your abilities normally travel {C:NUMBER}3 spaces every turn. Enemy {C:KEYWORD}Projectiles travel " .. "{C:NUMBER}2 spaces every turn.")
KEYWORDS.add("Range", Array:new(), "{C:KEYWORD}Range {C:NUMBER}X will affect the closest valid target at least " .. "{C:NUMBER}X spaces in a straight line away from you.")
KEYWORDS.add("Area", Array:new(), "Affects a certain amount of spaces roughly arranged in a circle. {FORCE_NEWLINE} " .. "{C:KEYWORD}Small {C:KEYWORD}Area - {C:NUMBER}5 spaces. All adjacent spaces to something is a {C:KEYWORD}Small {C:KEYWORD}Area centered on it. {FORCE_NEWLINE} " .. "{C:KEYWORD}Medium {C:KEYWORD}Area - {C:NUMBER}9 spaces. All spaces to around something is a {C:KEYWORD}Medium {C:KEYWORD}Area centered on it. {FORCE_NEWLINE} " .. "{C:KEYWORD}Large {C:KEYWORD}Area - {C:NUMBER}17 spaces. {FORCE_NEWLINE} " .. "{C:KEYWORD}Huge {C:KEYWORD}Area - {C:NUMBER}33 spaces.")
local PERIODIC_WARNING = " {FORCE_NEWLINE} Health loss is not considered as damage."
KEYWORDS.add("Cold", Array:new("Cold"), "Applying {C:KEYWORD}Cold to enemies will disable their movement. It will also cancel " .. "their {C:KEYWORD}Focused ability if it's a movement ability. {FORCE_NEWLINE} " .. "Losing health to {C:KEYWORD}Burn also reduces {C:KEYWORD}Cold duration by {C:NUMBER}1.")
KEYWORDS.add("Burn", Array:new("Burn"), "Abilities with {C:KEYWORD}Burn makes all affected spaces " .. "ignite for a certain duration. Enemies lose health whenever they step " .. "or end their turn on those spaces. It also reduces " .. "{C:KEYWORD}Cold duration by {C:NUMBER}1." .. PERIODIC_WARNING)
KEYWORDS.add("Quick", Array:new("Quick"), "{C:KEYWORD}Quick abilities do not end your turn when they are cast.")
KEYWORDS.add("Stun", Array:new("Stun", "Stunned", "Stunning"), "{C:KEYWORD}Stunned enemies cannot take any actions. {C:KEYWORD}Stunning enemies will " .. "cancel their {C:KEYWORD}Focused ability.")
KEYWORDS.add("Poison", Array:new("Poison", "Poisoned"), "{C:KEYWORD}Poisoned characters lose health every turn. {C:KEYWORD}Poison " .. "doesn't stack. If a {C:KEYWORD}Poisoned character gets {C:KEYWORD}Poisoned " .. "again the duration gets refreshed instead." .. PERIODIC_WARNING)
KEYWORDS.add("Chance", Array:new(), "{C:KEYWORD}Chance effects happen {C:NUMBER}1 out of " .. "{C:NUMBER}8 times. {C:KEYWORD}Chance effects for the same condition cannot happen at " .. "the same time.")
KEYWORDS.add("Focus", Array:new("Focus", "Focused", "Focusing"), "{C:KEYWORD}Focus abilities need {C:NUMBER}1 turn to prepare before it does its effects. " .. "You are considered {C:KEYWORD}Focusing during this preparation turn.")
KEYWORDS.add("Buff", Array:new("Buff"), "{C:KEYWORD}Buff {C:NUMBER}X provides a continuous effect that lasts {C:NUMBER}X turns. " .. "Can be canceled. Canceling is {C:KEYWORD}Quick.")
KEYWORDS.add("Sustain", Array:new("Sustain", "Sustaining"), "{C:KEYWORD}Sustain {C:NUMBER}X will do the specified effect " .. "at the end of your turn for {C:NUMBER}X turns. During sustain you cannot attack or cast any " .. "abilities except canceling ongoing {C:KEYWORD}Buffs and {C:KEYWORD}Sustains. You also cannot move unless the ability " .. "says so. {FORCE_NEWLINE} Canceling is {C:KEYWORD}Quick.")
KEYWORDS.add("Resist", Array:new("Resist"), "{C:KEYWORD}Resist {C:NUMBER}X reduces the damage taken by {C:NUMBER}X. Negative values " .. "increase the damage taken instead.")
KEYWORDS.add("Passive", Array:new("Passive"), "{C:KEYWORD}Passive provides a permanent effect as long as you are wearing the item.")
KEYWORDS.add("Autocast", Array:new("Autocast"), "{C:KEYWORD}Autocast {C:NUMBER}X automatically performs a certain effect as long as you " .. "fulfill its trigger condition. After which it goes on cooldown and cannot trigger again for {C:NUMBER}X turns.")
local kbBase, kbVar = CONSTANTS.KNOCKBACK_DAMAGE_BASE, CONSTANTS.KNOCKBACK_DAMAGE_VARIANCE
local kbMin, kbMax = round(kbBase * (1 - kbVar) - 0.001), round(kbBase * (1 + kbVar) + 0.001)
kbBase = kbBase * (1 + CONSTANTS.MAX_UPGRADE_INCREASE)
local kbMaxMin, kbMaxMax = round(kbBase * (1 - kbVar) - 0.001), round(kbBase * (1 + kbVar) + 0.001)
KEYWORDS.add("Push", Array:new("Push", "Pushing"), "Moves the target away from you. {C:KEYWORD}Pushing a target to an occupied space will " .. "deal damage to both the target and the occupied space. {FORCE_NEWLINE} That damage is based on the item's upgrade level: {FORCE_NEWLINE} " .. ("from {C:NUMBER}%s-%s damage at {C:NUMBER}+0 to {C:NUMBER}%s-%s at {C:NUMBER}+10."):format(kbMin, kbMax, kbMaxMin, kbMaxMax))
KEYWORDS.add("Health Orb", Array:new("Health Orb", "Health Orbs"), ("{C:KEYWORD}Health {C:KEYWORD}Orbs are red orbs that enemies sometimes drop whenever they die. {C:KEYWORD}Health {C:KEYWORD}Orbs restore {C:NUMBER}1/%d of your max health when"):format(round(1 / CONSTANTS.HEALTH_ORB_RESTORE)) .. " picked up. {C:KEYWORD}Elite enemies drop silver {C:KEYWORD}Health {C:KEYWORD}Orbs that also give scrap. Health Pedestals drop bigger {C:KEYWORD}Health {C:KEYWORD}Orbs that restore twice as much health.")
KEYWORDS.add("Elite", Array:new("Elite"), "Enemies with a border around them are {C:KEYWORD}Elite enemies. They are stronger than " .. "normal enemies and drop silver {C:KEYWORD}Health {C:KEYWORD}Orbs that give scrap.")
return KEYWORDS

