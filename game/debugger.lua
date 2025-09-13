Debugger = {  }
require("debug_options")
local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local Set = require("utils.classes.set")
local Global = require("global")
function Debugger.assertComponent(entity, componentName)
    Utils.assert(entity:hasComponent(componentName), "Component '%s' is required", componentName)
end

Debugger.texts = Array:new()
Debugger.rects = Array:new()
Debugger.benchmarker = require("benchmarker"):new()
function Debugger.startBenchmark(timerName)
    Debugger.benchmarker:start(timerName)
end

function Debugger.stopBenchmark(timerName)
    Debugger.benchmarker:stop(timerName)
end

local FONTS = require("draw.fonts")
local DrawText = require("draw.text")
local DrawMethods = require("draw.methods")
function Debugger.drawText(...)
    if DebugOptions.DRAW_DEBUG_TEXT then
        local texts = Array:new(...)
        texts = texts:map(tostring)
        Debugger.texts:push(texts:join(" "))
    end

end

function Debugger.drawRect(...)
    Debugger.rects:push(Rect:new(...))
end

function Debugger.getTimeMultiplier()
    if Global:get(Tags.GLOBAL_CURRENT_SCREEN):getService("controls"):isPressed(Tags.KEYCODE_DEBUG_SLOW) then
        return DebugOptions.DEBUG_SLOW_MULTIPLIER
    else
        return 1
    end

end

function Debugger.draw()
    if DebugOptions.DISPLAY_BENCHMARKS then
        Debugger.texts:pushFirst("FPS: " .. timer.getFPS())
        local benchmarkStrings = Debugger.benchmarker:getAsStrings()
        Debugger.texts:concat(benchmarkStrings)
    end

    if not Debugger.texts:isEmpty() then
        local FONT = FONTS.SMALL
        if FONT.font then
            graphics.wSetColor(WHITE)
            graphics.wSetFont(FONT)
            for i, text in ipairs(Debugger.texts) do
                DrawText.draw(text, 8, (i - 1) * (FONT.heightFull + FONT.spaceLine) + 20)
            end

        end

        Debugger.texts:clear()
    end

    if not Debugger.rects:isEmpty() then
        graphics.wSetColor(1, 0.5, 0.5)
        for rect in Debugger.rects() do
            DrawMethods.lineRect(rect)
        end

        Debugger.rects:clear()
    end

    local testFont = false
    if testFont and testFont.font then
        local text = "ABCDefhipqjyg"
        graphics.wSetColor(1, 0, 0)
        graphics.wRectangle(0, 0, testFont:getWidth(text), testFont.height)
        graphics.wSetColor(WHITE)
        graphics.wSetFont(testFont)
        DrawText.draw(text, 0, 0)
    end

end

Debugger.log = print
function Debugger.printGlobalLeak()
    Debugger.log("-- Global Leak --")
    local added = Set:new()
    local globals = Utils.clone(_G)
    local dontInclude = Set:new("love", "os", "package", "math", "coroutine", "string", "tau", "_G", "pi", "phi", "io", "debug", "table", "bit", "jit", "arg", "huge")
    for k, v in pairs(globals) do
        if dontInclude:contains(k) then
            globals[k] = nil
        end

        if type(v) == "function" then
            globals[k] = nil
        end

        if love[k] == v then
            globals[k] = nil
        end

    end

    for k, v in pairs(globals) do
        Debugger.log(k, v)
    end

    Debugger.log("-----------------")
end

function Debugger.warn(warning)
    if DebugOptions.FAIL_ON_WARNING then
        Utils.assert(false, warning)
    else
        Debugger.log("WARNING: " .. warning)
    end

end

if not DebugOptions.ENABLED then
    local keys = table.keys(Debugger)
    print("Debug DISABLED")
    for key in keys() do
        if type(Debugger[key]) == "function" then
            Debugger[key] = alwaysFalse
        end

    end

    function Object:__index(key)
        if Object[key] then
            return Object[key]
        end

        return nil
    end

    Object.__newindex = nil
    print = doNothing
    Utils.assert = doNothing
end

local utf8 = require("utf8")
local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    msg = tostring(msg)
    error_printer(msg, 2)
    if not love.window or not love.graphics or not love.event then
        return 
    end

    if not love.graphics.isCreated() or not love.window.isOpen() then
        local success, status = pcall(love.window.setMode, 800, 600)
        if not success or not status then
            return 
        end

    end

    if love.mouse then
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
        love.mouse.setRelativeMode(false)
        if love.mouse.isCursorSupported() then
            love.mouse.setCursor()
        end

    end

    if love.joystick then
        for i, v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration()
        end

    end

    if love.audio then
        love.audio.stop()
    end

    love.graphics.reset()
    local font = love.graphics.setNewFont(14)
    love.graphics.setColor(1, 1, 1, 1)
    local trace = debug.traceback()
    love.graphics.origin()
    local sanitizedmsg = {  }
    for char in msg:gmatch(utf8.charpattern) do
        table.insert(sanitizedmsg, char)
    end

    sanitizedmsg = table.concat(sanitizedmsg)
    local err = {  }
    table.insert(err, "Error\n")
    table.insert(err, sanitizedmsg)
    if #sanitizedmsg ~= #msg then
        table.insert(err, "Invalid UTF-8 string in error message.")
    end

    table.insert(err, "\n")
    for l in trace:gmatch("(.-)\n") do
        if not l:match("boot.lua") then
            l = l:gsub("stack traceback:", "Traceback\n")
            table.insert(err, l)
        end

    end

    local p = table.concat(err, "\n")
    p = p:gsub("\t", "")
    p = p:gsub("%[string \"(.-)\"%]", "%1")
    filesystem.createDirectory("errors")
    local errorLog = p .. "\n\n\n" .. "Game Version: " .. tostring(PortSettings.GAME_VERSION) .. "\n\n" .. Global:get(Tags.GLOBAL_CURRENT_SCREEN):extraDebuggingInfo()
    local errFile = os.date("errors/%Y-%m-%d %H.%M.%S.log")
    if not PortSettings.IS_MOBILE then
        filesystem.write(errFile, errorLog)
    end

    local draw
    if not DebugOptions.ENABLED then
        local viewport = require("global"):get(Tags.GLOBAL_CURRENT_SCREEN):getService("viewport")
        local scW, scH = viewport:getScreenDimensions()
        local font = FONTS.MEDIUM
        local message
        if PortSettings.IS_MOBILE then
            message = "Fatal Error! Please send a screenshot to dominaxisgames@gmail.com"
            draw = function()
                graphics.wSetFont(font)
                graphics.push()
                graphics.scale(viewport:getScale())
                graphics.clear(0, 0, 0)
                graphics.print(message, 8, 8)
                graphics.scale(1 / viewport:getScale())
                graphics.print(errorLog, 8 * viewport:getScale(), (8 + font.height) * viewport:getScale() * 2)
                graphics.pop()
                graphics.present()
            end
        else
            local fullPath = filesystem.getSaveDirectory() .. "/" .. errFile
            local width = font:getWidth(fullPath)
            local height = font.height * 4 + 8 * 3
            local message = "Fatal Error!\n\nSaved error report to:\n" .. fullPath
            message = message .. "\nPlease send this file to dominaxisgames@gmail.com"
            draw = function()
                graphics.wSetFont(font)
                graphics.push()
                graphics.scale(viewport:getScale())
                graphics.clear(0, 0, 0)
                graphics.print(message, (scW - width) / 2 + font.offset.x, floor((scH - height) / 2 + font.offset.y) - 1)
                graphics.pop()
                graphics.present()
            end
        end

    else
        draw = function()
            local pos = 70
            graphics.clear(0.17, 0.35, 0.2)
            graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
            graphics.present()
        end
    end

    return function()
        love.event.pump()
        for e, a, b, c in love.event.poll() do
                                    if e == "quit" then
                return 1
            elseif e == "keypressed" and a == "escape" then
                return 1
            elseif e == "touchpressed" then
                local name = love.window.getTitle()
                if #name == 0 or name == "Untitled" then
                    name = "Game"
                end

                local buttons = { "OK", "Cancel" }
                local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", buttons)
                if pressed == 1 then
                    return 1
                end

            end

        end

        draw()
        if love.timer then
            love.timer.sleep(0.1)
        end

    end
end

return Debugger

