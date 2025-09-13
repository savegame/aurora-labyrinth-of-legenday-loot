local Test = class("screens.screen")
local COLORS = require("draw.colors").ITEM_LABEL
local FONT = require("draw.fonts").MEDIUM
local DrawText = require("draw.text")
function Test:initialize()
    Test:super(self, "initialize")
end

local function drawText(currentY, text, color)
    graphics.wSetColor(color)
    DrawText.draw(text, 20, currentY)
    return currentY + 20
end

function Test:drawNonWidgets()
    graphics.wSetFont(FONT)
    local currentY = 20
    currentY = drawText(currentY, "Toxic Dagger", COLORS.NORMAL[1])
    currentY = drawText(currentY, "Agile Treads", COLORS.NORMAL[2])
    currentY = drawText(currentY, "Electrified Helm", COLORS.NORMAL[3])
    currentY = drawText(currentY, "Holy Breastplate of Corruption", COLORS.ENCHANTED[1])
    currentY = drawText(currentY, "Assault Bracers of Strength", COLORS.ENCHANTED[2])
    currentY = drawText(currentY, "Arcane Staff of Malice", COLORS.ENCHANTED[3])
    currentY = drawText(currentY, "Avarice", COLORS.LEGENDARY[2])
    currentY = drawText(currentY, "The Ultimatum", COLORS.LEGENDARY[3])
end

return Test

