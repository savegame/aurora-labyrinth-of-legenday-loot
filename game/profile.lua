local Profile = class()
Tags.add("KEYCODE_LEFT", 4)
Tags.add("KEYCODE_UP", 8)
Tags.add("KEYCODE_RIGHT", 6)
Tags.add("KEYCODE_DOWN", 2)
Tags.add("KEYCODE_WAIT", 11)
Tags.add("KEYCODE_CONFIRM", 12)
Tags.add("KEYCODE_CANCEL", 13)
Tags.add("KEYCODE_ABILITY_1", 21)
Tags.add("KEYCODE_ABILITY_2", 22)
Tags.add("KEYCODE_ABILITY_3", 23)
Tags.add("KEYCODE_ABILITY_4", 24)
Tags.add("KEYCODE_ABILITY_5", 25)
Tags.add("KEYCODE_EQUIPMENT", 31)
Tags.add("KEYCODE_KEYWORDS", 32)
Tags.add("KEYCODE_DEBUG_SLOW", 41)
Tags.add("FULLSCREEN_MODE_WINDOWED", 1)
Tags.add("FULLSCREEN_MODE_BORDERLESS", 2)
Tags.add("FULLSCREEN_MODE_EXCLUSIVE", 3)
Tags.add("TUTORIAL_FREQUENCY_ONCE", 1)
Tags.add("TUTORIAL_FREQUENCY_NEVER", 2)
Tags.add("TUTORIAL_FREQUENCY_ALWAYS", 3)
Tags.add("CHARACTER_RANDOM", 1)
Tags.add("CHARACTER_MALE", 2)
Tags.add("CHARACTER_FEMALE", 3)
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local Rect = require("utils.classes.rect")
local Global = require("global")
local FILENAMES = require("text.filenames")
local TERMS = require("text.terms")
local WINDOW_LIMITS = require("window_limits")
local MessagePack = require("messagepack")
local MorgueEntry = require("structures.morgue_entry")
local ItemStats = require("structures.item_stats")
local ITEMS = require("definitions.items")
function Profile:initialize()
    local data = {  }
    if filesystem.getInfo(FILENAMES.OPTIONS, "file") then
        local rawData, bytes = filesystem.read(FILENAMES.OPTIONS)
        local status
        status, data = pcall(MessagePack.unpack, rawData)
        if not status then
            data = {  }
        end

    end

    self:setNonControlWithData(data)
    self:setControlWithData(data)
    self:loadMorgue()
    self:loadItemStats()
    self:loadPlayData()
    if self.fullscreenMode == Tags.FULLSCREEN_MODE_WINDOWED then
        if self.windowIsMaximized then
            window.maximize()
        end

    end

end

function Profile:setNonControlWithData(data)
    self.fullscreenMode = data.fullscreenMode or Tags.FULLSCREEN_MODE_BORDERLESS
    self.fullscreenWidth = data.fullscreenWidth or 1280
    self.fullscreenHeight = data.fullscreenHeight or 720
    self.windowRect = false
    self.windowIsMaximized = false
    if data.windowRect then
        self.windowRect = Rect:new(data.windowRect.x, data.windowRect.y, data.windowRect.width, data.windowRect.height)
        self.windowIsMaximized = toBoolean(data.windowIsMaximized)
    end

    self.windowDisplay = data.windowDisplay or 1
    self.volumeBGM = data.volumeBGM or 0.5
    self.volumeSFX = data.volumeSFX or 0.5
    self.tutorialFrequency = data.tutorialFrequency or Tags.TUTORIAL_FREQUENCY_ONCE
    self.character = data.character or Tags.CHARACTER_RANDOM
    self.controlSize = data.controlSize or 6
end

function Profile:setControlWithData(data)
    self.controlModeGamepad = data.controlModeGamepad or false
    self.codeToKey = Hash:new()
    self.codeToKey:set(Tags.KEYCODE_LEFT, "left")
    self.codeToKey:set(Tags.KEYCODE_UP, "up")
    self.codeToKey:set(Tags.KEYCODE_RIGHT, "right")
    self.codeToKey:set(Tags.KEYCODE_DOWN, "down")
    self.codeToKey:set(Tags.KEYCODE_CONFIRM, "space")
    self.codeToKey:set(Tags.KEYCODE_CANCEL, "escape")
    self.codeToKey:set(Tags.KEYCODE_EQUIPMENT, "e")
    self.codeToKey:set(Tags.KEYCODE_WAIT, "w")
    self.codeToKey:set(Tags.KEYCODE_KEYWORDS, "r")
    self.codeToKey:set(Tags.KEYCODE_ABILITY_1, "1")
    self.codeToKey:set(Tags.KEYCODE_ABILITY_2, "2")
    self.codeToKey:set(Tags.KEYCODE_ABILITY_3, "3")
    self.codeToKey:set(Tags.KEYCODE_ABILITY_4, "4")
    self.codeToKey:set(Tags.KEYCODE_ABILITY_5, "5")
    self.codeToKey:set(Tags.KEYCODE_DEBUG_SLOW, "lctrl")
    if data.codeToKey then
        for key, value in pairs(data.codeToKey) do
            self.codeToKey:set(key, value)
        end

    end

    self.codeToButton = Hash:new()
    self.codeToButton:set(Tags.KEYCODE_LEFT, "leftx-")
    self.codeToButton:set(Tags.KEYCODE_UP, "lefty-")
    self.codeToButton:set(Tags.KEYCODE_RIGHT, "leftx+")
    self.codeToButton:set(Tags.KEYCODE_DOWN, "lefty+")
    self.codeToButton:set(Tags.KEYCODE_CONFIRM, "a")
    self.codeToButton:set(Tags.KEYCODE_CANCEL, "b")
    self.codeToButton:set(Tags.KEYCODE_EQUIPMENT, "start")
    self.codeToButton:set(Tags.KEYCODE_WAIT, "y")
    self.codeToButton:set(Tags.KEYCODE_KEYWORDS, "back")
    self.codeToButton:set(Tags.KEYCODE_ABILITY_1, "x")
    self.codeToButton:set(Tags.KEYCODE_ABILITY_2, "leftshoulder")
    self.codeToButton:set(Tags.KEYCODE_ABILITY_3, "rightshoulder")
    self.codeToButton:set(Tags.KEYCODE_ABILITY_4, "triggerleft+")
    self.codeToButton:set(Tags.KEYCODE_ABILITY_5, "triggerright+")
    self.codeToButton:set(Tags.KEYCODE_DEBUG_SLOW, "rightstick")
    if data.codeToButton then
        for key, value in pairs(data.codeToButton) do
            self.codeToButton:set(key, value)
        end

    end

end

function Profile:getKeyName(code, profileField)
    if not profileField then
        if self.controlModeGamepad then
            profileField = "codeToButton"
        else
            profileField = "codeToKey"
        end

    end

    local key = self[profileField]:get(code, " ")
    if TERMS.CONTROLS[key] then
        return TERMS.CONTROLS[key]
    else
        return key:sub(1, 1):upper() .. key:sub(2)
    end

end

function Profile:clone()
    local result = Profile:super(self, "clone")
    result.codeToKey = self.codeToKey:clone()
    result.codeToButton = self.codeToButton:clone()
    return result
end

function Profile:isNonControlEqual(other)
        if self.fullscreenMode ~= other.fullscreenMode then
        return false
    elseif self:shouldApplyDimensions() then
                if self.fullscreenWidth ~= other.fullscreenWidth then
            return false
        elseif self.fullscreenHeight ~= other.fullscreenHeight then
            return false
        end

    end

    if self.volumeSFX ~= other.volumeSFX then
        return false
    end

    if self.volumeBGM ~= other.volumeBGM then
        return false
    end

    if self.tutorialFrequency ~= other.tutorialFrequency then
        return false
    end

    if self.character ~= other.character then
        return false
    end

    if self.controlSize ~= other.controlSize then
        return false
    end

    return true
end

function Profile:shouldApplyDimensions()
    return self.fullscreenMode == Tags.FULLSCREEN_MODE_EXCLUSIVE or self.fullscreenMode == Tags.FULLSCREEN_MODE_WINDOWED
end

function Profile:applyNonControls(newProfile)
    local shouldRefresh = self.fullscreenMode ~= newProfile.fullscreenMode
    self.volumeSFX = newProfile.volumeSFX
    self.volumeBGM = newProfile.volumeBGM
    self.tutorialFrequency = newProfile.tutorialFrequency
    self.character = newProfile.character
    self.controlSize = newProfile.controlSize
    if self:shouldApplyDimensions() then
        shouldRefresh = shouldRefresh or (self.fullscreenWidth ~= newProfile.fullscreenWidth)
        shouldRefresh = shouldRefresh or (self.fullscreenHeight ~= newProfile.fullscreenHeight)
    end

    self.fullscreenWidth = newProfile.fullscreenWidth
    self.fullscreenHeight = newProfile.fullscreenHeight
    self.fullscreenMode = newProfile.fullscreenMode
    if shouldRefresh then
        local flags = {  }
        local width, height = 0, 0
                if self.fullscreenMode == Tags.FULLSCREEN_MODE_EXCLUSIVE then
            flags.fullscreen = true
            flags.fullscreentype = "exclusive"
            width, height = self.fullscreenWidth, self.fullscreenHeight
        elseif self.fullscreenMode == Tags.FULLSCREEN_MODE_BORDERLESS then
            flags.fullscreen = true
            flags.fullscreentype = "desktop"
        else
            flags.fullscreen = false
            flags.minwidth = WINDOW_LIMITS.WIDTH
            flags.minheight = WINDOW_LIMITS.HEIGHT
            flags.resizable = false
            local _x, _y, currentDisplay = window.getPosition()
            local dw, dh = window.getDesktopDimensions(currentDisplay)
            width, height = self.fullscreenWidth, self.fullscreenHeight
            flags.x = floor((dw - width) / 2)
            flags.y = floor((dh - height) / 2)
        end

        window.setMode(width, height, flags)
        local currentScreen = Global:get(Tags.GLOBAL_CURRENT_SCREEN)
        currentScreen:getService("viewport"):refreshScreenDimensions()
        currentScreen:onWindowModeChange()
    end

end

function Profile:assignWindowProperties()
    self.windowIsMaximized = window.isMaximized()
    local width, height = graphics.getDimensions()
    local x, y, display = window.getPosition()
    self.windowRect = Rect:new(x, y, width, height)
    self.windowDisplay = display
end

function Profile:save()
    if self.fullscreenMode == Tags.FULLSCREEN_MODE_WINDOWED then
        self:assignWindowProperties()
    end

    local data = { fullscreenMode = self.fullscreenMode, fullscreenWidth = self.fullscreenWidth, fullscreenHeight = self.fullscreenHeight, volumeSFX = self.volumeSFX, volumeBGM = self.volumeBGM, tutorialFrequency = self.tutorialFrequency, character = self.character, controlSize = self.controlSize, windowDisplay = self.windowDisplay, windowIsMaximized = self.windowIsMaximized, codeToKey = self.codeToKey.container, codeToButton = self.codeToButton.container, controlModeGamepad = self.controlModeGamepad }
    if self.windowRect then
        data.windowRect = { x = self.windowRect.x, y = self.windowRect.y, width = self.windowRect.width, height = self.windowRect.height }
    end

    filesystem.write(FILENAMES.OPTIONS, MessagePack.pack(data))
end

local function morgueCompare(a, b)
    local scoreA = a:getScore()
    local scoreB = b:getScore()
    if scoreA == scoreB then
        return a.endTime > b.endTime
    else
        return scoreA > scoreB
    end

end

function Profile:addMorgueEntry(entry)
    self.morgueEntries:push(entry)
    self.morgueEntries:stableSortSelf(morgueCompare)
    self:saveMorgue()
end

function Profile:saveMorgue()
    filesystem.write(FILENAMES.MORGUE, MessagePack.pack(self.morgueEntries:map(function(entry)
        return entry:toData()
    end)))
end

function Profile:loadMorgue()
    self.morgueEntries = Array:new()
    if filesystem.getInfo(FILENAMES.MORGUE, "file") then
        local rawData, bytes = filesystem.read(FILENAMES.MORGUE)
        local status, data
        status, data = pcall(MessagePack.unpack, rawData)
        if not status then
            data = {  }
        end

        self.morgueEntries = Array:convert(data):map(function(data)
            return MorgueEntry:new(data)
        end)
        self.morgueEntries:stableSortSelf(morgueCompare)
    end

end

function Profile:loadItemStats()
    self.itemStats = Hash:new()
    if filesystem.getInfo(FILENAMES.ITEM_STATS, "file") then
        local rawData, bytes = filesystem.read(FILENAMES.ITEM_STATS)
        local status, data = pcall(MessagePack.unpack, rawData)
        if status then
            for key, itemData in pairs(data) do
                self.itemStats:set(key, ItemStats:new(itemData))
            end

        end

    end

    if self.itemStats:isEmpty() then
        for k, _ in pairs(ITEMS.BY_ID) do
            self.itemStats:set(k, ItemStats:new())
        end

    end

end

function Profile:recordItemStats(equipped, key)
    for slot, item in equipped() do
        local itemStats = self.itemStats:get(item.definition.saveKey)
        itemStats[key] = itemStats[key] + 1
    end

end

function Profile:recordCast(item)
    local itemStats = self.itemStats:get(item.definition.saveKey)
    itemStats.timesCastedAbility = itemStats.timesCastedAbility + 1
end

function Profile:recordSeen(item)
    local itemStats = self.itemStats:get(item.definition.saveKey)
    if item:isLegendary() then
        itemStats.timesSeenLegendary = itemStats.timesSeenLegendary + 1
    else
        itemStats.timesSeenNormal = itemStats.timesSeenNormal + 1
    end

end

function Profile:saveItemStats()
    filesystem.write(FILENAMES.ITEM_STATS, MessagePack.pack(self.itemStats:mapValues(function(itemStat)
        return itemStat:toData()
    end).container))
end

function Profile:loadPlayData()
    self.playData = Hash:new()
    self.playData:set("unlockedComplex", false)
    self.playData:set("unlockedDifficulty", Tags.DIFFICULTY_HARD)
    if filesystem.getInfo(FILENAMES.PLAY_DATA, "file") then
        local rawData, bytes = filesystem.read(FILENAMES.PLAY_DATA)
        local status, data = pcall(MessagePack.unpack, rawData)
        if status then
            self.playData:set("unlockedComplex", data.unlockedComplex or false)
            self.playData:set("unlockedDifficulty", data.unlockedDifficulty or Tags.DIFFICULTY_HARD)
        end

    end

end

function Profile:savePlayData()
    filesystem.write(FILENAMES.PLAY_DATA, MessagePack.pack(self.playData.container))
end

function Profile:discoverItem(item)
    local key = item.definition.saveKey
    if not self.itemStats:hasKey(key) then
        self.itemStats:set(key, ItemStats:new())
    end

    self.itemStats:get(key):discoverItem(item)
end

function Profile:applyNonControlsAndSave(newProfile)
    self:applyNonControls(newProfile)
    self:save()
end

function Profile:applyControlsAndSave(newProfile, field)
    self[field] = newProfile[field]:clone()
    self:save()
end

return Profile

