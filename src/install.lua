local baseUrl = "https://raw.githubusercontent.com/newcrows/cc-robot/refs/heads"
local args = { ... }
local destination = args[1] or ""
local branch = args[2] or "main"

if string.sub(destination, 1, 1) ~= "/" then
    destination = "/" .. fs.combine(shell.dir(), destination)
end

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

local function download(relPath)
    local response = http.get(baseUrl .. "/" .. branch .. "/" .. relPath)
    local content = response.readAll()

    return content
end

local function downloadConfig()
    local content = download("install.config.json")
    local config = textutils.unserializeJSON(content)

    if config.pre_install and #config.pre_install > 0 then
        local preInstallContent = download(config.pre_install)
        local preInstallFunc = load(preInstallContent)

        if not preInstallFunc then
            preInstallFunc = function()
                error("load pre_install script failed")
            end
        end

        config.pre_install = preInstallFunc
    else
        config.pre_install = function()
        end
    end

    if config.post_install and #config.post_install > 0 then
        local postInstallContent = download(config.post_install)
        local postInstallFunc = load(postInstallContent)

        if not postInstallFunc then
            postInstallFunc = function()
                error("load post_install script failed")
            end
        end

        config.post_install = postInstallFunc
    else
        config.post_install = function()
        end
    end

    return config
end

local function downloadFile(file)
    write(file)

    local content = download(file)
    print(" (" .. readableSize(#content) .. ")")

    local localFile = fs.open(destination .. "/" .. file, "w")
    localFile.write(content)
    localFile.close()
end

local function downloadFiles(config)
    for _, file in pairs(config.files) do
        downloadFile(file)
    end
end

local function install()
    print("install robot..")

    print("download config..")
    local ok, config = pcall(downloadConfig)

    if not ok then
        print("..download config failed")
        return
    end

    print("run pre install script..")
    ok = pcall(config.pre_install, destination, branch, config)

    if not ok then
        print("..run pre install script failed")
        return
    end

    print("download files..")
    ok = pcall(downloadFiles, config)

    if not ok then
        print("..download files failed")
        return
    end

    print("run post install script..")
    ok = pcall(config.post_install, destination, branch, config)

    if not ok then
        print("..run post install script failed")
        return
    end

    print("..install ok")
end

install()
