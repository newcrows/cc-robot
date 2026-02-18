return {
    name = "advancedperipherals:me_bridge",
    constructor = function(opts)
        local side = opts.side

        return {
            info = function()
                if not peripheral.isPresent(side) then
                    print("I am not present")
                    return
                end

                print("I am a me_bridge on " .. side)
            end
        }
    end
}
