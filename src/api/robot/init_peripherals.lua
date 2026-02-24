return function(robot, meta, constants)
    local FACINGS = constants.facings
    local FACING_INDEX = constants.facing_index
    local SIDE_INDEX = constants.side_index
    local SIDES = constants.sides
    local DELTAS = constants.deltas
    local PERIPHERAL_WARNING = "peripheral_warning"
    local RAW_PROPERTIES = {
        x = true,
        y = true,
        z = true,
        name = true,
        side = true,
        target = true
    }

    local customPeripherals = {}
    local proxies = {}
    local softProxies = {}

    local function loadCustomPeripherals()
        local dir = "%INSTALL_DIR%/peripherals"
        local files = fs.list(dir)

        for _, file in ipairs(files) do
            local cleanFile = string.gsub(file, "%.lua$", "")
            local init = require("/" .. fs.combine(dir, cleanFile))

            local detail = type(init) == "function" and init(robot, meta, constants) or init
            local names = detail.names or { detail.name }

            for _, name in ipairs(names) do
                customPeripherals[name] = detail
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
        if facing == FACINGS.up then
            return SIDES.top
        elseif facing == FACINGS.down then
            return SIDES.bottom
        end

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
            error("peripheral is not in range", 0)
        end

        local function check()
            local side = getSideFor(facing)
            local target = peripheral.wrap(side)

            if not target then
                return false
            end

            local customPeripheral = customPeripherals[proxy.name]

            if customPeripheral then
                if customPeripheral.sides then
                    local found = false

                    for _, acceptedSide in pairs(customPeripheral.sides) do
                        if acceptedSide == side then
                            found = true
                            break
                        end
                    end

                    if not found then
                        error("side " .. side .. " not accepted for " .. proxy.name, 0)
                    end
                end

                local opts = {
                    name = proxy.name,
                    side = side,
                    target = target,
                    facing = facing,
                    x = proxy.x,
                    y = proxy.y,
                    z = proxy.z
                }

                target = customPeripheral.constructor(opts)
            end

            proxy.side = side
            proxy.target = target

            softProxies[key] = proxy
            return true
        end

        local function get()
            return {
                name = proxy.name,
                x = proxy.x,
                y = proxy.y,
                z = proxy.z
            }
        end

        local function constructor(detail)
            return meta.createEvent(PERIPHERAL_WARNING, detail)
        end

        meta.require(check, get, constructor)
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
                        softWrap(key, proxy)
                    end

                    if not peripheral.isPresent(proxy.side) then
                        softWrap(key, proxy)
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

            local itemName = meta.parseQuery(wrapAs)
            x, y, z, name = x.x, x.y, x.z, itemName
        elseif type(x) == "number" and type(y) == "number" and type(z) == "number" then
            x, y, z, name = x, y, z, wrapAs
        elseif type(x) == "string" then
            if SIDES[x] then
                x, wrapAs = x, y
            else
                wrapAs = x
                x = SIDES.front
            end

            if wrapAs then
                local itemName = meta.parseQuery(wrapAs)
                name = itemName
            else
                name = getNameFor(x)
            end

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

    local function getValues(table)
        local values = {}

        for _, value in pairs(table) do
            values[#values + 1] = value
        end

        return values
    end

    function meta.getCustomPeripheralDetail(query)
        local itemName = meta.parseQuery(query);
        return customPeripherals[itemName]
    end

    function meta.listCustomPeripherals()
        return getValues(customPeripherals)
    end

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
        return getValues(proxies)
    end

    function robot.onPeripheralWarning(callback)
        meta.on(PERIPHERAL_WARNING, callback)
    end

    function robot.onPeripheralWarningCleared(callback)
        meta.on(PERIPHERAL_WARNING .. "_cleared", callback)
    end

    robot.onPeripheralWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local name = e.detail.name
        local x = e.detail.x
        local y = e.detail.y
        local z = e.detail.z

        if not alreadyWarned then
            print("---- " .. PERIPHERAL_WARNING .. " ----")
            print("missing " .. name .. " at (" .. x .. ", " .. y .. ", " .. z .. ")")
        end
    end)
    robot.onPeripheralWarningCleared(function()
        print("---- " .. PERIPHERAL_WARNING .. "_cleared ----")
    end)

    loadCustomPeripherals()
end
