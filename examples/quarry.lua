local robot = require("%INSTALL_DIR%/api/robot")

local FACINGS = robot.constants.facings
local OPPOSITE_FACINGS = robot.constants.opposite_facings
local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local lastX, lastY, lastZ
local lastFacing
local trash

local function moveToStartPosition()
    lastX, lastY, lastZ = robot.x, robot.y, robot.z
    lastFacing = robot.facing

    robot.face(FACINGS.west)
    robot.move(robot.x, -robot.y, robot.z, function(_, dy, _)
        if dy > 0 then
            pickaxe.digUp()
        elseif dy < 0 then
            pickaxe.digDown()
        else
            pickaxe.dig()
        end
    end)
end

local function handleFuelWarning(level, requiredLevel, autoFuels, recurrent)
    if not recurrent then
        moveToStartPosition()
    end

    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] fuel warning!")
    print("level = " .. level .. ", requiredLevel = " .. requiredLevel)
end

local function handleFuelWarningCleared()
    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] fuel warning cleared!")

    robot.face(FACINGS.east)
    robot.move(lastX, lastY, -robot.z, function(delta)
        if delta.y > 0 then
            pickaxe.digUp()
        elseif delta.y < 0 then
            pickaxe.digDown()
        else
            pickaxe.dig()
        end
    end)

    robot.face(lastFacing)
end

local function digLine(length)
    while length > 1 do
        pickaxe.digUp(trash)
        pickaxe.digDown(trash)

        robot.forward(pickaxe.dig)
        length = length - 1
    end

    pickaxe.digUp(trash)
    pickaxe.digDown(trash)
end

local function digRectangle(length, width, nsFacing, ewFacing)
    while width > 1 do
        robot.face(nsFacing)
        digLine(length)

        robot.face(ewFacing)
        robot.forward(pickaxe.dig)

        nsFacing = OPPOSITE_FACINGS[nsFacing]
        width = width - 1
    end

    robot.face(nsFacing)
    digLine(length)
end

local function digCuboid(length, height, width)
    local nsFacing = FACINGS.north
    local ewFacing = FACINGS.east

    while height > 1 do
        digRectangle(length, width, nsFacing, ewFacing)

        nsFacing = width % 2 == 0 and nsFacing or OPPOSITE_FACINGS[nsFacing]
        ewFacing = OPPOSITE_FACINGS[ewFacing]

        robot.down(3, pickaxe.digDown)
        height = height - 1
    end

    digRectangle(length, width, nsFacing, ewFacing)
    moveToStartPosition()

    robot.face(FACINGS.north)
end

local args = { ... }
local length = tonumber(args[1]) or 0
local height = tonumber(args[2]) or 0
local width = tonumber(args[3]) or 0
local trashFile = args[4]

trash = trashFile and require(trashFile) or {}
robot.setAutoFuel("minecraft:coal", 64)

robot.onFuelWarning(handleFuelWarning)
robot.onFuelWarningCleared(handleFuelWarningCleared)

digCuboid(length, height, width)
