local Vector = require("utils.classes.vector")
local TERMS = require("text.terms")
local BUFFS = require("definitions.buffs")
local ENEMIES = require("definitions.enemies")
local CONSTANTS = require("logic.constants")
local LogicMethods = require("logic.methods")
return function(entity, position, direction, id, difficulty, eliteID, forcedOrbChance)
    entity:addComponent("serializable", direction, id, difficulty, eliteID, forcedOrbChance)
    entity:addComponent("body", position)
    entity:addComponent("turn")
    entity:addComponent("sprite")
    entity.sprite:turnToDirection(direction)
    entity:addComponent("charactereffects")
    entity:addComponent("offset")
    entity:addComponent("stats")
    entity.stats:setFromHash(ENEMIES[id].stats)
    local multiplier = (1 + CONSTANTS.DIFFICULTY_HEALTH_DIFFERENCE * (difficulty - Tags.DIFFICULTY_NORMAL))
    entity.stats:multiply(Tags.STAT_MAX_HEALTH, (DebugOptions.NONPLAYER_HEALTH_MULTIPLIER * multiplier))
    if difficulty == Tags.DIFFICULTY_EASY then
        entity.stats:multiply(Tags.STAT_ATTACK_DAMAGE_MIN, CONSTANTS.EASY_DAMAGE_MULTIPLIER)
        entity.stats:multiply(Tags.STAT_ATTACK_DAMAGE_MAX, CONSTANTS.EASY_DAMAGE_MULTIPLIER)
        if entity.stats:has(Tags.STAT_ABILITY_DAMAGE_MIN) then
            entity.stats:multiply(Tags.STAT_ABILITY_DAMAGE_MAX, CONSTANTS.EASY_DAMAGE_MULTIPLIER)
            entity.stats:multiply(Tags.STAT_ABILITY_DAMAGE_MAX, CONSTANTS.EASY_DAMAGE_MULTIPLIER)
        end

    end

    entity:addComponent("buffable")
    entity:addComponent("tank")
        if eliteID then
        entity.tank.orbChance = 1
        entity.tank.scrapReward = LogicMethods.getEliteScrapReward(ENEMIES[id].minFloor, difficulty)
    elseif forcedOrbChance then
        entity.tank.orbChance = forcedOrbChance
    else
        entity.tank.orbChance = CONSTANTS.ENEMY_ORB_CHANCE
        if ENEMIES[id].count then
            entity.tank.orbChance = entity.tank.orbChance / ENEMIES[id].count
        end

    end

    if eliteID then
        entity:addComponent("elite", eliteID)
    end

    entity:addComponent("agent", id)
    entity:addComponent("indicator", "ENEMY")
    entity:addComponent("hitter")
    entity:addComponent("triggerlist")
    entity:addComponent("triggers")
    entity.triggers.source = entity.triggerlist
    entity:addComponent("label", TERMS.ENEMIES[id])
    entity:addComponent("actor")
end

