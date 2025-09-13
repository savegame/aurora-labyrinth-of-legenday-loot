local IconFlash = class("actions.components.component")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
local SHADERS = require("draw.shaders")
function IconFlash:initialize(action)
    IconFlash:super(self, "initialize", action)
    self.icon = false
    self.color = false
    self.image = false
    self.flash = false
    self.target = false
    self.originOffset = Vector.ORIGIN
end

function IconFlash:_create()
    Utils.assert(self.icon and self.color, "#color & #icon is required for IconFlash")
    local image = self:createEffect("image", "items")
    image.cellSize = MEASURES.ITEM_SIZE
    image.cell = self.icon
    image.position = self.target or self.action.entity.sprite
    image.originOffset = self.originOffset
    self.image = image
    self.flash = self:cloneEffect(image)
    self.flash.color = self.color
    self.flash.shader = SHADERS.SILHOUETTE
end

function IconFlash:chainFlashEvent(currentEvent, flashTime)
    return currentEvent:chainEvent(function()
        self:_create()
    end):chainProgress(flashTime, function(progress)
        self.flash.opacity = 1 - progress
    end)
end

function IconFlash:chainFadeEvent(currentEvent, fadeTime)
    return currentEvent:chainProgress(fadeTime, function(progress)
        self.image.opacity = 1 - progress
    end):chainEvent(function()
        self:_delete()
    end)
end

function IconFlash:display()
    self:_create()
    self.flash.opacity = 0
end

function IconFlash:_delete()
    self.image:delete()
    self.flash:delete()
end

return IconFlash

