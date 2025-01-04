local _G = _G
local std = _G.gpm.std

local getfenv, table_unpack = std.getfenv, std.table.unpack

local glua_timer_Adjust, glua_timer_Create, glua_timer_Exists, glua_timer_Pause, glua_timer_Remove, glua_timer_RepsLeft, glua_timer_Start, glua_timer_Stop, glua_timer_TimeLeft, glua_timer_Toggle, glua_timer_UnPause, glua_timer_Simple
do
    local glua_timer = _G.timer
    glua_timer_Adjust, glua_timer_Create, glua_timer_Exists, glua_timer_Pause, glua_timer_Remove, glua_timer_RepsLeft, glua_timer_Start, glua_timer_Stop, glua_timer_TimeLeft, glua_timer_Toggle, glua_timer_UnPause, glua_timer_Simple = glua_timer.Adjust, glua_timer.Create, glua_timer.Exists, glua_timer.Pause, glua_timer.Remove, glua_timer.RepsLeft, glua_timer.Start, glua_timer.Stop, glua_timer.TimeLeft, glua_timer.Toggle, glua_timer.UnPause, glua_timer.Simple
end

---@class gpm.std.timer
local timer = {
    simple = glua_timer_Simple
}

--- Adjusts a previously created timer by `timer.create` with the given identifier.
---@param identifier string: Identifier of the timer to adjust.
---@param delay number: The delay interval in seconds.
---@param repetitions number?: Repetitions. Use 0 for infinite or nil to keep previous value.
---@param func function?: The new function. Use nil to keep previous value.
---@return boolean: True if successful, false otherwise.
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
    if data == nil then
        return false
    end

    delay = delay or data[ 1 ]
    data[ 1 ] = delay

    repetitions = repetitions or data[ 2 ]
    data[ 2 ] = repetitions

    func = func or data[ 3 ]
    data[ 3 ] = func

    return glua_timer_Adjust( pkg.prefix .. identifier, delay, repetitions, func )
end

--- Creates a new timer that will repeat its function given amount of times. This function also requires the timer to be named, which allows you to control it after it was created via the timer.
---@param identifier string: Identifier of the timer to create. Must be unique. If a timer already exists with the same identifier, that timer will be updated to the new settings and reset.
---@param delay number: The delay interval in seconds. If the delay is too small, the timer will fire on the next Tick.
---@param repetitions number: The number of times to repeat the timer. Enter 0 or any value below 0 for infinite repetitions.
---@param func function: Function called when timer has finished the countdown.
function timer.create( identifier, delay, repetitions, func )
    local fenv = getfenv( 2 )
    if fenv == nil then
        glua_timer_Create( identifier, delay, repetitions, func )
        return
    end

    local pkg = fenv.__package
    if pkg == nil then
        glua_timer_Create( identifier, delay, repetitions, func )
        return
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

    glua_timer_Create( pkg.prefix .. identifier, delay, repetitions, func )
end

--- Returns whenever the given timer exists or not.
---@param identifier string: Identifier of the timer.
---@return boolean: Returns `true` if the timer exists, `false` if it doesn't
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

--- Pauses the given timer.
---@param identifier string: Identifier of the timer.
---@return boolean: `false` if the timer didn't exist or was already paused, `true` otherwise.
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

--- Stops and removes a timer created by `timer.create`.
---@param identifier string: Identifier of the timer to remove.
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

--- Returns amount of repetitions/executions left before the timer destroys itself.
---@param identifier string: Identifier of the timer.
---@return number: The amount of executions left.
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

--- Restarts the given timer.
---@param identifier string: Identifier of the timer.
---@return boolean: `true` if the timer exists, `false` if it doesn't.
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

--- Stops the given timer and rewinds it.
---@param identifier string: Identifier of the timer.
---@return boolean: `false` if the timer didn't exist or was already stopped, `true` otherwise.
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

--- Returns amount of time left (in seconds) before the timer executes its function.<br>
--- NOTE: If the timer is paused, the amount will be negative.
---@param identifier string: Identifier of the timer.
---@return number: The amount of time left (in seconds).
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

--- Runs either `timer.pause` or `timer.unpause` based on the timer's current status.
---@param identifier string: Identifier of the timer.
---@return boolean: `true` if timer was not paused, `false` if it was.
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

--- Unpauses the timer.
---@param identifier string: Identifier of the timer.
---@return boolean: `false` if the timer didn't exist or was already running, `true` otherwise.
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

--- Returns the table of timers created by `timer.create`.<br>(WORKS ONLY IN PACKAGES)
---@return table | nil: The table of timers or `nil` if the table doesn't exist.
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

--- Runs the function in the next engine tick.
---@param fn function: Function to run.
---@param ... any: Arguments to pass to the function.
function timer.tick( fn, ... )
    local args = { ... }
    glua_timer_Simple( 0, function() fn( table_unpack( args ) ) end )
end

return timer
