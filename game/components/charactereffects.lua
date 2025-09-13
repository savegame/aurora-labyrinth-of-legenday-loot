local CharacterEffects = require("components.create_class")()
local Array = require("utils.classes.array")
local Set = require("utils.classes.set")
local Common = require("common")
local COLORS = require("draw.colors")
local SHADERS = require("draw.shaders")
local DrawMethods = require("draw.methods")
local NEGATIVE_FADE = require("actions.constants").NEGATIVE_FADE_DURATION
function CharacterEffects:initialize(entity)
    CharacterEffects:super(self, "initialize")
    self._entity = entity
    self.tint = false
    self.negativeOverlay = 0
    self.flashOpacity = 0
    self.flashColor = WHITE
    self.flashSpeed = 1
    self.fillOpacity = 0
    self.fillColor = false
    self.outlineOpacity = 0
    self.outlineColor = false
    self.outlinePulseColorSources = Array:new()
    self.buffCounters = Array:new()
    self.outlinePulseMin = COLORS.INDICATION_MIN_OPACITY
    self.outlinePulseMax = COLORS.INDICATION_MAX_OPACITY
end

function CharacterEffects:addOutlinePulseColorSource(source)
    self.outlinePulseColorSources:push(source)
end

function CharacterEffects:flash(flashDuration, flashColor)
    self.flashSpeed = 1 / flashDuration
    self.flashOpacity = 1
    self.flashColor = flashColor or WHITE
end

function CharacterEffects:draw(drawCommand, timePassed)
    local tint = Utils.evaluate(self.tint, self._entity, timePassed)
    if tint then
        local command = drawCommand:clone()
        command.shader = SHADERS.SILHOUETTE_NO_OUTLINE
        command.color = tint
        command:draw()
    end

    for outlinePulseColorSource in self.outlinePulseColorSources() do
        local outlinePulseColor = Utils.evaluate(outlinePulseColorSource, self._entity, timePassed)
        if outlinePulseColor then
            local command = drawCommand:clone()
            command.shader = SHADERS.OUTLINE_AS_COLOR
            command.opacity = Common.getPulseOpacity(timePassed, self.outlinePulseMin, self.outlinePulseMax) * drawCommand.opacity
            command.color = outlinePulseColor
            command:draw()
        end

    end

    if self.outlineColor then
        local command = drawCommand:clone()
        command.shader = SHADERS.OUTLINE_AS_COLOR
        command.opacity = self.outlineOpacity
        command.color = self.outlineColor
        command:draw()
    end

    if self.negativeOverlay > 0 then
        local command = drawCommand:clone()
        command.shader = SHADERS.INVERT
        command.opacity = self.negativeOverlay
        command:draw()
    end

    if self.flashOpacity > 0 then
        local command = drawCommand:clone()
        command.shader = SHADERS.SILHOUETTE
        command.color = self.flashColor
        command.opacity = self.flashOpacity
        command:draw()
    end

    if self.fillColor then
        local command = drawCommand:clone()
        command.shader = SHADERS.SILHOUETTE
        command.color = self.fillColor
        command.opacity = self.fillOpacity
        command:draw()
    end

end

function CharacterEffects.System:initialize()
    CharacterEffects.System:super(self, "initialize")
    self.storageClass = Set
end

function CharacterEffects.System:update(dt)
    for entity in self.entities() do
        local characterEffects = entity.charactereffects
        if characterEffects.negativeOverlay > 0 then
            characterEffects.negativeOverlay = max(0, characterEffects.negativeOverlay - dt / NEGATIVE_FADE)
        end

        if characterEffects.flashOpacity > 0 then
            characterEffects.flashOpacity = max(0, characterEffects.flashOpacity - dt * characterEffects.flashSpeed)
        end

    end

end

return CharacterEffects

