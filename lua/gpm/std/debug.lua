local string, debug = ...
local string_sub, string_gsub = string.sub, string.gsub
local debug_getinfo = debug.getinfo

local gsub_formatter = function( _, str )
    return str
end

return {
    -- Lua 5.1
    ["debug"] = debug.debug,
    ["getfenv"] = debug.getfenv,
    ["gethook"] = debug.gethook,
    ["getinfo"] = debug_getinfo,
    ["getlocal"] = debug.getlocal,
    ["getmetatable"] = debug.getmetatable,
    ["getregistry"] = debug.getregistry,
    ["getupvalue"] = debug.getupvalue,
    ["setfenv"] = debug.setfenv,
    ["sethook"] = debug.sethook,
    ["setlocal"] = debug.setlocal,
    ["setmetatable"] = debug.setmetatable,
    ["setupvalue"] = debug.setupvalue,
    ["traceback"] = debug.traceback,

    -- Lua 5.2
    ["getuservalue"] = debug.getuservalue,
    ["setuservalue"] = debug.setuservalue,
    ["upvalueid"] = debug.upvalueid,
    ["upvaluejoin"] = debug.upvaluejoin,

    -- Functions
    ["fempty"] = function() end, -- Make jit happy <3
    ["fcall"] = function( func, ... )
        return func( ... )
    end,
    ["getstack"] = function( startPos )
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
    end,
    ["getfmain"] = function()
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
    end,
    ["getfpath"] = function( location )
        local info = debug_getinfo( location, "S" )
        if info.what == "main" then
            return string_gsub( string_gsub( string_sub( info.source, 2 ), "^(.-)(lua/.*)$", gsub_formatter ), "^(.-)([%w_]+/gamemode/.*)$", gsub_formatter )
        end

        return ""
    end
}
