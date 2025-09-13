local FadeTrail = class("effects.effect")
local Array = require("utils.classes.array")
local SHADERS = require("draw.shaders")
local Trail = struct("drawCommand", "timeCreated")
local DEFAULT_FADE_SPEED = 9
local EASING = require("draw.easing")
function FadeTrail:initialize(effect)
    FadeTrail:super(self, "initialize")
    self.layer = Tags.LAYER_EFFECT_BELOW_NORMAL
    self.effect = effect or false
    self.initialOpacity = 1
    self.trails = Array:new()
    self.deleteOnFade = false
    self.silhouetteColor = false
    self.color = false
    self.disableFilterOutline = false
    self.fadeSpeed = DEFAULT_FADE_SPEED
    self.preprocess = doNothing
    self._trailEvent = false
end

function FadeTrail:leaveTrail(currentTime)
    Utils.assert(self.effect, "FadeTrail requires #effect")
    if self.effect:isVisible() then
        local drawCommand = self.effect:getDrawCommandGrid(currentTime)
        self.preprocess(drawCommand)
        self.trails:push(Trail:new(drawCommand, currentTime))
    end

end

function FadeTrail:chainTrailEvent(event, repeatInterval)
    self._trailEvent = event:chainEvent(function(currentTime)
        self:leaveTrail(currentTime)
    end, repeatInterval)
    return self._trailEvent
end

function FadeTrail:stopTrailEvent(leaveAtTime)
    self._trailEvent:stop()
    if leaveAtTime then
        self:leaveTrail(leaveAtTime)
    end

    self.deleteOnFade = true
end

function FadeTrail:getTrailOpacity(trail, currentTime)
    local progress = ((currentTime - trail.timeCreated) * self.fadeSpeed) / self.initialOpacity
    return self.initialOpacity * (1 - progress)
end

function FadeTrail:draw(managerCoordinates, currentTime)
        if self.silhouetteColor then
        if self.disableFilterOutline then
            graphics.setShader(SHADERS.SILHOUETTE)
        else
            graphics.setShader(SHADERS.SILHOUETTE_NO_OUTLINE)
        end

    elseif not self.disableFilterOutline then
        graphics.setShader(SHADERS.FILTER_OUTLINE)
    end

    self.trails:rejectSelf(function(trail)
        return self:getTrailOpacity(trail, currentTime) <= 0
    end)
    for trail in self.trails() do
        local drawCommand = trail.drawCommand:clone()
        drawCommand.color = self.silhouetteColor or self.color or WHITE
        drawCommand.opacity = self:getTrailOpacity(trail, currentTime)
        drawCommand.position = managerCoordinates:gridToScreen(drawCommand.position)
        drawCommand:draw()
    end

    graphics.setShader()
    if self.deleteOnFade and self.trails:isEmpty() then
        self:delete()
    end

end

return FadeTrail

