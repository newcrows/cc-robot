return function(robot, meta, constants)
    function robot.place(name, blocking)
        -- TODO [JM] implement
    end

    function robot.placeUp(name, blocking)
        -- TODO [JM] implement
    end

    function robot.placeDown(name, blocking)
        -- TODO [JM] implement
    end

    function robot.drop(name, count, blocking)
        -- TODO [JM] implement
    end

    function robot.dropUp(name, count, blocking)
        -- TODO [JM] implement
    end

    function robot.dropDown(name, count, blocking)
        -- TODO [JM] implement
    end

    function robot.detect()
        return turtle.detect()
    end

    function robot.detectUp()
        return turtle.detectUp()
    end

    function robot.detectDown()
        return turtle.detectDown()
    end

    function robot.compare(name)
        -- TODO [JM] implement
    end

    function robot.compareUp(name)
        -- TODO [JM] implement
    end

    function robot.compareDown(name)
        -- TODO [JM] implement
    end

    function robot.suck(count, blocking)
        -- TODO [JM] implement
    end

    function robot.suckUp(count, blocking)
        -- TODO [JM] implement
    end

    function robot.suckDown(count, blocking)
        -- TODO [JM] implement
    end

    function robot.inspect()
        return turtle.inspect()
    end

    function robot.inspectUp()
        return turtle.inspectUp()
    end

    function robot.inspectDown()
        return turtle.inspectDown()
    end
end
