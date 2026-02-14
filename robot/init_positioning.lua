return function(robot, _, constants)
    local FACINGS = constants.facings

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local function softWrapAll()
        for side, _ in pairs(meta.peripheralProxies) do
            meta.softWrap(side)
        end
    end

    local function softUnwrapAll()
        for side, _ in pairs(meta.peripheralProxies) do
            meta.softUnwrap(side)
        end
    end

    local function unwrapAll()
        for side, _ in pairs(meta.peripheralProxies) do
            meta.unwrap(side)
        end
    end

    local function move_0(moveFunc, blocking)
        if blocking then
            while not moveFunc() do
                sleep(1)
            end

            return true
        end

        return moveFunc()
    end

    local function move(moveFunc, blocking)
        softUnwrapAll()

        local ok, err = move_0(moveFunc, blocking)

        if ok then
            local delta = DELTAS[robot.facing]

            robot.x = robot.x + delta.x
            robot.z = robot.z + delta.z

            unwrapAll()
        else
            softWrapAll()
        end

        return ok, err
    end

    function robot.forward(blocking)
        return move(turtle.forward, blocking)
    end

    function robot.back(blocking)
        return move(turtle.back, blocking)
    end

    function robot.up(blocking)
        return move(turtle.up, blocking)
    end

    function robot.down(blocking)
        return move(turtle.down, blocking)
    end

    function robot.turnRight()
        turtle.turnRight()
        unwrapAll()

        return true
    end

    function robot.turnLeft()
        turtle.turnLeft()
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
