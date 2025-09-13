local Graphs = {  }
local SparseGraph = require("utils.classes.sparse_graph")
local PriorityQueue = require("utils.classes.priority_queue")
local Deque = require("utils.classes.deque")
function Graphs.Prim(graph)
    local result = SparseGraph:new()
    local shortest = {  }
    local queue = PriorityQueue:new(function(a, b)
        return shortest[a].length < shortest[b].length
    end)
    for i, value in ipairs(graph:values()) do
        result:addVertex(value)
        shortest[value] = { length = choose(i == 1, 0, math.huge) }
        queue:insert(value)
    end

    while not queue:isEmpty() do
        local minIncoming = queue:popMin()
        local edge = shortest[minIncoming]
        if edge.source then
            result:addEdge(edge.source, edge.target, edge.length)
        end

        for edge in graph:getVertex(minIncoming).edges() do
            if edge.length < shortest[edge.target].length then
                shortest[edge.target] = edge
                local index = queue:indexOf(edge.target)
                if index then
                    queue:update(index)
                end

            end

        end

    end

    return result
end

function Graphs.BFS(graph, starting)
    local visited = {  }
    visited[starting] = 0
    local queue = Deque:new(starting)
    return function()
        if queue:isEmpty() then
            return nil
        else
            local value = queue:popFirst()
            local vertex = graph:getVertex(value)
            for edge in vertex.edges() do
                if not visited[edge.target] then
                    visited[edge.target] = visited[value] + 1
                    queue:push(edge.target)
                end

            end

            return value, visited[value]
        end

    end
end

return Graphs

