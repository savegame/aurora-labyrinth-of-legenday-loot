local InputBlocker = class("widgets.widget")
function InputBlocker:initialize(director)
    InputBlocker:super(self, "initialize")
    director:subscribe(Tags.UI_CLEAR, self)
    self.blocker = self:addElement("blocker_wall", 0, 0)
    self.hideOnClear = false
end

function InputBlocker:checkMouseReception()
    if self.isVisible then
        return self.blocker
    else
        return false
    end

end

function InputBlocker:checkShortcutReception()
    if self.isVisible then
        return self.blocker
    else
        return false
    end

end

function InputBlocker:receiveMessage(message)
    if message == Tags.UI_CLEAR then
        if self.hideOnClear then
            self.isVisible = false
        else
            self:delete()
        end

    end

end

return InputBlocker

