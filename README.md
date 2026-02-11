# cc-robot

## what is this?

`robot` enhances how `turtles` work.

main features:
- equip any number of tools at once (up to 18)
- manage the inventory by item names instead of slots
- always know the (relative) position and facing of your turtle
- wrap your peripherals however you like
- pure lua, this is not a minecraft mod

see [DOCS.md](./DOCS.md) for documentation.

## usage

requires CC:Tweaked 1.116.0 or higher.

download from [pastebin](https://pastebin.com/T9CrYfSE)

`pastebin get T9CrYfSE robot.lua`

get a `robot` instance using `require()`
```lua
local robot = require("robot")
```

## multiple tools example
```lua
-- this snippet assumes you have a pickaxe, an axe, a shovel
-- and a sword somewhere in the turtle's inventory (and nothing else)
local robot = require("robot")

local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local axe = robot.equip("minecraft:diamond_axe")
local shovel = robot.equip("minecraft:diamond_shovel")
local sword = robot.equip("minecraft:diamond_sword")

pickaxe.dig()
axe.digUp()
shovel.digDown()
sword.attack()

for _, item in ipairs(robot.listItems()) do
    print(item.name .. " = " .. tostring(item.count))
end

-- yes, we have four tools equipped at once. so what?
```

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
