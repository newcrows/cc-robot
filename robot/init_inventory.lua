return function(robot, meta)
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

    local function getPhysicalEmptySlots()
        local emptySlots = 0

        for i = 1, 16 do
            local detail = turtle.getItemDetail(i)

            if not detail then
                emptySlots = emptySlots + 1
            end
        end

        return emptySlots
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

    local function compactPhysical()

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

    local function getEmptySlotsNeededForEquipmentAndReserved()
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

        for name, space in pairs(meta.reservedSpaces) do
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

    end

    function meta.getFirstSlot(name, includeEquipment, includeReservedItems)

    end

    function meta.selectFirstSlot(name, includeEquipment, includeReservedItems)

    end

    function meta.listEmptySlots(limit, compact)

    end

    function meta.getFirstEmptySlot(compact)

    end

    function meta.selectFirstEmptySlot(compact)

    end

    function meta.countItems(name, includeEquipment, includeReservedItems)

    end

    function meta.arrangeSlots(layoutFunc)
        local touchedSlots = {}
        local setSlot = function(slotId, name, count)
            if touchedSlots[slotId] then
                error("slot " .. tostring(slotId) .. " was already set in current arrangeSlots() call")
            end

            -- do the actual arrangement here
            return true
        end

        return layoutFunc(setSlot)
    end

    function robot.select(name)

    end

    function robot.getSelectedName()

    end

    function robot.getItemDetail(name)

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

        local availableEmptySlots = getPhysicalEmptySlots() - getEmptySlotsNeededForEquipmentAndReserved()
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

    end

    function robot.reserve(name, count)

    end

    function robot.free(name, count)

    end

    function robot.getReservedItemDetail(name)

    end

    function robot.getReservedItemCount(name)
        name = name or meta.selectedName

        if not meta.reservedSpaces[name] then
            return 0
        end

        return math.min(getPhysicalCount(name) - getEquipmentCount(name), meta.reservedSpaces[name])
    end

    function robot.getReservedItemSpace(name)
        name = name or meta.selectedName

        if not meta.reservedSpaces[name] then
            return 0
        end

        return meta.reservedSpaces[name] - robot.getReservedItemCount(name)
    end

    function robot.hasReservedItemCount(name)
        return robot.getReservedItemCount(name) > 0
    end

    function robot.hasReservedItemSpace(name)
        return robot.getReservedItemSpace(name) > 0
    end

    function robot.listReservedItems()
        local arr = {}

        for name, _ in pairs(meta.reservedSpaces) do
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
end
