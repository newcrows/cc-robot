return function(robot, meta, constants)
    local SIDES = constants.sides
    local OPPOSITE_SIDES = constants.opposite_sides
    local RESERVED_INVENTORY_NAME = constants.reserved_inventory_name
    local UNKNOWN_ITEM = constants.unknown_item
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
    local EQUIPMENT_WARNING = "equipment_warning"

    local proxies = {}
    local nextSide = SIDES.right

    local function eventConstructor(detail)
        return meta.createEvent(EQUIPMENT_WARNING, detail)
    end

    local function getEquippedSide(itemName)
        local rightDetail = nativeTurtle.getEquippedRight()

        if rightDetail and rightDetail.name == itemName then
            return SIDES.right
        end

        local leftDetail = nativeTurtle.getEquippedLeft()

        if leftDetail and leftDetail.name == itemName then
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

        local detail = meta.getCustomPeripheralDetail(proxy.name)
        local constructor = detail and detail.constructor or nil

        if constructor then
            local opts = {
                name = proxy.name,
                side = side,
                target = target
            }

            target = constructor(opts)
        end

        proxy.side = side
        proxy.target = target
    end

    local function requireItemToEquip(itemName)
        local function check()
            return meta.selectFirstSlot(itemName .. "@" .. RESERVED_INVENTORY_NAME)
        end

        local function get()
            return { state = STATE.missing, name = itemName }
        end

        meta.require(check, get, eventConstructor)
    end

    local function equipAndSoftWrap(side, proxy)
        requireItemToEquip(proxy.name)

        local equipFunc = side == SIDES.right and nativeTurtle.equipRight or nativeTurtle.equipLeft
        equipFunc()

        meta.updateItemCount(proxy.name .. "@" .. RESERVED_INVENTORY_NAME, -1)

        local equippedProxy = getEquippedProxy(side)

        if equippedProxy then
            equippedProxy.side = nil
            equippedProxy.target = nil
        end

        softWrap(side, proxy)
        nextSide = OPPOSITE_SIDES[nextSide]
    end

    local function requireSpaceToUnequip(itemName)
        local function check()
            return meta.selectFirstEmptySlot(UNKNOWN_ITEM .. "@*")
        end

        local function get()
            return { state = STATE.no_space, name = itemName }
        end

        meta.require(check, get, eventConstructor)
    end

    local function createProxy(itemName, pinned)
        local proxy = {
            name = itemName
        }

        function proxy.use(wrapOnly)
            if proxy.invalid then
                error("equipment is not equipped any more", 0)
            end

            if proxy.target then
                return
            end

            local equippedSide = getEquippedSide(itemName)

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

            requireSpaceToUnequip(proxy.name)

            local equipFunc = proxy.side == SIDES.right and nativeTurtle.equipRight or nativeTurtle.equipLeft
            equipFunc()

            meta.updateItemCount(proxy.name .. "@" .. RESERVED_INVENTORY_NAME, 1)

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
        proxies[itemName] = proxy

        if pinned then
            proxy.pin()
        else
            proxy.use(true)
        end

        return proxy
    end

    function meta.requireEquipment(itemName)
        local function check()
            local rightDetail = nativeTurtle.getEquippedRight()

            if rightDetail and rightDetail.name == itemName then
                return true
            end

            local leftDetail = nativeTurtle.getEquippedLeft()

            if leftDetail and leftDetail.name == itemName then
                return true
            end

            return meta.getFirstSlot(itemName .. "@*") ~= nil
        end

        local function get()
            return { state = STATE.missing, name = itemName }
        end

        meta.require(check, get, eventConstructor)
    end

    function robot.equip(query, pinned)
        local itemName, invName = meta.parseQuery(query)
        local proxy = proxies[itemName]

        if proxy then
            if pinned then
                proxy.pin()
            end

            return proxy
        end

        meta.reserve(query, 1)
        return createProxy(itemName, pinned)
    end

    function robot.unequip(query)
        local itemName, invName = meta.parseQuery(query)
        local proxy = proxies[itemName]

        if proxy then
            proxy.unpin()
            proxy.unuse()

            proxies[itemName] = nil
            proxy.invalid = true

            meta.free(query, 1)
        end
    end

    function robot.getEquipmentDetail(query)
        local itemName = meta.parseQuery(query, nil, "*")
        return proxies[itemName]
    end

    function robot.listEquipment()
        local arr = {}

        for _, detail in pairs(proxies) do
            table.insert(arr, detail)
        end

        return arr
    end

    function robot.onEquipmentWarning(callback)
        meta.on(EQUIPMENT_WARNING, callback)
    end

    function robot.onEquipmentWarningCleared(callback)
        meta.on(EQUIPMENT_WARNING .. "_cleared", callback)
    end

    robot.onEquipmentWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local state = e.detail.state
        local name = e.detail.name

        if not alreadyWarned then
            print("---- " .. EQUIPMENT_WARNING .. " ----")

            if state == STATE.missing then
                print("missing: " .. name .. " (please insert)")
            elseif state == STATE.no_space then
                print("no space for " .. name .. " (please clear)")
            end
        end

        meta.sync()
    end)
    robot.onEquipmentWarningCleared(function()
        print("---- " .. EQUIPMENT_WARNING .. "_cleared ----")
    end)
end
