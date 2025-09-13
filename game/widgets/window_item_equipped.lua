local WindowItemEquipped = class("widgets.window_item")
local CONSTANTS = require("logic.constants")
local Common = require("common")
local ItemCreateCommand = require("logic.item_create_command")
local Global = require("global")
local LogicMethods = require("logic.methods")
local ConvertNumber = require("utils.algorithms.convert_number")
local TERMS = require("text.terms")
local MEASURES = require("draw.measures")
local BUTTON_WIDTH = floor((MEASURES.WIDTH_ITEM_WINDOW - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
local EXTRA_FONT = require("draw.fonts").MEDIUM
local FLASH_DURATION = 0.35
local function onUpgradeButton(button, widget)
    widget = widget.parent
    if widget.director:canDoTurn() then
        widget.director:logAction("Upgrade equipped - " .. tostring(widget.item:getSlot()))
        local upgradeCost = widget.item:getUpgradeCost(widget.director.currentRun.difficulty)
        widget.director:addScrap(-upgradeCost)
        widget.director:decorateSaveRatios(function(player)
            widget.item:upgrade()
            Global:get(Tags.GLOBAL_PROFILE):discoverItem(widget.item)
            widget.item.scrapSpent = widget.item.scrapSpent + upgradeCost
        end)
        widget.parentList:onSelect()
        widget.director:flashPlayer()
    end

end

local function onSalvageButton(button, widget)
    widget = widget.parent
    if widget.director:canDoTurn() then
        local player = widget.parentList.player
        widget.director:logAction("Salvage equipped", widget.item:getSlot())
        local slot = widget.item:getSlot()
        local cancelAction = false
        if player.equipment:isSlotActive(slot) then
            cancelAction = widget.director:getCancelModeAction(slot)
        end

        player.equipment:equip(false, slot)
        widget.director:addScrap(widget.item:getSellCost())
        widget.parentList:selectFirstAvailable()
        widget.director:flashPlayer()
        if cancelAction then
            widget.director:executePlayerAction(cancelAction)
        end

    end

end

local function isUpgradeEnabled(button, widget)
    local item = widget.parent.item
    if not item:isUpgradeDisabled() then
        local director = widget.parent.director
        if item.level < LogicMethods.getCurrentMaxUpgrade(director:getCurrentFloor()) then
            if director:getScrap() >= widget.parent.item:getUpgradeCost(director.currentRun.difficulty) then
                return true
            end

        end

    end

    return false
end

local function isSalvageEnabled(button, widget)
    widget = widget.parent
    if widget.director:getCurrentFloor() == CONSTANTS.MAX_FLOORS and widget.item:getSlot() == Tags.SLOT_AMULET then
        return false
    end

    return widget.director:hasSpaceForScrap(widget.item:getSellCost()) or DebugOptions.MAX_OUT_SCRAP
end

local FORMAT_UPGRADE = "Upgrade: {C:%s}-%d{ICON:SALVAGE}"
local FORMAT_NEXT_UPGRADE = "Floor: %d"
function WindowItemEquipped:createExtraElements(currentY, textX)
    local upgradeText
    local currentFloor = self.director:getCurrentFloor()
            if self.item:isUpgradeDisabled() then
        upgradeText = "-"
    elseif self.item:isMaxLevel() then
        upgradeText = "Max Level"
    elseif self.item.level == LogicMethods.getCurrentMaxUpgrade(currentFloor) then
        local upgradeFloor = LogicMethods.getNextUpgradeFloor(currentFloor)
        upgradeText = FORMAT_NEXT_UPGRADE:format(upgradeFloor)
    else
        local upgradeColor = "BASE"
        if self.item.stats:get(Tags.STAT_UPGRADE_DISCOUNT, 0) > 0 then
            upgradeColor = "UPGRADED"
        end

        upgradeText = FORMAT_UPGRADE:format(upgradeColor, self.item:getUpgradeCost(self.director.currentRun.difficulty))
    end

    self.buttonGroup = self:addChildWidget("button_group", 0, currentY)
    local upgradeButton = self.buttonGroup:add(upgradeText, textX - 1, 0, BUTTON_WIDTH, onUpgradeButton)
    upgradeButton.input.triggerSound = "ANVIL"
    upgradeButton.input.isEnabled = isUpgradeEnabled
    local salvageText = TERMS.UI.SALVAGE_FORMAT:format(self.item:getSellCost())
    if self.director:getCurrentFloor() == CONSTANTS.MAX_FLOORS and self.item:getSlot() == Tags.SLOT_AMULET then
    end

    local salvageButton = self.buttonGroup:add(salvageText, MEASURES.WIDTH_ITEM_WINDOW - (textX - 1) - BUTTON_WIDTH, 0, BUTTON_WIDTH, onSalvageButton)
    salvageButton.input.triggerSound = "SALVAGE"
    salvageButton.input.isEnabled = isSalvageEnabled
    self.buttonGroup:addControl(Tags.KEYCODE_LEFT, -1)
    self.buttonGroup:addControl(Tags.KEYCODE_RIGHT, 1)
    return currentY + upgradeButton.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
end

function WindowItemEquipped:update(dt)
    WindowItemEquipped:super(self, "update", dt)
    self.window.flash = max(0, self.window.flash - dt / FLASH_DURATION)
end

local NEXT_UPGRADE_LABEL = "{B:NOTE}Next increase at {C:NUMBER}+"
function WindowItemEquipped:decoratePassiveDescription(description, isLast)
    description = self:super(self, "decoratePassiveDescription", description, isLast)
    return description
end

function WindowItemEquipped:addExtraDescription(currentY, startingX, textX)
    if not self.item:isMaxLevel() and self.item:displayNextIncrease() then
        self:addElement("divider", startingX, currentY, MEASURES.WIDTH_ITEM_WINDOW - MEASURES.BORDER_WINDOW * 2)
        currentY = currentY + MEASURES.MARGIN_INTERNAL + 2
        local nextUpgrade = self.item:getNextUpgradeWithGrowth()
        local descElement = self:addElement("text_wrapped", textX, currentY, MEASURES.WIDTH_ITEM_WINDOW - textX * 2, NEXT_UPGRADE_LABEL .. nextUpgrade .. ".", EXTRA_FONT)
        return currentY + descElement.rect.height + MEASURES.MARGIN_INTERNAL + 1
    else
        return WindowItemEquipped:super(self, "addExtraDescription", currentY, startingX, textX)
    end

end

return WindowItemEquipped

