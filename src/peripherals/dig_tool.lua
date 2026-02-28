return function(robot, meta, constants)
    return {
        names = {
            "minecraft:diamond_pickaxe",
            "minecraft:diamond_axe",
            "minecraft:diamond_shovel"
        },
        constructor = function()
            local function digHelper(digFunc, inspectFunc, query, blocking)
                if type(query) == "boolean" or type(query) == "function" then
                    blocking = query
                    query = nil
                end

                -- NOTE [JM] only invName matters in the query
                query = query or "*"
                local ok

                local function check()
                    return ok
                end

                local function tick()
                    local blockExists, blockDetail = inspectFunc()

                    if blockExists then
                        local itemInfo = constants.item_info[blockDetail.name]
                        local dropName = itemInfo.dropName or blockDetail.name

                        local itemName, invName = meta.parseQuery(query, dropName)
                        local adjustedQuery = itemName .. "@" .. invName

                        meta.requireItemSpace(adjustedQuery, 1)
                        ok = digFunc()

                        if ok then
                            meta.updateItemCount(adjustedQuery, 1)
                        end
                    end
                end

                meta.try(check, tick, blocking)
                return ok
            end

            return {
                -- NOTE [JM] use native.dig* within item_space_warning to prevent infinite recursion
                native = {
                    dig = nativeTurtle.dig,
                    digUp = nativeTurtle.digUp,
                    digDown = nativeTurtle.digDown
                },
                dig = function(query, blocking)
                    return digHelper(nativeTurtle.dig, nativeTurtle.inspect, query, blocking)
                end,
                digUp = function(query, blocking)
                    return digHelper(nativeTurtle.digUp, nativeTurtle.inspectUp, query, blocking)
                end,
                digDown = function(query, blocking)
                    return digHelper(nativeTurtle.digDown, nativeTurtle.inspectDown, query, blocking)
                end
            }
        end
    }
end
