return function(robot, meta, constants)
    local FACING_INDEX = constants.facing_index
    local SIDE_INDEX = constants.side_index
    local SIDES = constants.sides
    local DELTAS = constants.deltas

    local constructors = {}
    local proxies = {}

    local function getNameFor(side)
        local inspectFunc = ({
            front = turtle.inspect,
            top = turtle.inspectUp,
            bottom = turtle.inspectDown
        })[side]

        if not inspectFunc then
            error("name could not be determined on " .. side)
        end

        local _, detail = inspectFunc()

        if not detail then
            error("name could not be determined on " .. side)
        end

        return detail.name
    end

    local function getPositionFor(side)
        local facingI = (FACING_INDEX[robot.facing] + SIDE_INDEX[side]) % 4
        local facing = FACING_INDEX[facingI]
        local delta = DELTAS[facing]

        return robot.x + delta.x, robot.y + delta.y, robot.z + delta.z
    end

    local function wrapHelper(side, wrapAs)
        if side and not SIDES[side] then
            wrapAs, side = side, nil
        end

        side = side or SIDES.front

        local name = wrapAs or getNameFor(side)
        local x, y, z = getPositionFor(side)

        -- TODO [JM] peripheral proxy creation here

        -- maybe robot.go(peripheral) should just work?
        -- going to peripherals directly is probably a nice feature without bloating the api

        -- like robot.go(chest_1) -> robot moves next to chest_1?
        -- like robot.moveTo(chest_1) -> robot moves next to chest_1?

        -- go / moveTo either aliases or I decide which of both later on
        -- probably should use one of them only, so there is no bloat
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
