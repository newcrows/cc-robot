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

    function meta.waitFor(checkState, getState, warningEvent)
        local checked = checkState()
        local waited = false

        if checked then
            return
        end

        while not checked do
            if waited then
                os.sleep(1)
            end

            meta.dispatchEvent(event, table.unpack(getState()), waited)

            checked = checkState()
            waited = true
        end

        meta.dispatchEvent(event .. "_cleared")
    end
end
