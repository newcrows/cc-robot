return function(robot, meta)
    local function physicalCountAll()
        local total = 0

        for i = 1, 16 do
            total = total + turtle.getItemCount(i)
        end

        return total
    end

    local function countEmptySlots()
        return #meta.listEmptySlots()
    end

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
            local slotInfo = meta.selectFirstSlot(name)
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

        local totalSucked = 0
        local waited = false

        while (count and totalSucked < count) or (not count and countEmptySlots() > 0) or (blocking and totalSucked == 0) do
            local nextAmount = 64

            if count then
                nextAmount = math.min(64, count - totalSucked)
            end

            -- Bestandsaufnahme vor dem Saugen
            local before = physicalCountAll()
            local success = suckFunc(nextAmount)

            if success then
                -- Bestandsaufnahme nach dem Saugen zur Ermittlung der Differenz
                local after = physicalCountAll()
                local amount = after - before

                totalSucked = totalSucked + amount
                waited = false

                if count and totalSucked >= count then
                    return totalSucked
                end

                -- Falls success true war, aber 0 Items kamen (sehr selten, aber möglich):
                if amount == 0 and not blocking then
                    return totalSucked
                end
            else
                -- Nichts eingesaugt (Kiste leer oder kein freier Slot mehr verfügbar)
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
