-- TODO [JM] implement the generic inventory api
return {
    name = "minecraft:chest",
    constructor = function(opts)
        local side = opts.side

        return {
            info = function()
                if not peripheral.isPresent(side) then
                    print("I am not present")
                    return
                end

                print("I am a chest on " .. side)
            end
        }
    end
}
