return function(_, meta)
    -- TODO [JM] listeners must be called IN THE ORDER THEY WERE REGISTERED!
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

    -- TODO [JM] payload must be table instead of ...!
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

    -- TODO [JM] restructure so that callbacks all have the signature: callback(e)
    -- -> e is all props returned from get (MAKE THESE NAMED INSTEAD OF ARRAY)
    -- -> e has additional func e.cancelRequire() which cancels the meta.require call that triggered the event
    -- -> e has the companion func e.getRequireArgs() which tells you what was required in the first place
    -- -> e inherits the func e.stopPropagation() which means no other registered
    --      listeners are called after the current one's callback ends
    -- i.E.
    -- robot.onPathWarning(function (e)
    --   local rOrM = waitForResolutionOrManualMode()
    --   if rOrM == "r" then return end --resolved externally
    --
    --   e.cancelRequire() --meta.require() will return after current callback and event will not propagate any more
    --   YOU MUST HANDLE THE WARNING HERE YOURSELF, basically meta.require() yielded control to you!
    --   use e.getRequireArgs() to reconstruct what SHOULD have happened and do it YOURSELF
    --   !!! if you fail to achieve the required state, programs will behave unexpectedly and/or crash !!!
    -- end)
    -- TODO [JM] need to extend signature to (args, check, get, warning)
    -- -> need this so that custom warning handling knows what was required in the first place
    -- -> i.E.
    -- e.cancelRequire()
    -- local args = e.getRequireArgs()
    -- -> args == {x, y, z, facing} in case of path_warning
    --  (the original moveTo args, NOT the obstructing block args, these are already in e)
    -- -> move to the required position by yourself, using any method you deem good enough
    -- maybe we can inline for brevity and have e.cancelRequire return the args already:
    -- local args = e.cancelRequire()
    -- // handle the original task
    -- this is only possible however IF THE TASK IS CANCELLABLE
    -- -> maybe returns a boolean?
    -- i.E.
    -- local cancelled = e.cancelRequire()
    --
    -- if cancelled then
    --   local args = e.getRequireArgs()
    --   // fix it!
    -- end
    --
    -- // let the loop pass and meta.require continues to handle the problem
    -- NOTE: e must still carry e.alreadyWarned, we need that prop!
    -- NOTE: e.cancelRequire, e.getRequireArgs only exist if the event is a meta.require event
    --  any other event does not have those (duh)
    function meta.require(check, get, warning)
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

        local function blocking()
            meta.dispatchEvent(warning, dispatched, get())
            dispatched = true
        end

        local function tick()
        end

        meta.try(check, tick, blocking)

        if dispatched then
            meta.dispatchEvent(warning .. "_cleared")
        end
    end

    meta.addEventListener(callbacksListener)
end
