return function(robot, meta, constants)
    local RAW_PROPERTIES = constants.raw_properties
    local FACINGS = constants.facings
    local OPPOSITE_FACINGS = constants.opposite_facings
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

    local function wrapHelper(side, wrapAs)
        if side and not SIDES[side] then
            wrapAs, side = side, nil
        end

        side = side or SIDES.front

        -- TODO [JM] peripheral proxy creation here
    end

    local function loadConstructors()
        local dir = "%INSTALL_DIR%/peripherals"
        local files = fs.list(dir)

        for _, file in ipairs(files) do
            local cleanFile = string.gsub(file, "%.lua$", "")
            local detail = require(fs.combine(dir, cleanFile))

            constructors[detail.name] = detail.constructor
        end
    end

    function meta.getPeripheralConstructorDetail(name)
        name = name or robot.getSelectedName()
        return constructors[name]
    end

    function meta.listPeripheralConstructors()
        local arr = {}

        for name, constructor in pairs(constructors) do
            table.insert(arr, {
                name = name,
                constructor = constructor
            })
        end

        return arr
    end

    function robot.wrap(side, wrapAs)
        return wrapHelper(side, wrapAs)
    end

    function robot.wrapUp(wrapAs)
        return wrapHelper(SIDES.top, wrapAs)
    end

    function robot.wrapDown(wrapAs)
        return wrapHelper(SIDES.bottom, wrapAs)
    end

    loadConstructors()
end
