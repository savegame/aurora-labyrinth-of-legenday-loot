local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local CONSTANTS = require("logic.constants")
local EnemyDef = require("structures.enemy_def")
local ENEMIES_TABLE = { rat = { minFloor = -1, health = 0.9, damage = 1, frequency = 1.5 }, goblin = { minFloor = 0, health = 0.9, damage = 1, bannedElites = Array:new("KNOCKBACK") }, slime = { minFloor = 1, health = 0.22, damage = 0.85, count = 2, ability = 1.7 }, wolf = { minFloor = 2, health = 1, damage = 1, ability = 1.7 }, bear = { minFloor = 3, health = 1.1, damage = 0.9, ability = 1.7 }, skeleton_archer = { minFloor = 4, health = 0.8, damage = 1.1, bannedElites = Array:new("CHILLING", "KNOCKBACK", "HASTE") }, gelatinous_cube = { minFloor = 5, health = 0.8, damage = 0.9, bannedElites = Array:new("UNDYING") }, spider = { minFloor = 6, health = 0.9, damage = 1.1, ability = 1.7 }, cyclops = { minFloor = 7, health = 1.5, damage = 1.4 }, lightning_mage = { minFloor = 8, health = 0.8, damage = 0.8, ability = 2.4, bannedElites = Array:new("CHILLING", "KNOCKBACK", "HASTE") }, lizardman = { minFloor = 9, health = 0.4, damage = 0.8, count = 2 }, fire_cube = { minFloor = 10, health = 1.1, damage = 0.9, ability = 1.7, bannedElites = Array:new("UNDYING", "KNOCKBACK") }, snake = { minFloor = 11, health = 0.9, damage = 1.1, ability = 1.7, bannedElites = Array:new("POISONOUS") }, werewolf = { minFloor = 12, health = 1, damage = 1, ability = 1.7 }, zombie = { minFloor = 13, health = 0.45, damage = 0.8, count = 2 }, fire_mage = { minFloor = 14, health = 0.8, damage = 1.1, ability = 1.7, bannedElites = Array:new("CHILLING", "KNOCKBACK", "HASTE") }, golem = { minFloor = 15, health = 1.5, damage = 1.4, ability = 1.7, bannedElites = Array:new("KNOCKBACK") }, minotaur = { minFloor = 16, health = 1.2, damage = 0.9, ability = 1.7, bannedElites = Array:new("KNOCKBACK") }, goblin_rogue = { minFloor = 17, health = 0.4, damage = 0.8, count = 2, ability = 1.7, bannedElites = Array:new("CHILLING") }, drow_archer = { minFloor = 18, health = 0.8, damage = 1.1, ability = 1.7, bannedElites = Array:new("CHILLING", "KNOCKBACK", "HASTE") }, void_knight = { minFloor = 19, health = 1.0, damage = 1.0, ability = 1.7 }, green_dragon = { minFloor = 20, health = 1.1, damage = 0.9, ability = 1.7, bannedElites = Array:new("POISONOUS") }, magma_elemental = { minFloor = 21, health = 0.45 * 0.98, damage = 0.8 * 0.98, count = 2, ability = 1.7, bannedElites = Array:new("UNDYING") }, dark_mage = { minFloor = 22, health = 0.8 * 0.96, damage = 1.1 * 0.96, ability = 1.7, bannedElites = Array:new("CHILLING", "KNOCKBACK") }, yeti = { minFloor = 23, health = 1.5 * 0.94, damage = 1.4 * 0.94, bannedElites = Array:new("HASTE") }, magma_archer = { minFloor = 25, health = 0.7, damage = 1.05, ability = 1.7 }, magma_goblin = { minFloor = 25, health = 0.33, damage = 0.8, count = 2 }, purple_dragon = { minFloor = 25, health = 1, damage = 0.85, ability = 1.7 }, final_boss = { minFloor = 25, health = 6.75, damage = 0.95, ability = 1.7 } }
local ENEMIES = {  }
local LIST = Array:new()
local ASSERT_ZERO_FREQUENCY = "Can't increase frequency of enemy with zero frequency: %s"
for id, data in pairs(ENEMIES_TABLE) do
    local enemyDef = EnemyDef:new(id, data)
    ENEMIES[id] = enemyDef
    if id == DebugOptions.MAKE_ENEMY_FREQUENT_AND_IN_FLOOR then
        Utils.assert(enemyDef.frequency > 0, ASSERT_ZERO_FREQUENCY, id)
        enemyDef.minFloor = DebugOptions.STARTING_FLOOR
        enemyDef.frequency = 100
    end

    LIST:push(enemyDef)
end

LIST:stableSortSelf(function(a, b)
    return a.minFloor < b.minFloor
end)
if DebugOptions.REPORT_ENEMY_STATS then
    for enemyDef in LIST() do
        local stats = enemyDef.stats
        Debugger.log(("%17s  %4d   %2d-%2d    %2d-%2d"):format(enemyDef.id, stats:get(Tags.STAT_MAX_HEALTH), stats:get(Tags.STAT_ATTACK_DAMAGE_MIN), stats:get(Tags.STAT_ATTACK_DAMAGE_MAX), stats:get(Tags.STAT_ABILITY_DAMAGE_MIN, 0), stats:get(Tags.STAT_ABILITY_DAMAGE_MAX, 0)))
    end

end

ENEMIES.LIST = LIST
return ENEMIES

