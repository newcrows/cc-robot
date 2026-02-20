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

    local function placeHelper(placeFunc, name, blocking)
        local placed = false

        local function check()
            return placed
        end

        local function tick()
            if meta.selectFirstSlot(name) then
                placed = placeFunc()
            end
        end

        meta.require(check, tick, blocking)
        return placed
    end

    local function dropHelper(dropFunc, name, count, blocking)
        if type(name) == "number" or name == nil then
            blocking, count, name = count, name, robot.getSelectedName()
        elseif type(name) == "boolean" or type(name) == "function" then
            blocking, count, name = name, nil, robot.getSelectedName()
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
            local detail = meta.getFirstSlot(name)

            if detail then
                local amountToDrop = math.min(detail.count, remaining)
                local before = physicalCountAll()

                nativeTurtle.select(detail.id)

                if dropFunc(amountToDrop) then
                    local after = physicalCountAll()
                    remaining = remaining + (after - before)
                end
            end
        end

        meta.require(check, tick, blocking)
        return totalAmount - remaining
    end

    local function compareHelper(inspectFunc, name)
        name = name or robot.getSelectedName()

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

    local function suckHelper(suckFunc, count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking, count = count, nil
        end

        local totalSucked = 0
        local stackSize = constants.default_stack_size

        local function check()
            local conditionA = count and totalSucked >= count
            local conditionB = not count and countEmptySlots() == 0

            return conditionA or conditionB
        end

        local function tick()
            local nextAmount = count and math.min(stackSize, count - totalSucked) or stackSize
            local before = physicalCountAll()

            if suckFunc(nextAmount) then
                local after = physicalCountAll()

                totalSucked = totalSucked + (after - before)
            end
        end

        meta.require(check, tick, blocking)
        return totalSucked
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
