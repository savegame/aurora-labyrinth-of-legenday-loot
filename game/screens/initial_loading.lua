local InitialLoading = class("screens.screen")
local FONTS = require("draw.fonts")
local Array = require("utils.classes.array")
local Global = require("global")
local LoadingAnimation = require("draw.loading_animation")
local TIME_BEFORE_UPDATE = 1 / 100
local function loadingCoroutine()
    local images = Array:Convert(filesystem.getDirectoryItems("graphics"))
    local tiles = Array:Convert(filesystem.getDirectoryItems("graphics/tiles"))
    images:concat(tiles:map(function(tile)
        return "tiles/" .. tile
    end))
    for image in images() do
        if filesystem.getInfo("graphics/" .. image, "file") then
            Utils.loadImage(image:split(".")[1])
            coroutine.yield()
        end

    end

    coroutine.yield()
    Global:get(Tags.GLOBAL_AUDIO):loadAllSounds()
    coroutine.yield()
    FONTS.load()
    coroutine.yield()
end

function InitialLoading:initialize()
    InitialLoading:super(self, "initialize")
    self.loadingAnimation = LoadingAnimation:new()
    self.loadingCoroutine = coroutine.create(loadingCoroutine)
end

function InitialLoading:update(dt)
    InitialLoading:super(self, "update", dt)
    self.loadingAnimation:update(dt)
    local currentTime = timer.getTime()
    while timer.getTime() - currentTime < TIME_BEFORE_UPDATE do
        if coroutine.status(self.loadingCoroutine) == "dead" then
            local INITIAL_SCREEN = require("screens." .. DebugOptions.INITIAL_SCREEN)
            Global:set(Tags.GLOBAL_CURRENT_SCREEN, INITIAL_SCREEN:new())
        else
            Utils.assert(coroutine.resume(self.loadingCoroutine))
        end

    end

end

function InitialLoading:getCoverDuration()
    return 0
end

function InitialLoading:draw()
    InitialLoading:super(self, "draw")
    self.loadingAnimation:draw(self:getService("viewport"))
end

return InitialLoading

