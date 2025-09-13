local WindowGameover = class("widgets.window")
local Array = require("utils.classes.array")
local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local LogicInitial = require("logic.initial")
local CONSTANTS = require("logic.constants")
local ScreenGameLoading = require("screens.game_loading")
local ScreenTitle = require("screens.title")
local ConvertNumber = require("utils.algorithms.convert_number")
local RESOURCE_BAR_HEIGHT = require("elements.resource_bar").HEIGHT
local MEASURES = require("draw.measures")
local FONTS = require("draw.fonts")
local TERMS = require("text.terms")
local FONT_TITLE = FONTS.MEDIUM_BOLD
local FONT_TEXT = FONTS.MEDIUM
local WIDTH = 180
if PortSettings.IS_MOBILE then
    WIDTH = WIDTH + 30
end

local BUTTON_WIDTH = floor((WIDTH - MEASURES.MARGIN_INTERNAL * 3 - MEASURES.BORDER_WINDOW * 2) / 2)
local function getKillerText(killer)
    local result = "Killed by "
    if killer:hasComponent("label") then
        local article, label = killer.label:getWithArticle()
        if article then
            result = result .. article .. " "
        end

        local color = "NORMAL_ENEMY"
        local strokeColor = killer.sprite.strokeColor
        if strokeColor then
            for k, v in COLORS.TEXT_COLOR_PALETTE() do
                if v == strokeColor then
                    color = k
                    break
                end

            end

        end

        result = result .. "{B:" .. color .. "}" .. label
    end

    return result
end

local function onRestartButtonRelease(button, widget)
    widget = widget.parent
    local newRun = LogicInitial.createNewRun(widget._currentRun.difficulty)
    widget._director:screenTransition(ScreenGameLoading, false, LogicInitial.getInitialItems(newRun), CONSTANTS.SCRAP_INITIAL)
end

local function onExitButtonRelease(button, widget)
    widget = widget.parent
    widget._director:screenTransition(ScreenTitle)
end

local FLOOR_FORMAT = "On the {C:NUMBER}%d%s floor"
local MOVE_DURATION = 0.5
function WindowGameover:initialize(director, currentRun, killer)
    WindowGameover:super(self, "initialize", WIDTH)
    self._director = director
    self._currentRun = currentRun
    local MARGIN_INTERNAL = MEASURES.MARGIN_INTERNAL + 1
    local currentY = MEASURES.BORDER_WINDOW
    local startingX = MEASURES.BORDER_WINDOW
    local title = self:addElement("text", WIDTH / 2, currentY + MARGIN_INTERNAL, "You have died", FONT_TITLE)
    title.alignment = UP
    title.color = COLORS.TEXT_COLOR_PALETTE:get("DOWNGRADED")
    local textX = startingX + MARGIN_INTERNAL
    currentY = currentY + FONT_TITLE.height + MARGIN_INTERNAL * 2
    self:addElement("divider", startingX, currentY, WIDTH - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + 1 + MARGIN_INTERNAL
    self:addElement("text_special", textX, currentY, getKillerText(killer), FONT_TEXT)
    local killerSprite = self:addElement("draw_commands", WIDTH - MEASURES.BORDER_WINDOW - MEASURES.TILE_SIZE / 2 - MEASURES.MARGIN_INTERNAL - 1, currentY - 1)
    killerSprite.commands = function(element)
        local commands = Array:new()
        local timePassed = director:getTimePassed()
        local command = killer.sprite:getStrokeFillCommand(timePassed)
        if command then
            command.position = Vector:new(0, -1) - Vector.UNIT_XY
            command.opacity = 1
            command.flipX = true
            commands:push(command)
        end

        command = killer.sprite:getDrawCommand(director:getTimePassed())
        command.position = -Vector.UNIT_XY
        command.opacity = 1
        command.flipX = true
        commands:push(command)
        return commands
    end
    currentY = currentY + MEASURES.TILE_SIZE - FONT_TEXT.height - 2
    local floorText = FLOOR_FORMAT:format(currentRun.currentFloor, ConvertNumber.getOrdinalSuffix(currentRun.currentFloor))
    if currentRun.currentFloor == 0 then
        floorText = "On the {C:NUMBER}Tutorial floor"
    end

    self:addElement("text_special", textX, currentY, floorText, FONT_TEXT)
    currentY = currentY + FONT_TEXT.height + MEASURES.MARGIN_INTERNAL + 1
    self:addElement("divider", startingX, currentY, WIDTH - MEASURES.BORDER_WINDOW * 2)
    currentY = currentY + 1 + MEASURES.MARGIN_INTERNAL
    self.buttonGroup = self:addChildWidget("button_group", 0, currentY)
    local buttonRestart = self.buttonGroup:add(TERMS.UI.GAMEOVER_RESTART, textX - 1, 0, BUTTON_WIDTH, onRestartButtonRelease)
    local buttonExit = self.buttonGroup:add(TERMS.UI.GAMEOVER_EXIT, WIDTH - textX + 1 - BUTTON_WIDTH, 0, BUTTON_WIDTH, onExitButtonRelease)
    self.buttonGroup:addControl(Tags.KEYCODE_LEFT, -1)
    self.buttonGroup:addControl(Tags.KEYCODE_RIGHT, 1)
    currentY = currentY + buttonRestart.rect.height
    self.alignWidth = WIDTH
    self.alignHeight = currentY + MEASURES.MARGIN_INTERNAL + MEASURES.BORDER_WINDOW
    self.window.rect.height = self.alignHeight
    self.targetY = MEASURES.MARGIN_SCREEN * 2 + RESOURCE_BAR_HEIGHT
    if PortSettings.IS_MOBILE then
        self.targetY = self.targetY + MEASURES.MARGIN_SCREEN + RESOURCE_BAR_HEIGHT
    end

    self:setPosition(0, -self.alignHeight - MEASURES.MARGIN_SCREEN)
    self.moveSpeed = (self.targetY - self.position.y) / MOVE_DURATION
    self.alignment = UP
end

function WindowGameover:update(dt,...)
    WindowGameover:super(self, "update", dt, ...)
    if self.position.y < self.targetY then
        self:setPosition(0, min(self.targetY, self.position.y + self.moveSpeed * dt))
    end

end

return WindowGameover

