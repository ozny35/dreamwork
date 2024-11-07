local string, table_concat, math, tostring, isnumber, isbool, tonumber = ...
local math_ceil, math_max, math_floor, math_log, math_ln2 = math.ceil, math.max, math.floor, math.log, math.ln2
local string_byte, string_sub, string_len, string_find, string_match, string_gsub, string_rep, string_format = string.byte, string.sub, string.len, string.find, string.match, string.gsub, string.rep, string.format

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

local function replace( str, searchable, replaceable, withPattern )
    if withPattern == nil then
        local startPos, endPos = string_find( str, searchable, 1, true )
        while startPos ~= nil do
            str = string_sub( str, 1, startPos - 1 ) .. replaceable .. string_sub( str, endPos + 1 )
            startPos, endPos = string_find( str, searchable, endPos + 1, true )
        end

        return str
    else
        return string_gsub( str, searchable, replaceable )
    end
end

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

local function unpack( str, startPos, endPos )
    if startPos == nil then startPos = 1 end
    if endPos == nil then endPos = string_len( str ) end
    if startPos == endPos then
        return string_sub( str, endPos, endPos )
    else
        return string_sub( str, startPos, startPos ), unpack( str, startPos + 1, endPos )
    end
end

local binary2decimal = function( str )
    return tonumber( str, 2 )
end

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

local hex2decimal = function( str )
    return tonumber( str, 16 )
end

local decimal2hex = function( number )
    return string_format( "%X", number)
end

return {
    -- Lua 5.1
    ["byte"] = string.byte,
    ["char"] = string.char,
    ["dump"] = string.dump,
    ["find"] = string_find,
    ["format"] = string.format,
    ["gmatch"] = string.gmatch,
    ["gsub"] = string_gsub,
    ["len"] = string_len,
    ["lower"] = string.lower,
    ["match"] = string_match,
    ["rep"] = string.rep,
    ["reverse"] = string.reverse,
    ["sub"] = string_sub,
    ["upper"] = string.upper,

    -- Function
    ["slice"] = string_sub,
    ["cut"] = function( str, index )
        return string_sub( str, 1, index - 1 ), string_sub( str, index, string_len( str ) )
    end,
    ["insert"] = function( str, index, value )
        if value == nil then
            return str .. index
        else
            return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index, string_len( str ) )
        end
    end,
    ["remove"] = function( str, index )
        if index == nil then index = string_len( str ) end
        return string_sub( str, 1, index - 1 ) .. string_sub( str, index + 1, string_len( str ) )
    end,
    ["unpack"] = unpack,
    ["startsWith"] = function( str, startStr )
        return str == startStr or string_sub( str, 1, string_len( startStr ) ) == startStr
    end,
    ["endsWith"] = function( str, endStr )
        if endStr == "" or str == endStr then
            return true
        else
            local length = string_len( str )
            return string_sub( str, length - string_len( endStr ) + 1, length ) == endStr
        end
    end,
    ["concat"] = function( ... )
        local args = { ... }
        local length = #args
        if length == 0 then
            return ""
        else
            return table_concat( args, "", 1, length )
        end
    end,
    ["indexOf"] = function( str, searchable, position, withPattern )
        if searchable == nil then
            return 0
        elseif searchable == "" then
            return 1
        else
            position = math_max( position or 1, 1 )
            if position > string_len( str ) then
                return -1
            end

            return string_find( str, searchable, position, withPattern ~= true ) or -1, nil
        end
    end,
    ["split"] = function( str, pattern, withPattern )
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
    end,
    ["replace"] = replace,
    ["extract"] = function( str, pattern, default )
        local startPos, endPos, matched = string_find( str, pattern, 1, false )
        if startPos == nil then
            return str, default
        else
            return string_sub( str, 1, startPos - 1 ) .. string_sub( str, endPos + 1 ), matched or default
        end
    end,
    ["left"] = function( str, num )
        return string_sub( str, 1, num )
    end,
    ["right"] = function( str, num )
        return string_sub( str, -num )
    end,
    ["count"] = function( str, pattern, withPattern )
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
    end,
    ["byteSplit"] = byteSplit,
    ["byteCount"] = function( str, byte )
        if byte == nil then
            return 0
        else
            local count, pointer = 0, 1
            local nextByte = string_byte( str, pointer )

            while nextByte ~= nil do
                if nextByte == byte then
                    count = count + 1
                else
                    pointer = pointer + 1
                    nextByte = string_byte( str, pointer )
                end
            end

            return count
        end
    end,
    ["trimByte"] = function( str, byte, dir )
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
    end,
    ["trimBytes"] = function( str, bytes, dir )
        local startPos, endPos = 1, string_len( str )
        if dir == nil then dir = 0 end

        for key, value in pairs( bytes ) do
            if isnumber( value ) then
                bytes[ value ] = true
                bytes[ key ] = nil
            elseif isbool( value ) then
                if not isnumber( key ) then
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
    end,
    ["bytes"] = function( str, startPos, endPos )
        if startPos == nil then startPos = 1 end
        if endPos == nil then endPos = string_len( str ) end
        return { string_byte( str, startPos, endPos ) }, ( endPos - startPos ) + 1
    end,
    ["patternSafe"] = function( str )
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
    end,
    ["trim"] = trim,
    ["trimLeft"] = function( str, pattern ) return trim( str, pattern, 1 ) end,
    ["trimRight"] = function( str, pattern ) return trim( str, pattern, -1 ) end,
    ["isURL"] = function( str )
        return string_match( str, "^%l[%l+-.]+%:[^%z\x01-\x20\x7F-\xFF\"<>^`:{-}]*$" ) ~= nil
    end,
    ["isSteamID"] = function( str )
        return string_match( str, "^STEAM_[0-5]:[01]:%d+$" ) ~= nil
    end,
    ["isNumber"] = function( str, startPos, endPos )
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
    end,
    ["sqlSafe"] = function( str, noQuotes )
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
    end,
    ["isDomain"] = isDomain,
    ["isEmail"] = function( str )
        if str == "" then
            return false, "empty string"
        end

        local lastAt = string_find( str, "[^%@]+$" )
        if lastAt == nil then
            return false, "@ symbol is missing"
        end

        if lastAt >= 65 then
            return nil, "username is too long"
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
            return nil, "invalid usage of quotes"
        end

        return isDomain( string_sub( str, lastAt, string_len( str ) ) )
    end,
    ["get"] = function( str, index )
        return string_sub( str, index, index )
    end,
    ["set"] = function( str, index, value )
        return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index + 1, string_len( str ) )
    end,
    ["bin2dec"] = binary2decimal,
    ["dec2bin"] = decimal2binary,
    ["hex2dec"] = hex2decimal,
    ["dec2hex"] = decimal2hex,
    ["hex2bin"] = function( str, complement )
        return decimal2binary( hex2decimal( str ), complement )
    end,
    ["bin2hex"] = function( str )
        return decimal2hex( binary2decimal( str ) )
    end
}
