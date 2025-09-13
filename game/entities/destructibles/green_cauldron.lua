local ACTIONS_COMMON = require("actions.common")
local LogicMethods = require("logic.methods")
local BASE_DAMAGE = 40
local POISON_DURATION = 4
local DEATH = class(ACTIONS_COMMON.CAULDRON_DEATH)
function DEATH:affectPosition(anchor, target)
    self.entity.acidspit:applyToPosition(anchor, target)
end

return function(entity, position, currentFloor)
    require("entities.common_destructible")(entity, position, currentFloor)
    entity.sprite:setCell(8, 10)
    entity.stats:set(Tags.STAT_MAX_HEALTH, 1)
    local damage = LogicMethods.getFloorDependentValue(currentFloor, BASE_DAMAGE)
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MIN, damage)
    entity.stats:set(Tags.STAT_ABILITY_DAMAGE_MAX, damage)
    entity.tank.deathActionClass = DEATH
    entity.tank:restoreToFull()
    entity:addComponent("acidspit")
    entity.acidspit.poisonDuration = POISON_DURATION
    entity:addComponent("hitter")
    entity:addComponent("label", "Acid Cauldron")
end

