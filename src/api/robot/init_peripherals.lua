return function(robot, meta, constants)
    local FACING_INDEX = constants.facing_index
    local SIDE_INDEX = constants.side_index
    local SIDES = constants.sides
    local DELTAS = constants.deltas

    local constructors = {}
    local proxies = {}

    local function loadConstructors()
        local dir = "%INSTALL_DIR%/peripherals"
        local files = fs.list(dir)

        for _, file in ipairs(files) do
            local cleanFile = string.gsub(file, "%.lua$", "")
            local detail = require(fs.combine(dir, cleanFile))

            constructors[detail.name] = detail.constructor
        end
    end

    local function getNameFor(side)
        local inspectFunc = ({
            front = turtle.inspect,
            top = turtle.inspectUp,
            bottom = turtle.inspectDown
        })[side]

        if not inspectFunc then
            error("name could not be determined on " .. side)
        end

        local ok, detail = inspectFunc()

        if not ok then
            error("name could not be determined on " .. side)
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

    local function createProxy(x, y, z, name)
        local key = x .. "|" .. y .. "|" .. z
        local proxy = {
            x = x, y = y, z = z,
            name = name
        }

        -- TODO [JM] peripheral proxy creation here

        -- maybe robot.go(peripheral) should just work?
        -- going to peripherals directly is probably a nice feature without bloating the api

        -- like robot.go(chest_1) -> robot moves next to chest_1?
        -- like robot.moveTo(chest_1) -> robot moves next to chest_1?

        -- go / moveTo either aliases or I decide which of both later on
        -- probably should use one of them only, so there is no bloat

        proxies[key] = proxy
        return proxy
    end

    local function wrapHelper(x, y, z, wrapAs)
        x = x or SIDES.front
        local name

        if type(x) == "number" and type(y) == "number" and type(z) == "number" then
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

        local key = x .. "|" .. y .. "|" .. z
        local proxy = proxies[key]

        if proxy then
            if proxy.name ~= name then
                error("already wrapped as something else")
            end

            print("return " .. name .. " at (" .. x .. ", " .. y .. ", " .. z .. ")")
            return proxy
        end

        print("create " .. name .. " at (" .. x .. ", " .. y .. ", " .. z .. ")")
        return createProxy(x, y, z, name)
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

    function robot.wrap(x, y, z, wrapAs)
        return wrapHelper(x, y, z, wrapAs)
    end

    function robot.wrapUp(wrapAs)
        return wrapHelper(SIDES.top, wrapAs)
    end

    function robot.wrapDown(wrapAs)
        return wrapHelper(SIDES.bottom, wrapAs)
    end

    loadConstructors()
end
