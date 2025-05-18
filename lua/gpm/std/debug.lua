local _G = _G
local gpm = _G.gpm
local glua_string = _G.string

---@class gpm.std
local std = gpm.std

--- [SHARED AND MENU]
---
--- The debug library is intended to help you debug your scripts,
--- however it also has several other powerful uses.
---
--- In gpm this library has additional functions.
---
---@class gpm.std.debug : debuglib
local debug = std.debug or {}
std.debug = debug

local fempty = debug.fempty
if fempty == nil then

    --- [SHARED AND MENU]
    ---
    --- Just empty function, do nothing.
    ---
    --- Sometimes makes jit happy :>
    ---
    function fempty()
        -- yep, it's literally empty
    end

    debug.fempty = fempty

end

do

    local glua_debug = _G.debug

    -- LuaJIT
    debug.newproxy = debug.newproxy or _G.newproxy

    -- Lua 5.1
    debug.debug = debug.debug or glua_debug.debug or fempty
    debug.getinfo = debug.getinfo or glua_debug.getinfo or fempty
    debug.getregistry = debug.getregistry or glua_debug.getregistry or fempty
    debug.traceback = debug.traceback or glua_debug.traceback or fempty

    debug.getlocal = debug.getlocal or glua_debug.getlocal or fempty
    debug.setlocal = debug.setlocal or glua_debug.setlocal or fempty

    debug.getmetatable = debug.getmetatable or glua_debug.getmetatable or std.getmetatable or fempty
    debug.setmetatable = debug.setmetatable or glua_debug.setmetatable or function() return false end

    debug.getupvalue = debug.getupvalue or glua_debug.getupvalue or fempty -- fucked up in menu
    debug.setupvalue = debug.setupvalue or glua_debug.setupvalue or fempty -- fucked up in menu

    debug.getfenv = debug.getfenv or glua_debug.getfenv or std.getfenv or fempty
    debug.setfenv = debug.setfenv or glua_debug.setfenv or std.setfenv or fempty

    debug.gethook = debug.gethook or glua_debug.gethook or fempty
    debug.sethook = debug.sethook or glua_debug.sethook or fempty

    -- Lua 5.2
    debug.upvalueid = debug.upvalueid or glua_debug.upvalueid or fempty -- fucked up in menu
    debug.upvaluejoin = debug.upvaluejoin or glua_debug.upvaluejoin or fempty -- fucked up in menu

    debug.getuservalue = debug.getuservalue or glua_debug.getuservalue or fempty -- fucked up in menu
    debug.setuservalue = debug.setuservalue or glua_debug.setuservalue or fempty -- fucked up in menu

end

if debug.getmetatable == fempty or debug.setmetatable == fempty then
    error( "I tried my best, but it's over." )
end

local debug_getinfo = debug.getinfo

--- [SHARED AND MENU]
---
--- Call function with given arguments.
---
---@param func function The function to call.
---@param ... any  Arguments to be passed to the function.
---@return any ... The return values of the function.
function debug.fcall( func, ... )
    return func( ... )
end

do

    local FindMetaTable = _G.FindMetaTable or fempty
    local registry = debug.getregistry() or {}

    --- [SHARED AND MENU]
    ---
    --- Returns the registry table.
    ---
    ---@diagnostic disable-next-line: duplicate-set-field
    function debug.getregistry()
        return registry
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the metatable of the given name or `nil` if not found.
    ---
    ---@param name string The name of the metatable.
    ---@return table | nil meta The metatable.
    function debug.findmetatable( name )
        local cached = registry[ name ]
        if cached ~= nil then
            return cached
        end

        local metatable = FindMetaTable( name )
        if metatable ~= nil then
            registry[ name ] = metatable
            return metatable
        end

        return nil
    end

    --- [SHARED AND MENU]
    ---
    --- Returns all upvalues of the given function.
    ---
    ---@param fn function The function to get upvalues from.
    ---@param start_position? integer The start position of the upvalues, default is `0`.
    ---@return table<string, any> values A table with the upvalues.
    ---@return integer value_count The count of upvalues.
    function debug.getupvalues( fn, start_position )
        if start_position == nil then
            start_position = 0
        end

        start_position = start_position + 1

        local values = {}

        local i = start_position
        while true do
            local name, value = debug.getupvalue( fn, i )
            if not name then break end
            values[ name ] = value
            i = i + 1
        end

        return values, i - start_position
    end

    ---@class gpm.std.raw
    local raw = std.raw

    if raw.type == nil then

        local glua_type = _G.type

        local values, count = debug.getupvalues( glua_type )

        if count == 0 or values.C_type == nil then
            raw.type = glua_type
        else
            raw.type = values.C_type
        end

    end

    do

        local debug_getmetatable = debug.getmetatable
        local raw_get = raw.get

        -- in case the game gets killed (thanks Garry)
        if debug_getmetatable( fempty ) == nil and
            not debug.setmetatable( fempty, {} ) and
            debug_getmetatable( fempty ) == nil then

            local raw_type = raw.type

            --- [SHARED AND MENU]
            ---
            --- Returns the metatable of the given value or `nil` if not found.
            ---
            ---@param value any The value.
            ---@return table | nil meta The metatable.
            ---@diagnostic disable-next-line: duplicate-set-field
            function debug.getmetatable( value )
                return debug_getmetatable( value ) or registry[ raw_type( value ) ]
            end

            std.print( "at any cost, but it will work..." )

        end

        --- [SHARED AND MENU]
        ---
        --- Returns the value of the given key in the metatable of the given value.
        ---
        --- Returns `nil` if not found.
        ---
        ---@param value any The value to get the metatable from.
        ---@param key string The searchable key.
        ---@return any | nil value The value of the given key.
        function debug.getmetavalue( value, key, allow_index )
            local metatable = debug_getmetatable( value )
            if metatable == nil then
                return nil
            elseif allow_index then
                return metatable[ key ]
            else
                return raw_get( metatable, key )
            end
        end

    end

    local RegisterMetaTable = _G.RegisterMetaTable or fempty

    --- [SHARED AND MENU]
    ---
    --- Registers the metatable of the given name and table.
    ---
    ---@param name string The name of the metatable.
    ---@param tbl table The metatable.
    ---@param do_full_register? boolean If `true`, the metatable will be registered.
    ---@return integer meta_id The ID of the metatable or -1 if not fully registered.
    function debug.registermetatable( name, tbl, do_full_register )
        tbl = registry[ name ] or tbl
        registry[ name ] = tbl

        if do_full_register then
            RegisterMetaTable( name, tbl )
            return tbl.MetaID or -1
        else
            return -1
        end
    end

end

--- [SHARED AND MENU]
---
--- Returns current stack trace as a debuginfo list.
---
---@param start_position? integer The start position of the stack trace.
---@param fields? string The fields of the stack trace.
---@return debuginfo[] stack The stack trace.
---@return integer length The length of the stack trace.
function debug.getstack( start_position, fields )
    local stack, length = {}, 0

    for location = 1 + ( start_position or 1 ), 16, 1 do
        local info = debug_getinfo( location, fields or "Snluf" )
        if info then
            length = length + 1
            stack[ length ] = info
        else
            break
        end
    end

    return stack, length
end

--- [SHARED AND MENU]
---
--- Returns the function within which the call was made or `nil` if not found.
---
---@return function | nil fn The function within which the call was made or `nil` if not found.
function debug.getfmain()
    for location = 2, 16, 1 do
        local info = debug_getinfo( location, "fS" )
        if info then
            if info.what == "main" then
                return info.func
            end
        else
            break
        end
    end

    return nil
end

do

    local string_sub, string_gsub = glua_string.sub, glua_string.gsub
    local gsub_formatter = function( _, str ) return str end

    --- [SHARED AND MENU]
    ---
    --- Returns the path to the file in which it was called or an empty string if it could not be found.
    ---
    ---@param location function | integer The function or location to get the path from.
    ---@return string path The path to the file in which it was called or an [b]empty string[/b] if it could not be found.
    function debug.getfpath( location )
        local info = debug_getinfo( location, "S" )
        if info.what == "main" then
            ---@diagnostic disable-next-line: redundant-return-value
            return string_gsub( string_gsub( string_sub( info.source, 2 ), "^(.-)(lua/.*)$", gsub_formatter ), "^(.-)([%w_]+/gamemode/.*)$", gsub_formatter ), nil
        end

        return ""
    end

end

if std.jit then

    ---@diagnostic disable-next-line: undefined-field
    local util_funcinfo = std.jit.util.funcinfo

    --- [SHARED AND MENU]
    ---
    --- Checks if the function is jit compilable.
    ---
    ---@param fn function The function to check.
    ---@return boolean bool `true` if the function is jit compilable, otherwise `false`.
    function debug.isjitcompilable( fn )
        local info = util_funcinfo( fn )
        return info and info.ffid ~= nil
    end

else

    function debug.isjitcompilable()
        return false
    end

end

do

    local getfenv = std.getfenv

    --- [SHARED AND MENU]
    ---
    --- Returns the function package or `nil` if not found.
    ---
    ---@param location function | integer The function or stack level.
    ---@return Package? pkg The function package or `nil` if not found.
    function debug.getfpackage( location )
        -- TODO: Check this after creating the package class
        local fenv = getfenv( location )
        return fenv == nil and nil or fenv.__package
    end

end

do

    local setfenv = std.setfenv

    --- [SHARED AND MENU]
    ---
    --- Sets the function package.
    ---
    ---@param location function | integer The function or stack level.
    ---@param package Package The package to set.
    function debug.setfpackage( location, package )
        -- TODO: Check this after creating the package class
        setfenv( location, package.env )
    end

end
