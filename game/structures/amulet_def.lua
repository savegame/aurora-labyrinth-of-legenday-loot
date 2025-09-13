local AmuletDef = class("structures.item_def")
function AmuletDef:initialize(name)
    AmuletDef:super(self, "initialize", name)
    self.slot = Tags.SLOT_AMULET
    self.classSprite = false
    self.className = false
end

return AmuletDef

