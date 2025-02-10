local _G = _G
local std, glua_table = _G.gpm.std, _G.table
local math = std.math

local select, pairs, setmetatable, rawget, rawset, next = std.select, std.pairs, std.setmetatable, std.rawget, std.rawset, std.next
local debug_getmetatable = std.debug.getmetatable
local table_remove = glua_table.remove

local string_sub, string_find, string_len, string_lower
do
    local string = std.string
    string_sub, string_find, string_len, string_lower = string.sub, string.find, string.len, string.lower
end

local istable = std.istable

---@class gpm.std.table
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
    end
}

do

    local function deep_copy_with_keys_and_meta( source, lookup_table )
        local copy = {}
        lookup_table[ source ] = copy

        local metatable = debug_getmetatable( source )
        if metatable ~= nil and rawget( metatable, "__type" ) == nil then
            setmetatable( copy, metatable )
        end

        for key, value in pairs( source ) do
            local key_copy
            if istable( key ) then
                key_copy = lookup_table[ key ] or deep_copy_with_keys_and_meta( key, lookup_table )
            end

            if istable( value ) then
                copy[ key_copy or key ] = lookup_table[ value ] or deep_copy_with_keys_and_meta( value, lookup_table )
            else
                copy[ key_copy or key ] = value
            end
        end

        return copy
    end

    local function deep_copy_with_keys( source, lookup_table )
        local copy = {}
        lookup_table[ source ] = copy

        for key, value in pairs( source ) do
            local key_copy
            if istable( key ) then
                key_copy = lookup_table[ key ] or deep_copy_with_keys( key, lookup_table )
            end

            if istable( value ) then
                copy[ key_copy or key ] = lookup_table[ value ] or deep_copy_with_keys( value, lookup_table )
            else
                copy[ key_copy or key ] = value
            end
        end

        return copy
    end

    local function deep_copy_with_meta( source, lookup_table )
        local copy = {}

        local metatable = debug_getmetatable( source )
        if metatable ~= nil and rawget( metatable, "__type" ) == nil then
            setmetatable( copy, metatable )
        end

        for key, value in pairs( source ) do
            if istable( key ) then
                lookup_table = lookup_table or {}
                lookup_table[ source ] = copy
                copy[ key ] = lookup_table[ value ] or deep_copy_with_meta( value, lookup_table )
            else
                copy[ key ] = value
            end
        end

        return copy
    end

    local function deep_copy( source, lookup_table )
        local copy = {}

        for key, value in pairs( source ) do
            if istable( value ) then
                lookup_table = lookup_table or {}
                lookup_table[ source ] = copy
                copy[ key ] = lookup_table[ value ] or deep_copy( value, lookup_table )
            else
                copy[ key ] = value
            end
        end

        return copy
    end

    --- [SHARED AND MENU] Copies a table.
    ---@param source table: The table to copy.
    ---@param deepCopy boolean?: Whether to deep copy the table.
    ---@param copyKeys boolean?: Whether to copy the keys.
    ---@param copyMetatables boolean?: Whether to copy the metatables.
    ---@return table: The copied table.
    function table.copy( source, deepCopy, copyKeys, copyMetatables )
        local copy
        if deepCopy then
            if copyKeys then
                if copyMetatables then
                    copy = deep_copy_with_keys_and_meta( source, {} )
                else
                    copy = deep_copy_with_keys( source, {} )
                end
            elseif copyMetatables then
                copy = deep_copy_with_meta( source )
            else
                copy = deep_copy( source )
            end
        else
            copy = {}
            for key, value in pairs( source ) do
                rawset( copy, key, value )
            end
        end

        return copy
    end

    --- [SHARED AND MENU] Copies a sequential table.
    ---@param source table: The table to copy.
    ---@param deepCopy boolean?: Whether to deep copy the table.
    ---@param copyKeys boolean?: Whether to copy the keys.
    ---@param copyMetatables boolean?: Whether to copy the metatables.
    ---@param from integer?: The start index.
    ---@param to integer?: The end index.
    ---@return table: The copied table.
    function table.copySequential( source, deepCopy, copyKeys, copyMetatables, from, to )
        from, to = from or 1, to or #source
        local copy = {}

        if deepCopy then
            if copyMetatables then
                local metatable = debug_getmetatable( source )
                if metatable ~= nil and rawget( metatable, "__type" ) == nil then
                    setmetatable( copy, metatable )
                end
            end

            if copyKeys then
                for index = from, to, 1 do
                    local value = rawget( source, index )
                    if istable( value ) then
                        if copyMetatables then
                            copy[ index ] = deep_copy_with_keys_and_meta( source, {} )
                        else
                            copy[ index ] = deep_copy_with_keys( source, {} )
                        end
                    else
                        copy[ index ] = value
                    end
                end
            else
                for index = from, to, 1 do
                    local value = rawget( source, index )
                    if istable( value ) then
                        if copyMetatables then
                            copy[ index ] = deep_copy_with_meta( source )
                        else
                            copy[ index ] = deep_copy( source )
                        end
                    else
                        copy[ index ] = value
                    end
                end
            end
        else
            copy = {}
            for index = from, to, 1 do
                copy[ index ] = rawget( source, index )
            end
        end

        return copy
    end

end

do

    --- [SHARED AND MENU] Checks if two tables are equal.
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

            if not ( debug_getmetatable( value ) or debug_getmetatable( alt ) ) and istable( value ) and istable( alt ) then
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

            if not ( debug_getmetatable( value ) or debug_getmetatable( alt ) ) and istable( value ) and istable( alt ) then
                return equal( value, alt )
            end

            if value ~= alt then
                return false
            end
        end

        return true
    end

    table.equal = equal

end

do

    --- [SHARED AND MENU] Returns the difference between two tables as a list of keys.
    ---@param a table The first table.
    ---@param b table The second table.
    ---@return table: The list of keys.
    ---@return integer: The length of the list.
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

            if not ( debug_getmetatable( value ) or debug_getmetatable( alt ) ) and istable( value ) and istable( alt ) then
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

            if not ( debug_getmetatable( value ) or debug_getmetatable( alt ) ) and istable( value ) and istable( alt ) then
                result, length = diffKeys( value, alt, result, length )
            end

            if value ~= alt then
                length = length + 1
                result[ length ] = key
            end
        end

        return result, length
    end

    table.diffKeys = diffKeys

end

do

    --- [SHARED AND MENU] Returns the difference between two tables as a table with differences.
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

            if not ( debug_getmetatable( value ) or debug_getmetatable( alt ) ) and istable( value ) and istable( alt ) then
                ---@cast alt table
                result[ key ] = diff( value, alt )
            end

            if value ~= alt then
                result[ key ] = { value, alt }
            end
        end

        for key, value in pairs( b ) do
            if result[ key ] == nil then
                local alt = rawget( a, key )
                if alt == nil then
                    result[ key ] = { value, alt }
                end

                if not ( debug_getmetatable( value ) or debug_getmetatable( alt ) ) and istable( value ) and istable( alt ) then
                    ---@cast alt table
                    result[ key ] = diff( value, alt )
                end

                if value ~= alt then
                    result[ key ] = { value, alt }
                end
            end
        end

        return result
    end

    table.diff = diff

end

do

    local isstring = std.isstring

    --- [SHARED AND MENU] Converts a table to lowercase.
    ---@param tbl table The table to convert.
    ---@param lowerKeys? boolean Whether to convert keys to lowercase.
    ---@param lowerValues? boolean Whether to convert values to lowercase.
    ---@return table tbl
    local function lower( tbl, lowerKeys, lowerValues )
        for key, value in pairs( tbl ) do
            if istable( key ) then
                lower( key, lowerKeys, lowerValues )
            elseif lowerKeys and isstring( key ) then
                tbl[ key ] = nil
                key = string_lower( key )
            end

            if istable( value ) then
                lower( value, lowerKeys, lowerValues )
            elseif lowerValues and isstring( value ) then
                value = string_lower( value )
            end

            tbl[ key ] = value
        end

        return tbl
    end

    table.lower = lower

end

--- [SHARED AND MENU] Returns a slice of the given table.
---@param tbl table: The table to slice.
---@param to? integer: The start position.
---@param from? integer: The end position.
---@param step? integer: The step.
---@return table: The sliced table.
---@return integer: The length of the sliced table.
function table.slice( tbl, from, to, step )
    from = from or 1

    local length = #tbl
    to = to or length

    if from > to then
        return {}, 0
    end

    if from < 0 then
        from = length + from + 1
    end

    if to < 0 then
        to = length + to + 1
    end

    local slice = {}
    length = 0

    for index = from, to, step or 1 do
        length = length + 1
        slice[ length ] = tbl[ index ]
    end

    return slice, length
end

--- [SHARED AND MENU] Injects values from one table to another.
---@param destination table: The destination table.
---@param source table: The source table.
---@param position? integer: The position to inject.
---@param from? integer: The start position.
---@param to? integer: The end position.
---@return table: The destination table.
function table.inject( destination, source, position, from, to )
    if position == nil then
        -- if position, from and to are nil then just append to the end ( aka table.append )
        if from == nil and to == nil then
            local length = #destination

            for index = 1, #source, 1 do
                destination[ length + index ] = source[ index ]
            end

            return destination
        end

        position = #destination + 1
    elseif position < 0 then
        position = position + ( #destination + 2 )
    end

    if from == nil then from = 1 end
    if to == nil then to = #source end

    if from > to then
        return destination
    end

    local steps = to - from
    for i = #destination, position, -1 do
        destination[ steps + i + 1 ] = destination[ i ]
    end

    for i = 0, steps, 1 do
        destination[ position + i ] = source[ from + i ]
    end

    return destination
end

--- [SHARED AND MENU] Remove all occurrences of the given value.
---@param tbl table: The table to remove from.
---@param value any: The value to remove.
function table.removeByValue( tbl, value )
    for index = #tbl, 1, -1 do
        if tbl[ index ] == value then
            table_remove( tbl, index )
        end
    end
end

--- [SHARED AND MENU] Removes a range of values from the given table.
---@param tbl table: The table to remove from.
---@param from? integer: The start position.
---@param to? integer: The end position.
---@return table: The same table.
function table.eject( tbl, from, to )
    local length = #tbl

    if from == nil then
        if to == nil then
            return tbl
        end

        from = 1
    elseif to == nil then
        to = length
    end

    if from > to then
        return tbl
    end

    for index = from, to, 1 do
        tbl[ index ] = nil
    end

    local distance = to - from + 1
    for index = to + 1, length, 1 do
        tbl[ index - distance ], tbl[ index ] = tbl[ index ], nil
    end

    return tbl
end

--- [SHARED AND MENU] Returns true if the given list (table) contains the given value.
---@param tbl table: The table to check.
---@param value any The value to check.
---@return boolean: `true` if the table contains the value, `false` otherwise.
function table.contains( tbl, value )
    for index = #tbl, 1, -1 do
        if tbl[ index ] == value then
            return true
        end
    end

    return false
end

--- [SHARED AND MENU] Returns true if the given table contains the given value.
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

--- [SHARED AND MENU] Returns list (table) of keys and length of this list.
---@param tbl table: The table.
---@return any[]: The list of keys.
---@return integer: The length of the list.
function table.getKeys( tbl )
    local keys, length = {}, 0
    for key in pairs( tbl ) do
        length = length + 1
        keys[ length ] = key
    end

    return keys, length
end

--- [SHARED AND MENU] Returns list (table) of values and length of this list.
---@param tbl table: The table.
---@return any[]: The list of values.
---@return integer: The length of the list.
function table.getValues( tbl )
    local values, length = {}, 0
    for _, value in pairs( tbl ) do
        length = length + 1
        values[ length ] = value
    end

    return values, length
end

--- [SHARED AND MENU] Returns the count of keys in the given table.
---@param tbl table: The table.
---@return integer: The count of keys.
function table.count( tbl )
    local count = 0
    for _ in pairs( tbl ) do
        count = count + 1
    end

    return count
end

--- [SHARED AND MENU] Flips the keys with values in the given list (table).
---@param tbl table: The table to flip.
---@param noCopy? boolean: Do not copy the table.
---@return table: The flipped table.
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

--- [SHARED AND MENU] Returns the list (table) of key/value pairs and length of this list.
---@param tbl table: The key/value table.
---@return table: The list.
---@return integer: The length of the list.
function table.getPairs( tbl )
    local result, length = {}, 0
    for key, value in pairs( tbl ) do
        length = length + 1
        result[ length ] = { key, value }
    end

    return result, length
end

--- [SHARED AND MENU] Returns the value of the given key path.
---@param tbl table: The table to get the value from.
---@param str string The key path to get.
---@return any: The value of the key path.
function table.get( tbl, str )
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

--- [SHARED AND MENU] Sets the value of the given key path.
---@param tbl table: The table to set the value in.
---@param str string: The key path.
---@param value any: The value to set.
function table.set( tbl, str, value )
    local pointer = 1

    for _ = 1, string_len( str ), 1 do
        local startPos = string_find( str, ".", pointer, true )
        if startPos == nil then
            break
        else
            local key = string_sub( str, pointer, startPos - 1 )
            pointer = startPos + 1

            local tbl_value = rawget( tbl, key )
            if istable( tbl_value ) then
                tbl = tbl_value
            else
                rawset( tbl, key, {} )
            end
        end
    end

    tbl[ string_sub( str, pointer ) ] = value
end

--- [SHARED AND MENU] Returns true if the given table is sequential.
---@param tbl table: The table to check.
---@return boolean: `true` if the table is sequential, `false` otherwise.
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

--- [SHARED AND MENU] Returns true if the given table is empty.
---@param tbl table: The table to check.
---@return boolean: `true` if the table is empty, `false` otherwise.
function table.isEmpty( tbl )
    return next( tbl ) == nil
end

--- [SHARED AND MENU] Fills the given table with the given value.
---@param tbl table: The table to fill.
---@param value any: The value to fill the table with.
---@param from? integer: The start position.
---@param to? integer: The end position.
---@return table: The filled table.
function table.fill( tbl, value, from, to )
    if from or to then
        from = from or 1

        if to then
            if to < 0 then
                to = #tbl + to + 1
            end
        else
            to = #tbl
        end

        for index = from, to, 1 do
            tbl[ index ] = value
        end
    else
        for key in pairs( tbl ) do
            tbl[ key ] = value
        end
    end

    return tbl
end

do

    local math_random = math.random

    --- [SHARED AND MENU] Shuffles the given table.
    ---@param tbl table: The table.
    ---@return table: The shuffled table.
    function table.shuffle( tbl )
        local j, length = 0, #tbl
        for i = length, 1, -1 do
            j = math_random( 1, length )
            tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
        end

        return tbl
    end

    --- [SHARED AND MENU] Returns a random value from the given list (table).
    ---@param tbl table: The table.
    ---@return any: The value.
    ---@return integer: The index of the value.
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

end

do

    local math_fmul = math.fmul

    --- [SHARED AND MENU] Reverses the given list (table).
    ---@param tbl table: The table to reverse.
    ---@param noCopy? boolean: If `true`, the table will not be copied.
    ---@return table: The reversed table.
    function table.reverse( tbl, noCopy )
        local length = #tbl
        length = length + 1

        if noCopy then
            for i = 1, math_fmul( length - 1, 0.5 ), 1 do
                local j = length - i
                tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
            end

            return tbl
        end

        local reversed = {}
        for index = length - 1, 1, -1 do
            reversed[ length - index ] = tbl[ index ]
        end

        return reversed
    end

end

do

    local getmetatable = std.getmetatable
    local isfunction = std.isfunction

    --- [SHARED AND MENU] Returns the length of the given table.
    ---@param tbl table: The table.
    ---@return integer: The length of the table.
    ---@diagnostic disable-next-line: undefined-field
    table.len = glua_table.len or function( tbl )
        local metatable = getmetatable( tbl )
        if metatable == nil then
            return #tbl
        end

        local fn = rawget( metatable, "__len" )
        return isfunction( fn ) and fn( tbl ) or #tbl
    end

end

do

    --- [SHARED AND MENU] Creates a new table, filled with the given value and size.
    ---@param value any: The value to fill the table with.
    ---@param ... integer: The sizes of the table.
    ---@return table: The created table.
    local function create_table( value, size, ... )
        if size == nil then
            return value
        else
            local tbl = {}
            for i = 1, size, 1 do
                tbl[ i ] = create_table( value, ... )
            end

            return tbl
        end
    end

    table.create = create_table

end

--- [SHARED AND MENU] Removes values from the table.
---@param tbl table: The table.
---@param start integer?: The start position.
---@param delete_count integer?: The number of values to remove.
---@param ... any: The values to remove.
---@return table: The table with removed values.
function table.splice( tbl, start, delete_count, ... )
    if start == nil then return {} end
    local tbl_length = #tbl

    if start < 0 then
        start = tbl_length + start + 1
    end

    if delete_count == nil then
        delete_count = tbl_length - start + 1
    end

    local keys
    local arg_count = select( "#", ... )
    if arg_count ~= 0 then
        keys = {}

        local args = { ... }
        for i = 1, arg_count, 1 do
            keys[ args[ i ] ] = true
        end
    end

    local removed, removed_length = {}, 0
    ::back::

    for index = start, tbl_length, 1 do
        if keys == nil or keys[ rawget( tbl, index ) ] then
            removed_length = removed_length + 1
            removed[ removed_length ] = rawget( tbl, index )

            delete_count = delete_count - 1
            table_remove( tbl, index )

            if delete_count == 0 then
                break
            else
                start, tbl_length = index, #tbl
                goto back
            end
        end
    end

    return removed
end

return table
