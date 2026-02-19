-- this snippet assumes you have a pickaxe, an axe, a shovel
-- and a sword somewhere in the turtle's inventory
local robot = require("%INSTALL_DIR%/api/robot")

local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local axe = robot.equip("minecraft:diamond_axe")
local shovel = robot.equip("minecraft:diamond_shovel")
local sword = robot.equip("minecraft:diamond_sword")

-- print what we need to do in case some tool is missing
robot.onEquipmentWarning(function(_, name, waited)
    if not waited then
        print("waiting for " .. name)
        print("please put one into the inventory")
    end
end)

pickaxe.dig()
axe.digUp()
shovel.digDown()
sword.attack()

-- yes, we have four tools equipped at once. so what?
