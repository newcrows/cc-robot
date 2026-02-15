local function setup()

end

local function teardown()

end

return function(robot, utility)
    local FACINGS = robot.constants.facings
    setup()

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local function testForward()
        assert(not robot.forward())
        assert(robot.x == 0 and robot.y == 0 and robot.z == 0)

        robot.turnRight()

        assert(robot.forward())
        assert(robot.x == 1 and robot.y == 0 and robot.z == 0)

        robot.back()
        robot.turnLeft()
    end

    local function testBack()
        robot.turnRight()
        robot.turnRight()

        assert(not robot.back())
        assert(robot.x == 0 and robot.y == 0 and robot.z == 0)

        robot.turnRight()

        assert(robot.back())
        assert(robot.x == 1 and robot.y == 0 and robot.z == 0)

        robot.forward()
        robot.turnRight()
    end

    local function testUp()
        assert(robot.up())
        assert(robot.x == 0 and robot.y == 1 and robot.z == 0)

        robot.down()
    end

    local function testDown()
        assert(not robot.down())
        assert(robot.x == 0 and robot.y == 0 and robot.z == 0)

        robot.up()

        assert(robot.down())
        assert(robot.x == 0 and robot.y == 0 and robot.z == 0)
    end

    local function testTurnRight()
        assert(robot.turnRight())
        assert(robot.facing == FACINGS.east)

        assert(robot.turnRight())
        assert(robot.facing == FACINGS.south)

        assert(robot.turnRight())
        assert(robot.facing == FACINGS.west)

        assert(robot.turnRight())
        assert(robot.facing == FACINGS.north)
    end

    local function testTurnLeft()
        assert(robot.turnLeft())
        assert(robot.facing == FACINGS.west)

        assert(robot.turnLeft())
        assert(robot.facing == FACINGS.south)

        assert(robot.turnLeft())
        assert(robot.facing == FACINGS.east)

        assert(robot.turnLeft())
        assert(robot.facing == FACINGS.north)
    end

    local function testAutoFuel()
        local level = turtle.getFuelLevel()
        local requiredLevel = level + 20
        local stickCount

        robot.addAutoFuel("minecraft:stick", 4)
        robot.onAutoFuelWarning(function(_level, _requiredLevel, autoFuels)
            assert(_level == level)
            assert(_requiredLevel == requiredLevel)
            assert(autoFuels["minecraft:stick"] and autoFuels["minecraft:stick"] == 4)

            turtle.select(1)
            utility.getStackFromChest("minecraft:stick")

            stickCount = turtle.getItemCount(1)
            assert(stickCount >= 4)
        end)

        robot.meta.autoFuel(requiredLevel)
        assert(turtle.getItemCount(1) == stickCount - 4)

        turtle.drop()
        assert(turtle.getItemCount() == 0)

        for i = 1, 10 do
            turtle.up()
            turtle.down()
        end

        assert(turtle.getFuelLevel() == level)
    end

    testForward()
    testBack()
    testUp()
    testDown()
    testTurnRight()
    testTurnLeft()
    testAutoFuel()

    teardown()
    print("test_positioning passed")
end
