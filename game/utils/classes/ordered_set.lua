local OrderedSet = class()
local Array = require("utils.classes.array")
local LEFT, RIGHT, ROOT = -1, 1, 0
local function keyAddOrder(object, set)
    return object._setKey[set]
end

function OrderedSet:initialize(getKey,...)
    self.getKey = getKey or keyAddOrder
    self.n = 0
    self:add(...)
end

local function minNode(parent)
    local node = parent
    while true do
        if node[LEFT] == nil then
            return node
        end

        node = node[LEFT]
    end

end

local function maxNode(parent)
    local node = parent
    while true do
        if node[RIGHT] == nil then
            return node
        end

        node = node[RIGHT]
    end

end

local function getHeights(target)
    local leftHeight, rightHeight = 0, 0
    if target[LEFT] then
        leftHeight = target[LEFT].height
    end

    if target[RIGHT] then
        rightHeight = target[RIGHT].height
    end

    return leftHeight, rightHeight
end

local function refreshHeight(node)
    node.height = max(getHeights(node)) + 1
end

local function rotateRight(parent, targetNode, target)
    local leg = target[LEFT][RIGHT]
    target[LEFT][RIGHT] = target
    parent[targetNode] = target[LEFT]
    target[LEFT] = leg
    refreshHeight(target)
    refreshHeight(parent[targetNode])
end

local function rotateLeft(parent, targetNode, target)
    local leg = target[RIGHT][LEFT]
    target[RIGHT][LEFT] = target
    parent[targetNode] = target[RIGHT]
    target[RIGHT] = leg
    refreshHeight(target)
    refreshHeight(parent[targetNode])
end

local function getBalancingFactor(target)
    local l, r = getHeights(target)
    return l - r
end

local function balance(parent, target, targetNode)
        if getBalancingFactor(target) >= 2 then
        if getBalancingFactor(target[LEFT]) <= -1 then
            rotateLeft(target, LEFT, target[LEFT])
        end

        rotateRight(parent, targetNode, target)
    elseif getBalancingFactor(target) <= -2 then
        if getBalancingFactor(target[RIGHT]) >= 1 then
            rotateRight(target, RIGHT, target[RIGHT])
        end

        rotateLeft(parent, targetNode, target)
    end

end

function OrderedSet:insertNode(parent, targetNode, value, key)
    local target = parent[targetNode]
        if not target then
        parent[targetNode] = { key = key, value = value, height = 1 }
        self.n = self.n + 1
        return 
    elseif key <= target.key then
        self:insertNode(target, LEFT, value, key)
    else
        self:insertNode(target, RIGHT, value, key)
    end

    balance(parent, target, targetNode)
    refreshHeight(target)
end

local function findNode(parent, targetNode, value, key)
    if not parent[targetNode] then
        return nil, nil
    end

    local target = parent[targetNode]
    if key == target.key and value == target.value then
        return parent, targetNode
    else
        return findNode(target, choose(key <= target.key, LEFT, RIGHT), value, key)
    end

end

function OrderedSet:contains(value)
    if findNode(self, ROOT, value, self.getKey(value, self)) then
        return true
    end

    return false
end

function OrderedSet:deleteNode(parent, targetNode, value, key)
    local target = parent[targetNode]
    if not target then
        return 
    end

    if key == target.key and value == target.value then
                        if target[RIGHT] and target[LEFT] then
            if target[LEFT][RIGHT] then
                local pred = target[LEFT]
                local predParent = nil
                while true do
                    if not pred[RIGHT] then
                        break
                    end

                    predParent = pred
                    pred = pred[RIGHT]
                end

                target.value, target.key = pred.value, pred.key
                self:deleteNode(predParent, RIGHT, pred.value, pred.key)
            else
                target.value, target.key = target[LEFT].value, target[LEFT].key
                self:deleteNode(target, LEFT, target[LEFT].value, target[LEFT].key)
            end

        elseif target[RIGHT] then
            parent[targetNode] = target[RIGHT]
            self.n = self.n - 1
        elseif target[LEFT] then
            parent[targetNode] = target[LEFT]
            self.n = self.n - 1
        else
            parent[targetNode] = nil
            self.n = self.n - 1
        end

    else
        self:deleteNode(target, choose(key <= target.key, LEFT, RIGHT), value, key)
    end

    if parent[targetNode] then
        balance(parent, parent[targetNode], targetNode)
        refreshHeight(parent[targetNode])
    end

end

function OrderedSet:add(...)
    for i, v in ipairs({ ... }) do
        if self.getKey == keyAddOrder then
            if not v._setKey then
                v._setKey = {  }
            end

            if self.n == 0 then
                v._setKey[self] = 0
            else
                v._setKey[self] = self:maximum()._setKey[self] + 1
            end

        end

        self:insertNode(self, ROOT, v, self.getKey(v, self))
    end

end

function OrderedSet:isEmpty()
    return self[ROOT] == nil
end

function OrderedSet:minimum()
    if self:isEmpty() then
        return nil
    end

    return minNode(self[ROOT]).value
end

function OrderedSet:maximum()
    if self:isEmpty() then
        return nil
    end

    return maxNode(self[ROOT]).value
end

function OrderedSet:delete(...)
    for i, v in ipairs({ ... }) do
        self:deleteNode(self, ROOT, v, self.getKey(v, self))
    end

end

function OrderedSet:toArray()
    local array = Array:new()
    for element in self() do
        array:push(element)
    end

    return array
end

local function pushAllLeft(arr, node)
    while node do
        arr:push(node)
        node = node[LEFT]
    end

end

function OrderedSet:mapAction(name)
    for value in self() do
        value[name](value)
    end

end

function OrderedSet:__call()
    local stack = Array:new()
    if self[ROOT] then
        pushAllLeft(stack, self[ROOT])
    end

    return function()
        if stack:isEmpty() then
            return nil
        end

        local node = stack:pop()
        if node[RIGHT] then
            pushAllLeft(stack, node[RIGHT])
        end

        return node.value
    end
end

return OrderedSet

