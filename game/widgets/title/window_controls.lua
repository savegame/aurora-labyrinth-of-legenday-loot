local WindowControls = class("widgets.window")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local Common = require("common")
local Global = require("global")
local TERMS = require("text.terms")
local MEASURES = require("draw.measures")
local AbilityIcon = require("elements.ability_icon")
local ICON_GAMEPAD = Vector:new(10, 17)
local ICON_KEYBOARD = Vector:new(8, 21)
local BUTTON_WIDTH = floor((MEASURES.WIDTH_OPTIONS - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
local BLOCKER_OPACITY_CONTROLS = 0.5
local CONTROLS = Array:new(Tags.KEYCODE_CONFIRM, Tags.KEYCODE_CANCEL, Tags.KEYCODE_EQUIPMENT, Tags.KEYCODE_WAIT, Tags.KEYCODE_UP, Tags.KEYCODE_LEFT, Tags.KEYCODE_DOWN, Tags.KEYCODE_RIGHT, Tags.KEYCODE_ABILITY_1, Tags.KEYCODE_ABILITY_4, Tags.KEYCODE_ABILITY_2, Tags.KEYCODE_ABILITY_5, Tags.KEYCODE_ABILITY_3, Tags.KEYCODE_KEYWORDS)
local function isSlotActivated(slot, widget)
    if widget.selectedIndex > widget.itemSlots:size() then
        return false
    end

    return slot == widget.itemSlots[widget.selectedIndex]
end

local function onButtonClose(button, widget)
    widget:delete()
    widget._director:publish(Tags.UI_SHOW_OPTIONS)
end

local function onControl(control, widget)
    Common.playSFX("CURSOR")
    local value = control.movementValue
    local selectedIndex = widget.selectedIndex
    if value == 1 and selectedIndex % 2 == 0 then
        value = -1
    end

    widget:selectIndex(modAdd(selectedIndex, value, widget.itemSlots:size() + 2))
end

local function onConfirm(control, widget)
    if widget.selectedIndex <= widget.itemSlots:size() then
        Common.playSFX("CONFIRM")
        widget.itemSlots[widget.selectedIndex].input:trigger()
    else
        Common.playSFX("CONFIRM")
        widget.buttonGroup:triggerIndex(widget.selectedIndex - widget.itemSlots:size())
    end

end

local function onSlotActivate(slot, widget)
    local index = widget.itemSlots:indexOf(slot)
    widget:selectIndex(index)
    local inputBlocker = widget._director:createInputBlocker()
    inputBlocker.blocker.targetOpacity = BLOCKER_OPACITY_CONTROLS
    widget._director:createWidget("title.window_new_control", widget._director, widget.temporaryProfile, widget.profileField, CONTROLS[index], inputBlocker)
end

local function isApplyButtonEnabled(button, widget)
    local field = widget.parent.profileField
    return Global:get(Tags.GLOBAL_PROFILE)[field] ~= widget.parent.temporaryProfile[field]
end

local function onApplyButton(button, widget)
    Global:get(Tags.GLOBAL_PROFILE):applyControlsAndSave(widget.parent.temporaryProfile, widget.parent.profileField)
end

local function onResetButton(button, widget)
    widget.parent.temporaryProfile:setControlWithData({  })
end

function WindowControls:initialize(director, temporaryProfile, profileField, inGame)
    local WIDTH = MEASURES.WIDTH_OPTIONS
    WindowControls:super(self, "initialize", WIDTH)
    self._director = director
    self._inGame = inGame
    self.temporaryProfile = temporaryProfile
    self.profileField = profileField
    local title, icon
    if profileField == "codeToKey" then
        title = TERMS.UI.OPTIONS_CONTROLS_KEYBOARD
        icon = ICON_KEYBOARD
    else
        title = TERMS.UI.OPTIONS_CONTROLS_GAMEPAD
        icon = ICON_GAMEPAD
    end

    local currentY = self:addTitle(title, icon) - 1
    self:addButtonClose().input.onRelease = onButtonClose
    self.itemSlots = Array:new()
    local startingX = MEASURES.BORDER_WINDOW
    local currentX = startingX - 1
    for i = 1, CONTROLS:size() do
        local itemSlot = self:addElement("control_slot", currentX, currentY, ceil(WIDTH / 2) - (startingX - 1), self.temporaryProfile, profileField, CONTROLS[i])
        itemSlot.isActivated = isSlotActivated
        itemSlot.input.onRelease = onSlotActivate
        itemSlot.input.triggerSound = "CONFIRM"
        self.itemSlots:push(itemSlot)
        if i % 2 == 0 then
            currentY = currentY + itemSlot.rect.height - 1
            currentX = startingX - 1
        else
            currentX = currentX + ceil(WIDTH / 2) - (startingX - 1) - 1
        end

    end

    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    self:addHiddenControl(Tags.KEYCODE_UP, onControl, -2)
    self:addHiddenControl(Tags.KEYCODE_DOWN, onControl, 2)
    self:addHiddenControl(Tags.KEYCODE_LEFT, onControl, 1)
    self:addHiddenControl(Tags.KEYCODE_RIGHT, onControl, 1)
    self:addHiddenControl(Tags.KEYCODE_CONFIRM, onConfirm, 0, true)
    local buttonX = MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL
    self.buttonGroup = self:addChildWidget("button_group", 0, currentY)
    local applyButton = self.buttonGroup:add("Apply", buttonX, 0, BUTTON_WIDTH, onApplyButton)
    applyButton.input.isEnabled = isApplyButtonEnabled
    local resetButton = self.buttonGroup:add("Reset to Defaults", self.window.rect.width - buttonX - BUTTON_WIDTH, 0, BUTTON_WIDTH, onResetButton)
    currentY = currentY + applyButton.rect.height + MEASURES.MARGIN_INTERNAL
    self.buttonGroup:deselect()
    self.window.rect.height = currentY + MEASURES.BORDER_WINDOW
    self:selectIndex(1)
    self.alignment = CENTER
    self.alignWidth = WIDTH
    if inGame then
        self.alignHeight = self.window.rect.height + AbilityIcon:GetSize() + MEASURES.MARGIN_SCREEN
    else
        self.alignHeight = self.window.rect.height
    end

end

function WindowControls:selectIndex(index)
    self.selectedIndex = index
    if index > self.itemSlots:size() then
        self.buttonGroup:selectIndex(index - self.itemSlots:size())
    else
        self.buttonGroup:deselect()
        self:moveElementToTop(self.itemSlots[index])
    end

end

return WindowControls

