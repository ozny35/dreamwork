local std = _G.gpm.std

local tonumber = std.tonumber

---@class gpm.std.math
local math = std.math
local math_max = math.max

---@class gpm.std.string
local string = std.string
local string_byte, string_sub, string_find, string_rep, string_len, string_match = string.byte, string.sub, string.find, string.rep, string.len, string.match

---@class gpm.std.table
local table = std.table
local table_concat = table.concat


--- Converts a binary string to a decimal number.
---@param str string The binary string.
---@return number
local function bin2dec( str )
    return tonumber( str, 2 )
end

string.bin2dec = bin2dec

local dec2bin
do

    local math_ceil, math_floor, math_log, math_ln2 = math.ceil, math.floor, math.log, math.ln2

    --- Converts a decimal number to a binary string.
    ---@param number number The decimal number.
    ---@param complement? boolean Whether to complement the binary string.
    ---@return string The binary string.
    ---@return number The length of the binary string.
    function dec2bin( number, complement )
        if number == 0 then
            if complement then
                return "00000000", 8
            else
                return "0", 1
            end
        end

        local bits, length
        if number < 0 then
            number = -number
            bits, length = { "-" }, 1
        else
            bits, length = {}, 0
        end

        while number > 0 do
            length = length + 1
            bits[ length ] = number % 2 == 0 and "0" or "1"
            number = math_floor( number / 2 )
        end

        length = length + 1

        for index = 1, math_floor( length / 2 ), 1 do
            bits[ index ], bits[ length - index ] = bits[ length - index ], bits[ index ]
        end

        length = length - 1

        if complement then
            local zeros = math_max( 8, 2 ^ math_ceil( math_log( length ) / math_ln2 ) ) - length
            return string_rep( "0", zeros ) .. table_concat( bits, "", 1, length ), length + zeros
        else
            return table_concat( bits, "", 1, length ), length
        end
    end

end

string.dec2bin = dec2bin

--- Converts a hex string to a decimal number.
---@param str string The hex string.
---@return number
local function hex2dec( str )
    return tonumber( str, 16 )
end

string.hex2dec = hex2dec

local dec2hex
do

    local string_format = string.format

    --- Converts a decimal number to a hex string.
    ---@param number number The decimal number.
    ---@return string
    function dec2hex( number )
        return string_format( "%X", number)
    end

    string.dec2hex = dec2hex

end

--- Converts a hex string to a binary string.
---@param str string The hex string.
---@param complement? boolean
---@return string, number
function string.hex2bin( str, complement )
    return dec2bin( hex2dec( str ), complement )
end

--- Converts a binary string to a hex string.
---@param str string The binary string.
---@return string
function string.bin2hex( str )
    return dec2hex( bin2dec( str ) )
end

do

    local unsafe_pattern_bytes = {
        -- ()
        [ 0x28 ] = "%(",
        [ 0x29 ] = "%)",

        -- []
        [ 0x5B ] = "%[",
        [ 0x5D ] = "%]",

        -- .
        [ 0x2E ] = "%.",

        -- %
        [ 0x25 ] = "%%",

        -- +-
        [ 0x2B ] = "%+",
        [ 0x2D ] = "%-",

        -- *
        [ 0x2A ] = "%*",

        -- ?
        [ 0x3F ] = "%?",

        -- ^
        [ 0x5E ] = "%^",

        -- $
        [ 0x24 ] = "%$"
    }

    --- Returns a pattern-safe string.
    ---@param str string The string.
    ---@return string
    function string.makePatternSafe( str )
        local startPos, strLength = 1, string_len( str )
        local result, length = {}, 0

        for index = 1, strLength do
            local byte = string_byte( str, index )
            if byte == 0 then
                length = length + 1
                result[ length ] = string_sub( str, startPos, index - 1 ) .. "%z"
                startPos = index + 1
            else
                local pattern = unsafe_pattern_bytes[ byte ]
                if pattern then
                    length = length + 1

                    if startPos == index then
                        result[ length ] = pattern
                    else
                        result[ length ] = string_sub( str, startPos, index - 1 ) .. pattern
                    end

                    startPos = index + 1
                end
            end
        end

        length = length + 1
        result[ length ] = string_sub( str, startPos, strLength )

        if length == 0 then
            return str
        elseif length == 1 then
            return result[ 1 ]
        end

        return table_concat( result, "", 1, length )
    end

    --- Removes leading and trailing matches of a string.
    ---@param str string The string.
    ---@param pattern? string The pattern to match, `%s` for whitespace.
    ---@param direction? number The direction to trim. `1` for left, `-1` for right, `0` for both.
    ---@return string str The trimmed string.
    function string.trim( str, pattern, direction )
        if pattern == nil then
            pattern = "%s"
        else
            if pattern == "" then
                pattern = "%s"
            else
                local length = string_len( pattern )
                if length == 1 then
                    pattern = unsafe_pattern_bytes[ string_byte( pattern, 1 ) ] or pattern
                elseif length ~= 2 or string_byte( pattern, 1 ) ~= 0x25 then
                    pattern = "[" .. pattern .. "]"
                end
            end
        end

        if direction == 1 then -- left
            return string_match( str, "^(.-)" .. pattern .. "*$" ) or str
        elseif direction == -1 then -- right
            return string_match( str, "^" .. pattern .. "*(.+)$" ) or str
        else -- both
            return string_match( str, "^" .. pattern .. "*(.-)" .. pattern .. "*$" ) or str
        end
    end

end

--- Checks if a string is a URL.
---@param str string The string.
---@return boolean
function string.isURL( str )
    return string_match( str, "^%l[%l+-.]+%:[^%z\x01-\x20\x7F-\xFF\"<>^`:{-}]*$" ) ~= nil
end

--- Checks if a string is a SteamID.
---@param str string The string.
---@return boolean
function string.isSteamID( str )
    return string_match( str, "^STEAM_[0-5]:[01]:%d+$" ) ~= nil
end

local isDomain
do

    local string_byteSplit = string.byteSplit

    --- Checks if a string is a domain.
    ---@param str string The string.
    ---@return boolean isDomain Whether the string is a domain.
    ---@return string? error The error message.
    function isDomain( str )
        if str == "" then
            return false, "empty string"
        end

        local length = string_len( str )
        if length > 253 then
            return false, "domain is too long"
        end

        if string_byte( str, 1 ) == 0x2E --[[ . ]] then
            return false, "first character in domain cannot be a dot"
        end

        if string_byte( str, length ) == 0x2E --[[ . ]] then
            return false, "last character in domain cannot be a dot"
        end

        if string_match( str, "^[%l][%l%d.]*%.[%l]+$") then
            local labels = string_byteSplit( str, 0x2E --[[ . ]] )
            for index = 1, #labels do
                local label = labels[ index ]
                if label == "" then
                    return false, "empty label in domain"
                elseif string_len( label ) > 63 then
                    return false, "label '" .. label .. "' in domain is too long"
                end
            end

            return true
        end

        return false, "invalid domain"
    end

end

--- Checks if a string is an email.
---@param str string The string.
---@return boolean isEmail Whether the string is an email.
---@return string? error The error message.
function string.isEmail( str )
    if str == "" then
        return false, "empty string"
    end

    local last_at = string_find( str, "[^%@]+$" )
    if last_at == nil then
        return false, "@ symbol is missing"
    end

    if last_at >= 65 then
        return false, "username is too long"
    end

    local username = string_sub( str, 1, last_at - 2 )
    if username == nil or username == "" then
        return false, "username is missing"
    end

    if string_find( username, "[%c]" ) then
        return false, "invalid characters in username"
    end

    if string_find( username, "%p%p" ) then
        return false, "too many periods in username"
    end

    if string_byte( username, 1 ) == 0x22 --[[ " ]] and string_byte( username, string_len( username ) ) ~= 0x22 --[[ " ]] then
        return false, "invalid usage of quotes"
    end

    return isDomain( string_sub( str, last_at, string_len( str ) ) )
end
