-- TODO [JM] implement the generic inventory api
return {
    name = "minecraft:chest",
    constructor = function(opts)
        local robot = opts.robot
        local meta = opts.meta
        local target = opts.target

        local function listSlots(name, limit)
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

        local function countItems(name, includeReservedItems)
            local count = 0
            local slots = meta.listSlots(name, nil, includeReservedItems)

            for _, slot in ipairs(slots) do
                count = count + slot.count
            end

            return count
        end

        return {
            import = function(name, count, blocking)
                return robot.drop(name, count, blocking)
            end,
            export = function(name, count, blocking)

            end,
            getItemDetail = function(name)

            end,
            listItems = function()

            end
        }
    end
}
