local Resources = class("widgets.widget")
local MEASURES = require("draw.measures")
local BAR_WIDTH = MEASURES.WIDTH_RESOURCE_BAR
local BAR_HEIGHT = require("elements.resource_bar").HEIGHT
local GAME_MENU_SIZE = require("elements.button_game_menu").SIZE
local BAR_MARGIN = MEASURES.MARGIN_INTERNAL
function Resources:initialize(director, player)
    Resources:super(self, "initialize")
    self._equipment = player.equipment
    if PortSettings.IS_MOBILE then
        self.alignment = UP
        self.alignWidth = BAR_WIDTH * 2 + BAR_MARGIN
        self.alignHeight = BAR_HEIGHT
    else
        self.alignment = DOWN_LEFT
        self.alignWidth = BAR_WIDTH
        self.alignHeight = BAR_HEIGHT * 2 + BAR_MARGIN
    end

    self:setPosition(MEASURES.MARGIN_SCREEN, MEASURES.MARGIN_SCREEN)
    self.barHealth = self:addElement("resource_bar", 0, 0, BAR_WIDTH, player.tank)
    if PortSettings.IS_MOBILE then
        self.barMana = self:addElement("resource_bar", BAR_WIDTH + BAR_MARGIN, 0, BAR_WIDTH, player.mana)
    else
        self.barMana = self:addElement("resource_bar", 0, BAR_HEIGHT + BAR_MARGIN, BAR_WIDTH, player.mana)
    end

    director:subscribe(Tags.UI_ABILITY_SELECTED, self)
end

function Resources:update(dt, serviceViewport)
    Resources:super(self, "update", dt, serviceViewport)
    if PortSettings.IS_MOBILE then
        local scW, scH = serviceViewport:getScreenDimensions()
        local maxWidth = scW / 2 - BAR_MARGIN / 2 - MEASURES.MARGIN_SCREEN * 2 - MEASURES.MARGIN_BUTTON * 2 - GAME_MENU_SIZE * 3
        self.barHealth.rect.width = min(maxWidth, BAR_WIDTH)
        self.barMana.rect.width = self.barHealth.rect.width
        self.barMana:setPosition(self.barHealth.rect.width + BAR_MARGIN, self.barMana.position.y)
        self.alignWidth = self.barHealth.rect.width * 2 + BAR_MARGIN
    end

end

function Resources:receiveMessage(message, ability, isSlotActive, slot)
    if Tags.UI_ABILITY_SELECTED then
        self.barMana:setPotentialConsume(false)
        self.barHealth:setPotentialConsume(false)
        if ability and not isSlotActive then
            local manaCost = self._equipment:getSlotManaCost(slot)
            if manaCost > 0 then
                self.barMana:setPotentialConsume(manaCost)
            end

            local healthCost = self._equipment:getSlotHealthCost(slot)
            if healthCost > 0 then
                self.barHealth:setPotentialConsume(healthCost)
            end

        end

    end

end

return Resources

