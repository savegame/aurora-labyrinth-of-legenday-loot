local LoadingAnimation = class()
local Vector = require("utils.classes.vector")
local DrawCommand = require("utils.love2d.draw_command")
local Common = require("common")
local MEASURES = require("draw.measures")
local ITEM_SIZE = MEASURES.ITEM_SIZE
local ITEMS = require("definitions.items")
local WEAPON_COUNT = 5
local ROTATION_SPEED = 0.4
local DISTANCE = 6
local ITEM_ORIGIN = Vector:new(-DISTANCE, ITEM_SIZE + DISTANCE)
function LoadingAnimation:initialize()
    local weapons = ITEMS.BY_SLOT[Tags.SLOT_WEAPON]:getResults()
    local rng = Common.getMinorRNG()
    self.weapons = weapons:nDistinctRandom(5, rng):map(function(weapon)
        return weapon.icon
    end)
    if DebugOptions.HIDE_LOADING then
        self.weapons:clear()
    end

    self.angle = rng:random() * math.tau
    self.drawCommand = DrawCommand:new("items")
    self.drawCommand:setRectFromDimensions(ITEM_SIZE, ITEM_SIZE)
    self.drawCommand.origin = ITEM_ORIGIN
end

function LoadingAnimation:update(dt)
    local rotation = min(ROTATION_SPEED * math.tau * dt, math.tau / WEAPON_COUNT / 2)
    self.angle = (self.angle + rotation) % math.tau
end

function LoadingAnimation:draw(viewport)
    local scW, scH = viewport:getScreenDimensions()
    local offset = DISTANCE + ITEM_SIZE * math.sqrtOf2 + MEASURES.MARGIN_SCREEN
    local center = Vector:new(scW - offset, scH - offset)
    for i, weapon in ipairs(self.weapons) do
        self.drawCommand:setCell(weapon)
        self.drawCommand.angle = self.angle + math.tau * (i - 1) / WEAPON_COUNT
        self.drawCommand.position = center
        self.drawCommand:draw()
    end

end

return LoadingAnimation

