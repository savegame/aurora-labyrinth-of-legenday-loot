local UniqueList = class()
local Array = require("utils.classes.array")
function UniqueList:initialize(...)
    self:clear()
    self:pushMultiple(...)
end

function UniqueList:clear()
    self.head = false
    self.tail = false
    self.nodes = {  }
    self.n = 0
end

function UniqueList:createNode(element)
    self.nodes[element] = { n = false, p = false, e = element }
    return self.nodes[element]
end

function UniqueList:push(value)
    if not self:contains(value) then
        local node = self:createNode(value)
        if not self.tail then
            self.tail, self.head = node, node
        else
            node.p = self.tail
            self.tail.n = node
            self.tail = node
        end

        self.n = self.n + 1
    end

end

UniqueList.add = UniqueList.push
function UniqueList:pushMultiple(...)
    for i, value in ipairs({ ... }) do
        self:push(value)
    end

end

function UniqueList:pushFirst(...)
    if not self.head then
        self:push(...)
        return 
    end

    local oldHead = self.head
    for i, v in ipairs({ ... }) do
        self:insertBefore(v, oldHead.e)
    end

end

function UniqueList:first()
    if not self.head then
        return nil
    end

    return self.head.e
end

function UniqueList:last()
    if not self.tail then
        return nil
    end

    return self.tail.e
end

function UniqueList:insertBefore(element, beforeThis)
    local node = self.nodes[beforeThis]
    Utils.assert(node, "UniqueList: Inserting before non-existent element")
    if not node then
        return 
    end

    local newNode = self:createNode(element)
    if node.p then
        node.p.n = newNode
    end

    node.p, newNode.n, newNode.p = newNode, node, node.p
    if self.head == node then
        self.head = newNode
    end

    self.n = self.n + 1
end

function UniqueList:insertAfter(element, afterThis, pushIfNone)
    local node = self.nodes[afterThis]
    if not node or afterThis == nil then
        if pushIfNone then
            return self:push(element)
        else
            Utils.assert(node, "UniqueList: Inserting after non-existent element")
        end

        return 
    end

    local newNode = self:createNode(element)
    if node.n then
        node.n.p = newNode
    end

    node.n, newNode.p, newNode.n = newNode, node, node.n
    if self.tail == node then
        self.tail = newNode
    end

    self.n = self.n + 1
end

function UniqueList:delete(element)
    local node = self.nodes[element]
    if not node then
        return 
    end

    if node.p then
        node.p.n = node.n
    end

    if node.n then
        node.n.p = node.p
    end

    if self.head == node then
        self.head = node.n
    end

    if self.tail == node then
        self.tail = node.p
    end

    self.nodes[element] = nil
    self.n = self.n - 1
end

function UniqueList:__call()
    local current = self.head
    return function()
        while current and not self:contains(current.e) do
            current = current.n
        end

        if not current then
            return nil
        end

        local result = current.e
        current = current.n
        return result
    end
end

function UniqueList:reverseIterator()
    local current = self.tail
    return function()
        while current and not self:contains(current.e) do
            current = current.p
        end

        if not current then
            return nil
        end

        local result = current.e
        current = current.p
        return result
    end
end

function UniqueList:iterateIf(fn)
    local current = self.head
    return function()
        while current and (not self:contains(current.e) or not fn(current.e)) do
            current = current.n
        end

        if not current then
            return nil
        end

        local result = current.e
        current = current.n
        return result
    end
end

function UniqueList:iterateUnless(fn)
    return self:iterateIf(Utils.negateFunction(fn))
end

function UniqueList:accept(fn)
    local result = UniqueList:new()
    for value in self() do
        if fn(value) then
            result:push(value)
        end

    end

    return result
end

function UniqueList:contains(element)
    return toBoolean(self.nodes[element])
end

function UniqueList:findOne(fn)
    for v in self() do
        if fn(v) then
            return v
        end

    end

    return nil
end

function UniqueList:hasOne(fn)
    for v in self() do
        if fn(v) then
            return true
        end

    end

    return false
end

function UniqueList:isEmpty()
    return self.n == 0
end

function UniqueList:toArray()
    local result = Array:new()
    for value in self() do
        result:push(value)
    end

    return result
end

function UniqueList:__len()
    return self.n
end

UniqueList.__tostring = Array.__tostring
return UniqueList

