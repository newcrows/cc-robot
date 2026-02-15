local function setup(robot, utility)
    turtle.select(1)
    utility.getStackFromChest("minecraft:diamond_pickaxe")
    utility.getStackFromChest("minecraft:chest")

    assert(turtle.getItemCount(1) > 0)
    assert(turtle.getItemCount(2) > 0)

    robot.equip("minecraft:diamond_pickaxe")
    robot.reserve("minecraft:chest")
end

local function teardown(robot)
    robot.turnRight()
    robot.turnLeft()

    robot.unequip("minecraft:diamond_pickaxe")
    robot.free("minecraft:chest")

    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            turtle.drop()
        end
    end
end

return function(robot, utility)
    setup(robot, utility)

    assert(not robot.wrapUp())

    local chest = robot.wrap()
    assert(chest.export("minecraft:coal", 8) == 8)
    assert(robot.getItemCount("minecraft:coal") == 8)

    teardown(robot)
    print("test_peripherals passed")
end
