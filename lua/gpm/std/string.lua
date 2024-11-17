local _G = _G
local std, glua_string = _G.gpm.std, _G.string
local table_concat, tostring, tonumber = std.table.concat, std.tostring, std.tonumber

local math_ceil, math_max, math_floor, math_log, math_ln2
do
    local math = std.math
    math_ceil, math_max, math_floor, math_log, math_ln2 = math.ceil, math.max, math.floor, math.log, math.ln2
end

local is_number, is_bool
do
    local is = std.is
    is_number, is_bool = is.number, is.bool
end

local string_byte, string_sub, string_len, string_find, string_match, string_gsub, string_rep, string_format = glua_string.byte, glua_string.sub, glua_string.len, glua_string.find, glua_string.match, glua_string.gsub, glua_string.rep, glua_string.format

local patternUnSafeBytes = {
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

local asciiNumbers = {
    [ 0x30 ] = true, -- 0
    [ 0x31 ] = true, -- 1
    [ 0x32 ] = true, -- 2
    [ 0x33 ] = true, -- 3
    [ 0x34 ] = true, -- 4
    [ 0x35 ] = true, -- 5
    [ 0x36 ] = true, -- 6
    [ 0x37 ] = true, -- 7
    [ 0x38 ] = true, -- 8
    [ 0x39 ] = true -- 9
}

---Removes leading and trailing matches of a string.
---@param str string The string.
---@param pattern? string The pattern to match, `%s` for whitespace.
---@param dir? number The direction to trim. `1` for left, `-1` for right, `0` for both.
---@return string str The trimmed string.
local function trim( str, pattern, dir )
    if pattern == nil then
        pattern = "%s"
    else
        if pattern == "" then
            pattern = "%s"
        else
            local length = string_len( pattern )
            if length == 1 then
                pattern = patternUnSafeBytes[ string_byte( pattern, 1 ) ] or pattern
            elseif length ~= 2 or string_byte( pattern, 1 ) ~= 0x25 then
                pattern = "[" .. pattern .. "]"
            end
        end
    end

    if dir == 1 then -- left
        return string_match( str, "^(.-)" .. pattern .. "*$" ) or str
    elseif dir == -1 then -- right
        return string_match( str, "^" .. pattern .. "*(.+)$" ) or str
    else -- both
        return string_match( str, "^" .. pattern .. "*(.-)" .. pattern .. "*$" ) or str
    end
end

---Replaces all matches of a string.
---@param str string The string.
---@param searchable string The pattern to search for.
---@param replaceable string The string to replace.
---@param withPattern? boolean Whether to use pattern or not.
---@return string str The replaced string.
local function replace( str, searchable, replaceable, withPattern )
    if withPattern == nil then
        local startPos, endPos = string_find( str, searchable, 1, true )
        while startPos ~= nil do
            str = string_sub( str, 1, startPos - 1 ) .. replaceable .. string_sub( str, endPos + 1 )
            startPos, endPos = string_find( str, searchable, endPos + 1, true )
        end

        return str
    else
        ---@diagnostic disable-next-line: redundant-return-value
        return string_gsub( str, searchable, replaceable ), nil
    end
end

---Splits a string by a byte.
---@param str string The string.
---@param byte? number The byte to split by.
---@return string[] result The split string.
---@return number length The length of the split string.
local function byteSplit( str, byte )
    if byte == nil then
        return { str }, 1
    end

    local startPos, endPos = 1, 1
    local nextByte = string_byte( str, endPos )
    local result, length = {}, 0

    while nextByte ~= nil do
        if nextByte == byte then
            length = length + 1
            result[ length ] = string_sub( str, startPos, endPos - 1 )
            startPos = endPos + 1
        end

        endPos = endPos + 1
        nextByte = string_byte( str, endPos )
    end

    length = length + 1
    result[ length ] = string_sub( str, startPos, endPos - 1 )

    return result, length
end

---Checks if a string is a domain.
---@param str string The string.
---@return boolean isDomain Whether the string is a domain.
---@return string? error The error message.
local function isDomain( str )
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
        local labels = byteSplit( str, 0x2E --[[ . ]] )
        for index = 1, #labels do
            local label = labels[ index ]
            if label == "" then
                return false, "empty label in domain"
            elseif string_len( label ) > 63 then
                return false, "label '" .. label .. "' in domain is too long"
            end
        end

        return true
    else
        return false, "invalid domain"
    end
end

---Unpacks a string.
---@param str string The string.
---@param startPos? number The start position.
---@param endPos? number The end position.
---@return ... string
local function unpack( str, startPos, endPos )
    if startPos == nil then startPos = 1 end
    if endPos == nil then endPos = string_len( str ) end
    if startPos == endPos then
        return string_sub( str, endPos, endPos )
    else
        return string_sub( str, startPos, startPos ), unpack( str, startPos + 1, endPos )
    end
end

---Converts a binary string to a decimal number.
---@param str string The binary string.
---@return number
local binary2decimal = function( str )
    return tonumber( str, 2 )
end

---Converts a decimal number to a binary string.
---@param number number The decimal number.
---@param complement? boolean Whether to complement the binary string.
---@return string The binary string.
---@return number The length of the binary string.
local decimal2binary = function( number, complement )
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

---Converts a hex string to a decimal number.
---@param str string The hex string.
---@return number
local hex2decimal = function( str )
    return tonumber( str, 16 )
end

---Converts a decimal number to a hex string.
---@param number number The decimal number.
---@return string
local decimal2hex = function( number )
    return string_format( "%X", number)
end

---@class gpm.std.string
local string = {
    -- Lua 5.1
    byte = glua_string.byte,
    char = glua_string.char,
    dump = glua_string.dump,
    find = string_find,
    format = glua_string.format,
    gmatch = glua_string.gmatch,
    gsub = string_gsub,
    len = string_len,
    lower = glua_string.lower,
    match = string_match,
    rep = glua_string.rep,
    reverse = glua_string.reverse,
    sub = string_sub,
    upper = glua_string.upper,
    slice = string_sub,

    -- Custom
    trim = trim,
    unpack = unpack,
    replace = replace,
    isDomain = isDomain,
    byteSplit = byteSplit,
    bin2dec = binary2decimal,
    dec2bin = decimal2binary,
    hex2dec = hex2decimal,
    dec2hex = decimal2hex,
}

---Cuts the string into two.
---@param str string The string.
---@param index number Cutting index.
---@return string, string
function string.cut( str, index )
    return string_sub( str, 1, index - 1 ), string_sub( str, index, string_len( str ) )
end

---Inserts a value into the string.
---@param str string The string.
---@param index number Insertion index.
---@param value string The value.
---@return string
function string.insert( str, index, value )
    if value == nil then
        return str .. index
    else
        return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index, string_len( str ) )
    end
end

---Removes a character from the string by index.
---@param str string The string.
---@param index number Removal index.
---@return string
function string.remove( str, index )
    if index == nil then index = string_len( str ) end
    return string_sub( str, 1, index - 1 ) .. string_sub( str, index + 1, string_len( str ) )
end

---Checks if the string starts with the start string.
---@param str string The string.
---@param startStr string The start string.
---@return boolean
function string.startsWith( str, startStr )
    return str == startStr or string_sub( str, 1, string_len( startStr ) ) == startStr
end

---Checks if the string ends with the end string.
---@param str string The string.
---@param endStr string The end string.
---@return boolean
function string.endsWith( str, endStr )
    if endStr == "" or str == endStr then
        return true
    else
        local length = string_len( str )
        return string_sub( str, length - string_len( endStr ) + 1, length ) == endStr
    end
end

---Joins the strings.
---@vararg string The strings to join.
---@return string
function string.join( ... )
    local args = { ... }
    local length = #args
    if length == 0 then
        return ""
    else
        return table_concat( args, "", 1, length )
    end
end

---Concatenates the strings.
---@param concatenator? string The concatenator.
---@vararg string The strings to concatenate.
---@return string
function string.concat( concatenator, ... )
    local args = { ... }
    local length = #args
    if length == 0 then
        return ""
    else
        return table_concat( args, concatenator or "", 1, length )
    end
end

---Checks if the string contains the searchable string.
---@param str string The string.
---@param searchable string The searchable string.
---@param position? number The position to start from.
---@param withPattern? boolean If the pattern is used.
---@return number
function string.indexOf( str, searchable, position, withPattern )
    if searchable == nil then
        return 0
    elseif searchable == "" then
        return 1
    else
        position = math_max( position or 1, 1 )
        if position > string_len( str ) then
            return -1
        end

        return string_find( str, searchable, position, withPattern ~= true ) or -1
    end
end

---Splits the string.
---@param str string The string.
---@param pattern? string The pattern to split by.
---@param withPattern? boolean If the pattern is used.
---@return string[] result, number length
function string.split( str, pattern, withPattern )
    if pattern == nil then
        return { str }, 1
    elseif pattern == "" then
        local result, length = {}, string_len( str )
        for index = 1, length, 1 do
            result[ index ] = string_sub( str, index, index )
        end

        return result, length
    else
        local result, length, pointer = {}, 0, 1
        withPattern = withPattern ~= true

        while true do
            local startPos, endPos = string_find( str, pattern, pointer, withPattern )
            if startPos == nil then
                break
            else
                length = length + 1
                result[ length ] = string_sub( str, pointer, startPos - 1 )
                pointer = endPos + 1
            end
        end

        length = length + 1
        result[ length ] = string_sub( str, pointer )

        return result, length
    end
end

---Extracts the string.
---@param str string The string.
---@param pattern string The pattern to extract by.
---@param default? string The default value.
---@return string, string?
function string.extract( str, pattern, default )
    local startPos, endPos, matched = string_find( str, pattern, 1, false )
    if startPos == nil then
        return str, default
    else
        return string_sub( str, 1, startPos - 1 ) .. string_sub( str, endPos + 1 ), matched or default
    end
end

---Returns the number of matches of a string.
---@param str string The string.
---@param pattern? string The pattern.
---@param withPattern? boolean If the pattern is used.
---@return number
function string.count( str, pattern, withPattern )
    if pattern == nil then
        return 0
    elseif pattern == "" then
        return string_len( str )
    else
        withPattern = withPattern ~= true
        local pointer, length = 1, 0

        while true do
            local startPos, endPos = string_find( str, pattern, pointer, withPattern )
            if startPos == nil then
                break
            else
                length = length + 1
                pointer = endPos + 1
            end
        end

        return length
    end
end

---Returns the number of occurrences of a byte.
---@param str string The string.
---@param byte? number The byte to count.
---@return number
function string.byteCount( str, byte )
    if byte == nil or str == "" then return 0 end

    local count = 0

    for index = 1, string_len( str ) do
        if string_byte( str, index ) == byte then
            count = count + 1
        end
    end

    return count
end

---Trims a string by a byte.
---@param str string The string.
---@param byte? number The byte to trim by.
---@param dir? number The direction to trim. `1` for left, `-1` for right, `0` for both.
---@return string str The trimmed string.
---@return number length The length of the trimmed string.
function string.trimByte( str, byte, dir )
    local startPos, endPos = 1, string_len( str )
    if dir == nil then dir = 0 end

    if dir ~= -1 then
        while string_byte( str, startPos ) == byte do
            startPos = startPos + 1
            if startPos == endPos then return "", 0 end
        end
    end

    if dir ~= 1 then
        while string_byte( str, endPos ) == byte do
            endPos = endPos - 1
            if endPos == 0 then return "", 0 end
        end
    end

    return string_sub( str, startPos, endPos ), endPos - startPos + 1
end

---Trims a string by bytes.
---@param str string The string.
---@param bytes table The bytes to trim by.
---@param dir? number The direction to trim. `1` for left, `-1` for right, `0` for both.
---@return string str The trimmed string.
---@return number length The length of the trimmed string.
function string.trimBytes( str, bytes, dir )
    local startPos, endPos = 1, string_len( str )
    if dir == nil then dir = 0 end

    for key, value in pairs( bytes ) do
        if is_number( value ) then
            bytes[ value ] = true
            bytes[ key ] = nil
        elseif is_bool( value ) then
            if not is_number( key ) then
                error( "invalid bytes", 2 )
            end
        else
            error( "invalid bytes", 2 )
        end
    end

    if dir ~= -1 then
        while bytes[ string_byte( str, startPos ) ] do
            startPos = startPos + 1
            if startPos == endPos then return "", 0 end
        end
    end

    if dir ~= 1 then
        while bytes[ string_byte( str, endPos ) ] do
            endPos = endPos - 1
            if endPos == 0 then return "", 0 end
        end
    end

    return string_sub( str, startPos, endPos ), endPos - startPos + 1
end

---Returns the bytes of a string.
---@param str string The string.
---@param startPos? number The start position.
---@param endPos? number The end position.
---@return table, number
function string.bytes( str, startPos, endPos )
    if startPos == nil then startPos = 1 end
    if endPos == nil then endPos = string_len( str ) end
    return { string_byte( str, startPos, endPos ) }, ( endPos - startPos ) + 1
end

---Returns a pattern-safe string.
---@param str string The string.
---@return string
function string.patternSafe( str )
    local startPos, strLength = 1, string_len( str )
    local result, length = {}, 0

    for index = 1, strLength do
        local byte = string_byte( str, index )
        if byte == 0 then
            length = length + 1
            result[ length ] = string_sub( str, startPos, index - 1 ) .. "%z"
            startPos = index + 1
        else
            local pattern = patternUnSafeBytes[ byte ]
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

---Returns a SQL-safe string.
---@param str string The string.
---@return string
function string.sqlSafe( str, noQuotes )
    str = replace( tostring( str ), "'", "''", false )

    local null_chr = string_find( str, "\0", 1, false )
    if null_chr then
        str = string_sub( str, 1, null_chr - 1 )
    end

    if noQuotes then
        return str
    else
        return "'" .. str .. "'"
    end
end

---Checks if a string is a number.
---@param str string The string.
---@param startPos? number The start position.
---@param endPos? number The end position.
---@return boolean
function string.isNumber( str, startPos, endPos )
    if startPos == nil then startPos = 1 end
    if endPos == nil then endPos = string_len( str ) end
    for index = startPos, endPos do
        if index == startPos then
            local byte = string_byte( str, index )
            if asciiNumbers[ byte ] == nil and byte ~= 0x2D --[[ - ]] and byte ~= 0x2B --[[ + ]] then
                return false
            end
        elseif asciiNumbers[ string_byte( str, index ) ] == nil then
            return false
        end
    end

    return true
end

---Checks if a string is a URL.
---@param str string The string.
---@return boolean
function string.isURL( str )
    return string_match( str, "^%l[%l+-.]+%:[^%z\x01-\x20\x7F-\xFF\"<>^`:{-}]*$" ) ~= nil
end

---Checks if a string is a SteamID.
---@param str string The string.
---@return boolean
function string.isSteamID( str )
    return string_match( str, "^STEAM_[0-5]:[01]:%d+$" ) ~= nil
end

---Checks if a string is an email.
---@param str string The string.
---@return boolean isEmail Whether the string is an email.
---@return string? error The error message.
function string.isEmail( str )
    if str == "" then
        return false, "empty string"
    end

    local lastAt = string_find( str, "[^%@]+$" )
    if lastAt == nil then
        return false, "@ symbol is missing"
    end

    if lastAt >= 65 then
        return false, "username is too long"
    end

    local username = string_sub( str, 1, lastAt - 2 )
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

    return isDomain( string_sub( str, lastAt, string_len( str ) ) )
end

---Returns a character from the string by index.
---@param str string
---@param index number
---@return string
function string.get( str, index )
    return string_sub( str, index, index )
end

---Sets a character in the string by index.
---@param str string
---@param index number
---@param value string
---@return string
function string.set( str, index, value )
    return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index + 1, string_len( str ) )
end

---Converts a hex string to a binary string.
---@param str string The hex string.
---@param complement? boolean
---@return string, number
function string.hex2bin( str, complement )
    return decimal2binary( hex2decimal( str ), complement )
end

---Converts a binary string to a hex string.
---@param str string The binary string.
---@return string
function string.bin2hex( str )
    return decimal2hex( binary2decimal( str ) )
end

return string
