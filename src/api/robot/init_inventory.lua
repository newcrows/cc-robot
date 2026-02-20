return function(robot, meta, constants)
    local selectedName
    local reservedSpaces = {}
    local countWarningListenerId
    local countWarningClearedListenerId
    local spaceWarningListenerId
    local spaceWarningClearedListenerId

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

    local function countReservedEmptySlots()
        local reservedEmptySlots = 0

        for name, reservedTotal in pairs(reservedSpaces) do
            local currentCount = meta.countItems(name, true)
            local missing = reservedTotal - currentCount

            if missing > 0 then
                local existingSpace = 0
                local slots = meta.listSlots(name, nil, true)

                for _, slot in ipairs(slots) do
                    existingSpace = existingSpace + slot.space
                end

                local overflow = missing - existingSpace

                if overflow > 0 then
                    local stackSize = getStackSize(name)
                    reservedEmptySlots = reservedEmptySlots + math.ceil(overflow / stackSize)
                end
            end
        end

        return reservedEmptySlots
    end

    function meta.requireItemCount(name, count)
        local function check()
            return robot.hasItemCount(name, count)
        end

        local function get()
            return check, name, count, getStackSize(name)
        end

        meta.ensureCleared(check, get, "count_warning")
    end

    function meta.requireItemSpace(name, space)
        local function check()
            return robot.hasItemSpace(name, space)
        end

        local function get()
            return check, name, space, getStackSize(name)
        end

        meta.ensureCleared(check, get, "space_warning")
    end

    function meta.requireItemSpaceForUnknown(stackSize, space)
        local function check()
            return robot.hasItemSpaceForUnknown(stackSize, space)
        end

        local function get()
            return check, "unknown", space, stackSize
        end

        meta.ensureCleared(check, get, "space_warning")
    end

    function meta.listSlots(name, limit, includeReservedItems)
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
                error("id must be in range 1 <= id <= 16")
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

    function robot.getItemSpaceForUnknown(stackSize)
        local emptySlots = meta.listEmptySlots()
        return #emptySlots * (stackSize or getStackSize())
    end

    function robot.hasItemSpaceForUnknown(stackSize, space)
        return robot.getItemSpaceForUnknown(stackSize) > (space or 0)
    end

    function robot.listItems()
        local slots = meta.listSlots()
        local names = {}

        for _, slot in pairs(slots) do
            local detail = nativeTurtle.getItemDetail(slot.id)

            if detail then
                names[detail.name] = true
            end
        end

        local arr = {}

        for name, _ in pairs(names) do
            local detail = robot.getItemDetail(name)

            if detail then
                table.insert(arr, detail)
            end
        end

        return arr
    end

    function robot.reserve(name, space)
        name = name or selectedName
        reservedSpaces[name] = (reservedSpaces[name] or 0) + (space or getStackSize(name))
    end

    function robot.free(name, space)
        name = name or selectedName

        if not name then
            reservedSpaces = {}
            return
        end

        reservedSpaces[name] = (reservedSpaces[name] or 0) - (space or getStackSize(name))
    end

    function robot.getReservedItemDetail(name)
        name = name or selectedName
        local count = robot.getReservedItemCount(name)

        if count == 0 then
            return nil
        end

        return { name = name, count = count }
    end

    function robot.getReservedItemCount(name)
        name = name or selectedName

        local total = meta.countItems(name, true)
        local free = meta.countItems(name)

        return total - free
    end

    function robot.hasReservedItemCount(name, count)
        name = name or selectedName
        return robot.getReservedItemCount(name) >= (count or 1)
    end

    function robot.getReservedItemSpace(name)
        name = name or selectedName

        local count = robot.getReservedItemCount(name)
        return reservedSpaces[name] - count
    end

    function robot.hasReservedItemSpace(name, space)
        name = name or selectedName
        return robot.getReservedItemSpace(name) >= (space or 1)
    end

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

    function robot.onCountWarning(callback)
        meta.on("count_warning", callback)
    end

    function robot.onCountWarningCleared(callback)
        meta.on("count_warning_cleared", callback)
    end

    function robot.onSpaceWarning(callback)
        meta.on("space_warning", callback)
    end

    function robot.onSpaceWarningCleared(callback)
        meta.on("space_warning_cleared", callback)
    end

    robot.onCountWarning(function(alreadyWarned, _, name, count)
        if not alreadyWarned then
            print("---- count_warning ----")
            print("need " .. count .. " of " .. name)
            print("-----------------------")
        end
    end)
    robot.onCountWarningCleared(function()
        print("---- count_warning_cleared ----")
    end)

    robot.onSpaceWarning(function(alreadyWarned, _, name, space)
        if not alreadyWarned then
            print("---- space_warning ----")

            if name == "unknown" then
                print("need space for " .. space .. " unknown items")
            else
                print("need space for " .. space .. " " .. name)
            end

            print("-----------------------")
        end
    end)
    robot.onSpaceWarningCleared(function()
        print("---- space_warning_cleared ----")
    end)
end
