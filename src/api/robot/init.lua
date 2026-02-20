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

return robot
