local Offset = require("components.create_class")()
local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local OFFSET_MOD = Vector:new(1, require("draw.measures").Y_OFFSET_MOD)
local Profile = struct("bodyScrolling", "body", "jump", "disableModY")
function Offset:initialize(entity)
    Offset:super(self, "initialize")
    self.defaultDisableModY = false
    self.profiles = Array:new()
end

function Offset:createProfile()
    local result = Profile:new(Vector.ORIGIN, Vector.ORIGIN, 0)
    result.disableModY = self.defaultDisableModY
    self.profiles:push(result)
    return result
end

function Offset:deleteProfile(profile)
    self.profiles:delete(profile)
end

function Offset:getLastProfile()
    return self.profiles:last()
end

function Offset:deleteLastProfile()
    self.profiles:pop()
end

function Offset:getTotal(excludeJump, excludeBody)
    local total = Vector.ORIGIN
    for profile in self.profiles() do
        total = total + profile.bodyScrolling
        if not excludeBody then
            if profile.disableModY then
                total = total + profile.body
            else
                total = total + profile.body * OFFSET_MOD
            end

        end

        if not excludeJump then
            total = total + Vector:new(0, -profile.jump)
        end

    end

    return total
end

function Offset:getJump()
    local total = Vector.ORIGIN
    for profile in self.profiles() do
        total = total + Vector:new(0, -profile.jump)
    end

    return total
end

return Offset

