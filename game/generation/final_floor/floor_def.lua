local FinalFloorDef = class("generation.floor_def")
local LayoutExcavator = require("generation.layout_excavator")
local addPermanents = require("generation.final_floor.add_permanents")
local addObjects = require("generation.final_floor.add_objects")
function FinalFloorDef:initialize(floorLevel, data)
    FinalFloorDef:super(self, "initialize", floorLevel, data)
    self.excavatorClass = LayoutExcavator
end

function FinalFloorDef:addDecorators()
    self.decoratorsAlways:push(addPermanents)
    self.decoratorsOnCreate:push(addObjects)
end

function FinalFloorDef:configureGenerateCommand(command, isLoaded)
    self:setTiles(command)
    command.currentFloor = self.floorLevel
    command.excavator = self.excavatorClass:new()
    command.excavator:loadFromFilename("definitions/final_floor_layout.txt")
    local lw, lh = command.excavator:getLayoutDimensions()
    if isLoaded then
        command.decorators = self.decoratorsAlways
    else
        command.decorators = self.decoratorsAlways + self.decoratorsOnCreate
    end

    command.initialWidth = lw + command.padding * 2
    command.initialHeight = lh + command.padding * 2
end

return FinalFloorDef

