local function setup()

end

local function teardown()

end

return function(robot)
    setup()

    local arg1
    local arg2

    local listenerCount = #robot.meta.listEventListeners()
    local listener = {
        test_event = function(_arg1, _arg2)
            arg1 = _arg1
            arg2 = _arg2
        end
    }
    local id = robot.meta.addEventListener(listener)

    assert(robot.meta.getEventListener(id).listener == listener)
    assert(#robot.meta.listEventListeners() == listenerCount + 1)

    robot.meta.dispatchEvent("test_event", "hello", "world")
    assert(arg1 == "hello" and arg2 == "world")

    arg1 = nil
    arg2 = nil

    robot.meta.removeEventListener(id)
    robot.meta.dispatchEvent("test_event", "hello", "world")
    assert(not arg1 and not arg2)

    teardown()
    print("test_events passed")
end
