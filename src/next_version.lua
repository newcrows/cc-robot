local robot = require("nc/api/robot")
local pickaxe = robot.equip("minecraft:diamond_pickaxe")
local chest = robot.wrap("minecraft:chest")

robot.setFuel("minecraft:coal_block")

robot.moveTo(chest)
chest.import("minecraft:dirt", 32, true)

robot.moveTo(0, 0, 0)
robot.face("north")

robot.suck()

robot.select("minecraft:cobblestone")

robot.drop() -- drop ALL cobblestones, reserved or not
-- maybe: r.dropUnreserved() ?
-- or we just define r.drop() as dropping ONLY non-reserved items
-- and r.dropReserved() as dropping ONLY reserved items (or we simply NEVER allow dropping reserved items)
-- NOTE: drop() functions index the inventory AT LEAST TWICE
-- NOTE: it is not possible to "dropEverything" right now because name == nil will use selectedName
--  and selectedName == nil throws an error (as it should)
--  -> we need r.dropAll() for that OR allow the special name "*" i.E. drop("*")
--      IFF we allow the special name "*", ALL robot functions MUST support "*" as well
--      that would be a very clean and cool api, in fact
--      (only accept "*" where applicable, of course)
-- NOTE: to stay consistent with suck(), must return
-- i.E. {count = 4, items = ["minecraft:cobblestone"] = 4}, {count = 16, items = ["minecraft:cobblestone"] = 16}
-- -> same shape as the result of suck()
-- -> this assumes we specify "*", $name, "items", "$name@items", "reserved" or "$name@reserved"
-- -> this would mean robot.select() supports this syntax as well, to precisely select what we expect
--      which in turn would mean that the robot.getReservedItem*() functions are obsolete
--      ONLY the regular robot.getItem*() functions do anything (cause we can select precisely what we want)
--  i.E. robot.getItemCount("minecraft:dirt@reserved") -> get count of reserved dirt
--  the cool thing about this is that we can just add an NBT query or something:
--  i.E. robot.hasItemCount("minecraft:book@nbt:4f86646cf67f8149d5334208d3e9c60e4a778e388d7522501062923984d0fa6a")
--  -> return whether any book (reserved or not) with nbt == <nbt> exists in inventory

-- select non-reserved cobblestone
robot.select("minecraft:cobblestone@items")
robot.drop() -- drop ALL non-reserved cobblestone

-- place a reserved cobblestone
robot.place("minecraft:cobblestone@reserved")

-- drop ALL cobblestone left in inventory
robot.drop("minecraft:cobblestone")

-- for consistency, we allow the "*" filter for normal names as well
-- this has no effect
robot.drop("minecraft:cobblestone*")

robot.drop("@reserved") -- drop ALL reserved items
robot.drop("@items") -- drop ALL non-reserved items
robot.drop("*") -- drop ALL items

-- suck until reserved space is full (best effort, because it is impossible items sucked BEFORE sucking them)
robot.suck("@reserved")

-- suck until non-reserved space is full (best effort, see above)
robot.suck("@items")

-- suck until the inventory is completely full (or no blocks)
robot.suck("*")

-- throw if name is not in {"@reserved", "@items", "*"}
-- NOTE: maybe we can use the fact that we can bind $inventory peripherals to
--  actually allow names like "minecraft:compass@reserved" to pull until compass reserve reached
--  the count argument must be handled then, however
--  -> either we actually set reservedCount to at least $count
--  -> or we use math.min(reservedCount, count) to determine $actualCountToSuck (this variant is BETTER!!)
--      probably should use the math.min approach so that reserved space does not unpredictably change
robot.suck("minecraft:cobblestone")

robot.suck() -- suck from the front of the turtle -> may pick up reserved items, I can't stop that
-- maybe it helps here to return two counts -> $itemCount, $reservedItemCount ?
-- or if detailed == true (however that looks) two actual lists?
-- i.E. {count = 4, items = ["minecraft:cobblestone"] = 4}, {count = 16, items = ["minecraft:cobblestone"] = 16}
--  -> this would mean we picked up 4 non-reserved cobblestones and 16 reserved cobblestones?
-- NOTE: suck() functions index the inventory AT LEAST TWICE
-- NOTE: IFF we implement "*", r.suck() MUST throw if ANY other name is passed (for consistency)

pickaxe.place() -- attempt to place a cobblestone, reserved or not
-- maybe: r.placeUnreserved() ?
-- or we just define r.place() as placing ONLY non-reserved items
-- and r.placeReserved() as placing ONLY reserved items (or we simply NEVER allow placing reserved items)
-- NOTE: IFF we support "*" in drop() we must support it everywhere,
--  so place("*") would place SOME block from the inventory

pickaxe.dig() -- dig the block in front of the turtle -> may pick up reserved items, I can't stop that
-- maybe it helps here to return two counts -> $itemCount, $reservedItemCount ?
-- or if detailed == true (however that looks) two actual lists?
-- i.E. {["minecraft:cobblestone"] = 4}, {["minecraft:cobblestone"] = 16}
--  -> this would mean we picked up 4 non-reserved cobblestones and 16 reserved cobblestones?
-- NOTE: this would require EVERY successful dig() operation to index the WHOLE inventory TWICE
--  -> I don't know how good that is for performance, must test
-- ACTUALLY: i can make this efficient by calling peripheral.hasType(side, "inventory")
--  -> and only index the turtle inventory if the dug block was an inventory itself
--  -> otherwise, just use the turtle.inspect() immediately before dig() to know which block
--      will enter the inventory because of the dig operation
-- NOTE: IFF we implement "*", r.dig("*") MUST throw if ANY other name is passed AND the block to dig is NOT $name
--      (for consistency)
-- NOTE: for ULTIMATE CONSISTENCY
--  we need to support filters like "@reserved" so it ONLY digs if there is reserved space for ANY item
--  -> why ANY? because that is how the generic filter "@reserved" is defined everywhere
--  for specific stuff, do something like "minecraft:cobblestone@reserved"
--  -> this uses THE BLOCK_MAPPING NAME, NOT THE BLOCK NAME !! otherwise the logic fails
-- -> it is NOT possible to use filters like "@nbt:<nbt>", etc., because turtle.inspect() does not support
--      additional detailed information of blocks

-- essentially, robot behaves (almost) like turtle if no special filters are set
robot.select("minecraft:cobblestone")
robot.drop() -- drop all cobblestone (because default $name is "*" for drop(name) call)
robot.place() -- place any cobblestone found in inventory
robot.suck() -- suck all cobblestones found in $inventory on front
pickaxe.dig() -- dig the block in front if it is cobblestone

-- only special operators change how things work
robot.select("@reserved")
robot.drop() -- drop all reserved items
robot.place() -- place any (pseudo random, dependent on implicit slot order) block from reserved items
robot.suck() -- suck all items that have reserved space left from $inventory on front
pickaxe.dig() -- dig the block in front if there is reserved space left for that block

-- to make life easier, maybe we should consider:
robot.select() -- defaults to "*"

-- to make it even easier, MAYBE, just MAYBE we should:
robot.select("@reserved")
robot.drop("minecraft:cobblestone")
-- -> equivalent to r.drop("minecraft:cobblestone@reserved")

-- not sure about the inverse, but should probably work as well
robot.select("minecraft:cobblestone")
robot.drop("@reserved")

-- how to handle overrides?
robot.select("@reserved")
robot.drop("minecraft:cobblestone@items")
-- drop $name should take precedence?
-- or do we error out because drop "minecraft:cobblestone@items@reserved" is not possible?
-- -> i think the error is more consistent with the example below

-- but this must fail with error?
robot.select("minecraft:cobblestone@reserved")
robot.drop("@items")
-- -> we can't drop "minecraft:cobblestone@reserved@items" after all

-- this works, because * has less precedence than @reserved / @items?
robot.select("*")
robot.drop("minecraft:cobblestone@reserved")
-- -> effectively is "minecraft:cobblestone@reserved*" which is a valid $name

-- same for this:
robot.select("minecraft:cobblestone@reserved")
robot.drop("*")
-- -> "minecraft:cobblestone*@reserved" is a valid $name

-- additional filters must still be possible though, ONLY @reserved and @items are mutually exclusive
robot.select("@reserved")
robot.drop("@nbt:<nbt>") -- drop any reserved item with nbt == <nbt>

-- selection ambiguity (is this a thing)?
robot.select("*") -- this is the default when starting program
robot.select("minecraft:book@nbt:<nbt>") -- r.getSelectedName() now returns "minecraft:book@nbt=<nbt>"
robot.drop("@reserved") -- drop reserved book with nbt == <nbt>
robot.drop() -- drop any book with nbt == <nbt>
-- -> I see no problem with the selection, no ambiguity possible

-- dig() performance and behavior
-- if block is in BLOCK_DROP_NAMES as $key, very fast, just dig the block
-- else if block is an $inventory -> diff turtle.inventory with block $inventory
-- else -> take before / after snapshots to diff (best effort)

-- how do we address possible sub-data in a selector?
robot.select("minecraft:cobblestone@items@prop_a:prop_b:my-value")
local detail = {
    prop_a = {
        prop_b = "my-value"
    }
}
-- -> no problem, works
-- but we must escape "@", ":", "*" and "/"
robot.select("minecraft:cobblestone@items@prop_a:prop_b:my/:value")
local detail = {
    prop_a = {
        prop_b = "my:value"
    }
}
-- -> should work like this
robot.select("minecraft:cobblestone@items@prop_a:prop_b:my//value")
local detail = {
    prop_a = {
        prop_b = "my/value"
    }
}
-- -> should work like this
