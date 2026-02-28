return function(robot, meta, constants)
    local DELTAS = constants.deltas
    local FACING_INDEX = constants.facing_index
    local FACINGS = constants.facings
    local SIDE_INDEX = constants.side_index
    local SIDES = constants.sides
    local OPPOSITE_SIDES = constants.opposite_sides
    local OPPOSITE_FACINGS = constants.opposite_facings
    local ITEM_INFO = constants.item_info
    local DEFAULT_STACK_SIZE = constants.default_stack_size
    local RESERVED_INVENTORY_NAME = constants.reserved_inventory_name
    local FUEL_LEVEL_WARNING = "fuel_level_warning"
    local PATH_WARNING = "path_warning"
    local FUEL_SAFETY_MARGIN = math.min(nativeTurtle.getFuelLimit() / 10 * 2, 1000)

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local acceptedFuels = {}

    local function face(facing)
        local diff = (FACING_INDEX[facing] - FACING_INDEX[robot.facing]) % 4

        if diff == 1 then
            nativeTurtle.turnRight()
        elseif diff == 2 then
            nativeTurtle.turnRight()
            nativeTurtle.turnRight()
        elseif diff == 3 then
            nativeTurtle.turnLeft()
        end

        robot.facing = facing
    end

    local function moveHelper(moveFunc, delta, count, blocking)
        if type(count) == "boolean" or type(count) == "function" then
            blocking = count
            count = 1
        end

        count = count or 1
        local moved = 0

        local function check()
            return moved >= count
        end

        local function tick()
            if moveFunc() then
                robot.x = robot.x + delta.x
                robot.y = robot.y + delta.y
                robot.z = robot.z + delta.z

                moved = moved + 1
                meta.softUnwrapAll()

                return true
            end
        end

        meta.try(check, tick, blocking)
        return moved
    end

    local function turnHelper(turnFunc, direction, count)
        count = count or 1

        for i = 1, count do
            turnFunc()
        end

        local facingI = (FACING_INDEX[robot.facing] + (direction * count)) % 4

        robot.facing = FACING_INDEX[facingI]
        meta.softUnwrapAll()

        return count
    end

    local function refuel(query, availableCount)
        -- TODO [JM] loop like dropHelper_0 until item from query is not immediately available
        local ok, count = meta.selectFirstSlot(query)

        if ok then
            local cappedCount = math.min(count, availableCount)
            nativeTurtle.refuel(cappedCount)
        end
    end

    local function refuelTo(requiredLevel)
        if nativeTurtle.getFuelLevel() >= requiredLevel then
            return true
        end

        for name, reserveCount in pairs(acceptedFuels) do
            local query = name .. "@" .. RESERVED_INVENTORY_NAME
            local availableCount = math.min(robot.getItemCount(query), reserveCount)

            refuel(query, availableCount)

            if nativeTurtle.getFuelLevel() >= requiredLevel then
                return true
            end
        end

        return false
    end

    local function clamp(val)
        return math.max(-1, math.min(1, val))
    end

    local function moveX(targetFacing, dx, callback)
        if dx ~= 0 then
            local facing = dx > 0 and FACINGS.east or FACINGS.west

            if facing ~= targetFacing then
                return true
            end

            face(facing)
            robot.forward(math.abs(dx), function(stop)
                callback(stop, robot.x + clamp(dx), robot.y, robot.z, facing)
            end)
        end

        return true
    end

    local function moveY(targetFacing, dy, callback)
        if dy ~= 0 then
            local facing = dy > 0 and FACINGS.up or FACINGS.down
            if facing ~= targetFacing then
                return true
            end

            local moveFunc = dy > 0 and robot.up or robot.down
            moveFunc(math.abs(dy), function(stop)
                callback(stop, robot.x, robot.y + clamp(dy), robot.z, facing)
            end)
        end

        return true
    end

    local function moveZ(targetFacing, dz, callback)
        if dz ~= 0 then
            local facing = dz > 0 and FACINGS.south or FACINGS.north

            if facing ~= targetFacing then
                return true
            end

            face(facing)
            robot.forward(math.abs(dz), function(stop)
                callback(stop, robot.x, robot.y, robot.z + clamp(dz), facing)
            end)
        end

        return true
    end

    local function moveInOrder(order, blocking)
        for _, entry in ipairs(order) do
            entry[1](entry[2], entry[3], blocking)
        end
    end

    local function getKeys(table)
        local keys = {}

        for key in pairs(table) do
            keys[#keys + 1] = key
        end

        return keys
    end

    local function getStackSize(itemName)
        local block = ITEM_INFO[itemName]

        if block then
            return block.stackSize
        end

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail and detail.name == itemName then
                return detail.count + nativeTurtle.getItemSpace(i)
            end
        end

        return DEFAULT_STACK_SIZE
    end

    function meta.requireFuelLevel(requiredLevel)
        if not next(acceptedFuels) then
            error("no accepted fuels configured! use robot.setFuel() first.", 0)
        end

        if requiredLevel > nativeTurtle.getFuelLimit() then
            error("requiredLevel is bigger than turtle.getFuelLimit()!", 0)
        end

        requiredLevel = math.min(requiredLevel + FUEL_SAFETY_MARGIN, nativeTurtle.getFuelLimit())

        local function check()
            return refuelTo(requiredLevel)
        end

        local function get()
            return {
                missingFuelLevel = requiredLevel - nativeTurtle.getFuelLevel(),
                acceptedFuels = acceptedFuels
            }
        end

        local function constructor(detail)
            return meta.createEvent(FUEL_LEVEL_WARNING, detail)
        end

        meta.require(check, get, constructor)
    end

    function robot.forward(count, blocking)
        return moveHelper(nativeTurtle.forward, DELTAS[robot.facing], count, blocking)
    end

    function robot.back(count, blocking)
        local opposite = OPPOSITE_FACINGS[robot.facing]
        return moveHelper(nativeTurtle.back, DELTAS[opposite], count, blocking)
    end

    function robot.up(count, blocking)
        return moveHelper(nativeTurtle.up, DELTAS.up, count, blocking)
    end

    function robot.down(count, blocking)
        return moveHelper(nativeTurtle.down, DELTAS.down, count, blocking)
    end

    function robot.turnRight(count)
        return turnHelper(nativeTurtle.turnRight, 1, count)
    end

    function robot.turnLeft(count)
        return turnHelper(nativeTurtle.turnLeft, -1, count)
    end

    local function contains(t, value)
        for _, v in ipairs(t) do
            if v == value then
                return true
            end
        end

        return false
    end

    local function getValidSides(peripheral)
        local customPeripheral = meta.getCustomPeripheralDetail(peripheral.name)
        local sides

        if customPeripheral then
            sides = customPeripheral.sides
        end

        if not sides then
            sides = {
                SIDES.front,
                SIDES.right,
                SIDES.back,
                SIDES.left,
                SIDES.top,
                SIDES.bottom,
            }
        end

        return sides
    end

    local function requireStep(moveFunc)
        local tss = {
            [robot.forward] = SIDES.front,
            [robot.back] = SIDES.back,
            [robot.up] = SIDES.top,
            [robot.down] = SIDES.bottom
        }
        local tfs = {
            [robot.forward] = robot.facing,
            [robot.back] = OPPOSITE_FACINGS[robot.facing],
            [robot.up] = FACINGS.up,
            [robot.down] = FACINGS.down
        }

        local ts = tss[moveFunc]
        local tf = tfs[moveFunc]

        local function check()
            return moveFunc() > 0
        end

        local function get()
            local delta = DELTAS[tf]

            return {
                obstacle = {
                    x = robot.x + delta.x,
                    y = robot.y + delta.y,
                    z = robot.z + delta.z
                },
                side = ts,
                facing = tf
            }
        end

        local function constructor(detail)
            return meta.createEvent(PATH_WARNING, detail)
        end

        meta.require(check, get, constructor)
    end

    local function align(peripheral, side)
        if peripheral.x == robot.x and peripheral.y == robot.y and peripheral.z == robot.z then
            requireStep(robot.back)
            meta.requirePeripheral(peripheral.x, peripheral.y, peripheral.z)
        end

        local xzAligned = peripheral.x == robot.x and peripheral.z == robot.z

        if side ~= SIDES.bottom and peripheral.y < robot.y and xzAligned then
            -- move in front (normalize)
            requireStep(robot.back)
            requireStep(robot.down)
        elseif side ~= SIDES.top and peripheral.y > robot.y and xzAligned then
            -- move in front (normalize)
            requireStep(robot.back)
            requireStep(robot.up)
        end

        local yAligned = peripheral.y == robot.y

        if side == SIDES.top and yAligned then
            -- move below
            requireStep(robot.down)
            requireStep(robot.forward)
        elseif side == SIDES.bottom and yAligned then
            -- move above
            requireStep(robot.up)
            requireStep(robot.forward)
        elseif side == SIDES.right then
            robot.turnRight()
        elseif side == SIDES.back then
            robot.turnRight(2)
        elseif side == SIDES.left then
            robot.turnLeft()
        end
    end

    function robot.moveTo(x, y, z, facing)
        local peripheral
        local side

        if type(x) == "table" then
            peripheral = x
            side = y

            x, y, z = peripheral.x, peripheral.y, peripheral.z
            facing = nil

            if side then
                side = OPPOSITE_SIDES[side]
            end
        end

        local dx = (x or robot.x) - robot.x
        local dy = (y or robot.y) - robot.y
        local dz = (z or robot.z) - robot.z

        if peripheral then
            local sides = getValidSides(peripheral)

            if not side then
                side = contains(sides, SIDES.front) and SIDES.front or sides[1]
            elseif not contains(sides, side) then
                error(side .. " is not valid for peripheral")
            end
        end

        meta.requireFuelLevel(math.abs(dx) + math.abs(dy) + math.abs(dz))

        local order = {
            { moveY, FACINGS.up, dy },
            { moveX, FACINGS.east, dx },
            { moveZ, FACINGS.north, dz },
            { moveZ, FACINGS.south, dz },
            { moveX, FACINGS.west, dx },
            { moveY, FACINGS.down, dy }
        }
        local blocking = function(stop, tx, ty, tz, tf)
            local function check()
                -- TODO [JM] detect() is not enough here, entities could be in the way
                -- this doesn't lead to errors, but no PATH_WARNING is dispatched when entity is blocking the way

                local detectFuncs = {
                    [FACINGS.up] = nativeTurtle.detectUp,
                    [FACINGS.down] = nativeTurtle.detectDown,
                }

                local detectFunc = detectFuncs[tf] or nativeTurtle.detect
                return not detectFunc()
            end

            local function get()
                local ts

                if tf == FACINGS.up then
                    ts = SIDES.top
                elseif tf == FACINGS.down then
                    ts = SIDES.bottom
                else
                    ts = SIDES.front
                end

                return {
                    obstacle = {
                        x = tx,
                        y = ty,
                        z = tz
                    },
                    side = ts,
                    facing = tf
                }
            end

            local function constructor(detail)
                return meta.createEvent(PATH_WARNING, detail)
            end

            if peripheral and tx == peripheral.x and ty == peripheral.y and tz == peripheral.z then
                stop()
            else
                meta.require(check, get, constructor)
            end
        end

        moveInOrder(order, blocking)

        if peripheral then
            align(peripheral, side)
        elseif facing then
            face(facing)
        end

        return robot.x, robot.y, robot.z, robot.facing
    end

    function robot.setFuel(which, reserveCount)
        for _name, _reserveCount in pairs(acceptedFuels) do
            meta.free(_name, _reserveCount)
        end

        acceptedFuels = ({
            ["nil"] = function()
                return {}
            end,
            ["string"] = function()
                local itemName = meta.parseQuery(which)
                return { [itemName] = reserveCount or getStackSize(itemName) }
            end,
            ["table"] = function()
                local mapped = {}

                for _which, _reserveCount in pairs(which) do
                    local itemName = meta.parseQuery(_which)
                    mapped[itemName] = _reserveCount
                end

                return mapped
            end
        })[type(which)]()

        for _name, _reserveCount in pairs(acceptedFuels) do
            meta.reserve(_name .. "@items", _reserveCount)
        end
    end

    function robot.getFuelLevel()
        return nativeTurtle.getFuelLevel()
    end

    function robot.getFuelLimit()
        return nativeTurtle.getFuelLimit()
    end

    function robot.onFuelLevelWarning(callback)
        meta.on(FUEL_LEVEL_WARNING, callback)
    end

    function robot.onFuelLevelWarningCleared(callback)
        meta.on(FUEL_LEVEL_WARNING .. "_cleared", callback)
    end

    function robot.onPathWarning(callback)
        meta.on(PATH_WARNING, callback)
    end

    function robot.onPathWarningCleared(callback)
        meta.on(PATH_WARNING .. "_cleared", callback)
    end

    local lastMissingFuelLevel
    robot.onFuelLevelWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local missingFuelLevel = e.detail.missingFuelLevel
        --local acceptedFuels = e.detail.acceptedFuels

        if not alreadyWarned or lastMissingFuelLevel ~= missingFuelLevel then
            local acceptedNames = getKeys(acceptedFuels)

            print("---- " .. FUEL_LEVEL_WARNING .. " ----")
            print("missing " .. missingFuelLevel .. " fuelLevel")
            print("acceptedFuels = [" .. table.concat(acceptedNames, ", ") .. "]")

            lastMissingFuelLevel = missingFuelLevel
        end

        meta.sync()
    end)
    robot.onFuelLevelWarningCleared(function()
        print("---- " .. FUEL_LEVEL_WARNING .. "_cleared ----")
    end)

    robot.onPathWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local obstacle = e.detail.obstacle
        local facing = e.detail.facing

        local x = obstacle.x
        local y = obstacle.y
        local z = obstacle.z

        if not alreadyWarned then
            print("---- " .. PATH_WARNING .. " ----")
            print("obstacle at (" .. x .. ", " .. y .. ", " .. z .. ") while moving " .. facing)
        end
    end)
    robot.onPathWarningCleared(function()
        print("---- " .. PATH_WARNING .. "_cleared ----")
    end)
end
