local baseUrl = "https://raw.githubusercontent.com/newcrows/cc-robot/refs/heads/main"
local files = {
    "robot/init.lua",
    "robot/init_equipment.lua",
    "robot/init_events.lua",
    "robot/init_inventory.lua",
    "robot/init_misc.lua",
    "robot/init_peripherals.lua",
    "robot/init_positioning.lua",
    "test/init.lua",
    "test/test_equipment.lua",
    "test/test_events.lua",
    "test/test_inventory.lua",
    "test/test_misc.lua",
    "test/test_peripherals.lua",
    "test/test_positioning.lua",
    --"run_test.lua" write manually depending on download dir
}

local args = {...}
local destination = args[1] or "."

local function readableSize(numBytes)
    if numBytes < 1024 then
        return numBytes .. "b"
    end

    if numBytes < 1024 * 1024 then
        return math.floor(numBytes / 1024) .. "kb"
    end

    if numBytes < 1024 * 1024 * 1024 then
        return math.floor(numBytes / 1024 / 1024) .. "mb"
    end

    error("numBytes is too big")
end

local function downloadFile(file)
    write(file)

    local response = http.get(baseUrl .. "/" .. file)
    local content = response.readAll()

    print(" (" .. readableSize(#content) .. ")")

    local localFile = fs.open(destination .. "/" .. file, "w")

    localFile.write(content)
    localFile.close()
end

local function downloadFiles()
    print("downloading files..")
    for _, file in pairs(files) do
        downloadFile(file)
    end
end

local function createRunTestFile()
    print("creating " .. destination .. "/run_test.lua..")

    local rtFile = fs.open(destination .. "/run_test.lua", "w")
    rtFile.write("local test = require(\"" .. destination .. "/test\")\r\ntest()\r\n")
    rtFile.close()
end

local function installRobot()
    print("installing robot..")

    local ok = pcall(downloadFiles)

    if not ok then
        print("..install failed")
        return
    end

    ok = pcall(createRunTestFile)

    if not ok then
        print("..install failed")
        return
    end

    print("..install ok")
end

installRobot()
