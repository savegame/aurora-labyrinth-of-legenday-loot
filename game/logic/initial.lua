local LogicInitial = {  }
local Hash = require("utils.classes.hash")
local CONSTANTS = require("logic.constants")
local OverseerStandard = require("logic.overseer_standard")
local OverseerFinalFloor = require("logic.overseer_final_floor")
local OverseerTutorial = require("logic.overseer_tutorial")
local Run = require("structures.run")
local Global = require("global")
local ITEMS = require("definitions.items")
local ItemCreateCommand = require("logic.item_create_command")
local generateSeed = require("generation.seed")
function LogicInitial.createNewRun(difficulty)
    local newRun = Run:new()
    newRun:createNew(difficulty, DebugOptions.SEED or generateSeed())
    Debugger.log("Seed: ", newRun.seed)
    Global:set(Tags.GLOBAL_CURRENT_RUN, newRun)
    return newRun
end

function LogicInitial.getOverseerClass(currentFloor)
        if currentFloor == CONSTANTS.MAX_FLOORS then
        return OverseerFinalFloor
    elseif currentFloor == 0 then
        return OverseerTutorial
    else
        return OverseerStandard
    end

end

local function equipBasedOnDebugOptions(equipped, run, rng, command)
        if DebugOptions.STARTING_LEGENDARY and command.itemDef.slot ~= Tags.SLOT_AMULET and command.itemDef.legendaryMod then
        command.modifierDef = command.itemDef.legendaryMod
    elseif DebugOptions.STARTING_SUFFIXED then
        command.modifierChance = 1
        command:rollModifier(rng)
    end

    local item = command:create()
    item.hasBeenSeen = true
    equipped:set(item:getSlot(), item)
end

function LogicInitial.getInitialItems(run)
    local equipped = Hash:new()
    local rng = Utils.createRandomGenerator(run:getCurrentFloorSeed())
    if DebugOptions.DEFAULT_LEVEL_1_ITEMS then
        for filename in DebugOptions.DEFAULT_LEVEL_1_ITEMS() do
            local command = ItemCreateCommand:new(run.currentFloor)
            Utils.assert(ITEMS.BY_ID[filename], "Unable to find item '%s'", filename)
            command.itemDef = ITEMS.BY_ID[filename]
            if DebugOptions.STARTING_UPGRADE_LEVEL then
                command.upgradeLevel = DebugOptions.STARTING_UPGRADE_LEVEL
            else
                if run.currentFloor == 1 then
                    command.upgradeLevel = 0
                else
                    command.upgradeLevel = min(ceil((run.currentFloor + 1) / 2), CONSTANTS.ITEM_UPGRADE_LEVELS)
                end

            end

            equipBasedOnDebugOptions(equipped, run, rng, command)
        end

    end

    if DebugOptions.FILL_EMPTY_SLOTS then
        for slot in ITEMS.SLOTS() do
            if not equipped:hasKey(slot) then
                local command = ItemCreateCommand:new(run.currentFloor)
                command.itemSlot = slot
                if DebugOptions.STARTING_UPGRADE_LEVEL then
                    command.upgradeLevel = DebugOptions.STARTING_UPGRADE_LEVEL
                else
                    if run.currentFloor == 1 then
                        command.upgradeLevel = 0
                    else
                        command.upgradeLevel = min(ceil((run.currentFloor + 1) / 2), CONSTANTS.ITEM_UPGRADE_LEVELS)
                    end

                end

                command:rollItemDef(rng)
                if command.itemDef then
                    equipBasedOnDebugOptions(equipped, run, rng, command)
                end

            end

        end

    end

    return equipped
end

return LogicInitial

