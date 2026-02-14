return function(robot, meta, constants)
    local equipmentProxies = {}

    function robot.equip(name, pinned)
        -- TODO [JM] implement
    end

    function robot.unequip(name)
        -- TODO [JM] implement
    end

    function robot.getEquipmentDetail(name)
        name = name or meta.selectedName
        local proxy = equipmentProxies[name]

        if proxy then
            return {
                name = name,
                proxy = proxy
            }
        end

        return nil
    end

    function robot.hasEquipment(name)
        return robot.getEquipmentDetail(name) and true or false
    end

    function robot.listEquipment()
        local arr = {}

        for name, proxy in pairs(equipmentProxies) do
            table.insert(arr, {
                name = name,
                proxy = proxy
            })
        end

        return arr
    end

    local digToolConstructor = function(opts)
        -- implement dig tool constructor here
        -- TODO [JM] implement
    end

    local attackToolConstructor = function(opts)
        -- implement attack tool constructor here
        -- TODO [JM] implement
    end

    local craftToolConstructor = function(opts)
        -- implement craft tool constructor here
        -- TODO [JM] implement
    end

    meta.addConstructor("minecraft:diamond_pickaxe", digToolConstructor)
    meta.addConstructor("minecraft:diamond_axe", digToolConstructor)
    meta.addConstructor("minecraft:diamond_shovel", digToolConstructor)
    meta.addConstructor("minecraft:diamond_sword", attackToolConstructor)
    meta.addConstructor("minecraft:crafting_table", craftToolConstructor)
end
