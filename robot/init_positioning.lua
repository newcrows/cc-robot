return function(robot, meta, constants)
    local DELTAS = constants.deltas
    local FACING_INDEX = constants.facing_index
    local FACINGS = constants.facings
    local OPPOSITE_FACINGS = constants.opposite_facings

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local function callAll(callFunc)
        for _, wrappedPeripheral in pairs(meta.listWrappedPeripherals()) do
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

    function robot.refuel(name, count, blocking)
        -- TODO [JM] implement
    end

    function robot.getFuelLevel()
        return turtle.getFuelLevel()
    end

    function robot.getFuelLimit()
        return turtle.getFuelLimit()
    end
end
