local WindowNewControl = class("widgets.window")
local Common = require("common")
local TERMS = require("text.terms")
local MEASURES = require("draw.measures")
local FONT = require("draw.fonts").MEDIUM
function WindowNewControl:initialize(director, temporaryProfile, profileField, keyCode, inputBlocker)
    local text = TERMS.UI.OPTIONS_NEW_CONTROL:format(TERMS.CONTROLS[keyCode])
    WindowNewControl:super(self, "initialize", 100)
    self._director = director
    self._temporaryProfile = temporaryProfile
    self._inputBlocker = inputBlocker
    self._profileField = profileField
    self.keyCode = keyCode
    local height = FONT.height + MEASURES.MARGIN_INTERNAL * 2 + 4
    self.textElement = self:addElement("text_special", MEASURES.MARGIN_INTERNAL + 2, MEASURES.MARGIN_INTERNAL + 2, text, FONT)
    self.window.rect.width = self.textElement:getWidth() + MEASURES.MARGIN_INTERNAL * 2 + 4
    self.window.rect.height = height
    self.alignment = CENTER
    self.alignWidth = self.window.rect.width
    self.alignHeight = self.window.rect.height
    self.firstFrame = true
end

function WindowNewControl:update(...)
    WindowNewControl:super(self, "update", ...)
    if self.firstFrame then
        self.firstFrame = false
    else
        local rawKey
        if self._profileField == "codeToKey" then
            rawKey = self._director:getRawKeyReleased()
        else
            rawKey = self._director:getRawButtonReleased()
        end

        if rawKey then
            Common.playSFX("CONFIRM")
            self._temporaryProfile[self._profileField]:set(self.keyCode, rawKey)
            self:delete()
            self._inputBlocker:delete()
        end

    end

end

return WindowNewControl

