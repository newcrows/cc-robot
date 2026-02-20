return function(_, meta)
    local listeners = {}
    local nextId = 1

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

    function meta.ensure(check, tick, strategy)
        if type(check) ~= "function" then
            error("check must be a function")
        end

        if type(tick) ~= "function" then
            error("tick must be a function")
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
        local dispatched

        local function strategy()
            meta.dispatchEvent(warning, table.unpack(get()), dispatched)
            dispatched = true
        end

        local function tick()
        end

        meta.ensure(check, tick, strategy)

        if dispatched then
            meta.dispatchEvent(warning .. "_cleared")
        end
    end
end
