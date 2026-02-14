return function(robot, meta)
    local listeners = {}
    local nextId = 1

    function robot.addEventListener(listener)
        assert(type(listener) == "table", "listener must be a table")

        local id = nextId

        listeners[id] = listener
        nextId = nextId + 1

        return id
    end

    function robot.removeEventListener(id)
        assert(type(id) == "number", "id must be a number")

        listeners[id] = nil
        return true
    end

    function robot.getEventListener(id)
        assert(type(id) == "number", "id must be a number")

        return listeners[id]
    end

    function robot.listEventListeners()
        local arr = {}

        for id, listener in pairs(listeners) do
            table.insert(arr, {
                id = id,
                listener = listener
            })
        end

        return arr
    end

    function meta.dispatchEvent(name, ...)
        for _, listener in pairs(listeners) do
            if listener[name] then
                listener[name](...)
            end
        end
    end
end
