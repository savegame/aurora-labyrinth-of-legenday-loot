local Title = class("screens.screen")
local DirectorTitle = require("directors.title")
local Vector = require("utils.classes.vector")
local DrawCommand = require("utils.love2d.draw_command")
local Global = require("global")
local MEASURES = require("draw.measures")
function Title:initialize()
    Title:super(self, "initialize")
    Global:get(Tags.GLOBAL_AUDIO):playBGM("INTRO", 2)
    self:setServiceClass("director", DirectorTitle)
    self:preloadService("director")
    self.background = DrawCommand:new("title")
    self.background.origin = Vector:new(self.background:getDimensions())
    self.banner = DrawCommand:new("banner")
    self.banner.scale = 2
end

function Title:update(dt)
    Title:super(self, "update", dt)
    self:getService("director"):updateWidgets(dt)
end

function Title:onWindowModeChange()
    self:getService("director"):onWindowModeChange()
end

function Title:draw()
    Title:super(self, "draw")
    local scW, scH = self:getService("viewport"):getScreenDimensions()
    local iW, iH = self.background:getDimensions()
    local scale = scW / iW
    self.background.scale = scale
    Debugger.drawText(scH, scale, iH * scale)
        if scH > iH * scale then
        self.background:draw(scW, scH - (scH - iH * scale) / 2)
    elseif scH <= (iH - 16) * scale then
        self.background:draw(scW, scH + 8 * scale)
    else
        local extra = (iH * scale - scH) / 2
        self.background:draw(scW, scH + extra)
    end

    local director = self:getService("director")
    if (director.mainChoices and director.mainChoices.isVisible) or (director.difficultyChoices and director.difficultyChoices.isVisible) then
        self.banner:draw(MEASURES.MARGIN_TITLE, MEASURES.MARGIN_TITLE - 12)
    end

    director:drawWidgets()
end

return Title

