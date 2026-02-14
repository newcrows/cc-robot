return function(robot, meta, constants)
    function robot.equip(name, pinned)

    end

    function robot.unequip(name)

    end

    function robot.getEquipment(name)

    end

    function robot.hasEquipment(name)

    end

    function robot.listEquipment()

    end

    local digToolConstructor = function(opts)
        -- implement dig tool constructor here
    end

    local attackToolConstructor = function(opts)
        -- implement attack tool constructor here
    end

    local craftToolConstructor = function(opts)
        -- implement craft tool constructor here
    end

    meta.addConstructor("minecraft:diamond_pickaxe", digToolConstructor)
    meta.addConstructor("minecraft:diamond_axe", digToolConstructor)
    meta.addConstructor("minecraft:diamond_shovel", digToolConstructor)
    meta.addConstructor("minecraft:diamond_sword", attackToolConstructor)
    meta.addConstructor("minecraft:crafting_table", craftToolConstructor)
end
