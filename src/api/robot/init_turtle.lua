return function(robot, meta, constants)
    local PROP_MAPPING = {
        attack = "sword.attack",
        attackUp = "sword.attackUp",
        attackDown = "sword.attackDown",
        dig = "pickaxe.dig",
        digUp = "pickaxe.digUp",
        digDown = "pickaxe.digDown",
        equipRight = "robot.equip",
        equipLeft = "robot.equip",
        getEquippedRight = "robot.listEquipment",
        getEquippedLeft = "robot.listEquipment",
        getSelectedSlot = "robot.getSelectedName",
        refuel = "robot.setFuel",
    }

    local proxy = {}

    local metatable = {
        __index = function(_, prop)
            local mappedProp = PROP_MAPPING[prop]

            if not mappedProp then
                if robot[prop] then
                    mappedProp = "robot." .. prop
                end
            end

            if mappedProp then
                print("turtle." .. prop .. "() disabled")
                print("use " .. mappedProp .. "() instead")
                error("", 0)
            else
                print("turtle." .. prop .. "() disabled.")
                error("", 0)
            end
        end
    }

    setmetatable(proxy, metatable)
    _G.turtle = proxy
end
