return function(robot, meta, constants)
    local function placeHelper(placeFunc, name, blocking)
        if type(name) == "boolean" or type(name) == "function" then
            blocking, name = name, robot.getSelectedName()
        end

        if not name then
            error("name must not be nil", 0)
        end

        local success = false
        local waited = false

        while not success do
            success = meta.selectFirstSlot(name)

            if success then
                success = placeFunc()
            end

            if not success then
                if blocking then
                    if waited then
                        os.sleep(1)
                    end

                    if type(blocking) == "function" then
                        blocking()
                    end

                    waited = true
                else
                    return false
                end
            end
        end

        return true
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

        local remaining = count or robot.getItemCount(name)
        local amount = remaining
        local waited = false

        while remaining > 0 do
            local slotInfo = meta.selectFirstSlot(name, false)
            local amountToDrop = 0

            if slotInfo then
                local currentInSlot = slotInfo.count
                amountToDrop = math.min(currentInSlot, remaining)
            end

            if amountToDrop > 0 and dropFunc(amountToDrop) then
                remaining = remaining - amountToDrop
                waited = false
            else
                if blocking then
                    if waited then
                        os.sleep(1)
                    end

                    if type(blocking) == "function" then
                        blocking()
                    end

                    waited = true
                else
                    return amount - remaining
                end
            end
        end

        return amount
    end

    local function compareHelper(inspectFunc, name)
        name = name or robot.getSelectedName()

        if not name then
            error("name must not be nil", 0)
        end

        local _, detail = inspectFunc()

        if detail then
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

        -- Wenn count nil ist, saugen wir so viel wie möglich (bis zu 64)
        local target = count or 64
        local totalSucked = 0
        local waited = false

        while totalSucked < target or (blocking and totalSucked == 0) do
            local needed = target - totalSucked
            local success, amount = suckFunc(needed)

            if success then
                totalSucked = totalSucked + (amount or 1) -- amount kann bei alten CC-Versionen nil sein
                if totalSucked >= target then return totalSucked end
                waited = false
            else
                -- Nichts eingesaugt (Kiste leer oder Inventar voll)
                if blocking then
                    if waited then os.sleep(1) end
                    if type(blocking) == "function" then blocking() end
                    waited = true
                else
                    return totalSucked
                end
            end
        end

        return totalSucked
    end

    function robot.place(name, blocking)
        return placeHelper(turtle.place, name, blocking)
    end

    function robot.placeUp(name, blocking)
        return placeHelper(turtle.placeUp, name, blocking)
    end

    function robot.placeDown(name, blocking)
        return placeHelper(turtle.placeDown, name, blocking)
    end

    function robot.drop(name, count, blocking)
        return dropHelper(turtle.drop, name, count, blocking)
    end

    function robot.dropUp(name, count, blocking)
        return dropHelper(turtle.dropUp, name, count, blocking)
    end

    function robot.dropDown(name, count, blocking)
        return dropHelper(turtle.dropDown, name, count, blocking)
    end

    function robot.detect()
        return turtle.detect()
    end

    function robot.detectUp()
        return turtle.detectUp()
    end

    function robot.detectDown()
        return turtle.detectDown()
    end

    function robot.compare(name)
        return compareHelper(turtle.inspect, name)
    end

    function robot.compareUp(name)
        return compareHelper(turtle.inspectUp, name)
    end

    function robot.compareDown(name)
        return compareHelper(turtle.inspectDown, name)
    end

    function robot.suck(count, blocking)
        return suckHelper(turtle.suck, count, blocking)
    end

    function robot.suckUp(count, blocking)
        return suckHelper(turtle.suckUp, count, blocking)
    end

    function robot.suckDown(count, blocking)
        return suckHelper(turtle.suckDown, count, blocking)
    end

    function robot.inspect()
        return turtle.inspect()
    end

    function robot.inspectUp()
        return turtle.inspectUp()
    end

    function robot.inspectDown()
        return turtle.inspectDown()
    end
end
