# cc-robot

## what is this?

`robot` enhances how `turtles` work.

main features:
- equip any number of tools at once (up to 18)
- auto-fuel your turtles, never need to track `turtle.getFuelLevel()`
- manage the inventory by item names, never need to interact with slots
- always know the (relative) position and facing of your turtle
- wrap your peripherals however you like
- pure lua, this is not a minecraft mod

see [DOCS.md](./DOCS.md) for documentation.

## usage

requires `CC:Tweaked 1.116.0` or higher.

simply run `pastebin run 2tfVSk7r <install-dir>` ([pastebin link](https://pastebin.com/2tfVSk7r))
or checkout this repo.

get a `robot` instance using `require()`
```lua
local robot = require("robot")
```

## multiple tools example
```lua
-- this snippet assumes you have a pickaxe, an axe, a shovel
-- and a sword somewhere in the turtle's inventory
local robot = require("robot")

local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local axe = robot.equip("minecraft:diamond_axe")
local shovel = robot.equip("minecraft:diamond_shovel")
local sword = robot.equip("minecraft:diamond_sword")

pickaxe.dig()
axe.digUp()
shovel.digDown()
sword.attack()

-- yes, we have four tools equipped at once. so what?
```
see [DOCS.md](./DOCS.md) for documentation.

## crafting example
```lua
-- this snippet assumes the inventory only contains items required to craft pistons
local robot = require("robot")
local craftingTable = robot.equip("minecraft:crafting_table")

local pistonRecipe = {
    p = "minecraft:oak_planks",
    c = "minecraft:cobblestone",
    i = "minecraft:iron_ingot",
    r = "minecraft:redstone",
    pattern = [[
        p p p
        c i c
        c r c
    ]]
}

-- craft one piston
craftingTable.craft(pistonRecipe, 1)
```
see [DOCS.md](./DOCS.md) for documentation.

## auto-fuel example

auto-fuel is a feature that automatically consumes fuel when needed, i.E. when moving and low on fuel.

to auto-fuel, you simply need to specify which fuel(s) you want
and how much `robot` should stockpile of that fuel.

stockpiled / reserved items are never dropped or exported by `robot`.

```lua
-- snippet assumes a non-full chest in front of the turtle
local robot = require("robot")
local chest = robot.wrap()

robot.setAutoFuel("minecraft:coal_block", 64)

local function restockFuel()
    robot.select("minecraft:coal_block")
    chest.export(64 - robot.getReservedItemCount())
end

restockFuel()
```
see [DOCS.md](./DOCS.md) for documentation.

## inventory example
```lua
-- this snippet assumes a chest (or items floating in the world) in front of the turtle
local robot = require("robot")

-- suck as much as we can from the chest into the turtle
robot.suck()

-- print the turtle inventory
for _, item in ipairs(robot.listItems()) do 
    print(item.name .. " = " .. tostring(item.count))
end

-- drop back all dirt (if any), we don't need it
robot.drop("minecraft:dirt")

-- select torches
robot.select("minecraft:torch")

-- keep at most one stack of torches, drop back the rest (if any)
local torchCount = robot.getItemCount()
robot.drop(torchCount - 64)
```
see [DOCS.md](./DOCS.md) for documentation.
