return function(robot, meta, constants, utility)
    local TEST_EVENT = "test_event"
    local TEST_EVENT_DETAIL = { text = "hello, world!"}

    local detail
    local cb = function(e)
        detail = e.detail
    end

    meta.addEventListener(TEST_EVENT, cb)

    local e = meta.createEvent(TEST_EVENT, TEST_EVENT_DETAIL)

    meta.dispatchEvent(e)
    assert(detail and detail.text == TEST_EVENT_DETAIL.text)

    detail = nil
    meta.removeEventListener(TEST_EVENT, cb)

    meta.dispatchEvent(e)
    assert(not detail)

    meta.on(TEST_EVENT, cb)

    meta.dispatchEvent(e)
    assert(detail and detail.text == TEST_EVENT_DETAIL.text)

    detail = nil
    meta.on(TEST_EVENT, nil)

    meta.dispatchEvent(e)
    assert(not detail)

    local counter = 0
    local extra = true
    local function check()
        return counter > 1 and extra
    end

    local function tick()
        counter = counter + 1
    end

    meta.try(check, tick, false)
    assert(counter == 1)

    counter = 0
    meta.try(check, tick, true)
    assert(counter == 2)

    local function blocking()
        extra = true
    end

    counter = 0
    extra = false
    meta.try(check, tick, blocking)
    assert(counter == 2 and extra)

    local function get()
        return {counter = counter, extra = extra}
    end

    local function constructor(detail)
        return meta.createEvent(TEST_EVENT, detail)
    end

    counter = 0
    extra = false
    local stopped
    cb = function(e)
        stopped = true
        e.stopRequire()
    end

    meta.addEventListener(TEST_EVENT, cb)
    meta.require(check, get, constructor)
    assert(stopped)

    meta.removeEventListener(TEST_EVENT, cb)

    print("test_core passed")
end
