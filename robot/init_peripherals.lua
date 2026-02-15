return function(robot, meta, constants)
    local RAW_PROPERTIES = constants.raw_properties
    local SIDES = constants.sides
    local INSPECT_FUNCS = {
        [SIDES.front] = turtle.inspect,
        [SIDES.top] = turtle.inspectUp,
        [SIDES.bottom] = turtle.inspectDown
    }

    local constructors = {}
    local proxies = {}

    local function createWrapProxy(name, side, target)
        local proxy = {
            name = name,
            side = side,
            target = target
        }

        local metatable = {
            __index = function(_, key)
                if RAW_PROPERTIES[key] then
                    return rawget(proxy, key)
                end

                return function(...)
                    if not proxy.target then
                        error("wrapped block is no longer accessible")
                    end

                    return proxy.target[key](...)
                end
            end,
            __newindex = function(_, key, value)
                if RAW_PROPERTIES[key] then
                    rawset(proxy, key, value)
                end
            end
        }

        setmetatable(proxy, metatable)
        return proxy
    end

    local function getPhysicalName(side)
        local inspectFunc = INSPECT_FUNCS[side]

        assert(inspectFunc, "it is NEVER possible to get wrap name for " .. side)

        local ok, detail = inspectFunc()
        return ok and detail.name or nil
    end

    local function wrap_0(side, name)
        local target = peripheral.wrap(side)
        local constructor = constructors[name]

        if constructor then
            local opts = {
                robot = robot,
                meta = meta,
                constants = constants,
                name = name,
                side = side,
                target = target
            }

            target = constructor(opts)
        end

        local proxy = createWrapProxy(name, side, target)
        proxies[side] = proxy

        meta.dispatchEvent("wrap", side, name)
        return proxy
    end

    local function wrap(side, wrapAs)
        wrapAs = wrapAs or getPhysicalName(side)

        if not wrapAs then
            return nil
        end

        local equipments = meta.listEquipment()

        for _, equipment in pairs(equipments) do
            local proxy = equipment.proxy

            if proxy.target and proxy.side == side then
                if not proxy.unuse() then
                    error("could not unequip tool on " .. side)
                end
            end
        end

        return wrap_0(side, wrapAs)
    end

    function robot.wrap(side, wrapAs)
        side = side or SIDES.front
        return wrap(side, wrapAs)
    end

    function robot.wrapUp(wrapAs)
        return wrap(SIDES.top, wrapAs)
    end

    function robot.wrapDown(wrapAs)
        return wrap(SIDES.bottom, wrapAs)
    end

    function meta.getPeripheral(side)
        side = side or SIDES.front
        local proxy = proxies[side]

        if proxy then
            return {
                side = side,
                proxy = proxy
            }
        end
    end

    function meta.listPeripherals()
        local arr = {}

        for side, proxy in pairs(proxies) do
            table.insert(arr, {
                side = side,
                proxy = proxy
            })
        end

        return arr
    end

    function meta.setPeripheralConstructor(name, constructor)
        assert(name, "name must not be nil")
        assert(type(constructor) == "function", "constructor must be of type function")

        constructors[name] = constructor
        return true
    end

    function meta.removePeripheralConstructor(name)
        assert(name, "name must not be nil")

        constructors[name] = nil
        return true
    end

    function meta.getPeripheralConstructorDetail(name)
        assert(name, "name must not be nil")
        local constructor = constructors[name]

        if constructor then
            return {
                name = name,
                constructor = constructor
            }
        end

        return nil
    end

    function meta.listPeripheralConstructors()
        local arr = {}

        for name, constructor in pairs(constructors) do
            table.insert({
                name = name,
                constructor = constructor
            })
        end

        return arr
    end

    function meta.softWrap(side)
        assert(side, "side must not be nil")
        local proxy = proxies[side]

        if proxy and not proxy.target then
            proxy.target = peripheral.wrap(side)
            meta.dispatchEvent("soft_wrap", proxy.name, side)
        end

        return true
    end

    function meta.softUnwrap(side)
        assert(side, "side must not be nil")
        local proxy = proxies[side]

        if proxy and proxy.target then
            proxy.target = nil
            meta.dispatchEvent("soft_unwrap", proxy.name, side)
        end

        return true
    end

    meta.setPeripheralConstructor("minecraft:chest", function(opts)
        -- custom chest implementation here
        -- TODO [JM] implement
    end)
    meta.setPeripheralConstructor("minecraft:me_bridge", function(opts)
        -- custom me_bridge implementation here
        -- TODO [JM] implement
    end)
end
