-- TODO [JM] I need events in case peripherals unexpectedly went missing
-- programs should not randomly crash because someone took a chest or something
-- only hard errors (wrap "back" ohne wrapAs, etc.) sollten einen error auslösen
return function(robot, meta, constants)
    local FACING_INDEX = constants.facing_index
    local SIDE_INDEX = constants.side_index
    local SIDES = constants.sides
    local DELTAS = constants.deltas
    local RAW_PROPERTIES = {
        x = true,
        y = true,
        z = true,
        name = true,
        target = true
    }

    local constructors = {}
    local proxies = {}
    local softProxies = {}

    local function loadConstructors()
        local dir = "%INSTALL_DIR%/peripherals"
        local files = fs.list(dir)

        for _, file in ipairs(files) do
            local cleanFile = string.gsub(file, "%.lua$", "")
            local detail = require(fs.combine(dir, cleanFile))
            local names = detail.names or { detail.name }

            for _, name in ipairs(names) do
                constructors[name] = detail.constructor
            end
        end
    end

    local function getNameFor(side)
        local inspectFunc = ({
            front = nativeTurtle.inspect,
            top = nativeTurtle.inspectUp,
            bottom = nativeTurtle.inspectDown
        })[side]

        if not inspectFunc then
            error("name could not be determined on " .. side, 0)
        end

        local ok, detail = inspectFunc()

        if not ok then
            error("name could not be determined on " .. side, 0)
        end

        return detail.name
    end

    local function getPositionFor(side)
        if side == SIDES.top then
            return robot.x, robot.y + 1, robot.z
        elseif side == SIDES.bottom then
            return robot.x, robot.y - 1, robot.z
        end

        local facingI = (FACING_INDEX[robot.facing] + SIDE_INDEX[side]) % 4
        local facing = FACING_INDEX[facingI]
        local delta = DELTAS[facing]

        return robot.x + delta.x, robot.y + delta.y, robot.z + delta.z
    end

    local function getKeyFor(x, y, z)
        return x .. "|" .. y .. "|" .. z
    end

    local function getSideFor(facing)
        local facingI = FACING_INDEX[facing]
        local robotFacingI = FACING_INDEX[robot.facing]

        local sideI = (facingI - robotFacingI) % 4
        return SIDE_INDEX[sideI]
    end

    local function softWrap(key, proxy)
        local dx, dy, dz = proxy.x - robot.x, proxy.y - robot.y, proxy.z - robot.z
        local deltaKey = getKeyFor(dx, dy, dz)
        local facing = FACING_INDEX[deltaKey]

        if not facing then
            error("could not soft wrap", 0)
        end

        local side = getSideFor(facing)
        local target = peripheral.wrap(side)

        local constructor = constructors[proxy.name]

        if constructor then
            local opts = {
                robot = robot,
                meta = meta,
                constants = constants,
                name = proxy.name,
                x = proxy.x,
                y = proxy.y,
                z = proxy.z,
                facing = facing,
                side = side,
                target = target
            }

            target = constructor(opts)
        end

        proxy.target = target
        softProxies[key] = proxy
    end

    local function createProxy(x, y, z, name)
        local key = getKeyFor(x, y, z)
        local proxy = {
            x = x, y = y, z = z,
            name = name
        }

        local metatable = {
            __index = function(_, prop)
                if RAW_PROPERTIES[prop] then
                    return rawget(proxy, prop)
                end

                return function(...)
                    if not proxies[key] then
                        error("peripheral is no longer wrapped", 0)
                    end

                    if not softProxies[key] then
                        softWrap(key, proxies[key])
                    end

                    return proxy.target[prop](...)
                end
            end,
            __newindex = function(_, prop, value)
                if RAW_PROPERTIES[prop] then
                    rawset(proxy, prop, value)
                end
            end
        }

        setmetatable(proxy, metatable)
        proxies[key] = proxy

        return proxy
    end

    local function wrapHelper(x, y, z, wrapAs)
        x = x or SIDES.front
        local name

        if type(x) == "table" then
            if x.name then
                local key = getKeyFor(x.x, x.y, x.z)
                proxies[key] = x

                return x
            end

            x, y, z, name = x.x, x.y, x.z, wrapAs
        elseif type(x) == "number" and type(y) == "number" and type(z) == "number" then
            x, y, z, name = x, y, z, wrapAs
        elseif type(x) == "string" then
            if SIDES[x] then
                x, wrapAs = x, y
            else
                wrapAs = x
                x = SIDES.front
            end

            name = wrapAs or getNameFor(x)
            x, y, z = getPositionFor(x)
        end

        local key = getKeyFor(x, y, z)
        local proxy = proxies[key]

        if proxy then
            if proxy.name ~= name then
                error("already wrapped as something else", 0)
            end

            return proxy
        end

        return createProxy(x, y, z, name)
    end

    local function unwrapHelper(x, y, z)
        x = x or SIDES.front

        if type(x) == "table" then
            x, y, z = x.x, x.y, x.z
        elseif type(x) == "number" and type(y) == "number" and type(z) == "number" then
            --nop
        elseif type(x) == "string" then
            x, y, z = getPositionFor(x)
        end

        local key = getKeyFor(x, y, z)
        local proxy = proxies[key]

        if proxy then
            softProxies[key] = nil
            proxies[key] = nil
        end

        return true
    end

    function meta.getPeripheralConstructorDetail(name)
        name = name or robot.getSelectedName()

        return {
            name = name,
            constructor = constructors[name]
        }
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

    -- NOTE [JM] should use meta.softUnwrapAll for better performance, peripherals auto-soft-wrap anyway
    -- this function just exists for consistency
    function meta.softUnwrap(side)
        side = side or SIDES.front

        local x, y, z = getPositionFor(side)
        local key = getKeyFor(x, y, z)

        softProxies[key] = nil
    end

    function meta.softUnwrapAll()
        softProxies = {}
    end

    function robot.wrap(x, y, z, wrapAs)
        return wrapHelper(x, y, z, wrapAs)
    end

    function robot.wrapUp(wrapAs)
        return wrapHelper(SIDES.top, wrapAs)
    end

    function robot.wrapDown(wrapAs)
        return wrapHelper(SIDES.bottom, wrapAs)
    end

    function robot.unwrap(x, y, z)
        return unwrapHelper(x, y, z)
    end

    function robot.unwrapUp()
        return unwrapHelper(SIDES.top)
    end

    function robot.unwrapDown()
        return unwrapHelper(SIDES.bottom)
    end

    function robot.getPeripheralDetail(x, y, z)
        x = x or SIDES.front

        if type(x) == "string" then
            x, y, z = getPositionFor(x)
        end

        local key = getKeyFor(x, y, z)
        return proxies[key]
    end

    function robot.listPeripherals()
        local arr = {}

        for _, proxy in pairs(proxies) do
            table.insert(arr, proxy)
        end

        return arr
    end

    loadConstructors()
end
