local _G = _G
local glua_debug = _G.debug
local debug_getinfo = glua_debug.getinfo

---@class gpm.std.debug
local debug = {
    -- LuaJIT
    ["newproxy"] = _G.newproxy,

    -- Lua 5.1
    ["debug"] = glua_debug.debug,
    ["getfenv"] = glua_debug.getfenv,
    ["gethook"] = glua_debug.gethook,
    ["getinfo"] = debug_getinfo,
    ["getlocal"] = glua_debug.getlocal,
    ["getmetatable"] = glua_debug.getmetatable,
    ["getregistry"] = glua_debug.getregistry,
    ["getupvalue"] = glua_debug.getupvalue,
    ["setfenv"] = glua_debug.setfenv,
    ["sethook"] = glua_debug.sethook,
    ["setlocal"] = glua_debug.setlocal,
    ["setmetatable"] = glua_debug.setmetatable,
    ["setupvalue"] = glua_debug.setupvalue,
    ["traceback"] = glua_debug.traceback,

    -- Lua 5.2
    ["getuservalue"] = glua_debug.getuservalue,
    ["setuservalue"] = glua_debug.setuservalue,
    ["upvalueid"] = glua_debug.upvalueid,
    ["upvaluejoin"] = glua_debug.upvaluejoin,
}

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

do

    local string_sub, string_gsub
    do
        local glua_string = _G.string
        string_sub, string_gsub = glua_string.sub, glua_string.gsub
    end

    local gsub_formatter = function( _, str ) return str end

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

end

return debug
