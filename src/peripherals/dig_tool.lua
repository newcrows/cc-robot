return function(_, meta)
    return {
        names = {
            "minecraft:diamond_pickaxe",
            "minecraft:diamond_axe",
            "minecraft:diamond_shovel"
        },
        constructor = function()
            local function digHelper(digFunc, blocking)
                local ok

                local function check()
                    return ok
                end

                local function tick()
                    ok = digFunc()
                end

                meta.require(check, tick, blocking)
                return ok
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
end
