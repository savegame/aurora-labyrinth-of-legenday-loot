local EntitySpawner = require("components.create_class")()
function EntitySpawner:initialize(entity)
    EntitySpawner:super(self, "initialize", entity)
    self.enemyDifficulty = false
end

function EntitySpawner:spawnEnemy(enemyName, position, direction, orbChance)
    return self.system.services.createEntity("enemies." .. enemyName, position, direction, enemyName, self.enemyDifficulty, false, orbChance)
end

function EntitySpawner:spawn(entityName,...)
    return self.system.services.createEntity(entityName, ...)
end

function EntitySpawner.System:initialize()
    EntitySpawner.System:super(self, "initialize")
    self:setDependencies("createEntity")
end

return EntitySpawner

