return function(_, meta)
    -- TODO [JM] listeners must be called IN THE ORDER THEY WERE REGISTERED!
    local callbacks = {}
    local singularCallbacks = {}

    local function remove(t, value)
        local index = nil
        for i, v in ipairs(t) do
            if v == value then
                index = i
                break
            end
        end

        if index then
            return table.remove(t, index)
        end

        return nil
    end

    function meta.addEventListener(name, callback)
        assert(name, "name must not be nil")
        assert(type(callback) == "function", "callback must be a function")

        callbacks[name] = (callbacks[name] or {})
        table.insert(callbacks[name], callback)
    end

    function meta.removeEventListener(name, callback)
        assert(name, "name must not be nil")
        assert(type(callback) == "function", "callback must be a function")

        if callbacks[name] then
            remove(callbacks[name], callback)
        end
    end

    function meta.createEvent(name, detail)
        local e_meta = {}
        local e = {
            name = name,
            detail = detail, -- optional
            stopPropagation = function()
                e_meta.stopped = true
            end
        }

        e.meta = e_meta
        return e
    end

    function meta.dispatchEvent(e)
        local e_callbacks = callbacks[e.name]

        if e_callbacks then
            for _, callback in ipairs(e_callbacks) do
                callback(e)

                if e.meta.stopped then
                    break
                end
            end
        end
    end

    function meta.on(name, callback)
        local prevCallback = singularCallbacks[name]

        if prevCallback then
            meta.removeEventListener(name, prevCallback)
        end

        if callback then
            meta.addEventListener(name, callback)
        end

        singularCallbacks[name] = callback
    end

    function meta.try(check, tick, blocking)
        -- call tick() immediately
        -- call check() immediately -> if true return immediately
        -- if not blocking -> return immediately
        --
        -- then do the following in an endless loop:
        -- call blocking()
        -- call tick()
        -- call check() and return immediately if true
        -- if neither blocking nor tick returned true, yield for one second
        -- continue the loop

        if type(check) ~= "function" then
            error("check must be a function", 0)
        end

        if type(tick) ~= "function" then
            error("tick must be a function", 0)
        end

        tick()

        local ok = check()
        if ok or not blocking then
            return
        end

        blocking = type(blocking) == "function" and blocking or function()
        end

        while true do
            local didBlocking = blocking()
            local didTick = tick()

            if check() then
                return
            end

            if not didBlocking and not didTick then
                os.sleep(1)
            end
        end
    end

    function meta.require(check, get, constructor)
        -- meta.require(..) essentially calls check() until it returns true
        --
        -- for every iteration of an endless loop:
        -- get() is called to get the current state
        -- each iteration's current state is dispatched as a new event constructed by constructor
        -- if e.stopRequire() is called, we return immediately
        -- if check() returns true, we return immediately
        -- otherwise, sleep one second
        -- continue the loop

        if type(check) ~= "function" then
            error("check must be a function", 0)
        end

        if type(get) ~= "function" then
            error("get must be a function", 0)
        end

        if type(constructor) ~= "function" then
            error("constructor must be a function", 0)
        end

        local dispatched
        local name
        local stopped

        local function checkRequire()
            return stopped or check()
        end

        local function blocking()
            local e = constructor(get())

            e.alreadyWarned = dispatched
            e.stopRequire = function()
                stopped = true
                e.stopPropagation()
            end

            meta.dispatchEvent(e)

            dispatched = true
            name = e.name
        end

        local function tick()
        end

        meta.try(checkRequire, tick, blocking)

        if dispatched then
            local e = meta.createEvent(name .. "_cleared")
            meta.dispatchEvent(e)
        end
    end
end
