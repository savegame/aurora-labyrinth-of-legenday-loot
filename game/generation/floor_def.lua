local FloorDef = class()
local Range = require("utils.classes.range")
local Array = require("utils.classes.array")
local WideHallExcavator = require("generation.wide_hall_excavator")
local CrossRoomGenerator = require("generation.cross_room_generator")
local TILES = require("definitions.tiles")
local addStairs = require("generation.add_stairs")
local addWallTorches = require("generation.add_wall_torches")
local addObjects = require("generation.add_objects")
local addItems = require("generation.add_items")
local addInitialSpawn = require("generation.add_initial_spawn")
function FloorDef:initialize(floorLevel, data)
    self.floorLevel = floorLevel
    self.tileSource = data.tileSource
    if DebugOptions.GENERATE_ROOMS then
        self.roomCount = Range:new(DebugOptions.GENERATE_ROOMS, DebugOptions.GENERATE_ROOMS)
    else
        self.roomCount = data.roomCount
    end

    self.bgm = data.bgm
    self.roomWidthRange = false
    self.roomHeightRange = false
    self.stairs = data.stairs
    self.wallSize = 1
    self.excavatorClass = WideHallExcavator
    self.roomGeneratorClass = CrossRoomGenerator
    self.decoratorsAlways = Array:new()
    self.decoratorsOnCreate = Array:new()
    self:addDecorators()
end

function FloorDef:addDecorators()
    self.decoratorsAlways:push(addStairs)
    self.decoratorsAlways:push(addWallTorches)
    self.decoratorsOnCreate:push(addObjects)
    self.decoratorsOnCreate:push(addItems)
    self.decoratorsOnCreate:push(addInitialSpawn)
end

function FloorDef:setTiles(command)
    command.tileHall = self.tileSource.HALL
    command.tileRoom = self.tileSource.ROOM
    command.tileWall = self.tileSource.WALL
    command.tileDebug = TILES.DEBUG_1
end

function FloorDef:configureGenerateCommand(command, isLoaded)
    self:setTiles(command)
    command.currentFloor = self.floorLevel
    command.stairs = self.stairs
    command.excavator = self.excavatorClass:new()
    command.excavator.wallSize = self.wallSize
    command.excavator.roomCount = self.roomCount
    local roomGenerator = self.roomGeneratorClass:new()
    roomGenerator.widthRange = self.roomWidthRange
    roomGenerator.heightRange = self.roomHeightRange
    command.excavator.roomGenerator = roomGenerator
    if isLoaded then
        command.decorators = self.decoratorsAlways
    else
        command.decorators = self.decoratorsAlways + self.decoratorsOnCreate
    end

end

return FloorDef

