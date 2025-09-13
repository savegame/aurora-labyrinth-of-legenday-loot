local GenerateFloorCommand = class()
local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Hash = require("utils.classes.hash")
local GenerationLevel = require("generation.level")
local GUESS_WIDTH, GUESS_HEIGHT = 80, 60
local PADDING = 2
function GenerateFloorCommand:initialize()
    self.seed = false
    self.display = false
    self.yieldCallback = doNothing
    self.tileHall = false
    self.tileRoom = false
    self.tileWall = false
    self.tileDebug = false
    self.currentFloor = false
    self.level = false
    self.rooms = false
    self.difficulty = false
    self.unlockComplex = false
    self.stairs = false
    self.specialFields = Hash:new()
    self.initialWidth = GUESS_WIDTH
    self.initialHeight = GUESS_HEIGHT
    self.padding = PADDING
    self.excavator = false
    self.decorators = Array:new()
    self.rng = false
end

function GenerateFloorCommand:yield(...)
    self.yieldCallback(...)
end

function GenerateFloorCommand:yieldIfNotDisplay(...)
    if not self.display then
        self:yield(...)
    end

end

function GenerateFloorCommand:yieldIfDisplay(...)
    if self.display then
        self:yield(...)
    end

end

function GenerateFloorCommand:createLevel()
    self.level = GenerationLevel:new(self.tileWall, self.initialWidth, self.initialHeight)
    return self.level
end

function GenerateFloorCommand:generate()
    self.rng = Utils.createRandomGenerator(self.seed)
    self:yield()
    self.excavator:excavate(self)
    self.level:initializeObjects()
    self.level:saveHallPositions(self.tileHall)
    for decorator in self.decorators() do
        decorator(self)
    end

    return self.level
end

return GenerateFloorCommand

