return {
    run = function(opts, ctrl)
        local limit = tonumber(opts[1]) or 10
        local interval = tonumber(opts[2]) or 1

        for i = 1, limit do
            os.sleep(interval)
            ctrl.tick(i / limit)
        end
    end
}
