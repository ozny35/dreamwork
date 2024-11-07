local table, math, string, select, pairs, is_table, is_string, is_function, getmetatable, setmetatable, rawget, next = ...
local string_sub, string_find, string_len, string_lower = string.sub, string.find, string.len, string.lower
local math_random, math_fdiv = math.random, math.fdiv
local table_remove = table.remove

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

local function lower( tbl, lowerKeys, lowerValues )
    for key, value in pairs( tbl ) do
        if is_table( key ) then
            lower( key )
        elseif lowerKeys and is_string( key ) then
            tbl[ key ] = nil
            key = string_lower( key )
        end

        if is_table( value ) then
            lower( value )
        elseif lowerValues and is_string( value ) then
            value = string_lower( value )
        end

        tbl[ key ] = value
    end

    return tbl
end

return {
    -- Lua 5.1
    ["concat"] = table.concat,
    ["insert"] = table.insert,
    ["maxn"] = table.maxn, -- removed in Lua 5.2
    ["remove"] = table_remove,
    ["sort"] = table.sort,

    -- Lua 5.2
    ["pack"] = table.pack or function( ... ) return { ["n"] = select( "#", ... ), ... } end,
    ["unpack"] = table.unpack or _G.unpack,

    -- Lua 5.3
    ["move"] = table.move or function( source, first, last, offset, destination )
        if destination == nil then destination = source end

        for index = 0, last - first, 1 do
            destination[ offset + index ] = source[ first + index ]
        end

        return destination
    end,

    -- Extensions
    ["add"] = function( destination, source )
        local length = #destination

        for index = 1, #source, 1 do
            destination[ length + index ] = source[ index ]
        end

        return destination
    end,
    ["copy"] = copy,
    ["slice"] = function( tbl, startPos, endPos, step )
        if startPos == nil then startPos = 1 end

        local length = #tbl
        if endPos == nil then endPos = length end
        if startPos > endPos then return {} end

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
    end,
    ["inject"] = function( source, first, last, offset, destination )
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
    end,
    ["removeByValue"] = function( tbl, value )
        for index = #tbl, 1, -1 do
            if tbl[ index ] == value then
                table_remove( tbl, index )
            end
        end

        return nil
    end,
    ["hasValue"] = function( tbl, value )
        for index = 1, #tbl, 1 do
            if tbl[ index ] == value then
                return true
            end
        end

        return false
    end,
    ["getKeys"] = function( tbl )
        local keys, length = {}, 0
        for key in pairs( tbl ) do
            length = length + 1
            keys[ length ] = key
        end

        return keys, length
    end,
    ["getValues"] = function( tbl )
        local values, length = {}, 0
        for _, value in pairs( tbl ) do
            length = length + 1
            values[ length ] = value
        end

        return values, length
    end,
    ["count"] = function( tbl )
        local count = 0
        for _ in pairs( tbl ) do
            count = count + 1
        end

        return count
    end,
    ["flip"] = function( tbl, noCopy )
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
    end,
    ["toSequential"] = function( tbl )
        local result, length = {}, 0
        for key, value in pairs( tbl ) do
            length = length + 1
            result[ length ] = { key, value }
        end

        return result, length
    end,
    ["getValue"] = function( tbl, str )
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
    end,
    ["setValue"] = function( tbl, str, value )
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
    end,
    ["isSequential"] = function( tbl )
        local index = 1
        for _ in pairs( tbl ) do
            if tbl[ index ] == nil then
                return false
            else
                index = index + 1
            end
        end

        return true
    end,
    ["equal"] = equal,
    ["diffKeys"] = diffKeys,
    ["diff"] = diff,
    ["isEmpty"] = function( tbl )
        return next( tbl ) == nil
    end,
    ["empty"] = function( tbl )
        for key in pairs( tbl ) do
            tbl[ key ] = nil
        end

        return tbl
    end,
    ["shuffle"] = function( tbl )
        local j, length = 0, #tbl
        for i = length, 1, -1 do
            j = math_random( 1, length )
            tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
        end

        return tbl
    end,
    ["random"] = function( tbl )
        local length = #tbl
        if length == 0 then
            return nil, -1
        elseif length == 1 then
            return tbl[ 1 ], 1
        else
            local index = math_random( 1, length )
            return tbl[ index ], index
        end
    end,
    ["reverse"] = function( tbl, noCopy )
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
    end,
    ["lower"] = lower,
    ["len"] = function( tbl )
        local metatable = getmetatable( tbl )
        if metatable ~= nil then
            local fn = metatable.__len
            if is_function( fn ) then
                return fn( tbl )
            end
        end

        return #tbl
    end
}
