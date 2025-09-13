local ModifierDef = class("structures.growing_stats_def")
local Hash = require("utils.classes.hash")
local COLORS = require("draw.colors")
local DEFAULT_LEGENDARY_COLOR = COLORS.ITEM_LABEL.LEGENDARY:withAlpha(0.5)
function ModifierDef:initialize(name)
    ModifierDef:super(self, "initialize")
    self.name = name
    self.minFloor = 0
    self.statLine = false
    self.abilityExtraLine = false
    self.passiveExtraLine = false
    self.frequency = 1
    self.modifyItem = doNothing
    self.canRoll = alwaysFalse
    self.isLegendary = false
    self.strokeColor = false
end

function ModifierDef:getLegendaryStrokeColor(itemDef)
    if self.isLegendary then
        if self.strokeColor then
            return self.strokeColor
        else
            local ability = itemDef.ability
            if ability then
                return ability.iconColor
            else
                return DEFAULT_LEGENDARY_COLOR
            end

        end

    else
        return false
    end

end

return ModifierDef

