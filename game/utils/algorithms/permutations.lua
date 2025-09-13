local Permutations = {  }
function Permutations.next(permutation)
    if permutation:size() <= 1 then
        return permutation
    end

    local index = permutation:size()
    while index > 1 and permutation[index - 1] >= permutation[index] do
        index = index - 1
    end

    if index > 1 then
        for i2 = permutation.n, index, -1 do
            if permutation[i2] > permutation[index - 1] then
                permutation[i2], permutation[index - 1] = permutation[index - 1], permutation[i2]
                break
            end

        end

    end

    return permutation:subArray(1, index - 1):concat(permutation:subArray(index, n):reversed())
end

return Permutations

