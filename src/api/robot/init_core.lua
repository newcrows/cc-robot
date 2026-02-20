return function(_, meta)
    local listeners = {}
    local nextId = 1
    local callbacksListener = {}

    local function getEntries(table, keyAlias, valueAlias)
        keyAlias = keyAlias or "key"
        valueAlias = valueAlias or "value"

        local entries = {}

        for k, v in pairs(table) do
            entries[#entries + 1] = {
                [keyAlias] = k,
                [valueAlias] = v
            }
        end

        return entries
    end

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
        return getEntries(listeners, "id", "listener")
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

    function meta.require(check, tick, strategy)
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
            local didTick = tick()

            if check() then
                return
            end

            if not didTick then
                os.sleep(1)
            end
        end
    end

    function meta.requireCleared(check, get, warning)
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

        meta.require(check, tick, strategy)

        if dispatched then
            meta.dispatchEvent(warning .. "_cleared")
        end
    end

    meta.addEventListener(callbacksListener)
end
