local WindowItem = class("widgets.window")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Rect = require("utils.classes.rect")
local ACTIONS_BASIC = require("actions.basic")
local TextItems = require("text.items")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local MEASURES = require("draw.measures")
local ABILITY_SIZE = MEASURES.ABILITY_SIZE
local WIDTH = MEASURES.WIDTH_ITEM_WINDOW
local COLORS = require("draw.colors")
local FONT = require("draw.fonts").MEDIUM
local SHADERS = require("draw.shaders")
local EQUIP_WAIT = require("actions.constants").EQUIP_DURATION
local DrawText = require("draw.text")
local AbilityIcon = require("elements.ability_icon")
local GAME_MENU_SIZE = require("elements.button_game_menu").SIZE
local ABILITY_MARGIN = 3
local ABILITY_TOP_HEIGHT = ABILITY_MARGIN * 2 + ABILITY_SIZE
local SPACE_STAT_LINE = (FONT.spaceLine + MEASURES.MARGIN_INTERNAL) / 2
local function onButtonClose(button, widget)
    widget.director:publish(Tags.UI_CLEAR, true)
    widget.director:publish(Tags.UI_TUTORIAL_CLEAR, true)
end

local function getAbilityCostText(item)
    local costText = ""
    local healthCost = item.stats:get(Tags.STAT_ABILITY_HEALTH_COST, 0)
    local cooldown = item.stats:get(Tags.STAT_ABILITY_COOLDOWN, 0)
    if item.stats:hasKey(Tags.STAT_ABILITY_MANA_COST) then
        costText = textStatFormat("Mana: %s", item, Tags.STAT_ABILITY_MANA_COST)
    end

    if item.stats:hasKey(Tags.STAT_ABILITY_HEALTH_COST) then
        if #costText > 0 then
            costText = costText .. " - "
        end

        costText = costText .. textStatFormat("Health: %s", item, Tags.STAT_ABILITY_HEALTH_COST)
    end

    if item.stats:hasKey(Tags.STAT_ABILITY_COOLDOWN) then
        if #costText > 0 then
            costText = costText .. " - "
        end

        costText = costText .. textStatFormat("Cooldown: %s", item, Tags.STAT_ABILITY_COOLDOWN)
    end

    if item.extraCostLine then
        costText = costText .. " - " .. item.extraCostLine
    end

    return costText
end

function WindowItem:initialize(director, item, itemEntity, forcedBlank)
    WindowItem:super(self, "initialize", WIDTH)
    self.item = item
    self._itemEntity = itemEntity
    self.director = director
    self.parentList = false
    self.alignSide = CENTER
    self.forcedBlank = forcedBlank or false
    local startingX = MEASURES.BORDER_WINDOW
    local currentY = self:addTitleBar(item)
    local textX = startingX + MEASURES.MARGIN_INTERNAL + 1
    currentY = self:addStatLines(currentY, item, textX)
    if not item:isLegendaryAmulet() then
        local passiveDescriptions = item:getPassiveDescription()
        if passiveDescriptions then
            if not Array:isInstance(passiveDescriptions) then
                passiveDescriptions = Array:new(passiveDescriptions)
            end

            local isNegative = item:isFirstPassiveNegative()
            for description in passiveDescriptions() do
                currentY = self:addPassiveDescription(currentY, description, startingX, textX, isNegative)
                isNegative = false
            end

        end

        if item:getAbility() then
            currentY = self:addAbilityElements(currentY, item, startingX, textX)
        end

        currentY = self:addExtraDescription(currentY, startingX, textX)
    end

    if not self.forcedBlank then
        self:addElement("divider", startingX, currentY, WIDTH - MEASURES.BORDER_WINDOW * 2)
    end

    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    currentY = self:createExtraElements(currentY, textX)
    self.window:setHeight(currentY)
    self.alignment = CENTER
    self.alignWidth = self.window.rect.width
    if PortSettings.IS_MOBILE then
        self.alignHeight = self.window.rect.height - GAME_MENU_SIZE - MEASURES.MARGIN_SCREEN
    else
        self.alignHeight = self.window.rect.height + AbilityIcon:GetSize() + MEASURES.MARGIN_SCREEN
    end

    self:moveElementToTop(self.buttonClose)
    self:setPosition(0, 0)
    director:subscribe(Tags.UI_CLEAR, self)
end

function WindowItem:addTitleBar(item)
    local currentY = self:addTitle(self:getWindowTitle(), item:getIcon(), item:getStrokeColor())
    self.windowTitle.color = item.labelColor
    currentY = currentY - 1
    self:addButtonClose().input.onRelease = onButtonClose
    return currentY
end

function WindowItem:_addStatLine(currentY, statLine, textX)
    local text = self:addElement("text_wrapped", textX, currentY, WIDTH - textX * 2, statLine, FONT)
    text:setBaseColor(COLORS.ITEM_WINDOW_STATS)
    currentY = currentY + text.rect.height + 2 + SPACE_STAT_LINE
    return currentY, text
end

function WindowItem:getWindowTitle()
    return self.item:getFullName()
end

function WindowItem:setAlignSide(newSide)
    self.alignSide = newSide
    self:updateAlignSide()
end

function WindowItem:updateAlignSide()
        if self.alignSide == RIGHT then
        self.alignWidth = self.director:getRightAlignWidth()
    elseif self.alignSide == LEFT then
        self.alignWidth = self.director:getLeftAlignWidth()
    else
        self.alignWidth = self.window.rect.width
    end

end

function WindowItem:update(...)
    WindowItem:super(self, "update", ...)
    self:updateAlignSide()
end

function WindowItem:createExtraElements(currentY, textX)
    return currentY - MEASURES.MARGIN_INTERNAL + 1
end

function WindowItem:addStatLines(currentY, item, textX)
    local statLines = TextItems.getStatLines(item)
    local modStatLine = item:getModifierStatLine()
    if self.item:getSlot() == Tags.SLOT_AMULET then
        statLines = Array.EMPTY
    end

    if not statLines:isEmpty() or modStatLine then
        currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL + 1
        for statLine in statLines() do
            currentY, text = self:_addStatLine(currentY, statLine, textX)
        end

        if modStatLine then
            currentY, text = self:_addStatLine(currentY, modStatLine, textX)
            text:setBaseColor(COLORS.ITEM_WINDOW_EXTRA_STAT_LINE)
        end

        if self.forcedBlank and not (modStatLine and item.modifierDef and item.modifierDef.abilityExtraLine) and not PortSettings.IS_MOBILE then
            currentY = self:_addStatLine(currentY, "", textX)
        end

    end

    return currentY
end

local PASSIVE_LABEL = "{C:KEYWORD}Passive - "
local PASSIVE_LABEL_NEGATIVE = "{C:DOWNGRADED}Passive: "
local AUTOCAST_LABEL = "{C:KEYWORD}Autocast %s - "
function WindowItem:addPassiveDescription(currentY, description, startingX, textX, isNegative)
    self:addElement("divider", startingX, currentY, WIDTH - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + MEASURES.MARGIN_INTERNAL + 2
    local cooldown = self.item.stats:get(Tags.STAT_ABILITY_COOLDOWN, 0)
        if cooldown > 0 and self.item:getSlot() == Tags.SLOT_RING and self.item.definition.statsBase:hasKey(Tags.STAT_ABILITY_COOLDOWN) then
        description = textStatFormat(AUTOCAST_LABEL, self.item, Tags.STAT_ABILITY_COOLDOWN) .. description
    elseif isNegative then
        description = PASSIVE_LABEL_NEGATIVE .. description
    else
        description = PASSIVE_LABEL .. description
    end

    if self.item.modifierDef and self.item.modifierDef.passiveExtraLine then
        description = description .. " {FORCE_NEWLINE} {B:STAT_LINE}" .. Utils.evaluate(self.item.modifierDef.passiveExtraLine, self.item)
    end

    local descElement = self:addElement("text_wrapped", textX, currentY, WIDTH - textX * 2, description, FONT)
    if self.forcedBlank and not PortSettings.IS_MOBILE then
        currentY = self:_addStatLine(currentY, "", textX)
    end

    return currentY + descElement.rect.height + MEASURES.MARGIN_INTERNAL + 1
end

function WindowItem:addExtraDescription(currentY, startingX, textX)
    return currentY
end

function WindowItem:addAbilityHeader(currentY, item, startingX, textX)
    self:addElement("divider", startingX, currentY, WIDTH - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + 1
    local ability = item:getAbility()
    local abilityIcon = self:addElement("sprite", startingX + ABILITY_MARGIN, currentY + ABILITY_MARGIN, "abilities", ABILITY_SIZE)
    abilityIcon:setCell(ability.icon)
    abilityIcon:setColor(ability.iconColor)
    abilityIcon:setShader(SHADERS.FILTER_OUTLINE)
    self:addElement("divider", startingX + ABILITY_TOP_HEIGHT, currentY, ABILITY_TOP_HEIGHT, true)
    self:addElement("divider", startingX, currentY + ABILITY_TOP_HEIGHT, WIDTH - MEASURES.BORDER_WINDOW * 2)
    local abilityTopX = startingX + ABILITY_TOP_HEIGHT + MEASURES.MARGIN_INTERNAL + 1
    local ABILITY_TOP_MARGIN = (ABILITY_TOP_HEIGHT - FONT.height * 2) / 3
    currentY = currentY + ABILITY_TOP_MARGIN
    self:addElement("text", abilityTopX, currentY, ability.name, FONT, COLORS.ITEM_WINDOW_ABILITY_LABEL)
    currentY = currentY + FONT.height + ABILITY_TOP_MARGIN
    self:addElement("text_wrapped", abilityTopX, currentY, WIDTH - abilityTopX - textX, getAbilityCostText(item), FONT)
    currentY = currentY + FONT.height + ABILITY_TOP_MARGIN + 1
    return currentY
end

function WindowItem:addAbilityElements(currentY, item, startingX, textX)
    currentY = self:addAbilityHeader(currentY, item, startingX, textX)
    currentY = currentY + MEASURES.MARGIN_INTERNAL + 1
    local description = item:getAbility().getDescription(item)
    if item.modifierDef and item.modifierDef.abilityExtraLine then
        description = description .. " {FORCE_NEWLINE} {B:STAT_LINE}" .. Utils.evaluate(item.modifierDef.abilityExtraLine, item)
    end

    local descElement = self:addElement("text_wrapped", textX, currentY, WIDTH - textX * 2, description, FONT)
    return currentY + descElement.rect.height + MEASURES.MARGIN_INTERNAL + 1
end

function WindowItem:receiveMessage(message)
    if message == Tags.UI_CLEAR then
        self:delete()
    end

end

return WindowItem

