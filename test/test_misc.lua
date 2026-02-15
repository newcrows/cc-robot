local function setup(_, utility)
    turtle.select(1)
    utility.getStackFromChest("minecraft:diamond_pickaxe")
    utility.getStackFromChest("minecraft:chest")
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

    assert(not robot.place("minecraft:chest"))
    assert(robot.placeUp("minecraft:chest"))
    assert(robot.detectUp())
    assert(robot.compareUp("minecraft:chest"))
    assert(robot.suck(1) > 0)

    local _, detail = robot.inspectUp()
    assert(detail and detail.name == "minecraft:chest")

    local pickaxe = robot.equip("minecraft:diamond_pickaxe")
    assert(pickaxe.digUp())

    -- TODO [JM] investigate possible emptySlot selection bug (it still thinks pickaxe is in inventory?)
    robot.unequip("minecraft:diamond_pickaxe")
    assert(robot.drop("minecraft:diamond_pickaxe"))

    teardown()
    print("test_misc passed")
end
