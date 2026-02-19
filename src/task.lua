local task = require("%INSTALL_DIR%/api/task")
local args = {...}
local name = args[1]
local opts = {}

for i = 2, #args do
    table.insert(opts, args[i])
end

task.run(name, opts)
