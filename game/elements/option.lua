local Option = class("elements.list_slot")
function Option:initialize(width)
    Option:super(self, "initialize", width)
    self.controller = false
    self.extraElement = false
    if PortSettings.IS_MOBILE then
        self.rect.height = self.rect.height + 6
    end

end

return Option

