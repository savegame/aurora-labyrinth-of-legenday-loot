local SparseGraph = class()
local Array = require("utils.classes.array")
local Edge = struct("source", "target", "length")
local Vertex = struct("value", "edges")
function SparseGraph:initialize(...)
    self.vertices = Array:new()
    self.mapping = {  }
    for i, v in ipairs({ ... }) do
        self:addVertex(v)
    end

end

function SparseGraph:createWithSameVertices()
    local result = SparseGraph:new()
    for vertex in self.vertices() do
        result:addVertex(vertex.value)
    end

    return result
end

function SparseGraph:addVertex(value)
    local vertex = Vertex:new(value, Array:new())
    self.vertices:push(vertex)
    self.mapping[value] = self.vertices.n
    return vertex
end

function SparseGraph:toIndex(value)
    Utils.assert(self.mapping[value], "Value not found in sparse graph: %s", value)
    return self.mapping[value]
end

function SparseGraph:getVertex(value)
    return self.vertices[self:toIndex(value)]
end

function SparseGraph:addEdge(value1, value2, length, unidirectional)
    local index = self:toIndex(value1)
    length = length or 1
    local edge = self.vertices[index].edges:findOne(function(e)
        return e.target == value2
    end)
    if not edge then
        edge = Edge:new(value1, value2, length)
        self.vertices[index].edges:push(edge)
    end

    edge.length = length
    if not unidirectional then
        self:addEdge(value2, value1, length, true)
    end

end

function SparseGraph:getEdge(source, target)
    local index = self:toIndex(source)
    return self.vertices[index].edges:findOne(function(e)
        return e.target == target
    end)
end

function SparseGraph:hasEdge(value1, value2, unidirectional)
    local index = self:toIndex(value1)
    local edge = self.vertices[index].edges:findOne(function(e)
        return e.target == value2
    end)
    if edge then
        return true
    end

    if not unidirectional then
        return self:hasEdge(value2, value1, true)
    end

    return false
end

function SparseGraph:removeEdge(source, target, unidirectional)
    local index = self:toIndex(source)
    local edge = self.vertices[index].edges:findOne(function(e)
        return e.target == target
    end)
    if edge then
        self.vertices[index].edges:delete(edge)
        if not unidirectional then
            self:removeEdge(target, source, true)
        end

    end

    return edge
end

function SparseGraph:clearEdges(source, unidirectional)
    local index = self:toIndex(source)
    if not unidirectional then
        for edge in self.vertices[index].edges() do
            self:removeEdge(edge.target, source, true)
        end

    end

    self.vertices[index].edges:clear()
end

function SparseGraph:values()
    return self.vertices:map(function(vertex)
        return vertex.value
    end)
end

function SparseGraph:edges()
    local result = Array:new()
    for vertex in self.vertices() do
        for edge in vertex.edges() do
            result:push(edge)
        end

    end

    return result
end

function SparseGraph:isEmpty()
    for vertex in self.vertices() do
        for edge in vertex.edges() do
            return false
        end

    end

    return true
end

function SparseGraph:clear()
    for vertex in self.vertices() do
        self:clearEdges(vertex.value, true)
    end

end

function SparseGraph:edgesSingle()
    return self:edges():reject(function(edge)
        return self:toIndex(edge.source) > self:toIndex(edge.target)
    end)
end

return SparseGraph

