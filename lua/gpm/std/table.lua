local _G = _G
local glua_table = _G.table

local string_sub, string_find, string_len, string_lower
do
    local string = _G.string
    string_sub, string_find, string_len, string_lower = string.sub, string.find, string.len, string.lower
end

local std = _G.gpm.std
local select, pairs, getmetatable, setmetatable, rawget, next = std.select, std.pairs, std.getmetatable, std.setmetatable, std.rawget, std.next

local math_random, math_fdiv
do
    local math = std.math
    math_random, math_fdiv = math.random, math.fdiv
end

local is_table, is_string, is_function
do
    local is = std.is
    is_table, is_string, is_function = is.table, is.string, is["function"]
end

local table_remove = glua_table.remove

--- Copies the given table.
---@param source table The table to copy.
---@param isSequential boolean If true, the table is sequential, i.e. the keys are integers.
---@param deepCopy boolean If true, the table is deep copied.
---@param copyKeys boolean If true, the keys are copied.
---@return table
local function copy( source, isSequential, deepCopy, copyKeys, copies )
    if copies == nil then copies = {} end

    local result = copies[ source ]
    if result == nil then
        result = {}

        if deepCopy then
            setmetatable( result, getmetatable( source ) )
        end

        copies[ source ] = result
    end

    if copyKeys == nil then copyKeys = false end

    if isSequential then
        if deepCopy then
            for index = 1, #source, 1 do
                local value = source[ index ]
                if is_table( value ) then
                    value = copy( value, true, true, copyKeys, copies )
                end

                result[ index ] = value
            end
        else
            for index = 1, #source, 1 do
                result[ index ] = source[ index ]
            end
        end
    elseif deepCopy then
        for key, value in pairs( source ) do
            if is_table( value ) then
                value = copy( value, false, true, copyKeys, copies )
            end

            if copyKeys and is_table( key ) then
                result[ copy( value, false, true, true, copies ) ] = value
            else
                result[ key ] = value
            end
        end
    else
        for key, value in pairs( source ) do
            result[ key ] = value
        end
    end

    return result
end

--- Checks if two tables are equal.
---@param a table The first table to check.
---@param b table The second table to check.
---@return boolean
local function equal( a, b )
    if a == b then
        return true
    end

    for key, value in pairs( a ) do
        local alt = rawget( b, key )
        if alt == nil then
            return false
        end

        if not ( getmetatable( value ) or getmetatable( alt ) ) and is_table( value ) and is_table( alt ) then
            return equal( value, alt )
        end

        if value ~= alt then
            return false
        end
    end

    for key, value in pairs( b ) do
        local alt = rawget( a, key )
        if alt == nil then
            return false
        end

        if not ( getmetatable( value ) or getmetatable( alt ) ) and is_table( value ) and is_table( alt ) then
            return equal( value, alt )
        end

        if value ~= alt then
            return false
        end
    end

    return true
end

--- Returns the difference between two tables as a list of keys.
---@param a table The first table.
---@param b table The second table.
---@return table, number
local function diffKeys( a, b, result, length )
    if result == nil then result = {} end
    if length == nil then length = 0 end
    if a == b then return {}, 0 end

    for key, value in pairs( a ) do
        local alt = rawget( b, key )
        if alt == nil then
            length = length + 1
            result[ length ] = key
        end

        if not ( getmetatable( value ) or getmetatable( alt ) ) and is_table( value ) and is_table( alt ) then
            result, length = diffKeys( value, alt, result, length )
        end

        if value ~= alt then
            length = length + 1
            result[ length ] = key
        end
    end

    for key, value in pairs( b ) do
        local alt = rawget( a, key )
        if alt == nil then
            length = length + 1
            result[ length ] = key
        end

        if not ( getmetatable( value ) or getmetatable( alt ) ) and is_table( value ) and is_table( alt ) then
            result, length = diffKeys( value, alt, result, length )
        end

        if value ~= alt then
            length = length + 1
            result[ length ] = key
        end
    end

    return result, length
end

--- Returns the difference between two tables as a table with differences.
---@param a table The first table.
---@param b table The second table.
---@return table
local function diff( a, b )
  local result = {}

  for key, value in pairs( a ) do
        local alt = rawget( b, key )
        if alt == nil then
            result[ key ] = { value, alt }
        end

        if not ( getmetatable( value ) or getmetatable( alt ) ) and is_table( value ) and is_table( alt ) then
            result[ key ] = diff( value, alt )
        end

        if value ~= alt then
            result[ key ] = { value, alt }
        end
    end

    for key, value in pairs( b ) do
        if result[ key ] == nil then
            local alt = rawget(a, key)
            if alt == nil then
                result[ key ] = { value, alt }
            end

            if not ( getmetatable( value ) or getmetatable( alt ) ) and is_table( value ) and is_table( alt ) then
                result[ key ] = diff( value, alt )
            end

            if value ~= alt then
                result[ key ] = { value, alt }
            end
        end
    end

    return result
end

--- Converts a table to lowercase.
---@param tbl table The table to convert.
---@param lowerKeys? boolean Whether to convert keys to lowercase.
---@param lowerValues? boolean Whether to convert values to lowercase.
---@return table tbl
local function lower( tbl, lowerKeys, lowerValues )
    for key, value in pairs( tbl ) do
        if is_table( key ) then
            lower( key, lowerKeys, lowerValues )
        elseif lowerKeys and is_string( key ) then
            tbl[ key ] = nil
            key = string_lower( key )
        end

        if is_table( value ) then
            lower( value, lowerKeys, lowerValues )
        elseif lowerValues and is_string( value ) then
            value = string_lower( value )
        end

        tbl[ key ] = value
    end

    return tbl
end

local table = {
    -- Lua 5.1
    concat = glua_table.concat,
    insert = glua_table.insert,
    maxn = glua_table.maxn, -- removed in Lua 5.2
    remove = table_remove,
    sort = glua_table.sort,

    -- Lua 5.2
    pack = glua_table.pack or function( ... ) return { n = select( "#", ... ), ... } end,
    unpack = glua_table.unpack or _G.unpack,

    -- Lua 5.3
    move = glua_table.move or function( source, first, last, offset, destination )
        if destination == nil then destination = source end

        for index = 0, last - first, 1 do
            destination[ offset + index ] = source[ first + index ]
        end

        return destination
    end,

    -- Custom functions
    diff = diff,
    copy = copy,
    equal = equal,
    lower = lower,
    diffKeys = diffKeys
}

--- Appends values from one table to another.
---@param destination table The destination table.
---@param source table The source table.
---@return table destination
function table.append( destination, source )
    local length = #destination

    for index = 1, #source, 1 do
        destination[ length + index ] = source[ index ]
    end

    return destination
end

--- Returns a slice of the given table.
---@param tbl table The table to slice.
---@param startPos? number The start position.
---@param endPos? number The end position.
---@param step? number The step.
---@return table, number
function table.slice( tbl, startPos, endPos, step )
    if startPos == nil then startPos = 1 end

    local length = #tbl
    if endPos == nil then endPos = length end
    if startPos > endPos then
        return {}, 0
    end

    if startPos < 0 then
        startPos = length + startPos + 1
    end

    if endPos < 0 then
        endPos = length + endPos + 1
    end

    local result = {}
    length = 0

    for index = startPos, endPos, step or 1 do
        length = length + 1
        result[ length ] = tbl[ index ]
    end

    return result, length
end

--- Injects values from one table to another.
---@param source table The source table.
---@param first number The first index.
---@param last number The last index.
---@param offset number The offset.
---@param destination? table The destination table.
---@return table destination
function table.inject( source, first, last, offset, destination )
    if destination == nil then destination = source end

    if offset < 0 then
        offset = offset + ( #destination + 2 )
    end

    local steps = last - first
    for i = #destination, offset, -1 do
        destination[ steps + i + 1 ] = destination[ i ]
    end

    for i = 0, steps, 1 do
        destination[ offset + i ] = source[ first + i ]
    end

    return destination
end

--- Remove indexs from the given table by value.
---@param tbl table The table.
---@param value any The value.
function table.removeByValue( tbl, value )
    for index = #tbl, 1, -1 do
        if tbl[ index ] == value then
            table_remove( tbl, index )
        end
    end

    return nil
end

--- Returns true if the given list (table) contains the given value.
---@param tbl table The table.
---@param value any The value.
---@return boolean
function table.contains( tbl, value )
    for index = 1, #tbl, 1 do
        if tbl[ index ] == value then
            return true
        end
    end

    return false
end

--- Returns true if the given table contains the given value.
---@param tbl table The table.
---@param value any The value.
---@return boolean
function table.hasValue( tbl, value )
    for _, v in pairs( tbl ) do
        if v == value then
            return true
        end
    end

    return false
end

--- Returns list (table) of keys and length of this list.
---@param tbl table The table.
---@return table, number
function table.getKeys( tbl )
    local keys, length = {}, 0
    for key in pairs( tbl ) do
        length = length + 1
        keys[ length ] = key
    end

    return keys, length
end

--- Returns list (table) of values and length of this list.
---@param tbl table The table.
---@return table, number
function table.getValues( tbl )
    local values, length = {}, 0
    for _, value in pairs( tbl ) do
        length = length + 1
        values[ length ] = value
    end

    return values, length
end

--- Returns the count of keys in the given table.
---@param tbl table The table.
---@return number
function table.count( tbl )
    local count = 0
    for _ in pairs( tbl ) do
        count = count + 1
    end

    return count
end

--- Flips the keys with values in the given list (table).
---@param tbl table The table.
---@param noCopy? boolean
---@return table
function table.flip( tbl, noCopy )
    if noCopy then
        local keys, length = {}, 0
        for key in pairs( tbl ) do
            length = length + 1
            keys[ length ] = key
        end

        for i = 1, length, 1 do
            local key = keys[ i ]
            tbl[ tbl[ key ] ] = key
            tbl[ key ] = nil
        end

        return tbl
    else
        local result = {}
        for key, value in pairs( tbl ) do
            result[ value ] = key
        end

        return result
    end
end

--- Returns list (table) of pairs and length of this list.
---@param tbl table The key/value table.
---@return table, number
function table.toPairs( tbl )
    local result, length = {}, 0
    for key, value in pairs( tbl ) do
        length = length + 1
        result[ length ] = { key, value }
    end

    return result, length
end

--- Returns the value of the given key path.
---@param tbl table The table.
---@param str string The key path.
---@return any
function table.getValue( tbl, str )
    local pointer = 1

    for _ = 1, string_len( str ), 1 do
        local startPos = string_find( str, ".", pointer, true )
        if startPos == nil then
            break
        else
            tbl = tbl[ string_sub( str, pointer, startPos - 1 ) ]
            if tbl == nil then
                return nil
            else
                pointer = startPos + 1
            end
        end
    end

    return tbl[ string_sub( str, pointer ) ]
end

--- Sets the value of the given key path.
---@param tbl table The table.
---@param str string The key path.
---@param value any The value.
function table.setValue( tbl, str, value )
    local pointer = 1

    for _ = 1, string_len( str ), 1 do
        local startPos = string_find( str, ".", pointer, true )
        if startPos == nil then
            break
        else
            local key = string_sub( str, pointer, startPos - 1 )
            pointer = startPos + 1

            if is_table( tbl[ key ] ) then
                tbl = tbl[ key ]
            else
                tbl[ key ] = {}
            end
        end
    end

    tbl[ string_sub( str, pointer ) ] = value
end

--- Returns true if the given table is sequential.
---@param tbl table The table.
---@return boolean
function table.isSequential( tbl )
    local index = 1
    for _ in pairs( tbl ) do
        if tbl[ index ] == nil then
            return false
        else
            index = index + 1
        end
    end

    return true
end

--- Returns true if the given table is empty.
---@param tbl table The table.
---@return boolean
function table.isEmpty( tbl )
    return next( tbl ) == nil
end

--- Fills the given table with the given value.
---@param tbl table The table.
---@param endPos? number The end position.
---@param startPos? number The start position.
---@param value any The value.
---@return table
function table.fill( tbl, endPos, startPos, value )
    if endPos then
        if endPos < 0 then
            endPos = #tbl + endPos + 1
        end

        for index = startPos or 1, endPos, 1 do
            tbl[ index ] = value
        end
    else
        for key in pairs( tbl ) do
            tbl[ key ] = value
        end
    end

    return tbl
end

--- Shuffles the given list (table).
---@param tbl table The table.
---@return table
function table.shuffle( tbl )
    local j, length = 0, #tbl
    for i = length, 1, -1 do
        j = math_random( 1, length )
        tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
    end

    return tbl
end

--- Returns a random value from the given list (table).
---@param tbl table The table.
---@return any, number
function table.random( tbl )
    local length = #tbl
    if length == 0 then
        return nil, -1
    elseif length == 1 then
        return tbl[ 1 ], 1
    else
        local index = math_random( 1, length )
        return tbl[ index ], index
    end
end

--- Reverses the given list (table).
---@param tbl table The table.
---@param noCopy? boolean If true, the table will not be copied.
---@return table
function table.reverse( tbl, noCopy )
    local length = #tbl
    if noCopy then
        length = length + 1

        for index = 1, math_fdiv( length, 2 ), 1 do
            tbl[ index ], tbl[ length - index ] = tbl[ length - index ], tbl[ index ]
        end

        return tbl
    else
        local result = {}
        for index = length, 1, -1 do
            result[ length - index + 1 ] = tbl[ index ]
        end

        return result
    end
end

--- Returns the length of the given table.
---@param tbl table The table.
---@return number
---@diagnostic disable-next-line: undefined-field
table.len = glua_table.len or function( tbl )
    local metatable = getmetatable( tbl )
    if metatable == nil then
        return #tbl
    end

    local fn = rawget( metatable, "__len" )
    if is_function( fn ) then
        return fn( tbl )
    end

    return #tbl
end

return table
