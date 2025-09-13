local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Vector = require("utils.classes.vector")
local TILES = require("definitions.tiles")
local CONSTANTS = require("logic.constants")
local FloorDef = require("generation.floor_def")
local DEFAULT_ROOM_WIDTH_RANGE = Range:new(9, 10)
local DEFAULT_ROOM_HEIGHT_RANGE = Range:new(7, 8)
local FLOORS_TABLE = { [0] = { roomCount = Range:new(4, 5), tileSource = TILES.STONE, stairs = Vector:new(11, 8), floorDefClass = "tutorial.floor_def", bgm = "DUNGEON_1" }, [1] = { roomCount = Range:new(4, 5), tileSource = TILES.STONE, stairs = Vector:new(11, 8), bgm = "DUNGEON_1" }, [2] = { roomCount = Range:new(4, 5), tileSource = TILES.STONE, stairs = Vector:new(11, 8), bgm = "DUNGEON_1" }, [3] = { roomCount = Range:new(4, 5), tileSource = TILES.STONE, stairs = Vector:new(11, 8), bgm = "DUNGEON_1" }, [4] = { roomCount = Range:new(4, 5), tileSource = TILES.STONE, stairs = Vector:new(9, 9), bgm = "DUNGEON_1" }, [5] = { roomCount = Range:new(5, 6), tileSource = TILES.TEMPLE, stairs = Vector:new(9, 9), bgm = "DUNGEON_2" }, [6] = { roomCount = Range:new(5, 6), tileSource = TILES.TEMPLE, stairs = Vector:new(9, 9), bgm = "DUNGEON_2" }, [7] = { roomCount = Range:new(5, 6), tileSource = TILES.TEMPLE, stairs = Vector:new(9, 9), bgm = "DUNGEON_2" }, [8] = { roomCount = Range:new(5, 6), tileSource = TILES.TEMPLE, stairs = Vector:new(9, 10), bgm = "DUNGEON_2" }, [9] = { roomCount = Range:new(5, 6), tileSource = TILES.DUNGEON_LIGHT, stairs = Vector:new(9, 10), bgm = "DUNGEON_3" }, [10] = { roomCount = Range:new(5, 6), tileSource = TILES.DUNGEON_LIGHT, stairs = Vector:new(9, 10), bgm = "DUNGEON_3" }, [11] = { roomCount = Range:new(5, 6), tileSource = TILES.DUNGEON_LIGHT, stairs = Vector:new(9, 10), bgm = "DUNGEON_3" }, [12] = { roomCount = Range:new(5, 6), tileSource = TILES.DUNGEON_LIGHT, stairs = Vector:new(9, 8), bgm = "DUNGEON_3" }, [13] = { roomCount = Range:new(6, 7), tileSource = TILES.HOUSE, stairs = Vector:new(9, 8), bgm = "DUNGEON_4" }, [14] = { roomCount = Range:new(6, 7), tileSource = TILES.HOUSE, stairs = Vector:new(9, 8), bgm = "DUNGEON_4" }, [15] = { roomCount = Range:new(6, 7), tileSource = TILES.HOUSE, stairs = Vector:new(9, 8), bgm = "DUNGEON_4" }, [16] = { roomCount = Range:new(6, 7), tileSource = TILES.HOUSE, stairs = Vector:new(11, 4), bgm = "DUNGEON_4" }, [17] = { roomCount = Range:new(6, 7), tileSource = TILES.DUNGEON_BLUE, stairs = Vector:new(11, 4), bgm = "DUNGEON_5" }, [18] = { roomCount = Range:new(6, 7), tileSource = TILES.DUNGEON_BLUE, stairs = Vector:new(11, 4), bgm = "DUNGEON_5" }, [19] = { roomCount = Range:new(6, 7), tileSource = TILES.DUNGEON_BLUE, stairs = Vector:new(11, 4), bgm = "DUNGEON_5" }, [20] = { roomCount = Range:new(6, 7), tileSource = TILES.DUNGEON_BLUE, stairs = Vector:new(11, 10), bgm = "DUNGEON_5" }, [21] = { roomCount = Range:new(6, 7), tileSource = TILES.CAVE, stairs = Vector:new(11, 10), bgm = "DUNGEON_6" }, [22] = { roomCount = Range:new(6, 7), tileSource = TILES.CAVE, stairs = Vector:new(11, 10), bgm = "DUNGEON_6" }, [23] = { roomCount = Range:new(6, 7), tileSource = TILES.CAVE, stairs = Vector:new(11, 10), bgm = "DUNGEON_6" }, [24] = { roomCount = Range:new(6, 7), tileSource = TILES.CAVE, stairs = Vector:new(11, 10), bgm = "DUNGEON_6" }, [25] = { roomCount = Range:new(6, 7), tileSource = TILES.FINAL, stairs = Vector:new(11, 10), floorDefClass = "final_floor.floor_def", bgm = false } }
local FLOORS = {  }
for i = 0, CONSTANTS.MAX_FLOORS do
    local floorDef
    if FLOORS_TABLE[i].floorDefClass then
        floorDef = require("generation." .. FLOORS_TABLE[i].floorDefClass):new(i, FLOORS_TABLE[i])
    else
        floorDef = FloorDef:new(i, FLOORS_TABLE[i])
    end

    floorDef.roomWidthRange = DEFAULT_ROOM_WIDTH_RANGE
    floorDef.roomHeightRange = DEFAULT_ROOM_HEIGHT_RANGE
    if FLOORS_TABLE[i].decorator then
        floorDef = require("generation." .. FLOORS_TABLE[i].decorator)(floorDef) or floorDef
    end

    FLOORS[i] = floorDef
end

return FLOORS

