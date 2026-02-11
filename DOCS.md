# cc-robot docs

## table of contents

- [usage](#usage)
- [important differences to vanilla turtles](#important-differences-to-vanilla-turtles)
- [from relative to absolute position](#from-relative-to-absolute-position)
- [robot api](#robot-api)
    - [insertPeripheralConstructor(name, constructor)](#insertPeripheralConstructorname-constructor)
    - [removePeripheralConstructor(name)](#removePeripheralConstructorname)
    - [listPeripheralConstructors()](#listPeripheralConstructors)
    - [wrap(side) | wrapUp() | wrapDown()](#wrapside--wrapUp--wrapDown)
    - [up() | down() | forward() | back()](#up--down--forward--back)
    - [turnLeft() | turnRight()](#turnLeft--turnRight)
    - [place(name) | placeUp(name) | placeDown(name)](#placename--placeUpname--placeDownname)
    - [drop(name, count) | dropUp(name, count) | dropDown(name, count)](#dropname-count--dropUpname-count--dropDownname-count)
    - [select(name)](#selectname)
    - [getItemCount(name)](#getItemCountname)
    - [getItemSpace(name, stackCount)](#getItemSpacename-stackCount)
    - [getItemSpaceForUnknown()](#getItemSpaceForUnknown)
    - [hasItemCount(name)](#hasItemCountname)
    - [hasItemSpace(name, stackCount)](#hasItemSpacename-stackCount)
    - [hasItemSpaceForUnknown()](#hasItemSpaceForUnknown)
    - [detect() | detectUp() | detectDown()](#detect--detectUp--detectDown)
    - [compare(name) | compareUp(name) | compareDown(name)](#comparename--compareUpname--compareDownname)
    - [suck(count) | suckUp(count) | suckDown(count)](#suckcount--suckUpcount--suckDowncount)
    - [getFuelLevel()](#getFuelLevel)
    - [refuel()](#refuel)
    - [getSelectedName()](#getSelectedName)
    - [getFuelLimit()](#getFuelLimit)
    - [equip(name, pinned)](#equipname-pinned)
    - [unequip(nameOrProxy)](#unequipnameOrProxy)
    - [listEquipment()](#listEquipment)
    - [inspect() | inspectUp() | inspectDown()](#inspect--inspectUp--inspectDown)
    - [getItemDetail(name)](#getItemDetailname)
    - [listItems()](#listItems)

## usage

requires `CC:Tweaked 1.116.0` or higher.

download from [pastebin](https://pastebin.com/aHyLYPrm)

`pastebin get aHyLYPrm robot.lua`

get a `robot` instance using `require()`
```lua
local robot = require("robot")
```

## important differences to vanilla turtles

the `robot api` is very closely aligned to the `turtle api`, but:

there is no `robot.dig()|digUp()|digDown()`, instead you should `equip` a tool.
```lua
local pickaxe = robot.equip("minecraft:diamond_pickaxe")

-- dig in front of the turtle
pickaxe.dig()
```

there is no `robot.attack()|attackUp()|attackDown()`, instead you should `equip` a sword.
```lua
local sword = robot.equip("minecraft:diamond_sword")

-- attack in front of the turtle
sword.attack()
```

there is no `robot.craft()`, instead you should `equip` a crafting table.
```lua
local craftingTable = robot.equip("minecraft:crafting_table")
local coalBlockRecipe = {
  c = "minecraft:coal",
  pattern = [[
    c c c
    c c c
    c c c
  ]]
}

-- craft one block of coal
craftingTable.craft(coalBlockRecipe, 1)
```

NOTE: `turtle.craft()` is bugged in `CC:Tweaked 1.116.0`. you need to equip a crafting table and reboot the `turtle`, which is stupid.
`robot.equip("minecraft:crafting_table")` works without reboot.

## from relative to absolute position

if the turtle has a `modem` and a `compass`, you can trivially set the `robot` position to absolute coordinates (assuming gps is in range).

```lua
local modem = robot.equip("computercraft:wireless_modem_normal")
local compass = robot.equip("minecraft:compass")

modem.use()
robot.x, robot.y, robot.z = gps.locate()
robot.facing = compass.getFacing()
```

## robot api

### insertPeripheralConstructor(name, constructor)

registers a `constructor` for `peripherals` with a given `name`.

if `robot.equip(..)` or `robot.wrap|wrapUp|wrapDown()` is called, the `robot` instance will
look through the registered `constructors` and if one exists for `name`
it will call the registered `constructor` with `opts`.

the `constructor` must return a new instance of the custom `peripheral` when called.

NOTE: custom `peripherals` for `minecraft:diamond_pickaxe`,
`minecraft:diamond_axe`, `minecraft:diamond_shovel`, `minecraft:diamond_sword` and `minecraft:crafting_table`
are bundled with `robot`, you don't need to manually register those.

you DO NOT need to create custom `peripherals`, this is completely optional and regular `peripherals` work as-is.

EXAMPLE:
```lua
-- register peripheral constructor for pickaxe
-- this basically wraps the turtle dig* commands
robot.insertPeripheralConstructor("minecraft:diamond_pickaxe", function(opts) 
    return {
        dig = turtle.dig,
        digUp = turtle.digUp,
        digDown = turtle.digDown,
    }
end)

-- returns an instance of our custom peripheral
local pickaxe = robot.equip("minecraft:diamond_pickaxe")

-- dig the block in front of the turtle
pickaxe.dig()

```

### removePeripheralConstructor(name)

removes the `constructor` registered for `name`, if it exists.

EXAMPLE:
```lua
-- remove the automatically registered pickaxe constructor
robot.removePeripheralConstructor("minecraft:diamond_pickaxe")

local pickaxe = robot.equip("minecraft:diamond_pickaxe")

-- throws "attempt to call nil" because pickaxe does not normally have a peripheral
pickaxe.dig()
```

### listPeripheralConstructors()

returns a list of all registered `constructors`.

EXAMPLE:
```lua
-- returns a list of {name = string, constructor = function} entries
local peripheralConstructors = robot.listPeripheralConstructors()
```

### wrap(side) | wrapUp() | wrapDown()

wraps the `peripheral` on the given `side`.

calls the registered `constructor` for the `peripheral`.
if no `constructor` exists, this returns the result of `peripheral.wrap` directly.

the default `side` is `front`.

valid `sides` are `front, right, left, top, bottom`.

NOTE: `back` IS NOT a valid `side`.

EXAMPLE:
```lua
-- same as robot.wrapUp()
local chest = robot.wrap("top")

-- lists items in the chest above the turtle
chest.listItems()
```

### up() | down() | forward() | back()

these all behave like their `turtle` counterparts.

additionally, they update `robot.x, robot.y, robot.z`.

NOTE: calling `turtle` functions like `turtle.forward` DOES NOT update `robot` position.

EXAMPLE:
```lua
-- fresh robot instances have {x, y, z, facing} set to {0, 0, 0, "north"}
-- this snippet assumes the turtle is fuelled and there are no obstructions
-- preventing movement

robot.forward()

-- robot.z is now -1 (moved "north" by one block)

robot.up()

-- robot.z is still -1
-- robot.y is now 1 (moved "up" by one block)

-- and so on
```

### turnLeft() | turnRight()

these behave like their `turtle` counterparts.

additionally, they update `robot.facing`.

NOTE: calling `turtle` functions like `turtle.turnRight` DOES NOT update `robot.facing`.

EXAMPLE:
```lua
-- fresh robot instances have {x, y, z, facing} set to {0, 0, 0, "north"}

robot.turnRight()

-- robot.facing is "east" now

robot.turnLeft()

-- robot.facing is "north" again now

robot.turnLeft()

-- robot.facing is "west" now

-- and so on
```

### place(name) | placeUp(name) | placeDown(name)

tries to place block with `name` from inventory to the respective direction.

if no `name` is given, uses `robot.getSelectedName()`.

omits `equipment`.

EXAMPLE:
```lua
-- select by name, similar to turtle.select(slot)
robot.select("minecraft:dirt")

-- attempts to place a dirt block above the turtle
robot.placeUp()

-- attempts to place a cobblestone block in front of the turtle
-- without first selecting it by name
robot.place("minecraft:cobblestone")
```

### drop(name, count) | dropUp(name, count) | dropDown(name, count)

tries to drop `count` blocks with `name` from inventory to the respective direction.
returns the `amount` of items dropped.

if no `name` is given, uses `robot.getSelectedName()`.

if no `count` is given, attempts to drop ALL items with `name`.

omits `equipment`.

EXAMPLE:
```lua
robot.select("minecraft:dirt")

-- attempts to drop up to 8 dirt blocks in front of the turtle
robot.drop(8)

-- attempts to drop ALL cobblestone above the turtle
-- without first selecting it by name
robot.dropUp("minecraft:cobblestone")

-- attempts to drop 64 coal below the turtle
-- without first selecting it by name
robot.dropDown("minecraft:coal", 64)
```

### select(name)

selects `name`, similar to `turtle.select(slot)`.

no items with `name` need to exist in the inventory at the time of selection,
this is purely a pointer for when the time comes to do something with the
selected item(s).

most `robot` functions alternatively take a direct parameter `name` so selection is
mostly for convenience, i.E. doing some things in sequence with the same item(s).

NOTE: `robot` abstracts away `slots` completely. everything works via `name`.

EXAMPLE:
```lua
robot.select("minecraft:dirt")

-- dirt is now selected
-- you can now can do something with it, like robot.drop(), etc.
```

### getItemCount(name)

returns the `count` of `name` in inventory.

if no `name` is given, uses `robot.getSelectedName()`.

omits `equipment`.

EXAMPLE:
```lua
-- this snippet assumes you have exactly 16 dirt and 1 pickaxe in the turtle inventory
-- it doesn't matter how the items are distributed across slots
-- i.E.
-- slot_1 = 9 dirt
-- slot_5 = pickaxe
-- slot_16 = 7 dirt

robot.select("minecraft:dirt")

-- prints "16"
print(robot.getItemCount())

-- prints "1"
print(robot.getItemCount("minecraft:diamond_pickaxe"))

-- show that equipment is omitted
robot.equip("minecraft:diamond_pickaxe")

-- now prints "0"
-- robot.equip just declares equipment, it does not actually equip it until needed
-- this means the pickaxe is still in slot_5 but no longer visible to getItemCount(..)
print(robot.getItemCount("minecraft:diamond_pickaxe"))
```

### getItemSpace(name, stackCount)

returns the `space` for `name` in inventory.

if no `name` is given, uses `robot.getSelectedName()`.

if no items with `name` exist in inventory, assumes a `stackSize` of `64`.

if `stackCount` is passed, returns `stackCount * stackSize - count`.
this number can be negative.

`stackCount` is mainly used to clip stacks,
i.E. "how many more items for one whole stack".

DOES NOT omit `equipment`.

NOTE: if there are currently no empty slots, this will try to compact inventory and count space again.

EXAMPLE:
```lua
-- this snippet assumes you have exactly 16 dirt and one pickaxe in the turtle inventory
-- it doesn't matter how the items are distributed across slots
-- i.E.
-- slot_1 = 9 dirt
-- slot_5 = pickaxe
-- slot_16 = 7 dirt

robot.select("minecraft:dirt")

-- prints "944"
-- slot_1 can hold 55 more dirt
-- slot_5 can hold no dirt, it already holds a pickaxe
-- slot_16 can hold 57 more dirt
-- there are 13 empty slots that can hold 64 dirt each
-- add them together to get 944 -> 55 + 0 + 57 + 13 * 64 = 944
print(robot.getItemSpace())

-- prints "13"
-- slot_1 holds dirt, can't hold a pickaxe
-- slot_5 holds a pickaxe and can hold no more, pickaxes don't stack
-- slot_16 holds dirt, can't hold a pickaxe
-- there are now 13 empty slots and each can hold one pickaxe
print(robot.getItemSpace("minecraft:diamond_pickaxe"))

-- show that equipment IS NOT omitted
robot.equip("minecraft:diamond_pickaxe")

-- still prints "13"
-- robot.equip just declares equipment, it does not actually equip it until needed
-- this means three slots are still occupied by 9 dirt, a pickaxe and 7 dirt respectively
-- hence there are still 13 empty slots to hold one more pickaxe each
print(robot.getItemSpace("minecraft:diamond_pickaxe"))
```

### getItemSpaceForUnknown()

returns the minimum number of empty slots.

DOES NOT omit `equipment`.

NOTE: if there are currently no empty slots, this will try to compact inventory and count empty space again.

### hasItemCount(name)

returns `robot.getItemCount(name) > 0`.

omits `equipment`.

### hasItemSpace(name, stackCount)

returns `robot.getItemSpace(name, stackCount) > 0`.

DOES NOT omit `equipment`.

### hasItemSpaceForUnknown()

returns `true` if there is at least one empty slots and `false` otherwise.

DOES NOT omit `equipment`.

### detect() | detectUp() | detectDown()

equivalent to their respective `turtle` functions.

### compare(name) | compareUp(name) | compareDown(name)

equivalent to their respective `turtle` functions but operates on `name` instead of `slot`.

NOTE: to check for empty blocks, pass `"air"` as `name`.

EXAMPLE:
```lua
-- this snipped assumes in front of the turtle is a dirt block
-- and above the turtle is no block

-- returns true
robot.compare("minecraft:dirt")

-- returns false
robot.compare("minecraft:cobblestone")

-- returns true
robot.compareUp("air")
```

### suck(count) | suckUp(count) | suckDown(count)

tries to suck `count` blocks from the respective direction.
returns the `amount` of items sucked.

if no `count` is passed, `count` is set to `9999`.

NOTE: in `CC:Tweaked 1.116.0`, the functions `turtle.suck()|suckUp()|suckDown()` are bugged. the functions `robot.suck()|suckUp()|suckDown()` inherit the bugged behavior.

EXAMPLE:
```lua
-- sucks until inventory is full or no more items to suck
local amount = robot.suck()

-- prints the amount of items sucked
print(amount)
```

### getFuelLevel()

equivalent to `turtle.getFuelLevel()`.

### refuel()

attempts to refuel the turtle with `count` items of `name`.
returns the `amount` consumed.

if no `count` is passed, tries to consume all available items with `name`.

omits `equipment`.

EXAMPLE:
```lua
local amount = turtle.refuel("minecraft:coal")

--prints the amount of fuel consumed
print(amount)
```

### getSelectedName()

returns the `name` selected by `robot.select(..)`

### getFuelLimit()

equivalent to `turtle.getFuelLimit()`.

### equip(name, pinned)

declares `name` as equipment and returns a `handle` for the equipment.

you can declare an arbitrary amount of equipment. it "just works".

if no `name` is present, `robot.getSelectedName()` is used.

if `pinned` is `true`, the equipment will actually be equipped
and STAY equipped until `handle.unpin()` is called.

pinning is useful if you need to call something that uses equipment but does
not do so via the `handle`, i.E. the `gps` and `rednet` apis.
they don't call our `modem_handle` directly.

also, a `chunky_turtle` may not unequip the `chunk_controller` under any circumstance,
or we stop chunk loading and the turtle dies. so we `pin` the `chunk_controller`.

a soft version of pinning is `handle.use()` which will actually equip the equipment,
but not prevent it from being unequipped later, either via `handle.unuse()` or
by the automatic rotation of equipment.

any `handle.*` functions that require the tool to be equipped will automatically
equip it via automatic rotation.

EXAMPLE 1: with `use`
```lua
-- this snippet assumes you have a pickaxe, a sword
-- and a normal wireless modem (not ender modem!) somewhere in the turtle inventory
-- and gps set up and in range

local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local sword = robot.equip("minecraft:diamond_sword")
local modem = robot.equip("computercraft:wireless_modem_normal")

-- "just works" and attempts to dig in front of the turtle
pickaxe.dig()

-- "just works" and attacks in front of the turtle
sword.attack()

-- need to tell robot to actually equip the modem before calling gps
-- because gps is an external api and does not use the modem handle
modem.use()
local x, y, z = gps.locate()

-- prints the turtle's coordinates, assuming gps is set up and in range
print(tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z))

-- still "just works" and attempts to dig/attack in front of the turtle
pickaxe.dig()
sword.attack()

-- yes, you have THREE items equipped and yes, it "just works".
```

EXAMPLE 2: with `pin`
```lua
-- this snippet assumes you have a pickaxe, a sword
-- and a normal wireless modem (not ender modem!) somewhere in the turtle inventory
-- and gps set up and in range

local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local sword = robot.equip("minecraft:diamond_sword")
local modem = robot.equip("computercraft:wireless_modem_normal", true)

-- "just works" and attempts to dig in front of the turtle
pickaxe.dig()

-- "just works" and attacks in front of the turtle
sword.attack()

-- modem is pinned, so we don't need to explicitly call modem.use()
local x, y, z = gps.locate()

-- prints the turtle's coordinates, assuming gps is set up and in range
print(tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z))

-- still "just works" and attempts to dig/attack in front of the turtle
pickaxe.dig()
sword.attack()

-- you still have THREE items equipped and it "just works" till here.

-- what happens if we pin a second item?
pickaxe.pin()

-- that still works, ok
pickaxe.dig()

-- but this throws "both sides are pinned"
-- because one side has modem pinned, the other side has pickaxe pinned
-- and pinned items can not be removed unless handle.unpin() is called
-- and the turtle only has two equip slots (left and right)
sword.attack()

-- the gist of it is: only pin one item
```

### unequip(nameOrProxy)

unequips item with `name` or `proxy.name` depending on the arg.

if item is `pinned`, calls `handle.unpin()` first.

will always call `handle.unuse()` to move the item back into inventory.

the item is now visible again to all inventory functions, i.E. `getItemCount(..)`.

### listEquipment()

returns a list of all equipment, entries have the shape `proxy`.

`proxy` is just a fancy term for `handle`. it contains at least the following fields:
- `name` is the name of the item
- `side` is the side the item is equipped on, if it is currently equipped
- `target` is the wrapped `peripheral` or `customPeripheral` for the item, if it is currently equipped
- `pinned` whether the item is currently `pinned`
- `pin(), unpin(), use(), unuse()` are the default `handle` functions

NOTE: you never need to manually call `handle.unuse()`, this function
just exists for the automatic rotation to work correctly.

### inspect() | inspectUp() | inspectDown()

equivalent to their respective `turtle` functions.

### getItemDetail(name)

works similar to `turtle.getItemDetail` but returns the total `count` of the item

omits `equipment`.

EXAMPLE:
```lua
-- this snippet assumes you have four stacks dirt in the turtle inventory
local detail = robot.getItemDetail("minecraft:dirt")

-- prints "minecraft:dirt"
print(detail.name)

-- prints "256"
-- because four stacks dirt with 64 dirt each is 4 * 64 = 256
print(detail.count)
```

### listItems()

returns a list of all items in the inventory.

each `entry` has the following fields:
- `name` is the item name
- `count` is the count of items in inventory

omits `equipment`.
