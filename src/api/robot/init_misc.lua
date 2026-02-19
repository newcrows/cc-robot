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

    local function ensure(check, tick, strategy)
        tick()

        local ok = check()
        if ok or not strategy then
            return
        end

        strategy = type(strategy) == "function" and strategy or function()
        end

        while true do
            strategy(true)
            tick(true)

            if check() then
                return
            end

            os.sleep(1)
        end
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

        ensure(check, tick, blocking)
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
            -- TODO [JM] rename meta.getFirstSlot to meta.getFirstSlotDetail to stay coherent with all other funcs
            local detail = meta.getFirstSlot(name)

            if detail then
                local amountToDrop = math.min(detail.count, remaining)
                nativeTurtle.select(detail.id)

                if dropFunc(amountToDrop) then
                    remaining = remaining - amountToDrop
                end
            end
        end

        ensure(check, tick, blocking)
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

        return false
    end

    local function suckHelper(suckFunc, count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking, count = count, nil
        end

        local totalSucked = 0
        local waited = false
        local stackSize = constants.default_stack_size

        while (count and totalSucked < count) or (not count and countEmptySlots() > 0) or (blocking and totalSucked == 0) do
            local nextAmount = count and math.min(stackSize, count - totalSucked) or stackSize

            local before = physicalCountAll()
            local success = suckFunc(nextAmount)

            if success then
                local after = physicalCountAll()
                local amount = after - before

                totalSucked = totalSucked + amount
                waited = false

                if count and totalSucked >= count then
                    return totalSucked
                end
            else
                if blocking then
                    if countEmptySlots() <= 0 then
                        return totalSucked
                    end

                    if waited then
                        os.sleep(1)
                    end

                    if type(blocking) == "function" then
                        blocking()
                    end

                    waited = true
                else
                    return totalSucked
                end
            end
        end

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
