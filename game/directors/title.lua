local DirectorTitle = class("directors.director")
local CONSTANTS = require("logic.constants")
local ScreenGameLoading = require("screens.game_loading")
local Global = require("global")
local Run = require("structures.run")
local LogicInitial = require("logic.initial")
local FILENAMES = require("text.filenames")
Tags.add("UI_TITLE_BACK")
Tags.add("UI_TITLE_SHOW_NEW_GAME")
Tags.add("UI_TITLE_SHOW_STATS")
Tags.add("UI_TITLE_SHOW_ITEM_LOG")
Tags.add("UI_TITLE_SHOW_CREDITS")
Tags.add("UI_SHOW_OPTIONS")
function DirectorTitle:initialize()
    DirectorTitle:super(self, "initialize")
    self:setDependencies("controls")
    self.darkenCover = false
    self.mainChoices = false
    self.difficultyChoices = false
end

function DirectorTitle:onDependencyFulfill()
    DirectorTitle:super(self, "onDependencyFulfill")
    if PortSettings.IS_MOBILE then
        self.mainChoices = self:createWidget("title.main_buttons", self)
    else
        self.mainChoices = self:createWidget("title.main_choices", self)
    end

    self.difficultyChoices = self:createWidget("title.difficulty_choices", self)
    self.difficultyChoices.isVisible = false
    self.darkenCover = self:createWidget("input_blocker", self)
    self.darkenCover.blocker.targetOpacity = 0.25
    self.darkenCover.isVisible = false
    self.darkenCover.hideOnClear = true
    self:createWidget("title.window_high_scores", self)
    self:createWidget("title.window_log", self)
    self:createWidget("title.window_options", self)
    self:createWidget("title.window_credits", self)
end

function DirectorTitle:cover()
    self.darkenCover.blocker.opacity = 0
    self.darkenCover.isVisible = true
end

function DirectorTitle:startGame(difficulty)
    local newRun = LogicInitial.createNewRun(difficulty)
    Global:get(Tags.GLOBAL_AUDIO):fadeoutCurrentBGM()
    self:screenTransition(ScreenGameLoading, false, LogicInitial.getInitialItems(newRun), CONSTANTS.SCRAP_INITIAL)
end

function DirectorTitle:receiveMessage(message, arg1)
end

function DirectorTitle:continueGame()
    local currentRun = Run:new()
    local status, err = pcall(currentRun.loadFromFile, currentRun)
    if not status then
        Debugger.log("Error loading file", err)
        filesystem.remove(FILENAMES.CURRENT_RUN)
        return false
    else
        Global:set(Tags.GLOBAL_CURRENT_RUN, currentRun)
        Global:get(Tags.GLOBAL_AUDIO):fadeoutCurrentBGM()
        self:screenTransition(ScreenGameLoading, true)
        return true
    end

end

function DirectorTitle:startStats()
    self:screenTransition(ScreenStats)
end

function DirectorTitle:getRawKeyReleased()
    return self.services.controls.rawKeyReleased
end

function DirectorTitle:getRawButtonReleased()
    return self.services.controls.rawButtonReleased
end

return DirectorTitle

