local CharacterTrail = class("actions.components.component")
local TRAIL_FADE_SPEED = 6
local TRAIL_FADE_REPEAT = 0.025
local TRAIL_OPACITY = 0.6
function CharacterTrail:initialize(action)
    CharacterTrail:super(self, "initialize", action)
    self.silhouetteColor = false
    self.fadeTrail = false
end

function CharacterTrail:start(currentEvent)
    local fadeTrail = self:createEffect("fade_trail")
    fadeTrail.effect = self.action.entity.sprite
    fadeTrail.layer = Tags.LAYER_EFFECT_BELOW_CHARACTERS
    fadeTrail.fadeSpeed = TRAIL_FADE_SPEED
    fadeTrail.initialOpacity = TRAIL_OPACITY
    if self.silhouetteColor then
        fadeTrail.silhouetteColor = self.silhouetteColor
    end

    self.fadeTrail = fadeTrail
    return fadeTrail:chainTrailEvent(currentEvent, TRAIL_FADE_REPEAT)
end

function CharacterTrail:stop()
    if self.fadeTrail then
        self.fadeTrail:stopTrailEvent()
    end

end

return CharacterTrail

