# cc-robot

## what is this?

`robot` enhances how `turtles` work.

main features:
- equip any number of tools at once (up to 18)
- manage the inventory by item names instead of slots
- always know the (relative) position and facing of your turtle
- wrap your peripherals however you like
- pure lua, this is not a minecraft mod

see [DOCS.md](/DOCS.md) for documentation.

## usage

requires CC:Tweaked 1.116.0 or higher.

download from [pastebin](https://pastebin.com/CF0E2jUE)

`pastebin get CF0E2jUE robot.lua`

get a `robot` instance using `require()`
```lua
local robot = require("robot")
```

## example
```lua
-- this snippet assumes you have a pickaxe, an axe, a shovel
-- and a sword somewhere in the turtle's inventory (and nothing else)

-- also assumes in front is a cobblestone block, on top is an oak log block
-- and below is a dirt block

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

see [DOCS.md](/DOCS.md) for documentation.
