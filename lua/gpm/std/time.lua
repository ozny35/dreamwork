local _G = _G
---@class gpm.std
local std = _G.gpm.std

local os = _G.os
local os_time = os.time
local os_date = os.date
local os_clock = os.clock

-- TODO: add utc argument for funcs that use os_date
-- TODO: https://github.com/Nak2/NikNaks/blob/main/lua/niknaks/modules/sh_datetime.lua

local math = std.math
local math_min = math.min
local math_floor = math.floor

local string = std.string
local string_byte, string_char = string.byte, string.char
local string_format = string.format
local string_sub = string.sub
local string_len = string.len

local table_concat = std.table.concat
local raw_tonumber = std.raw.tonumber

--- [SHARED AND MENU]
---
--- A library for working with time and date.
---
---@class gpm.std.time
local time = std.time or {}
std.time = time

---@alias gpm.std.time.Unit
---| "ns" Nanoseconds
---| "us" Microseconds
---| "ms" Milliseconds
---| "s" Seconds
---| "m" Minutes
---| "h" Hours
---| "d" Days
---| "w" Weeks
---| "mo" Months
---| "y" Years

---@alias gpm.std.time.Duration
---| "1ms 1us 1ns" One millisecond, one microsecond and one nanosecond.
---| "1h 1m 1s" One hour, one minute and one second.
---| "1y 1w 1d" One year, one week and one day.
---| "1w 1d" One week and one day.
---| "1y" One year.
---| string

do

    local time_now = _G.SysTime or os_clock

    --- [SHARED AND MENU]
    ---
    --- Returns the current time in the specified unit.
    ---
    ---@param unit? gpm.std.time.Unit The unit to return the current time in, seconds by default.
    ---@return integer timestamp The current timestamp in the specified unit.
    function time.now( unit )
        local timestamp = os_time()

        if unit == nil then
            unit = "s"
        end

        if unit == "s" then
            return timestamp
        elseif unit == "m" then
            return math_floor( timestamp / 60 )
        elseif unit == "h" then
            return math_floor( timestamp / 3600 )
        elseif unit == "d" then
            return math_floor( timestamp / 86400 )
        elseif unit == "w" then
            return math_floor( timestamp / 604800 )
        elseif unit == "mo" then
            return math_floor( timestamp / 2592000 )
        elseif unit == "y" then
            return math_floor( timestamp / 31536000 )
        end

        timestamp = ( timestamp + time_now() % 1 ) * 1000

        if unit == "ms" then
            return math_floor( timestamp )
        elseif unit == "us" then
            return math_floor( timestamp * 1000 )
        elseif unit == "ns" then
            return math_floor( timestamp * 1000000 )
        end

        error( "unknown unit '" .. unit .. "'", 2 )
    end

end

do

    local string_gmatch = string.gmatch

    --- [SHARED AND MENU]
    ---
    --- Converts a duration string to seconds, milliseconds, microseconds and nanoseconds.
    ---
    ---@param duration_str gpm.std.time.Duration
    ---@param error_level? integer
    ---@return number seconds
    ---@return number milliseconds
    ---@return number microseconds
    ---@return number nanoseconds
    local function duration( duration_str, error_level )
        local seconds, milliseconds, microseconds, nanoseconds = 0, 0, 0, 0

        for number_str, unit_str in string_gmatch( duration_str, "(%-?%d+%.?%d*)(%l*)" ) do
            local integer = raw_tonumber( number_str, 10 )

            if unit_str == "y" then
                seconds = seconds + ( integer * 31536000 )
            elseif unit_str == "mo" then
                seconds = seconds + ( integer * 2592000 )
            elseif unit_str == "w" then
                seconds = seconds + ( integer * 604800 )
            elseif unit_str == "d" then
                seconds = seconds + ( integer * 86400 )
            elseif unit_str == "h" then
                seconds = seconds + ( integer * 3600 )
            elseif unit_str == "m" then
                seconds = seconds + ( integer * 60 )
            elseif unit_str == "s" then
                seconds = seconds + integer
            elseif unit_str == "ms" then
                milliseconds = milliseconds + integer
            elseif unit_str == "us" then
                microseconds = microseconds + integer
            elseif unit_str == "ns" then
                nanoseconds = nanoseconds + integer
            else
                error( "unknown unit '" .. unit_str .. "' in '" .. duration_str .. "'", ( error_level or 1 ) + 1 )
            end
        end

        return seconds, milliseconds, microseconds, nanoseconds
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a duration string to the specified unit.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds   |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds       |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds           |
    --- | `s`      | Second       | 1 second                    |
    --- | `m`      | Minute       | 60 seconds                  |
    --- | `h`      | Hour         | 60 minutes                  |
    --- | `d`      | Day          | 24 hours                    |
    --- | `w`      | Week         | 7 days                      |
    --- | `mo`     | Month        | ~30 days                    |
    --- | `y`      | Year         | 365 days                    |
    ---
    ---@param duration_str gpm.std.time.Duration
    ---@param unit? gpm.std.time.Unit
    ---@return integer
    function time.duration( duration_str, unit )
        local seconds, milliseconds, microseconds, nanoseconds = duration( duration_str, 2 )

        if unit == "ms" then
            return math_floor( seconds * 1e3 + milliseconds + microseconds * 1e-3 + nanoseconds * 1e-6 )
        elseif unit == "us" then
            return math_floor( seconds * 1e6 + milliseconds * 1e3 + microseconds + nanoseconds * 1e-3 )
        elseif unit == "ns" then
            return math_floor( seconds * 1e9 + milliseconds * 1e6 + microseconds * 1e3 + nanoseconds )
        end

        seconds = seconds + nanoseconds * 1e-9 + microseconds * 1e-6 + milliseconds * 1e-3

        if unit == "s" or unit == nil then
            return math_floor( seconds )
        elseif unit == "m" then
            return math_floor( seconds / 60 )
        elseif unit == "h" then
            return math_floor( seconds / 3600 )
        elseif unit == "d" then
            return math_floor( seconds / 86400 )
        elseif unit == "w" then
            return math_floor( seconds / 604800 )
        elseif unit == "mo" then
            return math_floor( seconds / 2592000 )
        elseif unit == "y" then
            return math_floor( seconds / 31536000 )
        end

        error( "unknown unit '" .. unit .. "'", 2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Adds a duration to a timestamp.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds   |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds       |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds           |
    --- | `s`      | Second       | 1 second                    |
    --- | `m`      | Minute       | 60 seconds                  |
    --- | `h`      | Hour         | 60 minutes                  |
    --- | `d`      | Day          | 24 hours                    |
    --- | `w`      | Week         | 7 days                      |
    --- | `mo`     | Month        | ~30 days                    |
    --- | `y`      | Year         | 365 days                    |
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@param duration_str gpm.std.time.Duration
    ---@return integer
    function time.add( timestamp, unit, duration_str )
        local seconds, milliseconds, microseconds, nanoseconds = duration( duration_str, 2 )

        if unit == "ns" then
            return math_floor( timestamp + ( seconds * 1e9 + milliseconds * 1e6 + microseconds * 1e3 + nanoseconds ) )
        elseif unit == "us" then
            return math_floor( timestamp + ( seconds * 1e6 + milliseconds * 1e3 + microseconds + nanoseconds * 1e-3 ) )
        elseif unit == "ms" then
            return math_floor( timestamp + ( seconds * 1e3 + milliseconds + microseconds * 1e-3 + nanoseconds * 1e-6 ) )
        end

        timestamp = timestamp + ( seconds + milliseconds * 1e-3 + microseconds * 1e-6 + nanoseconds * 1e-9 )

        if unit == "m" then
            seconds = seconds / 60
        elseif unit == "h" then
            seconds = seconds / 3600
        elseif unit == "d" then
            seconds = seconds / 86400
        elseif unit == "w" then
            seconds = seconds / 604800
        elseif unit == "mo" then
            seconds = seconds / 2592000
        elseif unit == "y" then
            seconds = seconds / 31536000
        elseif not ( unit == "s" or unit == nil ) then
            error( "unknown unit '" .. unit .. "'", 2 )
        end

        return math_floor( timestamp )
    end

    --- [SHARED AND MENU]
    ---
    --- Subtracts a duration from a timestamp.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds   |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds       |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds           |
    --- | `s`      | Second       | 1 second                    |
    --- | `m`      | Minute       | 60 seconds                  |
    --- | `h`      | Hour         | 60 minutes                  |
    --- | `d`      | Day          | 24 hours                    |
    --- | `w`      | Week         | 7 days                      |
    --- | `mo`     | Month        | ~30 days                    |
    --- | `y`      | Year         | 365 days                    |
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@param duration_str gpm.std.time.Duration
    ---@return integer
    function time.sub( timestamp, unit, duration_str )
        local seconds, milliseconds, microseconds, nanoseconds = duration( duration_str, 2 )

        if unit == "ns" then
            return timestamp - math_floor( seconds * 1e9 + milliseconds * 1e6 + microseconds * 1e3 + nanoseconds )
        elseif unit == "us" then
            return timestamp - math_floor( seconds * 1e6 + milliseconds * 1e3 + microseconds + nanoseconds * 1e-3 )
        elseif unit == "ms" then
            return timestamp - math_floor( seconds * 1e3 + milliseconds + microseconds * 1e-3 + nanoseconds * 1e-6 )
        end

        seconds = seconds + ( milliseconds * 1e-3 + microseconds * 1e-6 + nanoseconds * 1e-9 )

        if unit == "m" then
            seconds = seconds / 60
        elseif unit == "h" then
            seconds = seconds / 3600
        elseif unit == "d" then
            seconds = seconds / 86400
        elseif unit == "w" then
            seconds = seconds / 604800
        elseif unit == "mo" then
            seconds = seconds / 2592000
        elseif unit == "y" then
            seconds = seconds / 31536000
        elseif not ( unit == "s" or unit == nil ) then
            error( "unknown unit '" .. unit .. "'", 2 )
        end

        return timestamp - math_floor( seconds )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Transforms a timestamp from one unit to another.
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@param target? gpm.std.time.Unit
    ---@return integer
    local function transform( timestamp, unit, target, error_level )
        if error_level == nil then
            error_level = 2
        else
            error_level = error_level + 1
        end

        if unit == "ns" then
            timestamp = timestamp / 1e9
        elseif unit == "us" then
            timestamp = timestamp / 1e6
        elseif unit == "ms" then
            timestamp = timestamp / 1e3
        elseif unit == "m" then
            timestamp = timestamp * 60
        elseif unit == "h" then
            timestamp = timestamp * 3600
        elseif unit == "d" then
            timestamp = timestamp * 86400
        elseif unit == "w" then
            timestamp = timestamp * 604800
        elseif unit == "mo" then
            timestamp = timestamp * 2592000
        elseif unit == "y" then
            timestamp = timestamp * 31536000
        elseif not ( unit == "s" or unit == nil ) then
            error( "unknown unit '" .. unit .. "'", error_level )
        end

        if target == "s" or target == nil then
            return math_floor( timestamp )
        elseif target == "ns" then
            return math_floor( timestamp * 1e9 )
        elseif target == "us" then
            return math_floor( timestamp * 1e6 )
        elseif target == "ms" then
            return math_floor( timestamp * 1e3 )
        elseif target == "m" then
            return math_floor( timestamp / 60 )
        elseif target == "h" then
            return math_floor( timestamp / 3600 )
        elseif target == "d" then
            return math_floor( timestamp / 86400 )
        elseif target == "w" then
            return math_floor( timestamp / 604800 )
        elseif target == "mo" then
            return math_floor( timestamp / 2592000 )
        elseif target == "y" then
            return math_floor( timestamp / 31536000 )
        else
            error( "unknown target unit '" .. target .. "'", error_level )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Transforms a timestamp to a different unit.
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@param target? gpm.std.time.Unit
    ---@return integer
    function time.transform( timestamp, unit, target )
        return transform( timestamp, unit, target, 2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the time elapsed since lua was started.
    ---
    ---@param unit? gpm.std.time.Unit
    ---@return integer timestamp
    function time.elapsed( unit )
        return transform( math_floor( os_clock() * 1e3 ), "ms", unit, 2 )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Splits a timestamp into seconds, milliseconds, microseconds and nanoseconds.
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@return integer seconds
    ---@return integer milliseconds
    ---@return integer microseconds
    ---@return integer nanoseconds
    local function split( timestamp, unit, error_level )
        local milliseconds, microseconds, nanoseconds = 0, 0, 0
        local seconds

        if unit == "s" or unit == nil then
            seconds = math_floor( timestamp )
        elseif unit == "ns" then
            seconds = math_floor( timestamp / 1e9 )
            milliseconds = math_floor( ( timestamp - ( seconds * 1e9 ) ) / 1e6 )
            microseconds = math_floor( ( timestamp - ( ( seconds * 1e9 ) + ( milliseconds * 1e6 ) ) ) / 1e3 )
            nanoseconds = math_floor( timestamp - ( ( seconds * 1e9 ) + ( milliseconds * 1e6 ) + ( microseconds * 1e3 ) ) )
        elseif unit == "us" then
            seconds = math_floor( timestamp / 1e6 )
            milliseconds = math_floor( ( timestamp - ( seconds * 1e6 ) ) / 1e3 )
            microseconds = math_floor( timestamp - ( ( seconds * 1e6 ) + ( milliseconds * 1e3 ) ) )
        elseif unit == "ms" then
            seconds = math_floor( timestamp / 1e3 )
            milliseconds = math_floor( timestamp - ( seconds * 1e3 ) )
        elseif unit == "m" then
            seconds = math_floor( timestamp * 60 )
        elseif unit == "h" then
            seconds = math_floor( timestamp * 3600 )
        elseif unit == "d" then
            seconds = math_floor( timestamp * 86400 - 14400 )
        elseif unit == "w" then
            seconds = math_floor( timestamp * 604800 + 331200 )
        elseif unit == "mo" then
            seconds = math_floor( timestamp * 3888000 )
        elseif unit == "y" then
            seconds = math_floor( timestamp * 31536000 + 2592000 )
        else
            error( "unknown unit '" .. unit .. "'", ( error_level or 1 ) + 1 )
        end

        return seconds, milliseconds, microseconds, nanoseconds
    end

    --- [SHARED AND MENU]
    ---
    --- Represents a date and time.
    ---
    ---@class gpm.std.time.Date
    ---@field summer_time boolean Is the date in summer time?
    ---@field week_day integer The day of the week.
    ---@field milliseconds integer The number of milliseconds.
    ---@field microseconds integer The number of microseconds.
    ---@field nanoseconds integer The number of nanoseconds.
    ---@field hours12 integer The number of hours in 12-hour format.
    ---@field hours integer The number of hours.
    ---@field minutes integer The number of minutes.
    ---@field seconds integer The number of seconds.
    ---@field period "AM" | "PM" The period of the day.
    ---@field day integer The day of the month.
    ---@field month integer The month of the year.
    ---@field year integer The year.
    ---@field year_day integer The day of the year.
    ---@field year_week integer The week number of the year.
    ---@field timezone integer The timezone offset.

    --- [SHARED AND MENU]
    ---
    --- Converts a timestamp to a duration.
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@return gpm.std.time.Date
    function time.parse( timestamp, unit )
        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp, unit, 2 )

        local tbl = os_date( "*t", seconds )
        ---@cast tbl table

        tbl.summer_time = tbl.isdst
        tbl.isdst = nil

        tbl.week_day = ( tbl.wday + 5 ) % 7 + 1
        tbl.wday = nil

        tbl.year_day = tbl.yday
        tbl.yday = nil

        tbl.milliseconds = milliseconds or 0
        tbl.microseconds = microseconds or 0
        tbl.nanoseconds = nanoseconds or 0

        tbl.hours = tbl.hour
        tbl.hour = nil

        tbl.minutes = tbl.min
        tbl.min = nil

        tbl.seconds = tbl.sec
        tbl.sec = nil

        ---@diagnostic disable-next-line: param-type-mismatch
        local values = string.byteSplit( os_date( "%I;%p;%W;%z", seconds ), 0x3B )

        tbl.hours12 = tonumber( values[ 1 ], 10 ) or 0
        tbl.period = values[ 2 ] or "AM"

        tbl.year_week = ( tonumber( values[ 3 ], 10 ) or 0 ) + 1

        local timezone = tonumber( values[ 4 ], 10 ) or 0

        if timezone ~= 0 then
            timezone = timezone * 0.01
        end

        tbl.timezone = timezone

        return tbl
    end

    local duration_units = {
        { 31536000, "y" },
        { 2592000, "mo" },
        { 604800, "w" },
        { 86400, "d" },
        { 3600, "h" },
        { 60, "m" }
    }

    --- [SHARED AND MENU]
    ---
    --- Converts a number of seconds to a duration string.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds     |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds         |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds             |
    --- | `s`      | Second       | 1 second                      |
    --- | `m`      | Minute       | 60 seconds                    |
    --- | `h`      | Hour         | 60 minutes                    |
    --- | `d`      | Day          | 24 hours                      |
    --- | `w`      | Week         | 7 days                        |
    --- | `mo`     | Month        | ~30 days                      |
    --- | `y`      | Year         | 365 days                      |
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@return string
    function time.string( timestamp, unit )
        local segments, segment_count = {}, 0

        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp, unit, 2 )

        if seconds ~= 0 then

            for i = 1, 6, 1 do
                local lst = duration_units[ i ]

                local value = lst[ 1 ]
                if seconds >= value then
                    local count = math_floor( seconds / value )
                    seconds = seconds - ( count * value )

                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%d%s", count, lst[ 2 ] )
                end

                if seconds <= 0 then
                    break
                end
            end

        end

        if seconds ~= 0 then
            local second_count = math_floor( seconds )
            if second_count > 0 then
                seconds = seconds - second_count

                segment_count = segment_count + 1
                segments[ segment_count ] = string_format( "%ds", second_count )
            end
        end

        if milliseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%03dms", milliseconds )
        end

        if microseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%03dus", microseconds )
        end

        if nanoseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%03dns", nanoseconds )
        end

        return table_concat( segments, " ", 1, segment_count )
    end

    ---@type table<string, string>
    local keys = {
        -- %d	Day of the month [01-31]	16
        day = "%d",
        -- %j	Day of the year [001-365]	259
        day_of_year = "%j",

        -- %m	Month [01-12]	09
        month = "%m",
        -- %B	Full month name	September
        month_name = "%B",
        -- %b	Abbreviated month name	Sep
        month_short_name = "%b",

        -- %Y	Full year	1998
        year = "%Y",
        -- %y	Two-digit year [00-99]	98
        year_short = "%y",

        -- %H	Hour, using a 24-hour clock [00-23]	23
        hours = "%H",
        -- %M	Minute [00-59]	48
        minutes = "%M",
        -- %S	Second [00-60]	10
        seconds = "%S",

        -- %I	Hour, using a 12-hour clock [01-12]	11
        hours12 = "%I",
        -- %p	Either am or pm	pm
        period = "%p",

        -- %w	Weekday [0-6 = Sunday-Saturday]	3
        week_day = "%w",
        -- %A	Full weekday name	Wednesday
        week_day_name = "%A",
        -- %a	Abbreviated weekday name	Wed
        week_day_short_name = "%a",

        -- %W	Week of the year [00-53]	37
        year_week = "%W",

        -- %z	Timezone	-0300
        timezone = "%z",

        -- %X	Time (Same as %H:%M:%S)	23:48:10
        time = "%X",
        -- %x	Date (Same as %m/%d/%y)	09/16/98
        date = "%x",

        -- %c	Locale-appropriate date and time	Varies by platform and language settings
        date_time = "%c"
    }

    --- [SHARED AND MENU]
    ---
    --- Converts a timestamp to a formatted string.
    ---
    --- ### Format Keys
    --- | Key                     | Description                                            | Example                    |
    --- |-------------------------|--------------------------------------------------------|----------------------------|
    --- | `{week_day}`            | Weekday number [0–6, Sunday = 0]                       | `3`                        |
    --- | `{week_day_name}`       | Full weekday name                                      | `Wednesday`                |
    --- | `{week_day_short_name}` | Abbreviated weekday name                               | `Wed`                      |
    --- | `{day}`                 | Day of the month [01–31]                               | `16`                       |
    --- | `{day_of_year}`         | Day of the year [001–365]                              | `259`                      |
    --- | `{month}`               | Month number [01–12]                                   | `09`                       |
    --- | `{month_name}`          | Full month name                                        | `September`                |
    --- | `{month_short_name}`    | Abbreviated month name                                 | `Sep`                      |
    --- | `{year}`                | Full year                                              | `1998`                     |
    --- | `{year_week}`           | Week number of the year [00–53]                        | `37`                       |
    --- | `{year_short}`          | Two-digit year [00–99]                                 | `98`                       |
    --- | `{hours}`               | Hour in 24-hour format [00–23]                         | `23`                       |
    --- | `{minutes}`             | Minute [00–59]                                         | `48`                       |
    --- | `{seconds}`             | Second [00–60] (leap second included)                  | `10`                       |
    --- | `{hours12}`             | Hour in 12-hour format [01–12]                         | `11`                       |
    --- | `{period}`              | AM or PM                                               | `pm`                       |
    --- | `{date}`                | Localized date (same as `{month}/{day}/{year}`)        | `09/16/98`                 |
    --- | `{time}`                | Localized time (same as `{hours}:{minutes}:{seconds}`) | `23:48:10`                 |
    --- | `{date_time}`           | Localized full date and time                           | `Wed Sep 16 23:48:10 1998` |
    --- | `{timezone}`            | Timezone offset                                        | `-0300`                    |
    ---
    ---@param fmt string
    ---@param timestamp? integer
    ---@param unit? gpm.std.time.Unit
    ---@return string
    function time.format( fmt, timestamp, unit )
        if timestamp == nil then
            timestamp = time.now( unit )
        end

        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp, unit, 2 )

        ---@type string[]
        local segments = {}

        ---@type integer
        local segment_count = 0

        ---@type integer
        local fmt_length = string_len( fmt ) + 1

        ---@type integer
        local position = 1

        while position ~= fmt_length do
            local uint8 = string_byte( fmt, position, position )
            if uint8 == nil then
                break
            elseif uint8 == 0x25 --[[ "%" ]] then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( fmt, position, position + 1 )
                position = math_min( position + 2, fmt_length )
            elseif uint8 == 0x7B --[[ "{" ]] then

                ---@type integer?
                local bracket_position

                for i = position + 1, fmt_length, 1 do
                    if string_byte( fmt, i, i ) == 0x7D --[[ "}" ]] then
                        bracket_position = i
                        break
                    end
                end

                if bracket_position == nil then
                    error( string_format( "missing '}' at position %d", position ), 2 )
                end

                ---@type string
                local key = string_sub( fmt, position + 1, bracket_position - 1 )

                if key == "nanoseconds" then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%03d", nanoseconds )
                elseif key == "microseconds" then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%03d", microseconds )
                elseif key == "milliseconds" then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%03d", milliseconds )
                else

                    local pattern_str = keys[ key ]
                    if pattern_str == nil then
                        error( string_format( "unknown value name - '%s'", key ), 2 )
                    end

                    segment_count = segment_count + 1
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    segments[ segment_count ] = os_date( pattern_str, seconds )

                end

                position = math_min( bracket_position + 1, fmt_length )
            else

                ---@type integer?
                local bracket_position

                for i = position + 1, fmt_length, 1 do
                    if string_byte( fmt, i, i ) == 0x7B --[[ "{" ]] then
                        bracket_position = i
                        break
                    end
                end

                if bracket_position == nil then
                    bracket_position = fmt_length
                end

                bracket_position = bracket_position - 1

                if position == bracket_position then
                    position = position + 1
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_char( uint8 )
                else
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( fmt, position, bracket_position )
                    position = math_min( bracket_position + 2, fmt_length )
                end
            end
        end

        return table_concat( segments, "", 1, segment_count )
    end

end
