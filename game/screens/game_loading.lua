local GameLoading = class("screens.screen")
local Global = require("global")
local ScreenGame = require("screens.game")
local Run = require("structures.run")
local LogicInitial = require("logic.initial")
local CONSTANTS = require("logic.constants")
local GenerateFloorCommand = require("generation.generate_floor_command")
local FLOORS = require("definitions.floors")
local LoadingAnimation = require("draw.loading_animation")
local WARNING_FONT = require("draw.fonts").MEDIUM
local DrawText = require("draw.text")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local TIME_BEFORE_UPDATE = 1 / 100
local MAX_WAIT_BEFORE_AD = 3 * 60
function GameLoading:initialize(isLoaded, equipped, scrap)
    GameLoading:super(self, "initialize")
    self.loadingAnimation = LoadingAnimation:new()
    self.showIntro = false
    self.isLoaded = isLoaded or false
    self.equipped = equipped or false
    self.scrap = scrap or false
    local profile = Global:get(Tags.GLOBAL_PROFILE)
    local currentRun = Global:get(Tags.GLOBAL_CURRENT_RUN, false)
    if not currentRun then
        currentRun = LogicInitial.createNewRun(Tags.DIFFICULTY_NORMAL)
        self.equipped = LogicInitial.getInitialItems(currentRun)
        self.scrap = CONSTANTS.SCRAP_INITIAL
    end

    if not isLoaded then
        if currentRun.currentFloor == 1 then
            self.equipped = LogicInitial.getInitialItems(currentRun)
            self.scrap = CONSTANTS.SCRAP_INITIAL
            if profile.tutorialFrequency == Tags.TUTORIAL_FREQUENCY_ONCE then
                profile.tutorialFrequency = Tags.TUTORIAL_FREQUENCY_NEVER
                profile:save()
            end

            self.showIntro = true
        end

    end

    if not profile.playData:get("unlockedComplex") and currentRun.currentFloor >= CONSTANTS.FLOOR_UNLOCK_COMPLEX then
        Debugger.log("Unlocked Complex Items")
        profile.playData:set("unlockedComplex", true)
        profile:savePlayData()
    end

    Debugger.log("Current Floor: ", currentRun.currentFloor)
    local generateCommand = GenerateFloorCommand:new()
    generateCommand.seed = currentRun:getCurrentFloorSeed()
    generateCommand.yieldCallback = coroutine.yield
    generateCommand.difficulty = currentRun.difficulty
    generateCommand.unlockComplex = profile.playData:get("unlockedComplex")
    generateCommand.display = false
    local floorDef = FLOORS[currentRun.currentFloor]
    floorDef:configureGenerateCommand(generateCommand, isLoaded)
    self.bgm = floorDef.bgm
    currentRun:setGenerateSpecialFields(generateCommand)
    self.level = generateCommand:createLevel()
    self.generateCoroutine = coroutine.create(generateCommand.generate)
    Utils.assert(coroutine.resume(self.generateCoroutine, generateCommand))
end

function GameLoading:getCoverDuration()
    return 0
end

function GameLoading:isCoroutineDead()
    return coroutine.status(self.generateCoroutine) == "dead"
end

function GameLoading:update(dt)
    GameLoading:super(self, "update", dt)
    self.loadingAnimation:update(dt)
    if not self:isCoroutineDead() then
        local currentTime = timer.getTime()
        while timer.getTime() - currentTime < TIME_BEFORE_UPDATE do
            Utils.assert(coroutine.resume(self.generateCoroutine))
            if self:isCoroutineDead() then
                collectgarbage()
                break
            end

        end

    else
        Global:get(Tags.GLOBAL_AUDIO):loadAllSounds()
        Global:set(Tags.GLOBAL_CURRENT_SCREEN, ScreenGame:new(self.level, self.isLoaded, self.showIntro, self.bgm, self.equipped, self.scrap))
    end

end

function GameLoading:draw()
    GameLoading:super(self, "draw")
    self.loadingAnimation:draw(self:getService("viewport"))
end

return GameLoading

