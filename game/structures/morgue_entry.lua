local MorgueEntry = class()
local Vector = require("utils.classes.vector")
local Entity = require("entities.entity")
local Item = require("structures.item")
local ConvertNumber = require("utils.algorithms.convert_number")
local COLORS = require("draw.colors")
local CONSTANTS = require("logic.constants")
local function findColorString(color, default)
    for k, v in COLORS.TEXT_COLOR_PALETTE() do
        if v == color then
            return k
        end

    end

    return default or "NORMAL"
end

local function getEnderText(ender)
        if Item:isInstance(ender) then
        return ("{B:%s}%s"):format(findColorString(ender.labelColor), ender.name)
    elseif ender and ender:hasComponent("label") then
        local result = ""
        local article, label = ender.label:getWithArticle()
        if article then
            result = result .. article .. " "
        end

        local color = findColorString(ender.sprite.strokeColor, "NORMAL_ENEMY")
        result = result .. "{B:" .. color .. "}" .. label
        return result
    else
        return "Unknown"
    end

end

function MorgueEntry:initialize(entity, ender, currentRun)
    if Entity:isInstance(entity) then
        self.characterName = entity.equipment:getClassName()
        self.enderName = getEnderText(ender)
        self.spriteCell = entity.sprite.cell
        if Item:isInstance(ender) then
            self.victoryPrize = ender.definition.saveKey
        else
            self.victoryPrize = false
        end

        self.lastFloor = currentRun.currentFloor
        self.endTime = os.time()
        self.netWorth = entity.equipment:getTotalSellCost() + floor(entity.wallet:get() * CONSTANTS.SCRAP_SPENT_SELL_RATIO)
        self.difficulty = currentRun.difficulty
        if entity.sprite.strokeColor:size() > 0 then
            self.strokeColor = findColorString(entity.sprite.strokeColor:first())
        else
            self.strokeColor = false
        end

    else
        local data = entity
        self.characterName = data.characterName
        self.enderName = data.enderName
        self.spriteCell = Vector:new(data.spriteCellX, data.spriteCellY)
        self.victoryPrize = data.victoryPrize
        self.lastFloor = data.lastFloor
        self.endTime = data.endTime
        self.netWorth = data.netWorth
        self.difficulty = data.difficulty
    end

end

function MorgueEntry:getScore()
    local score = self.netWorth + self.lastFloor * 20
    if self.victoryPrize then
        score = score + 500
    end

    score = score * 150 / 175
    score = round(score * (1500 + (self.difficulty - Tags.DIFFICULTY_NORMAL) * 500) / 1500)
    return score
end

local FLOOR_FORMAT = "%d%s"
function MorgueEntry:getOrdinalFloor()
    return FLOOR_FORMAT:format(self.lastFloor, ConvertNumber.getOrdinalSuffix(self.lastFloor))
end

function MorgueEntry:toData()
    return { characterName = self.characterName, enderName = self.enderName, spriteCellX = self.spriteCell.x, spriteCellY = self.spriteCell.y, victoryPrize = self.victoryPrize, lastFloor = self.lastFloor, endTime = self.endTime, netWorth = self.netWorth, difficulty = self.difficulty }
end

return MorgueEntry

