local initPositioning = require((...) .. "/init_positioning")
local initEvents = require((...) .. "/init_events")
local initPeripherals = require((...) .. "/init_peripherals")
local initEquipment = require((...) .. "/init_equipment")
local initInventory = require((...) .. "/init_inventory")
local initMisc = require((...) .. "/init_misc")

local robot = {}
local meta = {}
local constants = {
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
    raw_properties = {
        name = true,
        side = true,
        target = true,
        pinned = true,
        use = true,
        unuse = true,
        pin = true,
        unpin = true
    }
}

robot.meta = meta
robot.constants = constants

initPositioning(robot, meta, constants)
initEvents(robot, meta, constants)
initPeripherals(robot, meta, constants)
initEquipment(robot, meta, constants)
initInventory(robot, meta, constants)
initMisc(robot, meta, constants)

--[[
$ = meta
# = custom tool/peripheral
...
all init calls here, logically separated:
POSITIONING = {
    robot_properties = {x, y, z, facing}
    forward, back, up, down, turnRight, turnLeft, getFuelLevel, refuel, getFuelLimit
}
EVENTS = {
    addEventListener, removeEventListener, getEventListener, listEventListeners,
    $dispatchEvent
}
PERIPHERALS = {
    wrap, wrapUp, wrapDown,
    $setConstructor, $removeConstructor, $getConstructor, $listConstructors
    $softWrap, $softUnwrap
    #chest, #me_bridge
}
EQUIPMENT = {
    equip, unequip, getEquipment, hasEquipment, listEquipment,
    #pickaxe, #axe, #shovel, #sword, #craftingTable
}
INVENTORY = {
    select, getSelectedName, getItemDetail, getItemCount, getItemSpace, getItemSpaceForUnknown,
    hasItemCount, hasItemSpace, hasItemSpaceForUnknown, listItems, reserve, free, getReservedItemDetail,
    getReservedItemCount, getReservedItemSpace, hasReservedItemCount, hasReservedItemSpace, listReservedItems,
    $listSlots, $getFirstSlot, $selectFirstSlot, $listEmptySlots, $getFirstEmptySlot, $selectFirstEmptySlot,
    $countItems, $arrangeSlots
}
MISC = {
    place, placeUp, placeDown, drop, dropUp, dropDown, detect, detectUp, detectDown,
    compare, compareUp, compareDown, suck, suckUp, suckDown, inspect, inspectUp, inspectDown
}
]]--

return robot
