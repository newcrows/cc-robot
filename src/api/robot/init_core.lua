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

    function meta.createEvent(name)
        local e_meta = {}
        local e = {
            name = name,
            stopPropagation = function()
                e_meta.stopped = true
            end
        }

        e.meta = e_meta
        return e
    end

    function meta.dispatchEvent(e)
        local callbacks = callbacks[e.name]

        if callbacks then
            for _, callback in ipairs(callbacks) do
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

        local function blocking()
            local e = constructor(get())
            e.alreadyWarned = dispatched

            meta.dispatchEvent(e)

            dispatched = true
            name = e.name
        end

        local function tick()
        end

        meta.try(check, tick, blocking)

        if dispatched then
            local e = meta.createEvent(name .. "_cleared")
            meta.dispatchEvent(e)
        end
    end
end
