local TileMap = class("services.service")
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local SparseGrid = require("utils.classes.sparse_grid")
local MEASURES = require("draw.measures")
local TILE_SIZE = MEASURES.TILE_SIZE
local TS2, TS4 = TILE_SIZE / 2, TILE_SIZE / 4
local MAX_TILES = floor(graphics.getSystemLimits().texturesize / (4 * TILE_SIZE))
function TileMap:initialize(level)
    TileMap:super(self, "initialize")
    self:setDependencies("level", "coordinates")
    self.variantRNG = Utils.createRandomGenerator()
    self.canvases = SparseGrid:new(false)
end

function TileMap:drawCanvases()
    local width, height = self.services.level:getDimensions()
    local canvasCols = max(ceil(width / MAX_TILES), 3)
    local canvasRows = max(ceil(height / MAX_TILES), 2)
    local canvasWidth = ceil(width / canvasCols)
    local canvasHeight = ceil(height / canvasRows)
    for iv in Utils.gridIteratorV(1, canvasCols, 1, canvasRows) do
        local starting = (iv - Vector.UNIT_XY) * Vector:new(canvasWidth, canvasHeight) + Vector.UNIT_XY
        local actualWidth, actualHeight = canvasWidth, canvasHeight
        if iv.x == canvasCols then
            actualWidth = width - (canvasCols - 1) * canvasWidth
        end

        if iv.y == canvasRows then
            actualHeight = height - (canvasRows - 1) * canvasHeight
        end

        local canvas
        if self.canvases:hasValue(iv) then
            canvas = self.canvases:get(iv)
        else
            canvas = graphics.newCanvas(actualWidth * TILE_SIZE, actualHeight * TILE_SIZE)
        end

        self:drawCanvas(canvas, starting, actualWidth, actualHeight)
        self.canvases:set(starting, canvas)
    end

end

function TileMap:drawCanvas(canvas, starting, width, height)
    graphics.setCanvas(canvas)
    graphics.clear(0, 0, 0, 0)
    graphics.push()
    graphics.origin()
    for position in Utils.gridIteratorV(starting.x, starting.x + width - 1, starting.y, starting.y + height - 1) do
        self:drawAtPosition(position, starting)
    end

    graphics.pop()
    graphics.setCanvas()
end

local function shouldMerge(tile1, tile2)
    if not tile1 or not tile2 then
        return true
    end

    return tile1 == tile2
end

function TileMap:drawAtPosition(position, starting)
    local grid = self.services.level.tiles
    local tile = grid:get(position)
    if not tile then
        return 
    end

    if not tile.image then
        return 
    end

    local imageFile = "tiles/" .. tile.image
    local image, quad = Utils.loadImage(imageFile), Utils.loadQuad(imageFile)
    graphics.wSetColor(WHITE)
    if tile.mergeType == Tags.MERGE_TYPE_SINGLE then
        local width, height = image:getDimensions()
        local cx = self.variantRNG:random(0, floor(width / TILE_SIZE) - 1) * TILE_SIZE
        local cy = self.variantRNG:random(0, floor(height / TILE_SIZE) - 1) * TILE_SIZE
        quad:setViewport(cx, cy, TILE_SIZE, TILE_SIZE)
        graphics.draw(image, quad, ((position - starting) * TILE_SIZE):expand())
    else
        for iv in Utils.gridIteratorV(0, 1, 0, 1) do
            local ov = iv * 2 - Vector.UNIT_XY
                                    if not shouldMerge(tile, grid:get(position + ov:xPart())) then
                if not shouldMerge(tile, grid:get(position + ov:yPart())) then
                    quad:setViewport(iv.x * 3 * TS2, (2 + 3 * iv.y) * TS2, TS2, TS2)
                else
                    quad:setViewport(iv.x * 3 * TS2, (3 + iv.y) * TS2, TS2, TS2)
                end

            elseif not shouldMerge(tile, grid:get(position + ov:yPart())) then
                quad:setViewport((1 + iv.x) * TS2, (2 + 3 * iv.y) * TS2, TS2, TS2)
            elseif not shouldMerge(tile, grid:get(position + ov)) then
                quad:setViewport((2 + iv.x) * TS2, iv.y * TS2, TS2, TS2)
            else
                quad:setViewport((1 + iv.x) * TS2, (3 + iv.y) * TS2, TS2, TS2)
            end

            graphics.draw(image, quad, ((position - starting) * TILE_SIZE + iv * TS2):expand())
        end

    end

    local aboveData = grid:get(position + Vector[UP], false)
    if aboveData and aboveData.isBlocking and not tile.isBlocking then
        local shadowImage = Utils.loadImage("tiles/shadow")
        local shadowQuad = Utils.loadQuad("tiles/shadow")
        local shadow = 2
        shadowQuad:setViewport((shadow - 1) * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
        graphics.draw(shadowImage, shadowQuad, ((position - starting) * TILE_SIZE):expand())
    end

end

function TileMap:draw()
    Debugger.startBenchmark("CANV")
    for starting, canvas in self.canvases() do
        Debugger.drawText(starting)
        local screenPosition = self.services.coordinates:gridToScreen(starting)
        graphics.wSetColor(WHITE)
        graphics.draw(canvas, screenPosition:expand())
    end

    Debugger.stopBenchmark("CANV")
end

return TileMap

