return function(robot, meta, constants)
    local UNKNOWN_ITEM = constants.unknown_item

    -- TODO [JM] obsolete when dropHelper_0 is implemented correctly
    local function physicalCountAll()
        local total = 0

        for i = 1, 16 do
            total = total + nativeTurtle.getItemCount(i)
        end

        return total
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
        -- TODO [JM] passing no query DOES NOT YET WORK
        query = query or "*"
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

                    -- TODO [JM] could use meta.snapshot/diff here
                    -- -> to make sure correct items were dropped
                    -- -> this would be the correct way
                    -- -> plus it would work exactly the same for suckHelper_0 (just -amount instead of +)
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
            blocking, count, query = count, query, nil
        elseif type(query) == "boolean" or type(query) == "function" then
            blocking, count, query = query, nil, nil
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
        if not query then
            query = "*"
        end

        local continue = true
        local targetItemName = meta.parseQuery(query)

        local function check()
            return not continue or remaining == 0
        end

        local function tick()
            local didSuckSomething = false

            local amountToSuck = math.min(constants.default_stack_size, remaining)
            local before = meta.snapshot()

            if suckFunc(amountToSuck) then
                local after = meta.snapshot()
                local diff = meta.diff(before, after)

                for name, delta in pairs(diff) do
                    local itemName, invName = meta.parseQuery(query, name)
                    meta.updateItemCount(itemName .. "@" .. invName, delta)

                    if targetItemName == itemName or targetItemName == "*" then
                        remaining = remaining - delta
                    end

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
            blocking, count, query = count, query, nil
        elseif type(query) == "boolean" or type(query) == "function" then
            blocking, count, query = query, nil, nil
        end

        local totalAmount = count or 9999
        local remaining = totalAmount

        local function check()
            local conditionA = count and remaining == 0
            local conditionB = count == 9999 and not robot.getItemSpace(UNKNOWN_ITEM .. "@*")

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
