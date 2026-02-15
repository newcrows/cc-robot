-- snippet assumes a chest in front of the turtle and no block above the turtle
local robot = require("robot")

-- because of CC:Tweaked limitations,
-- you need a pickaxe and an additional chest to use chest.export if the chest is full
robot.equip("minecraft:diamond_pickaxe")
robot.reserve("minecraft:chest", 1)

-- declare what we want to keep in the turtle as auto-fuel
robot.addAutoFuel("minecraft:coal_block", 64)

local function restockFuel()
    local chest = robot.wrap()

    robot.select("minecraft:coal_block")
    chest.export(64 - robot.getReservedItemCount())
end

restockFuel()

-- any robot action that changes its own position/facing or the environment (digging),
-- will unwrap the helper chest placed by chest peripheral
robot.turnRight()
robot.turnRight()
