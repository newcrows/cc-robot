local args = { ... }
-- local flags = args[1]
local destination = args[2]
-- local branch = args[3]
local config = args[4]

local function moveWithPrompt(src, dest)
    if fs.exists(dest) then
        write("'" .. dest .. "' already exists. Overwrite? (y/n): ")
        local response = read():lower()

        if response == "y" or response == "yes" or response == "" then
            fs.delete(dest)
        else
            return
        end
    end

    fs.move(src, dest)
end

-- TODO [JM] handle multiple placeholders at once, no need to iterate files more than once
local function replaceInFile(file, placeholder, replacement)
    local f = fs.open(file, "r")
    local content = f.readAll()
    f.close()

    local newContent = string.gsub(content, placeholder, replacement)

    f = fs.open(file, "w")
    f.write(newContent)
    f.close()
end

local function replaceInstallDirPlaceholders()
    for _, file in ipairs(config.files) do
        local absFile = destination .. "/" .. file
        replaceInFile(absFile, "%%INSTALL_DIR%%", destination == "/" and "" or destination)
    end
end

local function replaceStartupDirPlaceholders()
    for _, file in ipairs(config.files) do
        local absFile = destination .. "/" .. file
        replaceInFile(absFile, "%%STARTUP_DIR%%", "/startup")
    end
end

-- TODO [JM] move all files in src/startup to /startup after download
-- TODO [JM] move all files directly in src  to / after download
-- these files are startup logic and programs shipped with robot
-- TODO [JM] if files exist, prompt for override (default yes)
local function moveExecutablesToRoot()
    moveWithPrompt(destination .. "/startup/init.lua", "/startup/init.lua")
    moveWithPrompt(destination .. "/task.lua", "/task.lua")
end

local function printWhatNext()
    print("---- WHAT NEXT? ----")
    print("check out the examples on github")
    print("or dive right in!")
    print()
    print("happy coding!")
    print("--------------------")
end

replaceInstallDirPlaceholders()
replaceStartupDirPlaceholders()
moveExecutablesToRoot()
printWhatNext()
