local ACTIONS_BASIC = require("actions.basic")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local ItemCreateCommand = require("logic.item_create_command")
local DEATH = class(ACTIONS_BASIC.DIE)
local ACTION_CONSTANTS = require("actions.constants")
local ITEMS = require("definitions.items")
local Global = require("global")
local JUMP_HEIGHT = 0.3
function DEATH:initialize(entity, direction, abilityStats)
    DEATH:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("jump")
    self.jump.height = JUMP_HEIGHT
    self.jump:setEasingToLinear()
    self:addComponent("explosion")
    self.explosion:setArea(Tags.ABILITY_AREA_BOSS_EXPLOSION)
    self.explosion.hue = 270
    self.explosion.layer = Tags.LAYER_ABOVE_VISION
    self.itemDrop = false
end

local EXPLOSION_EXPAND_DURATION = 0.6
local EXPLOSION_DISPERSE_DURATION = 2.4
function DEATH:parallelResolve(anchor)
    DEATH:super(self, "parallelResolve", anchor)
    local player = self.entity.agent:getPlayer()
    player.buffable:forceApply(BUFFS:get("IMMUNE_HIDDEN"):new(math.huge))
    if not player.tank:isAlive() then
        player.tank.currentHealth = 1
    end

    if self.entity.melee.enabled then
        self.explosion:setHueToFire()
    end

    local itemCommand = ItemCreateCommand:new(1)
    local amulet = player.equipment:get(Tags.SLOT_AMULET)
    if not amulet then
        itemCommand.itemDef = ITEMS.BY_SLOT[Tags.SLOT_AMULET]:roll(self:getLogicRNG())
    else
        itemCommand.itemDef = amulet.definition
    end

    itemCommand.upgradeLevel = 10
    itemCommand.modifierDef = itemCommand.itemDef.legendaryMod
    self.itemDrop = self.entity.entityspawner:spawn("final_item", self.position, itemCommand:create())
    self.itemDrop.item.opacity = 0
    DEATH:super(self, "parallelResolve", anchor)
end

local SCREEN_FLASH_OPACITY = 0.5
local SCREEN_FLASH_DURATION = 0.5
local SCREEN_FLASH_COLOR = Color:new(0.95, 0.95, 0.95)
local DEATH_SPEED_MULTIPLIER = 0.3
function DEATH:process(currentEvent)
    Global:get(Tags.GLOBAL_AUDIO):fadeoutCurrentBGM()
    local entity = self.entity
    self.explosion.source = entity.body:getPosition() - Vector:new(0, JUMP_HEIGHT)
    entity.charactereffects.negativeOverlay = 1
    local effects = self:getEffects()
    effects:multiplySpeed(DEATH_SPEED_MULTIPLIER)
    local sound, origVolume
    Common.playSFX("BOSS_KILLING_HIT", 1)
    effects:flashScreen(SCREEN_FLASH_DURATION, SCREEN_FLASH_COLOR, SCREEN_FLASH_OPACITY)
    currentEvent = currentEvent:chainProgress(SCREEN_FLASH_DURATION, function(progress)
    end):chainEvent(function()
        effects:divideSpeed(DEATH_SPEED_MULTIPLIER)
        sound = Common.playSFX("GRAVITY", 0.5)
        origVolume = sound:getVolume()
    end)
    local _ev, duration
    self:shakeScreen(currentEvent, 4, 0.02)
    _ev, duration = currentEvent:findLast()
    entity.charactereffects.fillColor = entity.sprite.strokeColor
    currentEvent:chainProgress(duration / 2, function(progress)
        entity.charactereffects.fillOpacity = progress
    end)
    currentEvent = self.jump:chainRiseEvent(currentEvent, duration / 2):chainEvent(function()
        sound:stop()
        Common.playSFX("BOSS_DEATH_EXPLOSION")
    end)
    self:shakeScreen(currentEvent, 10, 0.0275)
    currentEvent:chainProgress(EXPLOSION_EXPAND_DURATION, function(progress)
        entity.charactereffects.fillOpacity = 1 - progress
        entity.sprite.opacity = 1 - progress
    end)
    currentEvent = self.explosion:chainExpandEvent(currentEvent, EXPLOSION_EXPAND_DURATION):chainEvent(function(_, anchor)
        self.entity.agentvisitor:visit(function(entity)
            if entity ~= self.entity then
                entity.tank.delayDeath = false
                entity.tank.preDeath = doNothing
                entity.tank.deathActionClass = ACTIONS_BASIC.DIE
                entity.tank.orbChance = 0
                entity.tank:kill(anchor)
            end

        end)
        self.entity.finalboss:clearEntities()
        self.itemDrop.item.opacity = 1
    end)
    return self.explosion:chainDisperseEvent(currentEvent, EXPLOSION_DISPERSE_DURATION):chainEvent(function(_, anchor)
        entity.body:removeFromGrid()
        entity.sprite.isRemoved = true
    end)
end

return DEATH

