local Bite = class("actions.components.component")
local Vector = require("utils.classes.vector")
local EASING = require("draw.easing")
local BITE_STARTING_OFFSET = 0.375
local BITE_DISTANCE = 0.45
local BITE_FADE_SPEED = 7
local BITE_FADE_REPEAT = 0.02
function Bite:initialize(action)
    Bite:super(self, "initialize", action)
    self.imageUpper = false
    self.imageLower = false
    self.fadeTrailUpper = false
    self.fadeTrailLower = false
    self.trailEvent = false
    self.target = false
end

function Bite:createImages()
    Utils.assert(self.target, "Bite requires target position")
    self.imageUpper = self:createEffect("image", "teeth_upper")
    self.imageLower = self:createEffect("image", "teeth_lower")
    self.imageUpper.position = self.target
    self.imageLower.position = self.target
    self.imageUpper.offset = Vector:new(0, -BITE_STARTING_OFFSET)
    self.imageLower.offset = Vector:new(0, BITE_STARTING_OFFSET)
end

function Bite:_createFadeTrailForImage(image)
    local fadeTrail = self:createEffect("fade_trail")
    fadeTrail.effect = image
    fadeTrail.fadeSpeed = BITE_FADE_SPEED
    return fadeTrail
end

function Bite:_createFadeTrails(currentEvent)
    self.fadeTrailUpper = self:_createFadeTrailForImage(self.imageUpper)
    self.fadeTrailLower = self:_createFadeTrailForImage(self.imageLower)
    self.trailEvent = currentEvent:chainEvent(function(currentTime)
        self.fadeTrailUpper:leaveTrail(currentTime)
        self.fadeTrailLower:leaveTrail(currentTime)
    end, BITE_FADE_REPEAT)
end

function Bite:_stopFadeTrails(currentTime)
    self.trailEvent:stop()
    self.fadeTrailUpper:leaveTrail(currentTime)
    self.fadeTrailLower:leaveTrail(currentTime)
    self.fadeTrailUpper.deleteOnFade = true
    self.fadeTrailLower.deleteOnFade = true
end

function Bite:chainContactEvent(currentEvent, duration)
    return currentEvent:chainEvent(function(_, anchor)
        self:_createFadeTrails(anchor)
    end):chainProgress(duration, function(progress)
        self.imageUpper.offset = Vector:new(0, -BITE_STARTING_OFFSET + BITE_DISTANCE * progress)
        self.imageLower.offset = Vector:new(0, BITE_STARTING_OFFSET - BITE_DISTANCE * progress)
    end):chainEvent(function(currentTime)
        self:_stopFadeTrails(currentTime)
    end)
end

function Bite:deleteImages()
    self.imageUpper:delete()
    self.imageLower:delete()
end

return Bite

