return function(_, meta)
    local callbacks = {}
    local singularCallbacks = {}

    local function remove(t, value)
        for i = #t, 1, -1 do
            if t[i] == value then
                return table.remove(t, i)
            end
        end
    end

    function meta.addEventListener(name, callback)
        assert(name, "name must not be nil")
        assert(type(callback) == "function", "callback must be a function")

        callbacks[name] = (callbacks[name] or {})
        table.insert(callbacks[name], 1, callback)
    end

    function meta.removeEventListener(name, callback)
        assert(name, "name must not be nil")
        assert(type(callback) == "function", "callback must be a function")

        if callbacks[name] then
            remove(callbacks[name], callback)
        end
    end

    function meta.createEvent(name, detail)
        if not name then
            error("name must not be nil", 0)
        end

        local event = {
            name = name,
            detail = detail
        }

        function event.stopPropagation()
            event.stopped = true
        end

        return event
    end

    function meta.dispatchEvent(event)
        if not event then
            error("event must not be nil", 0)
        end

        local eventCallbacks = callbacks[event.name]

        if eventCallbacks then
            for i = #eventCallbacks, 1, -1 do
                eventCallbacks[i](event)

                if event.stopped then
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

        local stopped = false

        local function stop()
            stopped = true
        end

        blocking = type(blocking) == "function" and blocking or function()
        end

        while true do
            local didBlocking = blocking(stop)
            local didTick = tick(stop)

            if stopped or check() then
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
        local stopped
        local name

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
            -- nop
        end

        meta.try(checkRequire, tick, blocking)

        if dispatched then
            local e = meta.createEvent(name .. "_cleared")
            meta.dispatchEvent(e)
        end
    end
end
