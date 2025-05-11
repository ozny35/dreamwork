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
---@class gpm.std.string : stringlib
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
    string.gmatch = string.gmatch or glua_string.gmatch
    string.gsub = string.gsub or glua_string.gsub
    string.len = string.len or glua_string.len
    string.lower = string.lower or glua_string.lower
    string.match = string.match or glua_string.match
    string.rep = string.rep or glua_string.rep
    string.reverse = string.reverse or glua_string.reverse
    string.sub = string.sub or glua_string.sub
    string.upper = string.upper or glua_string.upper

end

string.slice = string.sub

local string_byte = string.byte
local string_sub = string.sub
local string_len = string.len
local string_find = string.find
local string_rep = string.rep

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
---@param pattern string The pattern to divide by.
---@param from number? The start index.
---@param with_pattern boolean? If set to true, the pattern will be included in the resulting strings.
---@return string The first part of the strin.
---@return string The second part of the string.
function string.divide( str, pattern, from, with_pattern )
    local startPos, endPos = string_find( str, pattern, from or 1, with_pattern ~= true )
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
---@param pattern? string The pattern to split by.
---@param with_pattern? boolean If the pattern is used.
---@return string[] result The string array.
---@return number length The length of the array.
function string.split( str, pattern, with_pattern )
    if pattern == nil then
        return { str }, 1
    elseif pattern == "" then
        local result, length = {}, string_len( str )
        for index = 1, length, 1 do
            result[ index ] = string_sub( str, index, index )
        end

        return result, length
    end

    local result, length, pointer = {}, 0, 1
    with_pattern = with_pattern ~= true

    while true do
        local startPos, endPos = string_find( str, pattern, pointer, with_pattern )
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
---@param pattern string The pattern to extract by.
---@param default? string  The default value.
---@return string result The resulting string.
---@return string? extracted The extracted string.
function string.extract( str, pattern, default )
    local startPos, endPos, matched = string_find( str, pattern, 1, false )
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
---@param pattern? string The pattern to count by.
---@param with_pattern? boolean If the pattern is used.
---@return number count The number of matches.
function string.count( str, pattern, with_pattern )
    if pattern == nil then
        return 0
    elseif pattern == "" then
        return string_len( str )
    end

    with_pattern = with_pattern ~= true
    local pointer, length = 1, 0

    while true do
        local startPos, endPos = string_find( str, pattern, pointer, with_pattern )
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

--- [SHARED AND MENU]
---
--- Returns a character from the string by index.
---
---@param str string The input string.
---@param index number The character index.
---@return string char The character.
function string.get( str, index )
    return string_sub( str, index, index )
end

--- [SHARED AND MENU]
---
--- Sets a character in the string by index.
---
---@param str string The input string.
---@param index number The character index.
---@param value string The character.
---@return string result The resulting string.
function string.set( str, index, value )
    return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index + 1, string_len( str ) )
end

do

    local ascii_numbers = {
        [ 0x30 ] = true, -- 0
        [ 0x31 ] = true, -- 1
        [ 0x32 ] = true, -- 2
        [ 0x33 ] = true, -- 3
        [ 0x34 ] = true, -- 4
        [ 0x35 ] = true, -- 5
        [ 0x36 ] = true, -- 6
        [ 0x37 ] = true, -- 7
        [ 0x38 ] = true, -- 8
        [ 0x39 ] = true  -- 9
    }

    -- TODO: check performance diff with this and raw.tonumber ~= nil

    --- [SHARED AND MENU]
    ---
    --- Checks if a string is a number.
    ---
    ---@param str string The string.
    ---@param from? number The start position.
    ---@param to? number The end position.
    ---@return boolean is_number `true` if the string is a number, otherwise `false`.
    function string.isNumber( str, from, to )
        if from == nil then from = 1 end
        if to == nil then to = string_len( str ) end

        for index = from, to, 1 do
            if index == from then
                local byte = string_byte( str, index )
                if ascii_numbers[ byte ] == nil and byte ~= 0x2D --[[ - ]] and byte ~= 0x2B --[[ + ]] then
                    return false
                end
            elseif ascii_numbers[ string_byte( str, index ) ] == nil then
                return false
            end
        end

        return true
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
            ---@diagnostic disable-next-line: redundant-return-value
            return string_gsub( str, searchable, replaceable ), nil
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

do

    local string_match = string.match

    --- [SHARED AND MENU]
    ---
    --- Checks if a string is a URL.
    ---
    ---@param str string The string.
    ---@return boolean result `true` if the string is a URL, otherwise `false`.
    function string.isURL( str )
        return string_match( str, "^%l[%l+-.]+%:[^%z\x01-\x20\x7F-\xFF\"<>^`:{-}]*$" ) ~= nil
    end

    local jit_version = ( {
        [ "200" ] = 0x01,
        [ "201" ] = 0x02
    } )[ string_sub( std.tostring( std.jit.version_num ), 1, 3 ) ]

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

        local b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )
        return b1 == 0x1B and b2 == 0x4C and b3 == 0x4A and b4 == jit_version
    end

end
