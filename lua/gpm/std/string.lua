local _G = _G
local std, glua_string = _G.gpm.std, _G.string

local math = std.math
local math_max = math.max

local string_byte, string_sub, string_len, string_find, string_match, string_gsub = glua_string.byte, glua_string.sub, glua_string.len, glua_string.find, glua_string.match, glua_string.gsub

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
    slice = string_sub
}

--- Cuts the string into two.
---@param str string: The input string.
---@param index number: String cutting index.
---@return string, string: The first part of the string, the second part of the string.
function string.cut( str, index )
    return string_sub( str, 1, index - 1 ), string_sub( str, index, string_len( str ) )
end

--- Inserts a value into the string.
---@param str string: The input string.
---@param index number: The string insertion index.
---@param value string: The string value to insert.
---@return string: The resulting string.
function string.insert( str, index, value )
    if value == nil then
        return str .. index
    else
        return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index, string_len( str ) )
    end
end

--- Removes a character from the string by index.
---@param str string: The input string.
---@param from number: The start index.
---@param to number: The end index.
---@return string: The resulting string.
function string.remove( str, from, to )
    if from == nil then from = string_len( str ) end
    if to == nil then to = from end
    return string_sub( str, 1, from - 1 ) .. string_sub( str, to + 1, string_len( str ) )
end

--- Checks if the string starts with the start string.
---@param str string: The input string.
---@param startStr string: The start string.
---@return boolean: `true` if the string starts with the start string, otherwise `false`.
function string.startsWith( str, startStr )
    return str == startStr or string_sub( str, 1, string_len( startStr ) ) == startStr
end

--- Checks if the string ends with the end string.
---@param str string: The input string.
---@param endStr string: The end string.
---@return boolean: `true` if the string ends with the end string, otherwise `false`.
function string.endsWith( str, endStr )
    if endStr == "" or str == endStr then
        return true
    else
        local length = string_len( str )
        return string_sub( str, length - string_len( endStr ) + 1, length ) == endStr
    end
end

--- Checks if the string contains the searchable string.
---@param str string: The input string.
---@param searchable string: The searchable string.
---@param position? number: The position to start from.
---@param withPattern? boolean: If the pattern is used.
---@return number: The index of the searchable string, otherwise `-1`.
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

--- Splits the string.
---@param str string: The input string.
---@param pattern? string: The pattern to split by.
---@param withPattern? boolean: If the pattern is used.
---@return string[] result, number length: The resulting string array and the length of the array.
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

--- Extracts the string.
---@param str string: The input string.
---@param pattern string: The pattern to extract by.
---@param default? string: The default value.
---@return string, string?: The resulting string and the extracted string.
function string.extract( str, pattern, default )
    local startPos, endPos, matched = string_find( str, pattern, 1, false )
    if startPos == nil then
        return str, default
    else
        return string_sub( str, 1, startPos - 1 ) .. string_sub( str, endPos + 1 ), matched or default
    end
end

--- Returns the number of matches of a string.
---@param str string: The input string.
---@param pattern? string: The pattern to count by.
---@param withPattern? boolean: If the pattern is used.
---@return number: The number of matches.
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

--- Splits a string by a byte.
---@param str string: The input string.
---@param byte? number: The byte to split by.
---@return string[] result: The split string.
---@return number length: The length of the split string.
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

--- Returns the number of occurrences of a byte.
---@param str string: The input string.
---@param byte? number: The byte to count.
---@return number: The number of occurrences.
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

--- Trims a string by a byte.
---@param str string: The input string.
---@param byte? number: The byte to trim by.
---@param direction? number: The direction to trim. `1` for left, `-1` for right, `0` for both.
---@return string str: The trimmed string.
---@return number length: The length of the trimmed string.
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

--- Returns a character from the string by index.
---@param str string: The input string.
---@param index number: The character index.
---@return string: The character.
function string.get( str, index )
    return string_sub( str, index, index )
end

--- Sets a character in the string by index.
---@param str string: The input string.
---@param index number: The character index.
---@param value string: The character.
---@return string: The resulting string.
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

    --- Checks if a string is a number.
    ---@param str string: The string.
    ---@param from? number: The start position.
    ---@param to? number: The end position.
    ---@return boolean: `true` if the string is a number, otherwise `false`.
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

--- Replaces all matches of a string.
---@param str string: The input string.
---@param searchable string: The pattern to search for.
---@param replaceable string: The string to replace.
---@param withPattern? boolean: Whether to use pattern or not.
---@return string str: The replaced string.
function string.replace( str, searchable, replaceable, withPattern )
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

do

    --- Unpacks a string.
    ---@param str string: The input string.
    ---@param from? number: The start position.
    ---@param to? number: The end position.
    ---@return ... string
    local function unpack( str, from, to )
        if from == nil then from = 1 end
        if to == nil then to = string_len( str ) end
        if from == to then
            return string_sub( str, to, to )
        else
            return string_sub( str, from, from ), unpack( str, from + 1, to )
        end
    end

    string.unpack = unpack

end

return string
