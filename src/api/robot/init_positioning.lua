return function(robot, meta, constants)
    local DELTAS = constants.deltas
    local FACING_INDEX = constants.facing_index
    local FACINGS = constants.facings
    local OPPOSITE_FACINGS = constants.opposite_facings

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local acceptedFuels = {}
    local fuelWarningListenerId
    local fuelWarningClearedListenerId

    local function moveHelper(moveFunc, delta, count, blocking)
        local moved = 0

        local function check()
            return moved < count
        end

        local function tick()
            if moveFunc() then
                robot.x = robot.x + delta.x
                robot.y = robot.y + delta.y
                robot.z = robot.z + delta.z

                moved = moved + 1
                meta.softUnwrapAll()
            end
        end

        meta.ensure(check, tick, blocking)
        return moved
    end

    local function turnHelper(turnFunc, direction, count)
        count = count or 1

        for i = 1, count do
            turnFunc()
        end

        local facingI = (FACING_INDEX[robot.facing] + (direction * count)) % 4

        robot.facing = FACING_INDEX[facingI]
        meta.softUnwrapAll()

        return count
    end

    local function refuel(name, count)
        local slot = meta.selectFirstSlot(name, true)

        if slot then
            local cappedCount = math.min(nativeTurtle.getItemCount(), count)
            nativeTurtle.refuel(cappedCount)
        end
    end

    local function refuelTo(requiredLevel)
        if nativeTurtle.getFuelLevel() >= requiredLevel then
            return true
        end

        for name, reserveCount in pairs(acceptedFuels) do
            local availableCount = math.min(robot.getReservedItemCount(name), reserveCount)
            refuel(name, availableCount)

            if nativeTurtle.getFuelLevel() >= requiredLevel then
                return true
            end
        end

        return false
    end

    local function clamp(val)
        return math.max(-1, math.min(1, val))
    end

    local function moveX(targetFacing, dx, blocking)
        if dx ~= 0 then
            local facing = dx > 0 and FACINGS.east or FACINGS.west

            if facing ~= targetFacing then
                return true
            end

            robot.face(facing)
            robot.forward(math.abs(dx), blocking)
        end

        return true
    end

    local function moveY(targetFacing, dy, blocking)
        if dy ~= 0 then
            local facing = dy > 0 and FACINGS.up or FACINGS.down
            if facing ~= targetFacing then
                return true
            end

            local moveFunc = dy > 0 and robot.up or robot.down
            moveFunc(math.abs(dy), blocking)
        end

        return true
    end

    local function moveZ(targetFacing, dz, blocking)
        if dz ~= 0 then
            local facing = dz > 0 and FACINGS.south or FACINGS.north

            if facing ~= targetFacing then
                return true
            end

            robot.face(facing)
            robot.forward(math.abs(dz), blocking)
        end

        return true
    end

    local function moveInOrder(order, blocking)
        for _, entry in ipairs(order) do
            entry[1](entry[2], entry[3], blocking)
        end
    end

    function meta.requireFuelLevel(requiredLevel)
        if not next(acceptedFuels) then
            error("no accepted fuels configured! use robot.setFuel() first.", 0)
        end

        if requiredLevel > nativeTurtle.getFuelLimit() then
            error("requiredLevel is bigger than turtle.getFuelLimit()!", 0)
        end

        local function check()
            return refuelTo(requiredLevel)
        end

        local function get()
            return nativeTurtle.getFuelLevel(), requiredLevel, acceptedFuels
        end

        meta.ensureCleared(check, get, "fuel_warning")
    end

    function robot.forward(count, blocking)
        return moveHelper(nativeTurtle.forward, DELTAS[robot.facing], count, blocking)
    end

    function robot.back(count, blocking)
        local opposite = OPPOSITE_FACINGS[robot.facing]
        return moveHelper(nativeTurtle.back, DELTAS[opposite], count, blocking)
    end

    function robot.up(count, blocking)
        return moveHelper(nativeTurtle.up, DELTAS.up, count, blocking)
    end

    function robot.down(count, blocking)
        return moveHelper(nativeTurtle.down, DELTAS.down, count, blocking)
    end

    function robot.turnRight(count)
        return turnHelper(nativeTurtle.turnRight, 1, count)
    end

    function robot.turnLeft(count)
        return turnHelper(nativeTurtle.turnLeft, -1, count)
    end

    -- TODO [JM] remove the "blocking" arg, instead fire fuel_warning and path_warning separately
    -- also make all primitive move funcs (forward, back, up, down) use meta.ensure() directly
    -- also, the primitive functions should NOT fire fuel_warning any longer
    -- only complex functions (moveTo, equip, unequip, $softWrap, ..) should use any meta.require* logic
    function robot.moveTo(x, y, z)
        if type(x) == "table" then
            local name = x.name

            blocking = y
            x, y, z = x.x, x.y, x.z

            if name then
                local ox, oy, oz = x - robot.x, y - robot.y, z - robot.z

                -- TODO [JM] will this move THROUGH target peripheral? or does it always come from correct side?
                if ox ~= 0 then
                    x = x - clamp(ox)
                elseif oy ~= 0 then
                    y = y - clamp(oy)
                elseif oz ~= 0 then
                    z = z - clamp(oz)
                end
            end
        end

        local dx = (x or robot.x) - robot.x
        local dy = (y or robot.y) - robot.y
        local dz = (z or robot.z) - robot.z

        local order = {
            { moveX, FACINGS.east, dx},
            { moveY, FACINGS.up, dy},
            { moveZ, FACINGS.north, dz},
            { moveZ, FACINGS.south, dz},
            { moveY, FACINGS.down, dy},
            { moveX, FACINGS.west, dx}
        }
        local blocking = function()
            -- TODO [JM] will trigger meta.ensureCleared(.., "path_warning")
            -- with get() -> alreadyWarned, x, y, z, facing, side
        end

        moveInOrder(order, blocking)
        return robot.x, robot.y, robot.z
    end

    function robot.face(facing)
        local diff = (FACING_INDEX[facing] - FACING_INDEX[robot.facing]) % 4

        if diff == 1 then
            nativeTurtle.turnRight()
        elseif diff == 2 then
            nativeTurtle.turnRight()
            nativeTurtle.turnRight()
        elseif diff == 3 then
            nativeTurtle.turnLeft()
        end

        robot.facing = facing
    end

    function robot.setFuel(name, reserveCount)
        for _name, _reserveCount in pairs(acceptedFuels) do
            robot.free(_name, _reserveCount)
        end

        acceptedFuels = ({
            ["nil"] = function()
                return {}
            end,
            ["string"] = function()
                return { [name] = reserveCount or constants.default_stack_size }
            end,
            ["table"] = function()
                return name
            end
        })[type(name)]()

        for _name, _reserveCount in pairs(acceptedFuels) do
            robot.reserve(_name, _reserveCount)
        end
    end

    function robot.getFuelLevel()
        return nativeTurtle.getFuelLevel()
    end

    function robot.getFuelLimit()
        return nativeTurtle.getFuelLimit()
    end

    function robot.onFuelWarning(callback)
        if fuelWarningListenerId then
            meta.removeEventListener(fuelWarningListenerId)
            fuelWarningListenerId = nil
        end

        if callback then
            fuelWarningListenerId = meta.addEventListener({
                fuel_warning = callback
            })
        end
    end

    function robot.onFuelWarningCleared(callback)
        if fuelWarningClearedListenerId then
            meta.removeEventListener(fuelWarningClearedListenerId)
            fuelWarningClearedListenerId = nil
        end

        if callback then
            fuelWarningClearedListenerId = meta.addEventListener({
                fuel_warning_cleared = callback
            })
        end
    end

    robot.onFuelWarning(function(alreadyWarned, level, requiredLevel)
        if not alreadyWarned then
            local acceptedNames = meta.getKeys(acceptedFuels)

            print("---- fuel_warning ----")
            print("level = " .. level)
            print("requiredLevel = " .. requiredLevel)
            print("acceptedFuels = [" .. table.concat(acceptedNames, ", ") .. "]")
            print("----------------------")
        end
    end)

    robot.onFuelWarningCleared(function()
        print("---- fuel_warning_cleared ----")
    end)
end
