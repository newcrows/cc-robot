local function setup(_, utility)
    turtle.select(1)

    utility.getStackFromChest("minecraft:diamond_pickaxe")
    utility.getStackFromChest("minecraft:diamond_axe")
    utility.getStackFromChest("minecraft:diamond_shovel")
    utility.getStackFromChest("minecraft:chest")
    utility.getStackFromChest("minecraft:coal")
end

local function teardown()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            turtle.drop()
        end
    end
end

return function(robot, utility)
    setup(nil, utility)

    robot.select("minecraft:diamond_pickaxe")
    assert(robot.getSelectedName() == "minecraft:diamond_pickaxe")

    local coalCount = turtle.getItemCount(5)
    local coalSpace = 64 - coalCount
    assert(coalCount == robot.getItemDetail("minecraft:coal").count)
    assert(coalCount == robot.getItemCount("minecraft:coal"))
    assert(coalSpace == robot.getItemSpace("minecraft:coal") - 11 * 64)
    assert(robot.getItemSpaceForUnknown() == 11 * 64)

    robot.reserve("minecraft:coal", 65)
    local physicalCoalSpace = 11 * 64 + coalSpace
    local adjustedCoalSpace = physicalCoalSpace - robot.getReservedItemSpace("minecraft:coal")

    assert(not robot.getItemDetail("minecraft:coal"))
    assert(robot.getItemCount("minecraft:coal") == 0)
    assert(robot.getItemSpace("minecraft:coal") == adjustedCoalSpace)
    assert(robot.getItemSpaceForUnknown() == 10 * 64)

    assert(robot.getReservedItemDetail("minecraft:coal").count == coalCount)
    assert(robot.getReservedItemCount("minecraft:coal") == coalCount)
    assert(robot.getReservedItemSpace("minecraft:coal") == coalSpace + 1)

    robot.free("minecraft:coal", 65)

    coalCount = turtle.getItemCount(5)
    coalSpace = 64 - coalCount

    assert(coalCount == robot.getItemDetail("minecraft:coal").count)
    assert(coalCount == robot.getItemCount("minecraft:coal"))
    assert(coalSpace == robot.getItemSpace("minecraft:coal") - 11 * 64)
    assert(robot.getItemSpaceForUnknown() == 11 * 64)

    assert(not robot.getReservedItemDetail("minecraft:coal"))
    assert(robot.getReservedItemCount("minecraft:coal") == 0)
    assert(robot.getReservedItemSpace("minecraft:coal") == 0)

    teardown()
    print("test_inventory passed")
end
