return function(robot, meta)
    local constructors = {}

    function robot.wrap(side, wrapAs)
        -- TODO [JM] implement
    end

    function robot.wrapUp(wrapAs)
        -- TODO [JM] implement
    end

    function robot.wrapDown(wrapAs)
        -- TODO [JM] implement
    end

    -- NOTE [JM] moved to meta because writing custom peripherals is definitely meta
    function meta.setConstructor(name, constructor)
        assert(name, "name must not be nil")
        assert(type(constructor) == "function", "constructor must be of type function")

        constructors[name] = constructor
        return true
    end

    -- NOTE [JM] moved to meta because writing custom peripherals is definitely meta
    function meta.removeConstructor(name)
        assert(name, "name must not be nil")

        constructors[name] = nil
        return true
    end

    function meta.getConstructor(name)
        assert(name, "name must not be nil")
        return constructors[name]
    end

    -- NOTE [JM] moved to meta because writing custom peripherals is definitely meta
    function meta.listConstructors()
        local arr = {}

        for name, constructor in pairs(constructors) do
            table.insert({
                name,
                constructor
            })
        end

        return arr
    end

    -- NOTE [JM] exposed because custom peripherals that break blocks or move the turtle might need to softWrap
    function meta.softWrap(side)
        -- TODO [JM] implement
    end

    -- NOTE [JM] exposed because custom peripherals that break blocks or move the turtle might need to softUnwrap
    function meta.softUnwrap(side)
        -- TODO [JM] implement
    end

    meta.addConstructor("minecraft:chest", function(opts)
        -- custom chest implementation here
        -- TODO [JM] implement
    end)

    meta.addConstructor("minecraft:me_bridge", function(opts)
        -- custom me_bridge implementation here
        -- TODO [JM] implement
    end)
end
