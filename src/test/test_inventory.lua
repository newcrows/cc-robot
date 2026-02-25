return function(robot, meta, constants, utility)
    local before = meta.snapshot()

    utility.requireEmptyEquipSlots()
    utility.requireEmptyInventory()

    utility.requireItemCount("minecraft:diamond_pickaxe", 1)
    utility.requireItemCount("minecraft:dirt", 64)
    utility.requireItemCount("minecraft:coal_block", 32)

    local after = meta.snapshot()
    local diff = meta.diff(before, after)

    for name, delta in pairs(diff) do
        meta.updateItemCount(name .. "@*", delta)
    end

    robot.select("@*")
    local a, b = meta.parseQuery("item")
    assert(a == "item" and b == "*")

    a, b = meta.parseQuery("item@inv")
    assert(a == "item" and b == "inv")

    robot.select("item")
    a, b = meta.parseQuery("@*")
    assert(a == "item" and b == "*")

    local ok = pcall(meta.requireItemCount, "minecraft:coal_block")
    assert(not ok)

    robot.select("@items")
    meta.requireItemCount("minecraft:coal_block", 42)
    meta.requireItemSpace("ccrobot:unknown_item", 16)

    assert(not meta.selectFirstSlot("minecraft:coal_block"))

    meta.requireItemCount("minecraft:coal_block", 1)

    assert(meta.selectFirstSlot("minecraft:coal_block"))
    local sel = nativeTurtle.getSelectedSlot()
    local det = nativeTurtle.getItemDetail(sel)
    assert(det and det.name == "minecraft:coal_block")

    meta.requireItemCount("minecraft:coal_block", 65)
    local k, cnt = meta.selectFirstSlot("minecraft:coal_block")
    sel = nativeTurtle.getSelectedSlot()
    det = nativeTurtle.getItemDetail(sel)
    assert(det and det.name == "minecraft:coal_block" and det.count == cnt)

    local kk, spc = meta.selectFirstEmptySlot("minecraft:coal_block")
    sel = nativeTurtle.getSelectedSlot()
    assert(nativeTurtle.getItemSpace(sel) == spc)

    robot.select("some@some")
    assert(robot.getSelectedQuery() == "some@some")

    robot.select("minecraft:coal_block@items")
    det = robot.getItemDetail()
    assert(det and det.count == 65)
    assert(robot.getItemCount() == 65)
    assert(robot.getItemSpace() == 959)
    assert(#robot.listItems() == 1)

    print("test_inventory passed")
end
