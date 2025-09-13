Object = { _isClass = true, _depth = 0 }
local ASSERT_SUPER_INITIALIZE = 'Calling :super(self, "initialize") is required when inheriting'
function Object:new(...)
    local o = {  }
    o._initializing = true
    o._superInitializeRequired = self._depth - 1
    setmetatable(o, self)
    o:initialize(...)
    Utils.assert(o._superInitializeRequired <= 0, ASSERT_SUPER_INITIALIZE)
    o._superInitializeRequired = nil
    o._initializing = nil
    return o
end

function Object:initialize()
end

function Object:isInstance(object)
    if type(object) ~= "table" then
        return false
    end

    local mt = getmetatable(object)
    if not mt then
        return false
    end

    while mt ~= self and mt._parent do
        mt = mt._parent
    end

    return mt == self
end

function Object:isChild(klass)
    local mt = klass._parent
    while mt ~= self and mt._parent do
        mt = mt._parent
    end

    return mt == self
end

function Object:convert(object)
    setmetatable(object, self)
    return object
end

function Object:getClass()
    return getmetatable(self)
end

function Object:clone()
    if type(self) ~= "table" then
        return self
    end

    local newObj = {  }
    for k, v in pairs(self) do
        newObj[k] = v
    end

    local mt = getmetatable(self)
    if mt then
        setmetatable(newObj, mt)
    end

    return newObj
end

function Object:__index(key)
    if Object[key] then
        return Object[key]
    end

    Utils.assert(false, "Key '%s' does not exist (during get)", key)
    return nil
end

function Object:__newindex(key, value)
    if not rawget(self, "_initializing") and not rawget(self, "_isClass") and key ~= "_initializing" then
        Utils.assert(false, "Key '%s' does not exist (during set)", key)
    end

    rawset(self, key, value)
end

function Object:super(object, method,...)
    if method == "initialize" and self._parent ~= Object then
        object._superInitializeRequired = object._superInitializeRequired - 1
    end

    return self._parent[method](object, ...)
end

local META_METHODS = { "__add", "__sub", "__unm", "__concat", "__lt", "__call", "__gc", "__mul", "__div", "__pow", "__len", "__eq", "__le", "__newindex", "__tostring" }
function class(parent)
    if type(parent) == "string" then
        return class(require(parent))
    end

    local newClass = {  }
    newClass.__index = function(instance, key)
        return newClass[key]
    end
    newClass.__tojson = false
    parent = parent or Object
    newClass._isClass = true
    newClass._parent = parent
    newClass._depth = parent._depth + 1
    for _, methodName in ipairs(META_METHODS) do
        local method = rawget(parent, methodName)
        if method then
            newClass[methodName] = method
        end

    end

    newClass.initialize = function(instance, ...)
        newClass:super(instance, "initialize", ...)
    end
    setmetatable(newClass, parent)
    return newClass
end

local function structInitialize(self,...)
    local starting = { ... }
    for i, field in ipairs(self._fields) do
        if starting[i] ~= nil then
            self[field] = starting[i]
        else
            self[field] = false
        end

    end

end

function struct(...)
    local structClass = class()
    structClass._fields = { ... }
    structClass.initialize = structInitialize
    return structClass
end

return class

