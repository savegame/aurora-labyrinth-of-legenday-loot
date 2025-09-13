local TRIGGERS = {  }
local TRIGGER = class("actions.action")
TRIGGERS.TRIGGER = TRIGGER
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_ALWAYS
    self.sortOrder = 5
end

function TRIGGER:isEnabled()
    return true
end

TRIGGERS.PRE_MOVE = class(TRIGGER)
function TRIGGERS.PRE_MOVE:initialize(entity, direction, abilityStats)
    TRIGGERS.PRE_MOVE:super(self, "initialize", entity, direction, abilityStats)
    self.moveFrom = false
    self.moveTo = false
end

TRIGGERS.POST_MOVE = class(TRIGGER)
function TRIGGERS.POST_MOVE:initialize(entity, direction, abilityStats)
    TRIGGERS.POST_MOVE:super(self, "initialize", entity, direction, abilityStats)
    self.moveFrom = false
    self.moveTo = false
end

TRIGGERS.ON_ATTACK = class(TRIGGER)
function TRIGGERS.ON_ATTACK:initialize(entity, direction, abilityStats)
    TRIGGERS.ON_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self.attackTarget = false
end

TRIGGERS.ON_DAMAGE = class(TRIGGER)
function TRIGGERS.ON_DAMAGE:initialize(entity, direction, abilityStats)
    TRIGGERS.ON_DAMAGE:super(self, "initialize", entity, direction, abilityStats)
    self.hit = false
end

TRIGGERS.ON_HIT = class(TRIGGER)
function TRIGGERS.ON_HIT:initialize(entity, direction, abilityStats)
    TRIGGERS.ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.hit = false
end

TRIGGERS.ON_KILL = class(TRIGGER)
function TRIGGERS.ON_KILL:initialize(entity, direction, abilityStats)
    TRIGGERS.ON_KILL:super(self, "initialize", entity, direction, abilityStats)
    self.killed = false
    self.position = false
    self.killingHit = false
end

TRIGGERS.POST_HIT = class(TRIGGER)
function TRIGGERS.POST_HIT:initialize(entity, direction, abilityStats)
    TRIGGERS.POST_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.hit = false
end

TRIGGERS.PRE_HIT = class(TRIGGER)
function TRIGGERS.PRE_HIT:initialize(entity, direction, abilityStats)
    TRIGGERS.PRE_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.hit = false
end

TRIGGERS.WHEN_HEALED = class(TRIGGER)
function TRIGGERS.WHEN_HEALED:initialize(entity, direction, abilityStats)
    TRIGGERS.WHEN_HEALED:super(self, "initialize", entity, direction, abilityStats)
    self.hit = false
end

TRIGGERS.END_OF_TURN = class(TRIGGER)
function TRIGGERS.END_OF_TURN:initialize(entity, direction, abilityStats)
    TRIGGERS.END_OF_TURN:super(self, "initialize", entity, direction, abilityStats)
end

TRIGGERS.START_OF_TURN = class(TRIGGER)
function TRIGGERS.START_OF_TURN:initialize(entity, direction, abilityStats)
    TRIGGERS.START_OF_TURN:super(self, "initialize", entity, direction, abilityStats)
end

TRIGGERS.POST_CAST = class(TRIGGER)
function TRIGGERS.POST_CAST:initialize(entity, direction, abilityStats)
    TRIGGERS.POST_CAST:super(self, "initialize", entity, direction, abilityStats)
    self.triggeringSlot = false
    self.triggeringAction = false
end

TRIGGERS.ON_PROJECTILE_HIT = class(TRIGGER)
function TRIGGERS.ON_PROJECTILE_HIT:initialize(entity, direction, abilityStats)
    TRIGGERS.ON_PROJECTILE_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.projectile = false
    self.position = false
    self.catcher = false
end

TRIGGERS.ON_SLOT_DEACTIVATE = class(TRIGGER)
function TRIGGERS.ON_SLOT_DEACTIVATE:initialize(entity, direction, abilityStats)
    TRIGGERS.ON_SLOT_DEACTIVATE:super(self, "initialize", entity, direction, abilityStats)
    self.triggeringSlot = false
end

TRIGGERS.ON_ENEMY_FOCUS = class(TRIGGER)
function TRIGGERS.ON_ENEMY_FOCUS:initialize(entity, direction, abilityStats)
    TRIGGERS.ON_ENEMY_FOCUS:super(self, "initialize", entity, direction, abilityStats)
    self.focusingEnemy = false
end

return TRIGGERS

