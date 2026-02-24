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
            end
        end

        meta.try(check, tick, blocking)
        return placed
    end

    local function dropHelper_0(dropFunc, name, remaining)
        local continue = true

        local function check()
            return not continue or remaining == 0
        end

        local function tick()
            local detail = meta.getFirstSlot(name)
            local didDropSomething = false

            if detail then
                local amountToDrop = math.min(detail.count, remaining)
                local before = physicalCountAll()

                nativeTurtle.select(detail.id)

                if dropFunc(amountToDrop) then
                    local after = physicalCountAll()

                    if after ~= before then
                        didDropSomething = true
                        remaining = remaining + (after - before)
                    end
                end
            end

            continue = didDropSomething
            return didDropSomething
        end

        meta.try(check, tick, true)
        return remaining
    end

    local function dropHelper(dropFunc, name, count, blocking)
        if type(name) == "number" or name == nil then
            blocking, count, name = count, name, robot.getSelectedQuery()
        elseif type(name) == "boolean" or type(name) == "function" then
            blocking, count, name = name, nil, robot.getSelectedQuery()
        end

        if not name then
            error("name must not be nil", 0)
        end

        local totalAmount = count or robot.getItemCount(name)
        local remaining = totalAmount

        local function check()
            return remaining <= 0
        end

        local function tick()
            remaining = dropHelper_0(dropFunc, name, remaining)
        end

        meta.try(check, tick, blocking)
        return totalAmount - remaining
    end

    local function compareHelper(inspectFunc, name)
        name = name or robot.getSelectedQuery()

        if not name then
            error("name must not be nil", 0)
        end

        local ok, detail = inspectFunc()

        if ok then
            return detail.name == name
        else
            return name == "air" or name == "minecraft:air"
        end
    end

    local function suckHelper_0(suckFunc, remaining)
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
                    didSuckSomething = true
                    remaining = remaining + (before - after)
                end
            end

            continue = didSuckSomething
            return didSuckSomething
        end

        meta.try(check, tick, true)
        return remaining
    end

    local function suckHelper(suckFunc, count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking, count = count, nil
        end

        local totalAmount = count or 9999
        local remaining = totalAmount

        local function check()
            local conditionA = count and remaining == 0
            local conditionB = count == 9999 and countEmptySlots() == 0

            return conditionA or conditionB
        end

        local function tick()
            remaining = suckHelper_0(suckFunc, remaining)
        end

        meta.try(check, tick, blocking)
        return totalAmount - remaining
    end

    function robot.place(name, blocking)
        return placeHelper(nativeTurtle.place, name, blocking)
    end

    function robot.placeUp(name, blocking)
        return placeHelper(nativeTurtle.placeUp, name, blocking)
    end

    function robot.placeDown(name, blocking)
        return placeHelper(nativeTurtle.placeDown, name, blocking)
    end

    function robot.drop(name, count, blocking)
        return dropHelper(nativeTurtle.drop, name, count, blocking)
    end

    function robot.dropUp(name, count, blocking)
        return dropHelper(nativeTurtle.dropUp, name, count, blocking)
    end

    function robot.dropDown(name, count, blocking)
        return dropHelper(nativeTurtle.dropDown, name, count, blocking)
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

    function robot.compare(name)
        return compareHelper(nativeTurtle.inspect, name)
    end

    function robot.compareUp(name)
        return compareHelper(nativeTurtle.inspectUp, name)
    end

    function robot.compareDown(name)
        return compareHelper(nativeTurtle.inspectDown, name)
    end

    function robot.suck(count, blocking)
        return suckHelper(nativeTurtle.suck, count, blocking)
    end

    function robot.suckUp(count, blocking)
        return suckHelper(nativeTurtle.suckUp, count, blocking)
    end

    function robot.suckDown(count, blocking)
        return suckHelper(nativeTurtle.suckDown, count, blocking)
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
