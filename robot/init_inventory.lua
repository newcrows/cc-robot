return function(robot, meta)
    local selectedName
    local reservedSpaces = {}

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
        local blacklist = {}
        local setSlot = function(slotId, name, count)
            if blacklist[slotId] then
                error("slot " .. tostring(slotId) .. " was already set in current arrangeSlots() call")
            end

            setSlotHolder.setSlot(slotId, name, count, blacklist)
            blacklist[slotId] = true

            return true
        end

        return layoutFunc(setSlot)
    end

    function robot.select(name)
        selectedName = name
    end

    function robot.getSelectedName()
        return selectedName
    end

    function robot.getItemDetail(name)
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
        return meta.countItems(name, false)
    end

    function robot.hasItemCount(name, count)
        return robot.getItemCount(name) >= (count or 1)
    end

    function robot.getItemSpace(name)
        local space = 0
        local stackSize = getStackSize(name)

        for _, slot in ipairs(meta.listSlots(name, nil, false)) do
            space = space + slot.space
        end

        space = space + robot.getItemSpaceForUnknown(stackSize)
        return space
    end

    function robot.hasItemSpace(name, count)
        return robot.getItemSpace(name) >= (count or 1)
    end

    function robot.getItemSpaceForUnknown(stackSize)
        local emptySlots = meta.listEmptySlots(nil, false)
        return #emptySlots * (stackSize or 64)
    end

    function robot.hasItemSpaceForUnknown()
        return #meta.listEmptySlots(nil, false) > 0
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
        reservedSpaces[name] = (reservedSpaces[name] or 0) + (count or 64)
    end

    function robot.free(name, count)
        if not name then
            reservedSpaces = {}
            return
        end

        reservedSpaces[name] = (reservedSpaces[name] or 0) - (count or 64)
    end

    function robot.getReservedItemDetail(name)
        local count = robot.getReservedItemCount(name)

        if count == 0 then
            return nil
        end

        return { name = name, count = count }
    end

    function robot.getReservedItemCount(name)
        local total = meta.countItems(name, true)
        local free = meta.countItems(name, false)

        return total - free
    end

    function robot.hasReservedItemCount(name, count)
        return robot.getReservedItemCount(name) >= (count or 1)
    end

    function robot.getReservedItemSpace(name)
        local count = robot.getReservedItemCount(name)
        return reservedSpaces[name] - count
    end

    function robot.hasReservedItemSpace(name, count)
        return robot.getReservedItemSpace(name) >= (count or 1)
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
