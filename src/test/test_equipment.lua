return function(robot, meta, constants, utility)
    local before = meta.snapshot()

    utility.requireEmptyEquipSlots()
    utility.requireEmptyInventory()
    utility.requireItemCount("minecraft:diamond_pickaxe", 1)

    local after = meta.snapshot()
    local diff = meta.diff(before, after)

    for name, delta in pairs(diff) do
        meta.updateItemCount(name .. "@*", delta)
    end

    assert(robot.getItemCount("minecraft:diamond_pickaxe") == 1)

    local pickaxe = robot.equip("minecraft:diamond_pickaxe")

    assert(robot.getEquipmentDetail("minecraft:diamond_pickaxe").name == "minecraft:diamond_pickaxe")
    assert(#robot.listEquipment() == 1)
    assert(robot.getItemCount("minecraft:diamond_pickaxe@items") == 0)
    assert(robot.getItemCount("minecraft:diamond_pickaxe@reserved") == 1)

    pickaxe.use()
    assert(nativeTurtle.getEquippedRight())

    pickaxe.unuse()
    assert(not nativeTurtle.getEquippedRight())

    robot.unequip("minecraft:diamond_pickaxe")

    assert(not robot.getEquipmentDetail("minecraft:diamond_pickaxe"))
    assert(#robot.listEquipment() == 0)
    assert(robot.getItemCount("minecraft:diamond_pickaxe@items") == 1)
    assert(robot.getItemCount("minecraft:diamond_pickaxe@reserved") == 0)

    print("test_equipment passed")
end
