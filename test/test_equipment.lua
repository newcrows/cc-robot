local function setup(_, utility)
    turtle.select(1)

    utility.getStackFromChest("minecraft:diamond_pickaxe")
    utility.getStackFromChest("minecraft:diamond_axe")
    utility.getStackFromChest("minecraft:diamond_shovel")
    --utility.getStackFromChest("minecraft:chest")

    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(2) == 1)
    assert(turtle.getItemCount(3) == 1)
    --assert(turtle.getItemCount(4) > 0)
end

local function teardown()
    for i = 1, 16 do
        assert(turtle.getItemCount(1) == 0)
    end
end

return function(robot, utility)
    setup(nil, utility)

    local pickaxe = robot.equip("minecraft:diamond_pickaxe", true)
    local axe = robot.equip("minecraft:diamond_axe")
    local shovel = robot.equip("minecraft:diamond_shovel")

    pickaxe.digUp()
    axe.digUp()
    shovel.digUp()

    assert(pickaxe.target)
    assert(not axe.target)
    assert(shovel.target)

    assert(robot.drop("minecraft:diamond_pickaxe") == 0)
    assert(robot.drop("minecraft:diamond_axe") == 0)
    assert(robot.drop("minecraft:diamond_shovel") == 0)

    robot.unequip("minecraft:diamond_pickaxe")
    robot.unequip("minecraft:diamond_axe")
    robot.unequip("minecraft:diamond_shovel")

    assert(robot.drop("minecraft:diamond_pickaxe") == 1)
    assert(robot.drop("minecraft:diamond_axe") == 1)
    assert(robot.drop("minecraft:diamond_shovel") == 1)

    -- TODO [JM] test that you can't wrap a side if there is a peripheral (block) wrapped on that side

    teardown()
    print("test_equipment passed")
end
