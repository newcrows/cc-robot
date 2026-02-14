local DELTAS = {
    north = { x = 0, y = 0, z = -1 },
    east = { x = 1, y = 0, z = 0 },
    south = { x = 0, y = 0, z = 1 },
    west = { x = -1, y = 0, z = 0 },
    up = { x = 0, y = 1, z = 0 },
    down = { x = 0, y = -1, z = 0 }
}
local FACINGS = {
    [0] = "north",
    [1] = "east",
    [2] = "south",
    [3] = "west",
    [4] = "up",
    [5] = "down",
    north = 0,
    east = 1,
    south = 2,
    west = 3,
    up = 4,
    down = 5
}
local OPPOSITE_FACINGS = {
    north = "south",
    east = "west",
    south = "north",
    west = "east",
    up = "down",
    down = "up"
}
local SIDES = {
    front = "front",
    right = "right",
    back = "back",
    left = "left",
    top = "top",
    bottom = "bottom"
}
local OPPOSITE_SIDES = {
    front = "back",
    right = "left",
    back = "front",
    left = "right",
    top = "bottom",
    bottom = "top"
}
local RAW_PROPERTIES = {
    name = true,
    side = true,
    target = true,
    pinned = true,
    use = true,
    unuse = true,
    pin = true,
    unpin = true
}

local robot = {
    strict = true,
    version = "1.0.0",
    x = 0,
    y = 0,
    z = 0,
    facing = "north"
}
local meta = {
    selectedName = nil,
    equipProxies = {},
    equipSide = SIDES.right,
    peripheralConstructors = {},
    reservedItemSpaces = {},
    eventListeners = {},
    nextEventListenerId = 1,
    wrapProxies = {}
}

robot.meta = meta

local digConstructor = function()
    return {
        dig = function()
            meta.softUnwrap(SIDES.front)

            if turtle.dig() then
                meta.unwrap(SIDES.front)
                return true
            else
                meta.softWrap(SIDES.front)
            end

            return false
        end,
        digUp = function()
            meta.softUnwrap(SIDES.top)

            if turtle.digUp() then
                meta.unwrap(SIDES.top)
                return true
            else
                meta.softWrap(SIDES.top)
            end

            return false
        end,
        digDown = function()
            meta.softUnwrap(SIDES.bottom)

            if turtle.digDown() then
                meta.unwrap(SIDES.bottom)
                return true
            else
                meta.softWrap(SIDES.bottom)
            end

            return false
        end
    }
end

meta.peripheralConstructors["minecraft:diamond_pickaxe"] = digConstructor
meta.peripheralConstructors["minecraft:diamond_axe"] = digConstructor
meta.peripheralConstructors["minecraft:diamond_shovel"] = digConstructor
meta.peripheralConstructors["minecraft:diamond_sword"] = function()
    return {
        attack = turtle.attack,
        attackUp = turtle.attackUp,
        attackDown = turtle.attackDown
    }
end
meta.peripheralConstructors["minecraft:crafting_table"] = function(opts)
    local target = opts.target

    if not target then
        return nil
    end

    local function moveEquipmentOutOfTheWay()
        local lastEProxy = nil
        local eCount = 0

        for eName, eProxy in pairs(meta.equipProxies) do
            local eSlot = meta.getFirstSlot(eName, true)

            if eSlot then
                lastEProxy = eProxy
                eCount = eCount + eSlot.count
            end
        end

        if eCount > 1 then
            return false, "can't move equipment out of the way"
        end

        if lastEProxy then
            local ok, err = lastEProxy.use()

            if not ok then
                return ok, err
            end
        end

        return true
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

            local parsed = parse(recipe)
            local blacklist = {}

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

                ok, err = meta.setSlot(ingredientSlot, ingredientName, amount, blacklist)

                if not ok then
                    return false, err
                end

                blacklist[ingredientSlot] = true
            end

            local reverseBlacklist = {}

            for i = 1, 16 do
                if not blacklist[i] then
                    ok, err = meta.setSlot(i, nil, 0, reverseBlacklist)

                    if not ok then
                        return false, err
                    end

                    reverseBlacklist[i] = true
                end
            end

            return target.craft(limit)
        end
    }
end
meta.peripheralConstructors["advancedperipherals:me_bridge"] = function(opts)
    local side = opts.side
    local target = opts.target

    if not target then
        return nil
    end

    local facing

    if side == "front" then
        facing = robot.facing
    elseif side == "top" then
        facing = FACINGS.up
    elseif side == "bottom" then
        facing = FACINGS.down
    else
        error("invalid side " .. side)
    end

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
end

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

local function softUnwrapAllWrapProxies()
    for wrappedSide, _ in pairs(meta.wrapProxies) do
        meta.softUnwrap(wrappedSide)
    end
end

local function softWrapAllWrapProxies()
    for wrappedSide, _ in pairs(meta.wrapProxies) do
        meta.softWrap(wrappedSide)
    end
end

local function unwrapAllWrapProxies()
    for wrappedSide, _ in pairs(meta.wrapProxies) do
        meta.unwrap(wrappedSide)
    end
end

local function unwrapNotPresentWrapProxies()
    for wrappedSide, _ in pairs(meta.wrapProxies) do
        if not peripheral.isPresent(wrappedSide) then
            meta.unwrap(wrappedSide)
        end
    end
end

local function getName(side)
    if not side then
        error("side must not be nil")
    end

    local inspectFunc

    if side == robot.facing then
        inspectFunc = turtle.inspect
    elseif side == SIDES.front then
        inspectFunc = turtle.inspect
    elseif side == SIDES.top then
        inspectFunc = turtle.inspectUp
    elseif side == SIDES.bottom then
        inspectFunc = turtle.inspectDown
    elseif side == SIDES.right then
        inspectFunc = function()
            return nil, turtle.getEquippedRight()
        end
    elseif side == SIDES.left then
        inspectFunc = function()
            return nil, turtle.getEquippedLeft()
        end
    elseif side == SIDES.back then
        error("can not get name for " .. side)
    end

    local _, detail = inspectFunc()
    return detail and detail.name or nil
end

local function sync()
    for name, proxy in pairs(meta.equipProxies) do
        if proxy.target and name ~= getName(proxy.side) then
            if proxy.pinned then
                error("pinned " .. name .. " was removed illegally")
            end

            local side = proxy.side

            proxy.side = nil
            proxy.target = nil

            meta.dispatchEvent("unwrap", proxy.name, side, true)
        end
    end
end

local function isEmpty(side)
    if not side then
        error("side must not be nil")
    end

    local detail = side == SIDES.right and turtle.getEquippedRight() or turtle.getEquippedLeft()
    return detail == nil
end

-- NOTE [JM] assumes sync() was called beforehand (in strict mode)
local function canEquip(name, side)
    if not name then
        error("name must not be nil")
    end

    if not side then
        error("side must not be nil")
    end

    local proxy = meta.equipProxies[name]

    if not proxy then
        error("proxy must not be nil")
    end

    if proxy.target then
        return true
    end

    if meta.wrapProxies[side] then
        return false, name .. " can not be equipped because a peripheral is bound on " .. side
    end

    local slot = meta.getFirstSlot(name, true)

    if not slot then
        return false, name .. " can not be equipped because it was not found in inventory"
    end

    local swapName = getName(side)

    if not swapName then
        return true
    end

    local swapProxy = meta.equipProxies[swapName]

    if swapProxy and swapProxy.pinned then
        return false, swapName .. " can not be unequipped because it is pinned"
    end

    local swapSpace = robot.getItemSpace(swapName)

    if slot.count > 1 and swapSpace == 0 then
        return false, swapName .. " can not be unequipped because there is no space in inventory"
    end

    return true
end

-- NOTE [JM] assumes name IS NOT equipped
local function equip(name, side)
    if not name then
        error("name must not be nil")
    end

    if not side then
        error("side must not be nil")
    end

    local slot = meta.getFirstSlot(name, true)

    if not slot then
        return false, name .. " not found in inventory"
    end

    turtle.select(slot.id)

    local swapName = getName(side)
    local ok, err = side == SIDES.right and turtle.equipRight() or turtle.equipLeft()

    if not ok then
        return false, err
    end

    if swapName then
        local swapProxy = meta.equipProxies[swapName]

        if swapProxy then
            local swapSide = swapProxy.side

            swapProxy.side = nil
            swapProxy.target = nil

            meta.dispatchEvent("unwrap", swapProxy.name, swapSide, true)
        end
    end

    local proxy = meta.equipProxies[name]

    proxy.side = side
    proxy.target = meta.wrap(name, side, true)

    meta.equipSide = OPPOSITE_SIDES[meta.equipSide]
    return true
end

-- NOTE [JM] assumes sync() was called beforehand (in strict mode)
local function canUnequip(proxy)
    if not proxy then
        error("proxy must not be nil")
    end

    if not proxy.target then
        return true
    end

    if proxy.pinned then
        return false, proxy.name .. " can not be unequipped because it is pinned"
    end

    for swapName, swapProxy in pairs(meta.equipProxies) do
        if not swapProxy.target and canEquip(swapName, proxy.side) then
            return true
        end
    end

    local space = robot.getItemSpace(proxy.name)

    if space == 0 then
        return false, proxy.name .. " can not be unequipped because there is no space in inventory"
    end

    return true
end

-- NOTE [JM] assumes proxy IS equipped
local function unequip(proxy)
    if not proxy then
        error("proxy must not be nil")
    end

    for swapName, swapProxy in pairs(meta.equipProxies) do
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
    if not name then
        error("name must not be nil")
    end

    local proxy = {
        name = name,
        pinned = false,
        side = nil,
        target = nil
    }

    function proxy.use(wrapOnly)
        if robot.strict then
            -- programs can do some weird stuff with slotted equipment, like temporarily removing it
            -- external forces (like the player) can also remove equipment at any time
            -- so we should make sure we sync() before we access the inventory
            sync()
        end

        if proxy.target then
            return true
        end

        if name == getName(SIDES.right) then
            proxy.side = SIDES.right
            proxy.target = meta.wrap(name, SIDES.right, true)

            meta.equipSide = SIDES.left
        end

        if name == getName(SIDES.left) then
            proxy.side = SIDES.left
            proxy.target = meta.wrap(name, SIDES.left, true)

            meta.equipSide = SIDES.right
        end

        if wrapOnly then
            return false
        end

        if isEmpty(SIDES.right) then
            meta.equipSide = SIDES.right
        elseif isEmpty(SIDES.left) then
            meta.equipSide = SIDES.left
        end

        if canEquip(name, meta.equipSide) then
            return equip(name, meta.equipSide)
        end

        meta.equipSide = OPPOSITE_SIDES[meta.equipSide]

        if canEquip(name, meta.equipSide) then
            return equip(name, meta.equipSide)
        end

        return false, "could not equip " .. name
    end

    function proxy.unuse()
        if robot.strict then
            -- programs can do some weird stuff with slotted equipment, like temporarily removing it
            -- external forces (like the player) can also remove equipment at any time
            -- so we should make sure we sync() before we access the inventory
            sync()
        end

        if not proxy.target then
            return true
        end

        if canUnequip(proxy) then
            return unequip(proxy)
        end

        return false
    end

    function proxy.pin(virtualOnly)
        if not virtualOnly then
            local ok, err = proxy.use()

            if not ok then
                error(err)
            end
        end

        proxy.pinned = true
        return true
    end

    function proxy.unpin()
        proxy.pinned = false
        return true
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

                    if not ok then
                        error(err)
                    end
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

local function dropHelper(name, count, dropFunc)
    if not name then
        error("name must not be nil")
    end

    if not dropFunc then
        error("dropFunc must not be nil")
    end

    count = count or robot.getItemCount(name)
    local amount = 0

    while amount < count do
        local ok, err = meta.selectFirstSlot(name)

        if not ok then
            return amount, err
        end

        local itemCount = turtle.getItemCount()
        local dropCount = math.min(count - amount, itemCount)

        ok, err = dropFunc(dropCount)

        if not ok then
            return amount, err
        end

        local dropAmount = itemCount - turtle.getItemCount()

        if dropAmount == 0 then
            return amount, "nothing dropped further"
        end

        amount = amount + dropAmount
    end

    return amount
end

local function compareHelper(name, inspectFunc)
    if not name then
        error("name must not be nil")
    end

    if not inspectFunc then
        error("inspectFunc must not be nil")
    end

    local blockExists, blockDetail = inspectFunc()

    if blockExists and blockDetail.name == name then
        return true
    elseif not blockExists and name == "air" then
        return true
    end

    return false
end

local function suckHelper(count, suckFunc)
    if not suckFunc then
        error("suckFunc must not be nil")
    end

    count = count or 9999
    local amount = 0

    while amount < count do
        local rawCount = meta.countItems()
        local suckCount = math.min(count - amount, 64)

        local ok, err = suckFunc(suckCount)

        if not ok then
            if count == 9999 then
                return amount
            end

            return amount, err
        end

        amount = amount + meta.countItems() - rawCount
    end

    return amount
end

local function equipHelper(name, pinned)
    if not name then
        error("name must not be nil")
    end

    local proxy = meta.equipProxies[name]

    if not proxy then
        proxy = createEquipProxy(name)
        meta.equipProxies[name] = proxy

        proxy.use(true)

        if pinned then
            proxy.pin()
        end

        meta.dispatchEvent("equip", name, pinned)
    elseif pinned then
        proxy.pin()
    end

    return proxy
end

local function unequipHelper(name)
    if not name then
        error("name must not be nil")
    end

    local proxy = meta.equipProxies[name]

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
        meta.equipProxies[name] = nil

        meta.dispatchEvent("unequip", name)
        return true
    end

    return true
end

function meta.dispatchEvent(name, ...)
    for _, listener in pairs(meta.eventListeners) do
        local func = listener[name]

        if func then
            func(...)
        end
    end
end

-- NOTE [JM] custom code MAY NEVER wrap equipment, only blocks
-- isEquipment flag MUST ONLY be used by internal equipment rotation logic
function meta.wrap(name, side, isEquipment)
    if not name then
        error("name must not be nil")
    end

    if not side then
        error("side must not be nil")
    end

    local constructor = meta.peripheralConstructors[name]
    local target = peripheral.wrap(side)

    if constructor then
        local opts = {
            robot = robot,
            meta = meta,
            name = name,
            side = side,
            target = target,
            wrappedAsEquipment = isEquipment
        }

        -- most constructors should return nil if opts.target is nil
        -- only targets that are not peripherals (i.E. pickaxe) should behave differently
        target = constructor(opts)
    end

    if target then
        if not isEquipment then
            target = createWrapProxy(name, side, target)
            meta.wrapProxies[side] = target
        end

        meta.dispatchEvent("wrap", name, side, isEquipment)
    end

    return target
end

function meta.unwrap(side)
    if not side then
        error("side must not be nil")
    end

    local wrapProxy = meta.wrapProxies[side]

    if wrapProxy then
        wrapProxy.side = nil
        wrapProxy.target = nil

        meta.wrapProxies[side] = nil
        meta.dispatchEvent("unwrap", wrapProxy.name, side)
    end

    return true
end

function meta.softWrap(side)
    if not side then
        error("side must not be nil")
    end

    local proxy = meta.wrapProxies[side]

    if proxy then
        local constructor = meta.peripheralConstructors[proxy.name]
        local target = peripheral.wrap(side)

        if constructor then
            local opts = {
                robot = robot,
                meta = meta,
                name = proxy.name,
                side = side,
                target = target
            }

            target = constructor(opts)
        end

        proxy.target = target
        meta.dispatchEvent("softWrap", proxy.name, side)
    end

    return true
end

function meta.softUnwrap(side)
    if not side then
        error("side must not be nil")
    end

    local proxy = meta.wrapProxies[side]

    if proxy then
        proxy.side = nil
        proxy.target = nil

        meta.dispatchEvent("softUnwrap", proxy.name, side)
    end

    return true
end

function meta.listSlots(filter, limit, includeEquipment, includeHiddenItems)
    limit = limit or 16

    local slots = {}
    local seenEquipment = {}
    local seenInvisibleItems = {}

    if robot.strict then
        -- programs can do some weird stuff with slotted equipment, like temporarily removing it
        -- external forces (like the player) can also remove equipment at any time
        -- so we should make sure we sync() before we access the inventory
        sync()

        -- programs can do some weird stuff inside event listeners that may change inventory contents,
        -- external forces (like the player) can also take or mine peripheral blocks at any time
        -- so we should make sure we unwrapNotPresentWrappedNames() before we access the inventory
        unwrapNotPresentWrapProxies()
    end

    for i = 1, 16 do
        local detail = turtle.getItemDetail(i)

        if detail and not filter or detail and detail.name == filter then
            local countOffset = 0

            if not includeEquipment and not seenEquipment[detail.name] then
                local equipProxy = meta.equipProxies[detail.name]

                if equipProxy and not equipProxy.target then
                    countOffset = -1
                    seenEquipment[detail.name] = true
                end
            end

            if not includeHiddenItems then
                local invisibleCount = meta.reservedItemSpaces[detail.name]
                local seenInvisibleCount = seenInvisibleItems[detail.name] or 0

                if invisibleCount and seenInvisibleCount < invisibleCount then
                    local invisibleCountOffset = -math.min(detail.count + countOffset, invisibleCount - seenInvisibleCount)

                    countOffset = countOffset + invisibleCountOffset
                    seenInvisibleItems[detail.name] = seenInvisibleCount - invisibleCountOffset
                end
            end

            local adjustedCount = turtle.getItemCount(i) + countOffset

            if adjustedCount > 0 then
                table.insert(slots, {
                    id = i,
                    name = detail.name,
                    count = adjustedCount,
                    space = turtle.getItemSpace(i)
                })
            end

            if #slots == limit then
                return slots
            end
        end
    end

    return slots
end

function meta.listEmptySlots(limit, skipCompact)
    limit = limit or 16
    local slots = {}

    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            table.insert(slots, {
                id = i,
                count = 0,
                space = 64
            })

            if #slots == limit then
                return slots
            end
        end
    end

    if #slots == 0 and not skipCompact then
        meta.compact()
        return meta.listEmptySlots(limit, true)
    end

    return slots
end

function meta.getFirstSlot(name, includeEquipment, includeHiddenItems)
    local slots = meta.listSlots(name, 1, includeEquipment, includeHiddenItems)

    if #slots == 1 then
        return slots[1]
    else
        return nil
    end
end

function meta.getFirstEmptySlot()
    local slots = meta.listEmptySlots(1)

    if #slots == 1 then
        return slots[1]
    else
        return nil
    end
end

function meta.selectFirstSlot(name, includeEquipment, includeHiddenItems)
    local slot = meta.getFirstSlot(name, includeEquipment, includeHiddenItems)

    if slot then
        return turtle.select(slot.id)
    else
        return false, name .. " not found in inventory"
    end
end

function meta.selectFirstEmptySlot()
    local slot = meta.getFirstEmptySlot()

    if slot then
        return turtle.select(slot.id)
    else
        return false, "no empty slot found in inventory"
    end
end

function meta.countItems(filter, includeEquipment, includeHiddenItems)
    local count = 0
    local slots = meta.listSlots(filter, 16, includeEquipment, includeHiddenItems)

    for i = 1, #slots do
        count = count + slots[i].count
    end

    return count
end

function meta.compact()
    local slots = meta.listSlots(nil, nil, true)

    for i = #slots, 1, -1 do
        local slot = slots[i]
        local likeSlots = meta.listSlots(slot.name, nil, true)

        for k = #likeSlots, 1, -1 do
            local likeSlot = likeSlots[k]

            if slot.id > likeSlot.id then
                local likeSpace = likeSlot.space

                if likeSpace > 0 then
                    turtle.select(slot.id)
                    turtle.transferTo(likeSlot.id, likeSpace)

                    if turtle.getItemCount() == 0 then
                        break
                    end
                end
            end
        end
    end
end

function meta.setSlot(slotId, name, count, blacklist)
    if not slotId then
        error("slotId must not be nil")
    end

    if name == "air" then
        name = nil
    end

    if not name then
        count = 0
    elseif not count then
        count = meta.countItems(name, true, true)
    end

    if count == nil then
        error("count must not be nil")
    end

    blacklist = blacklist or {}

    local detail = turtle.getItemDetail(slotId)
    local slot = {
        name = detail and detail.name or nil,
        count = turtle.getItemCount(slotId),
        space = turtle.getItemSpace(slotId)
    }

    local sameSlots = {}
    local candidateSlots = meta.listSlots(name, 16, true, true)

    for i = 1, #candidateSlots do
        local candidateSlot = candidateSlots[i]

        if slotId ~= candidateSlot.id and not blacklist[candidateSlot.id] then
            table.insert(sameSlots, candidateSlot)
        end
    end

    if slot.name == name and slot.count > count then
        turtle.select(slotId)

        -- try to move surplus to slots holding the same item
        local amount = 0
        local surplusAmount = slot.count - count

        for _, sameSlot in ipairs(sameSlots) do
            local sameSpace = sameSlot.space
            local movableAmount = math.min(surplusAmount - amount, sameSpace)

            if movableAmount > 0 then
                if turtle.transferTo(sameSlot.id, movableAmount) then
                    amount = amount + movableAmount
                end
            end

            if amount == surplusAmount then
                return true
            end
        end

        -- try to move remaining surplus to the first non-blacklisted empty slot
        -- DO NOT compact, this would ignore blacklist and could re-arrange the inventory in an unwanted way
        local emptySlots = meta.listEmptySlots(16, true)
        local emptySlot = nil

        for _, candidateSlot in ipairs(emptySlots) do
            if not blacklist[candidateSlot.id] then
                emptySlot = candidateSlot
                break
            end
        end

        if not emptySlot then
            return false, "no space in inventory to move surplus elsewhere"
        end

        if not turtle.transferTo(emptySlot.id, surplusAmount - amount) then
            return false, "moving surplus to empty slot failed"
        end

        return true
    end

    if (slot.name == name or not slot.name) and slot.count < count then
        if name and #candidateSlots == 0 then
            return false, "no items found in inventory to move deficit from elsewhere"
        end

        local amount = 0
        local deficitAmount = count - slot.count

        for _, sameSlot in ipairs(sameSlots) do
            local sameCount = sameSlot.count
            local movableAmount = math.min(deficitAmount - amount, sameCount)

            if movableAmount > 0 then
                turtle.select(sameSlot.id)

                if turtle.transferTo(slotId, movableAmount) then
                    amount = amount + movableAmount
                end
            end

            if amount == deficitAmount then
                return true
            end
        end

        return false, "not enough items in inventory to move deficit from elsewhere"
    end

    if slot.name ~= name then
        if name and #candidateSlots == 0 then
            return false, "item not found in inventory"
        end

        local _, err = meta.setSlot(slotId, slot.name, 0, blacklist)

        if err then
            return false, "could not move other items elsewhere because there was not enough space in inventory"
        end

        _, err = meta.setSlot(slotId, name, count, blacklist)

        if err then
            return false, err
        end
    end

    return true
end

function robot.addEventListener(listener)
    if not listener then
        error("listener must not be nil")
    end

    local id = meta.nextEventListenerId

    meta.eventListeners[id] = listener
    meta.nextEventListenerId = id + 1

    return id
end

function robot.removeEventListener(id)
    if not id then
        error("id must not be nil")
    end

    meta.eventListeners[id] = nil
    return true
end

function robot.listEventListeners()
    local listenerArr = {}

    for _, listener in pairs(meta.eventListeners) do
        table.insert(listenerArr, listener)
    end

    return listenerArr
end

function robot.setPeripheralConstructor(nameOrConstructor, constructor)
    if nameOrConstructor == nil then
        nameOrConstructor = meta.selectedName
    elseif type(nameOrConstructor) == "function" then
        constructor = nameOrConstructor
        nameOrConstructor = meta.selectedName
    end

    if not nameOrConstructor then
        error("name must not be nil")
    end

    if not constructor then
        error("constructor must not be nil")
    end

    meta.peripheralConstructors[nameOrConstructor] = constructor

    return nameOrConstructor
end

function robot.removePeripheralConstructor(name)
    name = name or meta.selectedName

    if not name then
        error("name must not be nil")
    end

    meta.peripheralConstructors[name] = nil
end

function robot.listPeripheralConstructors()
    local constructorArr = {}

    for name, constructor in pairs(meta.peripheralConstructors) do
        table.insert(constructorArr, {
            name = name,
            constructor = constructor
        })
    end

    return constructorArr
end

function robot.wrap(sideOrWrapAs, wrapAs)
    if (sideOrWrapAs == SIDES.front or sideOrWrapAs == SIDES.top or sideOrWrapAs == SIDES.bottom) and not wrapAs then
        return meta.wrap(getName(sideOrWrapAs), sideOrWrapAs)
    elseif sideOrWrapAs == SIDES.front or sideOrWrapAs == SIDES.back or sideOrWrapAs == SIDES.top or sideOrWrapAs == SIDES.bottom then
        return meta.wrap(wrapAs, sideOrWrapAs)
    elseif (sideOrWrapAs == SIDES.right or sideOrWrapAs == SIDES.left) and wrapAs then
        local detail = sideOrWrapAs == SIDES.right and turtle.getEquippedRight() or turtle.getEquippedLeft()

        if detail then
            if not meta.selectFirstEmptySlot() then
                error("can't unequip tool because inventory is full")
            end

            local wasEquipment = false

            for _, proxy in pairs(meta.equipProxies) do
                if proxy.side == sideOrWrapAs then
                    local ok = proxy.unuse()

                    if not ok then
                        error("could not unuse equipment")
                    end

                    wasEquipment = true
                end
            end

            if not wasEquipment then
                local ok, err = sideOrWrapAs == SIDES.right and turtle.equipRight() or turtle.equipLeft()

                if not ok then
                    error(err)
                end
            end
        end

        return meta.wrap(wrapAs, sideOrWrapAs)
    elseif sideOrWrapAs == SIDES.right or sideOrWrapAs == SIDES.left then
        error("must explicitly wrap " .. sideOrWrapAs)
    elseif not sideOrWrapAs and not wrapAs then
        return meta.wrap(getName(SIDES.front), SIDES.front)
    else
        wrapAs = wrapAs or sideOrWrapAs
        return meta.wrap(wrapAs, SIDES.front)
    end
end

function robot.wrapUp(wrapAs)
    return meta.wrap(wrapAs or getName(SIDES.top), SIDES.top)
end

function robot.wrapDown(wrapAs)
    return meta.wrap(wrapAs or getName(SIDES.bottom), SIDES.bottom)
end

function robot.forward()
    softUnwrapAllWrapProxies()

    local ok, err = turtle.forward()

    if ok then
        unwrapAllWrapProxies()
        local delta = DELTAS[robot.facing]

        robot.x = robot.x + delta.x
        robot.z = robot.z + delta.z
    else
        softWrapAllWrapProxies()
    end

    return ok, err
end

function robot.back()
    softUnwrapAllWrapProxies()

    local ok, err = turtle.back()

    if ok then
        unwrapAllWrapProxies()
        local delta = DELTAS[robot.facing]

        robot.x = robot.x - delta.x
        robot.z = robot.z - delta.z
    else
        softWrapAllWrapProxies()
    end

    return ok, err
end

function robot.up()
    softUnwrapAllWrapProxies()

    local ok, err = turtle.up()

    if ok then
        unwrapAllWrapProxies()
        robot.y = robot.y + DELTAS.up.y
    else
        softWrapAllWrapProxies()
    end

    return ok, err
end

function robot.down()
    softUnwrapAllWrapProxies()

    local ok, err = turtle.down()

    if ok then
        unwrapAllWrapProxies()
        robot.y = robot.y + DELTAS.down.y
    else
        softWrapAllWrapProxies()
    end

    return ok, err
end

function robot.turnLeft()
    softUnwrapAllWrapProxies()

    local ok = turtle.turnLeft()

    if ok then
        unwrapAllWrapProxies()

        local i = FACINGS[robot.facing] - 1
        robot.facing = FACINGS[i % 4]
    else
        error("turnLeft can't fail, this is an illegal state")
    end

    return ok
end

function robot.turnRight()
    softUnwrapAllWrapProxies()

    local ok = turtle.turnRight()

    if ok then
        unwrapAllWrapProxies()

        local i = FACINGS[robot.facing] + 1
        robot.facing = FACINGS[i % 4]
    else
        error("turnRight can't fail, this is an illegal state")
    end

    return ok
end

function robot.place(name)
    name = name or meta.selectedName

    if not name then
        error("name must not be nil")
    end

    local ok, err = meta.selectFirstSlot(name)

    if not ok then
        return ok, err
    end

    return turtle.place()
end

function robot.placeUp(name)
    name = name or meta.selectedName

    if not name then
        error("name must not be nil")
    end

    local ok, err = meta.selectFirstSlot(name)

    if not ok then
        return ok, err
    end

    return turtle.placeUp()
end

function robot.placeDown(name)
    name = name or meta.selectedName

    if not name then
        error("name must not be nil")
    end

    local ok, err = meta.selectFirstSlot(name)

    if not ok then
        return ok, err
    end

    return turtle.placeDown()
end

function robot.drop(nameOrCount, count)
    if nameOrCount == nil then
        nameOrCount = meta.selectedName
    elseif type(nameOrCount) == "number" then
        count = nameOrCount
        nameOrCount = meta.selectedName
    end

    return dropHelper(nameOrCount, count, turtle.drop)
end

function robot.dropUp(nameOrCount, count)
    if nameOrCount == nil then
        nameOrCount = meta.selectedName
    elseif type(nameOrCount) == "number" then
        count = nameOrCount
        nameOrCount = meta.selectedName
    end

    return dropHelper(nameOrCount, count, turtle.dropUp)
end

function robot.dropDown(nameOrCount, count)
    if nameOrCount == nil then
        nameOrCount = meta.selectedName
    elseif type(nameOrCount) == "number" then
        count = nameOrCount
        nameOrCount = meta.selectedName
    end

    return dropHelper(nameOrCount, count, turtle.dropDown)
end

function robot.select(name)
    if not name then
        error("name must not be nil")
    end

    meta.selectedName = name
end

function robot.getItemCount(name)
    name = name or meta.selectedName
    return meta.countItems(name)
end

function robot.getItemSpace(nameOrStackCount, stackCount)
    if nameOrStackCount == nil then
        nameOrStackCount = meta.selectedName
    elseif type(nameOrStackCount) == "number" then
        stackCount = nameOrStackCount
        nameOrStackCount = meta.selectedName
    end

    local slots = meta.listSlots(nameOrStackCount, nil, true)
    local stackSize = #slots > 0 and (slots[1].count + slots[1].space) or 64

    local count = 0
    local space = 0

    for i = 1, #slots do
        count = count + slots[i].count
        space = space + slots[i].space
    end

    if stackCount == nil then
        return stackSize * #meta.listEmptySlots() + space
    else
        return stackCount * stackSize - count
    end
end

function robot.getItemSpaceForUnknown()
    return #meta.listEmptySlots()
end

function robot.hasItemCount(name)
    name = name or meta.selectedName

    if not name then
        error("name must not be nil")
    end

    local slot = meta.getFirstSlot(name)
    return slot and true or false
end

function robot.hasItemSpace(nameOrStackCount, stackCount)
    return robot.getItemSpace(nameOrStackCount, stackCount) > 0
end

function robot.hasItemSpaceForUnknown()
    local slot = meta.getFirstEmptySlot()
    return slot and true or false
end

function robot.detect()
    return turtle.detect()
end

function robot.detectUp()
    return turtle.detectUp()
end

function robot.detectDown()
    return turtle.detectDown()
end

function robot.compare(name)
    name = name or meta.selectedName
    return compareHelper(name, turtle.inspect)
end

function robot.compareUp(name)
    name = name or meta.selectedName
    return compareHelper(name, turtle.inspectUp)
end

function robot.compareDown(name)
    name = name or meta.selectedName
    return compareHelper(name, turtle.inspectDown)
end

function robot.suck(count)
    return suckHelper(count, turtle.suck)
end

function robot.suckUp(count)
    return suckHelper(count, turtle.suckUp)
end

function robot.suckDown(count)
    return suckHelper(count, turtle.suckDown)
end

function robot.getFuelLevel()
    return turtle.getFuelLevel()
end

function robot.refuel(nameOrCount, count)
    if nameOrCount == nil then
        nameOrCount = meta.selectedName
    elseif type(nameOrCount) == "number" then
        count = nameOrCount
        nameOrCount = meta.selectedName
    end

    return dropHelper(nameOrCount, count, turtle.refuel)
end

function robot.getSelectedName()
    return meta.selectedName
end

function robot.getFuelLimit()
    return turtle.getFuelLimit()
end

function robot.equip(nameOrPinned, pinned)
    if nameOrPinned == nil then
        nameOrPinned = meta.selectedName
    elseif type(nameOrPinned) == "boolean" then
        pinned = nameOrPinned
        nameOrPinned = meta.selectedName
    end

    return equipHelper(nameOrPinned, pinned)
end

function robot.unequip(nameOrProxy)
    if type(nameOrProxy) == "table" then
        nameOrProxy = nameOrProxy.name
    end

    nameOrProxy = nameOrProxy or meta.selectedName

    if not nameOrProxy then
        error("name must not be nil")
    end

    return unequipHelper(nameOrProxy)
end

-- essentially behaves like normal hasItemCount / not hasItemSpace
-- the other normal inventory methods don't really make sense for equipment
-- count is always 0 or 1 and so is space, just inverted
-- if the equipment is equipped, return true, otherwise return false
-- NOTE: equipment behaves like a "mini inventory", but every entry has space = 1
function robot.hasEquipmentCount(name)

end

-- essentially getItemSpace / hasItemSpace for equipment
-- if the equipment is equipped, return false, otherwise return true
function robot.hasEquipmentSpace(name)

end

-- essentially checks whether there is at least 1 empty slot in inventory
-- OR at least one empty equip slot (left / right)
function robot.hasEquipmentSpaceForUnknown()

end

function robot.listEquipment()
    local proxyArr = {}

    for _, proxy in pairs(meta.equipProxies) do
        table.insert(proxyArr, proxy)
    end

    return proxyArr
end

function robot.inspect()
    return turtle.inspect()
end

function robot.inspectUp()
    return turtle.inspectUp()
end

function robot.inspectDown()
    return turtle.inspectDown()
end

function robot.getItemDetail(name)
    name = name or meta.selectedName

    if not name then
        error("name must not be nil")
    end

    local count = robot.getItemCount(name)

    if count > 0 then
        return {
            name = name,
            count = count
        }
    end

    return nil
end

function robot.listItems()
    local slots = meta.listSlots()
    local items = {}

    for i = 1, #slots do
        local slot = slots[i]
        local item = items[slot.name]

        if not item then
            item = {
                name = slot.name,
                count = 0
            }

            items[slot.name] = item
        end

        item.count = item.count + slot.count
    end

    local itemArr = {}

    for _, item in pairs(items) do
        table.insert(itemArr, item)
    end

    return itemArr
end

-- how much space should be freed for item?
-- essentially changes the "mini inventory" size for that reserved item,
-- or deletes it if space = 0
function robot.free(name, space)
    if not name then
        error("name must not be nil")
    end

    if not space then
        error("count must not be nil")
    end

    if not meta.reservedItemSpaces[name] then
        meta.reservedItemSpaces[name] = 0
    end

    meta.reservedItemSpaces[name] = meta.reservedItemSpaces[name] - space
    return true
end

-- how much space should be reserved for item?
-- essentially creates a "mini inventory" only for that item,
-- separate from both the normal inventory and the equipment inventory
function robot.reserve(name, space)
    if not name then
        error("name must not be nil")
    end

    if not space then
        error("count must not be nil")
    end

    if not meta.reservedItemSpaces[name] then
        meta.reservedItemSpaces[name] = 0
    end

    meta.reservedItemSpaces[name] = meta.reservedItemSpaces[name] + space
    return true
end

-- return {name, count} of the reserved item,
-- analogous to normal getItemDetails()
function robot.getReservedItemDetails(name)

end

-- how much of the reserved item do we actually have in inventory?
function robot.getReservedItemCount(name)

end

-- how much space is left in the "mini inventory" for that reserved item?
function robot.getReservedItemSpace(name)

end

-- do we have any of the reserved item?
function robot.hasReservedItemCount(name)

end

-- is there space left in the "mini inventory" for the reserved item?
function robot.hasReservedItemSpace(name)

end

-- list all "mini inventories" with {name, count} entry per item,
-- analogous to normal listItems()
function robot.listReservedItems()
    local arr = {}

    for name, count in pairs(meta.reservedItemSpaces) do
        table.insert(arr, {
            name = name,
            count = count
        })
    end

    return arr
end

-- NOTE: you can ONLY interact with the normal inventory directly
-- the equipment "mini inventory" and the reserved "mini inventory" are not
-- accessible for practical purposes, they fulfill different roles

-- equipment: abstracts away tools to use,
--  returns tool handles and there is no other way to access it

-- reserved: abstracts away the need for certain items to remain in the turtle at all times
--  those items are not necessarily equipment, so reserved is its own separate inventory
--  that can only be interacted with by defining its space for each item it should hold
return robot
