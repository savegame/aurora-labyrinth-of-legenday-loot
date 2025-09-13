local DifficultyChoices
if PortSettings.IS_MOBILE then
    DifficultyChoices = class("widgets.title.main_buttons")
else
    DifficultyChoices = class("widgets.title.main_choices")
end

local Global = require("global")
local Array = require("utils.classes.array")
local ButtonConfig = require("structures.button_config")
local COLORS = require("draw.colors")
local DIFFICULTY_LABELS = require("text.terms").UI.OPTIONS_DIFFICULTY
local DIFFICULTY_COLORS = Array:new("EASY", "NORMAL", "HARD", "VERY_HARD", "IMPOSSIBLE"):map(function(label)
    return COLORS.TEXT_COLOR_PALETTE:get(label)
end)
local function onCancel(button, widget)
    widget._director:publish(Tags.UI_CLEAR)
    widget._director:publish(Tags.UI_TITLE_BACK)
end

function DifficultyChoices:initialize(director)
    DifficultyChoices:super(self, "initialize", director)
    director:subscribe(Tags.UI_TITLE_SHOW_NEW_GAME, self)
    for button in self.buttons() do
        button.disabledHide = true
        button.input.hoverOnDisabled = false
    end

    self:selectIndex(2)
    local control = self:addHiddenControl(Tags.KEYCODE_CANCEL, onCancel, 0)
    control.input.triggerSound = "CANCEL"
end

function DifficultyChoices:getButtonConfigs()
    local result = Array:new()
    local unlockedDifficulty = Global:get(Tags.GLOBAL_PROFILE).playData:get("unlockedDifficulty")
    for i = 1, DIFFICULTY_LABELS:size() do
        local index = i
        result:push(ButtonConfig:new(DIFFICULTY_LABELS[i], function(button, widget)
            widget._director:startGame(index)
        end, unlockedDifficulty >= i, DIFFICULTY_COLORS[i]))
    end

    if not PortSettings.IS_MOBILE then
        result:push(ButtonConfig:new("Blank", doNothing, false))
    end

    result:push(ButtonConfig:new("Cancel", onCancel))
    return result
end

function DifficultyChoices:receiveMessage(message)
        if message == Tags.UI_CLEAR then
        self.isVisible = false
    elseif message == Tags.UI_TITLE_SHOW_NEW_GAME then
        self.isVisible = true
    end

end

return DifficultyChoices

