return function(_, _, constants)
    constants.deltas = {
        north = { x = 0, y = 0, z = -1 },
        east = { x = 1, y = 0, z = 0 },
        south = { x = 0, y = 0, z = 1 },
        west = { x = -1, y = 0, z = 0 },
        up = { x = 0, y = 1, z = 0 },
        down = { x = 0, y = -1, z = 0 }
    }
    constants.facing_index = {
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
    }
    constants.facings = {
        north = "north",
        east = "east",
        south = "south",
        west = "west",
        up = "up",
        down = "down"
    }
    constants.opposite_facings = {
        north = "south",
        east = "west",
        south = "north",
        west = "east",
        up = "down",
        down = "up"
    }
    constants.side_index = {
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
    }
    constants.sides = {
        front = "front",
        right = "right",
        back = "back",
        left = "left",
        top = "top",
        bottom = "bottom"
    }
    constants.opposite_sides = {
        front = "back",
        right = "left",
        back = "front",
        left = "right",
        top = "bottom",
        bottom = "top"
    }
    constants.default_stack_size = 64
    constants.dropTable = {
        ["minecraft:stone"] = "minecraft_cobblestone",
        -- TODO [JM] add all block aliases for the vanilla ores, etc. here!
    }
end
