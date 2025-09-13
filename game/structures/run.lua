local Run = class()
local Array = require("utils.classes.array")
local Set = require("utils.classes.set")
local Hash = require("utils.classes.hash")
local Wrapper = require("utils.classes.wrapper")
local MessagePack = require("messagepack")
local LogicMethods = require("logic.methods")
local ItemCreateCommand = require("logic.item_create_command")
local ITEMS = require("definitions.items")
local SUFFIXES = require("definitions.suffixes")
local CONSTANTS = require("logic.constants")
local FILENAMES = require("text.filenames")
local LORE_OTHER = require("text.lore_other")
local Global = require("global")
local TUTORIAL_SEED = 285714
local MAX_FLOOR_SEED = 2 ^ 30
Tags.add("FLOOR_LEGENDARY", 1)
Tags.add("FLOOR_ANVIL", 2)
function Run:initialize()
    self.seed = false
    self.currentFloor = 1
    self.difficulty = Tags.DIFFICULTY_NORMAL
    self.floorSeeds = Array:new()
    self.legendaries = Hash:new()
    self.anvilFloors = Array:new()
    self.isFemale = false
    self.gameVersion = PortSettings.GAME_VERSION
end

function Run:createNew(difficulty, seed)
    self.seed = seed
    local rng = Utils.createRandomGenerator(self.seed)
    self:createFloorSeeds(rng)
    local profile = Global:get(Tags.GLOBAL_PROFILE)
    self.difficulty = difficulty
    if profile.character == Tags.CHARACTER_RANDOM then
        self.isFemale = rng:random() < 0.5
    else
        self.isFemale = (profile.character == Tags.CHARACTER_FEMALE)
    end

    self.currentFloor = DebugOptions.STARTING_FLOOR
    if profile.tutorialFrequency ~= Tags.TUTORIAL_FREQUENCY_NEVER then
        self.currentFloor = 0
    end

    LogicMethods.decideSpecialFloors(rng, self)
end

Tags.add("SAVE_FIELD_SEED", 1)
Tags.add("SAVE_FIELD_DIFFICULTY", 2)
Tags.add("SAVE_FIELD_IS_FEMALE", 3)
Tags.add("SAVE_FIELD_CURRENT_FLOOR", 4)
Tags.add("SAVE_FIELD_FLOOR_SEEDS", 5)
Tags.add("SAVE_FIELD_LEGENDARIES", 6)
Tags.add("SAVE_FIELD_ANVIL_FLOORS", 7)
Tags.add("SAVE_FIELD_RESTART_COUNT", 11)
Tags.add("SAVE_FIELD_ITEM", 12)
Tags.add("SAVE_FIELD_ITEM_LEVEL", 13)
Tags.add("SAVE_FIELD_ITEM_MODIFIER", 14)
Tags.add("SAVE_FIELD_ITEM_IS_LEGENDARY", 15)
Tags.add("SAVE_FIELD_ITEM_HAS_BEEN_UPGRADED", 16)
Tags.add("SAVE_FIELD_GAME_VERSION", 20)
function Run:loadFromFile()
    local data = filesystem.read("string", FILENAMES.CURRENT_RUN)
    data = MessagePack.unpack(data)
    self.seed = data[Tags.SAVE_FIELD_SEED]
    self.difficulty = data[Tags.SAVE_FIELD_DIFFICULTY]
    self.isFemale = data[Tags.SAVE_FIELD_IS_FEMALE]
    self.currentFloor = data[Tags.SAVE_FIELD_CURRENT_FLOOR]
    self.floorSeeds = Array:Convert(data[Tags.SAVE_FIELD_FLOOR_SEEDS])
    self.legendaries.container = data[Tags.SAVE_FIELD_LEGENDARIES]
    self.anvilFloors = Array:Convert(data[Tags.SAVE_FIELD_ANVIL_FLOORS])
    if data[Tags.SAVE_FIELD_GAME_VERSION] then
        self.gameVersion = data[Tags.SAVE_FIELD_GAME_VERSION]
    else
        self.gameVersion = 102
        if not rawget(self, "difficulty") then
            rawset(self, "difficulty", Tags.DIFFICULTY_NORMAL)
        end

    end

    print("GAME_VERSION", self.gameVersion)
end

function Run:save()
    self.anvilFloors:rejectSelf(function(value)
        return value < self.currentFloor
    end)
    self.legendaries:rejectEntriesSelf(function(key, value)
        return key < self.currentFloor
    end)
    self.gameVersion = PortSettings.GAME_VERSION
    local data = { [Tags.SAVE_FIELD_SEED] = self.seed, [Tags.SAVE_FIELD_DIFFICULTY] = self.difficulty, [Tags.SAVE_FIELD_IS_FEMALE] = self.isFemale, [Tags.SAVE_FIELD_CURRENT_FLOOR] = self.currentFloor, [Tags.SAVE_FIELD_FLOOR_SEEDS] = self.floorSeeds, [Tags.SAVE_FIELD_LEGENDARIES] = self.legendaries.container, [Tags.SAVE_FIELD_ANVIL_FLOORS] = self.anvilFloors, [Tags.SAVE_FIELD_GAME_VERSION] = self.gameVersion }
    data = MessagePack.pack(data)
    filesystem.write(FILENAMES.CURRENT_RUN, data)
end

function Run:createFloorSeeds(rng)
    self.floorSeeds:clear()
    for i = 1, CONSTANTS.MAX_FLOORS do
        self.floorSeeds:push(rng:random(1, MAX_FLOOR_SEED))
    end

end

function Run:setGenerateSpecialFields(generateCommand)
    if self.legendaries:hasKey(self.currentFloor) then
        generateCommand.specialFields:set(Tags.FLOOR_LEGENDARY, self.legendaries:get(self.currentFloor))
    end

    if self.anvilFloors:contains(self.currentFloor) then
        generateCommand.specialFields:set(Tags.FLOOR_ANVIL, 1)
    end

end

function Run:getCurrentFloorSeed()
    if self.currentFloor == 0 then
        return TUTORIAL_SEED
    else
        return self.floorSeeds[self.currentFloor]
    end

end

function Run:increaseFloor()
    self.currentFloor = self.currentFloor + 1
end

return Run

