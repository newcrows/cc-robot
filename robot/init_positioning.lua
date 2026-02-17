return function(robot, meta, constants)
    local DELTAS = constants.deltas
    local FACING_INDEX = constants.facing_index
    local FACINGS = constants.facings
    local OPPOSITE_FACINGS = constants.opposite_facings

    robot.x, robot.y, robot.z = 0, 0, 0
    robot.facing = FACINGS.north

    local function move(moveFunc, delta, count, blocking)
        if type(count) == "function" or type(count) == "boolean" then
            blocking = count
            count = 1
        else
            count = count or 1
        end

        local moved = 0
        while moved < count do
            local waited = false

            while not moveFunc() do
                if blocking then
                    if waited then
                        os.sleep(1)
                    end

                    if type(blocking) == "function" then
                        blocking()
                    end

                    waited = true
                else
                    return moved, "movement obstructed"
                end
            end

            robot.x = robot.x + delta.x
            robot.y = robot.y + delta.y
            robot.z = robot.z + delta.z
            moved = moved + 1
        end

        return moved, nil
    end

    local function turn(turnFunc, direction, count)
        count = count or 1

        for i = 1, count do
            turnFunc()
        end

        robot.facing = (robot.facing + (direction * count)) % 4
        return count
    end

    function robot.forward(count, blocking)
        return move(turtle.forward, DELTAS[robot.facing], count, blocking)
    end

    function robot.back(count, blocking)
        local opposite = OPPOSITE_FACINGS[robot.facing]
        return move(turtle.back, DELTAS[opposite], count, blocking)
    end

    function robot.up(count, blocking)
        return move(turtle.up, DELTAS.up, count, blocking)
    end

    function robot.down(count, blocking)
        return move(turtle.down, DELTAS.down, count, blocking)
    end

    function robot.turnRight(count)
        return turn(turtle.turnRight, 1, count)
    end

    function robot.turnLeft(count)
        return turn(turtle.turnLeft, -1, count)
    end

    function robot.move(dfb, dud, drl, blocking)
        if type(dfb) == "function" or type(dfb) == "boolean" then
            blocking, dfb, dud, drl = dfb, 0, 0, 0
        elseif type(dud) == "function" or type(dud) == "boolean" then
            blocking, dud, drl = dud, 0, 0
        elseif type(drl) == "function" or type(drl) == "boolean" then
            blocking, drl = drl, 0
        end

        dfb, dud, drl = dfb or 0, dud or 0, drl or 0

        local function wrap(d_dfb, d_dud, d_drl)
            if type(blocking) == "function" then
                local c_dfb = d_dfb > 0 and 1 or (d_dfb < 0 and -1 or 0)
                local c_dud = d_dud > 0 and 1 or (d_dud < 0 and -1 or 0)
                local c_drl = d_drl > 0 and 1 or (d_drl < 0 and -1 or 0)

                return function()
                    blocking(c_dfb, c_dud, c_drl)
                end
            end

            return blocking
        end

        local dfbBlocking = wrap(dfb, 0, 0)
        local dudBlocking = wrap(0, dud, 0)
        local drlBlocking = wrap(0, 0, drl)

        local forward = robot.forward
        local back = robot.back
        local up = robot.up
        local down = robot.down
        local turnRight = robot.turnRight
        local turnLeft = robot.turnLeft

        local m_dfb = dfb > 0 and forward(dfb, dfbBlocking) or -back(-dfb, dfbBlocking)
        if m_dfb ~= dfb then
            return m_dfb, 0, 0
        end

        local m_dud = dud > 0 and up(dud, dudBlocking) or -down(-dud, dudBlocking)
        if m_dud ~= dud then
            return m_dfb, m_dud, 0
        end

        local _ = drl > 0 and turnRight() or (drl < 0 and turnLeft())
        local m_drl = drl > 0 and forward(drl, drlBlocking) or -forward(-drl, drlBlocking)

        return m_dfb, m_dud, m_drl
    end

    function robot.face(targetFacing)
        local diff = (targetFacing - robot.facing) % 4

        if diff == 1 then
            turtle.turnRight()
        elseif diff == 2 then
            turtle.turnRight()
            turtle.turnRight()
        elseif diff == 3 then
            turtle.turnLeft()
        end

        robot.facing = targetFacing
    end
end
