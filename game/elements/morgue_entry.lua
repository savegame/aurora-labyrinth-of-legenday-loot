local MorgueEntry = class("elements.element")
local Common = require("common")
local Rect = require("utils.classes.rect")
local FONT = require("draw.fonts").MEDIUM
local MEASURES = require("draw.measures")
local MARGIN = 4
local HEIGHT = MEASURES.TILE_SIZE + 2 + MARGIN * 2
local COLORS = require("draw.colors")
local DrawMethods = require("draw.methods")
local DrawCommand = require("utils.love2d.draw_command")
local DrawText = require("draw.text")
local ITEMS = require("definitions.items")
local TextSpecial = require("draw.text_special")
local spriteDrawCommand = DrawCommand:new("sprites_animated")
spriteDrawCommand:setRectFromDimensions(MEASURES.TILE_SIZE + 2, MEASURES.TILE_SIZE + 2)
local strokeDrawCommand = DrawCommand:new("sprites_stroke")
strokeDrawCommand:setRectFromDimensions(MEASURES.TILE_SIZE + 4, MEASURES.TILE_SIZE + 4)
local LABEL_FORMAT = "{C:%s}%s - %s on {C:NUMBER}%s"
local KILLED_FORMAT = "Killed by %s {B:NORMAL}on the {C:NUMBER}%s floor"
local WON_FORMAT = "Obtained the amulet %s"
local SCORE_FORMAT = "Score: {C:%s}%d"
function MorgueEntry:initialize(width, entry)
    MorgueEntry:super(self, "initialize")
    self.rect = Rect:new(0, 0, width, HEIGHT)
    self.entry = entry
    if entry then
        local dateString = os.date("%m/%d/%Y", entry.endTime)
        local label, enderText
        if entry.victoryPrize then
            label = LABEL_FORMAT:format("UPGRADED", entry.characterName, "won", dateString)
            enderText = WON_FORMAT:format(entry.enderName)
        else
            label = LABEL_FORMAT:format("DOWNGRADED", entry.characterName, "died", dateString)
            if entry.lastFloor == 0 then
                enderText = KILLED_FORMAT:format(entry.enderName, "Tutorial")
            else
                enderText = KILLED_FORMAT:format(entry.enderName, entry:getOrdinalFloor())
            end

        end

        self.textLabel = TextSpecial:new(FONT, label, false)
        self.textEnder = TextSpecial:new(FONT, enderText, false)
        self.textNetWorth = TextSpecial:new(FONT, SCORE_FORMAT:format("NUMBER", entry:getScore()), false)
        self.textDifficulty = false
        self.textDifficulty = TextSpecial:new(FONT, Common.getDifficultyText(entry.difficulty), false)
    end

end

function MorgueEntry:draw(serviceViewport, timePassed)
    graphics.wSetColor(COLORS.WINDOW_BORDER)
    DrawMethods.lineRect(self.rect)
    if self.entry then
        local cell = self.entry.spriteCell
        if self.entry.victoryPrize then
            local itemDef = ITEMS.BY_ID[self.entry.victoryPrize]
            strokeDrawCommand:setCell(cell.x, cell.y * 2 - 1 + Common.getSpriteFrame(timePassed))
            strokeDrawCommand.color = itemDef.legendaryMod.strokeColor
            strokeDrawCommand:draw(MARGIN - 1, MARGIN - 1)
            graphics.wSetColor(COLORS.WINDOW_BORDER)
        end

        graphics.wRectangle(1 + MARGIN * 2 + MEASURES.TILE_SIZE, 0, 1, self.rect.height)
        spriteDrawCommand:setCell(cell.x, cell.y * 2 - 1 + Common.getSpriteFrame(timePassed))
        spriteDrawCommand:draw(MARGIN, MARGIN)
        local textMargin = 1 + MARGIN + 2
        local textX = 1 + MARGIN * 2 + MEASURES.TILE_SIZE + textMargin
        self.textLabel:draw(serviceViewport, textX, textMargin)
        self.textEnder:draw(serviceViewport, textX, self.rect.height - textMargin - FONT.height)
        self.textNetWorth:draw(serviceViewport, self.rect.width - textMargin - self.textNetWorth:getTotalWidth(), textMargin)
        if self.textDifficulty then
            self.textDifficulty:draw(serviceViewport, self.rect.width - textMargin - self.textDifficulty:getTotalWidth(), self.rect.height - textMargin - FONT.height)
        end

    end

end

return MorgueEntry

