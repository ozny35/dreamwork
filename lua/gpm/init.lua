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
    gpm = {}; _G.gpm = gpm
end

---@diagnostic disable-next-line: undefined-field
local include = gpm.dofile or _G.include or _G.dofile
gpm.dofile = include

---@diagnostic disable-next-line: undefined-field
local getTime = _G.SysTime or _G.os.time
gpm.StartTime = getTime()

gpm.VERSION = version
gpm.PREFIX = "gpm@" .. version

if gpm.detour == nil then
    gpm.detour = include( "detour.lua" )
end

--- object transducers
---@class gpm.transducers
local transducers = {}
gpm.transducers = transducers

--- gpm standard environment
---@class gpm.std
---@field MENU boolean `true` if code is running on the menu, `false` otherwise.
---@field CLIENT boolean `true` if code is running on the client, `false` otherwise.
---@field SERVER boolean `true` if code is running on the server, `false` otherwise.
---@field SHARED boolean `true` if code is running on the client or server, `false` otherwise.
---@field CLIENT_MENU boolean `true` if code is running on the client or menu, `false` otherwise.
---@field CLIENT_SERVER boolean `true` if code is running on the client or server, `false` otherwise.
---@field DEVELOPER integer A cached value of `developer` console variable.
---@field OSX boolean `true` if the game is running on OSX.
---@field LINUX boolean `true` if the game is running on Linux.
---@field WINDOWS boolean `true` if the game is running on Windows.
---@field BRANCH string A variable containing a string indicating which (Beta) Branch of the game you are using.
---@field SINGLEPLAYER boolean `true` if code is running on a single player game, `false` otherwise.
---@field DEDICATED boolean `true` if code is running on a dedicated server, `false` otherwise.
---@field GAMEMODE string A variable containing the name of the active gamemode.
local std = gpm.std
if std == nil then
    std = include( "std/constants.lua" )
    gpm.std = std
end

--- [SHARED AND MENU]
---
--- Library containing functions for working with raw data. (ignoring metatables)
---@class gpm.std.raw
local raw = std.raw
if raw == nil then
    raw = {
        tonumber = _G.tonumber,
        equal = _G.rawequal,
        ipairs = _G.ipairs,
        pairs = _G.pairs,
        error = _G.error,
        get = _G.rawget,
        set = _G.rawset,
        type = _G.type,
        len = _G.rawlen or function( value )
            return #value
        end
    }

    std.raw = raw
end

std.assert = std.assert or _G.assert
std.select = std.select or _G.select

std.tostring = std.tostring or _G.tostring

std.getmetatable = std.getmetatable or _G.getmetatable
std.setmetatable = std.setmetatable or _G.setmetatable

std.getfenv = std.getfenv or _G.getfenv -- removed in Lua 5.2
std.setfenv = std.setfenv or _G.setfenv -- removed in Lua 5.2

std.inext = std.inext or raw.ipairs( std )
std.next = std.next or _G.next

std.xpcall = std.xpcall or _G.xpcall
std.pcall = std.pcall or _G.pcall

local raw_get = raw.get

-- jit library
local jit = std.jit or _G.jit
std.jit = jit

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU

-- client-side files
if SERVER then
    ---@diagnostic disable-next-line: undefined-field
    local AddCSLuaFile = _G.AddCSLuaFile
    if AddCSLuaFile ~= nil then
        AddCSLuaFile( "database.lua" )
        AddCSLuaFile( "detour.lua" )
        AddCSLuaFile( "engine.lua" )

        AddCSLuaFile( "package/init.lua" )

        for _, file_name in raw.ipairs( _G.file.Find( "gpm/std/*", "lsv" ) ) do
            AddCSLuaFile( "std/" .. file_name )
        end
    end
end

---@class gpm.std.debug
local debug = include( "std/debug.lua" )
std.debug = debug

debug.gc = include( "std/garbage-collection.lua" )

local debug_getmetatable = debug.getmetatable

std.setmetatable( transducers, {
    __index = function( self, value )
        local metatable = debug_getmetatable( value )
        if metatable == nil then return value end

        local fn = raw_get( self, metatable )
        if fn == nil then return value end

        return fn( value )
    end
} )

--- [SHARED AND MENU]
---
--- Returns the length of the given value.
---@param value any The value to get the length of.
---@return integer length The length of the given value.
function std.len( value )
    local metatable = debug_getmetatable( value )
    if metatable == nil then return #value end

    local fn = raw_get( metatable, "__len" )
    if fn == nil then return #value end

    return fn( value )
end

do

    local raw_pairs = raw.pairs

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator `next` for a for loop that will return the values of the specified table in an arbitrary order.
    ---@param tbl table The table to iterate over.
    ---@return function iter The iterator function.
    ---@return table tbl The table being iterated over.
    ---@return any prev The previous key in the table (by default `nil`).
    function std.pairs( tbl )
        local metatable = debug_getmetatable( tbl )
        return ( metatable ~= nil and metatable.__pairs or raw_pairs )( tbl )
    end

end

do

    local debug_getmetavalue = debug.getmetavalue
    local raw_ipairs = raw.ipairs

    --- [SHARED AND MENU]
    ---
    --- Returns a [Stateless Iterator](https://www.lua.org/pil/7.3.html) for a [Generic For Loops](https://www.lua.org/pil/4.3.5.html), to return ordered key-value pairs from a table.
    ---
    --- This will only iterate though <b>numerical keys</b>, and these must also be sequential; starting at 1 with no gaps.
    ---
    ---@param tbl table The table to iterate over.
    ---@return function iter The iterator function.
    ---@return table lst The table being iterated over.
    ---@return number index The origin index =0.
    function std.ipairs( tbl )
        if debug_getmetavalue( tbl, "__index" ) == nil then
            return raw_ipairs( tbl )
        else
            local index = 0
            return function()
                index = index + 1
                local value = tbl[ index ]
                if value == nil then return end
                return index, value
            end, tbl, index
        end
    end

end

--- [SHARED AND MENU]
---
--- Attempts to convert the value to a number.
---@param value any The value to convert.
---@param base? integer The base used in the string. Can be any integer between 2 and 36, inclusive. (Default: 10)
---@return number num The numeric representation of the value with the given base, or `nil` if the conversion failed.
function std.tonumber( value, base )
    local metatable = debug_getmetatable( value )
    return metatable ~= nil and metatable.__tonumber( value, base ) or 0
end

--- [SHARED AND MENU]
---
--- Attempts to convert the value to a boolean.
---@param value any The value to convert.
---@return boolean bool The boolean representation of the value, or `false` if the conversion failed.
function std.toboolean( value )
    if value == nil or value == false then return false end

    local metatable = debug_getmetatable( value )
    return metatable ~= nil and metatable.__tobool( value ) or true
end

std.tobool = std.toboolean

--- [SHARED AND MENU]
---
--- Checks if the value is valid.
---@param value any The value to check.
---@return boolean is_valid Returns `true` if the value is valid, otherwise `false`.
function std.isvalid( value )
    local metatable = debug_getmetatable( value )
    return ( metatable and metatable.__isvalid and metatable.__isvalid( value ) ) == true
end

--- [SHARED AND MENU]
---
--- coroutine library
--- Coroutines are similar to threads, however they do not run simultaneously.
---
--- They offer a way to split up tasks and dynamically pause & resume functions.
local coroutine
do

    local CurTime = _G.CurTime
    local glua_coroutine = _G.coroutine
    local coroutine_yield = glua_coroutine.yield

    ---@class gpm.std.coroutine
    coroutine = {
        -- lua
        create = glua_coroutine.create,
        ---@diagnostic disable-next-line: deprecated
        isyieldable = glua_coroutine.isyieldable or function() return true end,
        resume = glua_coroutine.resume,
        running = glua_coroutine.running,
        status = glua_coroutine.status,
        wrap = glua_coroutine.wrap,
        yield = coroutine_yield
    }

    ---@async
    function coroutine.wait( seconds )
        local endtime = CurTime() + seconds
        while true do
            if endtime < CurTime() then return end
            coroutine_yield()
        end
    end

    std.coroutine = coroutine

end

local istable = _G.istable
if istable == nil then

    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Checks if the value type is a `table`.
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

        function NIL.__tobool()
            return false
        end

        function NIL.__tonumber()
            return 0
        end

        NIL.__bitcount = NIL.__tonumber

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

        function BOOLEAN.__tobool( value )
            return value
        end

        function BOOLEAN.__tonumber( value )
            return value == true and 1 or 0
        end

        function BOOLEAN.__bitcount()
            return 1
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `boolean`.
        ---@param value any The value to check.
        ---@return boolean is_bool Returns `true` if the value is a boolean, otherwise `false`.
        function std.isboolean( value )
            return debug_getmetatable( value ) == BOOLEAN
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

        function NUMBER.__tobool( value )
            return value ~= 0
        end

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

        function STRING.__tobool( value )
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

        local object = debug.fempty

        local FUNCTION = debug_getmetatable( object )
        if FUNCTION == nil then
            FUNCTION = {}
            debug_setmetatable( object, FUNCTION )
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

        local object = std.coroutine.create( debug.fempty )

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

---@class gpm.std.math
local math = include( "std/math.lua" )
math.ease = include( "std/math.ease.lua" )
std.math = math

do

    local math_ceil, math_log, math_ln2, math_isfinite = math.ceil, math.log, math.ln2, math.isfinite

    function NUMBER.__bitcount( value )
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

--- [SHARED AND MENU]
---
--- string library
---@class gpm.std.string
local string = include( "std/string.lua" )
std.string = string

local string_format = string.format
local string_len = string.len

function STRING.__bitcount( value )
    return string_len( value ) * 8
end

local print = std.print or _G.print
std.print = print

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

--- [SHARED AND MENU]
---
--- bit library
std.bit = include( "std/bit.lua" )

--- [SHARED AND MENU]
---
--- os library
---@class gpm.std.os
local os = include( "std/os.lua" )
std.os = os

-- TODO: remove me later or rewrite
do

    local iter = 1000
    local warmup = math.min( iter / 100, 100 )

    function gpm.bench( name, fn )
        for _ = 1, warmup do
            fn()
        end

        debug.gc.stop()

        local st = getTime()
        for _ = 1, iter do
            fn()
        end

        st = getTime() - st
        debug.gc.restart()
        std.printf( "%d iterations of %s, took %f sec.", iter, name, st )
        return st
    end

end

---@class gpm.std.table
local table = include( "std/table.lua" )
std.table = table

local table_concat = table.concat

do

    local coroutine_running = coroutine.running
    local debug_getinfo = debug.getinfo
    local string_rep = string.rep
    local tostring = std.tostring
    local raw_error = raw.error

    ---@diagnostic disable-next-line: undefined-field
    local ErrorNoHalt = _G.ErrorNoHalt or print

    ---@diagnostic disable-next-line: undefined-field
    local ErrorNoHaltWithStack = _G.ErrorNoHaltWithStack

    if ErrorNoHaltWithStack == nil then

        function ErrorNoHaltWithStack( message )
            if message == nil then message = "unknown" end

            local stack, size = { "\n[ERROR] " .. message }, 1

            while true do
                local info = debug_getinfo( size + 1, "Sln" )
                if info == nil then break end

                size = size + 1
                stack[ size ] = table_concat( { string_rep( " ", size ), ( size - 1 ), ". ", info.name or "unknown", " - ", info.short_src or "unknown", ":", info.currentline or -1 } )
            end

            size = size + 1
            stack[ size ] = "\n"

            return ErrorNoHalt( table_concat( stack, "\n", 1, size ) )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Throws a Lua error.
    ---@param message string | Error: The error message to throw.
    ---@param level gpm.std.ErrorType?: The error level to throw.
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
            return raw_error( message, level )
        end
    end

end

local type
do

    local debug_getinfo = debug.getinfo
    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Returns a string representing the name of the type of the passed object.
    ---@param value any The value to get the type of.
    ---@return string type_name The type name of the given value.
    function type( value )
        local metatable = debug_getmetatable( value )
        if metatable ~= nil then
            local name = raw_get( metatable, "__type" )
            if isstring( name ) then return name end
        end

        return raw_type( value )
    end

    std.type = type

    --- [SHARED AND MENU]
    ---
    --- Validates the type of the argument and returns a boolean and an error message.
    ---@param value any The argument value.
    ---@param arg_num number The argument number.
    ---@param expected_type string The expected type name.
    ---@return boolean ok Returns `true` if the argument is of the expected type, `false` otherwise.
    ---@return string? msg The error message.
    function std.arg( value, arg_num, expected_type )
        local got = type( value )
        if got == expected_type or expected_type == "any" then
            return true, nil
        else
            return false, string_format( "bad argument #%d to \'%s\' ('%s' expected, got '%s')", arg_num, debug_getinfo( 2, "n" ).name or "unknown", expected_type, got )
        end
    end

end

string.utf8 = include( "std/string.utf8.lua" )
gpm.engine = include( "engine.lua" )

local class = include( "std/class.lua" )
std.class = class

include( "std/structures.lua" )

-- symbol class
do

    local function __tostring( self )
        ---@diagnostic disable-next-line: param-type-mismatch
        return raw_get( debug_getmetatable( self ), "__type" )
    end

    local debug_newproxy = debug.newproxy

    ---@class gpm.std.Symbol : userdata
    ---@alias Symbol gpm.std.Symbol

    --- [SHARED AND MENU]
    ---
    --- Creates a new symbol.
    ---@param name string The name of the symbol.
    ---@return Symbol obj The new symbol.
    function std.Symbol( name )
        ---@class gpm.std.Symbol
        local obj = debug_newproxy( true )
        local metatable = debug_getmetatable( obj )
        metatable.__type = string_format( "Symbol: %p ['%s']", obj, name )
        metatable.__tostring = __tostring
        return obj
    end

end

std.Hook = include( "std/hook.lua" )
std.Timer = include( "std/timer.lua" )

include( "package/init.lua" )

include( "std/file.lua" )

local Color = include( "std/color.lua" )
std.Color = Color

--- [SHARED AND MENU]
---
--- The white color object (255, 255, 255, 255).
std.color_white = Color( 255, 255, 255, 255 )

local futures = include( "std/futures.lua" )
std.futures = futures

do

    local futures_running = futures.running
    local Timer_wait = std.Timer.wait

    --- Puts current thread to sleep for given amount of seconds.
    ---
    ---@see gpm.std.futures.pending
    ---@see gpm.std.futures.wakeup
    ---@async
    ---@param seconds number
    ---@return nil
    function std.sleep( seconds )
        local co = futures_running()
        if co == nil then
            std.error( "sleep cannot be called from main thread", 2 )
        else
            Timer_wait( function()
                futures.wakeup( co )
            end, seconds )

            return futures.pending()
        end
    end

end

std.apairs = futures.apairs
std.yield = futures.yield

std.Future = futures.Future
std.Task = futures.Task

do

    ---@class gpm.std.crypto
    local crypto = include( "std/crypto.lua" )
    std.crypto = crypto

    crypto.binary = include( "std/crypto.binary.lua" )
    crypto.ByteReader = include( "std/crypto.byte_reader.lua" )
    crypto.ByteWriter = include( "std/crypto.byte_writer.lua" )
    crypto.deflate = include( "std/crypto.deflate.lua" )

end

include( "std/bigint.lua" )

-- Extensions for string library.
include( "std/string.extensions.lua" )

std.Version = include( "std/version.lua" )

-- URL and URLSearchParams classes
include( "std/url.lua" )

-- Additional `file.path` function
do

    local string_byteSplit, string_lower = string.byteSplit, string.lower
    local table_flip = table.flip
    local is_url = std.isurl
    local URL = std.URL

    ---@class gpm.std.file.path
    local path = std.file.path

    --- [SHARED AND MENU]
    ---
    --- Converts a URL to a file path.
    ---@param url string | URL: The URL to convert.
    ---@return string path The file path.
    function path.fromURL( url )
        if not is_url( url ) then
            ---@cast url string
            url = URL( url )
        end

        ---@cast url URL

        return url.scheme .. "/" .. ( ( url.hostname and url.hostname ~= "" ) and table_concat( table_flip( string_byteSplit( string_lower( url.hostname ), 0x2E --[[ . ]] ) ), "/" ) or "" ) .. string_lower( url.pathname )
    end

end

local console = include( "std/console.lua" )
std.console = console

include( "std/error.lua" )

-- Welcome message
do

    local name

    local cvar = console.Variable.get( SERVER and "hostname" or "name", "string" )
    if cvar == nil then
        name = "stranger"
    else
        name = cvar:get()
        if name == "" or name == "unnamed" then name = "stranger" end
    end

    local splashes = {
        "eW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==",
        "I'm not here to tell you how great I am!",
        "We will have a great Future together.",
        "I'm here to show you how great I am!",
        "Millions of pieces without a tether",
        "Why are we always looking for more?",
        "Never forget to finish your tasks!",
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
        "Blazing fast ☄",
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

do

    ---@diagnostic disable-next-line: undefined-field
    local CompileString, gmbc_load_bytecode = _G.CompileString, _G.gmbc_load_bytecode
    local getfenv, setfenv = std.getfenv, std.setfenv
    local string_byte = string.byte

    --- [SHARED AND MENU]
    ---
    --- Loads a chunk of code in the specified environment.
    ---@param chunk string | function The chunk to load, can be a string or a function.
    ---@param chunkName string? The chunk name, if chunk is binary the name will be ignored.
    ---@param mode string? The string mode controls whether the chunk can be text or binary (that is, a precompiled chunk). It may be the string "b" (only binary chunks), "t" (only text chunks), or "bt" (both binary and text). The default is "bt".
    ---@param env table? The environment to load the chunk in.
    ---@return function? fn The compiled lua function.
    ---@return string? msg The error message.
    local function load( chunk, chunkName, mode, env )
        if env == nil then env = getfenv( 2 ) end

        if isstring( chunk ) then
            if mode == nil then mode = "bt" end
            ---@cast chunk string

            local fn
            if ( mode == "bt" or mode == "tb" or mode == "b" ) and string_byte( chunk, 1 ) == 0x1B then
                if gmbc_load_bytecode == nil then
                    return nil, "bytecode compilation is not supported"
                else
                    fn = gmbc_load_bytecode( chunk )
                end
            elseif ( mode == "bt" or mode == "tb" or mode == "t" ) then
                if not isstring( chunkName ) then return nil, "chunk name must be a string" end
                ---@cast chunkName string

                fn = CompileString( chunk, chunkName, false )
                if isstring( fn ) then
                    ---@cast fn string
                    return nil, fn
                end
            end

            ---@cast fn function?

            if fn == nil then
                return nil, "wrong load mode"
            end

            if istable( env ) then
                setfenv( fn, env )
            else
                return nil, "environment must be a table"
            end

            return fn
        elseif isfunction( chunk ) then
            ---@cast chunk function

            local segment = chunk()
            if segment == nil then return nil, "first segment is nil" end

            local result, length = {}, 0
            while segment ~= nil do
                length = length + 1
                result[ length ] = segment
                segment = chunk()
            end

            return load( table_concat( result, "", 1, length ), chunkName, mode, env )
        end

        return nil, "bad argument #1 to \'load\' ('string/function' expected, got '" .. type( chunk ) .. "')"
    end

    std.load = load

end

include( "std/game.lua" )
include( "std/level.lua" )

include( "std/math.classes.lua" )

if std.CLIENT_SERVER then
    include( "std/physics.lua" )
    include( "std/entity.lua" )
    include( "std/player.lua" )
    -- std.net = include( "std/net.lua" )
end

do

    local developer = console.Variable.get( "developer", "number" )

    local getDeveloper
    if developer == nil then
        getDeveloper = function() return 1 end
    elseif std.DEDICATED then
        local value = developer:get()
        developer:addChangeCallback( "gpm::init", function( _, __, new ) value = new end )
        getDeveloper = function() return value end
    else
        getDeveloper = function() return developer:get() end
    end

    local key2call = {
        DEVELOPER = getDeveloper
    }

    std.setmetatable( std, {
        __index = function( _, key )
            local func = key2call[ key ]
            if func == nil then return end
            return func()
        end
    } )

end

std.Logger = include( "std/logger.lua" )

local logger = std.Logger( gpm.PREFIX, {
    color = Color( 180, 180, 255 ),
    interpolation = false
} )

gpm.Logger = logger

std.sqlite = include( "std/sqlite.lua" )
include( "database.lua" )

local loadbinary
do

    local file_Exists = _G.file.Exists
    local require = _G.require

    local isEdge = jit.version_num ~= 20004
    local is32 = jit.arch == "x86"
    local os_name = jit.os

    local head = "lua/bin/gm" .. ( ( CLIENT and not MENU ) and "cl" or "sv" ) .. "_"
    local tail = "_" .. ( { "osx64", "osx", "linux64", "linux", "win64", "win32" } )[ ( os_name == "Windows" and 4 or 0 ) + ( os_name == "Linux" and 2 or 0 ) + ( is32 and 1 or 0 ) + 1 ] .. ".dll"

    --- [SHARED AND MENU]
    ---
    --- Checks if a binary module is installed and returns its path.
    ---@param name string The binary module name.
    ---@return boolean installed `true` if the binary module is installed, `false` otherwise.
    ---@return string path The absolute path to the binary module.
    local function lookupbinary( name )
        if name == "" then return false, "" end

        local filePath = head .. name .. tail
        if file_Exists( filePath, "MOD" ) then
            return true, "/" .. filePath
        end

        if isEdge and is32 and tail == "_linux.dll" then
            filePath = head .. name .. "_linux32.dll"
            if file_Exists( filePath, "MOD" ) then
                return true, "/" .. filePath
            end
        end

        return false, "/" .. filePath
    end

    std.lookupbinary = lookupbinary

    local sv_allowcslua = SERVER and console.Variable.get( "sv_allowcslua", "boolean" )

    --- [SHARED AND MENU]
    ---
    --- Loads a binary module
    ---@param name string The binary module name, for example: "chttp"
    ---@return boolean success true if the binary module is installed
    ---@return table? module the binary module table
    ---@protected
    function loadbinary( name )
        if lookupbinary( name ) then
            if sv_allowcslua ~= nil and sv_allowcslua:get() then
                sv_allowcslua:set( false )
            end

            require( name )
            return true, _G[ name ]
        else
            return false, nil
        end
    end

    std.loadbinary = loadbinary

end

-- https://github.com/WilliamVenner/gmsv_workshop
---@diagnostic disable-next-line: undefined-field
if SERVER and not ( std.istable( _G.steamworks ) and std.isfunction( _G.steamworks.DownloadUGC ) ) then
    loadbinary( "workshop" )
end

-- https://github.com/willox/gmbc
loadbinary( "gmbc" )

do

    ---@class gpm.std.http
    local http = include( "std/http.lua" )
    std.http = http

    http.github = include( "std/http.github.lua" )

end

do

    ---@class gpm.std.steam
    local steam = include( "std/steam.lua" )
    std.steam = steam

    steam.Identifier = steam.Identifier or include( "std/steam.identifier.lua" )
    steam.WorkshopItem = steam.WorkshopItem or include( "std/steam.workshop_item.lua" )

end

include( "std/addon.lua" )

if std.CLIENT_MENU then

    std.input = include( "std/input.lua" )
    std.menu = include( "std/menu.lua" )

    do

        ---@class gpm.std.client
        local client = include( "std/client.lua" )
        std.client = client

        client.window = include( "std/client.window.lua" )

    end

    std.render = include( "std/render.lua" )

end

std.server = include( "std/server.lua" )

if std.TYPE.COUNT ~= 44 then
    logger:warn( "Global TYPE_COUNT mismatch, data corruption suspected. (" .. std.tostring( _G.TYPE_COUNT or "missing" ) .. " ~= 44)"  )
end

if std._VERSION ~= "Lua 5.1" then
    logger:warn( "Lua version changed, possible unpredictable behavior. (" .. std.tostring( _G._VERSION or "missing") .. ")" )
end

logger:info( "Start-up time: %.4f sec.", getTime() - gpm.StartTime )

do
    local start_time = getTime()
    std.debug.gc.collect()
    logger:info( "Clean-up time: %.4f sec.", getTime() - start_time )
end

-- TODO: put https://wiki.facepunch.com/gmod/Global.DynamicLight somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.ProjectedTexture somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.IsFirstTimePredicted somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.RecipientFilter somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.ClientsideScene somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.Localize somewher
-- TODO: put https://wiki.facepunch.com/gmod/Global.Path somewhere
-- TODO: put https://wiki.facepunch.com/gmod/util.ScreenShake somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.AddonMaterial somewhere

-- TODO: https://github.com/toxidroma/class-war

-- TODO: NetTable class

-- TODO: Write "VideoRecorder" class ( https://wiki.facepunch.com/gmod/video.Record )

--[[

    TODO: return missing functions

    -- dofile - missing in glua

    -- load - missing in glua
    -- loadfile - missing in glua
    -- loadstring - is deprecated in lua 5.2

    -- require - broken in glua

]]

-- local file = std.file

-- -- Plugins
-- do

--     local files = _G.file.Find( "gpm/plugins/*.lua", "LUA" )
--     for i = 1, #files do
--         include( "plugins/" .. files[ i ] )
--     end

-- end

return gpm
