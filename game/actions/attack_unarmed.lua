local ACTIONS = {  }
local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local EASING = require("draw.easing")
local MONSTER_ATTACK_JUMP = 0.1
local CLAW_FORWARD_DURATION = 0.135
local CLAW_FORWARD_DISTANCE = 0.45
local CLAW_DURATION = 0.16
local CLAW_START = 0.055
local CLAW_PROGRESS_BEFORE_HIT = 0.5
ACTIONS.CLAW = class("actions.action")
function ACTIONS.CLAW:initialize(entity, direction, abilityStats)
    ACTIONS.CLAW:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("claw")
    self:addComponent("tackle")
    self:addComponent("jump")
    self.tackle.forwardDistance = CLAW_FORWARD_DISTANCE
    self.jump.height = MONSTER_ATTACK_JUMP
    self.forwardDuration = CLAW_FORWARD_DURATION
    self.clawStart = CLAW_START
    self.clawDuration = CLAW_DURATION
end

function ACTIONS.CLAW:speedMultiply(factor)
    self.forwardDuration = self.forwardDuration / factor
    self.clawStart = self.clawStart / factor
    self.clawDuration = self.clawDuration / factor
end

function ACTIONS.CLAW:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.tackle:createOffset()
    self.tackle:chainForwardEvent(currentEvent, self.forwardDuration)
    self.jump:chainFullEvent(currentEvent, self.forwardDuration)
    currentEvent = currentEvent:chainProgress(self.clawStart):chainEvent(function()
        Common.playSFX("WHOOSH")
        self.claw:createImage()
    end)
    local backStart = self.claw:chainSlashEvent(currentEvent, self.clawDuration)
    backStart = backStart:chainEvent(function()
        self.claw:deleteImage()
    end)
    self.tackle:chainBackEvent(backStart, self.forwardDuration)
    return currentEvent:chainProgress(CLAW_PROGRESS_BEFORE_HIT * self.clawDuration)
end

ACTIONS.CLAW_AND_DAMAGE = ActionUtils.actionWithMeleeDamage(ACTIONS.CLAW)
local BITE_DURATION = 0.08
local BITE_HOLD_DURATION = 0.11
ACTIONS.BITE_TEETH = class("actions.action")
function ACTIONS.BITE_TEETH:initialize(entity, direction, abilityStats)
    ACTIONS.BITE_TEETH:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("bite")
    self.target = false
end

function ACTIONS.BITE_TEETH:process(currentEvent)
    self.bite.target = self.target
    currentEvent = currentEvent:chainEvent(function()
        self.bite:createImages()
    end)
    currentEvent = self.bite:chainContactEvent(currentEvent, BITE_DURATION)
    currentEvent:chainProgress(BITE_HOLD_DURATION):chainEvent(function()
        self.bite:deleteImages()
    end)
    return currentEvent
end

local BITE_DISTANCE = 0.55
local BITE_FORWARD_DURATION = 0.12
local BITE_START = 0.07
ACTIONS.BITE = class(ACTIONS.BITE_TEETH)
function ACTIONS.BITE:initialize(entity, direction, abilityStats)
    ACTIONS.BITE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self:addComponent("jump")
    self.tackle.forwardDistance = BITE_DISTANCE
    self.jump.height = MONSTER_ATTACK_JUMP
    self.forwardDuration = BITE_FORWARD_DURATION
    self.biteStart = BITE_START
    self.sound = "BITE"
end

function ACTIONS.BITE:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    if not self.target then
        self.target = self.entity.body:getPosition() + Vector[self.direction]
    end

    self.tackle:createOffset()
    Common.playSFX(self.sound)
    self.tackle:chainForwardEvent(currentEvent, self.forwardDuration)
    self.jump:chainFullEvent(currentEvent, self.forwardDuration)
    currentEvent = currentEvent:chainProgress(self.biteStart)
    currentEvent = ACTIONS.BITE:super(self, "process", currentEvent)
    self.tackle:chainBackEvent(currentEvent, self.forwardDuration):chainEvent(function()
        self.tackle:deleteOffset()
    end)
    return currentEvent
end

ACTIONS.BITE_AND_DAMAGE = ActionUtils.actionWithMeleeDamage(ACTIONS.BITE)
ACTIONS.PEST_BITE = class(ACTIONS.BITE)
function ACTIONS.PEST_BITE:initialize(entity, direction, abilityStats)
    ACTIONS.PEST_BITE:super(self, "initialize", entity, direction, abilityStats)
    self.sound = "PEST_BITE"
end

ACTIONS.PEST_BITE_AND_DAMAGE = ActionUtils.actionWithMeleeDamage(ACTIONS.PEST_BITE)
local TACKLE_BRACE_DURATION = ACTION_CONSTANTS.DEFAULT_BRACE_DURATION
local TACKLE_BRACE_DISTANCE = ACTION_CONSTANTS.DEFAULT_BRACE_DISTANCE
local TACKLE_FORWARD_DISTANCE = 0.85
local TACKLE_DURATION = 0.12
ACTIONS.TACKLE = class("actions.action")
function ACTIONS.TACKLE:initialize(entity, direction, abilityStats)
    ACTIONS.TACKLE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("tackle")
    self.tackle.forwardDistance = TACKLE_FORWARD_DISTANCE
    self.tackle.braceDistance = TACKLE_BRACE_DISTANCE
    self.tackle.forwardEasing = EASING.QUAD
    self.tackle.backEasing = EASING.OUT_QUAD
    self.braceDuration = TACKLE_BRACE_DURATION
    self.forwardDuration = TACKLE_DURATION
    self.backDuration = TACKLE_DURATION
end

function ACTIONS.TACKLE:speedMultiply(factor)
    self.braceDuration = self.braceDuration / factor
    self.forwardDuration = self.forwardDuration / factor
    self.backDuration = self.backDuration / factor
end

function ACTIONS.TACKLE:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.tackle:createOffset()
    self.tackle.offset.disableModY = true
    currentEvent = self.tackle:chainBraceEvent(currentEvent, self.braceDuration):chainEvent(function()
        Common.playSFX("DASH_SHORT", 0.65 * self.forwardDuration / TACKLE_DURATION, 1.15)
    end)
    currentEvent = self.tackle:chainForwardEvent(currentEvent, self.forwardDuration)
    self.tackle:chainBackEvent(currentEvent, self.backDuration):chainEvent(function()
        self.tackle:deleteOffset()
    end)
    return currentEvent
end

ACTIONS.TACKLE_AND_DAMAGE = ActionUtils.actionWithMeleeDamage(ACTIONS.TACKLE)
return ACTIONS

