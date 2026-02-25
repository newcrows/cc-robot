return function(robot, meta)
    return {
        names = {
            "minecraft:diamond_pickaxe",
            "minecraft:diamond_axe",
            "minecraft:diamond_shovel"
        },
        constructor = function()
            local function digHelper(digFunc, inspectFunc, query, blocking)
                -- TODO [JM] only invName matters in the query
                --  -> if itemName is set, we add the block only to queryInv if match
                --      if no match, we put it in fallback_inventory (this is coherent with robot.suck())
                local ok

                local function check()
                    return ok
                end

                local function tick()
                    local blockExists, blockDetail = inspectFunc()

                    if blockExists then
                        -- TODO [JM] advanced checks with inspect() and peripheral.getType():full-inventory-sync
                        -- -> if simple block, meta.updateItemCount(itemName@queryInventory, 1)
                        --      (or fallback_inventory, if no itemName specified or block doesnt match itemName)
                        -- -> if type == "inventory" -> do full inventory before after diff after breaking the block

                        ok = digFunc()

                        if ok then
                            local itemName, invName = meta.parseQuery(query, blockDetail.name)
                            meta.updateItemCount(itemName .. "@" .. invName, 1)
                        end
                    end
                end

                meta.try(check, tick, blocking)
                return ok
            end

            return {
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
