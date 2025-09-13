local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local RollTable = require("utils.classes.roll_table")
local ObjectGroupDef = require("structures.object_group_def")
local OBJECTS = RollTable:new()
OBJECTS:addResult(1, ObjectGroupDef:new { prefab = "pot", floors = Range:new(1, 25), width = Range:new(2, 3), height = 1, args = { Range:new(1, 4) } })
OBJECTS:addResult(1, ObjectGroupDef:new { prefab = "pot", floors = Range:new(1, 25), width = 1, height = 2, args = { Range:new(1, 4) } })
OBJECTS:addResult(1, ObjectGroupDef:new { prefab = "weapon_rack", floors = Range:new(1, 25), width = Range:new(2, 3), height = 1, args = { Range:new(1, 2) } })
OBJECTS:addResult(1, ObjectGroupDef:new { prefab = "bookshelf", floors = Range:new(5, 20), width = Range:new(2, 3), height = 1, args = { Range:new(1, 2) } })
return OBJECTS

