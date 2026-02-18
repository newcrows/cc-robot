local args = { ... }
local flags = args[1]
-- local destination = args[2]
-- local branch = args[2]
local config = args[4]

if flags.t then
    print("include tests..")

    local testFiles = {
        "test/robot/init.lua",
        "test/robot/test_equipment.lua",
        "test/robot/test_events.lua",
        "test/robot/test_inventory.lua",
        "test/robot/test_misc.lua",
        "test/robot/test_peripherals.lua",
        "test/robot/test_positioning.lua"
    }

    for _, testFile in ipairs(testFiles) do
        table.insert(config.files, testFile)
    end
end
