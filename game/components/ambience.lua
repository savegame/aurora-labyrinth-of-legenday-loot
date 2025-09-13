local Ambience = require("components.create_class")()
local Common = require("common")
local UniqueList = require("utils.classes.unique_list")
local Hash = require("utils.classes.hash")
local Set = require("utils.classes.set")
function Ambience:initialize(entity, sound)
    Ambience:super(self, "initialize")
    self._entity = entity
    self.sound = sound
end

function Ambience.System:initialize()
    Ambience.System:super(self, "initialize")
    self.storageClass = UniqueList
    self.soundsPlaying = Hash:new()
    self:setDependencies("vision")
end

function Ambience.System:update()
    local soundsToPlay = Set:new()
    for entity in self.entities() do
        local position = Common.getPositionComponent(entity):getPosition()
        if self.services.vision:isVisibleForDisplay(position) then
            soundsToPlay:add(entity.ambience.sound)
        end

    end

    for sound in soundsToPlay() do
        if not self.soundsPlaying:hasKey(sound) then
            self.soundsPlaying:set(sound, Common.playSFX(sound))
        end

    end

    self.soundsPlaying:rejectEntriesSelf(function(sound, source)
        if soundsToPlay:contains(sound) then
            return false
        else
            source:stop()
            return true
        end

    end)
end

return Ambience

