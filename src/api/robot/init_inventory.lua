return function(robot, meta, constants)
    local ITEM_COUNT_WARNING = "item_count_warning"
    local ITEM_SPACE_WARNING = "item_space_warning"
    local RESERVED_INVENTORY_NAME = "reserved"

    local inventoryMap = {}
    local inventoryList = {}

    local fallbackInventoryName = "items"
    local fallbackInventory = {}

    local function split(str, sep)
        local t = {}
        for s in str:gmatch("([^" .. sep .. "]+)") do
            table.insert(t, s)
        end
        return t
    end

    local function parseQuery(query)
        local parts = split(query, "@")
        return parts[1], parts[2]
    end

    local function reduce(list, reduceFunc, initialValue)
        local aggregate = initialValue

        for _, item in ipairs(list) do
            aggregate = reduceFunc(aggregate, item)
        end

        return aggregate
    end

    local function getStackSize(itemName)
        -- TODO [JM]
        -- -> if it is in constants.block_map, return constants.block_map[name].stackSize
        -- -> elseif item is in any slot, return (space + count) for that slot
        -- -> else return constants.default_stack_size
        return 64
    end

    local function getFallbackSpace(itemName)
        local limits = {}

        -- get all limits for items not itemName in the declared inventories
        -- add each item to the itemLimit and itemCount
        for _, inventory in pairs(inventoryList) do
            for name, detail in pairs(inventory) do
                limits[name] = limits[name] or 0
                limits[name] = limits[name] + detail.limit
            end
        end

        -- get all limits for items in fallbackInventory (limit is the count here)
        for name, detail in pairs(fallbackInventory) do
            limits[name] = limits[name] or 0
            limits[name] = limits[name] + detail.count
        end

        local reservedSlotCount = 0

        -- ceil reserved slots for items not itemName
        -- reserved slots for items with itemName is NOT ceiled
        for name, limit in pairs(limits) do
            if name == itemName then
                reservedSlotCount = reservedSlotCount + limit / getStackSize(name)
            else
                reservedSlotCount = reservedSlotCount + math.ceil(limit / getStackSize(name))
            end
        end

        -- derive free slot space and add partially available space
        local freeSlotCount = 16 - reservedSlotCount
        return freeSlotCount * getStackSize(itemName)
    end

    local function addInventory(invName)
        local inv = {}

        inventoryMap[invName] = inv
        table.insert(inventoryList, inv)
    end

    local function syncInventories()
        local physicalItems = {}

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail then
                local name = detail.name
                local count = detail.count

                physicalItems[name] = (physicalItems[name] or 0) + count
            end
        end

        for i = 1, #inventoryList do
            local inventory = inventoryList[i]

            for name, count in pairs(physicalItems) do
                local item = inventory[name]

                if item then
                    local amount = math.min(item.limit, count)

                    item.count = amount
                    physicalItems[name] = count - amount
                end
            end
        end

        for name, count in pairs(physicalItems) do
            fallbackInventory[name] = (fallbackInventory[name] or { count = 0 })
            fallbackInventory[name].count = count
        end
    end

    local function reserve(itemName, invName, space)
        local inv = inventoryMap[invName]
        inv[itemName] = (inv[itemName] or {
            limit = 0,
            count = 0
        })

        inv[itemName].limit = inv[itemName].limit + space
    end

    local function free(itemName, invName, space)
        local inv = inventoryMap[invName]
        inv[itemName] = (inv[itemName] or {
            limit = 0,
            count = 0
        })

        inv[itemName].limit = inv[itemName].limit - space
    end

    function meta.reserve(name, space)
        reserve(name, RESERVED_INVENTORY_NAME, space)
    end

    function meta.free(name, space)
        free(name, RESERVED_INVENTORY_NAME, space)
    end

    function robot.getItemDetail(query)
        local itemName = parseQuery(query)

        return {
            name = itemName,
            count = robot.getItemCount(query)
        }
    end

    function robot.getItemCount(query)
        local itemName, invName = parseQuery(query)

        if invName == "*" then
            local sum = reduce(inventoryList, function(sum, inventory)
                local item = inventory[itemName]
                return item and sum + item.count or sum
            end, 0)

            local item = fallbackInventory[itemName]
            return sum + (item and item.count or 0)
        end

        if invName == fallbackInventoryName then
            local item = fallbackInventory[itemName]
            return item and item.count or 0
        end

        local item = inventoryMap[invName][itemName]
        return item and item.count or 0
    end

    function robot.getItemSpace(query)
        local itemName, invName = parseQuery(query)

        if invName == "*" then
            local sum = reduce(inventoryList, function(sum, inventory)
                local item = inventory[itemName]
                return item and sum + (item.limit - item.count) or sum
            end, 0)

            return sum + getFallbackSpace(itemName)
        end

        if invName == fallbackInventoryName then
            return getFallbackSpace(itemName)
        end

        local item = inventoryMap[invName][itemName]
        return item and (item.limit - item.count) or 0
    end

    function robot.onItemCountWarning(callback)
        meta.on(ITEM_COUNT_WARNING, callback)
    end

    function robot.onItemCountWarningCleared(callback)
        meta.on(ITEM_COUNT_WARNING .. "_cleared", callback)
    end

    function robot.onItemSpaceWarning(callback)
        meta.on(ITEM_SPACE_WARNING, callback)
    end

    function robot.onItemSpaceWarningCleared(callback)
        meta.on(ITEM_SPACE_WARNING .. "_cleared", callback)
    end

    addInventory(RESERVED_INVENTORY_NAME)
    syncInventories()

    local lastMissingCount
    robot.onItemCountWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local name = e.detail.name
        local missingCount = e.detail.missingCount

        if not alreadyWarned or lastMissingCount ~= missingCount then
            print("---- " .. ITEM_COUNT_WARNING .. " ----")
            print("missing " .. missingCount .. " of " .. name)

            lastMissingCount = missingCount
        end
    end)
    robot.onItemCountWarningCleared(function()
        print("---- " .. ITEM_COUNT_WARNING .. "_cleared ----")
    end)

    local lastMissingSpace
    robot.onItemSpaceWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local name = e.detail.name
        local missingSpace = e.detail.missingSpace

        if not alreadyWarned or lastMissingSpace ~= missingSpace then
            print("---- " .. ITEM_SPACE_WARNING .. " ----")
            print("missing " .. missingSpace .. " space for " .. name)

            lastMissingSpace = missingSpace
        end
    end)
    robot.onItemSpaceWarningCleared(function()
        print("---- " .. ITEM_SPACE_WARNING .. "_cleared ----")
    end)
end
