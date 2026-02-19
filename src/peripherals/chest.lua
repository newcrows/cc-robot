-- TODO [JM] rename this to "inventory.lua" and implement the generic inventory api
-- then use names = {"chest", "barrel", etc..} to register this for all inventory-like peripherals
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
