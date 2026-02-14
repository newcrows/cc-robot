local initPositioning = require((...) .. "/init_positioning")
local initEvents = require((...) .. "/init_events")
local initPeripherals = require((...) .. "/init_peripherals")
local initEquipment = require((...) .. "/init_equipment")
local initInventory = require((...) .. "/init_inventory")
local initMisc = require((...) .. "/init_misc")

local robot = {}
local meta = {}
local constants = {
    -- stuff that is needed everywhere, like SIDES or possibly RAW_PROPERTIES
}

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
