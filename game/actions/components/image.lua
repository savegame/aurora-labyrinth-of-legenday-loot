local Image = class("actions.components.component")
local Array = require("utils.classes.array")
function Image:initialize(action)
    Image:super(self, "initialize", action)
    self.images = Array:new()
    self.trails = Array:new()
end

function Image:create(filename)
    local image = self:createEffect("image", filename)
    image.position = self.action.entity.body:getPosition()
    image.direction = self.action.direction
    self.images:push(image)
    return image
end

function Image:createWithTrail(filename)
    local image = self:create(filename)
    local fadeTrail = self:createEffect("fade_trail")
    fadeTrail.effect = image
    fadeTrail.disableFilterOutline = true
    self.trails:push(fadeTrail)
    return image, fadeTrail
end

function Image:deleteImages()
    for image in self.images() do
        image:delete()
    end

end

function Image:stopAllTrails(currentTime)
    for trail in self.trails() do
        trail:stopTrailEvent(currentTime)
    end

end

return Image

