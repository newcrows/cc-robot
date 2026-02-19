-- snippet assumes turtle is not fully fueled
local robot = require("%INSTALL_DIR%/api/robot")

-- tell robot which fuel(s) to use and reserve space for
robot.setFuel("minecraft:coal_block")

-- print missing fuelLevel
robot.onFuelWarning(function(level, requiredLevel)
    print("has " .. level .. " requires " .. requiredLevel)
end)

-- try to move the maximum number of steps a turtle can move with max fuel
-- this triggers the fuel warning if the turtle is not fully fueled
-- put some coal_block into the inventory and see what happens
local steps = robot.getFuelLimit()
robot.forward(steps)
