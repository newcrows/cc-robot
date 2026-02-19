return function(robot, meta, constants)
    local SIDES = constants.sides

    local RAW_PROPERTIES = {
        side = true,
        name = true,
        target = true,
        use = true,
        unuse = true,
        pin = true,
        unpin = true
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

        local equipFunc = side == SIDES.right and turtle.equipRight or turtle.equipLeft
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
                return true
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
        end

        function proxy.pin()
        end

        function proxy.unpin()
        end

        local metatable = {
            __index = function(_, prop)
                if RAW_PROPERTIES[prop] then
                    return rawget(proxy, prop)
                end

                return function(...)
                    -- check whether we need to call use() here

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

    function robot.equip(name, pinned)
        name = name or robot.getSelectedName()
    end

    function robot.unequip(name)
        name = name or robot.getSelectedName()
    end
end
