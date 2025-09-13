local SkillDef = class()
local COOLDOWN_NORMAL = 11
local COOLDOWN_RARE = 30
function SkillDef:initialize()
    self.actionClass = false
    self.getCastDirection = false
    self.cooldown = false
    self.indicateArea = false
    self.continuousCast = false
end

function SkillDef:setCooldownToNormal()
    self.cooldown = COOLDOWN_NORMAL
end

function SkillDef:setCooldownToRare()
    self.cooldown = COOLDOWN_RARE
end

return SkillDef

