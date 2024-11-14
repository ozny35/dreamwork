local _G = _G
local std = _G.gpm.std

local getfenv, table_unpack = std.getfenv, std.table.unpack

local glua_timer_Adjust, glua_timer_Create, glua_timer_Exists, glua_timer_Pause, glua_timer_Remove, glua_timer_RepsLeft, glua_timer_Start, glua_timer_Stop, glua_timer_TimeLeft, glua_timer_Toggle, glua_timer_UnPause, glua_timer_Simple
do
    local glua_timer = _G.timer
    glua_timer_Adjust, glua_timer_Create, glua_timer_Exists, glua_timer_Pause, glua_timer_Remove, glua_timer_RepsLeft, glua_timer_Start, glua_timer_Stop, glua_timer_TimeLeft, glua_timer_Toggle, glua_timer_UnPause, glua_timer_Simple = glua_timer.Adjust, glua_timer.Create, glua_timer.Exists, glua_timer.Pause, glua_timer.Remove, glua_timer.RepsLeft, glua_timer.Start, glua_timer.Stop, glua_timer.TimeLeft, glua_timer.Toggle, glua_timer.UnPause, glua_timer.Simple
end

local timer = {
    simple = glua_timer_Simple
}

function timer.adjust( identifier, delay, repetitions, func )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Adjust( identifier, delay, repetitions, func )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Adjust( identifier, delay, repetitions, func )
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

    return glua_timer_Adjust( pkg.prefix .. identifier, delay, repetitions, func )
end

function timer.create( identifier, delay, repetitions, func )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Create( identifier, delay, repetitions, func )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Create( identifier, delay, repetitions, func )
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

    return glua_timer_Create( pkg.prefix .. identifier, delay, repetitions, func )
end

function timer.exists( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Exists( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Exists( identifier )
    end

    return glua_timer_Exists( pkg.prefix .. identifier )
end

function timer.pause( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Pause( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Pause( identifier )
    end

    return glua_timer_Pause( pkg.prefix .. identifier )
end

function timer.remove( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Remove( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Remove( identifier )
    end

    local timers = pkg.__timers
    if timers == nil then
        timers = {}; pkg.__timers = timers
    end

    timers[ identifier ] = nil
    return glua_timer_Remove( pkg.prefix .. identifier )
end

function timer.repetitionsLeft( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_RepsLeft( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_RepsLeft( identifier )
    end

    return glua_timer_RepsLeft( pkg.prefix .. identifier )
end

function timer.start( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Start( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Start( identifier )
    end

    return glua_timer_Start( pkg.prefix .. identifier )
end

function timer.stop( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Stop( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Stop( identifier )
    end

    return glua_timer_Stop( pkg.prefix .. identifier )
end

function timer.timeLeft( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_TimeLeft( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_TimeLeft( identifier )
    end

    return glua_timer_TimeLeft( pkg.prefix .. identifier )
end

function timer.toggle( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_Toggle( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_Toggle( identifier )
    end

    return glua_timer_Toggle( pkg.prefix .. identifier )
end

function timer.unpause( identifier )
    local fenv = getfenv( 2 )
    if fenv == nil then
        return glua_timer_UnPause( identifier )
    end

    local pkg = fenv.__package
    if pkg == nil then
        return glua_timer_UnPause( identifier )
    end

    return glua_timer_UnPause( pkg.prefix .. identifier )
end

function timer.getTable()
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
end

function timer.tick( fn, ... )
    local args = { ... }
    return glua_timer_Simple( 0, function() return fn( table_unpack( args ) ) end )
end

return timer
