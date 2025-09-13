local Game = class("screens.screen")
local Set = require("utils.classes.set")
local Array = require("utils.classes.array")
local Level = require("structures.level")
local Global = require("global")
local LogicInitial = require("logic.initial")
local DirectorGame = require("directors.game")
local ActionScheduler = require("services.actionscheduler")
local drawTargeting = require("draw.targeting")
local TRIGGERS = require("actions.triggers")
local MEASURES = require("draw.measures")
function Game:initialize(generationLevel, isLoaded, showIntro, bgm, equipped, scrap)
    Game:super(self, "initialize")
    if bgm then
        Global:get(Tags.GLOBAL_AUDIO):playBGM(bgm)
    else
        Global:get(Tags.GLOBAL_AUDIO):fadeoutCurrentBGM()
    end

    local level = Level:new(generationLevel)
    local currentRun = Global:get(Tags.GLOBAL_CURRENT_RUN)
    self:setServiceClass("director", DirectorGame)
    self:setServiceClass("overseer", LogicInitial.getOverseerClass(currentRun.currentFloor))
    self:setServiceClass("parallelscheduler", ActionScheduler)
    self:provideServiceDependency("level", level)
    self:provideServiceDependency("run", currentRun)
    self:getService("tilemap"):drawCanvases()
    local player
    if isLoaded then
        self:getService("serializable"):loadAll()
        player = self:getService("player"):get()
        if not player then
            isLoaded = false
        end

    end

    if not isLoaded then
        player = self:createEntity("player", generationLevel.startPosition, currentRun.isFemale)
        player.sprite:turnToDirection(generationLevel.startDirection)
        if equipped then
            player.equipment:setFromHash(equipped)
        end

        player.tank:restoreToFull()
        if player.mana:getCurrent() ~= 0 then
            player.mana:restoreToFull()
        end

        if scrap then
            player.wallet:set(scrap)
        end

    end

    for position, object in (generationLevel:getObjects())() do
        self:createEntity(object.name, position, object.args:expand())
    end

    local director = self:getService("director")
    director:createWidgets(currentRun)
    if not isLoaded then
        player.vision:scan(player.body:getPosition())
        player.vision:refreshExplored()
        self:getService("overseer"):increaseTurn(false)
        local anchor = self:getService("actionscheduler"):createEvent()
        player.turn:startOfTurn(anchor)
        player.equipment:startOfTurn(anchor)
        player.triggers:parallelChainEvent(anchor, TRIGGERS.START_OF_TURN, false)
    else
        player.buffable.delayAllNonStart = true
    end

    if showIntro then
        director:publish(Tags.UI_SHOW_INTRO)
    end

    if not isLoaded then
        director:saveGame()
    end

end

function Game:getTimeMultiplier()
    local timeMultiplier = Game:super(self, "getTimeMultiplier")
    return timeMultiplier * self:getService("effects"):getSpeedMultiplier()
end

function Game:update(dt)
    Game:super(self, "update", dt)
    Debugger.startBenchmark("FULL_UPDATE")
    Debugger.drawText("Turn: " .. self:getService("overseer").currentTurn)
    self:getService("director"):updateWidgets(dt)
    self:getService("actionscheduler"):update()
    self:getService("parallelscheduler"):update()
    self:getService("effects"):update(dt)
    self:getSystem("vision"):update()
    self:getSystem("tank"):update(dt)
    self:getSystem("mana"):update(dt)
    self:getSystem("charactereffects"):update(dt)
    self:getSystem("perishable"):update(dt)
    self:getService("ambience"):update()
    Debugger.stopBenchmark("FULL_UPDATE")
end

function Game:getMousePosition()
    return self:getService("coordinates"):screenToGrid(self:getService("viewport"):getMousePosition())
end

local CHARACTER_LAYERS = Set:new(Tags.LAYER_BELOW_CHARACTERS, Tags.LAYER_CHARACTER, Tags.LAYER_ENGULF, Tags.LAYER_FLYING)
function Game:draw()
    Game:super(self, "draw")
    Debugger.startBenchmark("FULL_DRAW")
    local player = self:getSystem("player"):get()
    self:getService("coordinates").center = player.sprite:getDisplayPosition(true, true)
    self:getService("coordinates"):cacheGridToScreen()
    Debugger.startBenchmark("TILEMAP")
    self:getService("tilemap"):draw()
    Debugger.stopBenchmark("TILEMAP")
    local systemSprite = self:getSystem("sprite")
    local effects = self:getService("effects")
    local systemProjectile = self:getSystem("projectile")
    local castingGuide = self:getService("castingguide")
    Debugger.startBenchmark("SPRITES")
    Debugger.startBenchmark("SPRITES_1")
    systemSprite:cacheDisplayPositions()
    systemSprite:draw(Set:new(Tags.LAYER_STEPPABLE))
    if DebugOptions.DISPLAY_CASTER_RESERVED then
        self:getSystem("caster"):drawReservedGrid()
    end

    castingGuide:drawBelow()
    Debugger.stopBenchmark("SPRITES_1")
    Debugger.startBenchmark("SPRITES_2")
    self:getSystem("item"):draw()
    Debugger.stopBenchmark("SPRITES_2")
    systemProjectile:draw(true)
    Debugger.startBenchmark("SPRITES_3")
    systemSprite:drawShadows()
    Debugger.stopBenchmark("SPRITES_3")
    Debugger.startBenchmark("SPRITES_4")
    effects:draw(Tags.LAYER_EFFECT_BELOW_CHARACTERS)
    systemSprite:draw(CHARACTER_LAYERS)
    systemProjectile:draw(false)
    effects:draw(Tags.LAYER_EFFECT_BELOW_NORMAL)
    effects:draw(Tags.LAYER_EFFECT_NORMAL)
    systemSprite:draw(Set:new(Tags.LAYER_ABOVE_EFFECTS))
    Debugger.stopBenchmark("SPRITES_4")
    Debugger.stopBenchmark("SPRITES")
    if DebugOptions.DRAW_TARGETING then
        local position = self:getMousePosition()
        local args = Array:new("Mouse Grid:", position.x, position.y)
        local entityAt = self:getSystem("body"):getAt(position)
        if entityAt then
            args:push(entityAt:getPrefab())
            args:push(entityAt.serializable.id)
            if entityAt:hasComponent("agent") then
                args:push(entityAt.agent.hasActedThisTurn)
                args:push(entityAt.tank:isAlive())
            end

        end

        local steppables = self:getSystem("steppable").entities:get(position) or Array.EMPTY
        for steppable in steppables() do
            args:push(steppable:getPrefab())
            if steppable:hasComponent("serializable") then
                args:push(steppable.serializable.id)
            end

        end

        Debugger.drawText(args:expand())
        drawTargeting(self:getService("viewport"):getMousePosition(), self:getService("coordinates"))
    end

    self:getSystem("tank"):draw()
    self:getSystem("mana"):draw()
    self:getSystem("vision"):draw()
    effects:draw(Tags.LAYER_ABOVE_VISION)
    castingGuide:drawAbove()
    effects:drawScreenFlash()
    Debugger.startBenchmark("WIDGETS")
    self:getService("director"):drawWidgets()
    Debugger.stopBenchmark("WIDGETS")
    Debugger.stopBenchmark("FULL_DRAW")
end

function Game:onWindowModeChange()
    self:getService("tilemap"):drawCanvases()
    self:getService("director"):onWindowModeChange()
end

function Game:onQuit()
    local director = self:getService("director")
    if director:canDoTurn() then
        director:saveGame()
    end

end

function Game:extraDebuggingInfo()
    local director = self:getService("director")
    result = "Current Floor: " .. tostring(director.currentFloor) .. "\n"
    result = result .. "Current Seed: " .. tostring(director.currentRun.seed) .. "\n"
    result = result .. "Difficulty: " .. tostring(director.currentRun.difficulty) .. "\n"
    result = result .. "\nEquipment:\n"
    local player = self:getSystem("player"):get()
    for slot, item in player.equipment.equipped() do
        result = result .. ("%d: +%d %s\n"):format(slot, item.level, item.name)
    end

    result = result .. "\nActions: \n"
    if PortSettings.IS_MOBILE then
        local actionTextFull = Array:new()
        local actionTextLine = Array:new()
        local i = 0
        for action in director.actionList() do
            i = i + 1
            actionTextLine:push(action)
            if i == 8 then
                i = 0
                actionTextFull:push(actionTextLine:join(", "))
                actionTextLine = Array:new()
            end

        end

        if not actionTextLine:isEmpty() then
            actionTextFull:push(actionTextLine:join(", "))
        end

        result = result .. actionTextFull:join("\n") .. "\n"
    else
        result = result .. director.actionList:join("\n") .. "\n"
    end

    return result
end

return Game

