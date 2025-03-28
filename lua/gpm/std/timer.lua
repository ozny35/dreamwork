local timer = _G.timer
if timer == nil then
    _G.gpm.Logger:error( "gpm.std.Timer: timer library not found" )
end

local std = _G.gpm.std

--- [SHARED AND MENU]
---
--- Timer object.
---@alias Timer gpm.std.Timer
---@class gpm.std.Timer: gpm.std.Object
---@field __class gpm.std.TimerClass
local Timer = std.class.base( "Timer" )

--- [SHARED AND MENU]
---
--- Timer class.
---@class gpm.std.TimerClass: gpm.std.Timer
---@field __base gpm.std.Timer
---@overload fun( name: string, delay: number?, repetitions: integer? ): Timer
local TimerClass = std.class.create( Timer )

do

    local status2string = {
        [ 0 ] = "removed",
        [ 1 ] = "stopped",
        [ 2 ] = "paused",
        [ 3 ] = "running"
    }

    function Timer:__tostring()
        return std.string.format( "Timer: %p [%s][%s]", self, self[ -2 ], status2string[ self[ -1 ] ] or "unknown" )
    end

end

---@alias gpm.std.Timer.Status
---| number # The timer status code.
---| `0` # Timer removed.
---| `1` # Timer stopped.
---| `2` # Timer paused.
---| `3` # Timer running.

do

    local timer_Create = timer.Create

    local function call( self )
        self[ -5 ] = true

        for i = 2, self[ 0 ], 2 do
            if not self[ -5 ] then break end
            self[ i ]( self )
        end

        self[ -5 ] = false

        local queue = self[ -6 ]

        if queue == nil then
            return
        end

        self[ -6 ] = nil

        for i = 1, #queue, 1 do
            local args = queue[ i ]
            if args[ 1 ] then
                self:attach( args[ 3 ], args[ 2 ] )
            else
                self:detach( args[ 2 ] )
            end
        end
    end

    ---@protected
    function Timer:__init( name, delay, repetitions )
        if repetitions == nil then repetitions = 1 end
        if delay == nil then delay = 0 end

        self[ 0 ] = 0
        self[ -1 ] = 2
        self[ -2 ] = name
        self[ -3 ] = delay
        self[ -4 ] = repetitions
        self[ -5 ] = false

        timer_Create( name, delay, repetitions, function()
            return call( self )
        end )
    end

end

--- [SHARED AND MENU]
---
--- Attaches a callback to the timer.
---@param fn function The callback function.
---@param name string?: The name of the callback, default is `unnamed`.
function Timer:attach( fn, name )
    if name == nil then name = "unnamed" end

    if self[ -5 ] then
        local queue = self[ -6 ]
        if queue == nil then
            self[ -6 ] = { { true, name, fn } }
        else
            queue[ #queue + 1 ] = { true, name, fn }
        end

        return
    end

    for i = 1, self[ 0 ], 2 do
        if self[ i ] == name then
            self[ i + 1 ] = fn
            return
        end
    end

    local index = self[ 0 ] + 1
    self[ index ] = name

    index = index + 1
    self[ index ] = fn

    self[ 0 ] = index
end

do

    local debug_fempty = std.debug.fempty
    local table_eject = std.table.eject

    --- [SHARED AND MENU]
    ---
    --- Detaches a callback from the timer.
    ---@param name string The name of the callback to detach.
    function Timer:detach( name )
        for i = 1, self[ 0 ], 2 do
            if self[ i ] == name then
                if self[ -5 ] then
                    self[ i + 1 ] = debug_fempty

                    local queue = self[ -6 ]
                    if queue == nil then
                        self[ -6 ] = { { false, name } }
                    else
                        queue[ #queue + 1 ] = { false, name }
                    end
                else
                    table_eject( self, i, i + 1 )
                    self[ 0 ] = self[ 0 ] - 2
                end

                break
            end
        end
    end

end

--- [SHARED AND MENU]
---
--- Detaches all timer callbacks.
function Timer:clear()
    self[ -5 ] = false

    for i = 1, self[ 0 ], 1 do
        self[ i ] = nil
    end

    self[ 0 ] = 0
end

---@protected
function Timer:__isvalid()
    return self[ -1 ] ~= 0
end

do

    local timer_Start = timer.Start

    --- [SHARED AND MENU]
    ---
    --- Start the timer.
    ---@return boolean: Returns `true` if successful, otherwise `false`.
    function Timer:start()
        local status = self[ -1 ]
        if status == 0 or status == 3 then return false end

        if status == 2 then
            self:setPause( false )
        end

        timer_Start( self[ -2 ] )
        self[ -1 ] = 3
        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Restart the timer.
    ---@return boolean: Returns `true` if successful, otherwise `false`.
    function Timer:restart()
        if self[ -1 ] == 0 then return false end
        self:setPause( false )

        timer_Start( self[ -2 ] )
        self[ -1 ] = 3
        return true
    end

end

do

    local timer_Stop = timer.Stop

    --- [SHARED AND MENU]
    ---
    --- Stops the timer.
    ---@return boolean: Returns `true` if successful, otherwise `false`.
    function Timer:stop()
        local status = self[ -1 ]
        if status == 0 or status == 1 then return false end

        if status == 2 then
            self:setPause( false )
        end

        timer_Stop( self[ -2 ] )
        self[ -1 ] = 1
        return true
    end

end

do

    local timer_Adjust = timer.Adjust

    --- [SHARED AND MENU]
    ---
    --- Returns the number of timer repetitions.
    ---@return integer: The number of timer repetitions.
    function Timer:getRepetitions()
        return self[ -4 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the number of timer repetitions.
    ---@param repetitions integer?: The number of timer repetitions.
    ---@return boolean: Returns `true` if successful, otherwise `false`.
    function Timer:setRepetitions( repetitions )
        if self[ -1 ] == 0 then return false end
        repetitions = self[ -4 ] or repetitions
        self[ -4 ] = repetitions

        timer_Adjust( self[ -2 ], self[ -3 ], repetitions )
        return true
    end

    do

        local timer_RepsLeft = timer.RepsLeft

        --- [SHARED AND MENU]
        ---
        --- Returns the number of timer repetitions left.
        ---@return integer: The number of timer repetitions left.
        function Timer:getRepetitionsLeft()
            if self[ -1 ] == 0 then return 0 end
            return timer_RepsLeft( self[ -1 ] )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Returns the delay between repetitions of the timer in seconds.
    ---@return number: The delay between repetitions in seconds.
    function Timer:getDelay()
        return self[ -3 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the delay between repetitions of the timer in seconds.
    ---@param delay number?: The delay between repetitions in seconds.
    ---@return boolean: Returns `true` if successful, otherwise `false`.
    function Timer:setDelay( delay )
        if self[ -1 ] == 0 then return false end
        delay = self[ -3 ] or delay
        self[ -3 ] = delay

        ---@cast delay number

        timer_Adjust( self[ -2 ], delay )
        return true
    end

    do

        local timer_TimeLeft = timer.TimeLeft
        local math_huge = std.math.huge

        --- [SHARED AND MENU]
        ---
        --- Returns the time left to the next callbacks call in seconds.
        ---@return number: The time left in seconds.
        function Timer:getTimeLeft()
            if self[ -1 ] == 3 then
                return timer_TimeLeft( self[ -2 ] )
            else
                return math_huge
            end
        end

    end

end

do

    local timer_Remove = timer.Remove

    --- [SHARED AND MENU]
    ---
    --- Removes the timer.
    ---@return boolean: Returns `true` if successful, `false` if timer already removed.
    function Timer:remove()
        if self[ -1 ] == 0 then return false end
        self[ -1 ] = 0
        self:clear()

        timer_Remove( self[ -1 ] )
        return true
    end

end

--- [SHARED AND MENU]
---
--- Checks if the timer is valid.
---@return boolean: Returns `true` if the timer is valid (not removed), otherwise `false`.
function Timer:isValid()
    return self[ -1 ] ~= 0
end

--- [SHARED AND MENU]
---
--- Checks if the timer is stopped.
---@return boolean: Returns `true` if the timer is stopped, otherwise `false`.
function Timer:isStopped()
    return self[ -1 ] == 1
end

--- [SHARED AND MENU]
---
--- Checks if the timer is paused.
---@return boolean: Returns `true` if the timer is paused, otherwise `false`.
function Timer:isPaused()
    return self[ -1 ] == 2
end

--- [SHARED AND MENU]
---
--- Checks if the timer is running.
---@return boolean: Returns `true` if the timer is running, otherwise `false`.
function Timer:isRunning()
    return self[ -1 ] == 3
end

do

    local timer_Pause, timer_UnPause = timer.Pause, timer.UnPause

    --- [SHARED AND MENU]
    ---
    --- Pauses/unpauses the timer.
    ---@param value boolean `true` to pause, `false` to unpause.
    ---@return boolean: Returns `true` if successful, otherwise `false`.
    function Timer:setPause( value )
        local status = self[ -1 ]
        if status == 0 or status == 1 then return false end

        if value then
            if status == 2 then return false end
            timer_Pause( self[ -2 ] )
            self[ -1 ] = 2
        else
            if status == 3 then return false end
            timer_UnPause( self[ -2 ] )
            self[ -1 ] = 3
        end

        return true
    end

end

do

    local timer_Simple = timer.Simple

    --- [SHARED AND MENU]
    ---
    --- Creates a simple timer.
    ---@param fn function The callback function.
    ---@param seconds number?: The delay in seconds.
    function TimerClass.wait( fn, seconds )
        return timer_Simple( seconds or 0, fn )
    end

end

do

    local timer_Exists = timer.Exists

    --- [SHARED AND MENU]
    ---
    --- Checks if the timer exists.
    ---@param name string The name of the timer.
    ---@return boolean: Returns `true` if the timer exists, otherwise `false`.
    function TimerClass.exists( name )
        return timer_Exists( name )
    end

end

return TimerClass
