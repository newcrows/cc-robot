return function(robot, meta, constants)
    local ITEM_INFO = constants.item_info
    local DEFAULT_STACK_SIZE = constants.default_stack_size
    local RESERVED_INVENTORY_NAME = constants.reserved_inventory_name
    local FALLBACK_INVENTORY_NAME = constants.fallback_inventory_name
    local ITEM_COUNT_WARNING = "item_count_warning"
    local ITEM_SPACE_WARNING = "item_space_warning"

    local inventoryMap = {}
    local inventoryList = {}
    local fallbackInventory = {}
    local selectedQuery = "@" .. FALLBACK_INVENTORY_NAME

    local function reduce(list, reduceFunc, initialValue)
        local aggregate = initialValue

        for _, item in ipairs(list) do
            aggregate = reduceFunc(aggregate, item)
        end

        return aggregate
    end

    local function getStackSize(itemName)
        local block = ITEM_INFO[itemName]

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

    local function transferAvailable(itemName, fromInvName, toInvName, count)
        local fromQuery = itemName .. "@" .. fromInvName
        local toQuery = itemName .. "@" .. toInvName

        local transmittableCount = robot.getItemCount(fromQuery)
        local receivableCount = robot.getItemSpace(toQuery)
        local movableCount = math.min(math.min(transmittableCount, receivableCount), count)

        if movableCount > 0 then
            meta.updateItemCount(fromQuery, -movableCount)
            meta.updateItemCount(toQuery, movableCount)

            return movableCount
        end

        return 0
    end

    local function split(str, sep)
        local result = {}
        -- Pattern: Suche alles bis zum Trenner oder Ende
        local pattern = string.format("([^%s]*)%s?", sep, sep)

        for part in str:gmatch(pattern) do
            table.insert(result, part)
        end

        -- Das letzte leere Match von gmatch entfernen (Lua Eigenheit)
        if result[#result] == "" then
            table.remove(result)
        end
        return result
    end

    local function updateItemLimit(query, delta)
        local itemName, invName = meta.parseQuery(query)
        local inv = inventoryMap[invName]

        inv[itemName] = inv[itemName] or { limit = 0, count = 0 }
        inv[itemName].limit = inv[itemName].limit + delta
    end

    -- TODO [JM] implement forcing wildcards (i.E. for robot.listItems())
    function meta.parseQuery(query, forceItemWildcard, forceInvWildcard)
        local qState
        local sqState

        if query == nil then
            qState = "missing"
        elseif string.sub(query, 1, 1) ~= "@" and string.find(query, "@") then
            qState = "full"
        elseif string.sub(query, 1, 1) == "@" then
            qState = "invName"
        else
            qState = "itemName"
        end

        if string.sub(selectedQuery, 1, 1) ~= "@" and string.find(selectedQuery, "@") then
            sqState = "full"
        elseif string.sub(selectedQuery, 1, 1) == "@" then
            sqState = "invName"
        else
            sqState = "itemName"
        end

        local result

        if qState == "full" then
            result = split(query, "@")
        elseif qState == "itemName" and sqState == "invName" then
            result = split(query .. selectedQuery, "@")
        elseif qState == "invName" and sqState == "itemName" then
            result = split(selectedQuery .. query, "@")
        elseif qState == "missing" and sqState == "full" then
            result = split(selectedQuery, "@")
        elseif qState == "itemName" and forceInvWildcard then
            result = {selectedQuery, nil}
        elseif qState == "invName" and forceItemWildcard then
            result = {nil, selectedQuery}
        elseif qState == "missing" and sqState == "itemName" and forceInvWildcard then
            result = {sqState, nil}
        elseif qState == "missing" and sqState == "invName" and forceItemWildcard then
            result = {nil, sqState}
        else
            error("query is not compatible with selectQuery")
        end

        if forceItemWildcard then
            result[1] = forceItemWildcard
        end

        if forceInvWildcard then
            result[2] = forceInvWildcard
        end

        return result[1], result[2]
    end

    -- TODO [JM] support wildcard item "*"
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

    -- TODO [JM] explicitly do NOT support wildcard item "*"
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

    -- TODO [JM] support wildcard item "*"
    function meta.getFirstSlot(query)
        local count = robot.getItemCount(query)
        local itemName = meta.parseQuery(query)

        if count <= 0 then
            return nil
        end

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail and detail.name == itemName then
                local available = math.min(detail.count, count)

                if available > 0 then
                    return {
                        id = i,
                        name = itemName,
                        count = available
                    }
                end
            end
        end

        error("inconsistent state. need sync?")
    end

    -- TODO [JM] explicitly do NOT support wildcard item "*"
    function meta.getFirstEmptySlot(query)
        local space = robot.getItemSpace(query)
        local itemName = meta.parseQuery(query)

        if space <= 0 then
            return nil
        end

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail and detail.name == itemName then
                local available = math.min(getStackSize(itemName) - detail.count, space)

                if available > 0 then
                    return {
                        id = i,
                        name = itemName,
                        space = available
                    }
                end
            end
        end

        for i = 1, 16 do
            if nativeTurtle.getItemCount(i) == 0 then
                local available = math.min(getStackSize(itemName), space)

                if available > 0 then
                    return {
                        id = i,
                        name = itemName,
                        space = available
                    }
                end
            end
        end

        error("inconsistent state. need sync?")
    end

    -- TODO [JM] support wildcard item "*"
    function meta.selectFirstSlot(query)
        local slot = meta.getFirstSlot(query)

        if slot then
            nativeTurtle.select(slot.id)
            return true, slot.count
        end

        return false
    end

    -- TODO [JM] explicitly do NOT support wildcard item "*"
    function meta.selectFirstEmptySlot(query)
        local slot = meta.getFirstEmptySlot(query)

        if slot then
            nativeTurtle.select(slot.id)
            return true, slot.space
        end

        return false
    end

    function meta.updateItemCount(query, delta)
        local itemName, invName = meta.parseQuery(query)

        if invName == "*" then
            if delta > 0 then
                for i = 1, #inventoryList do
                    local inv = inventoryList[i]
                    local item = inv[itemName]

                    if item then
                        local receivableCount = math.min(item.limit - item.count, delta)

                        item.count = item.count + receivableCount
                        delta = delta - receivableCount
                    end
                end

                local inv = fallbackInventory
                local item = inv[itemName]

                if item then
                    item.count = item.count + delta
                end

                return
            else
                local inv = fallbackInventory
                local item = inv[itemName]

                if item then
                    local transmittableCount = math.min(item.count, -delta)

                    item.count = item.count - transmittableCount
                    delta = delta + transmittableCount
                end

                for i = #inventoryList, 1, -1 do
                    inv = inventoryList[i]
                    item = inv[item]

                    if item then
                        local transmittableCount = math.min(item.count, -delta)

                        item.count = item.count - transmittableCount
                        delta = delta + transmittableCount
                    end
                end

                return
            end
        end

        local inv = invName == FALLBACK_INVENTORY_NAME and fallbackInventory or inventoryMap[invName]

        inv[itemName] = inv[itemName] or { limit = 0, count = 0 }
        inv[itemName].count = inv[itemName].count + delta
    end

    function meta.snapshot()
        local snapshot = {}

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail then
                snapshot[detail.name] = snapshot[detail.name] + detail.count
            end
        end

        return snapshot
    end

    function meta.diff(before, after)
        local keys = {}
        local diff = {}

        for key, _ in pairs(before) do
            keys[key] = true
        end

        for key, _ in pairs(after) do
            keys[key] = true
        end

        for key, _ in pairs(keys) do
            local beforeCount = before[key] or 0
            local afterCount = after[key] or 0

            if beforeCount ~= afterCount then
                diff[key] = afterCount - beforeCount
            end
        end

        return diff
    end

    function meta.reserve(query, delta)
        local itemName, invName = meta.parseQuery(query)
        delta = delta or getStackSize(itemName)

        if itemName == "*" then
            error("can not reserve '*'")
        end

        if invName == "*" then
            error("can not reserve items from 'all_inventories'")
        end

        if invName == RESERVED_INVENTORY_NAME then
            error("can not reserve items from 'reserved_inventory'")
        end

        updateItemLimit(itemName .. "@" .. RESERVED_INVENTORY_NAME, delta)
        return transferAvailable(itemName, invName, RESERVED_INVENTORY_NAME, delta)
    end

    function meta.free(query, delta)
        local itemName, invName = meta.parseQuery(query)
        delta = delta or getStackSize(itemName)

        if itemName == "*" then
            error("can not free '*'")
        end

        if invName == "*" then
            error("can not free items from 'all_inventories'")
        end

        if invName == RESERVED_INVENTORY_NAME then
            error("can not free items to 'reserved_inventory'")
        end

        updateItemLimit(itemName .. "@" .. RESERVED_INVENTORY_NAME, -delta)
        return transferAvailable(itemName, RESERVED_INVENTORY_NAME, invName, delta)
    end

    function robot.select(query)
        selectedQuery = query
    end

    function robot.getSelectedQuery()
        return selectedQuery
    end

    -- TODO [JM] support wildcard item "*"
    -- -> returns {name = "*", count = ...}
    function robot.getItemDetail(query)
        local itemName = meta.parseQuery(query)

        return {
            name = itemName,
            count = robot.getItemCount(query)
        }
    end

    -- TODO [JM] support wildcard item "*"
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

    -- TODO [JM] explicitly do NOT support wildcard item "*"
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
        local _, invName = meta.parseQuery(query, "*")
        local details

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
