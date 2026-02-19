return function(opts, ctrl)
    local limit = tonumber(opts[1]) or 100

    for i = 1, limit do
        os.sleep(1)
        ctrl.reportProgress(i / limit)
    end
end
