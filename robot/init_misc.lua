return function(robot, meta, constants)
    local function place(placeFunc, name, blocking)
        if blocking then
            while not meta.selectFirstSlot(name) or not placeFunc() do
                os.sleep(1)
            end

            return true
        end

        return meta.selectFirstSlot(name) and placeFunc()
    end

    local function drop(dropFunc, name, count, blocking)
        local amount = 0

        while amount < count do
            local ok, err = meta.selectFirstSlot(name)

            if not ok and blocking then
                os.sleep(1)
            elseif not ok then
                return amount, err
            end

            local itemCount = robot.getItemCount(name)
            local dropCount = math.min(count - amount, itemCount)

            ok, err = dropFunc(dropCount)

            if not ok and blocking then
                os.sleep(1)
            elseif not ok then
                return amount, err
            end

            local dropAmount = itemCount - robot.getItemCount(name)
            amount = amount + dropAmount
        end

        return amount
    end

    local function compare(inspectFunc, name)
        local blockExists, blockDetail = inspectFunc()

        if blockExists and blockDetail.name == name then
            return true
        elseif not blockExists and name == "air" then
            return true
        end

        return false
    end

    local function suck(suckFunc, count, blocking)
        count = count or 9999
        local amount = 0

        while amount < count do
            local rawCount = meta.countItems(nil, true, true)
            local suckCount = math.min(count - amount, 64)

            local ok, err = suckFunc(suckCount)

            if not ok and blocking then
                if count == 9999 and amount > 0 then
                    return amount
                end

                os.sleep(1)
            elseif not ok then
                if count == 9999 then
                    return amount
                end

                return amount, err
            end

            amount = amount + meta.countItems(nil, true, true) - rawCount
        end

        return amount
    end

    function robot.place(name, blocking)
        if type(name) == "boolean" then
            blocking = name
            name = nil
        end

        name = name or robot.getSelectedName()
        return place(turtle.place, name, blocking)
    end

    function robot.placeUp(name, blocking)
        if type(name) == "boolean" then
            blocking = name
            name = nil
        end

        name = name or robot.getSelectedName()
        return place(turtle.placeUp, name, blocking)
    end

    function robot.placeDown(name, blocking)
        if type(name) == "boolean" then
            blocking = name
            name = nil
        end

        name = name or robot.getSelectedName()
        return place(turtle.placeDown, name, blocking)
    end

    function robot.drop(name, count, blocking)
        if type(name) == "boolean" then
            blocking = name
            count = nil
            name = nil
        elseif type(name) == "number" then
            blocking = count
            count = name
            name = nil
        elseif type(name) == "string" and type("count") == "boolean" then
            blocking = count
            count = nil
        end

        name = name or robot.getSelectedName()
        count = count or robot.getItemCount(name)

        return drop(turtle.drop, name, count, blocking)
    end

    function robot.dropUp(name, count, blocking)
        if type(name) == "boolean" then
            blocking = name
            count = nil
            name = nil
        elseif type(name) == "number" then
            blocking = count
            count = name
            name = nil
        elseif type(name) == "string" and type("count") == "boolean" then
            blocking = count
            count = nil
        end

        name = name or robot.getSelectedName()
        count = count or robot.getItemCount(name)

        return drop(turtle.dropUp, name, count, blocking)
    end

    function robot.dropDown(name, count, blocking)
        if type(name) == "boolean" then
            blocking = name
            count = nil
            name = nil
        elseif type(name) == "number" then
            blocking = count
            count = name
            name = nil
        elseif type(name) == "string" and type("count") == "boolean" then
            blocking = count
            count = nil
        end

        name = name or robot.getSelectedName()
        count = count or robot.getItemCount(name)

        return drop(turtle.dropDown, name, count, blocking)
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
        name = name or robot.getSelectedName()
        return compare(turtle.inspect, name)
    end

    function robot.compareUp(name)
        name = name or robot.getSelectedName()
        return compare(turtle.inspectUp, name)
    end

    function robot.compareDown(name)
        name = name or robot.getSelectedName()
        return compare(turtle.inspectDown, name)
    end

    function robot.suck(count, blocking)
        if type(count) == "boolean" then
            blocking = count
            count = nil
        end

        return suck(turtle.suck, count, blocking)
    end

    function robot.suckUp(count, blocking)
        if type(count) == "boolean" then
            blocking = count
            count = nil
        end

        return suck(turtle.suckUp, count, blocking)
    end

    function robot.suckDown(count, blocking)
        if type(count) == "boolean" then
            blocking = count
            count = nil
        end

        return suck(turtle.suckDown, count, blocking)
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
