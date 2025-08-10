local _G = _G
local glua_jit = _G.jit

---@class dreamwork.std
---@field JIT_OS "Windows" | "Linux" | "OSX" | "BSD" | "POSIX" | "Other"
---@field JIT_ARCH "x86" | "x64" | "arm" | "arm64" | "arm64be" | "ppc" | "ppc64" | "ppc64le" | "mips" | "mipsel" | "mips64" | "mips64el" | string
---@field JIT_VERSION string The full name of the JIT compiler version.
---@field JIT_VERSION_INT integer The version of the JIT compiler.
local std = _G.dreamwork.std

---@class dreamwork.std.debug
local debug = std.debug

-- TODO: docs

--- [SHARED AND MENU]
---
--- The jit library is a standard Lua library which provides functions to manipulate the JIT compiler.
---
--- It"s a wrapper for the native jit library from LuaJIT.
---
---@class dreamwork.std.debug.jit
local jit = debug.jit or {}
debug.jit = jit

std.JIT_OS = glua_jit.os or "unknown"
std.JIT_ARCH = glua_jit.arch or "unknown"
std.JIT_VERSION = glua_jit.version or "unknown"
std.JIT_VERSION_INT = glua_jit.version_num or 0

jit.on = glua_jit.on or debug.fempty
jit.off = glua_jit.off or debug.fempty
jit.status = glua_jit.status or function() return false end

jit.attach = glua_jit.attach or debug.fempty
jit.flush = glua_jit.flush or debug.fempty

if glua_jit.opt == nil then
    jit.options = debug.fempty
else
    jit.options = glua_jit.opt.start or debug.fempty
end

local debug_getfmain = debug.getfmain
local raw_type = std.raw.type

---@diagnostic disable-next-line: undefined-field
local util = glua_jit.util or {}

-- TODO: improve luals support

---@type fun( func: function, position?: integer ): table
local util_funcinfo = util.funcinfo

if jit.getfinfo == nil then

    function jit.getfinfo( location, position )
        if raw_type( location ) == "number" then
            location = debug_getfmain( location + 1 )
        end

        if location == nil then
            error( "function not found", 2 )
        end

        return util_funcinfo( location, position )
    end

end

if jit.getfbc == nil then

    ---@type fun( func: function, position?: integer ): integer, integer
    local util_funcbc = util.funcbc

    function jit.getfbc( location, position )
        if raw_type( location ) == "number" then
            location = debug_getfmain( location + 1 )
        end

        if location == nil then
            error( "function not found", 2 )
        end

        return util_funcbc( location, position )
    end

end

if jit.getfconst == nil then

    ---@type fun( func: function, index?: integer ): any
    local util_funck = util.funck

    function jit.getfconst( location, position )
        if raw_type( location ) == "number" then
            location = debug_getfmain( location + 1 )
        end

        if location == nil then
            error( "function not found", 2 )
        end

        return util_funck( location, position )
    end

end

if jit.getfupvalue == nil then

    ---@type fun( func: function, index?: integer ): string
    local util_funcuvname = util.funcuvname
    if util_funcuvname == nil then
        -- TODO: fallback
    else

        function jit.getfupvalue( location, position )
            if raw_type( location ) == "number" then
                location = debug_getfmain( location + 1 )
            end

            if location == nil then
                error( "function not found", 2 )
            end

            return util_funcuvname( location, position )
        end

    end

end

if util_funcinfo == nil then

    function jit.isFFI( fn )
        return fn ~= nil
    end

else

    --- [SHARED AND MENU]
    ---
    --- Checks if the given function is a FFI function.
    ---
    ---@param fn function The function to check.
    ---@return boolean is_ffi `true` if the function is a FFI function, `false` otherwise.
    function jit.isFFI( fn )
        if fn == nil then
            return false
        else
            local info = util_funcinfo( fn )
            return info ~= nil and info.ffid ~= nil
        end
    end

end
