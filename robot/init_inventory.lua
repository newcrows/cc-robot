return function(robot, meta)
    local selectedName
    local reservedSpaces = {}
    local spaceWarningListenerId
    local spaceWarningClearedListenerId

    local function compact()
        for targetSlot = 1, 15 do
            local space = turtle.getItemSpace(targetSlot)

            if space > 0 then
                local target = turtle.getItemDetail(targetSlot)

                for sourceSlot = 16, targetSlot + 1, -1 do
                    local source = turtle.getItemDetail(sourceSlot)

                    if source then
                        if not target or source.name == target.name then
                            turtle.select(sourceSlot)
                            if turtle.transferTo(targetSlot) then
                                target = turtle.getItemDetail(targetSlot)
                                space = turtle.getItemSpace(targetSlot)
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
        return slot and slot.count + slot.space or 64
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

    local function waitForSpace(check)
        local waited = false

        while not check() do
            if waited then
                compact()
                os.sleep(1)
            end

            meta.dispatchEvent("space_warning", check, waited)
            waited = true
        end

        meta.dispatchEvent("space_warning_cleared")
    end

    function meta.requireItemSpace(name, space)
        local function check()
            return robot.hasItemSpace(name, space)
        end

        waitForSpace(check)
    end

    function meta.requireUnknownItemSpace(stackSize, space)
        local function check()
            return robot.hasItemSpaceForUnknown(stackSize, space)
        end

        waitForSpace(check)
    end

    function meta.listSlots(name, limit, includeReservedItems)
        limit = limit or 16
        local slots = {}

        -- 1. Durchlauf: Brutto-Bestand pro Item-Typ ermitteln
        local totalCounts = {}
        for i = 1, 16 do
            local d = turtle.getItemDetail(i)
            if d then
                totalCounts[d.name] = (totalCounts[d.name] or 0) + d.count
            end
        end

        -- 2. Durchlauf: Slots filtern und logischen Space/Count berechnen
        local reservedUsedForCount = {}
        local reservedUsedForSpace = {}

        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if detail and (not name or detail.name == name) then
                local count = detail.count
                local physicalSpace = turtle.getItemSpace(i)
                local usableSpace = physicalSpace

                if not includeReservedItems then
                    local reservedTotal = reservedSpaces[detail.name] or 0

                    -- LOGIK FÜR COUNT: Reservierung "frisst" vorhandene Items von vorne auf
                    local alreadyUsedCount = reservedUsedForCount[detail.name] or 0
                    local reservedInSlot = math.min(count, reservedTotal - alreadyUsedCount)
                    count = count - reservedInSlot
                    reservedUsedForCount[detail.name] = alreadyUsedCount + reservedInSlot

                    -- LOGIK FÜR SPACE: Fehlende Reservierung blockiert physischen Platz
                    local currentTotal = totalCounts[detail.name] or 0
                    local missingTotal = math.max(0, reservedTotal - currentTotal)

                    local alreadyBlockedSpace = reservedUsedForSpace[detail.name] or 0
                    local blockInSlot = math.min(physicalSpace, missingTotal - alreadyBlockedSpace)
                    usableSpace = physicalSpace - blockInSlot
                    reservedUsedForSpace[detail.name] = alreadyBlockedSpace + blockInSlot
                end

                -- Slot aufnehmen, wenn er freien Count ODER freien Space bietet
                if includeReservedItems or count > 0 or usableSpace > 0 then
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
            turtle.select(slot.id)
            return true
        end

        return false
    end

    function meta.listEmptySlots(limit, shouldCompact)
        limit = limit or 16

        if shouldCompact then
            compact()
        end

        local reservedEmptySlotCount = countReservedEmptySlots()
        local emptySlots = {}
        local emptyFound = 0

        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                emptyFound = emptyFound + 1

                if emptyFound > reservedEmptySlotCount then
                    table.insert(emptySlots, {
                        id = i,
                        name = nil,
                        count = 0,
                        space = 64
                    })
                end
            end

            if #emptySlots >= limit then
                break
            end
        end

        return emptySlots
    end

    function meta.getFirstEmptySlot(shouldCompact)
        local slots = meta.listEmptySlots(1, shouldCompact)
        return slots[1]
    end

    function meta.selectFirstEmptySlot(shouldCompact)
        local slot = meta.getFirstEmptySlot(shouldCompact)

        if slot then
            turtle.select(slot.id)
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
                return false
            end
            count = count or 0

            if not name or count <= 0 then
                if turtle.getItemCount(id) > 0 and not lockedSlots[id] then
                    turtle.select(id)
                    for i = 1, 16 do
                        if i ~= id and not lockedSlots[i] then
                            if turtle.transferTo(i) then
                                break
                            end
                        end
                    end
                end
                lockedSlots[id] = true
                return true
            end

            local currentInTarget = turtle.getItemDetail(id)

            if currentInTarget and currentInTarget.name ~= name then
                turtle.select(id)
                for i = 1, 16 do
                    if i ~= id and not lockedSlots[i] then
                        if turtle.transferTo(i) then
                            break
                        end
                    end
                end
                currentInTarget = nil
            end

            local currentCount = turtle.getItemCount(id)
            local needed = count - currentCount

            if needed > 0 then
                for sourceId = 1, 16 do
                    if sourceId ~= id and not lockedSlots[sourceId] then
                        local source = turtle.getItemDetail(sourceId)
                        if source and source.name == name then
                            turtle.select(sourceId)
                            turtle.transferTo(id, needed)

                            needed = count - turtle.getItemCount(id)
                            if needed <= 0 then
                                break
                            end
                        end
                    end
                end
            elseif needed < 0 then
                turtle.select(id)
                local toRemove = math.abs(needed)
                for i = 1, 16 do
                    if i ~= id and not lockedSlots[i] then
                        if turtle.transferTo(i, toRemove) then
                            break
                        end
                    end
                end
            end

            lockedSlots[id] = true
            return turtle.getItemCount(id) == count
        end

        local function clearSlot(id)
            setSlot(id)
        end

        -- Führe das Layout aus
        return layoutFunc(setSlot, clearSlot)
    end

    function robot.onSpaceWarning(callback)
        if spaceWarningListenerId then
            meta.removeEventListener(spaceWarningListenerId)
            spaceWarningListenerId = nil
        end

        if callback then
            spaceWarningListenerId = meta.addEventListener({
                space_warning = callback
            })
        end
    end

    function robot.onSpaceWarningCleared(callback)
        if spaceWarningClearedListenerId then
            meta.removeEventListener(spaceWarningClearedListenerId)
            spaceWarningClearedListenerId = nil
        end

        if callback then
            spaceWarningClearedListenerId = meta.addEventListener({
                space_warning_cleared = callback
            })
        end
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
        return meta.countItems(name, false)
    end

    function robot.hasItemCount(name, count)
        name = name or selectedName
        return robot.getItemCount(name) >= (count or 1)
    end

    function robot.getItemSpace(name)
        name = name or selectedName

        local space = 0
        local stackSize = getStackSize(name)

        for _, slot in ipairs(meta.listSlots(name, nil, false)) do
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
        local emptySlots = meta.listEmptySlots(nil, false)
        return #emptySlots * (stackSize or 64)
    end

    function robot.hasItemSpaceForUnknown(stackSize, space)
        return robot.getItemSpaceForUnknown(stackSize) > (space or 0)
    end

    function robot.listItems()
        local slots = meta.listSlots(nil, nil, false)
        local names = {}

        for _, slot in pairs(slots) do
            local detail = turtle.getItemDetail(slot.id)

            if detail then
                names[detail.name] = true
            end
        end

        local items = {}

        for name, _ in pairs(names) do
            local detail = robot.getItemDetail(name)

            if detail then
                table.insert(items, detail)
            end
        end

        return items
    end

    function robot.reserve(name, count)
        name = name or selectedName
        reservedSpaces[name] = (reservedSpaces[name] or 0) + (count or getStackSize(name))
    end

    function robot.free(name, space)
        name = name or selectedName

        if not name then
            reservedSpaces = {}
            return
        end

        reservedSpaces[name] = (reservedSpaces[name] or 0) - (space or 64)
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
        local free = meta.countItems(name, false)

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
        local list = {}
        for name, _ in pairs(reservedSpaces) do
            local count = robot.getReservedItemCount(name)
            if count > 0 then
                list[name] = count
            end
        end
        return list
    end
end
