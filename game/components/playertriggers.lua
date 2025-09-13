local PlayerTriggers = require("components.create_class")()
local Array = require("utils.classes.array")
local ActionList = require("actions.list")
local TRIGGERS = require("actions.triggers")
local PROCCING_SLOTS = Array:new(Tags.SLOT_WEAPON, Tags.SLOT_GLOVES, Tags.SLOT_ARMOR, Tags.SLOT_HELM, Tags.SLOT_BOOTS, false, false, false)
local PROCCING_SLOTS_LUCKY = Array:new(Tags.SLOT_WEAPON, Tags.SLOT_GLOVES, Tags.SLOT_ARMOR, Tags.SLOT_HELM, Tags.SLOT_BOOTS)
local SLOT_ORDER = require("definitions.items").SLOTS
function PlayerTriggers:initialize(entity)
    PlayerTriggers:super(self, "initialize", entity)
    self._entity = entity
    self._equipment = entity.equipment
    self.proccingSlot = DebugOptions.PROCCING_SLOT
    entity:callIfHasComponent("serializable", "addComponent", "playertriggers")
end

function PlayerTriggers:toData()
    return { proccingSlot = self.proccingSlot }
end

function PlayerTriggers:fromData(data)
    self.proccingSlot = data.proccingSlot
end

function PlayerTriggers:rerollProccingSlot()
    self.proccingSlot = DebugOptions.PROCCING_SLOT or PROCCING_SLOTS:randomValue(self.system.services.logicrng)
end

function PlayerTriggers:isActivationValid(slot, action)
    local activation = action.activationType
        if activation == Tags.TRIGGER_ALWAYS then
        return true
    elseif activation == Tags.TRIGGER_CHANCE then
        return slot == self.proccingSlot
    else
        return false
    end

end

function PlayerTriggers:_getActionsForSlot(baseClass, slot, direction, kwargs)
    local atEquipped = self._equipment:get(slot)
    local actions = ActionList:new()
    if atEquipped then
        local triggerClasses = atEquipped.triggers:accept(function(triggerClass)
            return baseClass:isChild(triggerClass)
        end)
        local stats = self._equipment:getSlotStats(slot)
        for triggerClass in triggerClasses() do
            local action = self._entity.actor:create(triggerClass, direction, stats)
            if kwargs then
                table.assign(action, kwargs)
            end

            if self:isActivationValid(slot, action) and action:isEnabled() then
                actions:push(action)
            end

        end

    end

    return actions
end

function PlayerTriggers:getActionsForTrigger(baseClass, direction, kwargs)
    local actions = ActionList:new()
    local actionsForProccing = self:_getActionsForSlot(baseClass, self.proccingSlot, direction, kwargs)
    for slot in SLOT_ORDER() do
        if slot == self.proccingSlot then
            actions:concat(actionsForProccing)
        else
            actions:concat(self:_getActionsForSlot(baseClass, slot, direction, kwargs))
        end

    end

    self:rerollProccingSlot()
    return actions
end

function PlayerTriggers:hasActionsForTrigger(baseClass, direction, kwargs)
    for slot in SLOT_ORDER() do
        local atEquipped = self._equipment:get(slot)
        if atEquipped then
            local triggerClasses = atEquipped.triggers:accept(function(triggerClass)
                return baseClass:isChild(triggerClass)
            end)
            for triggerClass in triggerClasses() do
                local action = self._entity.actor:create(triggerClass, direction, atEquipped.stats)
                if kwargs then
                    for k, v in pairs(kwargs) do
                        action[k] = v
                    end

                end

                if self:isActivationValid(slot, action) and action:isEnabled() then
                    return true
                end

            end

        end

    end

    return false
end

function PlayerTriggers.System:initialize()
    PlayerTriggers.System:super(self, "initialize")
    self:setDependencies("logicrng")
end

return PlayerTriggers

