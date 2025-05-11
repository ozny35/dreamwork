local _G = _G

---@class gpm.std
local std = _G.gpm.std

local select = std.select
local raw_get, raw_set, raw_pairs = std.raw.get, std.raw.set, std.raw.pairs
local string_sub, string_find, string_len = std.string.sub, std.string.find, std.string.len

--- [SHARED AND MENU]
---
--- The table library is a standard Lua library which provides functions to manipulate tables.
---
---@class gpm.std.table : tablelib
local table = std.table or {}
std.table = table

do

    local glua_table = _G.table

    -- Lua 5.1
    table.concat = table.concat or glua_table.concat
    table.insert = table.insert or glua_table.insert
    table.remove = table.remove or glua_table.remove
    table.sort = table.sort or glua_table.sort

    table.maxn = table.maxn or glua_table.maxn -- removed in Lua 5.2

    -- Lua 5.2
    table.pack = table.pack or glua_table.pack

    if table.pack == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function table.pack( ... )
            return { n = select( "#", ... ), ... }
        end
    end

    table.unpack = table.unpack or glua_table.unpack or _G.unpack

    -- Lua 5.3
    table.move = table.move or glua_table.move

    if table.move == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function table.move( source, first, last, offset, destination )
            if destination == nil then
                destination = source
            end

            for index = 0, last - first, 1 do
                raw_set( destination, offset + index, raw_get( source, first + index ) )
            end

            return destination
        end
    end

end

local table_remove = table.remove

--- [SHARED AND MENU]
---
--- Returns a slice of the given table.
---@param tbl table The table to slice.
---@param to? integer The start position.
---@param from? integer The end position.
---@param step? integer The step.
---@return table slice The sliced table.
---@return integer length The length of the sliced table.
function table.slice( tbl, from, to, step )
    local length = #tbl

    if from == nil then
        from = 1
    end

    if to == nil then
        to = length
    end

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

--- [SHARED AND MENU]
---
--- Truncates the given table.
---
--- The original table is modified.
---
--- The truncated table is a shallow copy of the original table.
---
---@param tbl table The table to truncate.
---@param length integer The length of the truncated table.
function table.truncate( tbl, length )
    for index = length + 1, #tbl, 1 do
        tbl[ index ] = nil
    end
end

--- [SHARED AND MENU]
---
--- Creates a truncated copy of the given table.
---
--- The original table is not modified.
---
--- The returned table is a shallow copy of the original table.
---
---@param tbl table The table to truncate.
---@param length integer The length of the truncated table.
---@return table result The truncated table.
function table.truncated( tbl, length )
    local result = {}

    for index = 1, length, 1 do
        result[ index ] = tbl[ index ]
    end

    return result
end

--- [SHARED AND MENU]
---
--- Injects values from one table to another.
---
---@param destination table The destination table.
---@param source table The source table.
---@param position? integer The position to inject.
---@param from? integer The start position.
---@param to? integer The end position.
function table.inject( destination, source, position, from, to )
    if position == nil then
        -- if position, from and to are nil then just append to the end ( aka table.append )
        if from == nil and to == nil then
            local length = #destination

            for index = 1, #source, 1 do
                destination[ length + index ] = source[ index ]
            end

            return
        end

        position = #destination + 1
    elseif position < 0 then
        position = position + ( #destination + 2 )
    end

    if from == nil then from = 1 end
    if to == nil then to = #source end

    if from <= to then
        local steps = to - from
        for i = #destination, position, -1 do
            destination[ steps + i + 1 ] = destination[ i ]
        end

        for i = 0, steps, 1 do
            destination[ position + i ] = source[ from + i ]
        end
    end
end

--- [SHARED AND MENU]
---
--- Remove all occurrences of the given value.
---
---@param tbl table The table to remove from.
---@param value any The value to remove.
---@param no_copy? boolean Don't copy the table.
---@param length? integer The length of the table.
---@return table tbl Table without the given value/'s.
---@return integer length New length of the table.
function table.removeByValue( tbl, value, no_copy, length )
    if no_copy then
        if length == nil then length = #tbl end

        for index = length, 1, -1 do
            if tbl[ index ] == value then
                table_remove( tbl, index )
                length = length - 1
            end
        end

        return tbl, length
    end

    local copy = {}
    length = 0

    for i = 1, #tbl, 1 do
        local table_value = tbl[ i ]
        if table_value ~= value then
            length = length + 1
            copy[ length ] = table_value
        end
    end

    return copy, length
end

--- [SHARED AND MENU]
---
--- Removes a range of values from the given table.
---
---@param tbl table The table to remove from.
---@param from? integer The start position.
---@param to? integer The end position.
function table.eject( tbl, from, to )
    local length = #tbl

    if from == nil then
        if to == nil then return end
        from = 1
    elseif to == nil then
        to = length
    end

    if from > to then return end

    for index = from, to, 1 do
        tbl[ index ] = nil
    end

    local distance = to - from + 1
    for index = to + 1, length, 1 do
        tbl[ index - distance ], tbl[ index ] = tbl[ index ], nil
    end
end

--- [SHARED AND MENU]
---
--- Returns true if the given table contains the given value.
---
---@param tbl table The table to check.
---@param value any The value to check.
---@param is_sequential? boolean If the table is sequential.
---@return boolean result `true` if the table contains the value, `false` otherwise.
function table.contains( tbl, value, is_sequential )
    if is_sequential then
        for index = #tbl, 1, -1 do
            if tbl[ index ] == value then
                return true
            end
        end
    else
        for _, v in raw_pairs( tbl ) do
            if v == value then
                return true
            end
        end
    end

    return false
end

--- [SHARED AND MENU]
---
--- Returns list (table) of keys and length of this list.
---@param tbl table The table.
---@return any[] key_lst The list of keys.
---@return integer key_count The length of the list.
function table.keys( tbl )
    local keys, length = {}, 0
    for key in raw_pairs( tbl ) do
        length = length + 1
        keys[ length ] = key
    end

    return keys, length
end

--- [SHARED AND MENU]
---
--- Returns list (table) of values and length of this list.
---@param tbl table The table.
---@return any[] value_lst The list of values.
---@return integer value_count The length of the list.
function table.values( tbl )
    local values, length = {}, 0
    for _, value in raw_pairs( tbl ) do
        length = length + 1
        values[ length ] = value
    end

    return values, length
end

--- [SHARED AND MENU]
---
--- Returns the count of keys in the given table.
---@param tbl table The table.
---@return integer key_count The count of keys.
function table.size( tbl )
    local count = 0
    for _ in raw_pairs( tbl ) do
        count = count + 1
    end

    return count
end

--- [SHARED AND MENU]
---
--- Flips the keys with values in the given list (table).
---
--- The original table is modified.
---
--- The keys are now the values and the values are now the keys.
---
---@param tbl table The table to flip.
function table.flip( tbl )
    local keys, length = {}, 0
    for key in raw_pairs( tbl ) do
        length = length + 1
        keys[ length ] = key
    end

    for i = 1, length, 1 do
        local key = keys[ i ]
        tbl[ tbl[ key ] ] = key
        tbl[ key ] = nil
    end
end

--- [SHARED AND MENU]
---
--- Creates a flipped version of the given table.
---
--- The original table is not modified.
---
--- The flipped table has the values as keys and the keys as values.
---
---@param tbl table The table to flip.
---@return table result The flipped table.
function table.flipped( tbl )
    local result = {}
    for key, value in raw_pairs( tbl ) do
        result[ value ] = key
    end

    return result
end

--- [SHARED AND MENU]
---
--- Returns the list (table) of key/value pairs and length of this list.
---
---@param tbl table The table.
---@return table result The list of key/value pairs ( sequential table ).
---@return integer length The length of the list.
function table.pairs( tbl )
    local result, length = {}, 0
    for key, value in raw_pairs( tbl ) do
        length = length + 1
        result[ length ] = { key, value }
    end

    return result, length
end

--- [SHARED AND MENU]
---
--- Returns the value of the given key path.
---
--- If the key path does not exist, returns `nil`.
---
--- Example:
---
--- ```lua
---     local t = { a = { b = { c = { d = { e = "e value!" } } } } }
---     print( table.get( t, "a.b.c.d.e" ) ) -- e value!
--- ```
---@param tbl table The table to get the value from.
---@param str string The key path to get.
---@return any value The value of the key path.
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

do

    local istable = std.istable

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the given key path.
    ---
    --- Tables are created if they do not exist.
    ---
    --- Example:
    ---
    --- ```lua
    ---     local t = {}
    ---     table.set( t, "a.b.c.d.e", "e value!" )
    ---     print( t.a.b.c.d.e ) -- e value!
    --- ```
    ---
    ---@param tbl table The table to set the value in.
    ---@param str string The key path.
    ---@param value any The value to set.
    function table.set( tbl, str, value )
        local pointer = 1

        for _ = 1, string_len( str ), 1 do
            local startPos = string_find( str, ".", pointer, true )
            if startPos == nil then
                break
            else
                local key = string_sub( str, pointer, startPos - 1 )
                pointer = startPos + 1


                local tbl_value = raw_get( tbl, key )
                if tbl_value and istable( tbl_value ) then
                    tbl = tbl_value
                else
                    local new_tbl = {}
                    raw_set( tbl, key, new_tbl )
                    tbl = new_tbl
                end
            end
        end

        tbl[ string_sub( str, pointer ) ] = value
    end

end

--- [SHARED AND MENU]
---
--- Returns true if the given table is sequential.
---@param tbl table The table to check.
---@return boolean result `true` if the table is sequential, `false` otherwise.
function table.isSequential( tbl )
    local index = 1
    for _ in raw_pairs( tbl ) do
        if tbl[ index ] == nil then
            return false
        else
            index = index + 1
        end
    end

    return true
end

do

    local next = std.next

    --- [SHARED AND MENU]
    ---
    --- Returns true if the given table is empty.
    ---@param tbl table The table to check.
    ---@return boolean result `true` if the table is empty, `false` otherwise.
    function table.isEmpty( tbl )
        return next( tbl ) == nil
    end

end

--- [SHARED AND MENU]
---
--- Empties the given table.
---
---@param tbl table The table to empty.
---@param is_sequential? boolean If the table is sequential.
---@return table tbl The empty table.
function table.empty( tbl, is_sequential )
    if is_sequential then
        for index = 1, #tbl, 1 do
            tbl[ index ] = nil
        end
    else
        for key in raw_pairs( tbl ) do
            tbl[ key ] = nil
        end
    end

    return tbl
end

--- [SHARED AND MENU]
---
--- Fills the given table with the given value.
---
---@param tbl table The table to fill.
---@param value any The value to fill the table with.
---@param from? integer The start position.
---@param to? integer The end position.
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
        for key in raw_pairs( tbl ) do
            tbl[ key ] = value
        end
    end
end

do

    local math_random = std.math.random

    --- [SHARED AND MENU]
    ---
    --- Shuffles the given table.
    ---
    ---@param tbl table The table.
    function table.shuffle( tbl )
        local j, length = 0, #tbl
        for i = length, 1, -1 do
            j = math_random( 1, length )
            tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a random value and index from the given sequential table.
    ---
    ---@param tbl table The sequential table.
    ---@return any value The random value.
    ---@return integer index The index of the value.
    function table.randomVI( tbl )
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

    --- [SHARED AND MENU]
    ---
    --- Returns a random value and key from the given table.
    ---
    ---@param tbl table The key-value table.
    ---@return any value The random value.
    ---@return any key The key of the value.
    function table.randomVK( tbl )
        local count = 0
        for _ in pairs( tbl ) do
            count = count + 1
        end

        local i = math_random( 1, count )

        for key, value in pairs( tbl ) do
            if i == 1 then
                return value, key
            else
                i = i - 1
            end
        end
    end

end

do

    local math_fmul = std.math.fmul

    --- [SHARED AND MENU]
    ---
    --- Reverses the given table.
    ---
    --- The original table is modified.
    ---
    ---@param tbl table The table to reverse.
    ---@param length? integer The length of the table.
    ---@return table tbl The reversed table.
    ---@return integer length The length of the reversed table.
    function table.reverse( tbl, length )
        if length == nil then length = #tbl end
        length = length + 1

        for i = 1, math_fmul( length - 1, 0.5 ), 1 do
            local j = length - i
            tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
        end

        return tbl, length - 1
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a reversed version of the given table.
    ---
    --- The original table is not modified.
    ---
    ---@param tbl table The table to reverse.
    ---@param length? integer The length of the table.
    ---@return table tbl The reversed table.
    ---@return integer length The length of the reversed table.
    function table.reversed( tbl, length )
        if length == nil then length = #tbl end
        length = length + 1

        local reversed = {}
        for index = length - 1, 1, -1 do
            reversed[ length - index ] = tbl[ index ]
        end

        return reversed, length - 1
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Creates a new table, filled with the given value and size.
    ---
    ---@param value any The value to fill the table with.
    ---@param ... integer The sizes of the table.
    ---@return table tbl The created table.
    local function create( value, size, ... )
        if size == nil then
            return value
        else
            local tbl = {}
            for i = 1, size, 1 do
                tbl[ i ] = create( value, ... )
            end

            return tbl
        end
    end

    table.create = create

end

--- [SHARED AND MENU]
---
--- Extracts selected range of values from the table.
---
---@param tbl table The table.
---@param from? integer The start position.
---@param to? integer The end position.
---@return table values The extracted values.
---@return integer length The length of the extracted values.
function table.extract( tbl, from, to )
    local extracted, extracted_length = {}, 0
    local length = #tbl

    if from == nil then
        if to == nil then
            return extracted, extracted_length
        end

        from = 1
    elseif to == nil then
        to = length
    end

    if from > to then
        return extracted, extracted_length
    end

    for index = from, to, 1 do
        extracted_length = extracted_length + 1
        extracted[ extracted_length ] = tbl[ index ]
    end

    return extracted, extracted_length
end

--- [SHARED AND MENU]
---
--- Removes values from the table.
---
---@param tbl table The table.
---@param start integer? The start position.
---@param delete_count integer? The number of values to remove.
---@param ... any The values to remove.
---@return table removed The table with removed values.
---@return integer removed_length The length of the removed table.
function table.splice( tbl, start, delete_count, ... )
    if start == nil then
        return {}, 0
    end

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
        if keys == nil or keys[ raw_get( tbl, index ) ] then
            removed_length = removed_length + 1
            removed[ removed_length ] = raw_get( tbl, index )

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

    return removed, removed_length
end
