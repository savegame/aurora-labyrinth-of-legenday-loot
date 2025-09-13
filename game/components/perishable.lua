local Perishable = require("components.create_class")()
local UniqueList = require("utils.classes.unique_list")
local Common = require("common")
local FADE_DURATION = require("actions.constants").WALK_DURATION
local function shouldSave(entity)
    return not entity.perishable.perishing
end

function Perishable:initialize(entity, duration)
    Perishable:super(self, "initialize")
    self._entity = entity
    self.duration = duration or math.huge
    self.perishing = false
    if entity:hasComponent("serializable") then
        entity.serializable:addComponent("perishable")
        entity.serializable.shouldSave = shouldSave
    end

end

function Perishable:toData()
    return { duration = self.duration }
end

function Perishable:fromData(data)
    self.duration = data.duration
end

function Perishable:perish()
    Common.getPositionComponent(self._entity):removeFromGrid()
    self.perishing = true
end

function Perishable.System:initialize()
    Perishable.System:super(self, "initialize")
    self:setDependencies("agent")
    self.storageClass = UniqueList
end

function Perishable.System:endOfTurn()
    if not self.services.agent:isTimeStopped() then
        for entity in self.entities() do
            local perishable = entity.perishable
            perishable.duration = perishable.duration - 1
            if perishable.duration <= 0 and not perishable.perishing then
                perishable:perish()
            end

        end

    end

end

function Perishable.System:update(dt)
    local reduction = dt / FADE_DURATION
    for entity in self.entities() do
        if entity.perishable.perishing then
            local sprite = false
                        if entity:hasComponent("sprite") then
                sprite = entity.sprite
            elseif entity:hasComponent("item") then
                sprite = entity.item
            end

            if not sprite or sprite.opacity <= reduction then
                entity:delete()
            else
                sprite.opacity = sprite.opacity - reduction
            end

        end

    end

end

function Perishable.System:isAnyPerishing()
    for entity in self.entities() do
        if entity.perishable.perishing then
            return true
        end

    end

    return false
end

return Perishable

