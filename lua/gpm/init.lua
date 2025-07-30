local version = "2.0.0"

---@class _G
local _G = _G

---@class gpm
---@field VERSION string Package manager version in semver format.
---@field PREFIX string Package manager unique prefix.
---@field StartTime number Time point when package manager was started in seconds.
local gpm = _G.gpm
if gpm == nil then
    ---@class gpm
    gpm = {}
    _G.gpm = gpm
end

-- TODO: globally replace all versions, steamids, url, etc. with their classes in gpm, e.g. std.URL, steam.Identifier
-- TODO: add https://eprosync.github.io/interstellar-docs/ support

--- [SHARED AND MENU]
---
--- gpm standard environment
---
---@class gpm.std
---@field LUA_VERSION string The version of the Lua interpreter.
---@field GAME_VERSION integer The version of the game. (Garry's Mod)
---@field SYSTEM_ENDIANNESS `true` if the operating system is big endianness, `false` if not.
---@field SYSTEM_COUNTRY string The country code of the operating system. (ISO 3166-1 alpha-2)
---@field HAS_BATTERY boolean `true` if the operating system has a battery, `false` if not.
---@field BATTERY_LEVEL integer The battery level, from `0` to `100`.
---@field OSX boolean `true` if the game is running on OSX.
---@field LINUX boolean `true` if the game is running on Linux.
---@field WINDOWS boolean `true` if the game is running on Windows.
---@field DEVELOPER integer A cached value of `developer` console variable.
---@field TICK_TIME number The time it takes to run one tick.
---@field TPS number The number of ticks per second.
---@field FRAME_TIME number The time it takes to run one frame in seconds. **Client-only**
---@field FPS number The number of frames per second. **Client-only**
local std = gpm.std
if std == nil then
    ---@class gpm.std
    std = {}
    gpm.std = std
end

std.LUA_VERSION = _G._VERSION or "unknown"
---@diagnostic disable-next-line: assign-type-mismatch
std.GAME_VERSION = _G.VERSION or 0

---@diagnostic disable-next-line: undefined-field
local dofile = gpm.dofile
if dofile == nil then
    dofile = _G.include or _G.dofile
    gpm.dofile = dofile
end

---@diagnostic disable-next-line: undefined-field
local os_clock = _G.SysTime

if os_clock == nil then
    local os = _G.os
    if os ~= nil then
        os_clock = os.clock or os.time
    end

    if os_clock == nil then
        error( "failed to get `os.clock`, critical environment corruption detected, startup failed!" )
    end
end

gpm.StartTime = os_clock()

gpm.VERSION = version
gpm.PREFIX = "gpm@" .. version

dofile( "detour.lua" )
dofile( "std/constants.lua" )

--- [SHARED AND MENU]
---
--- Library containing functions for working with raw data. (ignoring metatables)
---@class gpm.std.raw
local raw = std.raw or {}
std.raw = raw

raw.tonumber = raw.tonumber or _G.tonumber

raw.ipairs = raw.ipairs or _G.ipairs
raw.pairs = raw.pairs or _G.pairs

raw.equal = raw.equal or _G.rawequal

local raw_get = raw.get or _G.rawget
raw.get = raw_get

raw.set = raw.set or _G.rawset
raw.len = raw.len or _G.rawlen

if raw.len == nil then

    function raw.len( value )
        return #value
    end

end

std.assert = std.assert or _G.assert
std.select = std.select or _G.select
std.print = std.print or _G.print

std.tostring = std.tostring or _G.tostring

std.getmetatable = std.getmetatable or _G.getmetatable
std.setmetatable = std.setmetatable or _G.setmetatable

std.getfenv = std.getfenv or _G.getfenv -- removed in Lua 5.2
std.setfenv = std.setfenv or _G.setfenv -- removed in Lua 5.2

std.inext = std.inext or raw.ipairs( std )
std.next = std.next or _G.next

std.xpcall = std.xpcall or _G.xpcall
std.pcall = std.pcall or _G.pcall

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU

-- client-side files
if SERVER then
    ---@diagnostic disable-next-line: undefined-field
    local AddCSLuaFile = _G.AddCSLuaFile
    if AddCSLuaFile ~= nil then
        AddCSLuaFile( "init.lua" )
        AddCSLuaFile( "detour.lua" )
        AddCSLuaFile( "engine.lua" )
        AddCSLuaFile( "database.lua" )
        AddCSLuaFile( "transport.lua" )

        AddCSLuaFile( "package/init.lua" )

        for _, file_name in raw.ipairs( _G.file.Find( "gpm/std/*", "lsv" ) ) do
            AddCSLuaFile( "std/" .. file_name )
        end
    end
end

dofile( "std/debug.lua" )
dofile( "std/debug.gc.lua" )
dofile( "std/debug.jit.lua" )

local debug = std.debug
local debug_fempty = debug.fempty
local debug_getmetatable = debug.getmetatable
local debug_getmetavalue = debug.getmetavalue

local setmetatable = std.setmetatable

local JIT_OS = std.JIT_OS

std.OSX = JIT_OS == "OSX"
std.LINUX = JIT_OS == "Linux"
std.WINDOWS = JIT_OS == "Windows"

---@class gpm.transducers
local transducers = gpm.transducers
if transducers == nil then

    --- [SHARED AND MENU]
    ---
    --- The magical table that transform glua objects into gpm objects.
    ---
    ---@class gpm.transducers : table
    transducers = {}

    setmetatable( transducers, {
        __index = function( self, value )
            local metatable = debug_getmetatable( value )
            if metatable == nil then return value end

            local fn = raw_get( self, metatable )
            if fn == nil then return value end

            return fn( value )
        end
    } )

    gpm.transducers = transducers

end

if CLIENT or SERVER then
    local glua_util = _G.util
    if glua_util ~= nil then
        local fn = glua_util.GetActivityIDByName
        if fn ~= nil then
            setmetatable( std.ACT, {
                __index = function( tbl, key )
                    local value = fn( "ACT_" .. key )
                    tbl[ key ] = value
                    return value
                end
            } )
        end
    end
end

--- [SHARED AND MENU]
---
--- Returns the length of the given value.
---
---@param value any The value to get the length of.
---@return integer length The length of the given value.
function std.len( value )
    local metatable = debug_getmetatable( value )
    if metatable == nil then
        return #value
    end

    ---@type function?
    local fn = raw_get( metatable, "__len" )
    if fn == nil then
        return #value
    else
        return fn( value )
    end
end

do

    local raw_pairs = raw.pairs

    --- [SHARED AND MENU]
    ---
    --- If `t` has a metamethod `__pairs`, calls it with t as argument and returns the first three results from the call.
    ---
    --- Otherwise, returns three values: the [next](command:extension.lua.doc?["en-us/54/manual.html/pdf-next"]) function, the table `t`, and `nil`, so that the construction
    --- ```lua
    ---     for k,v in pairs(t) do body end
    --- ```
    --- will iterate over all key–value pairs of table `t`.
    ---
    --- See function [next](command:extension.lua.doc?["en-us/54/manual.html/pdf-next"]) for the caveats of modifying the table during its traversal.
    ---
    ---
    --- [View documents](command:extension.lua.doc?["en-us/54/manual.html/pdf-pairs"])
    ---
    ---@generic T: table, K, V
    ---@param t T
    ---@return fun( table: table<K, V>, index?: K ):K, V
    ---@return T
    function std.pairs( t )
        local fn = debug_getmetavalue( t, "__pairs" )
        if fn == nil then
            return raw_pairs( t )
        else
            return fn( t )
        end
    end

end

do

    local inext = std.inext

    --- [SHARED AND MENU]
    ---
    --- Returns three values (an iterator function, the table `t`, and `0`) so that the construction
    --- ```lua
    ---     for i,v in ipairs(t) do body end
    --- ```
    --- will iterate over the key–value pairs `(1,t[1]), (2,t[2]), ...`, up to the first absent index.
    ---
    ---
    --- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-ipairs"])
    ---
    ---@generic T: table, V
    ---@param t T
    ---@return fun( table: V[], i?: integer ): integer, V
    ---@return T
    ---@return integer i
    function std.ipairs( t )
        if debug_getmetavalue( t, "__index" ) == nil then
            return inext, t, 0
        else
            local index = 0
            return function()
                index = index + 1
                local value = t[ index ]
                if value == nil then return end
                return index, value
            end, t, index
        end
    end

end

--- [SHARED AND MENU]
---
--- If `e` has a metamethod `__tonumber`, calls it with `e` and `base` as arguments and returns its result.
---
--- When called with no `base`, `tonumber` tries to convert its argument to a number. If the argument is already a number or a string convertible to a number, then `tonumber` returns this number; otherwise, it returns `fail`.
---
--- The conversion of strings can result in integers or floats, according to the lexical conventions of Lua (see [§3.1](command:extension.lua.doc?["en-us/51/manual.html/3.1"])). The string may have leading and trailing spaces and a sign.
---
---
--- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-tonumber"])
---
---@param e any
---@param base? number
---@return number?
function std.tonumber( e, base )
    local fn = debug_getmetavalue( e, "__tonumber" )
    if fn == nil then
        return nil
    else
        return fn( e, base or 10 )
    end
end

--- [SHARED AND MENU]
---
--- If `e` has a metamethod `__toboolean`, calls it with `e` as argument and returns its result.
---
--- Otherwise, returns `nil`.
---
---@param e any
---@return boolean?
function std.toboolean( e )
    if e == nil or e == false then
        return false
    end

    local fn = debug_getmetavalue( e, "__toboolean" )
    if fn == nil then
        return nil
    else
        return fn( e )
    end
end

-- Alias for lazy developers
std.tobool = std.toboolean

--- [SHARED AND MENU]
---
--- Checks if the value is valid.
---@param value any The value to check.
---@return boolean is_valid Returns `true` if the value is valid, otherwise `false`.
function std.isvalid( value )
    local fn = debug_getmetavalue( value, "__isvalid" )
    if fn == nil then
        return false
    else
        return fn( value )
    end
end

do

    --- [SHARED AND MENU]
    ---
    --- coroutine library
    ---
    --- Coroutines are similar to threads, however they do not run simultaneously.
    ---
    --- They offer a way to split up tasks and dynamically pause & resume functions.
    ---
    ---@class gpm.std.coroutine
    local coroutine = std.coroutine or {}
    std.coroutine = coroutine

    local glua_coroutine = _G.coroutine
    if glua_coroutine == nil then
        error( "coroutine library not found, critical environment corruption detected, startup failed!" )
    end

    coroutine.create = coroutine.create or glua_coroutine.create
    coroutine.resume = coroutine.resume or glua_coroutine.resume
    coroutine.running = coroutine.running or glua_coroutine.running
    coroutine.status = coroutine.status or glua_coroutine.status
    coroutine.wrap = coroutine.wrap or glua_coroutine.wrap
    coroutine.yield = coroutine.yield or glua_coroutine.yield
    coroutine.isyieldable = coroutine.isyieldable or glua_coroutine.isyieldable

    if glua_coroutine.isyieldable == nil then

        local coroutine_running = coroutine.running
        local coroutine_status = coroutine.status

        --- [SHARED AND MENU]
        ---
        --- Returns `true` when the running coroutine can yield.
        ---
        --- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-coroutine.isyieldable"])
        ---
        ---@return boolean
        ---@nodiscard
        ---@diagnostic disable-next-line: duplicate-set-field
        function coroutine.isyieldable()
            local co = coroutine_running()
            return co ~= nil and coroutine_status( co ) == "running"
        end

    end

end

-- TODO: thread manager?

---@diagnostic disable-next-line : undefined-field
local istable = _G.istable
if istable == nil then

    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Checks if the value type is a `table`.
    ---
    ---@param value any The value to check.
    ---@return boolean is_table Returns `true` if the value is a table, otherwise `false`.
    function istable( value )
        return raw_type( value ) == "table"
    end

end

local isstring, STRING, NUMBER
do

    local debug_registermetatable = debug.registermetatable
    local debug_setmetatable = debug.setmetatable

    -- nil ( 0 )
    do

        local NIL = debug_getmetatable( nil )
        if NIL == nil then
            NIL = {}
            debug_setmetatable( nil, NIL )
        end

        debug_registermetatable( "nil", NIL )

        NIL.__type = "nil"
        NIL.__typeid = 0

        ---@private
        function NIL.__toboolean()
            return false
        end

        ---@private
        function NIL.__tonumber()
            return 0
        end

        NIL.__len = NIL.__tonumber

    end

    -- boolean ( 1 )
    do

        local BOOLEAN = debug_getmetatable( false )
        if BOOLEAN == nil then
            BOOLEAN = {}
            debug_setmetatable( false, BOOLEAN )
        end

        debug_registermetatable( "boolean", BOOLEAN )

        BOOLEAN.__type = "boolean"
        BOOLEAN.__typeid = 1

        ---@private
        function BOOLEAN.__toboolean( value )
            return value
        end

        ---@private
        function BOOLEAN.__tonumber( value )
            return value == true and 1 or 0
        end

        ---@private
        function BOOLEAN.__len()
            return 1
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `boolean`.
        ---@param value any The value to check.
        ---@return boolean is_bool Returns `true` if the value is a boolean, otherwise `false`.
        function std.isboolean( value )
            return value == true or value == false
        end

    end

    -- number ( 3 )
    do

        NUMBER = debug_getmetatable( 0 )
        if NUMBER == nil then
            NUMBER = {}
            debug_setmetatable( 0, NUMBER )
        end

        debug_registermetatable( "number", NUMBER )

        NUMBER.__type = "number"
        NUMBER.__typeid = 3

        ---@private
        function NUMBER.__toboolean( value )
            return value ~= 0
        end

        ---@private
        function NUMBER.__tonumber( value )
            return value
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `number`.
        ---@param value any The value to check.
        ---@return boolean is_number Returns `true` if the value is a number, otherwise `false`.
        function std.isnumber( value )
            return debug_getmetatable( value ) == NUMBER
        end

    end

    -- string ( 4 )
    do

        STRING = debug_getmetatable( "" )
        if STRING == nil then
            STRING = {}
            debug_setmetatable( "", STRING )
        end

        debug_registermetatable( "string", STRING )

        STRING.__type = "string"
        STRING.__typeid = 4

        ---@private
        function STRING.__toboolean( value )
            return value ~= "" and value ~= "0" and value ~= "false"
        end

        STRING.__tonumber = raw.tonumber

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `string`.
        ---@param value any The value to check.
        ---@return boolean is_string Returns `true` if the value is a string, otherwise `false`.
        function isstring( value )
            return debug_getmetatable( value ) == STRING
        end

        std.isstring = isstring

    end

    -- table ( 5 )
    std.istable = istable

    -- function ( 6 )
    do

        local FUNCTION = debug_getmetatable( debug_fempty )
        if FUNCTION == nil then
            FUNCTION = {}
            debug_setmetatable( debug_fempty, FUNCTION )
        end

        debug_registermetatable( "function", FUNCTION )

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `function`.
        ---@param value any
        ---@return boolean isFunction returns true if the value is a function, otherwise false
        function std.isfunction( value )
            return debug_getmetatable( value ) == FUNCTION
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value is callable.
        ---@param value any The value to check.
        ---@return boolean is_callable Returns `true` if the value is can be called (like a function), otherwise `false`.
        function std.iscallable( value )
            local metatable = debug_getmetatable( value )
            return metatable ~= nil and ( metatable == FUNCTION or debug_getmetatable( metatable.__call ) == FUNCTION )
        end

    end

    -- thread ( 8 )
    do

        local object = std.coroutine.create( debug_fempty )

        local THREAD = debug_getmetatable( object )
        if THREAD == nil then
            THREAD = {}
            debug_setmetatable( object, THREAD )
        end

        debug_registermetatable( "thread", THREAD )

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `thread`.
        ---@param value any The value to check.
        ---@return boolean is_thread Returns `true` if the value is a thread, otherwise `false`.
        function std.isthread( value )
            return debug_getmetatable( value ) == THREAD
        end

    end

end

dofile( "std/math.lua" )
dofile( "std/math.ease.lua" )

local math = std.math

do

    local math_ceil, math_log, math_isfinite = math.ceil, math.log, math.isfinite
    local math_ln2 = math.ln2

    ---@private
    function NUMBER.__len( value )
        if math_isfinite( value ) then
            if ( value % 1 ) == 0 then
                return math_ceil( math_log( value + 1 ) / math_ln2 ) + ( value < 0 and 1 or 0 )
            elseif value >= 1.175494351E-38 and value <= 3.402823466E+38 then
                return 32
            else
                return 64
            end
        else
            return 0
        end
    end

end

dofile( "std/table.lua" )
dofile( "std/string.lua" )
dofile( "std/bit.lua" )

local string = std.string
STRING.__len = string.len

local string_format = string.format

do

    local print = std.print

    --- [SHARED AND MENU]
    ---
    --- Prints a formatted string to the console.
    ---
    --- Basically the same as `print( string.format( str, ... ) )`
    ---@param str any
    ---@param ... any
    function std.printf( str, ... )
        return print( string_format( str, ... ) )
    end

end

do

    local string_byte = string.byte

    --- [SHARED AND MENU]
    ---
    --- Returns the value of the key in a table.
    ---
    ---@param tbl table The table.
    ---@param key any The key.
    ---@return any
    function raw.index( tbl, key )
        if isstring( key ) then
            ---@cast key string

            local uint8_1, uint8_2 = string_byte( key, 1, 2 )
            if uint8_1 == 0x5F --[[ "_" ]] and uint8_2 == 0x5F --[[ "_" ]] then
                return nil
            end

        end

        return raw_get( tbl, key )
    end

end

std.SYSTEM_ENDIANNESS = std.SYSTEM_ENDIANNESS or string.byte( string.dump( std.debug.fempty ), 7 ) == 0x00

--- [SHARED AND MENU]
---
--- Converts the value to a hashable string.
---
--- The function uses the `__tohash` metafield to convert the value to a string.
---
--- If the value does not have a `__tohash` metafield, then the object address is used.
---
---@param e any The value to convert.
---@return string str The hashable string.
function std.tohash( e )
    local fn = debug_getmetavalue( e, "__tohash" )
    if fn == nil then
        return string_format( "%p", e )
    else
        return fn( e )
    end
end

-- TODO: remove me later or rewrite
do

    local iter = 1000
    local warmup = math.min( iter / 100, 100 )

    function gpm.bench( name, fn )
        for _ = 1, warmup do
            fn()
        end

        debug.gc.stop()

        local st = os_clock()
        for _ = 1, iter do
            fn()
        end

        st = os_clock() - st
        debug.gc.restart()
        std.printf( "%d iterations of %s, took %f sec.", iter, name, st )
        return st
    end

end

local table_concat = std.table.concat

do

    local coroutine_running = std.coroutine.running
    local debug_getinfo = debug.getinfo
    local string_rep = string.rep
    local tostring = std.tostring

    ---@diagnostic disable-next-line: undefined-field
    local ErrorNoHalt = _G.ErrorNoHalt or std.print

    ---@diagnostic disable-next-line: undefined-field
    local ErrorNoHaltWithStack = _G.ErrorNoHaltWithStack

    if ErrorNoHaltWithStack == nil then

        function ErrorNoHaltWithStack( message )
            if message == nil then
                message = "unknown"
            end

            local stack, size = { "\n[LUA ERROR] " .. message }, 1

            while true do
                local info = debug_getinfo( size + 1, "Sln" )
                if info == nil then break end

                size = size + 1
                stack[ size ] = table_concat( { string_rep( " ", size ), ( size - 1 ), ". ", info.name or "unknown", " - ", info.short_src or "unknown", ":", info.currentline or -1 } )
            end

            size = size + 1
            stack[ size ] = "\n"

            ErrorNoHalt( table_concat( stack, "\n", 1, size ) )
        end

    end

    -- TODO: think about throw

    --- [SHARED AND MENU]
    ---
    --- Throws a Lua error.
    ---
    ---@param message string | Error The error message to throw.
    ---@param level gpm.std.ErrorType? The error level to throw.
    function std.error( message, level )
        -- async functions support
        if not coroutine_running() then
            message = tostring( message )
        end

        -- custom gmod errors: -1, -2
        if level == -1 then
            return ErrorNoHalt( message )
        elseif level == -2 then
            return ErrorNoHaltWithStack( message )
        else
            return error( message, level )
        end
    end

end

dofile( "std/class.lua" )

do

    local type
    do

        local raw_type = raw.type

        --- [SHARED AND MENU]
        ---
        --- Returns a string representing the name of the type of the passed object.
        ---
        ---@param value any The value to get the type of.
        ---@return string type_name The type name of the given value.
        function type( value )
            return debug_getmetavalue( value, "__type" ) or raw_type( value )
        end

        std.type = type

    end

    do

        local debug_getinfo = debug.getinfo

        --- [SHARED AND MENU]
        ---
        --- Validates the type of the argument and returns a boolean and an error message.
        ---
        ---@param value any The argument value.
        ---@param arg_num any The argument number/key.
        ---@param expected_type "string" | "number" | "boolean" | "table" | "function" | "thread" | "any" | string The expected type name.
        ---@return boolean ok Returns `true` if the argument is of the expected type, `false` otherwise.
        ---@return string? msg The error message.
        function std.arg( value, arg_num, expected_type )
            local got = type( value )
            if got == expected_type or expected_type == "any" then
                return true, nil
            else
                return false, string_format( "bad argument #%s to \'%s\' ('%s' expected, got '%s')", arg_num, debug_getinfo( 2, "n" ).name or "unknown", expected_type, got )
            end
        end

    end

end

--- [SHARED AND MENU]
---
--- The pack library that packs/unpacks types as binary.
---
---@class gpm.std.pack
std.pack = std.pack or {}

dofile( "std/pack.bytes.lua" )
dofile( "std/pack.bits.lua" )
dofile( "std/pack.lua" )

dofile( "std/math.classes.lua" )

dofile( "std/structures.lua" )
dofile( "std/futures.lua" )
dofile( "std/time.lua" )

dofile( "std/version.lua" )
dofile( "std/bigint.lua" )

dofile( "engine.lua" )

dofile( "std/game.lua" )

--- [SHARED AND MENU]
---
--- The encoding/decoding libraries.
---
---@class gpm.std.encoding
std.encoding = std.encoding or {}

dofile( "std/encoding.base16.lua" )
dofile( "std/encoding.base32.lua" )
dofile( "std/encoding.base64.lua" )
dofile( "std/encoding.percent.lua" )

dofile( "std/encoding.utf8.lua" )
dofile( "std/encoding.unicode.lua" )
dofile( "std/encoding.punycode.lua" )

dofile( "std/encoding.json.lua" )
dofile( "std/encoding.vdf.lua" )

--- [SHARED AND MENU]
---
--- The checksum calculation libraries.
---
---@class gpm.std.checksum
std.checksum = std.checksum or {}

dofile( "std/checksum.crc.lua" )
dofile( "std/checksum.adler.lua" )
dofile( "std/checksum.fletcher.lua" )

--- [SHARED AND MENU]
---
--- The compression libraries.
---
---@class gpm.std.compress
std.compress = std.compress or {}

dofile( "std/compress.deflate.lua" )
dofile( "std/compress.lzma.lua" )
dofile( "std/compress.lzw.lua" )

--- [SHARED AND MENU]
---
--- The hash libraries.
---
---@class gpm.std.hash
std.hash = std.hash or {}

dofile( "std/hash.fnv.lua" )
dofile( "std/hash.md5.lua" )
dofile( "std/hash.sha1.lua" )
dofile( "std/hash.sha256.lua" )

--- [SHARED AND MENU]
---
--- The crypto libraries.
---
---@class gpm.std.crypto
std.crypto = std.crypto or {}

dofile( "std/crypto.chacha20.lua" )
dofile( "std/crypto.hmac.lua" )
dofile( "std/crypto.pbkdf2.lua" )

dofile( "std/utils.lua" )
dofile( "std/uuid.lua" )

dofile( "std/color.lua" )
dofile( "std/timer.lua" )
dofile( "std/hook.lua" )
dofile( "std/url.lua" )

do

    local Color = std.Color
    local scheme = Color.scheme

    scheme.white = Color( 255, 255, 255, 255 )
    scheme.black = Color( 0, 0, 0, 255 )

    scheme.red = Color( 255, 0, 0, 255 )
    scheme.green = Color( 0, 255, 0, 255 )
    scheme.blue = Color( 0, 0, 255, 255 )

    scheme.yellow = Color( 255, 255, 0, 255 )
    scheme.cyan = Color( 0, 255, 255, 255 )
    scheme.magenta = Color( 255, 0, 255, 255 )

    scheme.gray = Color( 128, 128, 128, 255 )

    scheme.info = Color( 70, 135, 255 )
    scheme.warn = Color( 255, 130, 90 )
    scheme.error = Color( 250, 55, 40 )
    scheme.debug = Color( 0, 200, 150 )

    scheme.text_primary = Color( 200 )
    scheme.text_secondary = Color( 150 )

    scheme.realm_menu = Color( 75, 175, 80 )
    scheme.realm_client = Color( 225, 170, 10 )
    scheme.realm_server = Color( 5, 170, 250 )

end

if gpm.TickTimer0_05 == nil then
    local timer = std.Timer( 0.05, -1, gpm.PREFIX .. "::TickTimer0_05" )
    gpm.TickTimer0_05 = timer
    timer:start()
end

if gpm.TickTimer0_1 == nil then
    local timer = std.Timer( 0.1, -1, gpm.PREFIX .. "::TickTimer0_1" )
    gpm.TickTimer0_1 = timer
    timer:start()
end

if gpm.TickTimer0_25 == nil then
    local timer = std.Timer( 0.25, -1, gpm.PREFIX .. "::TickTimer0_25" )
    gpm.TickTimer0_25 = timer
    timer:start()
end

if gpm.TickTimer1 == nil then
    local timer = std.Timer( 1, -1, gpm.PREFIX .. "::TickTimer1" )
    gpm.TickTimer1 = timer
    timer:start()
end

dofile( "std/console.lua" )
dofile( "std/console.logger.lua")

local console_Variable = std.console.Variable

if SERVER then
    -- https://github.com/Facepunch/garrysmod-requests/issues/2793
    local variable = console_Variable.get( "sv_defaultdeployspeed", "number" )
    if variable ~= nil and variable.value == 4 then
        variable.value = 1
    end
end

local logger = std.console.Logger( {
    title = gpm.PREFIX,
    color = std.Color( 180, 180, 255 ),
    interpolation = false
} )

gpm.Logger = logger

-- dofile( "std/message.lua" )

local std_metatable = getmetatable( std )

if std_metatable == nil then

    ---@type table<string, fun( self: table ): any>
    local indexes = {}

    ---@type table<string, fun( self: table, value: any )>
    local newindexes = {}

    do

        local raw_set = raw.set

        std_metatable = {
            __indexes = indexes,
            __index = function( self, key )
                local fn = indexes[ key ]
                if fn ~= nil then
                    return fn( self )
                end
            end,
            __newindexes = newindexes,
            __newindex = function( self, key, value )
                local fn = newindexes[ key ]

                if fn == nil then
                    raw_set( self, key, value )
                    return
                end

                value = fn( self, value )

                if value ~= nil then
                    raw_set( self, key, value )
                end
            end
        }

        std.setmetatable( std, std_metatable )

    end

    do

        local developer_mode = 1

        local developer = std.console.Variable.get( "developer", "number" )
        if developer ~= nil then
            developer:attach( function( _, value )
                ---@cast value number
                developer_mode = math.floor( value )
            end, "gpm::std" )

            ---@diagnostic disable-next-line: param-type-mismatch
            developer_mode = math.floor( developer.value )
        end

        ---@private
        function indexes.DEVELOPER()
            return developer_mode
        end

    end

    ---@private
    function indexes:DST_TZ()
        if self.DST then
            return self.TZ + 1
        else
            return self.TZ
        end
    end

    if CLIENT then

        local time_elapsed = std.time.elapsed

        local frame_time = 0
        local fps = 0

        ---@private
        function indexes.FPS()
            return fps
        end

        ---@private
        function indexes.FRAME_TIME()
            return frame_time
        end

        local last_pre_render = 0

        gpm.engine.hookCatch( "PreRender", function()
            local elapsed_time = time_elapsed( nil, true )

            if last_pre_render ~= 0 then
                frame_time = elapsed_time - last_pre_render
                fps = 1 / frame_time
            end

            last_pre_render = elapsed_time
        end, 1 )

    end

end

dofile( "std/file.path.lua" )
dofile( "std/file.lua" )

-- dofile( "std/error.lua" ) -- TODO: deprecated

dofile( "std/audio_stream.lua" )

dofile( "package/init.lua" )

do

    local setTimeout = std.setTimeout
    local futures = std.futures

    --- [SHARED AND MENU]
    ---
    --- Puts current thread to sleep for given amount of seconds.
    ---
    ---@see gpm.std.futures.pending
    ---@see gpm.std.futures.wakeup
    ---@async
    ---@param seconds number
    function std.sleep( seconds )
        local co = futures.running()
        if co == nil then
            error( "sleep cannot be called from main thread", 2 )
        end

        ---@cast co thread

        setTimeout( function()
            futures.wakeup( co )
        end, seconds )

        return futures.pending()
    end

end

-- Welcome message
do

    local name

    local cvar = std.console.Variable.get( SERVER and "hostname" or "name", "string" )
    if cvar == nil then
        name = "stranger"
    else
        ---@type string
        name = cvar.value
        if string.isEmpty( name ) or name == "unnamed" then
            name = "stranger"
        end
    end

    local splashes = {
        "eW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==",
        "I'm not here to tell you how great I am!",
        "We will have a great Future together.",
        "I'm here to show you how great I am!",
        "Millions of pieces without a tether",
        "Why are we always looking for more?",
        "Never forget to finish your Task's!",
        "T2gsIHlvdSdyZSBhIHNtYXJ0IG9uZS4=",
        "Take it in and breathe the light",
        "Don't worry, " .. name .. " :>",
        "Big Brother is watching you",
        "As we build it once again",
        "I'll make you a promise.",
        "Flying over rooftops...",
        "Hello, " .. name .. "!",
        "We need more packages!",
        "Play SOMA sometime;",
        "Where's fireworks!?",
        "Looking For More ♪",
        "I'm watching you.",
        "Faster than ever.",
        "Love Wins Again ♪",
        "Made with love <3",
        "Blazing fast ☄",
        "Ancient Tech ♪",
        "Here For You ♪",
        "Good Enough ♪",
        "MAKE A MOVE ♪",
        "v" .. version,
        "Hello World!",
        "Star Glide ♪",
        "Once Again ♪",
        "Without Us ♪",
        "Data Loss ♪",
        "Sandblast ♪",
        "Now on LLS!",
        "That's me!",
        "I see you.",
        "Light Up ♪",
        "Majesty ♪",
        "Eat Me ♪"
    }

    local count = #splashes + 1
    splashes[ count ] = "Wow, here more " .. ( count - 1 ) .. " splashes!"

    local splash = splashes[ math.random( 1, count ) ]
    for i = 1, ( 25 - #splash ) * 0.5 do
        if i % 2 == 1 then
            splash = splash .. " "
        end

        splash = " " .. splash
    end

    std.printf( "\n                                     ___          __            \n                                   /'___`\\      /'__`\\          \n     __    _____     ___ ___      /\\_\\ /\\ \\    /\\ \\/\\ \\         \n   /'_ `\\ /\\ '__`\\ /' __` __`\\    \\/_/// /__   \\ \\ \\ \\ \\        \n  /\\ \\L\\ \\\\ \\ \\L\\ \\/\\ \\/\\ \\/\\ \\      // /_\\ \\ __\\ \\ \\_\\ \\   \n  \\ \\____ \\\\ \\ ,__/\\ \\_\\ \\_\\ \\_\\    /\\______//\\_\\\\ \\____/   \n   \\/___L\\ \\\\ \\ \\/  \\/_/\\/_/\\/_/    \\/_____/ \\/_/ \\/___/    \n     /\\____/ \\ \\_\\                                          \n     \\_/__/   \\/_/                %s                        \n\n  GitHub: https://github.com/Pika-Software\n  Discord: https://discord.gg/Gzak99XGvv\n  Website: https://p1ka.eu\n  Developers: Pika Software\n  License: MIT\n", splash )

end

if math.randomseed == 0 then
    math.randomseed = std.time.now( "ms", false )
    logger:info( "Random seed was re-synchronized with milliseconds since the Unix epoch." )
end

dofile( "std/sqlite.lua" )
dofile( "database.lua" )

local loadbinary
do

    local require = _G.require or debug.fempty
    local file_exists = std.file.exists

    local isEdge = std.JIT_VERSION_INT ~= 20004
    local is32 = std.JIT_ARCH == "x86"

    local head = "/garrysmod/lua/bin/gm" .. ( ( CLIENT and not MENU ) and "cl" or "sv" ) .. "_"
    local tail = "_" .. ( { "osx64", "osx", "linux64", "linux", "win64", "win32" } )[ ( JIT_OS == "Windows" and 4 or 0 ) + ( JIT_OS == "Linux" and 2 or 0 ) + ( is32 and 1 or 0 ) + 1 ] .. ".dll"

    --- [SHARED AND MENU]
    ---
    --- Checks if a binary module is installed and returns its path.
    ---
    ---@param name string The binary module name.
    ---@return boolean installed `true` if the binary module is installed, `false` otherwise.
    ---@return string path The absolute path to the binary module.
    local function lookupbinary( name )
        if string.isEmpty( name ) then
            return false, ""
        end

        local filePath = head .. name .. tail
        if file_exists( filePath ) then
            return true, "/" .. filePath
        end

        if isEdge and is32 and tail == "_linux.dll" then
            filePath = head .. name .. "_linux32.dll"
            if file_exists( filePath ) then
                return true, "/" .. filePath
            end
        end

        return false, "/" .. filePath
    end

    std.lookupbinary = lookupbinary

    local sv_allowcslua = SERVER and std.console.Variable.get( "sv_allowcslua", "boolean" )

    --- [SHARED AND MENU]
    ---
    --- Loads a binary module
    ---@param name string The binary module name, for example: "chttp"
    ---@return boolean success true if the binary module is installed
    ---@protected
    function loadbinary( name )
        if lookupbinary( name ) then
            if sv_allowcslua ~= nil and sv_allowcslua.value then
                sv_allowcslua.value = false
            end

            require( name )
            return true
        end

        return false
    end

    std.loadbinary = loadbinary

end

-- https://github.com/willox/gmbc
if loadbinary( "gmbc" ) then
    logger:info( "'gmbc' was connected as bytecode compiler, binary code compilation avaliable." )
end

do

    local getfenv, setfenv = std.getfenv, std.setfenv
    ---@diagnostic disable-next-line: undefined-field
    local gmbc_load_bytecode = _G.gmbc_load_bytecode
    local CompileString = _G.CompileString
    local file_read = std.file.read
    local pcall = std.pcall

    --- [SHARED AND MENU]
    ---
    --- Loads a string as
    --- a lua code chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param lua_code string The lua code chunk.
    ---@param chunk_name string | nil The lua code chunk name.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    local function loadstring( lua_code, chunk_name, env )
        local fn = CompileString( lua_code, chunk_name or "=(loadstring)", false )
        if fn == nil then
            return nil, "lua code compilation failed"
        elseif isstring( fn ) then
            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast fn string
            return nil, fn
        else
            setfenv( fn, env or getfenv( 2 ) )
            return fn
        end
    end

    std.loadstring = loadstring

    --- [SHARED AND MENU]
    ---
    --- Loads a string as
    --- a bytecode chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param bytecode string The luajit bytecode chunk.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    local function loadbytecode( bytecode, env )
        local success, result = pcall( gmbc_load_bytecode, bytecode )
        if success then
            setfenv( result, env or getfenv( 2 ) )
            return result, nil
        else
            return nil, result
        end
    end

    std.loadbytecode = loadbytecode

    --- [SHARED AND MENU]
    ---
    --- Loads a file as
    --- a lua code chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param file_path string The path to the file to read.
    ---@param is_bytecode boolean If `true`, the file will be loaded as a bytecode chunk.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    function std.loadfile( file_path, is_bytecode, env )
        local success, content = pcall( file_read, file_path )
        if success then
            if env == nil then
                env = getfenv( 2 )
            end

            if is_bytecode then
                return loadbytecode( content, env )
            else
                return loadstring( content, file_path, env )
            end
        else
            return nil, content
        end
    end

end

do

    local loadstring = std.loadstring
    local math_floor = math.floor
    local math_max = math.max
    local arg = std.arg

    local empty_env = {}

    --- [SHARED AND MENU]
    ---
    --- Creates a function that accepts a variable
    --- number of arguments and returns them in
    --- the order of the specified indices.
    ---
    --- | `junction(...)` call | `fjn(...)` call | result `...` |
    --- | ---------------------|-----------------|--------------|
    --- | `junction(1)`        | `(A, B, C)`     | `A`          |
    --- | `junction(2)`        | `(A, B, C)`     | `B`          |
    --- | `junction(3)`        | `(A, B, C)`     | `C`          |
    --- | `junction(2, 1)`     | `(A, B, C)`     | `B, A`       |
    --- | `junction(3, 1, 2)`  | `(X, Y, Z)`     | `Z, X, Y`    |
    ---
    ---@param ... integer The indices of arguments to return.
    ---@return fun( ... ): ... fjn
    function std.junction( ... )
        local out_arg_count = std.select( '#', ... )
        local out_args = { ... }

        local in_arg_count = 0

        for i = 1, out_arg_count, 1 do
            local value = out_args[ i ]
            local valid, err_msg = arg( value, i, "number" )
            if valid then
                out_args[ i ] = math_floor( value )
                in_arg_count = math_max( in_arg_count, value )
            else
                error( err_msg, 2 )
            end
        end

        local locals, local_count = {}, 0

        for i = 1, in_arg_count, 1 do
            local_count = local_count + 1
            locals[ local_count ] = "arg" .. i
        end

        local returns, return_count = {}, 0

        for i = 1, out_arg_count, 1 do
            return_count = return_count + 1
            returns[ return_count ] = "arg" .. out_args[ i ]
        end

        local fn, err_msg = loadstring( "local " .. table_concat( locals, ",", 1, local_count ) .. " = ...\r\nreturn " .. table_concat( returns, ",", 1, return_count ), "junction", empty_env )
        if fn == nil then
            error( err_msg, 2 )
        end

        return fn
    end

end

--[[

    TODO:

    FileReader     FileWriter       __init( file_path: string )
    file.Reader            file.Writer

    NetworkReader  NetworkWriter    __init( network_name: string )
    network.Reader         network.Writer
    net.Reader             net.Writer

    network.Message
    NetworkMessage
    net.Message

    net.MessageReader       net.MessageWriter

]]

dofile( "std/http.lua" )
dofile( "std/http.github.lua" )

dofile( "std/steam.lua" )
dofile( "std/steam.identifier.lua" )
dofile( "std/steam.workshop.lua" )

dofile( "std/addon.lua" )

if std.CLIENT_MENU then
    dofile( "std/window.lua" )
    dofile( "std/menu.lua" )
    dofile( "std/client.lua" )
    dofile( "std/render.lua" )
end

if _G.system ~= nil then

    local glua_system = _G.system

    std_metatable.__indexes.SYSTEM_COUNTRY = glua_system.GetCountry or function() return "gb" end

    if glua_system.BatteryPower ~= nil then

        local system_BatteryPower = glua_system.BatteryPower

        local battery_power = 0

        local function update_battery()
            if battery_power ~= system_BatteryPower() then
                battery_power = system_BatteryPower()
                if battery_power == 255 then
                    std.HAS_BATTERY = false
                    std.BATTERY_LEVEL = 100
                else
                    std.HAS_BATTERY = true
                    std.BATTERY_LEVEL = battery_power
                end
            end
        end

        update_battery()

        gpm.TickTimer1:attach( update_battery, "gpm::battery" )

    end

    if std.CLIENT_MENU then

        local system_HasFocus = glua_system.HasFocus
        if system_HasFocus ~= nil then

            ---@class gpm.std.window
            ---@field focus boolean `true` if the game's window has focus, `false` otherwise.
            local window = std.window

            local has_focus = system_HasFocus()
            window.focus = has_focus

            gpm.TickTimer0_05:attach( function()
                if has_focus ~= system_HasFocus() then
                    has_focus = not has_focus
                    window.focus = has_focus
                end
            end, "gpm::window_focus" )

        end

    end

end

dofile( "std/server.lua" )
dofile( "std/level.lua" )

if coroutine.wait == nil then

    local server_getUptime = std.server.getUptime

    ---@class gpm.std.coroutine
    local coroutine = std.coroutine
    local coroutine_yield = coroutine.yield

    ---@async
    function coroutine.wait( seconds )
        local endtime = server_getUptime() + seconds
        while true do
            if endtime < server_getUptime() then return end
            coroutine_yield()
        end
    end

end

if CLIENT or SERVER then
    dofile( "std/physics.lua" )
    dofile( "std/entity.lua" )
    dofile( "std/player.lua" )
    -- dofile( "std/network.lua" )
end

dofile( "std/input.lua" )

if _G.TYPE_COUNT ~= 44 then
    logger:warn( "Global TYPE_COUNT mismatch, data corruption suspected. (" .. std.tostring( _G.TYPE_COUNT or "missing" ) .. " ~= 44)"  )
end

if _G._VERSION ~= "Lua 5.1" then
    logger:warn( "Lua version changed, possible unpredictable behavior. (" .. std.tostring( _G._VERSION or "unknown" ) .. ")" )
end

if CLIENT or SERVER then
    dofile( "transport.lua" )
end

logger:info( "Start-up time: %.2f ms.", ( os_clock() - gpm.StartTime ) * 1000 )

do

    logger:info( "Preparing the database to begin migration..." )
    local start_time = os_clock()

    local db = gpm.db
    db.optimize()
    db.prepare()
    db.migrate( "initial file table" )

    logger:info( "Migration completed, time spent: %.2f ms.", ( os_clock() - start_time ) * 1000 )

end

if CLIENT or SERVER then
    gpm.transport.startup()
end

logger:info( "Preparation of the factory, loading of packages will start soon." )

-- TODO: package manager start-up ( aka package loading )

do
    local start_time = os_clock()
    debug.gc.collect()
    logger:info( "Clean-up time: %.2f ms.", ( os_clock() - start_time ) * 1000 )
end

-- TODO: put https://wiki.facepunch.com/gmod/Global.IsFirstTimePredicted somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.RecipientFilter somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.ClientsideScene somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.Path somewhere
-- TODO: put https://wiki.facepunch.com/gmod/util.ScreenShake somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.AddonMaterial somewhere

-- TODO: https://github.com/toxidroma/class-war

-- TODO: NetTable class

-- TODO: Write "VideoRecorder" class ( https://wiki.facepunch.com/gmod/video.Record )

--[[

    TODO: return missing functions

    -- dofile - missing in glua
    -- require - broken in glua

]]

-- TODO: put https://wiki.facepunch.com/gmod/Global.SuppressHostEvents somewhere
-- TODO: https://github.com/Nak2/NikNaks/blob/main/lua/niknaks/modules/sh_model_extended.lua
-- TODO: https://github.com/Nak2/NikNaks/blob/main/lua/niknaks/modules/sh_enums.lua

-- TODO: plugins support

--[[

    -- TODO

    concept

    local utf8 = require( "utf8" )
    local custom_utf8 = require( "package.utf8" )

    local ... = dofile( "./path.to.lua", ... ) -- as compile file

]]
