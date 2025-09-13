local TestGeneration = class("screens.screen")
local GenerateFloorCommand = require("generation.generate_floor_command")
local generateSeed = require("generation.seed")
local FLOORS = require("definitions.floors")
require("structures.run")
function TestGeneration:initialize()
    TestGeneration:super(self, "initialize")
    local seed = DebugOptions.SEED or generateSeed()
    Debugger.log("SEED: ", seed)
    local generateCommand = GenerateFloorCommand:new()
    generateCommand.seed = seed
    generateCommand.yieldCallback = coroutine.yield
    generateCommand.display = true
    generateCommand.difficulty = Tags.DIFFICULTY_NORMAL
    local floorDef = FLOORS[DebugOptions.STARTING_FLOOR]
    floorDef:configureGenerateCommand(generateCommand)
    self:provideServiceDependency("level", generateCommand:createLevel())
    self.generateCoroutine = coroutine.create(generateCommand.generate)
    coroutine.resume(self.generateCoroutine, generateCommand)
    self:preloadService("generationdisplay")
end

function TestGeneration:update(dt)
    TestGeneration:super(self, "update", dt)
    if coroutine.status(self.generateCoroutine) ~= "dead" then
        Utils.assert(coroutine.resume(self.generateCoroutine))
    end

end

function TestGeneration:draw()
    TestGeneration:super(self, "draw", dt)
    self:getService("generationdisplay"):draw()
end

return TestGeneration

