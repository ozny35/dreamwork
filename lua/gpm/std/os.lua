local os, system, jit, bit, math_fdiv = ...
local os_time, os_date = os.time, os.date
local bit_band, bit_bor, bit_lshift, bit_rshift = bit.band, bit.bit_bor, bit.bit_lshift, bit.rshift

return {
    ["arch"] = jit.arch,
    ["name"] = jit.os,
    ["clock"] = os.clock,
    ["date"] = os.date,
    ["difftime"] = os.difftime,
    ["time"] = os_time,
    ["dos2unix"] = function( time, date )
        local data = { ["year"] = 1980, ["month"] = 1, ["day"] = 1, ["hour"] = 0, ["min"] = 0, ["sec"] = 0 }

        if time then
            data.hour = bit_rshift( bit_band( time, 0xF800 ), 11 )
            data.min = bit_rshift( bit_band( time, 0x07E0 ), 5 )
            data.sec = bit_band( time, 0x001F ) * 2
        end

        if date then
            data.year = 1980 + bit_rshift( bit_band( date, 0xFE00 ), 9 )
            data.month = bit_rshift( bit_band( date, 0x01E0 ), 5 )
            data.day = bit_band( date, 0x001F )
        end

        return os_time( data )
    end,
    ["unix2dos"] = function( seconds )
        local data = os_date( "*t", seconds )
        return bit_bor( bit_lshift( data.hour, 11 ), bit_lshift( data.min, 5 ), math_fdiv( data.sec, 2 ) ), bit_bor( bit_lshift( data.year - 1980, 9 ), bit_lshift( data.month, 5 ), data.day )
    end,
    ["flashWindow"] = system.FlashWindow,
    ["battery"] = system.BatteryPower,
    ["steamTime"] = system.SteamTime,
    ["country"] = system.GetCountry,
    ["hasFocus"] = system.HasFocus,
    ["appTime"] = system.AppTime,
    ["uptime"] = system.UpTime
}
