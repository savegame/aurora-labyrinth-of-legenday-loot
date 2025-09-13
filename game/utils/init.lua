Utils = {  }
function Utils.assert(condition, messageFormat,...)
    if not condition then
        local message = ""
        if messageFormat then
            message = messageFormat:format(...) .. "\n"
        end

        assert(false, message .. debug.traceback())
    end

end

require("utils.tags")
require("utils.class")
require("utils.methods_basic")
require("utils.methods")
require("utils.classes.init")

