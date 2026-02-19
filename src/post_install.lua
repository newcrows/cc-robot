local args = { ... }
-- local flags = args[1]
local destination = args[2]
-- local branch = args[3]
local config = args[4]

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

local function printWhatNext()
    print("---- WHAT NEXT? ----")
    print("check out the examples on github")
    print("or dive right in!")
    print()
    print("happy coding!")
    print("--------------------")
end

replaceInstallDirPlaceholders()
printWhatNext()
