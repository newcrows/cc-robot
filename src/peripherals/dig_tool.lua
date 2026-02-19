return {
    names = {
        "minecraft:diamond_pickaxe",
        "minecraft:diamond_axe",
        "minecraft:diamond_shovel"
    },
    constructor = function(opts)
        local meta = opts.meta

        local function digHelper(digFunc, blocking)
            if digFunc() then
                meta.unwrapAll()

                return true
            end

            return false
        end

        return {
            dig = function(blocking)
                return digHelper(nativeTurtle.dig, blocking)
            end,
            digUp = function(blocking)
                return digHelper(nativeTurtle.digUp, blocking)
            end,
            digDown = function(blocking)
                return digHelper(nativeTurtle.digDown, blocking)
            end
        }
    end
}
