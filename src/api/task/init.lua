local configFile = "%INSTALL_DIR%/startup/task.config"
local task = {}

local function writeConfigFile(name, opts)
    local file = fs.open(configFile, "w")

    file.write(textutils.serialize({
        name = name,
        opts = opts
    }))
    file.close()
end

local function readConfigFile()
    local file = fs.open(configFile, "r")
    local content = file.readAll()
    file.close()

    return textutils.unserialize(content)
end

local function removeConfigFile()
    fs.remove(configFile)
end

function task.run(name, opts)
    if not resumed then
        writeConfigFile(name, opts)
    end

    local ctrl = {
        reportProgress = function(progress)
            local percentage = math.round(progress * 100)
            print("task " .. name .. " " .. percentage .. "% complete")
        end
    }

    local _task = require(name)
    _task(opts, ctrl)

    removeConfigFile()
end

function task.resume()
    if fs.exists(configFile) then
        local config = readConfigFile()
        config.opts.resumed = true

        task.run(config.name, config.opts)
    end
end

return task
