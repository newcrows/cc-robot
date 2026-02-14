local initEvents = require((...) .. "/init_events")
local initPeripherals = require((...) .. "/init_peripherals")
--local initInventory = require((...) .. "/init_inventory")

local robot = {}
local meta = {}
local constants = {
    -- stuff that is needed everywhere, like SIDES or possibly RAW_PROPERTIES
}

initEvents(robot, meta)
initPeripherals(robot, meta, constants)

--initInventory(robot, meta, constants)
--[[
$ = meta
# = custom tool/peripheral
...
all init calls here, logically separated:
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
INVENTORY = {
    select, getSelectedName, getItemDetail, getItemCount, getItemSpace, getItemSpaceForUnknown,
    hasItemCount, hasItemSpace, hasItemSpaceForUnknown, listItems, reserve, free, getReservedItemDetail,
    getReservedItemCount, getReservedItemSpace, hasReservedItemCount, hasReservedItemSpace, listReservedItems,
    $listSlots, $getFirstSlot, $selectFirstSlot, $listEmptySlots, $getFirstEmptySlot, $selectFirstEmptySlot,
    $countItems, $arrangeSlots
}
EQUIPMENT = {
    equip, unequip, getEquipment, hasEquipment, listEquipment,
    #pickaxe, #axe, #shovel, #sword, #craftingTable
}
POSITION = {
    forward, back, up, down, turnLeft, turnRight, getFuelLevel, refuel, getFuelLimit
}
MISC = {
    place, placeUp, placeDown, drop, dropUp, dropDown, detect, detectUp, detectDown,
    compare, compareUp, compareDown, suck, suckUp, suckDown, inspect, inspectUp, inspectDown
}
]]--

return robot
