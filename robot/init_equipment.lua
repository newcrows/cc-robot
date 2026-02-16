return function(robot, meta, constants)
    local RAW_PROPERTIES = constants.raw_properties
    local SIDES = constants.sides
    local OPPOSITE_SIDES = constants.opposite_sides
    local proxies = {}
    local currentSide = SIDES.right

    local function wrap(side, name)
        local target = peripheral.wrap(side)
        local detail = meta.getPeripheralConstructorDetail(name)

        if detail then
            local opts = {
                robot = robot,
                meta = meta,
                constants = constants,
                name = name,
                side = side,
                target = target
            }

            target = detail.constructor(opts)
        end

        return target
    end

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

        if meta.getPeripheral(side) then
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

                meta.dispatchEvent("unwrap", swapSide, swapProxy.name, true)
            end
        end

        local proxy = proxies[name]

        proxy.side = side
        proxy.target = wrap(side, name)

        currentSide = OPPOSITE_SIDES[currentSide]

        meta.dispatchEvent("wrap", side, name)
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

        meta.dispatchEvent("unwrap", side, proxy.name)

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

        function proxy.use(wrapOnly)
            if proxy.target then
                return true
            end

            if name == getPhysicalEquippedName(SIDES.right) then
                proxy.side = SIDES.right
                proxy.target = wrap(SIDES.right, name)

                currentSide = SIDES.left
                meta.dispatchEvent("wrap", SIDES.right, name)
            elseif name == getPhysicalEquippedName(SIDES.left) then
                proxy.side = SIDES.left
                proxy.target = wrap(SIDES.left, name, true)

                currentSide = SIDES.right
                meta.dispatchEvent("wrap", SIDES.left, name)
            end

            if wrapOnly then
                return false
            end

            if not getPhysicalEquippedName(SIDES.right) then
                currentSide = SIDES.right
            elseif not getPhysicalEquippedName(SIDES.left) then
                currentSide = SIDES.left
            end

            if canEquip(name, currentSide) then
                return equip(name, currentSide)
            end

            currentSide = OPPOSITE_SIDES[currentSide]

            if canEquip(name, currentSide) then
                return equip(name, currentSide)
            end

            return false, "could not equip " .. name
        end

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
        name = name or robot.getSelectedName()
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
        name = name or robot.getSelectedName()
        local proxy = proxies[name]

        if proxy then
            local pinned = proxy.pinned

            if pinned then
                proxy.unpin()
            end

            local ok, err = proxy.unuse()

            if pinned and not ok then
                proxy.pin(true)
            end

            if not ok then
                return ok, err
            end

            proxy.use = nil
            proxies[name] = nil

            meta.dispatchEvent("unequip", name)
            return true
        end

        return true
    end

    function meta.getEquipmentDetail(name)
        name = name or robot.getSelectedName()
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
        name = name or robot.getSelectedName()
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
        local target = opts.target

        if not target then
            return nil
        end

        local function moveEquipmentOutOfTheWay()
            -- TODO [JM] fix this and impl
            return true
            --local lastEProxy = nil
            --local eCount = 0
            --
            --for eName, eProxy in pairs(meta.equipProxies) do
            --    local eSlot = meta.getFirstSlot(eName, true)
            --
            --    if eSlot then
            --        lastEProxy = eProxy
            --        eCount = eCount + eSlot.count
            --    end
            --end
            --
            --if eCount > 1 then
            --    return false, "can't move equipment out of the way"
            --end
            --
            --if lastEProxy then
            --    local ok, err = lastEProxy.use()
            --
            --    if not ok then
            --        return ok, err
            --    end
            --end
            --
            --return true
        end

        local function trim(recipe)
            return recipe:gsub("^%s*(.-)%s*$", "%1")
        end

        local function splitLinesAndTrimEach(trimmedRecipe)
            local lines = {}

            for line in trimmedRecipe:gmatch("[^\r\n]+") do
                line = trim(line)
                table.insert(lines, line)
            end

            return lines
        end

        local function splitAndReplaceCells(line, recipe)
            local cells = {}

            for cell in line:gmatch("%S+") do
                if recipe[cell] then
                    cell = recipe[cell]
                end

                if cell == "_" then
                    cell = "air"
                end

                table.insert(cells, cell)
            end

            return cells
        end

        local function parse(recipe)
            local trimmed = trim(recipe.pattern)
            local lines = splitLinesAndTrimEach(trimmed)
            local counts = {}
            local layout = {}

            for i = 1, #lines do
                local cells = splitAndReplaceCells(lines[i], recipe)

                for k = 1, #cells do
                    local slot = i * 4 + k - 4
                    local name = cells[k]

                    if name ~= "air" then
                        if not counts[name] then
                            counts[name] = 0
                        end

                        counts[name] = counts[name] + 1
                        layout[slot] = name
                    end
                end
            end

            return {
                counts = counts,
                layout = layout
            }
        end

        return {
            craft = function(recipe, limit)
                if not recipe then
                    error("recipe must not be nil")
                end

                local unlimited = limit == nil

                limit = limit or 64
                local ok, err = moveEquipmentOutOfTheWay()

                if not ok then
                    return false, err
                end

                meta.arrangeSlots(function(setSlot)
                    local parsed = parse(recipe)
                    local blacklist = {}
                    local offset = 0

                    for ingredientSlot, ingredientName in pairs(parsed.layout) do
                        local count = meta.countItems(ingredientName)

                        if count < parsed.counts[ingredientName] * limit and not unlimited then
                            return false, "missing " .. tostring(parsed.counts[ingredientName] * limit - count) .. " " .. ingredientName
                        end

                        if count < parsed.counts[ingredientName] and limit == 0 then
                            return false, "missing " .. tostring(parsed.counts[ingredientName]) .. " " .. ingredientName
                                    .. " to check whether the recipe is valid"
                        end

                        local amount = math.floor(count / parsed.counts[ingredientName])

                        if (count - offset) % amount > 0 then
                            amount = amount + 1
                            offset = offset + 1
                        end

                        ok, err = setSlot(ingredientSlot, ingredientName, amount)

                        if not ok then
                            return false, err
                        end

                        blacklist[ingredientSlot] = true
                    end

                    for i = 1, 16 do
                        if not blacklist[i] then
                            ok, err = setSlot(i, nil, 0)

                            if not ok then
                                return false, err
                            end
                        end
                    end
                end)

                return target.craft(limit)
            end
        }
    end

    -- specific constructors
    meta.setPeripheralConstructor("minecraft:diamond_pickaxe", digToolConstructor)
    meta.setPeripheralConstructor("minecraft:diamond_axe", digToolConstructor)
    meta.setPeripheralConstructor("minecraft:diamond_shovel", digToolConstructor)
    meta.setPeripheralConstructor("minecraft:diamond_sword", attackToolConstructor)
    meta.setPeripheralConstructor("minecraft:crafting_table", craftToolConstructor)
end
