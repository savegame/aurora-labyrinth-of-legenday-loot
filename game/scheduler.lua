local Scheduler = class("services.service")
local Array = require("utils.classes.array")
local Set = require("utils.classes.set")
local Event = class()
local Progress = class(Event)
local WaitGroup = class(Event)
function Event:initialize(scheduler, callback, repeatInterval)
    self._scheduler = scheduler
    self.callback = callback or doNothing
    self.repeatInterval = false
    if repeatInterval then
        self.repeatInterval = repeatInterval
    end

    self.onFinish = false
    self.schedule = false
    self._isFinished = false
end

function Event:_addOnFinish(event)
    if not self.onFinish then
        self.onFinish = Array:new()
    end

    Utils.assert(not self._isFinished, "Chaining to an event that's already finished")
    self.onFinish:push(event)
    return event
end

function Event:chainEvent(callback, repeatInterval)
    local nextEvent = Event:new(self._scheduler, callback, repeatInterval)
    self:_addOnFinish(nextEvent)
    return nextEvent
end

function Event:chainProgress(duration, callback, easing)
    local nextProgress = Progress:new(self._scheduler, duration, callback, easing)
    self:_addOnFinish(nextProgress)
    return nextProgress
end

local ASSERT_NOT_WAITGROUP = "Argument for chainWaitGroupDone is not a WaitGroup"
function Event:chainWaitGroupDone(waitGroup)
    Utils.assert(WaitGroup:isInstance(waitGroup), ASSERT_NOT_WAITGROUP)
    self:_addOnFinish(waitGroup)
    return waitGroup
end

function Event:call(progressOrTime)
    return self.callback(progressOrTime, self)
end

function Event:findLast()
    local totalDuration = 0
    if Progress:isInstance(self) then
        totalDuration = totalDuration + self.duration
    end

    if self.onFinish then
        local maxEvent = nil
        local maxDuration = 0
        for onFinish in self.onFinish() do
            local event, duration = onFinish:findLast()
            if duration >= maxDuration then
                maxEvent = event
                maxDuration = duration
            end

        end

        return maxEvent, totalDuration + maxDuration
    else
        return self, totalDuration
    end

end

function Event:stop()
    self._scheduler:stopEvent(self)
end

function Event:createWaitGroup(...)
    return self._scheduler:createWaitGroup(...)
end

Tags.add("PROGRESS_CREATED", 0)
Tags.add("PROGRESS_RUNNING", 1)
Tags.add("PROGRESS_ENDING", 2)
function Progress:initialize(scheduler, duration, callback, easing)
    Progress:super(self, "initialize", scheduler, callback)
    self.state = Tags.PROGRESS_CREATED
    self.duration = duration
    self.easing = easing or returnSelf
    self.lastValue = -1
end

function Progress:updateProgress(currentTime)
    local schedule = self.schedule
    if self.state == Tags.PROGRESS_ENDING then
        schedule = self.schedule - self.duration
    end

    local value = (currentTime - schedule) / self.duration
    if value > 0 and self.lastValue < value then
        self.lastValue = value
        return self:call(bound(self.easing(value), 0, 1))
    end

end

function WaitGroup:initialize(scheduler, count, callback)
    Utils.assert(count > 0, "WaitGroup#count must be > 0")
    WaitGroup:super(self, "initialize", scheduler, callback)
    self.remaining = count
end

function Scheduler:initialize()
    Scheduler:super(self, "initialize")
    self.events = Array:new()
    self.onEventsEmpty = Array:new()
    self.waitGroups = Set:new()
    self.updateTime = false
end

function Scheduler:getCurrentTime()
    Utils.assert(false, "Override this")
end

function Scheduler:isEmpty()
    return self.events:isEmpty() and self.onEventsEmpty:isEmpty()
end

function Scheduler:getScheduleTime()
    return self.updateTime or self:getCurrentTime()
end

function Scheduler:update()
    local currentTime = self:getCurrentTime()
    local inProgress = Array:new()
    while not self.events:isEmpty() and self.events:last().schedule <= currentTime do
        local event = self.events:pop()
        if Progress:isInstance(event) then
            if event.state ~= Tags.PROGRESS_RUNNING then
                self.updateTime = event.schedule
            end

            if event.state == Tags.PROGRESS_CREATED then
                event.state = Tags.PROGRESS_RUNNING
                event:call(0)
            end

            if event.state == Tags.PROGRESS_ENDING then
                inProgress:delete(event)
                event:call(1)
                self:_scheduleOnFinish(event)
            else
                if event.schedule + event.duration <= currentTime then
                    event.state = Tags.PROGRESS_ENDING
                    self:_scheduleAtTime(event, event.schedule + event.duration)
                end

                inProgress:push(event)
            end

        else
            self.updateTime = event.schedule
            for eventInProgress in inProgress() do
                eventInProgress:updateProgress(event.schedule)
            end

            event:call(event.schedule)
            self:_scheduleOnFinish(event)
            if event.repeatInterval then
                self:_scheduleAtTime(event, event.schedule + Utils.evaluate(event.repeatInterval))
            end

        end

    end

    for event in inProgress() do
        event:updateProgress(currentTime)
        self:_scheduleAtTime(event, event.schedule)
    end

    if self.events:isEmpty() and not self.onEventsEmpty:isEmpty() then
        local event = self.onEventsEmpty:popFirst()
        self:_scheduleAtTime(event, self:getScheduleTime())
        self:update()
    else
        self.updateTime = false
    end

end

function Scheduler:_scheduleOnFinish(event)
    if not event.repeatInterval then
        event._isFinished = true
    end

    if not event.onFinish then
        return 
    end

    for nextEvent in event.onFinish() do
        if WaitGroup:isInstance(nextEvent) then
            nextEvent.remaining = nextEvent.remaining - 1
            if nextEvent.remaining <= 0 then
                self.waitGroups:delete(nextEvent)
                self:_scheduleAtTime(nextEvent, event.schedule)
            end

        else
            self:_scheduleAtTime(nextEvent, event.schedule)
        end

    end

    return event.onFinish:last()
end

function Scheduler:_scheduleAtTime(event, scheduleTime)
    event.schedule = scheduleTime
    local events = self.events
    events:push(event)
    for i = events.n, 2, -1 do
        if scheduleTime >= events[i - 1].schedule then
            events[i], events[i - 1] = events[i - 1], events[i]
        else
            break
        end

    end

    return event
end

function Scheduler:updateIfNotUpdating()
    if not self.updateTime then
        self:update()
    end

end

function Scheduler:createEventOnEmpty(callback, repeatInterval)
    local event = Event:new(self, callback, repeatInterval)
    self.onEventsEmpty:push(event)
    return event
end

function Scheduler:createPriorityEventOnEmpty(callback, repeatInterval)
    local event = Event:new(self, callback, repeatInterval)
    self.onEventsEmpty:pushFirst(event)
    return event
end

function Scheduler:createEvent(callback, repeatInterval)
    local event = Event:new(self, callback, repeatInterval)
    self:_scheduleAtTime(event, self:getScheduleTime())
    return event
end

function Scheduler:createProgress(duration, callback, easing)
    local progress = Progress:new(self, duration, callback, easing)
    self:_scheduleAtTime(progress, self:getScheduleTime())
    return progress
end

function Scheduler:createWaitGroup(count, callback)
    local waitGroup = WaitGroup:new(self, count, callback)
    self.waitGroups:add(waitGroup)
    return waitGroup
end

function Scheduler:stopEvent(event)
    self.events:delete(event)
    self.onEventsEmpty:delete(event)
end

return Scheduler

