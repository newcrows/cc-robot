-- snippet assumes a non-full chest in front of the turtle
local robot = require("%INSTALL_DIR%/api/robot")
local chest = robot.wrap()

robot.setAutoFuel("minecraft:coal_block", 64)

local function restockFuel()
    robot.select("minecraft:coal_block")
    chest.export(64 - robot.getReservedItemCount())
end

restockFuel()
