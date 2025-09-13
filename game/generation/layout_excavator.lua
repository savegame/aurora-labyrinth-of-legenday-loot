local LayoutExcavator = class()
local Common = require("common")
local SparseGrid = require("utils.classes.sparse_grid")
local Vector = require("utils.classes.vector")
function LayoutExcavator:initialize()
    self.padding = false
    self.layout = false
    self.objects = false
    self.startPosition = false
    self.startDirection = false
end

local BYTE_ZERO = ("0"):byte(1)
local BYTE_A = ("a"):byte(1)
local BYTE_Z = ("z"):byte(1)
local BYTE_PERCENT = ("%"):byte(1)
local BYTE_AT = ("@"):byte(1)
local BYTE_DOLLAR = ("$"):byte(1)
function LayoutExcavator:loadFromFilename(filename)
    local contents = filesystem.read(filename)
    local splitted = contents:split("%s")
    while not splitted:isEmpty() and #(splitted:last()) <= 0 do
        splitted:pop()
    end

    self.layout = SparseGrid:new(0, #(splitted[1]), splitted:size())
    self.objects = SparseGrid:new(false, self.layout.width, self.layout.height)
    for iy, line in ipairs(splitted) do
        for ix = 1, #(line) do
            local value = line:byte(ix)
            local position = Vector:new(ix, iy)
                                    if within(value, BYTE_A, BYTE_Z) then
                self.objects:set(position, line:sub(ix, ix))
                value = 1
            elseif value == BYTE_AT or value == BYTE_DOLLAR then
                if (DebugOptions.ENABLED and value == BYTE_DOLLAR) or (not DebugOptions.ENABLED and value == BYTE_AT) then
                    self.startPosition = position
                    self.startDirection = Common.getDirectionTowards(position, Vector:new((self.layout.width + 1) / 2, (self.layout.height + 1) / 2))
                end

                value = 1
            elseif value == BYTE_PERCENT then
                self.objects:set(position, "%")
                value = 0
            else
                value = value - BYTE_ZERO
            end

            if value ~= 0 then
                self.layout:set(Vector:new(ix, iy), value)
            end

        end

    end

end

function LayoutExcavator:getLayoutDimensions()
    return self.layout:getDimensions()
end

function LayoutExcavator:excavate(command)
    local width, height = command.level:getDimensions()
    local offset = Vector:new(command.padding, command.padding)
    local tiles = command.level.tiles
    for position, value in self.layout() do
                if value == 1 then
            tiles:set(position + offset, command.tileRoom)
        elseif value == 2 then
            tiles:set(position + offset, command.tileHall)
        end

    end

    command:yield()
    self.objects = self.objects:pad(command.padding, false)
    command.level.objectPositions = self.objects
    if self.startPosition then
        command.level.startPosition = self.startPosition + offset
    end

    if self.startDirection then
        command.level.startDirection = self.startDirection
    end

end

return LayoutExcavator

