return function(robot, meta, constants)
    local SIDES = constants.sides
    local RAW_PROPERTIES = {
        side = true,
        name = true,
        target = true,
        use = true,
        unuse = true
    }

    local proxies = {}
    local nextSide = SIDES.right

    local function getEquippedSide(name)
        local rightDetail = nativeTurtle.getEquippedRight()

        if rightDetail and rightDetail.name == name then
            return SIDES.right
        end

        local leftDetail = nativeTurtle.getEquippedLeft()

        if leftDetail and leftDetail.name == name then
            return SIDES.left
        end

        return nil
    end

    local function getEmptySide()
        if not nativeTurtle.getEquippedRight() then
            return SIDES.right
        end

        if not nativeTurtle.getEquippedLeft() then
            return SIDES.left
        end

        return nil
    end

    local function softWrap(side, proxy)
        local target = peripheral.wrap(side)

        local constructorDetail = meta.getPeripheralConstructorDetail(proxy.name)
        local constructor = constructorDetail and constructorDetail.constructor or nil

        if constructor then
            local opts = {
                robot = robot,
                meta = meta,
                constants = constants,
                side = side,
                target = target
            }

            target = constructor(opts)
        end

        proxy.side = side
        proxy.target = target
    end

    local function equipAndSoftWrap(side, proxy)
        if not meta.selectFirstSlot(proxy.name, true) then
            error("equipment not found in inventory", 0)
        end

        local equipFunc = side == SIDES.right and nativeTurtle.equipRight or nativeTurtle.equipLeft
        equipFunc()

        softWrap(side, proxy)
        nextSide = nextSide == SIDES.right and SIDES.left or SIDES.right
    end

    local function createProxy(name)
        local proxy = {
            name = name
        }

        function proxy.use()
            if proxy.target then
                return
            end

            local equippedSide = getEquippedSide(name)

            if equippedSide then
                softWrap(equippedSide, proxy)
                return
            end

            local emptySide = getEmptySide()

            if emptySide then
                equipAndSoftWrap(emptySide, proxy)
                return
            end

            equipAndSoftWrap(nextSide, proxy)
        end

        function proxy.unuse()
            if not proxy.target then
                return
            end

            if not meta.selectFirstEmptySlot(true) then
                error("no space in inventory", 0)
            end

            local equipFunc = proxy.side == SIDES.right and nativeTurtle.equipRight or nativeTurtle.equipLeft
            equipFunc()

            proxy.side = nil
            proxy.target = nil
        end

        local metatable = {
            __index = function(_, prop)
                if RAW_PROPERTIES[prop] then
                    return rawget(proxy, prop)
                end

                return function(...)
                    proxy.use()
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
        proxies[name] = proxy

        return proxy
    end

    function robot.equip(name)
        name = name or robot.getSelectedName()
        return createProxy(name)
    end

    function robot.unequip(name)
        name = name or robot.getSelectedName()
        local proxy = proxies[name]

        if proxy and proxy.target then
            proxy.unuse()

            -- need to make the proxy invalid somehow
            -- must be restore-able when robot.equip(proxy) is called later
            -- to stay consistent with robot.wrap(peripheral) restoring the peripheral
            proxies[name] = nil
        end
    end
end
