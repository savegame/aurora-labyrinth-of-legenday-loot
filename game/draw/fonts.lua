local FONTS = {  }
FONTS.Font = class()
local Vector = require("utils.classes.vector")
local FONTS_BY_USERDATA = {  }
function FONTS.Font:initialize(fontName, fontSize, height, heightFull)
    self.fontName = fontName
    self.fontSize = fontSize
    self.height = height
    self.heightFull = heightFull
    self.heightMeasure = (self.height + self.heightFull) / 2
    self.offset, self.spaceLine, self.spaceParagraph = false, false, false
    self.scale = 1
    self.font = false
end

function FONTS.Font:loadFont()
    if PortSettings.IS_MOBILE then
        self.font = graphics.newFont("graphics/fonts/mobile/sp_" .. self.fontName .. ".ttf", self.fontSize)
    else
        self.font = graphics.newFont("graphics/fonts/" .. self.fontName .. ".ttf", self.fontSize)
    end

    FONTS_BY_USERDATA[self.font] = self
end

function FONTS.Font:getWidth(text)
    return self.font:getWidth(text) - self.scale
end

function FONTS.Font:getStrokedWidth(text)
    return self.font:getWidth(text) - self.scale + 2
end

function FONTS.Font:getStrokedHeight()
    return self.height + 2
end

FONTS.LARGE = FONTS.Font:new("pressstart2p", 8, 7, 12)
FONTS.LARGE.offset = Vector:new(0, 0)
FONTS.LARGE.spaceLine, FONTS.LARGE.spaceParagraph = 5, 10
FONTS.LARGE_2 = FONTS.Font:new("pressstart2p", 24, 21, 36)
FONTS.LARGE_2.offset = Vector:new(0, 0)
FONTS.LARGE_2.spaceLine, FONTS.LARGE.spaceParagraph = 5, 10
if PortSettings.IS_MOBILE then
    FONTS.MEDIUM = FONTS.Font:new("standard", 16, 7, 9)
    FONTS.MEDIUM.offset = Vector:new(0, -4)
    FONTS.MEDIUM.spaceLine, FONTS.MEDIUM.spaceParagraph = 5, 9
else
    FONTS.MEDIUM = FONTS.Font:new("sixel", 16, 6, 8)
    FONTS.MEDIUM.offset = Vector:new(0, -5)
    FONTS.MEDIUM.spaceLine, FONTS.MEDIUM.spaceParagraph = 4, 8
end

FONTS.MEDIUM_2 = FONTS.Font:new("sixel", 32, 12, 16)
FONTS.MEDIUM_2.scale = 2
FONTS.MEDIUM_2.offset = Vector:new(0, -10)
FONTS.MEDIUM_2.spaceLine, FONTS.MEDIUM_2.spaceParagraph = 8, 16
FONTS.MEDIUM_BOLD = FONTS.Font:new("sixelbold", 16, 6, 8)
FONTS.MEDIUM_BOLD.offset = Vector:new(0, -5)
FONTS.MEDIUM_BOLD.spaceLine, FONTS.MEDIUM_BOLD.spaceParagraph = 3, 8
FONTS.MEDIUM_BOLD_2 = FONTS.Font:new("sixelbold", 32, 12, 16)
FONTS.MEDIUM_BOLD_2.scale = 2
FONTS.MEDIUM_BOLD_2.offset = Vector:new(0, -10)
FONTS.MEDIUM_BOLD_2.spaceLine, FONTS.MEDIUM_BOLD.spaceParagraph = 8, 16
FONTS.SMALL = FONTS.Font:new("munroedited", 10, 5, 5)
FONTS.SMALL.offset = Vector:new(0, -5)
FONTS.SMALL.spaceLine, FONTS.SMALL.spaceParagraph = 3, 5
FONTS.SMALL_2 = FONTS.Font:new("munroedited", 20, 10, 10)
FONTS.SMALL_2.scale = 2
FONTS.SMALL_2.offset = Vector:new(0, -9)
FONTS.SMALL_2.spaceLine, FONTS.SMALL_2.spaceParagraph = 6, 10
function FONTS.load()
    for _, font in pairs(FONTS) do
        if FONTS.Font:isInstance(font) then
            font:loadFont()
        end

    end

end

function FONTS.get()
    local userdataFont = graphics.getFont()
    local font = FONTS_BY_USERDATA[userdataFont]
    Utils.assert(font, "No currently set font")
    return font
end

function graphics.wSetFont(font)
    if FONTS.Font:isInstance(font) then
        return graphics.setFont(font.font)
    end

    return graphics.setFont(font)
end

return FONTS

