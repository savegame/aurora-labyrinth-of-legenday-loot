local Wallet = require("components.create_class")()
local LogicMethods = require("logic.methods")
function Wallet:initialize(entity)
    Wallet:super(self, "initialize")
    self.scrap = 0
    self.maxScrap = math.huge
    entity:callIfHasComponent("serializable", "addComponent", "wallet")
end

function Wallet:toData()
    return { scrap = self.scrap }
end

function Wallet:fromData(data)
    self.scrap = data.scrap
end

function Wallet:get()
    return self.scrap
end

function Wallet:hasSpaceFor(amount)
    return self:get() + amount <= self.maxScrap
end

function Wallet:add(value)
    if DebugOptions.MAX_OUT_SCRAP then
        self.scrap = 100
    else
        self.scrap = self.scrap + value
    end

end

function Wallet:set(value)
    if DebugOptions.MAX_OUT_SCRAP then
        self.scrap = 100
    else
        self.scrap = value
    end

end

return Wallet

