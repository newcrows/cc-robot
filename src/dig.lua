-- use robot api
local robot = require("%INSTALL_DIR%/api/robot");

-- prepare pickaxe and chest
local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local chest = robot.wrap("back", "minecraft:chest")

-- helper to dump items into the chest
local function offloadItems()
    local cx, cy, cz = robot.x, robot.y, robot.z
    local cFacing = robot.facing

    -- move to chest
    robot.moveTo(chest)

    -- dump all non-reserved items into chest
    chest.import("*@items")

    -- move back to last digging position
    robot.moveTo(cx, cy, cz, cFacing)
end

-- helper to clear the path on the way back to the chest
local function clearPath(e)
    local digFuncs = {
        front = pickaxe.native.dig,
        back = function()
            robot.turnRight(2)
            pickaxe.native.dig()
            robot.turnLeft(2)
        end,
        top = pickaxe.native.digUp,
        bottom = pickaxe.native.digDown
    }
    local side = e.detail.side

    -- try to clear the path by digging
    return digFuncs[side]()
end

local function digLine(length)
    for l = 1, length - 1 do
        pickaxe.digUp()
        pickaxe.digDown()
        robot.forward(pickaxe.dig)
    end

    pickaxe.digUp()
    pickaxe.digDown()
end

local function digArea(width, length)
    local turnFuncs = {robot.turnLeft, robot.turnRight}

    for w = 1, width - 1 do
        local turn = turnFuncs[(w % 2) + 1]
        digLine(length)

        turn()
        robot.forward(pickaxe.dig)
        turn()
    end

    digLine(length)
end

local function digCuboid(width, height, length)
    -- TODO [JM] implement
end

-- parse args
local args = {...}
local width = tonumber(args[1])
local height = tonumber(args[2])
local length = tonumber(args[3])

-- reserve a stack of coal as fuel (will auto-fuel on any coal found)
robot.setFuel("minecraft:coal")

-- handle events
robot.onItemSpaceWarning(offloadItems)
robot.onPathWarning(clearPath)

-- empty inventory and dig cuboid
offloadItems()
digCuboid(width, height, length)
