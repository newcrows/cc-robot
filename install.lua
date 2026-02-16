local baseUrl = "https://raw.githubusercontent.com/newcrows/cc-robot/refs/heads/main"
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

local function downloadConfig()
    print("download config..")

    local response = http.get(baseUrl .. "/install.config.json")
    local content = response.readAll()

    return textutils.deserializeJSON(content)
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

local function downloadFiles(files)
    print("download files..")

    for _, file in pairs(files) do
        downloadFile(file)
    end
end

local function install()
    print("install robot..")

    local ok, config = pcall(downloadConfig)

    if not ok then
        print("..download config failed")
        return
    end

    ok = pcall(downloadFiles, config.files)

    if not ok then
        print("..download files failed")
        return
    end

    print("..install ok")
end

install()
