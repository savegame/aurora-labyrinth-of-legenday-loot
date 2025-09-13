local TutorialFloorDef = class("generation.floor_def")
local LayoutExcavator = require("generation.layout_excavator")
local addObjects = require("generation.tutorial.add_objects")
function TutorialFloorDef:initialize(floorLevel, data)
    TutorialFloorDef:super(self, "initialize", floorLevel, data)
    self.excavatorClass = LayoutExcavator
end

function TutorialFloorDef:addDecorators()
    self.decoratorsAlways:push(addObjects)
end

function TutorialFloorDef:configureGenerateCommand(command)
    self:setTiles(command)
    command.stairs = self.stairs
    command.excavator = self.excavatorClass:new()
    command.excavator:loadFromFilename("definitions/tutorial_floor_layout.txt")
    local lw, lh = command.excavator:getLayoutDimensions()
    command.decorators = self.decoratorsAlways
    command.initialWidth = lw + command.padding * 2
    command.initialHeight = lh + command.padding * 2
end

return TutorialFloorDef

