local DockAbilities = class("widgets.widget")
local Common = require("common")
local Vector = require("utils.classes.vector")
local MEASURES = require("draw.measures")
local AbilityIcon = require("elements.ability_icon")
local ACCESSORY_SIZE = require("elements.accessory_icon").SIZE
local TERMS = require("text.terms")
local SLOTS = require("definitions.items").SLOTS_WITH_ABILITIES
local function getDisabledReason(entity, slot)
    local equipment = entity.equipment
    local sustained = equipment:getSustainedSlot()
                    if equipment:isSlotActive(slot) then
        return false
    elseif sustained then
        return "Can't cast while sustaining ability"
    elseif not equipment:isReady(slot) then
        return "On cooldown"
    elseif not equipment:hasManaForSlot(slot) then
        return "Not enough mana"
    elseif not equipment:hasHealthForSlot(slot) then
        return "Not enough health"
    else
        return false
    end

end

local function onAbilityTrigger(abilityIcon, widget)
    if widget._director:canDoTurn() then
        local equipment = widget._player.equipment
        local reason = getDisabledReason(widget._player, abilityIcon.slot)
        if reason then
            widget._director:publish(Tags.UI_CLEAR, false)
            widget._director:publish(Tags.UI_ABILITY_DISABLE_TRIGGER, reason)
        else
            if widget.selectedSlot == abilityIcon.slot then
                widget:castSelected()
            else
                widget:selectSlot(abilityIcon.slot)
            end

        end

    end

end

local function onAbilityHover(abilityIcon, widget, isHoveredExactly)
    if isHoveredExactly then
        local item = widget._player.equipment:get(abilityIcon.slot)
        if item then
            widget._director:publish(Tags.UI_ABILITY_MOUSEOVER, item)
        end

    end

end

local function isAbilityEnabled(abilityIcon, widget)
    local equipment = widget._player.equipment
    return toBoolean(equipment:getAbility(abilityIcon.slot))
end

local function isAbilityActivated(abilityIcon, widget)
    return widget.selectedSlot == abilityIcon.slot
end

local function hasAbilitySelected(abilityIcon, widget)
    return toBoolean(widget.selectedSlot)
end

local function onConfirmTrigger(control, widget)
    widget:castSelected()
end

local function onCancelTrigger(control, widget)
    widget:selectSlot(false)
end

local function isAbilityVisible(abilityIcon, widget)
    if abilityIcon.slot ~= Tags.SLOT_AMULET then
        return true
    end

    local equipment = widget._player.equipment
    return equipment:hasEquipped(Tags.SLOT_AMULET) and not equipment:hasEquipped(Tags.SLOT_WEAPON)
end

local MOBILE_LAYOUT = { [Tags.SLOT_WEAPON] = Vector:new(2, 2), [Tags.SLOT_GLOVES] = Vector:new(1, 2), [Tags.SLOT_HELM] = Vector:new(0, 2), [Tags.SLOT_ARMOR] = Vector:new(1.5, 1), [Tags.SLOT_BOOTS] = Vector:new(0.5, 1), [Tags.SLOT_AMULET] = Vector:new(2, 2) }
function DockAbilities:initialize(director, player)
    DockAbilities:super(self, "initialize")
    self._director = director
    self._player = player
    self.selectedSlot = false
    local iconSize = AbilityIcon:GetSize()
    local iconMargin = AbilityIcon:GetMargin()
    if PortSettings.IS_MOBILE then
        self.alignment = DOWN_RIGHT
        self.alignWidth = iconSize * 3 + iconMargin * 2
        self.alignHeight = iconSize * 3 + iconMargin * 2
        self:setPosition(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN)
    else
        self.alignment = DOWN
        self.alignWidth = iconSize * SLOTS:size() + iconMargin * (SLOTS:size() - 1)
        self.alignHeight = iconSize
        self:setPosition(0, MEASURES.MARGIN_SCREEN)
    end

    local currentX = 0
    local currentY = 0
    local slots = SLOTS:clone()
    slots:push(Tags.SLOT_AMULET)
    for i, slot in ipairs(slots) do
        if PortSettings.IS_MOBILE then
            local layout = MOBILE_LAYOUT[slot]
            currentX = (iconSize + iconMargin) * layout.x
            currentY = (iconSize + iconMargin) * layout.y
        end

        local abilityIcon
        if slot == Tags.SLOT_AMULET then
            abilityIcon = self:addElement("ability_icon", choose(PortSettings.IS_MOBILE, currentX, 0), currentY, slot, self._player, Tags["KEYCODE_ABILITY_1"])
        else
            abilityIcon = self:addElement("ability_icon", currentX, currentY, slot, self._player, Tags["KEYCODE_ABILITY_" .. i])
            currentX = currentX + iconSize + iconMargin
        end

        abilityIcon.input.isEnabled = isAbilityEnabled
        if PortSettings.IS_MOBILE then
            abilityIcon.input.onRelease = onAbilityTrigger
        else
            abilityIcon.input.onTrigger = onAbilityTrigger
            abilityIcon.input.onHover = onAbilityHover
        end

        abilityIcon.isActivated = isAbilityActivated
        abilityIcon.isVisible = isAbilityVisible
    end

    if PortSettings.IS_MOBILE then
        self:addElement("accessory_icon", -iconMargin - ACCESSORY_SIZE, (iconSize + iconMargin) * 2 + iconSize - ACCESSORY_SIZE, Tags.SLOT_RING, self._player)
    else
        local accessoryIcon = self:addElement("accessory_icon", currentX, iconSize - ACCESSORY_SIZE, Tags.SLOT_RING, self._player)
        accessoryIcon.input.onHover = onAbilityHover
    end

    local confirmControl = self:addElement("hidden_control")
    confirmControl.isVisible = hasAbilitySelected
    confirmControl.input.shortcut = Tags.KEYCODE_CONFIRM
    confirmControl.input.onTrigger = onConfirmTrigger
    local cancelControl = self:addElement("hidden_control")
    cancelControl.isVisible = hasAbilitySelected
    cancelControl.input.shortcut = Tags.KEYCODE_CANCEL
    cancelControl.input.onTrigger = onCancelTrigger
    director:subscribe(Tags.UI_CLEAR, self)
    if PortSettings.IS_MOBILE then
        director:subscribe(Tags.UI_SHOW_WINDOW_EQUIPMENT, self)
        director:subscribe(Tags.UI_SHOW_WINDOW_KEYWORDS, self)
        director:subscribe(Tags.UI_SHOW_ANVIL, self)
        director:subscribe(Tags.UI_HIDE_CONTROLS, self)
        director:subscribe(Tags.UI_SHOW_INTRO, self)
        director:subscribe(Tags.UI_ITEM_STEP, self)
    else
        director:subscribe(Tags.UI_MOUSE_BACKGROUND_TRIGGER, self)
        director:subscribe(Tags.UI_MOUSE_RIGHT_TRIGGER, self)
    end

end

function DockAbilities:selectSlot(slot)
    if slot then
        self._director:publish(Tags.UI_CLEAR, false)
    end

    self.selectedSlot = slot or false
    local ability = self._player.equipment:getAbility(slot)
    local isSlotActive = false
    if ability then
        isSlotActive = self._player.equipment:isSlotActive(slot)
    end

    self._director:publish(Tags.UI_ABILITY_SELECTED, ability, isSlotActive, self.selectedSlot)
end

function DockAbilities:isDirectionValid(ability, abilityStats)
    local directions = Utils.evaluate(ability.directions, self._player, abilityStats)
    return (not directions) or directions:contains(self._player.sprite.direction)
end

local DIRECTION_TO_STRING = { [RIGHT] = "RIGHT", [DOWN] = "DOWN", [LEFT] = "LEFT", [UP] = "UP" }
function DockAbilities:castSelected()
    local slot = self.selectedSlot
    local equipment = self._player.equipment
    local ability = equipment:getAbility(slot)
    local abilityStats = equipment:getSlotStats(slot)
    if equipment:isSlotActive(slot) then
        abilityStats:set(Tags.STAT_ABILITY_QUICK, 1)
        local action = self._player.actor:create(ability.modeCancelClass, self._player.sprite.direction, abilityStats)
        self._director:logAction("Cancel Mode - " .. tostring(slot))
        self._director:executePlayerAction(action)
    else
        local invalidReason = ability.getInvalidReason(self._player, self._player.sprite.direction, abilityStats)
        if not self._player.buffable:canMove() then
            if ability:hasTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED) then
                invalidReason = TERMS.INVALID_DIRECTION_IMMOBILIZED
            end

        end

        if invalidReason then
            self._director:publish(Tags.UI_ABILITY_INVALID_DIRECTION, invalidReason)
        else
            local action = self._player.actor:create(ability.actionClass, self._player.sprite.direction, abilityStats)
            equipment:consumeSlotResources(abilityStats)
            equipment:activateSlot(slot, action)
            self._director:logAction("Activate Slot - " .. tostring(slot) .. " " .. DIRECTION_TO_STRING[self._player.sprite.direction])
            self._director:publish(Tags.UI_TUTORIAL_CLEAR)
            self._director:executePlayerAction(action)
        end

    end

end

function DockAbilities:receiveMessage(message, ability, isSlotActive, slot)
                if message == Tags.UI_CLEAR then
        self:selectSlot(false)
        self.isVisible = true
    elseif message == Tags.UI_SHOW_WINDOW_EQUIPMENT or message == Tags.UI_SHOW_WINDOW_KEYWORDS or message == Tags.UI_ITEM_STEP or message == Tags.UI_SHOW_INTRO or message == Tags.UI_SHOW_ANVIL or message == Tags.UI_HIDE_CONTROLS then
        self.isVisible = false
    elseif message == Tags.UI_MOUSE_BACKGROUND_TRIGGER then
        if self.selectedSlot then
            self:castSelected()
        end

    elseif message == Tags.UI_MOUSE_RIGHT_TRIGGER then
        self:selectSlot(false)
    end

end

return DockAbilities

