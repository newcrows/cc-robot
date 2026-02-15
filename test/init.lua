local robot = require("robot")
local files = fs.list(...)
local tests = {}

for _, file in ipairs(files) do
    if file ~= "init.lua" then
        local name = string.match(file, "(.+)%..+$")
        local test = require((...) .. "/" .. name)

        -- NOTE [JM] test development only
        if name == "test_events" then
            table.insert(tests, test)

        end
    end
end

local function G_setup()
    if turtle.getFuelLevel() < 100 then
        error("not enough fuel")
    end

    local function findStartingPosition()
        while true do
            while turtle.forward() do

            end

            local _, detail = turtle.inspect()

            if detail and detail.name == "minecraft:redstone_block" then
                break
            end

            turtle.turnRight()
        end

        while turtle.down() do

        end

        turtle.turnRight()

        while turtle.forward() do

        end

        turtle.turnRight()

        turtle.forward()

        turtle.turnLeft()

        local _, detail = turtle.inspect()
        assert(detail and detail.name == "minecraft:chest", "could not move to starting position")

        return true
    end

    local function emptyTurtle()
        for i = 1, 16 do
            if turtle.getItemCount(i) > 0 then
                turtle.select(i)
                turtle.drop()
            end
        end

        turtle.select(1)
        turtle.equipLeft()
        turtle.drop()

        turtle.equipRight()
        turtle.drop()

        return true
    end

    findStartingPosition()
    emptyTurtle()
end

local function G_teardown()
    -- nop
end

return function()
    local utility = {}

    local function findEmptySlotInChest(chest)
        for i = 1, 16 do
            if not chest.getItemDetail(i) then
                return i
            end
        end

        error("no empty slot in chest")
    end

    local function makeFirstSlotEmptyIfNot(chest, name)
        local detail = chest.getItemDetail(1)

        if detail and detail.name ~= name then
            local emptySlot = findEmptySlotInChest(chest)
            chest.pushItems(peripheral.getName(chest), 1, 64, emptySlot)
        end
    end

    function utility.getStackFromChest(name)
        local chest = peripheral.wrap("front")
        makeFirstSlotEmptyIfNot(chest, name)

        for slot, detail in pairs(chest.list()) do
            if detail.name == name then
                chest.pushItems(peripheral.getName(chest), slot, 64, 1)

                if turtle.suck() then
                    return
                end

                error("could not suck from chest")
            end
        end

        error(name .. " not found in chest")
    end

    for _, test in ipairs(tests) do
        -- NOTE [JM] disable this for test development only
        --G_setup()

        test(robot, utility)
        G_teardown()
    end

    print("all tests passed")
end
