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
            meta.dispatchEvent("soft_wrap", side, proxy.name)
        end

        return true
    end

    function meta.softUnwrap(side)
        assert(side, "side must not be nil")
        local proxy = proxies[side]

        if proxy and proxy.target then
            proxy.target = nil
            meta.dispatchEvent("soft_unwrap", side, proxy.name)
        end

        return true
    end

    function meta.unwrap(side)
        assert(side, "side must not be nil")
        local proxy = proxies[side]

        if proxy then
            proxies[side] = nil
            meta.dispatchEvent("unwrap", side, proxy.name)
        end
    end

    meta.setPeripheralConstructor("minecraft:chest", function(opts)
        local targetChest = opts.target
        local targetName = peripheral.getName(targetChest)
        local helperChest
        local hasPickaxe = meta.hasEquipment("minecraft:diamond_pickaxe")

        if not targetChest then
            return nil
        end

        local function onAnyWrap(side, name)
            if name == "minecraft:chest" and side ~= "top" then
                robot.free("minecraft:chest", 1)

                if hasPickaxe and robot.placeUp("minecraft:chest") then
                    os.sleep(0.1)
                    helperChest = peripheral.wrap("top")
                end
            end
        end

        local function onAnyUnwrap(side, name)
            if name == "minecraft:chest" and side ~= "top" then
                if helperChest then
                    robot.equip("minecraft:diamond_pickaxe").digUp()
                    robot.reserve("minecraft:chest", 1)

                    helperChest = nil
                end
            end
        end

        meta.addEventListener({
            wrap = onAnyWrap,
            unwrap = onAnyUnwrap,
            soft_wrap = onAnyWrap,
            soft_unwrap = onAnyUnwrap
        })

        return {
            import = function(name, count, blocking)
                return robot.drop(name, count, blocking)
            end,
            export = function(name, count, blocking)
                assert(helperChest, "missing helper chest, can't export")
                local amount = 0

                while true do
                    for slot, detail in pairs(targetChest.list()) do
                        if detail.name == name then
                            local pullAmount = math.min(detail.count, count - amount)
                            amount = amount + helperChest.pullItems(targetName, slot, pullAmount)
                        end
                    end

                    if amount < count and blocking then
                        os.sleep(1)
                    else
                        break
                    end
                end

                return robot.suckUp(amount, blocking)
            end,
            getItemDetail = function(name)
                local count = 0

                for _, detail in pairs(targetChest.list()) do
                    if detail.name == name then
                        count = count + detail.count
                    end
                end

                return {
                    name = name,
                    count = count
                }
            end,
            listItems = function()
                local items = {}

                for _, detail in pairs(targetChest.list()) do
                    local item = items[detail.name]

                    if not item then
                        item = { name = detail.name, count = 0 }
                        items[detail.name] = item
                    end

                    item.count = item.count + detail.count
                end

                local arr = {}

                for _, item in pairs(items) do
                    table.insert(arr, item)
                end

                return arr
            end
        }
    end)
    meta.setPeripheralConstructor("advancedperipherals:me_bridge", function(opts)
        local side = opts.side
        local target = opts.target
        local facings = {
            front = robot.facing,
            top = FACINGS.up,
            bottom = FACINGS.down
        }

        if not target then
            return nil
        end

        local facing = facings[side]
        local oppFacing = OPPOSITE_FACINGS[facing]

        return {
            import = function(name, count)
                if not name then
                    error("name must not be nil")
                end

                local rCount = robot.getItemCount(name)

                if not count or rCount < count then
                    count = rCount
                end

                if count == 0 then
                    return 0, name .. " not found in turtle inventory"
                end

                return target.importItem({ name = name, count = count }, oppFacing)
            end,
            export = function(name, count)
                if not name then
                    error("name must not be nil")
                end

                if not count then
                    local item = target.getItem({ name = name })

                    if item then
                        count = item.count
                    else
                        return 0, name .. " not found in me_network"
                    end
                end

                if robot.getItemSpace(name) < count then
                    meta.compact()
                end

                return target.exportItem({ name = name, count = count }, oppFacing)
            end,
            getItemDetail = function(name)
                if not name then
                    error("name must not be nil")
                end

                return target.getItem({ name = name })
            end,
            listItems = function()
                return target.getItems()
            end
        }
    end)
end
