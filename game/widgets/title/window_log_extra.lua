local WindowLogExtra = class("widgets.window")
local Array = require("utils.classes.array")
local MEASURES = require("draw.measures")
local FONT = require("draw.fonts").MEDIUM
local COLORS = require("draw.colors")
local StatRow = struct("name", "statKey")
local STAT_ROWS = Array:new(StatRow:new("Highest level (normal)", "highestLevelNormal"), StatRow:new("Highest level (legendary)", "highestLevelLegendary"), StatRow:new("Kills (while equipped)", "kills"), StatRow:new("Stairs entered", "stairs"), StatRow:new("Deaths", "deaths"), StatRow:new("Wins", "wins"), StatRow:new("Times casted ability", "timesCastedAbility"))
local function findColorString(color)
    for k, v in COLORS.TEXT_COLOR_PALETTE() do
        if v == color then
            if k == "NORMAL" then
                return "UPGRADED"
            end

            return k
        end

    end

    return "NORMAL"
end

function WindowLogExtra:initialize(director, item, parentWindow, itemWindow, isDiscovered, itemStats)
    self.itemStats = itemStats
    WindowLogExtra:super(self, "initialize", MEASURES.WIDTH_ITEM_WINDOW)
    self.itemWindow = itemWindow
    self.parentWindow = parentWindow
    self.alignment = CENTER
    self.isVisible = function(self)
        return self.parentWindow:evaluateIsVisible()
    end
    local textX = MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL + 1
    self.upgradeText = false
    if isDiscovered then
        local currentY = textX
        for row in STAT_ROWS() do
                        if row == STAT_ROWS[2] and item:getSlot() == Tags.SLOT_AMULET then
            elseif row ~= STAT_ROWS:last() or item.stats:hasKey(Tags.STAT_ABILITY_COOLDOWN) then
                self:addElement("text", textX, currentY, row.name, FONT, COLORS.NORMAL)
                local statText, color = itemStats:getStatString(row.statKey)
                local stat = self:addElement("text", self.window.rect.width - textX, currentY, itemStats:getStatString(row.statKey), FONT, COLORS.TEXT_COLOR_PALETTE:get(color))
                stat.alignment = UP_RIGHT
                currentY = currentY + FONT.height + MEASURES.MARGIN_INTERNAL + 1
            end

        end

    end

end

function WindowLogExtra:update(dt, serviceViewport)
    WindowLogExtra:super(self, "update", dt, serviceViewport)
    self.alignWidth = self.window.rect.width * 2 - self.parentWindow.alignWidth
    local margin = self.parentWindow:getMidMargin(serviceViewport) - 1
    self.window.rect.height = (self.parentWindow.window.rect.height - self.itemWindow.window.rect.height - margin)
    self.alignHeight = self.window.rect.height - self.itemWindow.window.rect.height - margin
    if self.upgradeText then
        self.upgradeText:setY((self.window.rect.height - FONT.height) / 2)
    end

end

return WindowLogExtra

