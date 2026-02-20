return function(robot, meta, constants)
    local DELTAS = constants.deltas
    local FACING_INDEX = constants.facing_index
    local FACINGS = constants.facings
    local OPPOSITE_FACINGS = constants.opposite_facings
    local FUEL_LEVEL_WARNING = "fuel_level_warning"
    local PATH_WARNING = "path_warning"
    local FUEL_SAFETY_MARGIN = math.min(nativeTurtle.getFuelLimit() / 10 * 2, 1000)

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local acceptedFuels = {}

    local function moveHelper(moveFunc, delta, count, blocking)
        local moved = 0

        local function check()
            return moved >= count
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

        meta.require(check, tick, blocking)
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

    local function moveX(targetFacing, dx, callback)
        if dx ~= 0 then
            local facing = dx > 0 and FACINGS.east or FACINGS.west

            if facing ~= targetFacing then
                return true
            end

            robot.face(facing)
            robot.forward(math.abs(dx), function()
                callback(robot.x + clamp(dx), robot.y, robot.z, facing)
            end)
        end

        return true
    end

    local function moveY(targetFacing, dy, callback)
        if dy ~= 0 then
            local facing = dy > 0 and FACINGS.up or FACINGS.down
            if facing ~= targetFacing then
                return true
            end

            local moveFunc = dy > 0 and robot.up or robot.down
            moveFunc(math.abs(dy), function()
                callback(robot.x, robot.y + clamp(dy), robot.z, facing)
            end)
        end

        return true
    end

    local function moveZ(targetFacing, dz, callback)
        if dz ~= 0 then
            local facing = dz > 0 and FACINGS.south or FACINGS.north

            if facing ~= targetFacing then
                return true
            end

            robot.face(facing)
            robot.forward(math.abs(dz), function()
                callback(robot.x, robot.y, robot.z + clamp(dz), facing)
            end)
        end

        return true
    end

    local function moveInOrder(order, blocking)
        for _, entry in ipairs(order) do
            entry[1](entry[2], entry[3], blocking)
        end
    end

    local function getKeys(table)
        local keys = {}

        for key in pairs(table) do
            keys[#keys + 1] = key
        end

        return keys
    end

    function meta.requireFuelLevel(requiredLevel)
        if not next(acceptedFuels) then
            error("no accepted fuels configured! use robot.setFuel() first.", 0)
        end

        if requiredLevel > nativeTurtle.getFuelLimit() then
            error("requiredLevel is bigger than turtle.getFuelLimit()!", 0)
        end

        requiredLevel = math.min(requiredLevel + FUEL_SAFETY_MARGIN, nativeTurtle.getFuelLimit())

        local function check()
            return refuelTo(requiredLevel)
        end

        local function get()
            return nativeTurtle.getFuelLevel(), requiredLevel, acceptedFuels
        end

        meta.requireCleared(check, get, FUEL_LEVEL_WARNING)
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

    function robot.moveTo(x, y, z)
        if type(x) == "table" then
            local name = x.name
            x, y, z = x.x, x.y, x.z

            if name then
                local ox, oy, oz = x - robot.x, y - robot.y, z - robot.z

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

        meta.requireFuelLevel(math.abs(dx) + math.abs(dy) + math.abs(dz))

        local order = {
            { moveY, FACINGS.up, dy },
            { moveX, FACINGS.east, dx },
            { moveZ, FACINGS.north, dz },
            { moveZ, FACINGS.south, dz },
            { moveX, FACINGS.west, dx },
            { moveY, FACINGS.down, dy }
        }
        local blocking = function(tx, ty, tz, tf)
            local function check()
                local detectFuncs = {
                    [FACINGS.up] = nativeTurtle.detectUp,
                    [FACINGS.down] = nativeTurtle.detectDown,
                }

                local detectFunc = detectFuncs[tf] or nativeTurtle.detect
                return not detectFunc()
            end

            local function get()
                -- the obstructing block's coordinates, NOT the turtle's coordinates
                return tx, ty, tz
            end

            meta.requireCleared(check, get, PATH_WARNING)
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

    function robot.onFuelLevelWarning(callback)
        meta.on(FUEL_LEVEL_WARNING, callback)
    end

    function robot.onFuelLevelWarningCleared(callback)
        meta.on(FUEL_LEVEL_WARNING .. "_cleared", callback)
    end

    function robot.onPathWarning(callback)
        meta.on(PATH_WARNING, callback)
    end

    function robot.onPathWarningCleared(callback)
        meta.on(PATH_WARNING .. "_cleared", callback)
    end

    local lastSeenLevel
    robot.onFuelLevelWarning(function(alreadyWarned, level, requiredLevel)
        if not alreadyWarned or lastSeenLevel ~= level then
            local acceptedNames = getKeys(acceptedFuels)

            print("---- " .. FUEL_LEVEL_WARNING .. " ----")
            print("level = " .. level)
            print("requiredLevel = " .. requiredLevel)
            print("acceptedFuels = [" .. table.concat(acceptedNames, ", ") .. "]")

            lastSeenLevel = level
        end
    end)
    robot.onFuelLevelWarningCleared(function()
        print("---- " .. FUEL_LEVEL_WARNING .. "_cleared ----")
    end)

    robot.onPathWarning(function(alreadyWarned, x, y, z)
        if not alreadyWarned then
            print("---- " .. PATH_WARNING .. " ----")
            print("path is obstructed at (" .. x .. ", " .. y .. ", " .. z .. ")")
        end
    end)
    robot.onPathWarningCleared(function()
        print("---- " .. PATH_WARNING .. "_cleared ----")
    end)
end
