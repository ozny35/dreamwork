local _G = _G
local glua_jit = _G.jit

---@class gpm.std
---@field JIT_OS "Windows" | "Linux" | "OSX" | "BSD" | "POSIX" | "Other"
---@field JIT_ARCH "x86" | "x64" | "arm" | "arm64" | "arm64be" | "ppc" | "ppc64" | "ppc64le" | "mips" | "mipsel" | "mips64" | "mips64el" | string
---@field JIT_VERSION integer The version of the JIT compiler.
---@field JIT_VERSION_NAME string The full name of the JIT compiler version.
local std = _G.gpm.std

---@class gpm.std.debug
local debug = std.debug

-- TODO: docs

--- [SHARED AND MENU]
---
--- The jit library is a standard Lua library which provides functions to manipulate the JIT compiler.
---
--- It"s a wrapper for the native jit library from LuaJIT.
---
---@class gpm.std.debug.jit
local jit = debug.jit or {}
debug.jit = jit

std.JIT_OS = std.JIT_OS or glua_jit.os or "unknown"
std.JIT_ARCH = std.JIT_ARCH or glua_jit.arch or "unknown"
std.JIT_VERSION = std.JIT_VERSION or glua_jit.version_num or 0
std.JIT_VERSION_NAME = std.JIT_VERSION_NAME or glua_jit.version or "unknown"

jit.on = jit.on or glua_jit.on or debug.fempty
jit.off = jit.off or glua_jit.off or debug.fempty
jit.status = jit.status or glua_jit.status or function() return false end

jit.attach = jit.attach or glua_jit.attach or debug.fempty
jit.flush = jit.flush or glua_jit.flush or debug.fempty

if glua_jit.opt == nil then
    jit.options = jit.options or debug.fempty
else
    jit.options = jit.options or glua_jit.opt.start or debug.fempty
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

    function jit.isFFIF()
        return false
    end

else

    --- [SHARED AND MENU]
    ---
    --- Checks if the given function is a FFI function.
    ---
    ---@param fn function The function to check.
    ---@return boolean is_ffi `true` if the function is a FFI function, `false` otherwise.
    function jit.isFFIF( fn )
        local info = util_funcinfo( fn )
        return info ~= nil and info.ffid ~= nil
    end

end
