local function setup()

end

local function teardown()

end

return function(robot, utility)
    setup()
    local FACINGS = robot.constants.facings

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

        robot.setAutoFuel("minecraft:stick", 4)
        robot.onFuelWarning(function(_level, _requiredLevel, autoFuels)
            assert(_level == level)
            assert(_requiredLevel == requiredLevel)
            assert(autoFuels["minecraft:stick"] and autoFuels["minecraft:stick"] == 4)

            turtle.select(1)
            utility.getStackFromChest("minecraft:stick")

            stickCount = turtle.getItemCount(1)
            assert(stickCount >= 4)
        end)

        robot.meta.autoFuel(requiredLevel)
        robot.removeAutoFuel()

        assert(turtle.getItemCount(1) == stickCount - 4)

        robot.drop("minecraft:stick")
        assert(turtle.getItemCount() == 0)

        for i = 1, 10 do
            turtle.up()
            turtle.down()
        end

        assert(turtle.getFuelLevel() == level)
    end

    local function testRefuel()
        local level = turtle.getFuelLevel()

        turtle.select(1)
        utility.getStackFromChest("minecraft:stick")

        local stickCount = robot.getItemCount("minecraft:stick")
        assert(stickCount > 0)

        robot.refuel("minecraft:stick", 4)
        assert(turtle.getFuelLevel() == level + 20)
        assert(robot.getItemCount("minecraft:stick") == stickCount - 4)

        robot.drop("minecraft:stick")
        assert(turtle.getItemCount() == 0)

        for i = 1, 10 do
            turtle.up()
            turtle.down()
        end

        assert(turtle.getFuelLevel() == level)
    end

    local function testGetFuelLevel()
        assert(robot.getFuelLevel() == turtle.getFuelLevel())
    end

    local function testGetFuelLimit()
        assert(robot.getFuelLimit() == turtle.getFuelLimit())
    end

    testForward()
    testBack()
    testUp()
    testDown()
    testTurnRight()
    testTurnLeft()
    testAutoFuel()
    testRefuel()
    testGetFuelLevel()
    testGetFuelLimit()

    teardown()
    print("test_positioning passed")
end
