require("utils")
require("utils.love2d")
Utils.loadAllLove()
Utils.disableDefaultRandomGenerator()
graphics.setDefaultFilter("nearest", "nearest")
graphics.setBackgroundColor(0, 0, 0)
require("port_settings")
require("debugger")
local Global = require("global")
local Profile = require("profile")
local Cursor = require("cursor")
local Audio = require("audio")
if DebugOptions.ENABLED then
    require("text.lore_amulet_victory")
end

function love.load()
    Global:set(Tags.GLOBAL_CURSOR, Cursor:new())
    Global:set(Tags.GLOBAL_PROFILE, Profile:new())
    Global:set(Tags.GLOBAL_AUDIO, Audio:new())
    Global:set(Tags.GLOBAL_CURRENT_SCREEN, require("screens.initial_loading"):new())
end

function love.update(dt)
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):updateWithDelta(dt)
end

function love.draw()
    local dpiScale = 1
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):drawFull()
    Debugger.draw()
end

function love.resize(...)
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("viewport"):refreshScreenDimensions()
end

function love.keypressed(key)
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):keyPressed(key)
end

function love.keyreleased(key)
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):keyReleased(key)
end

function love.mousepressed(x, y, button)
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):keyPressed("mouse_" .. button)
end

function love.mousereleased(x, y, button)
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):keyReleased("mouse_" .. button)
end

function love.quit()
    Global:get(Tags.GLOBAL_PROFILE):save()
    Global:get(Tags.GLOBAL_PROFILE):saveItemStats()
    Global:get(Tags.GLOBAL_CURRENT_SCREEN):onQuit()
end

if PortSettings.IS_MOBILE then
    function love.run()
        if love.load then
            love.load(love.arg.parseGameArguments(arg), arg)
        end

        local nextUpdateTime = timer.getTime()
        if love.timer then
            love.timer.step()
        end

        local dt = 0
        return function()
            if love.event then
                love.event.pump()
                for name, a, b, c, d, e, f in love.event.poll() do
                    if name == "quit" then
                        if not love.quit or not love.quit() then
                            return a or 0
                        end

                    end

                    love.handlers[name](a, b, c, d, e, f)
                end

            end

            if love.timer then
                dt = love.timer.step()
            end

            if love.update then
                love.update(dt)
            end

            if love.graphics and love.graphics.isActive() then
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())
                if love.auroraos then love.auroraos.begin_draw() end
                if love.draw then
                    love.draw()
                end
                if love.auroraos then love.auroraos.end_draw() end

                love.graphics.present()
            end

            nextUpdateTime = nextUpdateTime + 1 / 30
            local currentTime = timer.getTime()
            if nextUpdateTime > currentTime then
                love.timer.sleep(max(0.001, nextUpdateTime - currentTime))
            end

        end
    end

else
    function love.gamepadaxis(joystickObject, axis, value)
        Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):axisConvert(axis, value)
    end

    function love.gamepadpressed(joystickObject, button)
        Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):buttonPressed(button)
    end

    function love.gamepadreleased(joystickObject, button)
        Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):buttonReleased(button)
    end

    function love.joystickadded(joystickObject)
        Global:get(Tags.GLOBAL_PROFILE).controlModeGamepad = true
    end

    function love.joystickremoved(joystickObject)
        if joystick.getJoystickCount() <= 0 then
            Global:get(Tags.GLOBAL_PROFILE).controlModeGamepad = false
        end

    end

end


