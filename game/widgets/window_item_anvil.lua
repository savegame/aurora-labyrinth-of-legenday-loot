local WindowItemAnvil = class("widgets.window_item")
local Common = require("common")
local MEASURES = require("draw.measures")
local LogicMethods = require("logic.methods")
local ItemCreateCommand = require("logic.item_create_command")
local function onMainButton(button, widget)
    if widget.director:canDoTurn() then
        local player = widget.parentList.player
        local command = ItemCreateCommand:new(1)
        command.itemDef = widget.item.definition
        if widget.isGolden then
            command.modifierDef = widget.item.definition.legendaryMod
        end

        if not command.modifierDef then
            command.modifierChance = 1
            command.bannedModifier = widget.item.modifierDef
            command:rollModifier(Utils.createRandomGenerator(widget.director.currentRun:getCurrentFloorSeed()))
        end

        command.upgradeLevel = widget.item.level
        local newItem = command:create()
        newItem.scrapSpent = widget.item.scrapSpent
        newItem.hasBeenSeen = true
        widget.director:publish(Tags.UI_CLEAR)
        widget.director:publish(Tags.UI_TUTORIAL_CLEAR)
        widget.director:publish(Tags.UI_HIDE_CONTROLS)
        widget.director:destroyAnvil(widget.parentList.anvilEntity)
        widget.director:createAfterInfuseWindow(newItem)
    end

end

local function isButtonEnabled(button, widget)
    local modifier = widget.item.modifierDef
    if widget.item.definition.disableUpgrade then
        return false
    end

    return not modifier or not modifier.isLegendary
end

function WindowItemAnvil:initialize(...)
    WindowItemAnvil:super(self, "initialize", ...)
    self.isGolden = false
end

function WindowItemAnvil:createExtraElements(currentY, textX)
    local text = ""
        if self.item.definition.disableUpgrade then
        text = "Can't enchant starting weapon"
    elseif self.item.modifierDef then
        if self.item.modifierDef.isLegendary then
            text = "Can't replace {C:LEGENDARY}Legendary enchantment"
        else
            local name = self.item.modifierDef.name
            if name:sub(1, 4) == "the " then
                name = name:sub(5)
            end

            text = ("Replace enchantment {C:UPGRADED}%s"):format(name)
        end

    else
        text = "Enchant"
    end

    local mainButton = self:addElement("button_text", textX - 1, currentY, MEASURES.WIDTH_ITEM_WINDOW - textX * 2 + 2, MEASURES.HEIGHT_BUTTON, text)
    mainButton.isActivated = true
    mainButton.input.triggerSound = "ANVIL"
    mainButton.input.shortcut = Tags.KEYCODE_CONFIRM
    mainButton.input.isEnabled = isButtonEnabled
    mainButton.input.onRelease = onMainButton
    self:addHiddenControl(Tags.KEYCODE_LEFT, doNothing, -1)
    self:addHiddenControl(Tags.KEYCODE_RIGHT, doNothing, 1)
    return currentY + mainButton.rect.height + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
end

return WindowItemAnvil

