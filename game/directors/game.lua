Tags.add("UI_ABILITY_SELECTED")
Tags.add("UI_ABILITY_DISABLE_TRIGGER")
Tags.add("UI_ABILITY_INVALID_DIRECTION")
Tags.add("UI_CAST_TURN")
Tags.add("UI_SHOW_WINDOW_PAUSE")
Tags.add("UI_SHOW_WINDOW_EQUIPMENT")
Tags.add("UI_SHOW_WINDOW_KEYWORDS")
Tags.add("UI_SHOW_INTRO")
Tags.add("UI_SHOW_ANVIL")
Tags.add("UI_HIDE_CONTROLS")
Tags.add("UI_ABILITY_NOTIFY")
Tags.add("UI_ABILITY_MOUSEOVER")
Tags.add("UI_SCRAP_CHANGED")
Tags.add("UI_GAMEOVER")
Tags.add("UI_TUTORIAL_PROCEED")
Tags.add("UI_TUTORIAL_ITEM_MESSAGE")
Tags.add("UI_TUTORIAL_CLEAR")
Tags.add("UI_ITEM_STEP")
Tags.add("UI_ITEM_EQUIP")
Tags.add("UI_HEALTH_ORB_KILL")
Tags.add("UI_HEALTH_ORB_PICKUP")
Tags.add("UI_DESTRUCTIBLE_KILL")
Tags.add("UI_REFRESH_EXPLORED")
Tags.add("UI_MOUSE_TILE_CHANGED")
Tags.add("UI_MOUSE_BACKGROUND_TRIGGER")
Tags.add("UI_MOUSE_BACKGROUND_PRESS")
Tags.add("UI_MOUSE_RIGHT_TRIGGER")
local DirectorGame = class("directors.director")
local Array = require("utils.classes.array")
local MessagePack = require("messagepack")
local Common = require("common")
local Global = require("global")
local MEASURES = require("draw.measures")
local COLORS = require("draw.colors")
local ACTIONS_BASIC = require("actions.basic")
local ACTION_CONSTANTS = require("actions.constants")
local FILENAMES = require("text.filenames")
local TERMS = require("text.terms")
local MorgueEntry = require("structures.morgue_entry")
local Item = require("structures.item")
local BLOCKER_OPACITY_PAUSE = 0.45
local BLOCKER_OPACITY_GAMEOVER = 0.25
function DirectorGame:initialize()
    DirectorGame:super(self, "initialize")
    self:setDependencies("timing", "turn", "level", "player", "frontinteractive", "caster", "indicator", "castingguide", "vision", "parallelscheduler", "viewport", "coordinates", "controls", "serializable", "createEntity")
    self._player = false
    self.pauseBlocker = false
    self.minimap = false
    self.currentRun = false
    self.currentFloor = 1
    self.currentFloorSeed = false
    self.hoveredItem = false
    self.hoverDelayDestroy = false
    self.hoverWindow = false
    self.actionList = Array:new()
end

function DirectorGame:createWidgets(currentRun)
    self.currentRun = currentRun
    self.currentFloor = currentRun.currentFloor
    local player = self.services.player:get()
    self._player = player
    if not PortSettings.IS_MOBILE then
        self:createWidget("background_input", self, self.services.viewport, self.services.coordinates, self.services.vision)
    end

    self.minimap = self:createWidget("minimap", self, self.services.level, self.services.vision:get(), self.services.indicator)
    self:createWidget("dock_window_buttons", self)
    self:createWidget("controls_movement", self, player, self.services.frontinteractive, self.services.caster)
    self:createWidget("dock_abilities", self, player)
    self:createWidget("ability_notification", self)
    local resources = self:createWidget("resources", self, player)
    self:createWidget("window_equipment", self, player)
    self:createWidget("window_keyword_list", self)
    self:createWidget("sustain_guide", self, player.equipment)
    if currentRun.currentFloor < 1 then
        self:createWidget("tutorial_guide", self)
    end

    local displayFloor = self:createWidget("display_floor", currentRun)
    self:createWidget("display_scrap", self, player.wallet, resources.barMana.rect.width, displayFloor.alignWidth)
    self.pauseBlocker = self:createInputBlocker()
    self.pauseBlocker.blocker.targetOpacity = BLOCKER_OPACITY_PAUSE
    self.pauseBlocker.isVisible = false
    self.pauseBlocker.hideOnClear = true
    self:createWidget("window_pause", self)
    self:createWidget("title.window_options", self, true)
    self:publish(Tags.UI_CLEAR, true)
end

function DirectorGame:getCurrentFloor()
    return self.currentRun.currentFloor
end

function DirectorGame:getTimePassed()
    return self.services.timing.timePassed
end

function DirectorGame:receiveMessage(message,...)
    local args = Array:new(...)
                        if message == Tags.UI_GAMEOVER then
        local currentRun = Global:get(Tags.GLOBAL_CURRENT_RUN)
        filesystem.remove(FILENAMES.CURRENT_RUN)
        filesystem.remove(FILENAMES.CURRENT_FLOOR)
        Global:deleteKey(Tags.GLOBAL_CURRENT_RUN)
        self:publish(Tags.UI_CLEAR, true)
        self:createInputBlocker().blocker.targetOpacity = BLOCKER_OPACITY_GAMEOVER
        local profile = Global:get(Tags.GLOBAL_PROFILE)
        if Item:isInstance(args[1]) then
            self._player.equipment:recordWin()
            self:publish(Tags.UI_HIDE_CONTROLS)
            Common.playStinger("VICTORY")
            local unlockedDifficulty = profile.playData:get("unlockedDifficulty")
            if unlockedDifficulty < TERMS.UI.OPTIONS_DIFFICULTY:size() and currentRun.difficulty + 2 > unlockedDifficulty then
                unlockedDifficulty = unlockedDifficulty + 1
                profile.playData:set("unlockedDifficulty", unlockedDifficulty)
            else
                unlockedDifficulty = false
            end

            profile:savePlayData()
            self:createWidget("window_victory", self, unlockedDifficulty)
        else
            self._player.equipment:recordDeath()
            Common.playStinger("DEFEAT")
            self:createWidget("window_gameover", self, currentRun, args[1])
        end

        profile:addMorgueEntry(MorgueEntry:new(self._player, args[1], currentRun))
        profile:saveItemStats()
    elseif message == Tags.UI_SHOW_WINDOW_PAUSE then
        if not self.pauseBlocker.isVisible then
            self.pauseBlocker.blocker.opacity = 0
            self.pauseBlocker.isVisible = true
        end

    elseif message == Tags.UI_ITEM_STEP then
        Global:get(Tags.GLOBAL_PROFILE):discoverItem(args[1])
        self:createGroundItemWindows(args[1], args[2])
    elseif message == Tags.UI_SHOW_INTRO then
        self:createWidget("window_intro", self)
    elseif message == Tags.UI_SHOW_ANVIL then
        self:createAnvilWindow(args[1], args[2])
    elseif message == Tags.UI_ABILITY_MOUSEOVER then
        self.hoverDelayDestroy = true
        if self.hoveredItem ~= args[1] then
            if self.hoverWindow then
                self.hoverWindow:delete()
            end

            self.hoverWindow = self:createWidget("window_ability_mouseover", self, args[1])
            self.hoveredItem = args[1]
        end

    end

end

function DirectorGame:updateWidgets(dt)
    if self.hoverDelayDestroy then
        self.hoverDelayDestroy = false
    else
        if self.hoverWindow then
            self.hoverWindow:delete()
            self.hoverWindow = false
            self.hoveredItem = false
        end

    end

    DirectorGame:super(self, "updateWidgets", dt)
end

function DirectorGame:canDoTurn()
    return self._player.tank:isAlive() and self.services.turn:canDoTurn()
end

function DirectorGame:executePlayerAction(action)
    self:publish(Tags.UI_CLEAR, true)
    self.services.turn:executeActionForTurn(action)
end

function DirectorGame:getCancelModeAction(slot)
    local equipment = self._player.equipment
    local ability = equipment:getAbility(slot)
    local abilityStats = equipment:getSlotStats(slot)
    return self._player.actor:create(ability.modeCancelClass, self._player.sprite.direction, abilityStats)
end

function DirectorGame:startTurnWithWait(dontClear)
    local action = self._player.actor:create(ACTIONS_BASIC.WAIT_PLAYER)
    if not dontClear then
        self:executePlayerAction(action)
    else
        self.services.turn:executeActionForTurn(action)
    end

end

local FLASH_COLOR = COLORS.NORMAL:withAlpha(0.5)
function DirectorGame:startTurnWithFlashWait(dontClear)
    self:flashPlayer()
    self:startTurnWithWait(dontClear)
end

function DirectorGame:getPlayer()
    return self._player
end

function DirectorGame:flashPlayer()
    self._player.charactereffects:flash(ACTION_CONSTANTS.NEGATIVE_FADE_DURATION, FLASH_COLOR)
end

function DirectorGame:destroyAnvil(anvil)
    anvil.tank:killNoTrigger(self.services.parallelscheduler:createEvent())
end

function DirectorGame:decorateSaveRatios(fn)
    local healthRatio = self._player.tank:getRatio()
    local manaRatio = self._player.mana:getRatio()
    fn(self._player)
    self._player.tank:setRatio(healthRatio)
    self._player.mana:setRatio(manaRatio)
end

function DirectorGame:createItemWindow(windowClass, item, alignment, itemEntity)
    local itemWindow = self:createWidget(windowClass, self, item, itemEntity)
    itemWindow:setAlignSide(alignment)
    return itemWindow
end

function DirectorGame:getLeftAlignWidth()
    local scW, scH = self.services.viewport:getScreenDimensions()
    local fromCenter = MEASURES.MARGIN_ITEM_WINDOW + MEASURES.WIDTH_ITEM_WINDOW * 2
    return min(fromCenter, scW - MEASURES.MARGIN_SCREEN * 2)
end

function DirectorGame:getRightAlignWidth()
    local scW, scH = self.services.viewport:getScreenDimensions()
    local fromCenter = MEASURES.MARGIN_ITEM_WINDOW
    return -min(fromCenter, (scW / 2 - MEASURES.WIDTH_ITEM_WINDOW - MEASURES.MARGIN_SCREEN) * 2)
end

function DirectorGame:createGroundItemWindows(item, itemEntity)
    local slot = item:getSlot()
    local currentItem = self._player.equipment:get(slot)
        if slot == Tags.SLOT_AMULET and item.modifierDef and item.modifierDef.isLegendary then
        self:createItemWindow("window_item_final", item, CENTER, itemEntity)
    elseif currentItem then
        local iwCurrent = self:createItemWindow("window_item_compare", currentItem, LEFT)
        local iwNew = self:createItemWindow("window_item_ground", item, RIGHT, itemEntity)
        iwCurrent.alignHeight = max(iwCurrent.alignHeight, iwNew.alignHeight)
        iwNew.alignHeight = iwCurrent.alignHeight
        iwCurrent.buttonClose.isVisible = false
    else
        self:createItemWindow("window_item_ground", item, CENTER, itemEntity)
    end

end

function DirectorGame:createAfterInfuseWindow(item)
    local windowOld = self:createItemWindow("window_item_compare", self._player.equipment:get(item:getSlot()), LEFT, false)
    windowOld.buttonClose.isVisible = false
    local windowNew = self:createItemWindow("window_item_anvil_new", item, RIGHT, false)
end

function DirectorGame:createAnvilWindow(anvilEntity, isGolden)
    self:createWidget("window_anvil", self, self._player, anvilEntity, isGolden)
end

function DirectorGame:startTurnWithEquip(itemEntity)
    local action = self._player.actor:create(ACTIONS_BASIC.EQUIP)
    action:setItemEntity(itemEntity)
    self:executePlayerAction(action)
end

function DirectorGame:startTurnWithUnequip(slot)
    local action = self._player.actor:create(ACTIONS_BASIC.UNEQUIP)
    action.slot = slot
    self:executePlayerAction(action)
end

function DirectorGame:startTurnWithVictory()
    local action = self._player.actor:create(ACTIONS_BASIC.VICTORY)
    self:logAction("Victory")
    self:executePlayerAction(action)
end

function DirectorGame:startTurnWithEquipFinal(itemEntity)
    local action = self._player.actor:create(ACTIONS_BASIC.EQUIP_FINAL)
    action.itemEntity = itemEntity
    self:executePlayerAction(action)
end

function DirectorGame:addScrap(amount)
    self._player.wallet:add(amount)
end

function DirectorGame:getScrap()
    return self._player.wallet:get()
end

function DirectorGame:getRawKeyReleased()
    return self.services.controls.rawKeyReleased
end

function DirectorGame:getRawButtonReleased()
    return self.services.controls.rawButtonReleased
end

function DirectorGame:hasSpaceForScrap(amount)
    return self._player.wallet:hasSpaceFor(amount)
end

function DirectorGame:isTutorial()
    return self.currentFloor == 0
end

function DirectorGame:saveGame()
    if not self:isTutorial() and not self.screenTransitioning and self._player.tank:isAlive() then
        self.currentRun:save()
        self.services.serializable:saveAll()
        Global:get(Tags.GLOBAL_PROFILE):saveItemStats()
    end

end

function DirectorGame:spawnTutorialEnemy(enemy, offset)
    local playerPosition = self._player.body:getPosition()
    local position = playerPosition + offset
    local enemy = self.services.createEntity("enemies." .. enemy, position, Common.getDirectionTowards(position, playerPosition), enemy, Tags.DIFFICULTY_NORMAL, false, 0)
    enemy.agent.hasSeenPlayer = true
end

function DirectorGame:logAction(action)
    Debugger.log("Action: " .. action)
    self.actionList:push(action)
end

return DirectorGame

