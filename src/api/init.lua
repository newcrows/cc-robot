local robot = require((...) .. "/robot")
local task = require((...) .. "/task")

local api = {
    robot = robot,
    task = task
}

return api
