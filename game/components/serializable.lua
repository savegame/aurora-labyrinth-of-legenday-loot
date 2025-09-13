local Serializable = require("components.create_class")()
local CONSTANTS = require("logic.constants")
local ITEMS = require("definitions.items")
local SUFFIXES = require("definitions.suffixes")
local Array = require("utils.classes.array")
local UniqueList = require("utils.classes.unique_list")
local Vector = require("utils.classes.vector")
local Hash = require("utils.classes.hash")
local SparseGrid = require("utils.classes.sparse_grid")
local Entity = require("entities.entity")
local Common = require("common")
local FILENAMES = require("text.filenames")
local MessagePack = require("messagepack")
local Item = require("structures.item")
local ItemCreateCommand = require("logic.item_create_command")
function Serializable:initialize(entity,...)
    Serializable:super(self, "initialize")
    self.id = 0
    self._entity = entity
    self.marshallables = Array:new()
    self.postMarshallables = Array:new()
    self.shouldSave = true
    self.args = Array:new(...)
    while not self.args:isEmpty() and self.args:last() == nil do
        self.args:pop()
    end

end

function Serializable:addArg(arg)
    self.args:push(arg or false)
end

function Serializable:addComponent(componentName)
    self.marshallables:push(componentName)
end

function Serializable:addComponentPost(componentName)
    self.postMarshallables:push(componentName)
end

function Serializable:toData()
    return { entityID = self.id }
end

local function convertToData(object)
    if type(object) == "table" then
                                if Vector:isInstance(object) then
            return { x = object.x, y = object.y }
        elseif Item:isInstance(object) then
            return object:toData()
        elseif Entity:isInstance(object) then
            return object.serializable:toData()
        elseif Hash:isInstance(object) or Array:isInstance(object) or SparseGrid:isInstance(object) then
            return object
        else
            Utils.assert(false, "Unserializable argument: %s", table.keys(object))
            return false
        end

    else
        return object
    end

end

function Serializable:marshal()
    local data = {  }
    data.entityID = self.id
    data.prefab = self._entity:getPrefab()
    data.args = self.args:map(convertToData)
    local position = Common.getPositionComponent(self._entity):getPosition()
    data.x = position.x
    data.y = position.y
    for marshallable in self.marshallables() do
        data[marshallable] = self._entity[marshallable]:toData(convertToData)
    end

    for marshallable in self.postMarshallables() do
        if not self.marshallables:contains(marshallable) then
            data[marshallable] = self._entity[marshallable]:toData(convertToData)
        end

    end

    return data
end

function Serializable.System:initialize()
    Serializable.System:super(self, "initialize")
    self.storageClass = UniqueList
    self:setDependencies("createEntity", "overseer", "logicrng")
    self.nextID = 1
end

function Serializable.System:addInstance(entity)
    entity.serializable.id = self.nextID
    self.entities:push(entity)
    self.nextID = self.nextID + 1
end

function Serializable.System:saveAll()
    local dataEntities = Array:new()
    for entity in self.entities() do
        if Utils.evaluate(entity.serializable.shouldSave, entity) then
            dataEntities:push(entity.serializable:marshal())
        end

    end

    local toSave = { entities = dataEntities, overseer = self.services.overseer:toData(convertToData), rng = self.services.logicrng:getState() }
    toSave = MessagePack.pack(toSave)
    filesystem.write(FILENAMES.CURRENT_FLOOR, toSave)
end

local function convertNoContextData(data)
                if data.x then
        return Vector:new(data.x, data.y)
    elseif data.itemDefinition then
        return ItemCreateCommand:CreateFromData(data)
    elseif data.container then
        if data.width then
            local result = SparseGrid:new(data.default, data.width, data.height)
            result.container = data.container
            return result
        else
            return Hash:new(data.container)
        end

    elseif data[1] then
        return Array:Convert(data)
    else
        Utils.assert("Unknown data", table.keys(data))
    end

end

function Serializable.System:loadAll()
    if filesystem.getInfo(FILENAMES.CURRENT_FLOOR, "file") then
        local rawData, bytes = filesystem.read(FILENAMES.CURRENT_FLOOR)
        local status, data = pcall(MessagePack.unpack, rawData)
        local maxID = 0
        local byID = Hash:new()
        if status then
            local convertFromData = function(data)
                if type(data) == "table" then
                    if data.entityID then
                        return byID:get(data.entityID)
                    else
                        return convertNoContextData(data)
                    end

                else
                    return data
                end

            end
            local createEntity = self.services.createEntity
            local dataEntities = Array:Convert(data.entities)
            for entityData in dataEntities() do
                local args = Array:Convert(entityData.args):map(convertFromData)
                local entity = createEntity(entityData.prefab, function(entity)
                    for marshallable in entity.serializable.marshallables() do
                        entity[marshallable]:fromData(entityData[marshallable], convertFromData)
                    end

                end, Vector:new(entityData.x, entityData.y), unpack(args))
                entity.serializable.id = entityData.entityID
                byID:set(entityData.entityID, entity)
                maxID = entityData.entityID
            end

            for entityData in dataEntities() do
                local entity = byID:get(entityData.entityID)
                for marshallable in entity.serializable.postMarshallables() do
                    entity[marshallable]:fromDataPost(entityData[marshallable], convertFromData)
                end

            end

            self.services.overseer:fromData(data.overseer, convertFromData)
            self.services.logicrng:setState(data.rng)
        end

        self.nextID = maxID + 1
    end

end

return Serializable

