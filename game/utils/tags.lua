Tags = {  }
Tags.currentValue = 32768
function Tags.add(tag, value)
    Utils.assert(not rawget(Tags, tag), "Tag '%s' already exists", tag)
    if value then
        Tags[tag] = value
    else
        Tags.currentValue = Tags.currentValue + 1
        Tags[tag] = Tags.currentValue
    end

end

setmetatable(Tags, { __index = function(t, k)
    Utils.assert(false, "Tag '%s' does not exist", k)
end })
function Tags.toString(value)
    for k, v in pairs(Tags) do
        if v == value then
            return "Tags." .. k
        end

    end

    Utils.assert(false, "Tag with value %s does not exist", value)
end

Tags.add("DEFAULT")
Tags.add("ALL")
Tags.add("NONE")
return Tags

