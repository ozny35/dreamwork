---@class gpm.std
local std = _G.gpm.std

--- [SHARED AND MENU]
---
--- The string type is a sequence of characters.
---
--- The string library is a standard Lua library which provides functions for the manipulation of strings.
---
--- In gpm string library contains additional functions.
---
---@class gpm.std.string
local string = std.string or {}
std.string = string

do

    local glua_string = _G.string

    -- Lua 5.1
    string.byte = string.byte or glua_string.byte
    string.char = string.char or glua_string.char
    string.dump = string.dump or glua_string.dump
    string.find = string.find or glua_string.find
    string.format = string.format or glua_string.format
    ---@diagnostic disable-next-line: deprecated
    string.gmatch = string.gmatch or glua_string.gmatch or glua_string.gfind
    string.gsub = string.gsub or glua_string.gsub
    string.len = string.len or glua_string.len
    string.lower = string.lower or glua_string.lower
    string.match = string.match or glua_string.match
    string.rep = string.rep or glua_string.rep
    string.reverse = string.reverse or glua_string.reverse
    string.sub = string.sub or glua_string.sub
    string.upper = string.upper or glua_string.upper

end

local string_char, string_byte = string.char, string.byte
local string_match, string_find = string.match, string.find
local string_sub, string_rep, string_len = string.sub, string.rep, string.len

local table = std.table
local table_concat = table.concat

--- [SHARED AND MENU]
---
--- Checks if the string is empty.
---
---@param str string The input string.
---@return boolean result True if the string is empty.
function string.isEmpty( str )
    return string_byte( str, 1, 1 ) == nil
end

--- [SHARED AND MENU]
---
--- Cuts the string into two.
---
---@param str string The input string.
---@param index number String cutting index.
---@return string The first part of the string.
---@return string The second part of the string.
function string.cut( str, index )
    return string_sub( str, 1, index - 1 ), string_sub( str, index, string_len( str ) )
end

--- [SHARED AND MENU]
---
--- Divides the string by the pattern.
---
---@param str string The input string.
---@param pattern_str string The pattern to divide by.
---@param from number? The start index.
---@param with_pattern boolean? If set to true, the pattern will be included in the resulting strings.
---@return string The first part of the strin.
---@return string The second part of the string.
function string.divide( str, pattern_str, from, with_pattern )
    local startPos, endPos = string_find( str, pattern_str, from or 1, with_pattern ~= true )
    if startPos == nil then
        return str, ""
    else
        return string_sub( str, 1, startPos - 1 ), string_sub( str, ( endPos or startPos ) + 1, string_len( str ) )
    end
end

--- [SHARED AND MENU]
---
--- Inserts a value into the string.
---
---@param str string The input string.
---@param index number The string insertion index.
---@param value string The string value to insert.
---@return string result The resulting string.
function string.insert( str, index, value )
    if value == nil then
        return str .. index
    else
        return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index, string_len( str ) )
    end
end

--- [SHARED AND MENU]
---
--- Removes a character from the string by index.
---
---@param str string The input string.
---@param from number The start index.
---@param to number The end index.
---@return string result The resulting string.
function string.remove( str, from, to )
    if from == nil then from = string_len( str ) end
    if to == nil then to = from end
    return string_sub( str, 1, from - 1 ) .. string_sub( str, to + 1, string_len( str ) )
end

--- [SHARED AND MENU]
---
--- Checks if the string starts with the start string.
---
---@param str string The input string.
---@param startStr string The start string.
---@return boolean is_starts `true` if the string starts with the start string, otherwise `false`.
function string.startsWith( str, startStr )
    return str == startStr or string_sub( str, 1, string_len( startStr ) ) == startStr
end

--- [SHARED AND MENU]
---
--- Checks if the string ends with the end string.
---
---@param str string The input string.
---@param endStr string The end string.
---@return boolean is_ends `true` if the string ends with the end string, otherwise `false`.
function string.endsWith( str, endStr )
    if endStr == "" or str == endStr then
        return true
    else
        local length = string_len( str )
        return string_sub( str, length - string_len( endStr ) + 1, length ) == endStr
    end
end

do

    local math_max = std.math.max

    --- [SHARED AND MENU]
    ---
    --- Checks if the string contains the searchable string.
    ---
    ---@param str string The input string.
    ---@param searchable string The searchable string.
    ---@param position? number The position to start from.
    ---@param with_pattern? boolean If the pattern is used.
    ---@return number index The index of the searchable string, otherwise `-1`.
    function string.indexOf( str, searchable, position, with_pattern )
        if searchable == nil then
            return 0
        elseif searchable == "" then
            return 1
        else
            position = math_max( position or 1, 1 )
            if position > string_len( str ) then
                return -1
            end

            return string_find( str, searchable, position, with_pattern ~= true ) or -1
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Pads the string.
    ---
    ---@param str string The string to pad.
    ---@param length integer The desired length of the string.
    ---@param char? string The padding compensation symbol. Space by default.
    ---@param direction? integer The compensation direction, `1` for left, `-1` for right, `0` for both.
    ---@return string result The padded string.
    function string.pad( str, length, char, direction )
        local missing_length = math_max( 0, length - string_len( str ) )
        if missing_length == 0 then return str end

        if char == nil then
            char = " "
        elseif string_len( char ) ~= 1 then
            error( "char must be a single character", 2 )
        end

        if direction == 1 then
            return string_rep( char, missing_length ) .. str
        elseif direction == -1 then
            return str .. string_rep( char, missing_length )
        end

        missing_length = missing_length * 0.5

        if missing_length % 1 == 0 then
            return string_rep( char, missing_length ) .. str .. string_rep( char, missing_length )
        else
            return string_rep( char, missing_length ) .. str .. string_rep( char, missing_length + 1 )
        end
    end

end

--- [SHARED AND MENU]
---
--- Splits the string.
---
---@param str string The input string.
---@param pattern_str? string The pattern to split by.
---@param with_pattern? boolean If the pattern is used.
---@return string[] result The string array.
---@return number length The length of the array.
function string.split( str, pattern_str, with_pattern )
    if pattern_str == nil then
        return { str }, 1
    elseif pattern_str == "" then
        local result, length = {}, string_len( str )
        for index = 1, length, 1 do
            result[ index ] = string_sub( str, index, index )
        end

        return result, length
    end

    local result, length, pointer = {}, 0, 1
    with_pattern = with_pattern ~= true

    while true do
        local startPos, endPos = string_find( str, pattern_str, pointer, with_pattern )
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

--- [SHARED AND MENU]
---
--- Extracts the string.
---
---@param str string The input string.
---@param pattern_str string The pattern to extract by.
---@param default? string  The default value.
---@return string result The resulting string.
---@return string? extracted The extracted string.
function string.extract( str, pattern_str, default )
    local startPos, endPos, matched = string_find( str, pattern_str, 1, false )
    if startPos == nil then
        return str, default
    else
        return string_sub( str, 1, startPos - 1 ) .. string_sub( str, endPos + 1 ), matched or default
    end
end

--- [SHARED AND MENU]
---
--- Returns the number of matches of a string.
---
---@param str string The input string.
---@param pattern_str? string The pattern to count by.
---@param with_pattern? boolean If the pattern is used.
---@return number count The number of matches.
function string.count( str, pattern_str, with_pattern )
    if pattern_str == nil then
        return 0
    elseif pattern_str == "" then
        return string_len( str )
    end

    with_pattern = with_pattern ~= true
    local pointer, length = 1, 0

    while true do
        local startPos, endPos = string_find( str, pattern_str, pointer, with_pattern )
        if startPos == nil then
            break
        else
            length = length + 1
            pointer = endPos + 1
        end
    end

    return length
end

--- [SHARED AND MENU]
---
--- Splits a string by a byte.
---
---@param str string The input string.
---@param byte? number The byte to split by.
---@return string[] result The split string.
---@return number length The length of the split string.
function string.byteSplit( str, byte )
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

--- [SHARED AND MENU]
---
--- Returns the number of occurrences of a byte.
---
---@param str string The input string.
---@param byte? number The byte to count.
---@return number byte_count The number of occurrences.
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

--- [SHARED AND MENU]
---
--- Trims a string by a byte.
---
---@param str string The input string.
---@param byte? number The byte to trim by.
---@param direction? number The direction to trim. `1` for left, `-1` for right, `0` for both.
---@return string str The trimmed string.
---@return number length The length of the trimmed string.
function string.byteTrim( str, byte, direction )
    local startPos, endPos = 1, string_len( str )

    if direction ~= -1 then
        while string_byte( str, startPos ) == byte do
            startPos = startPos + 1
            if startPos == endPos then return "", 0 end
        end
    end

    if direction ~= 1 then
        while string_byte( str, endPos ) == byte do
            endPos = endPos - 1
            if endPos == 0 then return "", 0 end
        end
    end

    return string_sub( str, startPos, endPos ), endPos - startPos + 1
end

do

    local raw_tonumber = std.raw.tonumber

    --- [SHARED AND MENU]
    ---
    --- Checks if the string is a number.
    ---
    ---@param str string The input string.
    ---@param base? integer The number base, default is `10`.
    ---@param from? number The start position, default is `1`.
    ---@param to? number The end position, default is the length of the string.
    ---@return boolean is_number `true` if the string is a number, otherwise `false`.
    function string.isNumber( str, base, from, to )
        if from == nil and to == nil then
            return raw_tonumber( str, base ) ~= nil
        else
            return raw_tonumber( string_sub( str, from or 1, to ), base ) ~= nil
        end
    end

end

do

    local string_gsub = string.gsub

    --- [SHARED AND MENU]
    ---
    --- Replaces all matches of a string.
    ---
    ---@param str string The input string.
    ---@param searchable string The pattern to search for.
    ---@param replaceable string The string to replace.
    ---@param with_pattern? boolean Whether to use pattern or not.
    ---@return string str The replaced string.
    function string.replace( str, searchable, replaceable, with_pattern )
        if with_pattern then
            local result = string_gsub( str, searchable, replaceable )
            return result
        else
            local startPos, endPos = string_find( str, searchable, 1, true )
            while startPos ~= nil do
                str = string_sub( str, 1, startPos - 1 ) .. replaceable .. string_sub( str, endPos + 1 )
                startPos, endPos = string_find( str, searchable, endPos + 1, true )
            end

            return str
        end
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Unpacks a string into characters.
    ---
    ---@param str string The input string.
    ---@param from? number The start position.
    ---@param to? number The end position.
    ---@return string ...
    local function explode( str, from, to )
        if from == nil then from = 1 end
        if to == nil then to = string_len( str ) end
        if from == to then
            return string_sub( str, to, to )
        else
            return string_sub( str, from, from ), explode( str, from + 1, to )
        end
    end

    string.explode = explode

end

--- [SHARED AND MENU]
---
--- Checks if a string is a URL.
---
---@param str string The string.
---@return boolean result `true` if the string is a URL, otherwise `false`.
function string.isURL( str )
    return string_match( str, "^%l[%l+-.]+%:[^%z\x01-\x20\x7F-\xFF\"<>^`:{-}]*$" ) ~= nil
end

do

    local jit_version = ( {
        [ "200" ] = 0x01,
        [ "201" ] = 0x02
    } )[ string_sub( std.tostring( std.JIT_VERSION_INT ), 1, 3 ) ]

    --- [SHARED AND MENU]
    ---
    --- Checks if a string is bytecode.
    ---
    ---@param str string The string.
    ---@param start_position? integer The start position of the string.
    ---@return boolean result `true` if the string is bytecode, otherwise `false`.
    function string.isBytecode( str, start_position )
        if start_position == nil then
            start_position = 1
        end

        local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, start_position, start_position + 3 )
        return uint8_1 == 0x1B and uint8_2 == 0x4C and uint8_3 == 0x4A and uint8_4 == jit_version
    end

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

    --- [SHARED AND MENU]
    ---
    --- Returns a pattern-safe string.
    ---
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
                local pattern_str = unsafe_pattern_bytes[ byte ]
                if pattern_str then
                    length = length + 1

                    if startPos == index then
                        result[ length ] = pattern_str
                    else
                        result[ length ] = string_sub( str, startPos, index - 1 ) .. pattern_str
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

    --- [SHARED AND MENU]
    ---
    --- Removes leading and trailing matches of a string.
    ---
    ---@param str string The string.
    ---@param pattern_str? string The pattern to match, `%s` for whitespace.
    ---@param direction? number The direction to trim. `1` for left, `-1` for right, `0` for both.
    ---@return string str The trimmed string.
    function string.trim( str, pattern_str, direction )
        if pattern_str == nil then
            pattern_str = "%s"
        else
            if pattern_str == "" then
                pattern_str = "%s"
            else
                local length = string_len( pattern_str )
                if length == 1 then
                    pattern_str = unsafe_pattern_bytes[ string_byte( pattern_str, 1 ) ] or pattern_str
                elseif length ~= 2 or string_byte( pattern_str, 1 ) ~= 0x25 then
                    pattern_str = "[" .. pattern_str .. "]"
                end
            end
        end

        if direction == 1 then -- left
            return string_match( str, "^(.-)" .. pattern_str .. "*$" ) or str
        elseif direction == -1 then -- right
            return string_match( str, "^" .. pattern_str .. "*(.+)$" ) or str
        else -- both
            return string_match( str, "^" .. pattern_str .. "*(.-)" .. pattern_str .. "*$" ) or str
        end
    end

end

do

    local extended_ascii_alphabet = {}
    local lowercase_alphabet = {}
    local uppercase_alphabet = {}
    local numberic_alphabet = {}
    local symbol_alphabet = {}

    do

        local extended_ascii_alphabet_size = 0
        local lowercase_alphabet_size = 0
        local uppercase_alphabet_size = 0
        local numberic_alphabet_size = 0
        local symbol_alphabet_size = 0

        for i = 33, 47, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 48, 57, 1 do
            numberic_alphabet_size = numberic_alphabet_size + 1
            numberic_alphabet[ numberic_alphabet_size ] = i
        end

        for i = 58, 64, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 65, 90, 1 do
            uppercase_alphabet_size = uppercase_alphabet_size + 1
            uppercase_alphabet[ uppercase_alphabet_size ] = i
        end

        for i = 91, 96, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 97, 122, 1 do
            lowercase_alphabet_size = lowercase_alphabet_size + 1
            lowercase_alphabet[ lowercase_alphabet_size ] = i
        end

        for i = 123, 126, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 128, 255, 1 do
            extended_ascii_alphabet_size = extended_ascii_alphabet_size + 1
            extended_ascii_alphabet[ extended_ascii_alphabet_size ] = i
        end

        lowercase_alphabet[ 0 ] = lowercase_alphabet_size
        uppercase_alphabet[ 0 ] = uppercase_alphabet_size
        numberic_alphabet[ 0 ] = numberic_alphabet_size
        symbol_alphabet[ 0 ] = symbol_alphabet_size

    end

    local math_random = std.math.random
    local table_unpack = table.unpack

    --- [SHARED AND MENU]
    ---
    --- Generates a random string.
    ---
    --- Can be used to generate a password/key/secret.
    ---
    --- The length of the string is 8 by default.
    ---
    ---@param length? integer The length of the string, defaults to 8.
    ---@param lowercase? boolean Whether to include lowercase letters.
    ---@param uppercase? boolean Whether to include uppercase letters.
    ---@param numbers? boolean Whether to include numbers.
    ---@param symbols? boolean Whether to include symbols.
    ---@param extended_ascii? boolean Whether to include extended ASCII characters.
    ---@return string
    function string.random( length, lowercase, uppercase, numbers, symbols, extended_ascii )
        if length == nil then
            length = 8
        elseif length == 0 then
            return ""
        end

        local alphabets, alphabet_count = {}, 0

        if lowercase ~= false then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = lowercase_alphabet
        end

        if uppercase then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = uppercase_alphabet
        end

        if numbers ~= false then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = numberic_alphabet
        end

        if symbols then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = symbol_alphabet
        end

        if extended_ascii then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = extended_ascii_alphabet
        end

        local chars, char_count = {}, 0

        for _ = 1, length, 1 do
            local alphabet = alphabets[ math_random( 1, alphabet_count ) ]

            char_count = char_count + 1
            chars[ char_count ] = alphabet[ math_random( 1, alphabet[ 0 ] ) ]
        end

        return string_char( table_unpack( chars, 1, char_count ) )
    end

end

local isDomain
do

    local string_byteSplit = string.byteSplit

    --- [SHARED AND MENU]
    ---
    --- Checks if a string is a domain.
    ---
    ---@param str string The string.
    ---@return boolean isDomain Whether the string is a domain.
    ---@return string | nil err_msg The error message.
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

--- [SHARED AND MENU]
---
--- Checks if a string is an email.
---
---@param str string The string.
---@return boolean isEmail Whether the string is an email.
---@return nil | string err_msg The error message.
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
