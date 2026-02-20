return {
    run = function(opts, ctrl)
        local robot = opts.robot
        local chest = robot.wrap()

        chest.import("minecraft:cobblestone", 32)

        for k, v in pairs(chest.listItems()) do
            print(k .. " = " .. v)
        end
    end
}
