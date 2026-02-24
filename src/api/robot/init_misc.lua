return function(robot, meta, constants)
    local function physicalCountAll()
        local total = 0

        for i = 1, 16 do
            total = total + nativeTurtle.getItemCount(i)
        end

        return total
    end

    local function countEmptySlots()
        return #meta.listEmptySlots()
    end

    local function placeHelper(placeFunc, query, blocking)
        local placed = false

        local function check()
            return placed
        end

        local function tick()
            if meta.selectFirstSlot(query) then
                placed = placeFunc()

                if placed then
                    meta.updateItemCount(query, -1)
                end
            end
        end

        meta.try(check, tick, blocking)
        return placed
    end

    local function dropHelper_0(dropFunc, query, remaining)
        local continue = true

        local function check()
            return not continue or remaining == 0
        end

        local function tick()
            local detail = meta.getFirstSlot(query)
            local didDropSomething = false

            if detail then
                local amountToDrop = math.min(detail.count, remaining)
                local before = physicalCountAll()

                nativeTurtle.select(detail.id)

                if dropFunc(amountToDrop) then
                    local after = physicalCountAll()

                    if after ~= before then
                        remaining = remaining + (after - before)
                        meta.updateItemCount(query, (after - before))

                        didDropSomething = true
                    end
                end
            end

            continue = didDropSomething
            return didDropSomething
        end

        meta.try(check, tick, true)
        return remaining
    end

    local function dropHelper(dropFunc, query, count, blocking)
        if type(query) == "number" or query == nil then
            blocking, count, query = count, query, robot.getSelectedQuery()
        elseif type(query) == "boolean" or type(query) == "function" then
            blocking, count, query = query, nil, robot.getSelectedQuery()
        end

        local totalAmount = count or robot.getItemCount(query)
        local remaining = totalAmount

        local function check()
            return remaining <= 0
        end

        local function tick()
            remaining = dropHelper_0(dropFunc, query, remaining)
        end

        meta.try(check, tick, blocking)
        return totalAmount - remaining
    end

    local function compareHelper(inspectFunc, query)
        query = query or robot.getSelectedQuery()

        local itemName = meta.parseQuery(query)
        local ok, detail = inspectFunc()

        if ok then
            return detail.name == itemName
        else
            return itemName == "minecraft:air"
        end
    end

    local function suckHelper_0(suckFunc, query, remaining)
        local continue = true

        local function check()
            return not continue or remaining == 0
        end

        local function tick()
            local didSuckSomething = false

            local amountToSuck = math.min(constants.default_stack_size, remaining)
            local before = physicalCountAll()

            if suckFunc(amountToSuck) then
                local after = physicalCountAll()

                if after ~= before then
                    remaining = remaining + (before - after)
                    -- TODO [JM] meta.updateItemCount(), but for ALL items in diff: before vs after
                    -- -> fill query:inventory first and put the rest into fallback_inventory
                    -- -> also fill ONLY query:item into query:inventory and the rest into fallback_inventory
                    --      (assuming query:item is specified)
                    -- -> we can actually use "before" and "after" snapshots (physical inventory) here, probably
                    --      but we must do it in a way that throws error should before diff already have sync errors

                    didSuckSomething = true
                end
            end

            continue = didSuckSomething
            return didSuckSomething
        end

        meta.try(check, tick, true)
        return remaining
    end

    local function suckHelper(suckFunc, query, count, blocking)
        if type(query) == "number" or query == nil then
            blocking, count, query = count, query, robot.getSelectedQuery()
        elseif type(query) == "boolean" or type(query) == "function" then
            blocking, count, query = query, nil, robot.getSelectedQuery()
        end

        local totalAmount = count or 9999
        local remaining = totalAmount

        local function check()
            local conditionA = count and remaining == 0
            local conditionB = count == 9999 and countEmptySlots() == 0

            return conditionA or conditionB
        end

        local function tick()
            remaining = suckHelper_0(suckFunc, query, remaining)
        end

        meta.try(check, tick, blocking)
        return totalAmount - remaining
    end

    function robot.place(query, blocking)
        return placeHelper(nativeTurtle.place, query, blocking)
    end

    function robot.placeUp(query, blocking)
        return placeHelper(nativeTurtle.placeUp, query, blocking)
    end

    function robot.placeDown(query, blocking)
        return placeHelper(nativeTurtle.placeDown, query, blocking)
    end

    function robot.drop(query, count, blocking)
        return dropHelper(nativeTurtle.drop, query, count, blocking)
    end

    function robot.dropUp(query, count, blocking)
        return dropHelper(nativeTurtle.dropUp, query, count, blocking)
    end

    function robot.dropDown(query, count, blocking)
        return dropHelper(nativeTurtle.dropDown, query, count, blocking)
    end

    function robot.detect()
        return nativeTurtle.detect()
    end

    function robot.detectUp()
        return nativeTurtle.detectUp()
    end

    function robot.detectDown()
        return nativeTurtle.detectDown()
    end

    function robot.compare(query)
        return compareHelper(nativeTurtle.inspect, query)
    end

    function robot.compareUp(query)
        return compareHelper(nativeTurtle.inspectUp, query)
    end

    function robot.compareDown(query)
        return compareHelper(nativeTurtle.inspectDown, query)
    end

    function robot.suck(query, count, blocking)
        return suckHelper(nativeTurtle.suck, query, count, blocking)
    end

    function robot.suckUp(query, count, blocking)
        return suckHelper(nativeTurtle.suckUp, query, count, blocking)
    end

    function robot.suckDown(query, count, blocking)
        return suckHelper(nativeTurtle.suckDown, query, count, blocking)
    end

    function robot.inspect()
        return nativeTurtle.inspect()
    end

    function robot.inspectUp()
        return nativeTurtle.inspectUp()
    end

    function robot.inspectDown()
        return nativeTurtle.inspectDown()
    end
end
