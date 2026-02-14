return function(robot, _, constants)
    local FACINGS = constants.facings

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    function robot.forward(blocking)

    end

    function robot.back(blocking)

    end

    function robot.up(blocking)

    end

    function robot.down(blocking)

    end

    function robot.turnRight()

    end

    function robot.turnLeft()

    end

    function robot.refuel(name, count, blocking)

    end

    function robot.getFuelLevel()

    end

    function robot.getFuelLimit()

    end
end
