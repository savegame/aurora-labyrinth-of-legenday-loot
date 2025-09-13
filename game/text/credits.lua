local Array = require("utils.classes.array")
local CreditEntry = struct("label", "name", "extra")
return Array:new(CreditEntry:new("Created By", "Dominaxis Games", "dominaxisgames@gmail.com"), CreditEntry:new("Game Design & Programming", "Julian Villaruz"), CreditEntry:new("Art", "Oryx Design Lab (www.oryxdesignlab.com)", "majdulf"), CreditEntry:new("Music", "rerolltimes100"), CreditEntry:new("Sounds", "Daydream Sound"), CreditEntry:new("Made with:", "LOVE 2D Game Engine (www.love2d.org)"), CreditEntry:new("Special Thanks", "cezille07, Raniel Capispisan, Chynna Cordevilla"))

