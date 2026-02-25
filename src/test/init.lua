local testConstants = require((...) .. "/test_constants")
local testCore = require((...) .. "/test_core")
local testEquipment = require((...) .. "/test_equipment")
local testInventory = require((...) .. "/test_inventory")
local testMisc = require((...) .. "/test_misc")

local robot = require("/api/robot") -- %INSTALL_DIR% !!
local meta = robot.meta
local constants = robot.constants

local EMPTY_EQUIP_SLOTS = "empty_equi_slots"
local EMPTY_INVENTORY = "empty_inventory"
local ITEM_COUNT = "item_count"
local utility = {}

function utility.requireEmptyEquipSlots()
    meta.on(EMPTY_EQUIP_SLOTS, function(e)
        if not e.alreadyWarned then
            print("please empty the equip slots")
        end
    end)

    local function check()
        return not nativeTurtle.getEquippedLeft() and not nativeTurtle.getEquippedRight()
    end

    local function get()
        -- nop
    end

    local function constructor(detail)
        return meta.createEvent(EMPTY_EQUIP_SLOTS, detail)
    end

    meta.require(check, get, constructor)
end

function utility.requireEmptyInventory()
    meta.on(EMPTY_INVENTORY, function(e)
        if not e.alreadyWarned then
            print("please empty the inventory")
        end
    end)

    local function check()
        for i = 1, 16 do
            if nativeTurtle.getItemCount(i) > 0 then
                return false
            end
        end

        return true
    end

    local function get()
        -- nop
    end

    local function constructor(detail)
        return meta.createEvent(EMPTY_INVENTORY, detail)
    end

    meta.require(check, get, constructor)
end

function utility.requireItemCount(name, count)
    meta.on(ITEM_COUNT, function(e)
        if not e.alreadyWarned then
            print("please insert " .. count .. " " .. name)
        end
    end)

    local function check()
        local _count = 0

        for i = 1, 16 do
            local detail = nativeTurtle.getItemDetail(i)

            if detail and detail.name == name then
                _count = _count + detail.count
            end
        end

        return _count >= count
    end

    local function get()
        -- nop
    end

    local function constructor(detail)
        return meta.createEvent(ITEM_COUNT, detail)
    end

    meta.require(check, get, constructor)
end

--testConstants(robot, meta, constants, utility)
--testCore(robot, meta, constants, utility)
--testEquipment(robot, meta, constants, utility)
--testInventory(robot, meta, constants, utility)
testMisc(robot, meta, constants, utility)
