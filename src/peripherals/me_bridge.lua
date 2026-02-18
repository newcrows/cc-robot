return {
    name = "advancedperipherals:me_bridge",
    constructor = function(opts)
        local side = opts.side
        local target = opts.target
        local facings = {
            front = robot.facing,
            top = FACINGS.up,
            bottom = FACINGS.down
        }

        if not target then
            return nil
        end

        local facing = facings[side]
        local oppFacing = OPPOSITE_FACINGS[facing]

        return {
            import = function(name, count, blocking)
                assert(name, "name must not be nil")
                local amount = 0

                while true do
                    local rCount = robot.getItemCount(name)

                    if not count or rCount < count then
                        count = rCount
                    end

                    if count == 0 and not blocking then
                        return 0, name .. " not found in turtle inventory"
                    end

                    amount = amount + target.importItem({ name = name, count = count }, oppFacing)

                    if amount == count or not blocking then
                        return amount
                    end

                    os.sleep(1)
                end
            end,
            -- TODO [JM] impl blocking
            export = function(name, count, blocking)
                assert(name, "name must not be nil")

                if not count then
                    local item = target.getItem({ name = name })

                    if item then
                        count = item.count
                    else
                        return 0, name .. " not found in me_network"
                    end
                end

                if robot.getItemSpace(name) < count then
                    meta.compact()
                end

                return target.exportItem({ name = name, count = count }, oppFacing)
            end,
            getItemDetail = function(name)
                if not name then
                    error("name must not be nil")
                end

                return target.getItem({ name = name })
            end,
            listItems = function()
                return target.getItems()
            end
        }
    end
}
