local TILES = {  }
local Tile = struct("image", "mergeType", "isBlocking", "isRoom")
Tags.add("MERGE_TYPE_SINGLE")
Tags.add("MERGE_TYPE_MERGE")
TILES.CAVE = {  }
TILES.CAVE.HALL = Tile:new("cave_hall", Tags.MERGE_TYPE_SINGLE, false, false)
TILES.CAVE.ROOM = Tile:new("cave_room", Tags.MERGE_TYPE_SINGLE, false, true)
TILES.CAVE.WALL = Tile:new("cave_wall", Tags.MERGE_TYPE_MERGE, true)
TILES.DUNGEON_BLUE = {  }
TILES.DUNGEON_BLUE.HALL = Tile:new("dungeon_blue_hall", Tags.MERGE_TYPE_SINGLE, false, false)
TILES.DUNGEON_BLUE.ROOM = Tile:new("dungeon_blue_room", Tags.MERGE_TYPE_SINGLE, false, true)
TILES.DUNGEON_BLUE.WALL = Tile:new("dungeon_blue_wall", Tags.MERGE_TYPE_MERGE, true)
TILES.TEMPLE = {  }
TILES.TEMPLE.HALL = Tile:new("temple_hall", Tags.MERGE_TYPE_SINGLE, false, false)
TILES.TEMPLE.ROOM = Tile:new("temple_room", Tags.MERGE_TYPE_SINGLE, false, true)
TILES.TEMPLE.WALL = Tile:new("temple_wall", Tags.MERGE_TYPE_MERGE, true)
TILES.STONE = {  }
TILES.STONE.HALL = Tile:new("stone_hall", Tags.MERGE_TYPE_SINGLE, false, false)
TILES.STONE.ROOM = Tile:new("stone_room", Tags.MERGE_TYPE_SINGLE, false, true)
TILES.STONE.WALL = Tile:new("stone_wall", Tags.MERGE_TYPE_MERGE, true)
TILES.HOUSE = {  }
TILES.HOUSE.HALL = Tile:new("house_hall", Tags.MERGE_TYPE_SINGLE, false, false)
TILES.HOUSE.ROOM = Tile:new("house_room", Tags.MERGE_TYPE_SINGLE, false, true)
TILES.HOUSE.WALL = Tile:new("house_wall", Tags.MERGE_TYPE_MERGE, true)
TILES.DUNGEON_LIGHT = {  }
TILES.DUNGEON_LIGHT.HALL = Tile:new("dungeon_light_hall", Tags.MERGE_TYPE_SINGLE, false, false)
TILES.DUNGEON_LIGHT.ROOM = Tile:new("dungeon_light_room", Tags.MERGE_TYPE_SINGLE, false, true)
TILES.DUNGEON_LIGHT.WALL = Tile:new("dungeon_light_wall", Tags.MERGE_TYPE_MERGE, true)
TILES.FINAL = {  }
TILES.FINAL.HALL = Tile:new("final_hall", Tags.MERGE_TYPE_SINGLE, false, false)
TILES.FINAL.ROOM = Tile:new("final_room", Tags.MERGE_TYPE_SINGLE, false, true)
TILES.FINAL.WALL = Tile:new("final_wall", Tags.MERGE_TYPE_MERGE, true)
TILES.DEBUG_1 = Tile:new("debug_1", Tags.MERGE_TYPE_SINGLE, false)
return TILES

