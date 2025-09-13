local MessagePack = require("messagepack")
local FILENAMES = require("text.filenames")
local WINDOW_LIMITS = require("window_limits")
local function loadOptions()
    if love.filesystem.getInfo(FILENAMES.OPTIONS, "file") then
        local rawData, bytes = love.filesystem.read(FILENAMES.OPTIONS)
        local status, data = pcall(MessagePack.unpack, rawData)
        if status then
            return data
        end

    end

    return false
end

local FULLSCREEN_MODE_WINDOWED = 1
local FULLSCREEN_MODE_BORDERLESS = 2
local FULLSCREEN_MODE_EXCLUSIVE = 3
function love.conf(t)
    t.identity = "Labyrinth of Legendary Loot"
    t.appendidentity = true
    t.version = "11.4"
    t.accelerometerjoystick = false
    t.audio.mixwithsystem = false
    t.window.title = "Labyrinth of Legendary Loot"
    t.window.icon = "graphics/icon.png"
    love.filesystem.setIdentity(t.identity)
    local options = loadOptions()
    if options then
                if options.fullscreenMode == FULLSCREEN_MODE_BORDERLESS then
            t.window.fullscreen = true
            t.window.fullscreentype = "desktop"
        elseif options.fullscreenMode == FULLSCREEN_MODE_EXCLUSIVE then
            t.window.fullscreen = true
            t.window.fullscreentype = "exclusive"
            t.window.width = options.fullscreenWidth
            t.window.height = options.fullscreenHeight
        else
            t.window.fullscreen = false
            if options.windowRect then
                t.window.x = options.windowRect.x
                t.window.y = options.windowRect.y
                t.window.width = options.windowRect.width
                t.window.height = options.windowRect.height
                t.window.display = options.windowDisplay or 1
                t.window.resizable = false
            else
                t.window.width = WINDOW_LIMITS.DEFAULT_WIDTH
                t.window.height = WINDOW_LIMITS.DEFAULT_HEIGHT
            end

            t.window.minwidth = WINDOW_LIMITS.WIDTH
            t.window.minheight = WINDOW_LIMITS.HEIGHT
        end

    else
        t.window.fullscreen = true
        t.window.fullscreentype = "desktop"
    end

    t.window.width = WINDOW_LIMITS.WIDTH
    t.window.height = WINDOW_LIMITS.HEIGHT

    t.window.vsync = 1
    t.window.msaa = 0
    t.window.display = 1
    t.window.highdpi = false
    t.modules.physics = false
    t.modules.video = false
end


