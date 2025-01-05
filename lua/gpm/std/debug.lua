local _G = _G
local glua_debug = _G.debug
local debug_getinfo, glua_string = glua_debug.getinfo, _G.string

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

--- Call function with given arguments.
---@param func function
---@param ... any
---@return any
function debug.fcall( func, ... )
    return func( ... )
end

do

    local FindMetaTable = _G.FindMetaTable or fempty
    local metatables = debug.getregistry() or {}

    --- Returns the metatable of the given name or `nil` if not found.
    ---@param name string
    ---@return table?
    function debug.findmetatable( name )
        local tbl = metatables[ name ]
        if tbl == nil then
            tbl = FindMetaTable( name )
            if tbl == nil then
                return nil
            else
                metatables[ name ] = tbl
                return tbl
            end
        else
            return tbl
        end
    end

    local RegisterMetaTable = _G.RegisterMetaTable or fempty

    --- Registers the metatable of the given name and table.
    ---@param name string: The name of the metatable.
    ---@param tbl table: The metatable.
    ---@param do_full_register? boolean: If true, the metatable will be registered.
    ---@return number: The ID of the metatable.
    function debug.registermetatable( name, tbl, do_full_register )
        tbl = metatables[ name ] or tbl
        metatables[ name ] = tbl

        if do_full_register then
            RegisterMetaTable( name, tbl )
            return tbl.MetaID or -1
        else
            return -1
        end
    end

end

--- Returns current stack trace as a table with strings.
---@param startPos? number
---@return table stack
---@return number length
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

--- Returns the function within which the call was made or `nil` if not found.
---@return function | nil
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

    --- Returns the path to the file in which it was called or an empty string if it could not be found.
    ---@param location number | function
    ---@return string path
    function debug.getfpath( location )
        local info = debug_getinfo( location, "S" )
        if info.what == "main" then
            ---@diagnostic disable-next-line: redundant-return-value
            return string_gsub( string_gsub( string_sub( info.source, 2 ), "^(.-)(lua/.*)$", gsub_formatter ), "^(.-)([%w_]+/gamemode/.*)$", gsub_formatter ), nil
        end

        return ""
    end

end

local std = _G.gpm.std

do

    local string_format = glua_string.format
    local tonumber = std.tonumber

    --- Returns the memory address of the value.
    ---@param value any
    ---@return number?
    function debug.getpointer( value )
        return tonumber( string_format( "%p", value ), 16 )
    end

end

do

    local getfenv = std.getfenv

    --- Returns the function package or `nil` if not found.
    ---@param location function | number: The function or stack level.
    ---@return Package?
    function debug.getfpackage( location )
        -- TODO: Check this after creating the package class
        local fenv = getfenv( location )
        return fenv == nil and nil or fenv.__package
    end

end

do

    local setfenv = std.setfenv

    --- Sets the function package.
    ---@param location function | number: The function or stack level.
    ---@param package Package
    function debug.setfpackage( location, package )
        -- TODO: Check this after creating the package class
        setfenv( location, package.env )
    end

end

return debug
