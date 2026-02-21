local initConstants = require((...) .. "/init_constants")
local initCore = require((...) .. "/init_core")
local initEquipment = require((...) .. "/init_equipment")
local initInventory = require((...) .. "/init_inventory")
local initMisc = require((...) .. "/init_misc")
local initPeripherals = require((...) .. "/init_peripherals")
local initPositioning = require((...) .. "/init_positioning")
local initTurtle = require((...) .. "/init_turtle")

local robot = {}
local meta = {}
local constants = {}

initTurtle(robot, meta, constants)
initConstants(robot, meta, constants)
initCore(robot, meta, constants)
initInventory(robot, meta, constants)
initEquipment(robot, meta, constants)
initPositioning(robot, meta, constants)
initPeripherals(robot, meta, constants)
initMisc(robot, meta, constants)

robot.meta = meta
robot.constants = constants

--[[
EQUIPMENT_WARNING -> meta.requireEquipment(name) | any <equipment> function called
ITEM_COUNT_WARNING -> meta.requireItemCount(name, count)
ITEM_SPACE_WARNING -> meta.requireItemSpace(name, space) | meta.requireItemSpaceForUnknown(stackSize, space)
PERIPHERAL_WARNING -> <peripheral> in range and any <peripheral> function called
FUEL_LEVEL_WARNING -> meta.requireFuelLevel(requiredLevel) | robot.moveTo(x, y, z)
PATH_WARNING -> robot.moveTo(x, y, z) and path is obstructed
]]--

return robot
