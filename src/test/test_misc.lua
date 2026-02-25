return function(robot, meta, constants, utility)
    local before = meta.snapshot()

    --utility.requireEmptyEquipSlots()
    --utility.requireEmptyInventory()
    utility.requireItemCount("minecraft:diamond_pickaxe", 1)
    utility.requireItemCount("minecraft:dirt", 64)

    local after = meta.snapshot()
    local diff = meta.diff(before, after)

    for name, delta in pairs(diff) do
        meta.updateItemCount(name .. "@*", delta)
    end

    local pickaxe = robot.equip("minecraft:diamond_pickaxe")
    pickaxe.use()

    assert(not robot.detect())
    robot.place("minecraft:dirt")
    assert(robot.detect())
    pickaxe.dig()
    assert(not robot.detect())

    robot.unequip("minecraft:diamond_pickaxe")

    robot.dropUp("minecraft:dirt", 4)
    assert(robot.getItemCount("minecraft:dirt") == 60)

    robot.suckUp("minecraft:dirt", 8, true)
    assert(robot.getItemCount("minecraft:dirt") == 68)

    print("test_misc passed")
end
