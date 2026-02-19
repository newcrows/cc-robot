local args = { ... }
-- local flags = args[1]
local destination = args[2]
-- local branch = args[3]
local config = args[4]

local function replaceInFile(file, map)
    local f = fs.open(file, "r")
    local content = f.readAll()
    f.close()

    local newContent = content

    for placeholder, replacement in pairs(map) do
        newContent = string.gsub(newContent, placeholder, replacement)
    end

    f = fs.open(file, "w")
    f.write(newContent)
    f.close()
end

local function replacePlaceholders()
    local map = {
        ["%%INSTALL_DIR%%"] = destination == "/" and "" or destination,
        ["%%STARTUP_DIR%%"] = "/startup"
    }

    for _, file in ipairs(config.files) do
        local absFile = destination .. "/" .. file
        replaceInFile(absFile, map)
    end
end

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

local function moveSpecialFiles()
    for _, file in ipairs(config.files) do
        if fs.getDir(file) == "" then
            moveWithPrompt(destination .. "/" .. file, "/" .. file)
        end

        if string.match(fs.getDir(file), "^startup") then
            moveWithPrompt(destination .. "/" .. file, "/" .. file)
        end
    end
end

local function printWhatNext()
    print("---- WHAT NEXT? ----")
    print("check out the examples on github")
    print("or dive right in!")
    print()
    print("happy coding!")
    print("--------------------")
end

replacePlaceholders()
moveSpecialFiles()
printWhatNext()
