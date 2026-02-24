return function(robot, meta, constants)
    local BLOCK_MAP = constants.block_map
    local DEFAULT_STACK_SIZE = constants.default_stack_size
    local RESERVED_INVENTORY_NAME = constants.reserved_inventory_name
    local FALLBACK_INVENTORY_NAME = constants.fallback_inventory_name
    local ITEM_COUNT_WARNING = "item_count_warning"
    local ITEM_SPACE_WARNING = "item_space_warning"

    local inventoryMap = {}
    local inventoryList = {}
    local fallbackInventory = {}
    local selectedQuery = "*@*"

    local function split(str, sep)
        local t = {}
        for s in str:gmatch("([^" .. sep .. "]+)") do
            table.insert(t, s)
        end
        return t
    end

    local function reduce(list, reduceFunc, initialValue)
        local aggregate = initialValue

        for _, item in ipairs(list) do
            aggregate = reduceFunc(aggregate, item)
        end

        return aggregate
    end

    local function getStackSize(itemName)
        local block = BLOCK_MAP[itemName]

        if block then
            return block.stackSize
        end

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail and detail.name == itemName then
                return detail.count + nativeTurtle.getItemSpace(i)
            end
        end

        return DEFAULT_STACK_SIZE
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

    function meta.parseQuery(query)
        local parts = split(query, "@")
        local selParts = split(selectedQuery, "@")

        if #parts == 2 and #parts[1] > 0 then
            -- fully formulated query
            return parts[1], parts[2]
        elseif #parts == 2 then
            -- is a query like "@reserved" or "@items"
            -- we check whether selectedQuery is an item (does not contain "@")

            if #selParts == 2 then
                error("query and selectedQuery are incompatible")
            else
                return selParts[1], parts[2]
            end
        else
            -- is a query like "minecraft:dirt"
            -- we check whether selectedQuery is NOT an item (does contain "@")

            if #selParts == 2 and #selParts[1] == 0 then
                return parts[1], selParts[2]
            else
                error("query and selectedQuery are incompatible")
            end
        end
    end

    function meta.requireItemCount(query, count)
        local function check()
            return robot.getItemCount(query) >= count
        end

        local function get()
            return {
                query = query,
                missingCount = count - robot.getItemCount(query)
            }
        end

        local function constructor(detail)
            return meta.createEvent(ITEM_COUNT_WARNING, detail)
        end

        meta.require(check, get, constructor)
    end

    function meta.requireItemSpace(query, space)
        local function check()
            return robot.getItemSpace(query) >= space
        end

        local function get()
            return {
                query = query,
                missingSpace = space - robot.getItemSpace(query)
            }
        end

        local function constructor(detail)
            return meta.createEvent(ITEM_SPACE_WARNING, detail)
        end

        meta.require(check, get, constructor)
    end

    function meta.getFirstSlot(query)
        local count = robot.getItemCount(query)
        local space = robot.getItemSpace(query)

        if count == 0 and space == 0 then
            return nil
        end

        local itemName = meta.parseQuery(query)

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail and detail.name == itemName or not detail and itemName == "minecraft:air" then
                return {
                    id = i,
                    name = itemName,
                    count = detail.count
                }
            end
        end

        return nil
    end

    function meta.selectFirstSlot(query)
        local slot = meta.getFirstSlot(query)

        if slot then
            nativeTurtle.select(slot.id)
            return true
        end

        return false
    end

    function meta.transferItem(itemName, fromInvName, toInvName, count)
        local transmittableCount = robot.getItemCount(itemName .. "@" .. fromInvName)
        local receivableCount = robot.getItemSpace(itemName .. "@" .. toInvName)
        local movableCount = math.min(math.min(transmittableCount, receivableCount), count)

        if fromInvName == "*" then
            error("can't transfer items from 'all_inventories'")
        end

        if toInvName == "*" then
            error("can't transfer items to 'all_inventories'")
        end

        if fromInvName == FALLBACK_INVENTORY_NAME then
            local inv = fallbackInventory

            inv[itemName] = inv[itemName] or {count = 0}
            inv[itemName].count = inv[itemName] - movableCount
        else
            local inv = inventoryMap[fromInvName]

            inv[itemName] = inv[itemName] or {limit = 0, count = 0}
            inv[itemName].count = inv[itemName] - movableCount
        end

        if toInvName == FALLBACK_INVENTORY_NAME then
            local inv = fallbackInventory

            inv[itemName] = inv[itemName] or {count = 0}
            inv[itemName].count = inv[itemName] + movableCount
        else
            local inv = inventoryMap[toInvName]

            inv[itemName] = inv[itemName] or {limit = 0, count = 0}
            inv[itemName].count = inv[itemName] + movableCount
        end

        return movableCount
    end

    function robot.reserve(query, space)
        local itemName, invName = meta.parseQuery(query)

        if invName ~= "*" then
            print("warning: reserve() ignores invName")
        end

        reserve(itemName, RESERVED_INVENTORY_NAME, space)
    end

    function robot.free(query, space)
        local itemName, invName = meta.parseQuery(query)

        if invName ~= "*" then
            print("warning: free() ignores invName")
        end

        free(itemName, RESERVED_INVENTORY_NAME, space)
    end

    function robot.select(query)
        selectedQuery = query
    end

    function robot.getSelectedQuery()
        return selectedQuery
    end

    function robot.getItemDetail(query)
        local itemName = meta.parseQuery(query)

        return {
            name = itemName,
            count = robot.getItemCount(query)
        }
    end

    function robot.getItemCount(query)
        local itemName, invName = meta.parseQuery(query)

        if invName == "*" then
            local sum = reduce(inventoryList, function(sum, inventory)
                local item = inventory[itemName]
                return item and sum + item.count or sum
            end, 0)

            local item = fallbackInventory[itemName]
            return sum + (item and item.count or 0)
        end

        if invName == FALLBACK_INVENTORY_NAME then
            local item = fallbackInventory[itemName]
            return item and item.count or 0
        end

        local item = inventoryMap[invName][itemName]
        return item and item.count or 0
    end

    function robot.getItemSpace(query)
        local itemName, invName = meta.parseQuery(query)

        if invName == "*" then
            local sum = reduce(inventoryList, function(sum, inventory)
                local item = inventory[itemName]
                return item and sum + (item.limit - item.count) or sum
            end, 0)

            return sum + getFallbackSpace(itemName)
        end

        if invName == FALLBACK_INVENTORY_NAME then
            return getFallbackSpace(itemName)
        end

        local item = inventoryMap[invName][itemName]
        return item and (item.limit - item.count) or 0
    end

    function robot.listItems(query)
        local itemName, invName = meta.parseQuery(query)
        local details

        if itemName ~= "*" then
            print("warning: listItems() ignores itemName")
        end

        if invName == "*" then
            for _, inventory in pairs(inventoryList) do
                for name, detail in pairs(inventory) do
                    details[name] = details[name] or { name = name, count = 0 }
                    details[name].count = details[name].count + detail.count
                end
            end

            for name, detail in pairs(fallbackInventory) do
                details[name] = details[name] or { name = name, count = 0 }
                details[name].count = details[name].count + detail.count
            end
        elseif invName == FALLBACK_INVENTORY_NAME then
            for name, detail in pairs(fallbackInventory) do
                details[name] = details[name] or { name = name, count = 0 }
                details[name].count = details[name].count + detail.count
            end
        else
            for name, detail in pairs(inventoryMap[invName]) do
                details[name] = details[name] or { name = name, count = 0 }
                details[name].count = details[name].count + detail.count
            end
        end

        local arr = {}

        for _, detail in pairs(details) do
            table.insert(arr, detail)
        end

        return arr
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

    robot.select("@items")
    addInventory(RESERVED_INVENTORY_NAME)
    syncInventories()

    local lastMissingCount
    robot.onItemCountWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local query = e.detail.query
        local missingCount = e.detail.missingCount

        if not alreadyWarned or lastMissingCount ~= missingCount then
            print("---- " .. ITEM_COUNT_WARNING .. " ----")
            print("missing " .. missingCount .. " of " .. query)

            lastMissingCount = missingCount
        end
    end)
    robot.onItemCountWarningCleared(function()
        print("---- " .. ITEM_COUNT_WARNING .. "_cleared ----")
    end)

    local lastMissingSpace
    robot.onItemSpaceWarning(function(e)
        local alreadyWarned = e.alreadyWarned
        local query = e.detail.query
        local missingSpace = e.detail.missingSpace

        if not alreadyWarned or lastMissingSpace ~= missingSpace then
            print("---- " .. ITEM_SPACE_WARNING .. " ----")
            print("missing " .. missingSpace .. " space for " .. query)

            lastMissingSpace = missingSpace
        end
    end)
    robot.onItemSpaceWarningCleared(function()
        print("---- " .. ITEM_SPACE_WARNING .. "_cleared ----")
    end)
end
