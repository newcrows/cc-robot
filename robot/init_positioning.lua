return function(robot, meta, constants)
    local DELTAS = constants.deltas
    local FACING_INDEX = constants.facing_index
    local FACINGS = constants.facings
    local OPPOSITE_FACINGS = constants.opposite_facings
    local AUTO_FUEL_LOW_THRESHOLD = constants.auto_fuel_low_threshold
    local AUTO_FUEL_HIGH_THRESHOLD = constants.auto_fuel_high_threshold
    local autoFuels = {}

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local function callAll(callFunc)
        for _, wrappedPeripheral in pairs(meta.listPeripherals()) do
            callFunc(wrappedPeripheral.side)
        end
    end

    local function softWrapAll()
        callAll(meta.softWrap)
    end

    local function softUnwrapAll()
        callAll(meta.softUnwrap)
    end

    local function unwrapAll()
        callAll(meta.unwrap)
    end

    local function refuel(name, count, blocking, includeReservedItems)
        local amount = 0

        while amount < count do
            local ok, err = meta.selectFirstSlot(name, false, includeReservedItems)

            if not ok and blocking then
                os.sleep(1)
            elseif not ok then
                return amount, err
            end

            local itemCount = turtle.getItemCount()
            local dropCount = math.min(count - amount, itemCount)

            ok, err = turtle.refuel(dropCount)

            if not ok and blocking then
                os.sleep(1)
            elseif not ok or turtle.getFuelLevel() == turtle.getFuelLimit() then
                return amount, err
            end

            local dropAmount = itemCount - turtle.getItemCount()
            amount = amount + dropAmount
        end

        return amount
    end

    local function autoFuel(requiredFuelLevel)
        local anyAutoFuelSeen = false
        local warningDispatched = false

        while true do
            for name, count in pairs(autoFuels) do
                if count > 0 then
                    anyAutoFuelSeen = true
                end

                refuel(name, count, false, true)

                if turtle.getFuelLevel() >= requiredFuelLevel then
                    if warningDispatched then
                        meta.dispatchEvent("auto_fuel_warning_cleared")
                    end

                    return
                end
            end

            if not anyAutoFuelSeen then
                return
            else
                if not warningDispatched then
                    meta.dispatchEvent("auto_fuel_warning", requiredFuelLevel, turtle.getFuelLevel(), autoFuels)
                    warningDispatched = true
                end

                os.sleep(1)
            end
        end
    end

    local function step(moveFunc, blocking)
        if blocking then
            while not moveFunc() do
                sleep(1)
            end

            return true
        end

        return moveFunc()
    end

    local function move(moveFunc, blocking, delta)
        softUnwrapAll()

        if turtle.getFuelLevel() < AUTO_FUEL_LOW_THRESHOLD then
            meta.autoFuel(AUTO_FUEL_HIGH_THRESHOLD)
        end

        local ok, err = step(moveFunc, blocking)

        if ok then
            robot.x = robot.x + delta.x
            robot.y = robot.y + delta.y
            robot.z = robot.z + delta.z

            unwrapAll()
        else
            softWrapAll()
        end

        return ok, err
    end

    function robot.forward(blocking)
        return move(turtle.forward, blocking, DELTAS[robot.facing])
    end

    function robot.back(blocking)
        local oppositeFacing = OPPOSITE_FACINGS[robot.facing]
        return move(turtle.back, blocking, DELTAS[oppositeFacing])
    end

    function robot.up(blocking)
        return move(turtle.up, blocking, DELTAS.up)
    end

    function robot.down(blocking)
        return move(turtle.down, blocking, DELTAS.down)
    end

    function robot.turnRight()
        turtle.turnRight()

        local facingI = (FACING_INDEX[robot.facing] + 1) % 4
        robot.facing = FACING_INDEX[facingI]

        unwrapAll()
        return true
    end

    function robot.turnLeft()
        turtle.turnLeft()

        local facingI = (FACING_INDEX[robot.facing] + 3) % 4
        robot.facing = FACING_INDEX[facingI]

        unwrapAll()
        return true
    end

    function robot.addAutoFuel(name, reserveCount)
        name = name or robot.getSelectedName()
        reserveCount = reserveCount or 1

        robot.reserve(name, reserveCount)
        autoFuels[name] = (autoFuels[name] or 0) + reserveCount

        return true
    end

    function robot.removeAutoFuel(name, freeCount)
        name = name or robot.getSelectedName()
        freeCount = freeCount or 1

        autoFuels[name] = (autoFuels[name] or 0) - freeCount
        robot.free(name, freeCount)

        return true
    end

    function robot.onAutoFuelWarning(callback)
        meta.addEventListener({
            auto_fuel_warning = callback
        })
    end

    function robot.refuel(name, count, blocking)
        return refuel(name, count, blocking)
    end

    function robot.getFuelLevel()
        return turtle.getFuelLevel()
    end

    function robot.getFuelLimit()
        return turtle.getFuelLimit()
    end

    function meta.autoFuel(requiredFuelLevel)
        if turtle.getFuelLevel() < requiredFuelLevel then
            autoFuel(requiredFuelLevel)
        end
    end
end
