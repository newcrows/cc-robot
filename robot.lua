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
    pinned = true,
    side = true,
    target = true,
    use = true,
    unuse = true,
    pin = true,
    unpin = true
}

local robot = {
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
    peripheralConstructors = {}
}

meta.peripheralConstructors["minecraft:diamond_pickaxe"] = function()
    return {
        dig = turtle.dig,
        digUp = turtle.digUp,
        digDown = turtle.digDown
    }
end
meta.peripheralConstructors["minecraft:diamond_axe"] = function()
    return {
        dig = turtle.dig,
        digUp = turtle.digUp,
        digDown = turtle.digDown
    }
end
meta.peripheralConstructors["minecraft:diamond_shovel"] = function()
    return {
        dig = turtle.dig,
        digUp = turtle.digUp,
        digDown = turtle.digDown
    }
end
meta.peripheralConstructors["minecraft:diamond_sword"] = function()
    return {
        attack = turtle.attack,
        attackUp = turtle.attackUp,
        attackDown = turtle.attackDown
    }
end
meta.peripheralConstructors["advancedperipherals:me_bridge"] = function(opts)
    local side = opts.side
    local target = opts.target

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
                error("pinned " .. name .. " was removed manually")
            end

            proxy.side = nil
            proxy.target = nil
        end
    end
end

local function wrap(name, side)
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
            target = target
        }

        return constructor(opts)
    end

    return target
end

local function isEmpty(side)
    if not side then
        error("side must not be nil")
    end

    local detail = side == SIDES.right and turtle.getEquippedRight() or turtle.getEquippedLeft()
    return detail == nil
end

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

    if proxy and proxy.target then
        return true
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
            swapProxy.side = nil
            swapProxy.target = nil
        end
    end

    local proxy = meta.equipProxies[name]

    proxy.side = side
    proxy.target = wrap(name, side)

    meta.equipSide = OPPOSITE_SIDES[meta.equipSide]
    return true
end

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
        return false, name .. " can not be unequipped because there is no space in inventory"
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
        return false, "could not unequip " .. name .. " because there is no space in inventory"
    end

    turtle.select(slot.id)

    local ok, err = proxy.side == SIDES.right and turtle.equipRight() or turtle.equipLeft()

    if not ok then
        return false, err
    end

    proxy.side = nil
    proxy.target = nil

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
        sync()

        if proxy.target then
            return true
        end

        if name == getName(SIDES.right) then
            proxy.side = SIDES.right
            proxy.target = wrap(name, SIDES.right)

            meta.equipSide = SIDES.left
        end

        if name == getName(SIDES.left) then
            proxy.side = SIDES.left
            proxy.target = wrap(name, SIDES.left)

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
        sync()

        if not proxy.target then
            return true
        end

        if proxy.target and canUnequip(proxy) then
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
    end

    if pinned then
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

        return true
    end

    return true
end

function meta.listSlots(filter, limit, includeEquipment)
    limit = limit or 16

    local slots = {}
    local seenEquipment = {}

    -- NOTE [JM] skipped for performance reasons
    -- sync()

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

function meta.getFirstSlot(name, includeEquipment)
    if not name then
        error("name must not be nil")
    end

    local slots = meta.listSlots(name, 1, includeEquipment)

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

function meta.selectFirstSlot(name, includeEquipment)
    if not name then
        error("name must not be nil")
    end

    local slot = meta.getFirstSlot(name, includeEquipment)

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

function meta.countItems(filter, includeEquipment)
    local count = 0
    local slots = meta.listSlots(filter, 16, includeEquipment)

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

function robot.insertPeripheralConstructor(nameOrConstructor, constructor)
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

function robot.wrap(side)
    side = side or SIDES.front

    if not side then
        error("side must not be nil")
    end

    return wrap(getName(side), side)
end

function robot.wrapUp()
    return wrap(getName(SIDES.top), SIDES.top)
end

function robot.wrapDown()
    return wrap(getName(SIDES.bottom), SIDES.bottom)
end

function robot.up()
    local ok, err = turtle.up()

    if ok then
        robot.y = robot.y + DELTAS.up.y
    end

    return ok, err
end

function robot.down()
    local ok, err = turtle.down()

    if ok then
        robot.y = robot.y + DELTAS.down.y
    end

    return ok, err
end

function robot.forward()
    local ok, err = turtle.forward()

    if ok then
        local delta = DELTAS[robot.facing]

        robot.x = robot.x + delta.x
        robot.z = robot.z + delta.z
    end

    return ok, err
end

function robot.back()
    local ok, err = turtle.back()

    if ok then
        local delta = DELTAS[robot.facing]

        robot.x = robot.x - delta.x
        robot.z = robot.z - delta.z
    end

    return ok, err
end

function robot.turnLeft()
    local ok, err = turtle.turnLeft()

    if ok then
        local i = FACINGS[robot.facing] - 1
        robot.facing = FACINGS[i % 4]
    end

    return ok, err
end

function robot.turnRight()
    local ok, err = turtle.turnRight()

    if ok then
        local i = FACINGS[robot.facing] + 1
        robot.facing = FACINGS[i % 4]
    end

    return ok, err
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
    return robot.getItemCount(name) > 0
end

function robot.hasItemSpace(nameOrStackCount, stackCount)
    return robot.getItemSpace(nameOrStackCount, stackCount) > 0
end

function robot.hasItemSpaceForUnknown()
    local slot = meta.getFirstEmptySlot()

    if slot then
        return true
    else
        return false
    end
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

return robot
