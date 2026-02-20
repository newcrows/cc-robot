local tasksDir = "%INSTALL_DIR%/tasks"
local configFile = "%STARTUP_DIR%/task.config"
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

local function processRequirements(req)
    if not req then
        return
    end

    -- NOTE [JM] default fuel is coal_block because it has high fuel value per stack
    if req.acceptedFuels then
        robot.setFuel(req.acceptedFuels)
    else
        robot.setFuel("minecraft:coal_block", 64)
    end

    if req.fuelLevel then
        robot.meta.requireFuelLevel(req.fuelLevel)
    end

    if req.equipment then
        for _, name in ipairs(req.equipment) do
            robot.meta.requireEquipment(name)
            robot.reserve(name, 1) -- mock reserve equipment
        end
    end

    if req.itemCount then
        for name, count in pairs(req.itemCount) do
            robot.meta.requireItemCount(name, count)
        end
    end

    if req.itemSpace then
        for name, space in pairs(req.itemSpace) do
            robot.meta.requireItemSpace(name, space)
            robot.reserve(name, space) -- mock reserve to see whether all needed items fit together
        end
    end

    if req.equipment then
        for _, name in ipairs(req.equipment) do
            robot.free(name, 1) -- free mock reserved equipment
        end
    end

    if req.itemSpace then
        for name, space in pairs(req.itemSpace) do
            robot.free(name, space) -- free the mock reserved items
        end
    end
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

function task.run(name, opts, reloadGlobals)
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

    if reloadGlobals then
        _G.robot = require("%INSTALL_DIR%/api/robot")
    end

    if not opts.resumed then
        processRequirements(_task.requirements)
    end

    local result = runProtected(_task.run, opts, ctrl)

    removeConfigFile()
    print(result .. ": " .. name, table.unpack(opts))
end

function task.resume()
    if fs.exists(configFile) then
        local config = readConfigFile()
        config.opts.resumed = true

        task.run(config.name, config.opts)
    end
end

return task
