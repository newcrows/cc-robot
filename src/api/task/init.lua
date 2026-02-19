local tasksDir = "%INSTALL_DIR%/tasks"
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
    fs.delete(configFile)
end

function task.run(name, opts)
    if not opts.resumed then
        writeConfigFile(name, opts)
        print("run: " .. name, table.unpack(opts))
    else
        print("resume: " .. name, table.unpack(opts))
    end

    local ctrl = {
        reportProgress = function(progress)
            local percentage = math.floor(progress * 100)
            print(percentage .. "% complete")
        end
    }

    local _task = require(tasksDir .. "/" .. name)
    _task(opts, ctrl)

    removeConfigFile()
    print("finished: " .. name, table.unpack(opts))
end

function task.resume()
    if fs.exists(configFile) then
        local config = readConfigFile()
        config.opts.resumed = true

        task.run(config.name, config.opts)
    end
end

return task
