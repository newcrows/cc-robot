return function(robot, meta)
    local reservedSpaces = {}

    local function getPhysicalCount(name)
        local count = 0

        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if detail and detail.name == name then
                count = count + detail.count
            end
        end

        return count
    end

    local function getPhysicalSpace(name)
        local space = 0
        local emptySlots = 0
        local stackSize

        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if detail and detail.name == name then
                local slotSpace = turtle.getItemSpace(i)

                if not stackSize then
                    stackSize = detail.count + slotSpace
                end

                space = space + slotSpace
            elseif not detail then
                emptySlots = emptySlots + 1
            end
        end

        if not stackSize then
            stackSize = 64
        end

        return space + emptySlots * stackSize
    end

    local function getPhysicalStackSize(name)
        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if detail and detail.name == name then
                return detail.count + turtle.getItemSpace(i)
            end
        end

        return 64
    end

    local function countPhysicalEmptySlots()
        local emptySlots = 0

        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if not detail then
                emptySlots = emptySlots + 1
            end
        end

        return emptySlots
    end

    local function compactPhysical()
        local slots = meta.listSlots(nil, nil, true, true)

        for i = #slots, 1, -1 do
            local slot = slots[i]
            local likeSlots = meta.listSlots(slot.name, nil, true, true)

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

    local function getEquipmentCount(name)
        name = name or meta.selectedName

        local proxy = meta.equipProxies[name]

        if proxy and not proxy.target then
            return 1
        end

        return 0
    end

    local function getEquipmentSpace(name)
        name = name or meta.selectedName

        local proxy = meta.equipProxies[name]

        if proxy and proxy.target then
            return 1
        end

        return 0
    end

    local function countEmptySlotsNeededForEquipmentAndReserved()
        local itemsWeNeedSpaceFor = {}

        for _, proxy in pairs(meta.equipProxies) do
            if proxy.target then
                itemsWeNeedSpaceFor[proxy.name] = (itemsWeNeedSpaceFor[proxy.name] or 0) + 1
            end
        end

        local itemsWeHaveCountOf = {}
        local itemsWeHaveSpaceFor = {}

        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if detail then
                local space = turtle.getItemSpace(i)

                itemsWeHaveCountOf[detail.name] = (itemsWeHaveCountOf[detail.name] or 0) + detail.count
                itemsWeHaveSpaceFor[detail.name] = (itemsWeHaveSpaceFor[detail.name] or 0) + space
            end
        end

        for name, space in pairs(reservedSpaces) do
            local additionalSpaceWeNeed = math.max(space - (itemsWeHaveCountOf[name] or 0), 0)
            itemsWeNeedSpaceFor[name] = (itemsWeNeedSpaceFor[name] or 0) + additionalSpaceWeNeed
        end

        local emptySlotsWeNeed = 0

        for name, space in pairs(itemsWeNeedSpaceFor) do
            local stackSize = getPhysicalStackSize(name)
            emptySlotsWeNeed = emptySlotsWeNeed + math.ceil(space / stackSize)
        end

        return emptySlotsWeNeed
    end

    function meta.listSlots(name, limit, includeEquipment, includeReservedItems)
        limit = limit or 16

        local slots = {}
        local seenEquipment = {}
        local seenReservedItems = {}

        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if detail and not name or detail and detail.name == name then
                local countOffset = 0

                if not includeEquipment and not seenEquipment[detail.name] then
                    local equipment = meta.getEquipmentDetail(detail.name)

                    if equipment and not equipment.proxy.target then
                        countOffset = -1
                        seenEquipment[detail.name] = true
                    end
                end

                if not includeReservedItems then
                    local invisibleCount = reservedSpaces[detail.name]
                    local seenInvisibleCount = seenReservedItems[detail.name] or 0

                    if invisibleCount and seenInvisibleCount < invisibleCount then
                        local invisibleCountOffset = -math.min(detail.count + countOffset, invisibleCount - seenInvisibleCount)

                        countOffset = countOffset + invisibleCountOffset
                        seenReservedItems[detail.name] = seenInvisibleCount - invisibleCountOffset
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

    function meta.getFirstSlot(name, includeEquipment, includeReservedItems)
        local slots = meta.listSlots(name, 1, includeEquipment, includeReservedItems)
        return slots[1]
    end

    function meta.selectFirstSlot(name, includeEquipment, includeReservedItems)
        local slot = meta.getFirstSlot(name, includeEquipment, includeReservedItems)

        if slot then
            turtle.select(slot.id)
            return true
        end

        return false
    end

    function meta.listEmptySlots(limit, compact)
        local neededEmptySlotCount = countEmptySlotsNeededForEquipmentAndReserved()
        local slots = {}

        if compact then
            compactPhysical()
        end

        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                if neededEmptySlotCount == 0 then
                    table.insert(slots, {
                        id = i,
                        count = 0
                    })
                else
                    neededEmptySlotCount = neededEmptySlotCount - 1
                end

                if #slots == limit then
                    return slots
                end
            end
        end

        return slots
    end

    function meta.getFirstEmptySlot(compact)
        local slots = meta.listEmptySlots(1, compact)
        return slots[1]
    end

    function meta.selectFirstEmptySlot(compact)
        local slot = meta.getFirstEmptySlot(compact)

        if slot then
            turtle.select(slot.id)
            return true
        end

        return false
    end

    function meta.countItems(name, includeEquipment, includeReservedItems)
        local count = 0
        local slots = meta.listSlots(name, 16, includeEquipment, includeReservedItems)

        for i = 1, #slots do
            count = count + slots[i].count
        end

        return count
    end

    function meta.arrangeSlots(layoutFunc)
        local touchedSlots = {}
        local setSlot = function(slotId, name, count)
            if touchedSlots[slotId] then
                error("slot " .. tostring(slotId) .. " was already set in current arrangeSlots() call")
            end

            -- TODO [JM] implement

            return true
        end

        return layoutFunc(setSlot)
    end

    function robot.select(name)
        assert(name, "name must not be nil")
        meta.selectedName = name
    end

    function robot.getSelectedName()
        return meta.selectedName
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

    function robot.getItemCount(name)
        name = name or meta.selectedName
        return getPhysicalCount(name) - getEquipmentCount(name) - robot.getReservedItemCount(name)
    end

    function robot.getItemSpace(name)
        name = name or meta.selectedName
        return getPhysicalSpace(name) - getEquipmentSpace(name) - robot.getReservedItemSpace(name)
    end

    function robot.getItemSpaceForUnknown(stackSize)
        stackSize = stackSize or 64

        local availableEmptySlots = countPhysicalEmptySlots() - countEmptySlotsNeededForEquipmentAndReserved()
        return availableEmptySlots * stackSize
    end

    function robot.hasItemCount(name)
        return robot.hasItemCount(name) > 0
    end

    function robot.hasItemSpace(name)
        return robot.hasItemSpace(name) > 0
    end

    function robot.hasItemSpaceForUnknown(stackSize)
        return robot.getItemSpaceForUnknown(stackSize) > 0
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

        local arr = {}

        for _, item in pairs(items) do
            table.insert(arr, item)
        end

        return arr
    end

    function robot.reserve(name, count)
        name = name or meta.selectedName
        count = count or 1

        reservedSpaces[name] = (reservedSpaces[name] or 0) + count
    end

    function robot.free(name, count)
        name = name or meta.selectedName
        count = count or 1

        reservedSpaces[name] = (reservedSpaces[name] or 0) - count
    end

    function robot.getReservedItemDetail(name)
        name = name or meta.selectedName
        local count = robot.getReservedItemCount(name)

        if count > 0 then
            return {
                name = name,
                count = count
            }
        end

        return nil
    end

    function robot.getReservedItemCount(name)
        name = name or meta.selectedName

        if not reservedSpaces[name] then
            return 0
        end

        return math.min(getPhysicalCount(name) - getEquipmentCount(name), reservedSpaces[name])
    end

    function robot.getReservedItemSpace(name)
        name = name or meta.selectedName

        if not reservedSpaces[name] then
            return 0
        end

        return reservedSpaces[name] - robot.getReservedItemCount(name)
    end

    function robot.hasReservedItemCount(name)
        return robot.getReservedItemCount(name) > 0
    end

    function robot.hasReservedItemSpace(name)
        return robot.getReservedItemSpace(name) > 0
    end

    function robot.listReservedItems()
        local arr = {}

        for name, _ in pairs(reservedSpaces) do
            local count = robot.getReservedItemCount(name)

            if count > 0 then
                table.insert({
                    name = name,
                    count = count
                })
            end
        end

        return arr
    end

    robot.select("air")
end
