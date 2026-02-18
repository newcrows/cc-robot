-- this snippet assumes a chest (or items floating in the world) in front of the turtle
local robot = require("%INSTALL_DIR%/api/robot")

-- suck as much as we can from the chest into the turtle
robot.suck()

-- print the turtle inventory
for _, item in ipairs(robot.listItems()) do
    print(item.name .. " = " .. tostring(item.count))
end

-- drop back all dirt (if any), we don't need it
robot.drop("minecraft:dirt")

-- select torches
robot.select("minecraft:torch")

-- keep at most one stack of torches, drop back the rest (if any)
local torchCount = robot.getItemCount()
robot.drop(torchCount - 64)
