return function(_, meta)
    local listeners = {}
    local nextId = 1
    local callbacksListener = {}

    function meta.addEventListener(listener)
        assert(type(listener) == "table", "listener must be a table")

        local id = nextId

        listeners[id] = listener
        nextId = nextId + 1

        return id
    end

    function meta.removeEventListener(id)
        assert(type(id) == "number", "id must be a number")

        listeners[id] = nil
        return true
    end

    function meta.getEventListenerDetail(id)
        assert(type(id) == "number", "id must be a number")

        local listener = listeners[id]

        if listener then
            return {
                id = id,
                listener = listener
            }
        end

        return nil
    end

    function meta.listEventListeners()
        local arr = {}

        for id, listener in pairs(listeners) do
            table.insert(arr, {
                id = id,
                listener = listener
            })
        end

        return arr
    end

    function meta.dispatchEvent(event, ...)
        assert(event, "event must not be nil")

        for _, listener in pairs(listeners) do
            if listener[event] then
                listener[event](...)
            end
        end
    end

    function meta.on(event, callback)
        callbacksListener[event] = callback -- it can be so simple..
    end

    -- TODO [JM] use this wherever we loop table keys!! maybe add similar helpers here (getValues ?)
    function meta.getKeys(table)
        local keys = {}

        for key in pairs(table) do
            keys[#keys + 1] = key
        end

        return keys
    end

    function meta.getValues(table)
        local values = {}

        for _, value in pairs(table) do
            values[#values + 1] = value
        end

        return values
    end

    function meta.ensure(check, tick, strategy)
        if type(check) ~= "function" then
            error("check must be a function", 0)
        end

        if type(tick) ~= "function" then
            error("tick must be a function", 0)
        end

        tick()

        local ok = check()
        if ok or not strategy then
            return
        end

        strategy = type(strategy) == "function" and strategy or function()
        end

        while true do
            strategy()
            tick()

            if check() then
                return
            end

            os.sleep(1)
        end
    end

    function meta.ensureCleared(check, get, warning)
        if type(check) ~= "function" then
            error("check must be a function", 0)
        end

        if type(get) ~= "function" then
            error("get must be a function", 0)
        end

        if not warning then
            error("warning must not be nil", 0)
        end

        local dispatched

        local function strategy()
            meta.dispatchEvent(warning, dispatched, get())
            dispatched = true
        end

        local function tick()
        end

        meta.ensure(check, tick, strategy)

        if dispatched then
            meta.dispatchEvent(warning .. "_cleared")
        end
    end

    meta.addEventListener(callbacksListener)
end
