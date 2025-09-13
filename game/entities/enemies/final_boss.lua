local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local BUFFS = require("definitions.buffs")
local Common = require("common")
local ACTION_CONSTANTS = require("actions.constants")
local ActionUtils = require("actions.utils")
local ATTACK_UNARMED = require("actions.attack_unarmed")
local FINAL_BOSS_ACTIONS = require("actions.final_boss")
local LogicMethods = require("logic.methods")
local CONSTANTS = require("logic.constants")
local ENEMIES = require("definitions.enemies")
local COOLDOWN_MODE_SUMMON = 28
Tags.add("BOSS_TIMER_ABILITY", 1)
Tags.add("BOSS_TIMER_MODE_SUMMON", 2)
local COLORS = require("draw.colors")
local COLOR_MELEE = COLORS.ELITE_BOSS_MELEE
local COLOR_RANGED = COLORS.ELITE_BOSS_RANGED
local SkillDef = require("structures.skill_def")
local MODE_SUMMON = class("actions.action")
function MODE_SUMMON:initialize(entity, direction, abilityStats)
    MODE_SUMMON:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
end

local MODE_FILL_DURATION = 0.3
local Controller = BUFFS:define("BOSS_CONTROLLER")
function MODE_SUMMON:process(currentEvent)
    Common.playSFX("CAST_CHARGE")
    local entity = self.entity
    local controller = entity.buffable:findOneWithClass(Controller)
    if controller.isMelee then
        entity.charactereffects.fillColor = COLOR_RANGED
        self.lightningspawner.color = COLOR_RANGED
    else
        entity.charactereffects.fillColor = COLOR_MELEE
        self.lightningspawner.color = COLOR_MELEE
    end

    return currentEvent:chainProgress(MODE_FILL_DURATION, function(progress)
        entity.charactereffects.fillOpacity = progress
    end):chainEvent(function(_, anchor)
        controller:toggleModes(entity)
        entity.turntimer:setOnCooldown(Tags.BOSS_TIMER_MODE_SUMMON)
        local summonPositions = ActionUtils.getAreaPositions(entity, entity.body:getPosition(), Tags.ABILITY_AREA_ROUND_5X5, true)
        local logicRNG = self:getLogicRNG()
        summonPositions:shuffleSelf(logicRNG)
        local toSummon = Array:new()
        if not DebugOptions.FINAL_BOSS_NO_SUMMON then
            if logicRNG:rollChance(0.5) then
                toSummon:push("magma_archer")
            else
                toSummon:push("purple_dragon")
            end

            if controller.summonedCount == 1 then
                toSummon:push("magma_elemental")
                toSummon:push("magma_goblin")
            else
                if logicRNG:rollChance(0.5) then
                    toSummon:push("magma_elemental")
                else
                    toSummon:push("magma_goblin")
                end

            end

        end

        local playerPos = entity.agent:getPlayer().body:getPosition()
        Common.playSFX("LIGHTNING")
        for position in summonPositions() do
            if toSummon:isEmpty() then
                break
            end

            if self.entity.body:isPassable(position) then
                local thisPosition = position
                local thisSummon = toSummon:pop()
                self.lightningspawner:spawn(anchor, thisPosition):chainEvent(function(_, anchor)
                    local enemy = entity.entityspawner:spawnEnemy(thisSummon, thisPosition, Common.getDirectionTowards(thisPosition, playerPos), 1)
                    enemy.charactereffects:flash(ACTION_CONSTANTS.NEGATIVE_FADE_DURATION, self.lightningspawner.color)
                    enemy.tank.orbChance = 1
                    enemy.agent.hasSeenPlayer = true
                    enemy.body:catchProjectilesAt(anchor, thisPosition)
                    enemy.body:stepAt(anchor, thisPosition)
                end)
            end

        end

    end):chainProgress(MODE_FILL_DURATION, function(progress)
        entity.charactereffects.fillOpacity = 1 - progress
    end)
end

function Controller:initialize()
    Controller:super(self, "initialize", math.huge)
    self.summonedCount = 0
    self.isMelee = DebugOptions.FINAL_BOSS_RANGED
end

function Controller:onApply(entity)
    if self.isMelee then
        entity.sprite.strokeColor = COLOR_MELEE
        entity.melee.enabled = true
        entity.ranged.cooldown = math.huge
        entity.agent.avoidsReserved = false
        entity.caster.skill = FINAL_BOSS_ACTIONS.TRIPLE_CLAW
        entity.caster:setOnCooldown()
    else
        entity.sprite.strokeColor = COLOR_RANGED
        entity.melee.enabled = false
        entity.ranged.cooldown = 0
        entity.agent.avoidsReserved = true
        entity.caster.skill = FINAL_BOSS_ACTIONS.ARCANE_SHOWER
        entity.caster:setOnCooldown()
    end

end

function Controller:toggleModes(entity)
    self.isMelee = (not self.isMelee)
    self:onApply(entity)
end

function Controller:toData()
    return { summonedCount = self.summonedCount, isMelee = self.isMelee }
end

function Controller:fromData(data)
    self.summonedCount = data.summonedCount
    self.isMelee = data.isMelee
end

function Controller:onTurnStart(anchor, entity)
    if self.summonedCount <= 1 and entity.tank:getRatio() < 0.5 then
        entity.turntimer:refreshCooldown(Tags.BOSS_TIMER_MODE_SUMMON)
    end

    if entity.turntimer:isReady(Tags.BOSS_TIMER_MODE_SUMMON) then
        if not entity.buffable:isAffectedBy(BUFFS:get("BOSS_ARCANE_SHOWER")) then
            entity.agent.priorityAction = entity.actor:create(MODE_SUMMON, entity.sprite.direction)
            entity.turntimer:setOnInfinite(Tags.BOSS_TIMER_MODE_SUMMON)
            self.summonedCount = self.summonedCount + 1
        end

    end

end

return function(entity, position, direction, id, difficulty)
    require("entities.common_enemy")(entity, position, direction, id, difficulty, false)
    entity.label.properNoun = true
    entity.sprite:setCell(5, 6)
    entity.sprite.strokeColor = COLOR_RANGED
    entity.sprite.opacity = 0
    entity.tank.drawBar = false
    entity.tank.deathActionClass = FINAL_BOSS_ACTIONS.DEATH
    entity:addComponent("melee")
    entity.melee.attackClass = ATTACK_UNARMED.CLAW_AND_DAMAGE
    entity:addComponent("turntimer")
    entity.turntimer:setCooldown(Tags.BOSS_TIMER_MODE_SUMMON, COOLDOWN_MODE_SUMMON)
    local genericSkill = SkillDef:new()
    genericSkill.cooldown = math.huge
    genericSkill.getCastDirection = alwaysFalse
    entity:addComponent("caster", genericSkill)
    entity.caster:setOnCooldown()
    entity:addComponent("projectilespawner")
    entity.projectilespawner:setCell(3, 1)
    entity.projectilespawner.isMagical = true
    entity:addComponent("ranged")
    entity.ranged.attackClass = FINAL_BOSS_ACTIONS.RANGED_ATTACK
    entity.ranged.attackCooldown = 2
    entity.ranged.alignBackOff = true
    entity.ranged.fireOffCenter = true
    entity.buffable:forceApply(Controller:new())
    entity:addComponent("agentvisitor")
    entity:addComponent("entityspawner")
    entity.entityspawner.enemyDifficulty = difficulty
    entity:addComponent("finalboss")
end

