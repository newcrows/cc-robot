return function(robot, meta, constants)
    local RAW_PROPERTIES = constants.raw_properties
    local SIDES = constants.sides
    local OPPOSITE_SIDES = constants.opposite_sides
    local proxies = {}

    local function getPhysicalEquippedName(side)
        local getEquippedFuncs = {
            [SIDES.right] = turtle.getEquippedRight,
            [SIDES.left] = turtle.getEquippedLeft,
        }

        local getEquippedFunc = getEquippedFuncs[side]
        local detail = getEquippedFunc()

        return detail and detail.name or nil
    end

    local function equipPhysical(side)
        local equipFuncs = {
            [SIDES.right] = turtle.equipRight,
            [SIDES.left] = turtle.equipLeft,
        }

        local equipFunc = equipFuncs[side]
        return equipFunc()
    end

    local function canEquip(name, side)
        local proxy = proxies[name]

        if proxy.target then
            return true
        end

        if meta.getWrappedPeripheral(side) then
            return false, name .. " can not be equipped because a peripheral is bound on " .. side
        end

        local slot = meta.getFirstSlot(name, true)

        if not slot then
            return false, name .. " can not be equipped because it was not found in inventory"
        end

        local swapName = getPhysicalEquippedName(side)

        if not swapName then
            return true
        end

        local swapProxy = proxies[swapName]

        if swapProxy and swapProxy.pinned then
            return false, swapName .. " can not be unequipped because it is pinned"
        end

        -- NOTE [JM] offset by +1 because getItemSpace returns -1 for equipped equipment
        local swapSpace = robot.getItemSpace(swapName) + 1

        if slot.count > 1 and swapSpace == 0 then
            return false, swapName .. " can not be unequipped because there is no space in inventory"
        end

        return true
    end

    local function equip(name, side)
        local slot = meta.getFirstSlot(name, true)

        if not slot then
            return false, name .. " not found in inventory"
        end

        turtle.select(slot.id)

        local swapName = getPhysicalEquippedName(side)
        local ok, err = equipPhysical(side)

        if not ok then
            return false, err
        end

        if swapName then
            local swapProxy = proxies[swapName]

            if swapProxy then
                local swapSide = swapProxy.side

                swapProxy.side = nil
                swapProxy.target = nil

                meta.dispatchEvent("unwrap", swapProxy.name, swapSide, true)
            end
        end

        local proxy = proxies[name]

        proxy.side = side
        proxy.target = meta.wrap(name, side, true)

        meta.equipSide = OPPOSITE_SIDES[meta.equipSide]
        return true
    end

    local function canUnequip(proxy)
        if not proxy.target then
            return true
        end

        if proxy.pinned then
            return false, proxy.name .. " can not be unequipped because it is pinned"
        end

        for swapName, swapProxy in pairs(proxies) do
            if not swapProxy.target and canEquip(swapName, proxy.side) then
                return true
            end
        end

        -- NOTE [JM] offset by +1 because getItemSpace returns -1 for equipped equipment
        local space = robot.getItemSpace(proxy.name) + 1

        if space == 0 then
            return false, proxy.name .. " can not be unequipped because there is no space in inventory"
        end

        return true
    end

    local function unequip(proxy)
        for swapName, swapProxy in pairs(proxies) do
            if not swapProxy.target and canEquip(swapName, proxy.side) then
                return equip(swapName, proxy.side)
            end
        end

        local slot = meta.getFirstEmptySlot()

        if not slot then
            return false, "could not unequip " .. proxy.name .. " because there is no space in inventory"
        end

        turtle.select(slot.id)

        local ok, err = proxy.side == SIDES.right and turtle.equipRight() or turtle.equipLeft()

        if not ok then
            return false, err
        end

        local side = proxy.side

        proxy.side = nil
        proxy.target = nil

        meta.dispatchEvent("unwrap", proxy.name, side, true)

        return true
    end

    local function createEquipProxy(name)
        local proxy = {
            name = name,
            side = nil,
            target = nil,
            pinned = false
        }

        function proxy.pin(virtualOnly)
            if not virtualOnly then
                local ok, err = proxy.use()
                assert(ok, err)
            end

            proxy.pinned = true
            return true
        end

        function proxy.unpin()
            proxy.pinned = false
            return true
        end

        -- TODO [JM] impl proxy.use here

        function proxy.unuse()
            if not proxy.target then
                return true
            end

            if canUnequip(proxy) then
                return unequip(proxy)
            end

            return false
        end

        local metatable = {
            __index = function(_, key)
                if RAW_PROPERTIES[key] then
                    return rawget(proxy, key)
                end

                return function(...)
                    -- NOTE [JM] proxy.target check for performance reasons
                    if not proxy.target then
                        local ok, err = proxy.use()
                        assert(ok, err)
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

    function robot.equip(name, pinned)
        name = name or meta.selectedName
        local proxy = proxies[name]

        if not proxy then
            proxy = createEquipProxy(name)
            proxies[name] = proxy

            proxy.use(true)

            if pinned then
                proxy.pin()
            end

            meta.dispatchEvent("equip", name)
        elseif pinned then
            proxy.pin()
        end

        return proxy
    end

    function robot.unequip(name)
        name = name or meta.selectedName
        -- TODO [JM] implement
    end

    function meta.getEquipmentDetail(name)
        name = name or meta.selectedName
        local proxy = proxies[name]

        if proxy then
            return {
                name = name,
                proxy = proxy
            }
        end

        return nil
    end

    function meta.hasEquipment(name)
        name = name or meta.selectedName
        return meta.getEquipmentDetail(name) and true or false
    end

    function meta.listEquipment()
        local arr = {}

        for name, proxy in pairs(proxies) do
            table.insert(arr, {
                name = name,
                proxy = proxy
            })
        end

        return arr
    end

    local digToolConstructor = function()
        local function dig_0(digFunc, blocking)
            if blocking then
                while not digFunc() do
                    sleep(1)
                end

                return true
            end

            return digFunc()
        end

        local function dig(digFunc, blocking, side)
            meta.softUnwrap(side)

            local ok, err = dig_0(digFunc, blocking)

            if ok then
                meta.unwrap(side)
            else
                meta.softWrap(side)
            end

            return ok, err
        end

        return {
            dig = function(blocking)
                return dig(turtle.dig, blocking, SIDES.front)
            end,
            digUp = function(blocking)
                return dig(turtle.digUp, blocking, SIDES.top)
            end,
            digDown = function(blocking)
                return dig(turtle.digDown, blocking, SIDES.bottom)
            end
        }
    end

    local attackToolConstructor = function()
        local function attack_0(attackFunc, blocking)
            if blocking then
                while not attackFunc() do
                    sleep(1)
                end

                return true
            end

            return attackFunc()
        end

        local function attack(attackFunc, blocking, side)
            meta.softUnwrap(side)

            local ok, err = attack_0(attackFunc, blocking)

            if ok then
                meta.unwrap(side)
            else
                meta.softWrap(side)
            end

            return ok, err
        end

        return {
            attack = function(blocking)
                return attack(turtle.attack, blocking, SIDES.front)
            end,
            attackUp = function(blocking)
                return attack(turtle.attackUp, blocking, SIDES.top)
            end,
            attackDown = function(blocking)
                return attack(turtle.attackDown, blocking, SIDES.bottom)
            end
        }
    end

    local craftToolConstructor = function(opts)
        -- TODO [JM] implement
    end

    -- generic constructors
    meta.setWrapConstructor("dig_tool", digToolConstructor)
    meta.setWrapConstructor("attack_tool", attackToolConstructor)
    meta.setWrapConstructor("craft_tool", craftToolConstructor)

    -- specific constructors
    meta.setWrapConstructor("minecraft:diamond_pickaxe", digToolConstructor)
    meta.setWrapConstructor("minecraft:diamond_axe", digToolConstructor)
    meta.setWrapConstructor("minecraft:diamond_shovel", digToolConstructor)
    meta.setWrapConstructor("minecraft:diamond_sword", attackToolConstructor)
    meta.setWrapConstructor("minecraft:crafting_table", craftToolConstructor)
end
