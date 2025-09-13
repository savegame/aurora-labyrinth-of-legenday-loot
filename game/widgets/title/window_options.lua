local WindowOptions = class("widgets.window")
local Common = require("common")
local ConvertNumber = require("utils.algorithms.convert_number")
local Array = require("utils.classes.array")
local Range = require("utils.classes.range")
local Vector = require("utils.classes.vector")
local Global = require("global")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local FONTS = require("draw.fonts")
local TERMS = require("text.terms")
local AbilityIcon = require("elements.ability_icon")
local BUTTON_CHOOSER_SIZE = 16
if PortSettings.IS_MOBILE then
    BUTTON_CHOOSER_SIZE = 24
end

local BUTTON_WIDTH = floor((MEASURES.WIDTH_OPTIONS - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
local function onButtonClose(button, widget)
    Global:get(Tags.GLOBAL_AUDIO).tempVolumeBGM = false
    Global:get(Tags.GLOBAL_AUDIO):setTempVolumeSFX(false)
    if widget._inGame then
        widget.isVisible = false
        widget._director:publish(Tags.UI_SHOW_WINDOW_PAUSE)
    else
        widget._director:publish(Tags.UI_CLEAR)
        widget._director:publish(Tags.UI_TITLE_BACK)
    end

end

function WindowOptions:initialize(director, inGame)
    local WIDTH = MEASURES.WIDTH_OPTIONS
    self.temporaryProfile = Global:get(Tags.GLOBAL_PROFILE):clone()
    WindowOptions:super(self, "initialize", WIDTH)
    self._director = director
    self._inGame = inGame or false
    self.options = Array:new()
    self.isVisible = false
    self.currentY = self:addTitle("Options", Vector:new(8, 17)) - 1
    self:addButtonClose().input.onRelease = onButtonClose
    if not PortSettings.IS_MOBILE then
        self:addDisplayOptions()
    end

    self:addSoundOptions()
    if not inGame then
        self:addOtherOptions()
    end

    if not PortSettings.IS_MOBILE then
        self:addControlOption("codeToKey")
        self:addControlOption("codeToButton")
    end

    self:addButtonGroup()
    self.leftControl = false
    self.rightControl = false
    if not PortSettings.IS_MOBILE then
        self:addControllers()
    end

    self:selectIndex(1)
    self.window.rect.height = self.currentY + MEASURES.BORDER_WINDOW
    self.alignment = CENTER
    self.alignWidth = WIDTH
    if inGame then
        self.alignHeight = self.window.rect.height + AbilityIcon:GetSize() + MEASURES.MARGIN_SCREEN
    else
        self.alignHeight = self.window.rect.height
    end

    self:moveElementToTop(self.buttonClose)
    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_SHOW_OPTIONS, self)
end

function WindowOptions:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
    elseif message == Tags.UI_SHOW_OPTIONS then
        self.isVisible = true
    end

end

local function isOptionActivated(option, widget)
    if PortSettings.IS_MOBILE then
        return false
    end

    if widget.selectedIndex > widget.options:size() then
        return false
    end

    return option == widget.options[widget.selectedIndex]
end

local function onOptionActivate(option, widget)
    widget:selectIndex(widget.options:indexOf(option))
end

function WindowOptions:selectIndex(index)
    self.selectedIndex = index
    if index > self.options:size() then
        self.buttonGroup:selectIndex(1)
        self:moveElementToTop(self.buttonGroup)
    else
        self.buttonGroup:deselect()
        if not PortSettings.IS_MOBILE then
            self:moveElementToTop(self.leftControl)
            self:moveElementToTop(self.rightControl)
            local option = self.options[index]
            self:moveElementToTop(option)
            if option.controller then
                self:moveElementToTop(option.controller)
            end

            if option.extraElement then
                self:moveElementToTop(option.extraElement)
            end

        end

    end

end

function WindowOptions:createOption(label)
    local option = self:addElement("option", 1, self.currentY, self.window.rect.width - 2)
    option.label = label
    option.isActivated = isOptionActivated
    option.input.onTrigger = onOptionActivate
    self.options:push(option)
    self.currentY = self.currentY + option.rect.height - 1
    return option
end

local FULLSCREEN_OPTIONS = Array:new(Tags.FULLSCREEN_MODE_WINDOWED, Tags.FULLSCREEN_MODE_EXCLUSIVE, Tags.FULLSCREEN_MODE_BORDERLESS)
local RESOLUTION_FORMAT = "%d x %d"
function WindowOptions:addDisplayOptions()
    local width = self.window.rect.width
    local option = self:createOption("Fullscreen Mode")
    local buttonOffset = (option.rect.height - BUTTON_CHOOSER_SIZE) / 2
    local chooserWidth = MEASURES.WIDTH_OPTIONS_CHOICE
    local chooserX = width - buttonOffset - chooserWidth - 1
    self.chooserFullscreen = self:addChildWidget("chooser", chooserX, option.position.y + buttonOffset, chooserWidth, BUTTON_CHOOSER_SIZE, FULLSCREEN_OPTIONS, FULLSCREEN_OPTIONS:indexOf(self.temporaryProfile.fullscreenMode))
    self.chooserFullscreen.optionToText = function(option)
        return TERMS.UI.OPTIONS_FULLSCREEN[option]
    end
    self.chooserFullscreen.onChange = function(chooser, option)
        self.temporaryProfile.fullscreenMode = option
        self.chooserResolution:refresh()
    end
    option.controller = self.chooserFullscreen
    option = self:createOption("Resolution")
    local resolutions = Array:Convert(window.getFullscreenModes())
    resolutions = resolutions:stableSort(function(a, b)
        if a.height == b.height then
            return a.width < b.width
        else
            return a.height < b.height
        end

    end)
    self.chooserResolution = self:addChildWidget("chooser", chooserX, option.position.y + buttonOffset, chooserWidth, BUTTON_CHOOSER_SIZE, resolutions, resolutions:size())
    self.chooserResolution.isEnabled = function(chooser)
        return self.chooserFullscreen:getSelectedOption() ~= Tags.FULLSCREEN_MODE_BORDERLESS
    end
    self.chooserResolution.optionToText = function(option)
        return RESOLUTION_FORMAT:format(option.width, option.height)
    end
    self.chooserResolution.disabledText = function(chooser)
        if self.chooserFullscreen:getSelectedOption() == Tags.FULLSCREEN_MODE_WINDOWED then
            return " - "
        else
            return self.chooserResolution.optionToText(resolutions:last())
        end

    end
    self.chooserResolution.onChange = function(chooser, option)
        self.temporaryProfile.fullscreenWidth = option.width
        self.temporaryProfile.fullscreenHeight = option.height
    end
    if self.temporaryProfile.fullscreenMode ~= Tags.FULLSCREEN_MODE_BORDERLESS then
        local closest = resolutions:last()
        local profile = self.temporaryProfile
        local minDifference = abs(closest.width - profile.fullscreenWidth)
        minDifference = minDifference + abs(closest.height - profile.fullscreenHeight)
        for resolution in resolutions() do
            local thisDifference = abs(resolution.width - profile.fullscreenWidth)
            thisDifference = thisDifference + abs(resolution.height - profile.fullscreenHeight)
            if thisDifference < minDifference then
                minDifference = thisDifference
                closest = resolution
            end

        end

        self.chooserResolution:setIndex(resolutions:indexOf(closest))
    end

    option.controller = self.chooserResolution
end

function WindowOptions:addSoundOptions()
    local width = self.window.rect.width
    local option = self:createOption("Music Volume")
    self.sliderMusic = self:addElement("slider", 0, 0, MEASURES.WIDTH_OPTIONS_CHOICE - 2)
    local sliderOffset = (option.rect.height - self.sliderMusic.rect.height) / 2
    local sliderX = width - MEASURES.WIDTH_OPTIONS_CHOICE - sliderOffset + 2
    self.sliderMusic:setX(sliderX)
    self.sliderMusic:setY(option.position.y + sliderOffset)
    self.sliderMusic.value = self.temporaryProfile.volumeBGM
    self.sliderMusic.onChange = function(value)
        self.temporaryProfile.volumeBGM = value
        Global:get(Tags.GLOBAL_AUDIO).tempVolumeBGM = value
    end
    option.controller = self.sliderMusic
    option = self:createOption("Sound Effects")
    self.sliderSFX = self:addElement("slider", sliderX, option.position.y + sliderOffset, MEASURES.WIDTH_OPTIONS_CHOICE - 2)
    self.sliderSFX.value = self.temporaryProfile.volumeSFX
    self.sliderSFX.onChange = function(value)
        self.temporaryProfile.volumeSFX = value
        Global:get(Tags.GLOBAL_AUDIO):setTempVolumeSFX(value)
    end
    option.controller = self.sliderSFX
end

function WindowOptions:addOtherOptions()
    local width = self.window.rect.width
    local option = self:createOption("Tutorial")
    local buttonOffset = (option.rect.height - BUTTON_CHOOSER_SIZE) / 2
    local chooserWidth = MEASURES.WIDTH_OPTIONS_CHOICE
    local chooserX = width - buttonOffset - chooserWidth - 1
    self.chooserTutorial = self:addChildWidget("chooser", chooserX, option.position.y + buttonOffset, chooserWidth, BUTTON_CHOOSER_SIZE, TERMS.UI.OPTIONS_TUTORIAL, self.temporaryProfile.tutorialFrequency)
    self.chooserTutorial.onChange = function(chooser, option)
        self.temporaryProfile.tutorialFrequency = TERMS.UI.OPTIONS_TUTORIAL:indexOf(option)
    end
    option.controller = self.chooserTutorial
    option = self:createOption("Character")
    self.chooserCharacter = self:addChildWidget("chooser", chooserX, option.position.y + buttonOffset, chooserWidth, BUTTON_CHOOSER_SIZE, TERMS.UI.OPTIONS_CHARACTER, self.temporaryProfile.character)
    self.chooserCharacter.onChange = function(chooser, option)
        self.temporaryProfile.character = TERMS.UI.OPTIONS_CHARACTER:indexOf(option)
    end
    option.controller = self.chooserCharacter
    if PortSettings.IS_MOBILE then
        option = self:createOption("Controls Size")
        self.chooserControlSize = self:addChildWidget("chooser", chooserX, option.position.y + buttonOffset, chooserWidth, BUTTON_CHOOSER_SIZE, Range:new(1, 10):toArray():map(tostring), self.temporaryProfile.controlSize)
        self.chooserControlSize.onChange = function(chooser, option)
            self.temporaryProfile.controlSize = tonumber(option)
        end
        option.controller = self.chooserControlSize
    end

end

local function isEditControlsActivated(button, widget)
    if widget.selectedIndex > widget.options:size() then
        return false
    end

    local option = widget.options[widget.selectedIndex]
    return button == option.extraElement
end

function WindowOptions:addControlOption(profileField)
    local option
    if profileField == "codeToKey" then
        option = self:createOption(TERMS.UI.OPTIONS_CONTROLS_KEYBOARD, false)
    else
        option = self:createOption(TERMS.UI.OPTIONS_CONTROLS_GAMEPAD, false)
    end

    local buttonHeight = (MEASURES.HEIGHT_BUTTON - 2)
    local buttonOffsetY = (option.rect.height - buttonHeight) / 2
    local buttonOffsetX = (option.rect.height - BUTTON_CHOOSER_SIZE) / 2
    local buttonWidth = MEASURES.WIDTH_OPTIONS_CHOICE
    local editControlsButton = self:addElement("button_simple_text", self.window.rect.width - buttonOffsetX - buttonWidth - 1, option.position.y + buttonOffsetY, buttonWidth, buttonHeight, "Edit", FONTS.MEDIUM, true)
    editControlsButton.isActivated = isEditControlsActivated
    editControlsButton.input.onRelease = function(button, widget)
        widget.isVisible = false
        widget._director:createWidget("title.window_controls", widget._director, widget.temporaryProfile, profileField, widget._inGame)
    end
    editControlsButton.input.shortcut = Tags.KEYCODE_CONFIRM
    option.extraElement = editControlsButton
end

local function isApplyButtonEnabled(button, widget)
    return not Global:get(Tags.GLOBAL_PROFILE):isNonControlEqual(widget.parent.temporaryProfile)
end

local function onApplyButton(button, widget)
    Global:get(Tags.GLOBAL_PROFILE):applyNonControlsAndSave(widget.parent.temporaryProfile)
    widget.parent._director:publish(Tags.UI_REFRESH_EXPLORED)
end

local function onResetButton(button, widget)
    local widget = widget.parent
    widget.temporaryProfile:setNonControlWithData({  })
    if not PortSettings.IS_MOBILE then
        widget.chooserFullscreen:selectByValue(widget.temporaryProfile.fullscreenMode)
        widget.chooserResolution:selectLast()
        local resolution = widget.chooserResolution:getSelectedOption()
        widget.temporaryProfile.fullscreenWidth = resolution.width
        widget.temporaryProfile.fullscreenHeight = resolution.height
    end

    widget.sliderMusic:setValue(widget.temporaryProfile.volumeBGM)
    widget.sliderSFX:setValue(widget.temporaryProfile.volumeSFX)
    if not widget._inGame then
        widget.chooserTutorial:setIndex(widget.temporaryProfile.tutorialFrequency)
        widget.chooserCharacter:setIndex(widget.temporaryProfile.character)
    end

end

function WindowOptions:addButtonGroup()
    self.currentY = self.currentY + 1 + MEASURES.MARGIN_INTERNAL
    local buttonX = MEASURES.BORDER_WINDOW + MEASURES.MARGIN_INTERNAL
    self.buttonGroup = self:addChildWidget("button_group", 0, self.currentY)
    local applyButton = self.buttonGroup:add("Apply", buttonX, 0, BUTTON_WIDTH, onApplyButton)
    applyButton.input.isEnabled = isApplyButtonEnabled
    local resetButton = self.buttonGroup:add("Reset to Default", self.window.rect.width - buttonX - BUTTON_WIDTH, 0, BUTTON_WIDTH, onResetButton)
    self.currentY = self.currentY + applyButton.rect.height + MEASURES.MARGIN_INTERNAL
    self.buttonGroup:addControl(Tags.KEYCODE_LEFT, -1)
    self.buttonGroup:addControl(Tags.KEYCODE_RIGHT, 1)
    self.buttonGroup:deselect()
    self.buttonGroup:dehover()
end

local function onControlVertical(control, widget)
    Common.playSFX("CURSOR")
    widget:selectIndex(modAdd(widget.selectedIndex, control.movementValue, widget.options:size() + 1))
end

local function onControlHorizontal(control, widget)
    if widget.selectedIndex <= widget.options:size() then
        local option = widget.options[widget.selectedIndex]
        if option.controller then
            Common.playSFX("CURSOR")
            option.controller:selectNext(control.movementValue)
        end

    end

end

function WindowOptions:addControllers()
    self:addHiddenControl(Tags.KEYCODE_UP, onControlVertical, -1)
    self:addHiddenControl(Tags.KEYCODE_DOWN, onControlVertical, 1)
    self.leftControl = self:addHiddenControl(Tags.KEYCODE_LEFT, onControlHorizontal, -1)
    self.rightControl = self:addHiddenControl(Tags.KEYCODE_RIGHT, onControlHorizontal, 1)
end

return WindowOptions

