local Strings = {  }
function Strings.Levenshtein(s1, s2)
    local memoize = SparseGrid:new(math.huge)
    local l1, l2 = #s1, #s2
    for position in Utils.gridIteratorV(0, l1, 0, l2) do
        if position.x == 0 or position.y == 0 then
            memoize:set(position, max(position.x, position.y))
        else
            memoize:set(position, min(memoize:get(position - Vector.UNIT_X) + 1, memoize:get(position - Vector.UNIT_Y) + 1, memoize:get(position - Vector.UNIT_XY) + choose(s1:byte(position.x) == s2:byte(position.y), 0, 1)))
        end

    end

    return memoize:get(Vector:new(l1, l2))
end

return Strings

