local AbilityDef = class()
local Set = require("utils.classes.set")
local ACTIONS_BASIC = require("actions.basic")
local BUFFS = require("definitions.buffs")
require("definitions.standard_buffs")
require("definitions.elites")
local DEFAULT_FORMAT = "To-do: %s's description"
local function defaultGetDescription(item)
    return DEFAULT_FORMAT:format(item:getAbility().name)
end

function AbilityDef:initialize(name)
    self.name = name
    self.tags = Set:new()
    self.actionClass = false
    self.buffClass = BUFFS.PLACEHOLDER
    self.icon = false
    self.iconColor = WHITE
    self.directions = DIRECTIONS_AA
    self.indicate = false
    self.getInvalidReason = alwaysFalse
    self.getDescription = defaultGetDescription
    self.modeCancelClass = ACTIONS_BASIC.DEFAULT_MODE_CANCEL
end

function AbilityDef:addTag(tag)
    self.tags:add(tag)
end

function AbilityDef:hasTag(tag)
    return self.tags:contains(tag)
end

return AbilityDef

