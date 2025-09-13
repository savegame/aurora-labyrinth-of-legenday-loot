local TutorialGuide = class("widgets.widget")
local Vector = require("utils.classes.vector")
local Common = require("common")
local FONT = require("draw.fonts").MEDIUM
local MEASURES = require("draw.measures")
local MARGIN = 5
local AbilityIcon = require("elements.ability_icon")
local GAME_MENU_SIZE = require("elements.button_game_menu").SIZE
local TEXT_TUTORIAL = require("text.tutorial")
local RESOURCE_HEIGHT = require("elements.resource_bar").HEIGHT
function TutorialGuide:initialize(director)
    TutorialGuide:super(self, "initialize")
    self._director = director
    self.alignment = DOWN
    self.noText = false
    local height = FONT.height * 2 + MARGIN * 3 + 2
    self.window = self:addElement("window", 0, 0, 100, height)
    self.window.hasBorder = false
    self.text1 = self:addElement("text_special", 0, MARGIN, "", FONT)
    self.text1.alignment = UP
    self.text2 = self:addElement("text_special", 0, height - MARGIN - FONT.height, "", FONT)
    self.text2.alignment = UP
    self.origY = false
    if PortSettings.IS_MOBILE then
        self.alignment = UP
        self.origY = MEASURES.MARGIN_SCREEN * 2 + GAME_MENU_SIZE
        self:setPosition(0, self.origY)
    else
        self:setPosition(0, MEASURES.MARGIN_SCREEN * 2 + AbilityIcon:GetSize() + height + 2)
    end

    self.tutorialIndex = 1
    self.showedNotify = false
    self.isVisible = function(self)
        if self.noText then
            return false
        end

        return true
    end
    self:setLines(TEXT_TUTORIAL.getLines(self.tutorialIndex))
    director:subscribe(Tags.UI_ABILITY_NOTIFY, self)
    director:subscribe(Tags.UI_CLEAR, self)
    director:subscribe(Tags.UI_TUTORIAL_PROCEED, self)
    director:subscribe(Tags.UI_TUTORIAL_ITEM_MESSAGE, self)
    director:subscribe(Tags.UI_TUTORIAL_CLEAR, self)
    director:subscribe(Tags.UI_ITEM_STEP, self)
    director:subscribe(Tags.UI_ITEM_EQUIP, self)
    director:subscribe(Tags.UI_HEALTH_ORB_KILL, self)
    director:subscribe(Tags.UI_DESTRUCTIBLE_KILL, self)
    director:subscribe(Tags.UI_HEALTH_ORB_PICKUP, self)
    director:subscribe(Tags.UI_SHOW_WINDOW_EQUIPMENT, self)
end

function TutorialGuide:receiveMessage(message, arg1)
                                            if message == Tags.UI_ABILITY_NOTIFY then
        if not self.showedNotify then
            self:setLines(TEXT_TUTORIAL.getItemLines(3))
            self.showedNotify = true
        else
            self:setLines(false, false)
        end

    elseif message == Tags.UI_TUTORIAL_CLEAR then
        self:setLines(false, false)
    elseif message == Tags.UI_CLEAR then
        if not arg1 then
            self:setLines(false, false)
        end

    elseif message == Tags.UI_TUTORIAL_PROCEED then
        self.tutorialIndex = self.tutorialIndex + 1
        self:setLines(TEXT_TUTORIAL.getLines(self.tutorialIndex))
    elseif message == Tags.UI_ITEM_STEP then
        local item = arg1
                        if item:getSlot() == Tags.SLOT_GLOVES then
            self:setLines(TEXT_TUTORIAL.getItemLines(1))
        elseif item:getSlot() == Tags.SLOT_WEAPON then
            if item:getAbility() then
                self:setLines(TEXT_TUTORIAL.getItemLines(4))
            else
                self:setLines(TEXT_TUTORIAL.getItemLines(5))
            end

        elseif item:getSlot() == Tags.SLOT_ARMOR then
            self:setLines(TEXT_TUTORIAL.getItemLines(6))
            if PortSettings.IS_MOBILE then
                self:setPosition(0, self.origY - 12)
            end

        end

    elseif message == Tags.UI_HEALTH_ORB_KILL then
        local isElite = arg1
        if isElite then
            self:setLines(TEXT_TUTORIAL.getHealthOrbLines(2))
        else
            self:setLines(TEXT_TUTORIAL.getHealthOrbLines(1))
        end

    elseif message == Tags.UI_DESTRUCTIBLE_KILL then
        if arg1 and arg1:getPrefab() ~= "rock" then
            self:setLines(TEXT_TUTORIAL.getLines(18))
        end

    elseif message == Tags.UI_HEALTH_ORB_PICKUP then
        local isElite = arg1
        if isElite then
            self._director:getPlayer().wallet:add(10)
            self:setLines(TEXT_TUTORIAL.getHealthOrbLines(3))
        else
            self:setLines(false, false)
        end

    elseif message == Tags.UI_ITEM_EQUIP then
        local item = arg1
                if item:getSlot() == Tags.SLOT_GLOVES then
            self:setLines(TEXT_TUTORIAL.getItemLines(2))
            self._director:getPlayer().equipment:resetCooldown(Tags.SLOT_GLOVES)
            self._director:spawnTutorialEnemy("slime", Vector:new(-4, 0))
            self._director:startTurnWithWait()
        elseif item:getSlot() == Tags.SLOT_ARMOR then
            self:setLines(false, false)
        end

    elseif message == Tags.UI_TUTORIAL_ITEM_MESSAGE then
        local item = arg1
        if item:getAbility() then
            if item:getSlot() == Tags.SLOT_WEAPON then
                self:setLines(TEXT_TUTORIAL.getItemLines(4))
            end

        end

    elseif message == Tags.UI_SHOW_WINDOW_EQUIPMENT then
        local player = self._director:getPlayer()
        if player.wallet:get() > 10 then
            self:setLines(TEXT_TUTORIAL.getItemLines(7))
        end

        if PortSettings.IS_MOBILE then
            self:setPosition(0, MEASURES.MARGIN_SCREEN * 2 + RESOURCE_HEIGHT)
        end

    end

end

function TutorialGuide:setLines(line1, line2)
    if not line1 then
        self.noText = true
        if self.origY then
            self:setPosition(0, self.origY)
        end

        return 
    else
        self.noText = false
    end

    self.text1:setText(line1)
    self.text2:setText(line2)
    local w1, w2 = self.text1:getWidth(), self.text2:getWidth()
    local maxWidth = max(w1, w2)
    self.window.rect.width = maxWidth + (MARGIN + 1) * 2
    self.alignWidth = self.window.rect.width
    self.text1:setX(self.alignWidth / 2)
    self.text2:setX(self.alignWidth / 2)
end

function TutorialGuide:update(...)
    TutorialGuide:super(self, "update", ...)
end

return TutorialGuide

