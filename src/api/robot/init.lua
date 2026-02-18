local initPositioning = require((...) .. "/init_positioning")
local initEvents = require((...) .. "/init_events")
local initPeripherals = require((...) .. "/init_peripherals")
local initEquipment = require((...) .. "/init_equipment")
local initInventory = require((...) .. "/init_inventory")
local initMisc = require((...) .. "/init_misc")

local robot = {}
local meta = {}
local constants = {
    auto_fuel_low_threshold = turtle.getFuelLimit() / 10 * 2,
    auto_fuel_high_threshold = turtle.getFuelLimit() / 10 * 8,
    deltas = {
        north = { x = 0, y = 0, z = -1 },
        east = { x = 1, y = 0, z = 0 },
        south = { x = 0, y = 0, z = 1 },
        west = { x = -1, y = 0, z = 0 },
        up = { x = 0, y = 1, z = 0 },
        down = { x = 0, y = -1, z = 0 }
    },
    facing_index = {
        [0] = "north",
        [1] = "east",
        [2] = "south",
        [3] = "west",
        [4] = "up",
        [5] = "down",
        ["0|0|-1"] = "north",
        ["1|0|0"] = "east",
        ["0|0|1"] = "south",
        ["-1|0|0"] = "west",
        ["0|1|0"] = "up",
        ["0|-1|0"] = "down",
        north = 0,
        east = 1,
        south = 2,
        west = 3,
        up = 4,
        down = 5
    },
    facings = {
        north = "north",
        east = "east",
        south = "south",
        west = "west",
        up = "up",
        down = "down"
    },
    opposite_facings = {
        north = "south",
        east = "west",
        south = "north",
        west = "east",
        up = "down",
        down = "up"
    },
    side_index = {
        [0] = "front",
        [1] = "right",
        [2] = "back",
        [3] = "left",
        [4] = "up",
        [5] = "down",
        front = 0,
        right = 1,
        back = 2,
        left = 3,
        up = 4,
        down = 5
    },
    sides = {
        front = "front",
        right = "right",
        back = "back",
        left = "left",
        top = "top",
        bottom = "bottom"
    },
    opposite_sides = {
        front = "back",
        right = "left",
        back = "front",
        left = "right",
        top = "bottom",
        bottom = "top"
    },
    default_stack_size = 64
}

robot.meta = meta
robot.constants = constants

initPositioning(robot, meta, constants)
initEvents(robot, meta, constants)
initPeripherals(robot, meta, constants)
initEquipment(robot, meta, constants)
initInventory(robot, meta, constants)
initMisc(robot, meta, constants)

return robot
