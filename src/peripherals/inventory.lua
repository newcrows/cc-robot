-- TODO [JM] implement the generic inventory api
-- TODO [JM] must be function(robot, meta, constants) -> return instead of plain return
--  -> we can pass robot, meta, constants so custom peripherals have access to context
--  -> this means we can lighten the opts passed by softWrap()
--      and remove robot, meta, constants from the opts object passed to constructor
-- sides is optional, but:
-- -> inventory (i.E. chest) needs to use robot.drop / robot.suck
-- -> drop/suck only work on front, top and bottom of the robot
-- -> so we generally constrict sides to {front, top, bottom} of robot
-- -> this makes it work correctly with peripheral#softWrap() and robot.moveTo(peripheral)
-- TODO [JM] peripheral#softWrap() must throw error when robot side not in sides
return function(robot, meta, constants)
    local SIDES = constants.sides

    return {
        name = "minecraft:chest",
        sides = {
            SIDES.front,
            SIDES.top,
            SIDES.bottom
        },
        constructor = function(opts)
            local side = opts.side
            local target = opts.target

            local inventory = {}

            local function listSlots(name, limit)
                name = name or robot.getSelectedName()
                limit = limit or target.size()
                local slots = {}

                for i = 1, target.size() do
                    local detail = target.getItemDetail(i)

                    if detail and (not name or detail.name == name) then
                        local count = detail.count

                        if count > 0 then
                            table.insert(slots, {
                                id = i,
                                name = detail.name,
                                count = count
                            })
                        end

                        if #slots >= limit then
                            return slots
                        end
                    end
                end
                return slots
            end

            local function getFirstSlot(name)
                local slots = listSlots(name, 1)
                return slots[1]
            end

            local function countItems(name)
                local count = 0
                local slots = meta.listSlots(name)

                for _, slot in ipairs(slots) do
                    count = count + slot.count
                end

                return count
            end

            function inventory.import(name, count, blocking)
                local dropFunc = ({
                    front = robot.drop,
                    top = robot.dropUp,
                    bottom = robot.dropDown
                })[side]

                if not dropFunc then
                    error("can not robot.drop() to side " .. side)
                end

                return dropFunc(name, count, blocking)
            end

            function inventory.export(name, count, blocking)
                -- TODO [JM] implement
            end

            function inventory.getItemDetail(name)
                name = name or robot.getSelectedName()
                local count = countItems(name)

                if count > 0 then
                    return {
                        name = name,
                        count = count
                    }
                end
            end

            function inventory.listItems()
                local slots = listSlots()
                local names = {}

                for _, slot in pairs(slots) do
                    names[slot.name] = true
                end

                local arr = {}

                for name, _ in pairs(names) do
                    local count = countItems(name)

                    table.insert(arr, {
                        name = name,
                        count = count
                    })
                end

                return arr
            end

            return inventory
        end
    }
end
