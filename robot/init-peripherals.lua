return function(robot, meta, constants)
    function robot.wrap(sideOrWrapAs, wrapAs)

    end

    function robot.wrapUp(wrapAs)

    end

    function robot.wrapDown(wrapAs)

    end

    -- NOTE [JM] moved to meta because writing custom peripherals is definitely meta
    function meta.setConstructor(name, constructor)

    end

    -- NOTE [JM] moved to meta because writing custom peripherals is definitely meta
    function meta.removeConstructor(name)

    end

    function meta.getConstructor(name)

    end

    -- NOTE [JM] moved to meta because writing custom peripherals is definitely meta
    function meta.listConstructors()

    end

    -- NOTE [JM] exposed because custom peripherals that break blocks or move the turtle might need to softWrap
    function meta.softWrap(side)

    end

    -- NOTE [JM] exposed because custom peripherals that break blocks or move the turtle might need to softUnwrap
    function meta.softUnwrap(side)

    end

    meta.addConstructor("minecraft:chest", function(opts)
        -- custom chest implementation here
    end)

    meta.addConstructor("minecraft:me_bridge", function(opts)
        -- custom me_bridge implementation here
    end)
end
