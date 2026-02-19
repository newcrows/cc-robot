return function(robot, meta, constants)
    local SIDES = constants.sides
    local OPPOSITE_SIDES = constants.opposite_sides
    local RAW_PROPERTIES = {
        side = true,
        name = true,
        target = true,
        pinned = true,
        invalid = true,
        use = true,
        unuse = true,
        pin = true,
        unpin = true
    }
    local STATE = {
        missing = "missing",
        no_space = "no_space"
    }

    local proxies = {}
    local nextSide = SIDES.right
    local equipmentWarningListenerId
    local equipmentWarningClearedListenerId

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

    local function getEquippedProxy(side)
        for _, proxy in pairs(proxies) do
            if proxy.target and proxy.side == side then
                return proxy
            end
        end
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
                name = proxy.name,
                side = side,
                target = target
            }

            target = constructor(opts)
        end

        proxy.side = side
        proxy.target = target
    end

    local function checkEquipment(check, state, name)
        local waited = false

        while not check() do
            if waited then
                os.sleep(1)
            end

            meta.dispatchEvent("equipment_warning", state, name, waited)
            waited = true
        end

        meta.dispatchEvent("equipment_warning_cleared")
    end

    local function equipAndSoftWrap(side, proxy)
        local function check()
            return meta.selectFirstSlot(proxy.name, true)
        end

        checkEquipment(check, STATE.missing, proxy.name)

        local equipFunc = side == SIDES.right and nativeTurtle.equipRight or nativeTurtle.equipLeft
        equipFunc()

        local equippedProxy = getEquippedProxy(side)

        if equippedProxy then
            equippedProxy.side = nil
            equippedProxy.target = nil
        end

        softWrap(side, proxy)
        nextSide = OPPOSITE_SIDES[nextSide]
    end

    local function createProxy(name, pinned)
        local proxy = {
            name = name
        }

        function proxy.use(wrapOnly)
            if proxy.invalid then
                error("equipment is not equipped any more", 0)
            end

            if proxy.target then
                return
            end

            local equippedSide = getEquippedSide(name)

            if equippedSide then
                softWrap(equippedSide, proxy)
                return
            end

            if wrapOnly then
                return
            end

            local emptySide = getEmptySide()

            if emptySide then
                equipAndSoftWrap(emptySide, proxy)
                return
            end

            local equippedProxy = getEquippedProxy(nextSide)

            if equippedProxy and equippedProxy.pinned then
                nextSide = OPPOSITE_SIDES[nextSide]
                equippedProxy = getEquippedProxy(nextSide)

                if equippedProxy and equippedProxy.pinned then
                    error("both sides are pinned", 0)
                end
            end

            equipAndSoftWrap(nextSide, proxy)
        end

        function proxy.unuse()
            if not proxy.target then
                return
            end

            if proxy.pinned then
                error("can't unuse pinned equipment", 0)
            end

            local function check()
                return meta.selectFirstEmptySlot(true)
            end

            checkEquipment(check, STATE.no_space, proxy.name)

            local equipFunc = proxy.side == SIDES.right and nativeTurtle.equipRight or nativeTurtle.equipLeft
            equipFunc()

            proxy.side = nil
            proxy.target = nil
        end

        function proxy.pin()
            proxy.use()
            proxy.pinned = true
        end

        function proxy.unpin()
            proxy.pinned = false
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

        if pinned then
            proxy.pin()
        else
            proxy.use(true)
        end

        return proxy
    end

    function robot.equip(name, pinned)
        name = name or robot.getSelectedName()

        if type(name) == "table" then
            proxies[name] = name
            name.invalid = nil

            robot.reserve(name, 1)
            name.use(true)
        end

        local proxy = proxies[name]

        if proxy then
            if pinned then
                proxy.pin()
            end

            return proxy
        end

        robot.reserve(name, 1)
        return createProxy(name, pinned)
    end

    function robot.unequip(name)
        name = name or robot.getSelectedName()
        local proxy = proxies[name]

        if proxy then
            proxy.unpin()
            proxy.unuse()

            proxies[name] = nil
            proxy.invalid = true

            robot.free(name, 1)
        end
    end

    function robot.onEquipmentWarning(callback)
        if equipmentWarningListenerId then
            meta.removeEventListener(equipmentWarningListenerId)
            equipmentWarningListenerId = nil
        end

        if callback then
            equipmentWarningListenerId = meta.addEventListener({
                equipment_warning = callback
            })
        end
    end

    function robot.onEquipmentWarningCleared(callback)
        if equipmentWarningClearedListenerId then
            meta.removeEventListener(equipmentWarningClearedListenerId)
            equipmentWarningClearedListenerId = nil
        end

        if callback then
            equipmentWarningClearedListenerId = meta.addEventListener({
                equipment_warning_cleared = callback
            })
        end
    end

end
