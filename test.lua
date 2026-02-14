local robot = require("robot")
local meta = robot.meta

--[[
    TEST SETUP

    fuel_level:
        > 5 and < fuelLimit - 19

    inventory:
        slot_1 = 1x diamond pickaxe
        slot_2 = 2x compass
        slot_3 = 2x chest
        slot_4 = 64x dirt
        slot_5 = 32x dirt
        slot_6 = 4x stick
        slot_7 = 1x diamond sword
        all other slots must be empty

    equipment:
        slot_right = empty
        slot_left = empty

    blocks:
        front = air
        right = air
        back = air
        left = air
        top = air
        bottom = air
        below bottom = chest with 10x diamond pickaxe and nothing else

    reboot and then run test.lua

    NOTE [JM] test order is fixed because tests have side effects
]]--

local function testSetup()
    local function assertItemsInSlot(slot, name, count)
        local detail = turtle.getItemDetail(slot)
        local msg = "need " .. tostring(count) .. " " .. name .. " in slot " .. slot

        assert(detail and detail.name == name and detail.count == count, msg)
    end

    local fuelLevel = turtle.getFuelLevel()
    local fuelLimit = turtle.getFuelLimit()
    assert(fuelLevel > 5 and fuelLevel < fuelLimit - 19)

    assertItemsInSlot(1, "minecraft:diamond_pickaxe", 1)

    assertItemsInSlot(2, "minecraft:compass", 2)

    assertItemsInSlot(3, "minecraft:chest", 2)

    assertItemsInSlot(4, "minecraft:dirt", 64)

    assertItemsInSlot(5, "minecraft:dirt", 32)

    assertItemsInSlot(6, "minecraft:stick", 4)

    assertItemsInSlot(7, "minecraft:diamond_sword", 1)

    for i = 8, 16 do
        assert(turtle.getItemCount(i) == 0, "slot " .. tostring(i) .. " must be empty")
    end

    assert(not turtle.getEquippedRight(), "must not have tool on right")
    assert(not turtle.getEquippedLeft(), "must not have tool on left")

    turtle.turnRight()
    assert(not turtle.detect(), "must not have block on right")

    turtle.turnRight()
    assert(not turtle.detect(), "must not have block on back")

    turtle.turnRight()
    assert(not turtle.detect(), "must not have block on left")

    turtle.turnRight()
    assert(not turtle.detect(), "must not have block on front")

    assert(not turtle.detectUp(), "must not have block above")
    assert(not turtle.detectDown(), "must not have block below")

    assert(turtle.down(), "move failed")

    local function saveSetup()

        local _, detail = turtle.inspectDown()
        assert(detail and detail.name == "minecraft:chest", "must have chest on the second block below")

        local chest = peripheral.wrap("bottom")
        local chestItems = chest.list()
        local chestItemCount = 0

        for slot, item in pairs(chestItems) do
            if slot < 11 then
                assert(item.name == "minecraft:diamond_pickaxe", "chest.slot " .. tostring(slot) .. "must contain pickaxe")
                chestItemCount = chestItemCount + 1
            else
                error("chest.slot " .. tostring(slot) .. " must be empty")
            end
        end

        assert(chestItemCount == 10, "chest must contain exactly 10 pickaxes")
    end

    local ok, err = pcall(saveSetup)

    assert(turtle.up(), "move failed")

    if not ok then
        error(err)
    end

    print("testSetup passed")
end

local function testInsertEventListener()
    local listener = {}
    local id = robot.addEventListener(listener)

    assert(meta.eventListeners[id] == listener)

    print("testInsertEventListener passed")
end

local function testRemoveEventListener()
    local listener = {}
    local id = robot.addEventListener(listener)

    robot.removeEventListener(id)
    assert(meta.eventListeners[id] == nil)

    print("testRemoveEventListener passed")
end

local function testListEventListeners()
    assert(#robot.listEventListeners() == 1)

    local listener = {}
    local id = robot.addEventListener(listener)

    assert(#robot.listEventListeners() == 2)

    robot.removeEventListener(id)
    assert(#robot.listEventListeners() == 1)

    print("testListEventListeners passed")
end

local function testInsertPeripheralConstructor()
    local constructor = function(opts)
        return opts.target
    end

    robot.setPeripheralConstructor("test:peripheral", constructor)

    assert(meta.peripheralConstructors["test:peripheral"] == constructor)

    print("testInsertPeripheralConstructor passed")
end

local function testRemovePeripheralConstructor()
    local constructor = function(opts)
        return opts.target
    end

    robot.setPeripheralConstructor("test:peripheral", constructor)
    assert(meta.peripheralConstructors["test:peripheral"] == constructor)

    robot.removePeripheralConstructor("test:peripheral")
    assert(meta.peripheralConstructors["test:peripheral"] == nil)

    print("testRemovePeripheralConstructor passed")
end

local function testListPeripheralConstructors()
    assert(#robot.listPeripheralConstructors() == 6)

    local constructor = function(opts)
        return opts.target
    end

    robot.setPeripheralConstructor("test:peripheral_2", constructor)

    assert(#robot.listPeripheralConstructors() == 7)

    print("testListPeripheralConstructors passed")
end

local function testWrap()
    local function placeChest()
        turtle.select(3)
        turtle.place()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    placeChest()

    local custom = {}
    local constructor = function()
        return custom
    end

    robot.setPeripheralConstructor("test:wrap", constructor)

    local wrapped = assert(robot.wrap())
    assert(wrapped)

    wrapped = assert(robot.wrap("front"))
    assert(wrapped)

    wrapped = robot.wrap("test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    wrapped = robot.wrap(nil, "test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    wrapped = robot.wrap("front", "test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    turtle.turnRight()

    local ok, _ = pcall(robot.wrap, "left")
    assert(not ok)

    wrapped = robot.wrap("left", "test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    turtle.turnRight()

    local ok, _ = pcall(robot.wrap, "back")
    assert(not ok)

    wrapped = robot.wrap("back", "test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    turtle.turnRight()

    ok, _ = pcall(robot.wrap, "right")
    assert(not ok)

    wrapped = robot.wrap("right", "test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    turtle.turnRight()

    digChest()

    print("testWrap passed")
end

local function testWrapUp()
    local function placeChest()
        turtle.select(3)
        turtle.placeUp()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digUp()
        turtle.select(1)
        turtle.equipRight()
    end

    placeChest()

    local custom = {}
    local constructor = function()
        return custom
    end

    robot.setPeripheralConstructor("test:wrap", constructor)

    local wrapped = assert(robot.wrapUp())
    assert(wrapped)

    wrapped = assert(robot.wrapUp())
    assert(wrapped)

    wrapped = robot.wrapUp("test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    digChest()

    print("testWrapUp passed")
end

local function testWrapDown()
    local function placeChest()
        turtle.select(3)
        turtle.placeDown()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digDown()
        turtle.select(1)
        turtle.equipRight()
    end

    placeChest()

    local custom = {}
    local constructor = function()
        return custom
    end

    robot.setPeripheralConstructor("test:wrap", constructor)

    local wrapped = assert(robot.wrapDown())
    assert(wrapped)

    wrapped = assert(robot.wrapDown())
    assert(wrapped)

    wrapped = robot.wrapDown("test:wrap")
    assert(wrapped.target == custom and wrapped.target)

    digChest()

    print("testWrapDown passed")
end

local function testForward()
    assert(robot.forward())
    assert(robot.z == -1)

    print("testForward passed")
end

local function testBack()
    assert(robot.back())
    assert(robot.z == 0)

    print("testBack passed")
end

local function testUp()
    assert(robot.up())
    assert(robot.y == 1)

    print("testUp passed")
end

local function testDown()
    assert(robot.down())
    assert(robot.y == 0)

    print("testDown passed")
end

local function testTurnLeft()
    assert(robot.turnLeft())
    assert(robot.facing == "west")

    assert(robot.turnLeft())
    assert(robot.facing == "south")

    assert(robot.turnLeft())
    assert(robot.facing == "east")

    assert(robot.turnLeft())
    assert(robot.facing == "north")

    print("testTurnLeft passed")
end

local function testTurnRight()
    assert(robot.turnRight())
    assert(robot.facing == "east")

    assert(robot.turnRight())
    assert(robot.facing == "south")

    assert(robot.turnRight())
    assert(robot.facing == "west")

    assert(robot.turnRight())
    assert(robot.facing == "north")

    print("testTurnRight passed")
end

local function testPlace()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    robot.select("minecraft:chest")
    assert(robot.place())

    local ok, detail = turtle.inspect()
    assert(ok and detail.name == "minecraft:chest")

    digChest()

    robot.select("air")
    assert(robot.place("minecraft:chest"))

    ok, detail = turtle.inspect()
    assert(ok and detail.name == "minecraft:chest")

    digChest()

    robot.select("test:place")
    assert(not robot.place())
    assert(not turtle.detect())

    robot.select("air")
    assert(not robot.place("test:place"))
    assert(not turtle.detect())

    print("testPlace passed")
end

local function testPlaceUp()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digUp()
        turtle.select(1)
        turtle.equipRight()
    end

    robot.select("minecraft:chest")
    assert(robot.placeUp())

    local ok, detail = turtle.inspectUp()
    assert(ok and detail.name == "minecraft:chest")

    digChest()

    robot.select("air")
    assert(robot.placeUp("minecraft:chest"))

    ok, detail = turtle.inspectUp()
    assert(ok and detail.name == "minecraft:chest")

    digChest()

    robot.select("test:place")
    assert(not robot.placeUp())
    assert(not turtle.detectUp())

    robot.select("air")
    assert(not robot.placeUp("test:place"))
    assert(not turtle.detectUp())

    print("testPlaceUp passed")
end

local function testPlaceDown()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digDown()
        turtle.select(1)
        turtle.equipRight()
    end

    robot.select("minecraft:chest")
    assert(robot.placeDown())

    local ok, detail = turtle.inspectDown()
    assert(ok and detail.name == "minecraft:chest")

    digChest()

    robot.select("air")
    assert(robot.placeDown("minecraft:chest"))

    ok, detail = turtle.inspectDown()
    assert(ok and detail.name == "minecraft:chest")

    digChest()

    robot.select("test:place")
    assert(not robot.placeDown())
    assert(not turtle.detectDown())

    robot.select("air")
    assert(not robot.placeDown("test:place"))
    assert(not turtle.detectDown())

    print("testPlaceDown passed")
end

local function testDrop()
    local function placeChest()
        turtle.select(3)
        turtle.place()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    local function countDirt()
        local count4 = turtle.getItemCount(4)
        local count5 = turtle.getItemCount(5)
        local count8 = turtle.getItemCount(8)

        return count4 + count5 + count8
    end

    placeChest()

    robot.select("minecraft:dirt")

    assert(robot.drop(0) == 0)
    assert(robot.drop(-1) == 0)

    assert(robot.drop(1) == 1)
    assert(countDirt() == 64 + 32 - 1)
    turtle.suck(64)

    assert(robot.drop(64) == 64)
    assert(countDirt() == 64 + 32 - 64)
    turtle.suck(64)

    assert(robot.drop(64 + 1) == 65)
    assert(countDirt() == 64 + 32 - 65)
    turtle.suck(64)
    turtle.suck(1)

    turtle.select(5)
    turtle.transferTo(4, 32)

    turtle.select(8)
    turtle.transferTo(4, 32)

    robot.select("air")

    assert(robot.drop("minecraft:dirt", 0) == 0)
    assert(robot.drop("minecraft:dirt", -1) == 0)

    assert(robot.drop("minecraft:dirt", 1) == 1)
    assert(countDirt() == 64 + 32 - 1)
    turtle.suck(64)

    assert(robot.drop("minecraft:dirt", 64) == 64)
    assert(countDirt() == 64 + 32 - 64)
    turtle.suck(64)

    assert(robot.drop("minecraft:dirt", 64 + 1) == 65)
    assert(countDirt() == 64 + 32 - 65)
    turtle.suck(64)
    turtle.suck(1)

    turtle.select(5)
    turtle.transferTo(4, 32)

    turtle.select(8)
    turtle.transferTo(4, 32)

    robot.select("test:drop")
    assert(robot.drop() == 0)

    robot.select("air")
    assert(robot.drop("test:drop") == 0)

    digChest()

    print("testDrop passed")
end

local function testDropUp()
    local function placeChest()
        turtle.select(3)
        turtle.placeUp()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digUp()
        turtle.select(1)
        turtle.equipRight()
    end

    local function countDirt()
        local count4 = turtle.getItemCount(4)
        local count5 = turtle.getItemCount(5)
        local count8 = turtle.getItemCount(8)

        return count4 + count5 + count8
    end

    placeChest()

    robot.select("minecraft:dirt")

    assert(robot.dropUp(0) == 0)
    assert(robot.dropUp(-1) == 0)

    assert(robot.dropUp(1) == 1)
    assert(countDirt() == 64 + 32 - 1)
    turtle.suckUp(64)

    assert(robot.dropUp(64) == 64)
    assert(countDirt() == 64 + 32 - 64)
    turtle.suckUp(64)

    assert(robot.dropUp(64 + 1) == 65)
    assert(countDirt() == 64 + 32 - 65)
    turtle.suckUp(64)
    turtle.suckUp(1)

    turtle.select(5)
    turtle.transferTo(4, 32)

    turtle.select(8)
    turtle.transferTo(4, 32)

    robot.select("air")

    assert(robot.dropUp("minecraft:dirt", 0) == 0)
    assert(robot.dropUp("minecraft:dirt", -1) == 0)

    assert(robot.dropUp("minecraft:dirt", 1) == 1)
    assert(countDirt() == 64 + 32 - 1)
    turtle.suckUp(64)

    assert(robot.dropUp("minecraft:dirt", 64) == 64)
    assert(countDirt() == 64 + 32 - 64)
    turtle.suckUp(64)

    assert(robot.dropUp("minecraft:dirt", 64 + 1) == 65)
    assert(countDirt() == 64 + 32 - 65)
    turtle.suckUp(64)
    turtle.suckUp(1)

    turtle.select(5)
    turtle.transferTo(4, 32)

    turtle.select(8)
    turtle.transferTo(4, 32)

    robot.select("test:drop")
    assert(robot.dropUp() == 0)

    robot.select("air")
    assert(robot.dropUp("test:drop") == 0)

    digChest()

    print("testDropUp passed")
end

local function testDropDown()
    local function placeChest()
        turtle.select(3)
        turtle.placeDown()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digDown()
        turtle.select(1)
        turtle.equipRight()
    end

    local function countDirt()
        local count4 = turtle.getItemCount(4)
        local count5 = turtle.getItemCount(5)
        local count8 = turtle.getItemCount(8)

        return count4 + count5 + count8
    end

    placeChest()

    robot.select("minecraft:dirt")

    assert(robot.dropDown(0) == 0)
    assert(robot.dropDown(-1) == 0)

    assert(robot.dropDown(1) == 1)
    assert(countDirt() == 64 + 32 - 1)
    turtle.suckDown(64)

    assert(robot.dropDown(64) == 64)
    assert(countDirt() == 64 + 32 - 64)
    turtle.suckDown(64)

    assert(robot.dropDown(64 + 1) == 65)
    assert(countDirt() == 64 + 32 - 65)
    turtle.suckDown(64)
    turtle.suckDown(1)

    turtle.select(5)
    turtle.transferTo(4, 32)

    turtle.select(8)
    turtle.transferTo(4, 32)

    robot.select("air")

    assert(robot.dropDown("minecraft:dirt", 0) == 0)
    assert(robot.dropDown("minecraft:dirt", -1) == 0)

    assert(robot.dropDown("minecraft:dirt", 1) == 1)
    assert(countDirt() == 64 + 32 - 1)
    turtle.suckDown(64)

    assert(robot.dropDown("minecraft:dirt", 64) == 64)
    assert(countDirt() == 64 + 32 - 64)
    turtle.suckDown(64)

    assert(robot.dropDown("minecraft:dirt", 64 + 1) == 65)
    assert(countDirt() == 64 + 32 - 65)
    turtle.suckDown(64)
    turtle.suckDown(1)

    turtle.select(5)
    turtle.transferTo(4, 32)

    turtle.select(8)
    turtle.transferTo(4, 32)

    robot.select("test:drop")
    assert(robot.dropDown() == 0)

    robot.select("air")
    assert(robot.dropDown("test:drop") == 0)

    digChest()

    print("testDropDown passed")
end

local function testSelect()
    robot.select("test:select")
    assert(meta.selectedName == "test:select")

    local ok, _ = pcall(robot.select)
    assert(not ok)

    print("testSelect passed")
end

local function testGetItemCount()
    robot.select("minecraft:dirt")
    assert(robot.getItemCount() == 64 + 32)

    robot.select("air")
    assert(robot.getItemCount("minecraft:dirt") == 64 + 32)

    robot.select("test:getItemCount")
    assert(robot.getItemCount() == 0)

    print("testGetItemCount passed")
end

local function testGetItemSpace()
    robot.select("minecraft:dirt")
    assert(robot.getItemSpace() == 11 * 64 - (64 + 32))
    assert(robot.getItemSpace(1) == -32)
    assert(robot.getItemSpace(2) == 32)

    robot.select("air")
    assert(robot.getItemSpace("minecraft:dirt") == 11 * 64 - (64 + 32))
    assert(robot.getItemSpace("minecraft:dirt", 1) == -32)
    assert(robot.getItemSpace("minecraft:dirt", 2) == 32)

    robot.select("test:getItemSpace")
    assert(robot.getItemSpace() == 9 * 64)

    turtle.select(5)
    for i = 7, 16 do
        turtle.transferTo(i, 1)
    end

    robot.select("test:getItemSpace")
    assert(robot.getItemSpace() == 9 * 64)

    print("testGetItemSpace passed")
end

local function testGetItemSpaceForUnknown()
    assert(robot.getItemSpaceForUnknown() == 9)

    turtle.select(5)
    for i = 7, 16 do
        turtle.transferTo(i, 1)
    end

    assert(robot.getItemSpaceForUnknown() == 9)

    print("testGetItemSpaceForUnknown passed")
end

local function testHasItemCount()
    robot.select("minecraft:dirt")
    assert(robot.hasItemCount())

    robot.select("air")
    assert(robot.hasItemCount("minecraft:dirt"))

    robot.select("test:hasItemCount")
    assert(not robot.hasItemCount())

    robot.select("air")
    assert(not robot.hasItemCount("test:hasItemCount"))

    print("testHasItemCount passed")
end

local function testHasItemSpace()
    robot.select("minecraft:dirt")
    assert(robot.hasItemSpace())
    assert(not robot.hasItemSpace(1))
    assert(robot.hasItemSpace(2))

    robot.select("air")
    assert(robot.hasItemSpace("minecraft:dirt"))
    assert(not robot.hasItemSpace("minecraft:dirt", 1))
    assert(robot.hasItemSpace("minecraft:dirt", 2))

    robot.select("test:hasItemSpace")
    assert(robot.hasItemSpace())

    robot.select("air")
    assert(robot.hasItemSpace("test:hasItemSpace"))

    turtle.down()
    for i = 8, 16 do
        turtle.suckDown(1)
    end

    robot.select("test:hasItemSpace")
    assert(not robot.hasItemSpace())

    robot.select("air")
    assert(not robot.hasItemSpace("test:hasItemSpace"))

    for i = 8, 16 do
        turtle.select(i)
        turtle.dropDown(1)
    end
    turtle.up()

    print("testHasItemSpace passed")
end

local function testHasItemSpaceForUnknown()
    assert(robot.hasItemSpaceForUnknown())

    turtle.down()
    for i = 8, 16 do
        turtle.suckDown(1)
    end

    assert(not robot.hasItemSpaceForUnknown())

    for i = 8, 16 do
        turtle.select(i)
        turtle.dropDown(1)
    end
    turtle.up()

    print("testHasItemSpaceForUnknown passed")
end

local function testDetect()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    assert(not robot.detect())

    turtle.select(3)
    turtle.place()

    assert(robot.detect())

    digChest()

    print("testDetect passed")
end

local function testDetectUp()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digUp()
        turtle.select(1)
        turtle.equipRight()
    end

    assert(not robot.detectUp())

    turtle.select(3)
    turtle.placeUp()

    assert(robot.detectUp())

    digChest()

    print("testDetectUp passed")
end

local function testDetectDown()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digDown()
        turtle.select(1)
        turtle.equipRight()
    end

    assert(not robot.detectDown())

    turtle.select(3)
    turtle.placeDown()

    assert(robot.detectDown())

    digChest()

    print("testDetectDown passed")
end

local function testCompare()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    robot.select("minecraft:chest")
    assert(not robot.compare())

    robot.select("air")
    assert(robot.compare())
    assert(not robot.compare("minecraft:chest"))

    turtle.select(3)
    turtle.place()

    robot.select("minecraft:chest")
    assert(robot.compare())
    assert(not robot.compare("air"))

    robot.select("air")
    assert(robot.compare("minecraft:chest"))

    digChest()

    print("testCompare passed")
end

local function testCompareUp()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digUp()
        turtle.select(1)
        turtle.equipRight()
    end

    robot.select("minecraft:chest")
    assert(not robot.compareUp())

    robot.select("air")
    assert(robot.compareUp())
    assert(not robot.compareUp("minecraft:chest"))

    turtle.select(3)
    turtle.placeUp()

    robot.select("minecraft:chest")
    assert(robot.compareUp())
    assert(not robot.compareUp("air"))

    robot.select("air")
    assert(robot.compareUp("minecraft:chest"))

    digChest()

    print("testCompareUp passed")
end

local function testCompareDown()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digDown()
        turtle.select(1)
        turtle.equipRight()
    end

    robot.select("minecraft:chest")
    assert(not robot.compareDown())

    robot.select("air")
    assert(robot.compareDown())
    assert(not robot.compareDown("minecraft:chest"))

    turtle.select(3)
    turtle.placeDown()

    robot.select("minecraft:chest")
    assert(robot.compareDown())
    assert(not robot.compareDown("air"))

    robot.select("air")
    assert(robot.compareDown("minecraft:chest"))

    digChest()

    print("testCompareDown passed")
end

local function testSuck()
    local function placeChest()
        turtle.select(3)
        turtle.place()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    placeChest()

    turtle.select(1)
    turtle.drop()

    turtle.select(4)
    turtle.drop(64)

    turtle.select(5)
    turtle.drop(32)

    turtle.select(1)

    assert(robot.suck() == 97)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 64)
    assert(turtle.getItemCount(5) == 32)

    turtle.select(1)
    turtle.drop()

    turtle.select(4)
    turtle.drop(64)

    turtle.select(5)
    turtle.drop(32)

    turtle.select(1)

    assert(robot.suck(2) == 2)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 1)

    assert(robot.suck(-1) == 0)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 1)

    digChest()

    print("testSuck passed")
end

local function testSuckUp()
    local function placeChest()
        turtle.select(3)
        turtle.placeUp()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digUp()
        turtle.select(1)
        turtle.equipRight()
    end

    placeChest()

    turtle.select(1)
    turtle.dropUp()

    turtle.select(4)
    turtle.dropUp(64)

    turtle.select(5)
    turtle.dropUp(32)

    turtle.select(1)

    assert(robot.suckUp() == 97)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 64)
    assert(turtle.getItemCount(5) == 32)

    turtle.select(1)
    turtle.dropUp()

    turtle.select(4)
    turtle.dropUp(64)

    turtle.select(5)
    turtle.dropUp(32)

    turtle.select(1)

    assert(robot.suckUp(2) == 2)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 1)

    assert(robot.suckUp(-1) == 0)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 1)

    digChest()

    print("testSuckUp passed")
end

local function testSuckDown()
    local function placeChest()
        turtle.select(3)
        turtle.placeDown()
    end

    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digDown()
        turtle.select(1)
        turtle.equipRight()
    end

    placeChest()

    turtle.select(1)
    turtle.dropDown()

    turtle.select(4)
    turtle.dropDown(64)

    turtle.select(5)
    turtle.dropDown(32)

    turtle.select(1)

    assert(robot.suckDown() == 97)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 64)
    assert(turtle.getItemCount(5) == 32)

    turtle.select(1)
    turtle.dropDown()

    turtle.select(4)
    turtle.dropDown(64)

    turtle.select(5)
    turtle.dropDown(32)

    turtle.select(1)

    assert(robot.suckDown(2) == 2)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 1)

    assert(robot.suckDown(-1) == 0)
    assert(turtle.getItemCount(1) == 1)
    assert(turtle.getItemCount(4) == 1)

    digChest()

    print("testSuckDown passed")
end

local function testGetFuelLevel()
    assert(turtle.getFuelLevel() == robot.getFuelLevel())
    print("testGetFuelLevel passed")
end

local function testRefuel()
    local before = turtle.getFuelLevel()

    robot.select("minecraft:stick")
    assert(robot.refuel(1) == 1)
    assert(turtle.getFuelLevel() == before + 5)

    robot.select("air")
    assert(robot.refuel("minecraft:stick", 1) == 1)
    assert(turtle.getFuelLevel() == before + 10)

    assert(robot.refuel("minecraft:stick") == 2)
    assert(turtle.getFuelLevel() == before + 20)

    assert(robot.refuel("test:refuel") == 0)
    assert(turtle.getFuelLevel() == before + 20)

    for i = 1, 10 do
        turtle.up()
        turtle.down()
    end

    print("testRefuel passed")
end

local function testGetSelectedName()
    robot.select("test:getSelectedName")
    assert(meta.selectedName == "test:getSelectedName")

    local ok = pcall(robot.select)
    assert(not ok)

    print("testGetSelectedName passed")
end

local function testGetFuelLimit()
    assert(turtle.getFuelLimit() == robot.getFuelLimit())
    print("testGetFuelLimit passed")
end

local function testEquip()
    robot.select("minecraft:diamond_pickaxe")
    local pickaxe = robot.equip()
    assert(meta.equipProxies["minecraft:diamond_pickaxe"])

    robot.select("air")
    local pickaxeAgain = robot.equip("minecraft:diamond_pickaxe")
    assert(pickaxe == pickaxeAgain)

    local detail = turtle.getItemDetail(1)
    assert(detail and detail.name == "minecraft:diamond_pickaxe")

    robot.equip("minecraft:diamond_pickaxe", true)
    detail = turtle.getItemDetail(1)
    local equipRight = turtle.getEquippedRight()
    assert(not detail and equipRight and equipRight.name == "minecraft:diamond_pickaxe")

    assert(not pickaxe.unuse())

    assert(pickaxe.unpin())
    assert(pickaxe.unuse())

    detail = turtle.getItemDetail(1)
    assert(detail and detail.name == "minecraft:diamond_pickaxe")

    local compass = robot.equip("minecraft:compass")
    assert(meta.equipProxies["minecraft:compass"])

    assert(compass.use())
    equipRight = turtle.getEquippedRight()
    assert(equipRight and equipRight.name == "minecraft:compass")

    assert(pickaxe.use())
    local equipLeft = turtle.getEquippedLeft()
    assert(equipLeft and equipLeft.name == "minecraft:diamond_pickaxe")

    local sword = robot.equip("minecraft:diamond_sword")
    assert(meta.equipProxies["minecraft:diamond_sword"])

    local ok = pcall(sword.attack)
    equipRight = turtle.getEquippedRight()
    assert(ok)
    assert(equipRight and equipRight.name == "minecraft:diamond_sword")

    assert(pickaxe.pin())
    assert(sword.pin())
    assert(not compass.use())

    assert(pickaxe.unpin())
    assert(compass.use())

    equipLeft = turtle.getEquippedLeft()
    assert(equipLeft and equipLeft.name == "minecraft:compass")

    assert(sword.unpin())

    turtle.down()

    turtle.select(6)
    turtle.suckDown()

    for i = 8, 16 do
        turtle.select(i)
        turtle.suckDown()
    end

    meta.equipProxies["minecraft:diamond_pickaxe"] = nil

    assert(sword.unuse())
    detail = turtle.getItemDetail(1)
    assert(detail and detail.name == "minecraft:diamond_sword")

    meta.equipProxies["minecraft:diamond_sword"] = nil

    assert(not compass.unuse())
    assert(turtle.getItemCount(7) == 1)

    turtle.select(6)
    turtle.dropDown()

    for i = 8, 16 do
        turtle.select(i)
        turtle.dropDown()
    end

    turtle.up()

    turtle.down()

    turtle.select(6)
    turtle.suckDown()

    for i = 8, 16 do
        turtle.select(i)
        turtle.suckDown()
    end

    turtle.select(1)
    turtle.equipRight()

    sword = robot.equip("minecraft:diamond_sword")
    assert(sword)

    compass = robot.equip("minecraft:compass")
    assert(compass)

    assert(compass.unuse())
    detail = turtle.getItemDetail(1)
    assert(detail and detail.name == "minecraft:compass")

    meta.equipProxies["minecraft:compass"] = nil

    assert(sword.unuse())

    turtle.select(6)
    turtle.dropDown()

    for i = 8, 16 do
        turtle.select(i)
        turtle.dropDown()
    end

    turtle.up()

    turtle.select(1)
    turtle.transferTo(8)

    turtle.select(2)
    turtle.transferTo(1)

    turtle.select(8)
    turtle.transferTo(2)

    meta.equipProxies = {}

    print("testEquip passed")
end

local function testUnequip()
    assert(robot.equip("minecraft:diamond_pickaxe"))
    assert(not turtle.getEquippedRight())

    assert(robot.equip("minecraft:compass", true))
    local equipRight = turtle.getEquippedRight()
    assert(equipRight and equipRight.name == "minecraft:compass")

    assert(robot.unequip("minecraft:diamond_pickaxe"))
    assert(meta.equipProxies["minecraft:diamond_pickaxe"] == nil)

    assert(robot.unequip("minecraft:compass"))
    assert(not turtle.getEquippedLeft())
    assert(meta.equipProxies["minecraft:compass"] == nil)

    turtle.select(6)
    turtle.transferTo(2)

    print("testUnequip passed")
end

local function testInspect()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    turtle.select(3)
    turtle.place()

    local _, tDetail = turtle.inspect()
    local _, rDetail = robot.inspect()

    assert(tDetail.name == rDetail.name)

    digChest()

    print("testInspect passed")
end

local function testInspectUp()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digUp()
        turtle.select(1)
        turtle.equipRight()
    end

    turtle.select(3)
    turtle.placeUp()

    local _, tDetail = turtle.inspectUp()
    local _, rDetail = robot.inspectUp()

    assert(tDetail.name == rDetail.name)

    digChest()

    print("testInspectUp passed")
end

local function testInspectDown()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.digDown()
        turtle.select(1)
        turtle.equipRight()
    end

    turtle.select(3)
    turtle.placeDown()

    local _, tDetail = turtle.inspectDown()
    local _, rDetail = robot.inspectDown()

    assert(tDetail.name == rDetail.name)

    digChest()

    print("testInspectDown passed")
end

local function testGetItemDetail()
    local detail = robot.getItemDetail("minecraft:dirt")

    assert(detail and detail.name == "minecraft:dirt" and detail.count == 64 + 32)

    robot.select("test:getItemDetail")
    detail = robot.getItemDetail()
    assert(not detail)

    meta.selectedName = nil
    local ok = pcall(robot.getItemDetail)
    assert(not ok)

    print("testGetItemDetail passed")
end

local function testListItems()
    local function assertItem(item, name, count)
        if item.name == name then
            assert(item.count == count)
        end
    end

    local items = robot.listItems()
    assert(#items == 5)

    for _, item in ipairs(items) do
        assertItem(item, "minecraft:diamond_pickaxe", 1)
        assertItem(item, "minecraft:compass", 2)
        assertItem(item, "minecraft:chest", 2)
        assertItem(item, "minecraft:dirt", 64 + 32)
        assertItem(item, "minecraft:sword", 1)
    end

    print("testListItems passed")
end

local function testMetaWrap()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    turtle.select(3)
    turtle.place()

    local name, side, isEquipment
    local id = robot.addEventListener({
        wrap = function(_name, _side, _isEquipment)
            name = _name
            side = _side
            isEquipment = _isEquipment
        end
    })

    -- NOTE [JM] the CC:Tweaked has a bug here:
    -- you can't peripheral.wrap() in the same tick as you turtle.place()'d
    -- so we yield via sleep
    sleep(0.1)
    local chest = meta.wrap("minecraft:chest", "front")

    assert(chest)
    assert(meta.wrapProxies["front"] and meta.wrapProxies["front"].name == "minecraft:chest")
    assert(name == "minecraft:chest")
    assert(side == "front")
    assert(not isEquipment)

    robot.removeEventListener(id)

    digChest()

    print("testMetaWrap passed")
end

local function testMetaUnwrap()
    local function digChest()
        turtle.select(1)
        turtle.equipRight()
        turtle.select(3)
        turtle.dig()
        turtle.select(1)
        turtle.equipRight()
    end

    turtle.select(3)
    turtle.place()

    local name, side, wasEquipment
    local id = robot.addEventListener({
        unwrap = function(_name, _side, _wasEquipment)
            name = _name
            side = _side
            wasEquipment = _wasEquipment
        end
    })

    -- NOTE [JM] the CC:Tweaked has a bug here:
    -- you can't peripheral.wrap() in the same tick as you turtle.place()'d
    -- so we yield via sleep
    sleep(0.1)
    meta.wrap("minecraft:chest", "front")

    assert(meta.wrapProxies["front"] and meta.wrapProxies["front"].name == "minecraft:chest")
    assert(meta.unwrap("front"))
    assert(not meta.wrapProxies["front"])
    assert(name == "minecraft:chest")
    assert(side == "front")
    assert(not wasEquipment)

    robot.removeEventListener(id)

    digChest()

    print("testMetaUnwrap passed")
end

local function testMetaListSlots()
    local function assertItem(item, name, count, orCount)
        if item.name == name then
            assert(item.count == count or orCount and item.count == orCount)
        end
    end

    local slots = meta.listSlots()
    assert(#slots == 6)

    for _, item in pairs(slots) do
        assertItem(item, "minecraft:diamond_pickaxe", 1)
        assertItem(item, "minecraft:compass", 2)
        assertItem(item, "minecraft:chest", 2)
        assertItem(item, "minecraft:dirt", 64, 32)
        assertItem(item, "minecraft:sword", 1)
    end

    slots = meta.listSlots("minecraft:dirt")
    assert(#slots == 2)

    for _, item in pairs(slots) do
        assertItem(item, "minecraft:dirt", 64, 32)
    end

    slots = meta.listSlots(nil, 3)
    assert(#slots == 3)

    for _, item in pairs(slots) do
        assertItem(item, "minecraft:diamond_pickaxe", 1)
        assertItem(item, "minecraft:compass", 2)
        assertItem(item, "minecraft:chest", 2)
    end

    robot.equip("minecraft:diamond_pickaxe")

    slots = meta.listSlots()

    assert(#slots == 5)

    for _, item in pairs(slots) do
        assert(item.name ~= "minecraft:diamond_pickaxe")
        assertItem(item, "minecraft:compass", 2)
        assertItem(item, "minecraft:chest", 2)
        assertItem(item, "minecraft:dirt", 64, 32)
        assertItem(item, "minecraft:sword", 1)
    end

    slots = meta.listSlots(nil, nil, true)
    assert(#slots == 6)

    for _, item in pairs(slots) do
        assertItem(item, "minecraft:diamond_pickaxe", 1)
        assertItem(item, "minecraft:compass", 2)
        assertItem(item, "minecraft:chest", 2)
        assertItem(item, "minecraft:dirt", 64, 32)
        assertItem(item, "minecraft:sword", 1)
    end

    robot.reserveItems("minecraft:dirt", 4)

    slots = meta.listSlots("minecraft:dirt")
    assert(#slots == 2)

    for _, item in pairs(slots) do
        assertItem(item, "minecraft:dirt", 60, 32)
    end

    meta.equipProxies = {}
    meta.reservedItemCounts = {}

    print("testMetaListSlots passed")
end

local function testMetaListEmptySlots()
    local slots = meta.listEmptySlots()
    assert(#slots == 10)

    for _, slot in pairs(slots) do
        assert(slot.id > 5 and slot.id ~= 7)
        assert(not slot.name)
        assert(slot.count == 0)
    end

    slots = meta.listEmptySlots(4)
    assert(#slots == 4)

    for _, slot in pairs(slots) do
        assert(slot.id > 5 and slot.id ~= 7)
        assert(not slot.name)
        assert(slot.count == 0)
    end

    turtle.select(4)
    turtle.transferTo(6, 1)

    for i = 8, 16 do
        turtle.transferTo(i, 1)
    end

    slots = meta.listEmptySlots()
    assert(#slots == 10)

    for _, slot in pairs(slots) do
        assert(slot.id > 5 and slot.id ~= 7)
        assert(not slot.name)
        assert(slot.count == 0)
    end

    turtle.select(4)
    turtle.transferTo(6, 1)

    for i = 8, 16 do
        turtle.transferTo(i, 1)
    end

    slots = meta.listEmptySlots(16, true)
    assert(#slots == 0)

    for i = 8, 16 do
        turtle.select(i)
        turtle.transferTo(4, 1)
    end

    turtle.select(6)
    turtle.transferTo(4, 1)

    print("testMetaListEmptySlots passed")
end

local function testMetaGetFirstSlot()
    local slot = meta.getFirstSlot()
    assert(slot.id == 1 and slot.name == "minecraft:diamond_pickaxe" and slot.count == 1)

    turtle.select(1)
    turtle.transferTo(16, 1)

    slot = meta.getFirstSlot()
    assert(slot.id == 2 and slot.name == "minecraft:compass" and slot.count == 2)

    turtle.select(16)
    turtle.transferTo(1, 1)

    robot.equip("minecraft:diamond_pickaxe")

    slot = meta.getFirstSlot()
    assert(slot.id == 2 and slot.name == "minecraft:compass" and slot.count == 2)

    slot = meta.getFirstSlot(nil, true)
    assert(slot.id == 1 and slot.name == "minecraft:diamond_pickaxe" and slot.count == 1)

    meta.equipProxies = {}

    robot.reserveItems("minecraft:diamond_pickaxe", 1)
    robot.reserveItems("minecraft:compass", 1)

    slot = meta.getFirstSlot()
    assert(slot.id == 2 and slot.name == "minecraft:compass" and slot.count == 1)

    robot.reserveItems("minecraft:compass", 1)

    slot = meta.getFirstSlot()
    assert(slot.id == 3 and slot.name == "minecraft:chest" and slot.count == 2)

    meta.reservedItemCounts = {}

    print("testMetaGetFirstSlot passed")
end

local function testMetaGetFirstEmptySlot()
    local slot = meta.getFirstEmptySlot()
    assert(slot.id == 6)

    turtle.select(4)
    turtle.transferTo(6, 1)

    slot = meta.getFirstEmptySlot()
    assert(slot.id == 8)

    turtle.select(6)
    turtle.transferTo(4, 1)

    print("testMetaGetFirstEmptySlot passed")
end

local function testMetaSelectFirstSlot()
    turtle.select(16)

    meta.selectFirstSlot()
    assert(turtle.getSelectedSlot() == 1)

    turtle.select(1)
    turtle.transferTo(16, 1)

    meta.selectFirstSlot()
    assert(turtle.getSelectedSlot() == 2)

    turtle.select(16)
    turtle.transferTo(1, 1)

    robot.equip("minecraft:diamond_pickaxe")

    meta.selectFirstSlot()
    assert(turtle.getSelectedSlot() == 2)

    meta.equipProxies = {}

    robot.reserveItems("minecraft:diamond_pickaxe", 1)
    robot.reserveItems("minecraft:compass", 1)

    meta.selectFirstSlot()
    assert(turtle.getSelectedSlot() == 2)

    robot.reserveItems("minecraft:compass", 1)

    meta.selectFirstSlot()
    assert(turtle.getSelectedSlot() == 3)

    meta.reservedItemCounts = {}

    print("testMetaSelectFirstSlot passed")
end

local function testMetaSelectFirstEmptySlot()
    meta.selectFirstEmptySlot()
    assert(turtle.getSelectedSlot() == 6)

    turtle.select(4)
    turtle.transferTo(6, 1)

    meta.selectFirstEmptySlot()
    assert(turtle.getSelectedSlot() == 8)

    turtle.select(6)
    turtle.transferTo(4, 1)

    print("testMetaSelectFirstEmptySlot passed")
end

local function testMetaCountItems()
    assert(meta.countItems() == 1 + 2 + 2 + 64 + 32 + 1)
    assert(meta.countItems("minecraft:compass") == 2)

    robot.equip("minecraft:compass")
    assert(meta.countItems("minecraft:compass") == 1)
    assert(meta.countItems("minecraft:compass", true) == 2)

    meta.equipProxies = {}

    robot.reserveItems("minecraft:compass", 1)
    assert(meta.countItems("minecraft:compass") == 1)
    assert(meta.countItems("minecraft:compass", nil, true) == 2)

    meta.reservedItemCounts = {}

    print("testMetaCountItems passed")
end

local function testMetaCompact()
    turtle.select(4)
    turtle.transferTo(16, 4)

    turtle.select(5)
    turtle.transferTo(12, 4)

    meta.compact()

    assert(turtle.getItemCount(16) == 0)
    assert(turtle.getItemCount(12) == 0)
    assert(turtle.getItemCount(4) == 64)
    assert(turtle.getItemCount(5) == 32)

    print("testMetaCompact passed")
end

local function testMetaSetSlot()
    meta.setSlot(16, "minecraft:dirt", 17)
    assert(turtle.getItemCount(16) == 17)

    meta.setSlot(16, "air")
    assert(turtle.getItemCount(16) == 0)

    meta.setSlot(16, "minecraft:dirt", 17)
    meta.setSlot(16, "minecraft:dirt", 0)
    assert(turtle.getItemCount(16) == 0)

    meta.setSlot(16, "minecraft:dirt", 17, { [4] = true })
    assert(turtle.getItemCount(4) == 64)
    assert(turtle.getItemCount(5) == 15)
    assert(turtle.getItemCount(16) == 17)

    meta.setSlot(16, "minecraft:dirt", 0, { [5] = true })
    assert(turtle.getItemCount(16) == 0)

    turtle.select(6)
    turtle.transferTo(5)

    meta.setSlot(1, "minecraft:dirt", 5)
    assert(turtle.getItemCount(4) == 59)
    assert(turtle.getItemCount(6) == 1)

    meta.setSlot(1, "minecraft:diamond_pickaxe")

    print("testMetaSetSlot passed")
end

local function testMetaMarkItemsVisible()
    meta.reservedItemCounts["minecraft:dirt"] = 100

    robot.freeItems("minecraft:dirt", 10)
    assert(meta.reservedItemCounts["minecraft:dirt"] == 90)

    meta.reservedItemCounts = {}

    print("testMetaMarkItemsVisible passed")
end

local function testMetaMarkItemsHidden()
    robot.reserveItems("minecraft:dirt", 10)
    assert(meta.reservedItemCounts["minecraft:dirt"] == 10)

    robot.reserveItems("minecraft:dirt", 10)
    assert(meta.reservedItemCounts["minecraft:dirt"] == 20)

    meta.reservedItemCounts = {}

    print("testMetaMarkItemsHidden passed")
end

local function testMetaDispatchEvent()
    local customArg

    robot.addEventListener({
        customEvent = function(_customArg)
            customArg = _customArg
        end
    })

    meta.dispatchEvent("customEvent", "hello, world!")
    assert(customArg == "hello, world!")

    robot.eventListeners = {}

    print("testMetaDispatchEvent passed")
end

local function testEvent_softWrap_softUnwrap()
    local didSoftWrap = false
    local didSoftUnwrap = false

    robot.addEventListener({
        softWrap = function(name, side)
            assert(name == "minecraft:chest")
            assert(side == "front")

            didSoftWrap = true
        end,
        softUnwrap = function(name, side)
            assert(name == "minecraft:chest")
            assert(side == "front")

            didSoftUnwrap = true
        end
    })

    turtle.select(3)
    turtle.place()

    os.sleep(0.1)
    local chest = robot.wrap()

    assert(#chest.list() == 0)

    robot.forward()

    assert(didSoftUnwrap)
    assert(didSoftWrap)
    assert(#chest.list() == 0)

    didSoftWrap = false
    didSoftUnwrap = false

    turtle.select(1)
    turtle.equipRight()
    turtle.select(3)
    turtle.dig()
    turtle.select(1)
    turtle.equipRight()

    robot.forward()

    assert(not didSoftWrap)
    assert(didSoftUnwrap)

    didSoftWrap = false
    didSoftUnwrap = false

    robot.back()
    robot.eventListeners = {}

    assert(not didSoftWrap)
    assert(not didSoftUnwrap)
    assert(not pcall(chest.list))

    print("testEvent_softWrap_softUnwrap passed")
end

local function testEvent_wrap_unwrap()
    local didWrap = false
    local didUnwrap = false

    robot.addEventListener({
        wrap = function(name, side, isEquipment)
            assert(name == "minecraft:chest")
            assert(side == "front")
            assert(not isEquipment)
            didWrap = true
        end,
        unwrap = function(name, side, wasEquipment)
            assert(name == "minecraft:chest")
            assert(side == "front")
            assert(not wasEquipment)
            didUnwrap = true
        end
    })

    turtle.select(3)
    turtle.place()

    os.sleep(0.1)
    local chest = robot.wrap()

    assert(didWrap)
    assert(#chest.list() == 0)

    robot.forward()

    assert(not didUnwrap)
    assert(#chest.list() == 0)

    turtle.select(1)
    turtle.equipRight()
    turtle.select(3)
    turtle.dig()
    turtle.select(1)
    turtle.equipRight()

    robot.forward()

    assert(didUnwrap)
    assert(not pcall(chest.list))

    robot.back()
    robot.eventListeners = {}

    print("testEvent_wrap_unwrap passed")
end

local function testEvent_equip_unequip()
    local didEquip = false
    local didUnequip = false

    robot.addEventListener({
        equip = function(name, isPinned)
            assert(name == "minecraft:diamond_pickaxe")
            assert(not isPinned)
            didEquip = true
        end,
        unequip = function(name, wasPinned)
            assert(name == "minecraft:diamond_pickaxe")
            assert(not wasPinned)
            didUnequip = true
        end
    })

    robot.equip("minecraft:diamond_pickaxe")
    assert(didEquip)

    robot.unequip("minecraft:diamond_pickaxe")
    assert(didUnequip)

    meta.eventListeners = {}

    print("testEvent_equip_unequip passed")
end

testSetup()
testInsertEventListener()
testRemoveEventListener()
testListEventListeners()
testInsertPeripheralConstructor()
testRemovePeripheralConstructor()
testListPeripheralConstructors()
testWrap()
testWrapUp()
testWrapDown()
testForward()
testBack()
testUp()
testDown()
testTurnLeft()
testTurnRight()
testPlace()
testPlaceUp()
testPlaceDown()
testDrop()
testDropUp()
testDropDown()
testSelect()
testGetItemCount()
testGetItemSpace()
testGetItemSpaceForUnknown()
testHasItemCount()
testHasItemSpace()
testHasItemSpaceForUnknown()
testDetect()
testDetectUp()
testDetectDown()
testCompare()
testCompareUp()
testCompareDown()
testSuck()
testSuckUp()
testSuckDown()
testGetFuelLevel()
testRefuel()
testGetSelectedName()
testGetFuelLimit()
testEquip()
testUnequip()
testInspect()
testInspectUp()
testInspectDown()
testGetItemDetail()
testListItems()
testMetaWrap()
testMetaUnwrap()
testMetaListSlots()
testMetaListEmptySlots()
testMetaGetFirstSlot()
testMetaGetFirstEmptySlot()
testMetaSelectFirstSlot()
testMetaSelectFirstEmptySlot()
testMetaCountItems()
testMetaCompact()
testMetaSetSlot()
testMetaMarkItemsVisible()
testMetaMarkItemsHidden()
testMetaDispatchEvent()
testEvent_softWrap_softUnwrap()
testEvent_wrap_unwrap()
testEvent_equip_unequip()
