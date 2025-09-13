local Benchmarker = class()
local Hash = require("utils.classes.hash")
local Record = struct("totalDuration", "instances")
function Benchmarker:initialize()
    self.timers = Hash:new()
    self.records = Hash:new()
end

function Benchmarker:start(timerName)
    self.timers:set(timerName, timer.getTime())
end

function Benchmarker:stop(timerName)
    local currentTime = timer.getTime()
    Utils.assert(self.timers:hasKey(timerName), "Benchmark timer '%s' does not exist", timerName)
    if not self.records:hasKey(timerName) then
        self.records:set(timerName, Record:new(0, 0))
    end

    local record = self.records:get(timerName)
    record.totalDuration = record.totalDuration + (currentTime - self.timers:get(timerName))
    record.instances = record.instances + 1
end

local FORMAT = "%15s - %.2f ms - %.2f%% frame"
function Benchmarker:getAsStrings()
    local keys = self.records:keys():unstableSort()
    return keys:map(function(key)
        local record = self.records:get(key)
        local seconds = record.totalDuration / record.instances
        return FORMAT:format(key, seconds * 1000, 100 * seconds / (1 / 60))
    end)
end

return Benchmarker

