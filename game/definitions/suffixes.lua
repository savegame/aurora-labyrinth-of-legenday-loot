local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
local SUFFIXES = {  }
SUFFIXES.ORDERED = Array:new()
local function loadSuffixes(suffixes)
    for key, modifierDef in pairs(suffixes) do
        Utils.assert(not SUFFIXES[key], "Suffix Conflict: %s", key)
        modifierDef.saveKey = key
        SUFFIXES[key] = modifierDef
        SUFFIXES.ORDERED:push(SUFFIXES[key])
    end

end

loadSuffixes(require("definitions.suffixes.stat_modifier"))
loadSuffixes(require("definitions.suffixes.when_hit"))
loadSuffixes(require("definitions.suffixes.on_attack"))
loadSuffixes(require("definitions.suffixes.on_kill"))
loadSuffixes(require("definitions.suffixes.ability"))
SUFFIXES.ORDERED:unstableSortSelf(function(a, b)
    return a.saveKey < b.saveKey
end)
for suffix in SUFFIXES.ORDERED() do
    suffix:extrapolate()
end

return SUFFIXES

