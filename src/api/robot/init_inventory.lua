return function(robot, meta, constants)
    local ITEM_COUNT_WARNING = "item_count_warning"
    local ITEM_SPACE_WARNING = "item_space_warning"

    local selectedName
    local order = { "reserved", "items" }
    local inventories = {
        reserved = { name = "reserved", limits = {}, slots = {} },
        items = { name = "items", limits = {}, slots = {} },
        ["*"] = { name = "*", limits = {}, slots = {} } -- limits is never used in "*"
    }

    local function parseQuery(str)
        if not str or str == "" or str == "*" then
            return "*", "*"
        end
        -- Pattern: trenne alles vor @ von allem nach @
        local item, inv = str:match("^(.-)@(.+)$")
        if not item then
            -- Falls nur @ vorhanden (@reserved)
            if str:sub(1, 1) == "@" then
                return "*", str:sub(2)
            end
            -- Falls nur Item vorhanden (dirt)
            return str, "*"
        end
        -- Leere Teile ("@reserved") werden zu "*"
        return (item == "" and "*" or item), (inv == "" and "*" or inv)
    end

    function meta.resolveQuery(query)
        local sItem, sInv = parseQuery(selectedName)
        local qItem, qInv = parseQuery(query)

        -- 1. Prüfe, ob selectedName bereits VOLL qualifiziert ist (beides ungleich "*")
        local sIsFull = (sItem ~= "*" and sInv ~= "*")

        -- 2. Prüfe, ob die Query versucht, etwas zu ändern (q ist ungleich "*@*")
        local qIsAttemptingChange = (qItem ~= "*" or qInv ~= "*")

        -- 3. Fehler: Wenn sN voll ist, darf q keine Änderungen (Item oder Inv) mehr fordern
        if sIsFull and qIsAttemptingChange then
            error("Forbidden: Cannot override parts of a fully qualified selectedName (" .. selectedName .. ") with query (" .. query .. ")", 2)
        end

        -- 4. Merge-Logik (Query überschreibt sN, solange sN nicht voll war)
        local finalItem = (qItem ~= "*") and qItem or sItem
        local finalInv = (qInv ~= "*") and qInv or sInv

        return finalItem, finalInv
    end

    function meta.syncInventories()
        -- 1. Reset
        for _, inv in pairs(inventories) do inv.slots = {} end
        local globalConsumed = {}

        for slotId = 1, 16 do
            local count = turtle.getItemCount(slotId)
            local name = count > 0 and turtle.getItemDetail(slotId).name or "air"
            local maxStack = count > 0 and (count + turtle.getItemSpace(slotId)) or 64

            local remainingInSlot = count
            local physicalSpaceInSlot = maxStack - count

            -- Aggregatoren für das "*" Inventar pro Slot
            local starCount = 0
            local starSpace = 0

            -- 2. Kaskadierung durch "order"
            for _, invName in ipairs(order) do
                local inv = inventories[invName]
                globalConsumed[name] = globalConsumed[name] or {}
                globalConsumed[name][invName] = globalConsumed[name][invName] or 0

                local limit = inv.limits[name] or (invName == order[#order] and maxStack or 0)

                -- vCount und vSpace Berechnung (inkl. Negativwerten)
                local vAvailable = limit - globalConsumed[name][invName]
                local vCount = (name == itemName or name == "air") and math.min(remainingInSlot, vAvailable) or 0
                local vSpace = limit - (globalConsumed[name][invName] + vCount)

                -- Physische Begrenzung nur, wenn vSpace positiv ist
                if vSpace > 0 then
                    vSpace = math.min(physicalSpaceInSlot, vSpace)
                end

                table.insert(inv.slots, {
                    id = slotId, name = name, count = vCount, space = vSpace
                })

                -- Kaskaden-Logik: vSpace (pos/neg) vom physischen Rest abziehen
                physicalSpaceInSlot = physicalSpaceInSlot - vSpace

                -- Summierung für das "*" Inventar
                starCount = starCount + vCount
                starSpace = starSpace + vSpace

                globalConsumed[name][invName] = globalConsumed[name][invName] + vCount
                if name == itemName then remainingInSlot = remainingInSlot - vCount end
            end

            -- 3. Das "*" Inventar als strikte Summe
            -- Wenn @reserved + @items negativ sind, wird auch starSpace negativ.
            table.insert(inventories["*"].slots, {
                id = slotId,
                name = name,
                count = starCount,
                space = starSpace
            })
        end
    end

    function meta.listSlots(query)
        local finalItem, finalInv = meta.resolveQuery(query)

        local vInventory = inventories[finalInv]
        if not vInventory then
            return {}
        end

        local results = {}
        for _, slot in ipairs(vInventory.slots) do
            -- "*" ist Wildcard für Items, "air" für leere Slots
            local isItemMatch = (finalItem == "*" or slot.name == finalItem)
            local isAirMatch = (finalItem == "air" and slot.name == "air")

            if isItemMatch or isAirMatch then
                -- Ein Slot ist relevant, wenn er Inhalt hat ODER Platz bietet
                if slot.count > 0 or slot.space > 0 then
                    table.insert(results, slot)
                end
            end
        end

        return results
    end

    function robot.reserve(name, space)
        assert(name, "Item-Name fehlt")
        local limits = inventories.reserved.limits

        -- Erhöhe das Limit (Initialisierung auf 0, falls das Item neu ist)
        limits[name] = (limits[name] or 0) + (space or 0)

        -- Wichtig: Nach der Änderung der Limits muss der State neu berechnet werden
        meta.syncInventories()
    end

    function robot.free(name, count)
        assert(name, "Item-Name fehlt")
        local limits = inventories.reserved.limits
        -- Einfache Subtraktion, negative Werte erlaubt
        limits[name] = (limits[name] or 0) - (count or 0)
        meta._syncInventories()
    end

    local function compact()
        for targetSlot = 1, 15 do
            local space = nativeTurtle.getItemSpace(targetSlot)

            if space > 0 then
                local target = nativeTurtle.getItemDetail(targetSlot)

                for sourceSlot = 16, targetSlot + 1, -1 do
                    local source = nativeTurtle.getItemDetail(sourceSlot)

                    if source then
                        if not target or source.name == target.name then
                            nativeTurtle.select(sourceSlot)
                            if nativeTurtle.transferTo(targetSlot) then
                                target = nativeTurtle.getItemDetail(targetSlot)
                                space = nativeTurtle.getItemSpace(targetSlot)
                            end
                        end
                    end

                    if space == 0 then
                        break
                    end
                end
            end
        end
    end

    local function getStackSize(name)
        local slot = meta.getFirstSlot(name, true)
        return slot and slot.count + slot.space or constants.default_stack_size
    end

    function meta.requireItemCount(name, count)
        local function check()
            return robot.hasItemCount(name, count)
        end

        local function get()
            return {
                name = name,
                missingCount = count - robot.getItemCount(name)
            }
        end

        local function constructor(detail)
            return meta.createEvent(ITEM_COUNT_WARNING, detail)
        end

        meta.require(check, get, constructor)
    end

    function meta.requireItemSpace(name, space)
        local function check()
            return robot.hasItemSpace(name, space)
        end

        local function get()
            return {
                name = name,
                missingSpace = space - robot.getItemSpace(name),
                stackSize = getStackSize(name)
            }
        end

        local function constructor(detail)
            return meta.createEvent(ITEM_SPACE_WARNING, detail)
        end

        meta.require(check, get, constructor)
    end

    function meta.requireItemSpaceForUnknown(stackSize, space)
        local function check()
            return robot.hasItemSpaceForUnknown(stackSize, space)
        end

        local function get()
            return {
                name = "unknown",
                missingSpace = space - robot.getItemSpaceForUnknown(stackSize),
                stackSize = stackSize
            }
        end

        local function constructor(detail)
            return meta.createEvent(ITEM_SPACE_WARNING, detail)
        end

        meta.require(check, get, constructor)
    end

    function meta._listSlots(name, limit, includeReservedItems)
        limit = limit or 16
        local slots = {}

        local totalCounts = {}
        for i = 1, 16 do
            local d = nativeTurtle.getItemDetail(i)
            if d then
                totalCounts[d.name] = (totalCounts[d.name] or 0) + d.count
            end
        end

        local reservedUsedForCount = {}
        local reservedUsedForSpace = {}

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail and (not name or detail.name == name) then
                local count = detail.count
                local physicalSpace = nativeTurtle.getItemSpace(i)
                local usableSpace = physicalSpace

                if not includeReservedItems then
                    local reservedTotal = reservedSpaces[detail.name] or 0

                    local alreadyUsedCount = reservedUsedForCount[detail.name] or 0
                    local reservedInSlot = math.min(count, reservedTotal - alreadyUsedCount)
                    count = count - reservedInSlot
                    reservedUsedForCount[detail.name] = alreadyUsedCount + reservedInSlot

                    local currentTotal = totalCounts[detail.name] or 0
                    local missingTotal = math.max(0, reservedTotal - currentTotal)

                    local alreadyBlockedSpace = reservedUsedForSpace[detail.name] or 0
                    local blockInSlot = math.min(physicalSpace, missingTotal - alreadyBlockedSpace)
                    usableSpace = physicalSpace - blockInSlot
                    reservedUsedForSpace[detail.name] = alreadyBlockedSpace + blockInSlot
                end

                if count > 0 or usableSpace > 0 then
                    table.insert(slots, {
                        id = i,
                        name = detail.name,
                        count = count,
                        space = usableSpace
                    })
                end

                if #slots >= limit then
                    return slots
                end
            end
        end
        return slots
    end

    function meta.getFirstSlot(name, includeReservedItems)
        local slots = meta.listSlots(name, 1, includeReservedItems)
        return slots[1]
    end

    function meta.selectFirstSlot(name, includeReservedItems)
        local slot = meta.getFirstSlot(name, includeReservedItems)

        if slot then
            nativeTurtle.select(slot.id)
            return true
        end

        return false
    end

    function meta.listEmptySlots(limit, includeReservedItems, shouldCompact)
        limit = limit or 16

        if shouldCompact then
            compact()
        end

        local reservedEmptySlotCount = includeReservedItems and 0 or countReservedEmptySlots()
        local emptySlots = {}
        local emptyFound = 0

        for i = 1, 16 do
            if nativeTurtle.getItemCount(i) == 0 then
                emptyFound = emptyFound + 1

                if emptyFound > reservedEmptySlotCount then
                    table.insert(emptySlots, {
                        id = i,
                        count = 0,
                        space = getStackSize()
                    })
                end
            end

            if #emptySlots >= limit then
                break
            end
        end

        if #emptySlots == 0 and not shouldCompact then
            return meta.listEmptySlots(limit, includeReservedItems, true)
        end

        return emptySlots
    end

    function meta.getFirstEmptySlot(includeReservedItems)
        local slots = meta.listEmptySlots(1, includeReservedItems)
        return slots[1]
    end

    function meta.selectFirstEmptySlot(includeReservedItems)
        local slot = meta.getFirstEmptySlot(includeReservedItems)

        if slot then
            nativeTurtle.select(slot.id)
            return true
        end

        return false
    end

    function meta.countItems(name, includeReservedItems)
        local count = 0
        local slots = meta.listSlots(name, nil, includeReservedItems)

        for _, slot in ipairs(slots) do
            count = count + slot.count
        end

        return count
    end

    function meta.arrangeSlots(layoutFunc)
        local lockedSlots = {}

        local function setSlot(id, name, count)
            if id < 1 or id > 16 then
                error("id must be in range 1 <= id <= 16", 0)
            end

            count = count or 1

            if not name or count <= 0 then
                if nativeTurtle.getItemCount(id) > 0 and not lockedSlots[id] then
                    nativeTurtle.select(id)
                    for i = 1, 16 do
                        if i ~= id and not lockedSlots[i] then
                            if nativeTurtle.transferTo(i) then
                                break
                            end
                        end
                    end
                end
                lockedSlots[id] = true
                return true
            end

            local currentInTarget = nativeTurtle.getItemDetail(id)

            if currentInTarget and currentInTarget.name ~= name then
                nativeTurtle.select(id)
                for i = 1, 16 do
                    if i ~= id and not lockedSlots[i] then
                        if nativeTurtle.transferTo(i) then
                            break
                        end
                    end
                end
                currentInTarget = nil
            end

            local currentCount = nativeTurtle.getItemCount(id)
            local needed = count - currentCount

            if needed > 0 then
                for sourceId = 1, 16 do
                    if sourceId ~= id and not lockedSlots[sourceId] then
                        local source = nativeTurtle.getItemDetail(sourceId)
                        if source and source.name == name then
                            nativeTurtle.select(sourceId)
                            nativeTurtle.transferTo(id, needed)

                            needed = count - nativeTurtle.getItemCount(id)
                            if needed <= 0 then
                                break
                            end
                        end
                    end
                end
            elseif needed < 0 then
                nativeTurtle.select(id)
                local toRemove = math.abs(needed)
                for i = 1, 16 do
                    if i ~= id and not lockedSlots[i] then
                        if nativeTurtle.transferTo(i, toRemove) then
                            break
                        end
                    end
                end
            end

            lockedSlots[id] = true
            return nativeTurtle.getItemCount(id) == count
        end

        local function clearSlot(id)
            setSlot(id)
        end

        return layoutFunc(setSlot, clearSlot)
    end

    function robot.select(name)
        selectedName = name
    end

    function robot.getSelectedName()
        return selectedName
    end

    function robot.getItemDetail(name)
        name = name or selectedName

        local count = robot.getItemCount(name)

        if count == 0 then
            return nil
        end

        return {
            name = name,
            count = count
        }
    end

    function robot.getItemCount(name)
        name = name or selectedName
        return meta.countItems(name)
    end

    function robot.hasItemCount(name, count)
        name = name or selectedName
        return robot.getItemCount(name) >= (count or 1)
    end

    function robot.getItemSpace(name)
        name = name or selectedName

        local space = 0
        local stackSize = getStackSize(name)
        local slots = meta.listSlots(name)

        for _, slot in ipairs(slots) do
            space = space + slot.space
        end

        space = space + robot.getItemSpaceForUnknown(stackSize)
        return space
    end

    function robot.hasItemSpace(name, space)
        name = name or selectedName
        return robot.getItemSpace(name) >= (space or 1)
    end

    -- TODO [JM] generic get space for unknown must still work after new select logic implemented
    function robot.getItemSpaceForUnknown(stackSize)
        local emptySlots = meta.listEmptySlots()
        return #emptySlots * (stackSize or getStackSize())
    end

    -- TODO [JM] generic has space for unknown must still work after new select logic implemented
    function robot.hasItemSpaceForUnknown(stackSize, space)
        return robot.getItemSpaceForUnknown(stackSize) > (space or 0)
    end

    function robot.listItems()
        local slots = meta.listSlots()
        local names = {}

        for _, slot in pairs(slots) do
            names[slot.name] = true
        end

        local arr = {}

        for name, _ in pairs(names) do
            local count = meta.countItems(name)

            table.insert(arr, {
                name = name,
                count = count
            })
        end

        return arr
    end

    function robot._reserve(name, space)
        name = name or selectedName
        reservedSpaces[name] = (reservedSpaces[name] or 0) + (space or getStackSize(name))
    end

    function robot._free(name, space)
        name = name or selectedName

        if not name then
            reservedSpaces = {}
            return
        end

        reservedSpaces[name] = (reservedSpaces[name] or 0) - (space or getStackSize(name))
    end

    -- TODO [JM] obsolete when new select logic with  *, @items, @reserved is implemented
    function robot.getReservedItemDetail(name)
        name = name or selectedName
        local count = robot.getReservedItemCount(name)

        if count == 0 then
            return nil
        end

        return { name = name, count = count }
    end

    -- TODO [JM] obsolete when new select logic with  *, @items, @reserved is implemented
    function robot.getReservedItemCount(name)
        name = name or selectedName

        local total = meta.countItems(name, true)
        local free = meta.countItems(name)

        return total - free
    end

    -- TODO [JM] obsolete when new select logic with  *, @items, @reserved is implemented
    function robot.hasReservedItemCount(name, count)
        name = name or selectedName
        return robot.getReservedItemCount(name) >= (count or 1)
    end

    -- TODO [JM] obsolete when new select logic with  *, @items, @reserved is implemented
    function robot.getReservedItemSpace(name)
        name = name or selectedName

        local count = robot.getReservedItemCount(name)
        return reservedSpaces[name] - count
    end

    -- TODO [JM] obsolete when new select logic with  *, @items, @reserved is implemented
    function robot.hasReservedItemSpace(name, space)
        name = name or selectedName
        return robot.getReservedItemSpace(name) >= (space or 1)
    end

    -- TODO [JM] obsolete when new select logic with  *, @items, @reserved is implemented
    function robot.listReservedItems()
        local arr = {}

        for name, _ in pairs(reservedSpaces) do
            local detail = robot.getReservedItemDetail(name)

            if detail then
                table.insert(arr, detail)
            end
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
