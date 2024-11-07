local timer, table_unpack, getfenv = ...
local timer_Adjust, timer_Create, timer_Exists, timer_Pause, timer_Remove, timer_RepsLeft, timer_Start, timer_Stop, timer_TimeLeft, timer_Toggle, timer_UnPause, timer_Simple = timer.Adjust, timer.Create, timer.Exists, timer.Pause, timer.Remove, timer.RepsLeft, timer.Start, timer.Stop, timer.TimeLeft, timer.Toggle, timer.UnPause, timer.Simple

return {
    ["adjust"] = function( identifier, delay, repetitions, func )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Adjust( identifier, delay, repetitions, func )
        end

        local pkg = fenv.__package
        if pkg == nil then
            return timer_Adjust( identifier, delay, repetitions, func )
        end

        local timers = pkg.__timers
        if timers == nil then
            timers = {}; pkg.__timers = timers
        end

        local data = timers[ identifier ]
        if data == nil then return nil end

        delay = delay or data[ 1 ]
        data[ 1 ] = delay

        repetitions = repetitions or data[ 2 ]
        data[ 2 ] = repetitions

        func = func or data[ 3 ]
        data[ 3 ] = func

        return timer_Adjust( pkg.prefix .. identifier, delay, repetitions, func )
    end,
    ["create"] = function( identifier, delay, repetitions, func )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Create( identifier, delay, repetitions, func )
        end

        local pkg = fenv.__package
        if pkg == nil then
            return timer_Create( identifier, delay, repetitions, func )
        end

        local timers = pkg.__timers
        if timers == nil then
            timers = {}; pkg.__timers = timers
        end

        local data = timers[ identifier ]
        if data == nil then
            timers[ identifier ] = { delay, repetitions, func }
        else
            data[ 1 ] = delay
            data[ 2 ] = repetitions
            data[ 3 ] = func
        end

        return timer_Create( pkg.prefix .. identifier, delay, repetitions, func )
    end,
    ["exists"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Exists( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_Exists( identifier )
            else
                return timer_Exists( pkg.prefix .. identifier )
            end
        end
    end,
    ["pause"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Pause( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_Pause( identifier )
            else
                return timer_Pause( pkg.prefix .. identifier )
            end
        end
    end,
    ["remove"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Remove( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_Remove( identifier )
            else
                local timers = pkg.__timers
                if timers == nil then
                    timers = {}; pkg.__timers = timers
                end

                timers[ identifier ] = nil
                return timer_Remove( pkg.prefix .. identifier )
            end
        end
    end,
    ["repetitionsLeft"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_RepsLeft( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_RepsLeft( identifier )
            else
                return timer_RepsLeft( pkg.prefix .. identifier )
            end
        end
    end,
    ["start"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Start( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_Start( identifier )
            else
                return timer_Start( pkg.prefix .. identifier )
            end
        end
    end,
    ["stop"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Stop( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_Stop( identifier )
            else
                return timer_Stop( pkg.prefix .. identifier )
            end
        end
    end,
    ["timeLeft"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_TimeLeft( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_TimeLeft( identifier )
            else
                return timer_TimeLeft( pkg.prefix .. identifier )
            end
        end
    end,
    ["toggle"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_Toggle( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_Toggle( identifier )
            else
                return timer_Toggle( pkg.prefix .. identifier )
            end
        end
    end,
    ["unpause"] = function( identifier )
        local fenv = getfenv( 2 )
        if fenv == nil then
            return timer_UnPause( identifier )
        else
            local pkg = fenv.__package
            if pkg == nil then
                return timer_UnPause( identifier )
            else
                return timer_UnPause( pkg.prefix .. identifier )
            end
        end
    end,
    ["getTable"] = function()
        local fenv = getfenv( 2 )
        if fenv == nil then
            return nil
        end

        local pkg = fenv.__package
        if pkg == nil then
            return nil
        end

        local timers = pkg.__timers
        if timers == nil then
            timers = {}; pkg.__timers = timers
        end

        return timers
    end,
    ["simple"] = timer_Simple,
    ["tick"] = function( fn, ... )
        local args = { ... }
        return timer_Simple( 0, function() return fn( table_unpack( args ) ) end )
    end
}
