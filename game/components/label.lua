local Label = require("components.create_class")()
local Array = require("utils.classes.array")
function Label:initialize(entity, label)
    Label:super(self, "initialize")
    self.label = label or false
    self.properNoun = false
end

local VOWELS = Array:new("A", "E", "I", "O", "U")
function Label:getWithArticle()
    if self.properNoun then
        return false, self.label
    else
        for vowel in VOWELS() do
            if self.label:startsWith(vowel) then
                return "an", self.label
            end

        end

        return "a", self.label
    end

end

function Label:get()
    return self.label
end

return Label

