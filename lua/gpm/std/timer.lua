local timer = _G.timer
if timer == nil then
    error( "timer library not found" )
end

---@class gpm.std
local std = _G.gpm.std

if std.Timer ~= nil then
    return
end

local gc_setTableRules = std.debug.gc.setTableRules
local game_getUptime = std.game.getUptime
local timer_RepsLeft = timer.RepsLeft
local timer_UnPause = timer.UnPause
local timer_Exists = timer.Exists
local timer_Create = timer.Create
local timer_Adjust = timer.Adjust

--- [SHARED AND MENU]
---
--- The timer object.
---
---@class gpm.std.Timer : gpm.std.Object
---@field __class gpm.std.TimerClass
---@field name string The internal name of the timer. **Read-only.**
---@field state gpm.std.Timer.state The current state of the timer. **Read-only.**
---@field delay number The delay between repetitions of the timer in seconds.
---@field repetition_index integer The current repetition index of the timer. **Read-only.**
---@field repetitions_total integer The total amount of repetitions of the timer.
---@field repetitions_remaining integer The remaining amount of repetitions of the timer. **Read-only.**
---@field time_total number The total running time of the timer in seconds. **Read-only.**
---@field time_remaining number The remaining running time of the timer in seconds. **Read-only.**
---@field time_elapsed number The total elapsed time of the timer in seconds. **Read-only.**
---@field time_left number The remaining time until the next run of timer callbacks in seconds, or `nil` if the timer is stopped. **Read-only.**
---@field start_time number The start time of the timer in seconds. **Read-only.**
local Timer = std.class.base( "Timer", true )

--- [SHARED AND MENU]
---
--- The timer class.
---
---@class gpm.std.TimerClass : gpm.std.Timer
---@field __base gpm.std.Timer
---@overload fun( delay: number?, repetitions_total: integer?, name: string? ): gpm.std.Timer
local TimerClass = std.class.create( Timer )
std.Timer = TimerClass

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Timer gpm.std.Timer

---@type table<gpm.std.Timer, string>
local names = {}

gc_setTableRules( names, true, false )

do

    local timer_Remove = timer.Remove

    ---@protected
    function Timer:__gc()
        local name = names[ self ]
        if name ~= nil and timer_Exists( name ) then
            timer_Remove( name )
        end
    end

end

---@alias gpm.std.Timer.state
---| `0` # Timer stopped.
---| `1` # Timer paused.
---| `2` # Timer running.

---@type table<gpm.std.Timer, gpm.std.Timer.state>
local states = {}

gc_setTableRules( states, true, false )

do

    local status2string = {
        [ 0 ] = "stopped",
        [ 1 ] = "paused",
        [ 2 ] = "running"
    }

    ---@protected
    function Timer:__tostring()
        return std.string.format( "Timer: %p [%s][%s]", self, self.name, status2string[ self.state ] or "unknown" )
    end

end

--- [SHARED AND MENU]
---
--- Checks if the timer is stopped.
---
---@return boolean is_stopped Returns `true` if the timer is stopped, otherwise `false`.
function Timer:isStopped()
    return self.state == 0
end

--- [SHARED AND MENU]
---
--- Checks if the timer is paused.
---
---@return boolean is_paused Returns `true` if the timer is paused, otherwise `false`.
function Timer:isPaused()
    return self.state == 1
end

--- [SHARED AND MENU]
---
--- Checks if the timer is running.
---
---@return boolean is_running Returns `true` if the timer is running, otherwise `false`.
function Timer:isRunning()
    return self.state == 2
end

---@type table<gpm.std.Timer, boolean>
local in_call = {}

gc_setTableRules( in_call, true, false )

---@class gpm.std.Timer.Callback

---@type table<gpm.std.Timer, table>
local callbacks = {}

std.setmetatable( callbacks, {
    __index = function( _, self )
        local t = {}
        callbacks[ self ] = t
        return t
    end,
    __mode = "k"
} )

---@type table<gpm.std.Timer, table>
local queues = {}

gc_setTableRules( queues, true, false )

---@type table<gpm.std.Timer, number>
local delays = {}

gc_setTableRules( delays, true, false )

---@type table<gpm.std.Timer, integer>
local repetitions_total = {}

gc_setTableRules( repetitions_total, true, false )

---@type table<gpm.std.Timer, integer>
local repetition_indexes = {}

gc_setTableRules( repetition_indexes, true, false )

---@type table<gpm.std.Timer, number>
local start_times = {}

gc_setTableRules( start_times, true, false )

---@type table<gpm.std.Timer, boolean | nil>
local running_timers = {}

do

    local debug_getmetatable = std.debug.getmetatable
    local timer_TimeLeft = timer.TimeLeft
    local raw_get = std.raw.get

    local math = std.math
    local math_abs = math.abs
    local math_huge = math.huge

    ---@protected
    function Timer:__index( key )
        if key == "name" then
            return names[ self ] or "unknown"
        elseif key == "state" then
            local name = names[ self ]
            if name ~= nil and timer_Exists( name ) and ( timer_TimeLeft( name ) or 0 ) < 0 then
                return 1
            else
                return states[ self ] or 0
            end
        elseif key == "delay" then
            return delays[ self ] or 0
        elseif key == "start_time" then
            return start_times[ self ] or 0
        elseif key == "repetition_index" then
            if self.repetitions_total == -1 then
                return repetition_indexes[ self ] or 0
            else
                return self.repetitions_total - self.repetitions_remaining
            end
        elseif key == "repetitions_total" then
            return repetitions_total[ self ] or 1
        elseif key == "repetitions_remaining" then
            local name = names[ self ]
            if name == nil or self.state == 0 then
                return self.repetitions_total
            elseif repetitions_total[ self ] == -1 then
                return math_huge
            end

            local repetitions_left = timer_RepsLeft( name )
            if repetitions_left == nil then
                return 0
            elseif repetitions_left == -1 then
                return math_huge
            else
                return repetitions_left
            end
        elseif key == "time_total" then
            local repetitions = self.repetitions_total
            if repetitions == 0 then
                return math_huge
            else
                return self.delay * repetitions
            end
        elseif key == "time_left" then
            if self.state == 0 then
                return self.delay
            end

            local name = names[ self ]
            if name == nil or not timer_Exists( name ) then
                return self.delay
            end

            local time_left = timer_TimeLeft( name )
            if time_left == nil then
                return self.delay
            end

            return math_abs( time_left )
        elseif key == "time_remaining" then
            if self.state == 0 then
                return self.time_total
            elseif self.repetitions_total == -1 then
                return math_huge
            else
                return self.time_total - self.time_elapsed
            end
        elseif key == "time_elapsed" then
            local delay = self.delay
            return ( self.repetition_index * delay ) - ( self.time_left - delay )
        else
            return raw_get( Timer, key )
        end
    end

end

do

    local tonumber = std.tonumber
    local math_max = math.max

    ---@protected
    function Timer:__newindex( key, value )
        if key == "delay" then
            local delay = math_max( 0, tonumber( value, 10 ) or 0 )
            delays[ self ] = delay

            local name = names[ self ]
            if name ~= nil and timer_Exists( name ) then
                timer_Adjust( name, delay )
            end
        elseif key == "repetitions_total" then
            local repetitions = math_max( 0, tonumber( value, 10 ) or 1 )
            repetitions_total[ self ] = repetitions

            if repetitions == 0 then
                running_timers[ self ] = nil
            end

            if self.state == 0 then
                local name = names[ self ]
                if name ~= nil and timer_Exists( name ) then
                    timer_Adjust( name, self.delay, repetitions )
                end
            end
        else
            error( "attempt to modify unknown timer property", 2 )
        end
    end

end

local timer_call
do

    local pcall = std.pcall

    ---@param self gpm.std.Timer
    function timer_call( self )
        if self.repetitions_total == -1 then
            local repetition_index = self.repetition_index + 1
            repetition_indexes[ self ] = repetition_index

            if start_times[ self ] == nil and repetition_index == 1 then
                start_times[ self ] = game_getUptime() - self.delay
            end
        elseif start_times[ self ] == nil and self.repetition_index == 1 then
            start_times[ self ] = game_getUptime() - self.delay
        end

        in_call[ self ] = true

        local lst = callbacks[ self ]

        for i = 2, #lst, 2 do
            if in_call[ self ] then
                local success, err_msg = pcall( lst[ i ], self )
                if not success then
                    -- TODO: replace with cool new errors that i make later
                    print( "[gpm] timer error: " .. err_msg )
                end
            else
                break
            end
        end

        in_call[ self ] = nil

        local queue = queues[ self ]
        if queue ~= nil then
            queues[ self ] = nil

            for i = 1, #queue, 1 do
                local args = queue[ i ]
                if args[ 1 ] then
                    self:attach( args[ 3 ], args[ 2 ] )
                else
                    self:detach( args[ 2 ] )
                end
            end
        end

        local name = names[ self ]
        if name ~= nil and timer_RepsLeft( name ) == 0 then
            self:stop()
        end
    end

end

do

    local crypto_UUIDv7 = std.crypto.UUIDv7

    ---@protected
    function Timer:__init( delay, repetition_count, name )
        names[ self ] = name or crypto_UUIDv7()
        states[ self ] = 0

        delays[ self ] = delay or 0
        repetitions_total[ self ] = repetition_count or 1
    end

end

--- [SHARED AND MENU]
---
--- Attaches a callback to the timer.
---
---@param fn fun( timer: gpm.std.Timer ) The callback function.
---@param name string? The name of the callback, default is `unnamed`.
function Timer:attach( fn, name )
    if name == nil then
        name = "unnamed"
    end

    if in_call[ self ] then
        local queue = queues[ self ]
        if queue == nil then
            queues[ self ] = {
                { true, name, fn }
            }
        else
            queue[ #queue + 1 ] = { true, name, fn }
        end

        return
    end

    local lst = callbacks[ self ]
    local lst_length = #lst

    for i = 1, lst_length, 2 do
        if lst[ i ] == name then
            lst[ i + 1 ] = fn
            return
        end
    end

    local index = lst_length + 1
    lst[ index ] = name

    index = index + 1
    lst[ index ] = fn
end

do

    local debug_fempty = std.debug.fempty
    local table_eject = std.table.eject

    --- [SHARED AND MENU]
    ---
    --- Detaches a callback from the timer.
    ---
    ---@param name string The name of the callback to detach.
    function Timer:detach( name )
        if name == nil then
            name = "unnamed"
        end

        local lst = callbacks[ self ]

        for i = 1, #lst, 2 do
            if lst[ i ] == name then
                if in_call[ self ] then
                    lst[ i + 1 ] = debug_fempty

                    local queue = queues[ self ]
                    if queue == nil then
                        queues[ self ] = {
                            { false, name }
                        }
                    else
                        queue[ #queue + 1 ] = { false, name }
                    end
                else
                    table_eject( lst, i, i + 1 )
                end

                break
            end
        end
    end

end

--- [SHARED AND MENU]
---
--- Detaches all timer callbacks.
---
function Timer:clear()
    callbacks[ self ] = nil
    in_call[ self ] = nil
end

do

    local timer_Start = timer.Start

    --- [SHARED AND MENU]
    ---
    --- Restarts the timer.
    ---
    function Timer:start()
        local repetitions = self.repetitions_total

        local name = names[ self ]
        if name ~= nil then
            if timer_Exists( name ) then
                timer_Adjust( name, self.delay, repetitions )
                timer_Start( name )
            else
                timer_Create( name, self.delay, repetitions, function()
                    return timer_call( self )
                end )
            end
        end

        if repetitions > 0 then
            running_timers[ self ] = true
        else
            running_timers[ self ] = nil
        end

        states[ self ] = 2
    end

end

do

    local timer_Stop = timer.Stop

    --- [SHARED AND MENU]
    ---
    --- Stops the timer.
    ---
    function Timer:stop()
        repetition_indexes[ self ] = nil
        running_timers[ self ] = nil
        start_times[ self ] = nil

        local name = names[ self ]
        if name ~= nil then
            if self.state == 1 then
                timer_UnPause( name )
            end

            timer_Stop( name )
        end

        states[ self ] = 0
    end

end

---@type table<gpm.std.Timer, number>
local pause_times = {}

gc_setTableRules( pause_times, true, false )

do

    local timer_Pause = timer.Pause

    --- [SHARED AND MENU]
    ---
    --- Pauses the timer.
    ---
    function Timer:pause()
        if self.state ~= 2 then
            return
        end

        local name = names[ self ]
        if name == nil then
            return
        end

        pause_times[ self ] = game_getUptime()
        timer_Pause( name )
        states[ self ] = 1
    end

end

--- [SHARED AND MENU]
---
--- Resumes/unpauses the timer.
---
function Timer:resume()
    if self.state ~= 1 then
        return
    end

    local name = names[ self ]
    if name == nil then
        return
    end

    timer_UnPause( name )
    states[ self ] = 2
end

do

    local timer_Simple = timer.Simple

    --- [SHARED AND MENU]
    ---
    --- Creates a timer with a single callback.
    ---
    ---@param fn function The callback function.
    ---@param delay? number The delay in seconds, default is `0`.
    function TimerClass.simple( fn, delay )
        timer_Simple( delay or 0, fn )
    end

end
