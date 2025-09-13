PortSettings = {  }
PortSettings.IS_MOBILE = false
if love.system.getOS() == "AuroraOS" then
    PortSettings.IS_MOBILE = true
end
PortSettings.GAME_VERSION = 114
return PortSettings

