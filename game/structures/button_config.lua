local ButtonConfig = class()
function ButtonConfig:initialize(label, callback, isEnabled, color)
    self.label = label or ""
    self.callback = callback or doNothing
    local isEnabledType = type(isEnabled)
    if isEnabledType == "function" or isEnabledType == "boolean" then
        self.isEnabled = isEnabled
    else
        self.isEnabled = true
    end

    self.color = color or false
end

return ButtonConfig

