return {
    name = "minecraft:chest",
    constructor = function(opts)
        local targetChest = opts.target
        local targetName = peripheral.getName(targetChest)
        local helperChest
        local hasPickaxe = meta.hasEquipment("minecraft:diamond_pickaxe")

        if not targetChest then
            return nil
        end

        local function onAnyWrap(side, name)
            if name == "minecraft:chest" and side ~= "top" then
                robot.free("minecraft:chest", 1)

                if hasPickaxe and robot.placeUp("minecraft:chest") then
                    os.sleep(0.1)
                    helperChest = peripheral.wrap("top")
                end
            end
        end

        local function onAnyUnwrap(side, name)
            if name == "minecraft:chest" and side ~= "top" then
                if helperChest then
                    robot.equip("minecraft:diamond_pickaxe").digUp()
                    robot.reserve("minecraft:chest", 1)

                    helperChest = nil
                end
            end
        end

        local function findEmptySlotInChest()
            for i = 1, 9 * 3 do
                if not targetChest.getItemDetail(i) then
                    return i
                end
            end

            error("no empty slot in chest")
        end

        local function makeFirstSlotEmptyIfNot(name)
            local detail = targetChest.getItemDetail(1)

            if detail and detail.name ~= name then
                local emptySlot = findEmptySlotInChest()
                targetChest.pushItems(targetName, 1, 64, emptySlot)
            end
        end

        local function moveStackToFirstSlot(name)
            for slot, detail in pairs(targetChest.list()) do
                if detail.name == name then
                    targetChest.pushItems(targetName, slot, 64, 1)
                    return true
                end
            end

            return false
        end

        local function isReachableAndNotFull()
            local reachableSides = {
                front = true,
                top = true,
                bottom = true
            }

            local reachable = reachableSides[opts.side]
            local notFull, _ = pcall(findEmptySlotInChest)

            return reachable and notFull
        end

        local function exportReachableSide(name, count, blocking)
            if type(name) == "boolean" then
                blocking = name
                count = nil
                name = nil
            elseif type(name) == "number" then
                blocking = count
                count = name
                name = nil
            elseif type(name) == "string" and type("count") == "boolean" then
                blocking = count
                count = nil
            end

            name = name or robot.getSelectedName()

            local suckFuncs = {
                front = robot.suck,
                top = robot.suckUp,
                bottom = robot.suckDown
            }

            local suckFunc = suckFuncs[opts.side]

            local amount = 0
            makeFirstSlotEmptyIfNot(name)

            while amount < count do
                if not moveStackToFirstSlot(name) and not blocking then
                    return amount, name .. " not found in chest"
                end

                local detail = targetChest.getItemDetail(1)

                if detail then
                    local suckCount = math.min(detail.count, count - amount)
                    amount = amount + suckFunc(suckCount, blocking)
                end
            end

            return amount
        end

        local function exportWithHelperChest(name, count, blocking)
            if type(name) == "boolean" then
                blocking = name
                count = nil
                name = nil
            elseif type(name) == "number" then
                blocking = count
                count = name
                name = nil
            elseif type(name) == "string" and type("count") == "boolean" then
                blocking = count
                count = nil
            end

            name = name or robot.getSelectedName()

            assert(helperChest, "missing helper chest, can't export")
            local amount = 0

            while true do
                for slot, detail in pairs(targetChest.list()) do
                    if detail.name == name then
                        local pullAmount = math.min(detail.count, count - amount)
                        amount = amount + helperChest.pullItems(targetName, slot, pullAmount)
                    end
                end

                if amount < count and blocking then
                    os.sleep(1)
                else
                    break
                end
            end

            return robot.suckUp(amount, blocking)
        end

        if not isReachableAndNotFull() then
            meta.addEventListener({
                wrap = onAnyWrap,
                unwrap = onAnyUnwrap,
                soft_wrap = onAnyWrap,
                soft_unwrap = onAnyUnwrap
            })
        end

        return {
            import = function(name, count, blocking)
                return robot.drop(name, count, blocking)
            end,
            export = isReachableAndNotFull() and exportReachableSide or exportWithHelperChest,
            getItemDetail = function(name)
                local count = 0

                for _, detail in pairs(targetChest.list()) do
                    if detail.name == name then
                        count = count + detail.count
                    end
                end

                return {
                    name = name,
                    count = count
                }
            end,
            listItems = function()
                local items = {}

                for _, detail in pairs(targetChest.list()) do
                    local item = items[detail.name]

                    if not item then
                        item = { name = detail.name, count = 0 }
                        items[detail.name] = item
                    end

                    item.count = item.count + detail.count
                end

                local arr = {}

                for _, item in pairs(items) do
                    table.insert(arr, item)
                end

                return arr
            end
        }
    end
}
