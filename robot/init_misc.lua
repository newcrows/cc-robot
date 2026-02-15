return function(robot, meta, constants)
    local function place(placeFunc, name, blocking)
        if blocking then
            while not meta.selectFirstSlot(name) or not placeFunc() do
                sleep(1)
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

            local itemCount = turtle.getItemCount()
            local dropCount = math.min(count - amount, itemCount)

            ok, err = dropFunc(dropCount)

            if not ok and blocking then
                os.sleep(1)
            elseif not ok then
                return amount, err
            end

            local dropAmount = itemCount - turtle.getItemCount()
            amount = amount + dropAmount
        end

        return amount
    end

    function robot.place(name, blocking)
        name = name or robot.getSelectedName()
        return place(turtle.place, name, blocking)
    end

    function robot.placeUp(name, blocking)
        name = name or robot.getSelectedName()
        return place(turtle.placeUp, name, blocking)
    end

    function robot.placeDown(name, blocking)
        name = name or robot.getSelectedName()
        return place(turtle.placeDown, name, blocking)
    end

    function robot.drop(name, count, blocking)
        name = name or robot.getSelectedName()
        count = count or robot.getItemCount(name)

        return drop(turtle.drop, name, count, blocking)
    end

    function robot.dropUp(name, count, blocking)
        name = name or robot.getSelectedName()
        count = count or robot.getItemCount(name)

        return drop(turtle.dropUp, name, count, blocking)
    end

    function robot.dropDown(name, count, blocking)
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
        -- TODO [JM] implement
    end

    function robot.compareUp(name)
        -- TODO [JM] implement
    end

    function robot.compareDown(name)
        -- TODO [JM] implement
    end

    function robot.suck(count, blocking)
        -- TODO [JM] implement
    end

    function robot.suckUp(count, blocking)
        -- TODO [JM] implement
    end

    function robot.suckDown(count, blocking)
        -- TODO [JM] implement
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
