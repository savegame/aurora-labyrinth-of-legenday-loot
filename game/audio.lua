local Audio = class()
local Hash = require("utils.classes.hash")
local MEASURES = require("draw.measures")
local SOUNDS = require("definitions.sounds")
local FADE_DURATION = MEASURES.COVER_FADE_DURATION * 2.5
local MUSIC_VOLUME_MULTIPLIER = 0.6
local SFX_VOLUME_MULTIPLIER = 0.9
local Global = require("global")
function Audio:initialize()
    self.currentBGM = false
    self.currentBGMVolume = 1
    self.fadingOut = false
    self.tempVolumeBGM = false
    self.tempVolumeSFX = false
    self.activeBGS = Hash:new()
end

function Audio:fadeoutCurrentBGM()
    if self.currentBGM then
        self.fadingOut = true
    end

end

function Audio:update(dt)
    if self.currentBGM then
        local sound = SOUNDS.BGM[self.currentBGM]
        if self.fadingOut then
            self.currentBGMVolume = self.currentBGMVolume - dt / FADE_DURATION
            if self.currentBGMVolume <= 0 then
                sound.source:stop()
                self.currentBGM = false
                self.fadingOut = false
                return 
            end

        end

        local profileVolume
        if self.tempVolumeBGM then
            profileVolume = self.tempVolumeBGM
        else
            profileVolume = Global:get(Tags.GLOBAL_PROFILE).volumeBGM
        end

        sound.source:setVolume(sound.origVolume * self.currentBGMVolume * profileVolume * MUSIC_VOLUME_MULTIPLIER)
    end

end

function Audio:playBGM(bgm, offset)
    if self.currentBGM == bgm then
        self.fadingOut = false
        self.currentBGMVolume = 1
        return 
    end

    if self.currentBGM then
        SOUNDS.BGM[self.currentBGM].source:stop()
    end

    self.currentBGM = bgm
    self.currentBGMVolume = 1
    self.fadingOut = false
    local sound = SOUNDS.BGM[bgm]
    Utils.assert(sound, "Unable to find BGM: %s", bgm)
    local profileVolume = Global:get(Tags.GLOBAL_PROFILE).volumeBGM
    sound.source:setVolume(sound.origVolume * profileVolume * MUSIC_VOLUME_MULTIPLIER)
    if offset then
        sound.source:seek(offset, "seconds")
    end

    sound.source:play()
end

function Audio:_getVolumeSFX()
    if self.tempVolumeSFX then
        return self.tempVolumeSFX
    else
        return Global:get(Tags.GLOBAL_PROFILE).volumeSFX
    end

end

function Audio:playSFX(sfx, pitchMultiplier, volumeMultiplier)
    local sound = SOUNDS.SFX[sfx]
    Utils.assert(sound, "Unable to find SFX: %s", sfx)
    if sound.source:isPlaying() then
        sound.source:stop()
    end

    pitchMultiplier = pitchMultiplier or 1
    volumeMultiplier = volumeMultiplier or 1
    local profileVolume = self:_getVolumeSFX()
    sound.source:setPitch(sound.origPitch * pitchMultiplier)
    sound.source:setVolume(sound.origVolume * volumeMultiplier * profileVolume * SFX_VOLUME_MULTIPLIER)
    if sound.source:isLooping() then
        self.activeBGS:set(sfx, volumeMultiplier)
    end

    sound.source:play()
    return sound.source
end

function Audio:stopBGS()
    for key, _ in self.activeBGS() do
        local sound = SOUNDS.SFX[key]
        if sound.source:isPlaying() then
            sound.source:stop()
        end

    end

end

function Audio:setTempVolumeSFX(value)
    self.tempVolumeSFX = value
    local profileVolume = self:_getVolumeSFX()
    for sfx, volumeMultiplier in self.activeBGS() do
        local sound = SOUNDS.SFX[sfx]
        sound.source:setVolume(sound.origVolume * volumeMultiplier * profileVolume * SFX_VOLUME_MULTIPLIER)
    end

end

function Audio:loadAllSounds()
    SOUNDS.load()
end

return Audio

