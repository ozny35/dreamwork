local _G = _G
local std, glua_debug = _G.gpm.std, _G.debug
local debug_getinfo, glua_string = glua_debug.getinfo, _G.string

--- [SHARED AND MENU]
---
--- Just empty function, do nothing.
local function fempty() end

---@class gpm.std.debug
local debug = {
    -- LuaJIT
    newproxy = _G.newproxy,

    -- Lua 5.1
    debug = glua_debug.debug,
    getfenv = glua_debug.getfenv,
    gethook = glua_debug.gethook,
    getinfo = debug_getinfo,
    getlocal = glua_debug.getlocal,
    getmetatable = glua_debug.getmetatable,
    getregistry = glua_debug.getregistry,
    getupvalue = glua_debug.getupvalue or fempty, -- fucked up in menu
    setfenv = glua_debug.setfenv,
    sethook = glua_debug.sethook,
    setlocal = glua_debug.setlocal,
    setmetatable = glua_debug.setmetatable,
    setupvalue = glua_debug.setupvalue or fempty, -- fucked up in menu
    traceback = glua_debug.traceback,

    -- Lua 5.2
    getuservalue = glua_debug.getuservalue or fempty, -- fucked up in menu
    setuservalue = glua_debug.setuservalue or fempty, -- fucked up in menu
    upvalueid = glua_debug.upvalueid or fempty, -- fucked up in menu
    upvaluejoin = glua_debug.upvaluejoin or fempty, -- fucked up in menu

    -- Custom
    fempty = fempty
}

--- [SHARED AND MENU]
---
--- Call function with given arguments.
---@param func function The function to call.
---@param ... any: Arguments to be passed to the function.
---@return any ... The return values of the function.
function debug.fcall( func, ... )
    return func( ... )
end

do

    local FindMetaTable = _G.FindMetaTable or fempty
    local registry = debug.getregistry() or {}

    function debug.getregistry()
        return registry
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the metatable of the given name or `nil` if not found.
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

    do

        local debug_getmetatable = debug.getmetatable

        -- in case the game gets killed ( p.s. rubat and garry wants this )
        if debug_getmetatable( fempty ) == nil then
            local type = _G.type

            --- [SHARED AND MENU]
            ---
            --- Returns the metatable of the given value or `nil` if not found.
            ---@param value any The value.
            ---@return table | nil meta The metatable.
            function debug.getmetatable( value )
                return debug_getmetatable( value ) or registry[ type( value ) ]
            end
        end

        --- [SHARED AND MENU]
        ---
        --- Returns the value of the given key in the metatable of the given value or `nil` if not found.
        ---@param value any The value.
        ---@param key string The key.
        ---@return any | nil value The value.
        function debug.getmetavalue( value, key )
            local metatable = debug_getmetatable( value )
            return metatable and rawget( metatable, key )
        end

    end

    local RegisterMetaTable = _G.RegisterMetaTable or fempty

    --- [SHARED AND MENU]
    ---
    --- Registers the metatable of the given name and table.
    ---@param name string The name of the metatable.
    ---@param tbl table The metatable.
    ---@param do_full_register? boolean: If true, the metatable will be registered.
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
--- Returns current stack trace as a table with strings.
---@param startPos? integer: The start position of the stack trace.
---@return table stack The stack trace.
---@return integer length The length of the stack trace.
function debug.getstack( startPos )
    local stack, length = {}, 0

    for location = 1 + ( startPos or 1 ), 16, 1 do
        local info = debug_getinfo( location, "Snluf" )
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
    ---@param location function | integer: The function or location to get the path from.
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

    local string_format = glua_string.format
    local tonumber = std.tonumber

    --- [SHARED AND MENU]
    ---
    --- Returns the memory address of the value.
    ---@param value any The value to get the memory address of.
    ---@return integer | nil address The memory address or `nil` if not found.
    function debug.getpointer( value )
        return tonumber( string_format( "%p", value ), 16 )
    end

end

do

    local getfenv = std.getfenv

    --- [SHARED AND MENU]
    ---
    --- Returns the function package or `nil` if not found.
    ---@param location function | integer: The function or stack level.
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
    ---@param location function | integer: The function or stack level.
    ---@param package Package The package to set.
    function debug.setfpackage( location, package )
        -- TODO: Check this after creating the package class
        setfenv( location, package.env )
    end

end

return debug
