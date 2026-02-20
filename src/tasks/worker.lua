local tasksDir = "%INSTALL_DIR%/tasks"
local configFile = "%STARTUP_DIR%/slave.task.config"
local worker = {}

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

local function runProtected(_task, opts, ctrl)
    local oldPull = os.pullEvent

    os.pullEvent = function(filter)
        local eventData = { os.pullEventRaw(filter) }

        if eventData[1] == "terminate" then
            error("TASK_TERMINATED", 0)
        end

        return unpack(eventData)
    end

    local ok, err = pcall(_task, opts, ctrl)
    os.pullEvent = oldPull

    if not ok then
        if err == "TASK_TERMINATED" then
            return "terminated"
        else
            return "crashed"
        end
    end

    return "finished"
end

function worker.run(name, opts)
    if not opts.resumed then
        writeConfigFile(name, opts)
        -- TODO [JM] notify task run via rednet here
        --print("run: " .. name, table.unpack(opts))
    else
        -- TODO [JM] notify task resume via rednet here
        --print("resume: " .. name, table.unpack(opts))
    end

    local ctrl = {
        reportProgress = function(progress)
            -- TODO [JM] report progress via rednet here
        end
    }

    local _task = require(tasksDir .. "/" .. name)
    local result = runProtected(_task, opts, ctrl)

    removeConfigFile()

    -- TODO [JM] notify task finished|terminated|crashed via rednet here
    print(result .. ": " .. name, table.unpack(opts))
end

function worker.resume()
    if fs.exists(configFile) then
        local config = readConfigFile()
        config.opts.resumed = true

        worker.run(config.name, config.opts)
    end
end

return {
    requirements = {
        equipment = {
            "computercraft:wireless_modem_normal",
            "minecraft:compass"
        }
    },
    run = function(opts, ctrl)
        worker.resume()

        -- _G.robot injected by startup
        local modem = robot.equip("computercraft:wireless_modem_normal")
        local compass = robot.equip("minecraft:compass")

        -- refresh position data
        modem.use()
        robot.x, robot.y, robot.z = gps.locate()
        robot.facing = compass.getFacing()

        -- TODO [JM] wait for new tasks via rednet here
    end
}
