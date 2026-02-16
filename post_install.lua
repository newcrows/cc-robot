local args = { ... }
local destination = args[1]
local config = args[3]

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
    local exampleDir = (destination == "/" and "" or destination) .. "/example"

    print("check out the examples in:")
    print(exampleDir)

    print("happy coding!")
end

replaceInstallDirPlaceholders()
printWhatNext()
