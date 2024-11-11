local _G = _G
local glua_string, glua_debug = _G.string, _G.debug
local string_sub, string_gsub = glua_string.sub, glua_string.gsub
local debug_getinfo = glua_debug.getinfo

local gsub_formatter = function( _, str )
    return str
end

---@class gpm.std.debug
local debug = {}

-- Lua 5.1
debug.glua_debug = glua_debug.debug
debug.getfenv = glua_debug.getfenv
debug.gethook = glua_debug.gethook
debug.getinfo = debug_getinfo
debug.getlocal = glua_debug.getlocal
debug.getmetatable = glua_debug.getmetatable
debug.getregistry = glua_debug.getregistry
debug.getupvalue = glua_debug.getupvalue
debug.setfenv = glua_debug.setfenv
debug.sethook = glua_debug.sethook
debug.setlocal = glua_debug.setlocal
debug.setmetatable = glua_debug.setmetatable
debug.setupvalue = glua_debug.setupvalue
debug.traceback = glua_debug.traceback

-- Lua 5.2
debug.getuservalue = glua_debug.getuservalue
debug.setuservalue = glua_debug.setuservalue
debug.upvalueid = glua_debug.upvalueid
debug.upvaluejoin = glua_debug.upvaluejoin

---Just empty function, do nothing.
function debug.fempty() end

---Call function with given arguments.
---@param func function
---@vararg any
---@return any
function debug.fcall( func, ... )
    return func( ... )
end

---Returns current stack trace as a table with strings.
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

---Returns the function within which the call was made or nil if not found.
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

---Returns the path to the file in which it was called or an empty string if it could not be found.
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

return debug
