local MultiHash = class()
local Array = require("utils.classes.array")
function MultiHash:initialize(key)
    self.container = {  }
    self.key = key or "key"
end

function MultiHash:getKey(value)
    return value[self.key]
end

function MultiHash:add(value)
    local key = self:getKey(value)
        if not self.container[key] then
        self.container[key] = value
    elseif not Array:isInstance(self.container[key]) then
        self.container[key] = Array:new(self.container[key], value)
    else
        self.container[key]:push(value)
    end

end

function MultiHash:getOne(key)
    local value = self.container[key]
    if Array:isInstance(value) then
        return value:last()
    else
        return value
    end

end

function MultiHash:getAll(key)
    local value = self.container[key]
    if not value then
        return Array.EMPTY
    end

    if not Array:isInstance(value) then
        return Array:new(value)
    end

    return value
end

function MultiHash:delete(value)
    local key = self:getKey(value)
        if self.container[key] == value then
        self.container[key] = nil
    elseif Array:isInstance(self.container[key]) then
        self.container[key]:delete(value)
        if self.container[key]:isEmpty() then
            self.container[key] = nil
        end

    end

    return value
end

function MultiHash:deleteAll(key)
    self.container[key] = nil
end

return MultiHash

