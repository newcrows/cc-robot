return function(robot, meta, constants)
    local DELTAS = constants.deltas
    local FACING_INDEX = constants.facing_index
    local FACINGS = constants.facings
    local OPPOSITE_FACINGS = constants.opposite_facings
    local AUTO_FUEL_LOW_THRESHOLD = constants.auto_fuel_low_threshold
    local AUTO_FUEL_HIGH_THRESHOLD = constants.auto_fuel_high_threshold
    local autoFuels = {}
    local fuelWarningListenerId
    local fuelWarningClearedListenerId

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
                if type(blocking) == "function" then
                    blocking()
                end

                os.sleep(1)
            elseif not ok then
                return amount, err
            end

            local itemCount = turtle.getItemCount()
            local refuelCount = math.min(count - amount, itemCount)

            ok, err = turtle.refuel(refuelCount)

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
                        meta.dispatchEvent("fuel_warning_cleared")
                    end

                    return
                end
            end

            if not anyAutoFuelSeen then
                while turtle.getFuelLevel() < requiredFuelLevel do
                    meta.dispatchEvent(
                            "fuel_warning",
                            turtle.getFuelLevel(),
                            requiredFuelLevel,
                            autoFuels,
                            warningDispatched --recurrent and not cleared since
                    )

                    if warningDispatched then
                        os.sleep(1)
                    end

                    warningDispatched = true
                end

                return
            else
                meta.dispatchEvent(
                        "fuel_warning",
                        turtle.getFuelLevel(),
                        requiredFuelLevel,
                        autoFuels,
                        warningDispatched --recurrent and not cleared since
                )

                if warningDispatched then
                    os.sleep(1)
                end

                warningDispatched = true
            end
        end
    end

    local function step(moveFunc, blocking, delta)
        if blocking then
            local firstTry = true

            while not moveFunc() do
                if type(blocking) == "function" then
                    blocking(delta.x, delta.y, delta.z)
                end

                if firstTry then
                    firstTry = false
                else
                    os.sleep(1)
                end
            end

            return true
        end

        return moveFunc()
    end

    local function move(moveFunc, count, blocking, delta)
        local amount = 0
        local didUnwrap = false

        while amount < count do
            if amount == 0 then
                softUnwrapAll()
            end

            if turtle.getFuelLevel() < AUTO_FUEL_LOW_THRESHOLD then
                meta.autoFuel(AUTO_FUEL_HIGH_THRESHOLD)
            end

            local ok, err = step(moveFunc, blocking, delta)

            if ok then
                robot.x = robot.x + delta.x
                robot.y = robot.y + delta.y
                robot.z = robot.z + delta.z

                if not didUnwrap then
                    unwrapAll()
                    didUnwrap = true
                end

                amount = amount + 1
            else
                if amount == 0 then
                    softWrapAll()
                end

                if not blocking then
                    return amount, err
                end
            end
        end

        return amount
    end

    function robot.forward(count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking = count
            count = 1
        end

        count = count or 1
        return move(turtle.forward, count, blocking, DELTAS[robot.facing])
    end

    function robot.back(count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking = count
            count = 1
        end

        count = count or 1

        local oppositeFacing = OPPOSITE_FACINGS[robot.facing]
        return move(turtle.back, count, blocking, DELTAS[oppositeFacing])
    end

    function robot.up(count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking = count
            count = 1
        end

        count = count or 1
        return move(turtle.up, count, blocking, DELTAS.up)
    end

    function robot.down(count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking = count
            count = 1
        end

        count = count or 1
        return move(turtle.down, count, blocking, DELTAS.down)
    end

    function robot.turnRight(count)
        count = count or 1

        while count > 0 do
            turtle.turnRight()
            local facingI = (FACING_INDEX[robot.facing] + 1) % 4

            robot.facing = FACING_INDEX[facingI]
            count = count - 1
        end

        unwrapAll()
        return true
    end

    function robot.turnLeft(count)
        count = count or 1

        while count > 0 do
            turtle.turnLeft()
            local facingI = (FACING_INDEX[robot.facing] + 3) % 4

            robot.facing = FACING_INDEX[facingI]
            count = count - 1
        end

        unwrapAll()
        return true
    end

    function robot.move(dfb, dud, drl, blocking)
        local fbAmount = 0
        local dudAmount = 0
        local drlAmount = 0
        local err

        if dfb > 0 then
            fbAmount, err = robot.forward(dfb, blocking)
        elseif dfb < 0 then
            fbAmount, err = robot.back(-dfb, blocking)
            fbAmount = -fbAmount
        end

        if fbAmount ~= dfb then
            return fbAmount, dudAmount, drlAmount, err
        end

        if dud > 0 then
            dudAmount, err = robot.up(dud, blocking)
        elseif dud < 0 then
            dudAmount, err = robot.down(-dud, blocking)
            dudAmount = -dudAmount
        end

        if dudAmount ~= dud then
            return fbAmount, dudAmount, drlAmount, err
        end

        if drl > 0 then
            robot.turnRight()
            drlAmount, err = robot.forward(drl, blocking)
        elseif drl < 0 then
            robot.turnLeft()
            drlAmount, err = robot.forward(-drl, blocking)
            drlAmount = -drlAmount
        end

        if drlAmount ~= drl then
            return fbAmount, dudAmount, drlAmount, err
        end

        return fbAmount, dudAmount, drlAmount
    end

    function robot.face(facing)
        facing = facing or robot.facing

        if not FACINGS[facing] then
            error("invalid facing " .. facing)
        end

        local currentI = FACING_INDEX[robot.facing]
        local rightFacing = FACING_INDEX[(currentI + 1) % 4]
        local leftFacing = FACING_INDEX[(currentI - 1) % 4]

        if facing == robot.facing then
            return true
        elseif facing == rightFacing then
            robot.turnRight()
            return true
        elseif facing == leftFacing then
            robot.turnLeft()
        else
            robot.turnRight()
            robot.turnRight()
        end

        return true
    end

    function robot.setAutoFuel(name, reserveCount)
        if type(name) == "number" then
            reserveCount = name
            name = nil
        end

        name = name or robot.getSelectedName()
        reserveCount = reserveCount or 1

        if type(name) ~= "table" then
            name = {
                [name] = reserveCount
            }
        end

        for _name, _reserveCount in pairs(name) do
            robot.reserve(_name, _reserveCount)
        end

        autoFuels = name
        return true
    end

    function robot.removeAutoFuel()
        for name, reserveCount in pairs(autoFuels) do
            robot.free(name, reserveCount)
        end

        autoFuels = {}
        return true
    end

    function robot.onFuelWarning(callback)
        if not callback and fuelWarningListenerId then
            meta.removeEventListener(fuelWarningListenerId)
            fuelWarningListenerId = nil

            return
        end

        fuelWarningListenerId = meta.addEventListener({
            fuel_warning = callback
        })
    end

    function robot.onFuelWarningCleared(callback)
        if not callback and fuelWarningClearedListenerId then
            meta.removeEventListener(fuelWarningClearedListenerId)
            fuelWarningClearedListenerId = nil

            return
        end

        fuelWarningClearedListenerId = meta.addEventListener({
            fuel_warning_cleared = callback
        })
    end

    function robot.refuel(name, count, blocking)
        if type(name) == "boolean" or type(name) == "function" then
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
