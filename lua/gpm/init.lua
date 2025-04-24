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

--- [SHARED AND MENU]
---
--- gpm standard environment
---
---@class gpm.std
local std = gpm.std
if std == nil then
    ---@class gpm.std
    std = {}
    gpm.std = std
end

---@diagnostic disable-next-line: undefined-field
local dofile = gpm.dofile
if dofile == nil then
    dofile = _G.include or _G.dofile
    gpm.dofile = dofile
end

---@diagnostic disable-next-line: undefined-field
local getTime = _G.SysTime or _G.os.time
gpm.StartTime = getTime()

gpm.VERSION = version
gpm.PREFIX = "gpm@" .. version

dofile( "detour.lua" )

-- TODO: make direct functions for transducers instead of metatable checks

--- object transducers
---@class gpm.transducers
local transducers = {}
gpm.transducers = transducers

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

raw.error = raw.error or _G.error
raw.type = raw.type or _G.type

raw.equal = raw.equal or _G.rawequal
raw.get = raw.get or _G.rawget
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

dofile( "std/debug.lua" )
dofile( "std/debug.gc.lua" )

local debug = std.debug
local debug_fempty = debug.fempty
local debug_getmetatable = debug.getmetatable

local setmetatable = std.setmetatable

setmetatable( transducers, {
    __index = function( self, value )
        local metatable = debug_getmetatable( value )
        if metatable == nil then return value end

        local fn = raw_get( self, metatable )
        if fn == nil then return value end

        return fn( value )
    end
} )

if _G.util ~= nil then

    local fn = _G.util.GetActivityIDByName
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

    do

        local inext = std.inext

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
                return inext, tbl, 0
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
    ---@param base? integer The base used in the value. Can be any integer between 2 and 36, inclusive. (Default: 10)
    ---@return number result The numeric representation of the value with the given base, or `0` if the conversion failed or not possible.
    function std.tonumber( value, base )
        local fn = debug_getmetavalue( value, "__tonumber" )
        if fn == nil then
            return 0
        else
            return fn( value, base or 10 )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Attempts to convert the value to a boolean.
    ---@param value any The value to convert.
    ---@return boolean bool The boolean representation of the value, or `false` if the conversion failed.
    function std.toboolean( value )
        if value == nil or value == false then
            return false
        end

        local fn = debug_getmetavalue( value, "__toboolean" )
        if fn == nil then
            return true
        else
            return fn( value )
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

end

do

    --- [SHARED AND MENU]
    ---
    --- coroutine library
    --- Coroutines are similar to threads, however they do not run simultaneously.
    ---
    --- They offer a way to split up tasks and dynamically pause & resume functions.
    ---@class gpm.std.coroutine : coroutinelib
    local coroutine = std.coroutine or {}
    std.coroutine = coroutine

    local glua_coroutine = _G.coroutine

    ---@diagnostic disable-next-line: deprecated
    coroutine.isyieldable = coroutine.isyieldable or glua_coroutine.isyieldable or function() return true end

    coroutine.create = coroutine.create or glua_coroutine.create
    coroutine.resume = coroutine.resume or glua_coroutine.resume
    coroutine.running = coroutine.running or glua_coroutine.running
    coroutine.status = coroutine.status or glua_coroutine.status
    coroutine.wrap = coroutine.wrap or glua_coroutine.wrap
    coroutine.yield = coroutine.yield or glua_coroutine.yield

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

dofile( "std/string.lua" )

local string = std.string

do
    local string_len = string.len

    function STRING.__bitcount( value )
        return string_len( value ) * 8
    end

end

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

dofile( "std/bit.lua" )
dofile( "std/os.lua" )

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

dofile( "std/table.lua" )

local table_concat = std.table.concat

do

    local coroutine_running = std.coroutine.running
    local debug_getinfo = debug.getinfo
    local string_rep = string.rep
    local tostring = std.tostring
    local raw_error = raw.error

    ---@diagnostic disable-next-line: undefined-field
    local ErrorNoHalt = _G.ErrorNoHalt or std.print

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

    -- TODO: think about throw

    --- [SHARED AND MENU]
    ---
    --- Throws a Lua error.
    ---
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

dofile( "std/class.lua" )

local type
do

    local debug_getinfo = debug.getinfo
    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Returns a string representing the name of the type of the passed object.
    ---
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
    ---
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

dofile( "std/string.utf8.lua" )
dofile( "engine.lua" )

dofile( "std/math.classes.lua" )
dofile( "std/structures.lua" )

-- symbol class
do

    local function __tostring( self )
        ---@diagnostic disable-next-line: param-type-mismatch
        return string_format( "%s: %p", raw_get( debug_getmetatable( self ), "__type" ), self )
    end

    local debug_newproxy = debug.newproxy

    ---@class gpm.std.Symbol : userdata
    ---@alias Symbol gpm.std.Symbol

    --- [SHARED AND MENU]
    ---
    --- Creates a new symbol.
    ---
    ---@param name string The name of the symbol.
    ---@return Symbol obj The new symbol.
    function std.Symbol( name )
        ---@class gpm.std.Symbol
        local obj = debug_newproxy( true )
        local metatable = debug_getmetatable( obj )
        metatable.__type = name .. " Symbol"
        metatable.__tostring = __tostring
        return obj
    end

end

dofile( "std/futures.lua" )
dofile( "std/hook.lua" )
dofile( "std/timer.lua" )
dofile( "std/color.lua" )

do

    local Timer_wait = std.Timer.wait
    local futures = std.futures

    --- Puts current thread to sleep for given amount of seconds.
    ---
    ---@see gpm.std.futures.pending
    ---@see gpm.std.futures.wakeup
    ---@async
    ---@param seconds number
    function std.sleep( seconds )
        local co = futures.running()
        if co == nil then
            std.error( "sleep cannot be called from main thread", 2 )
        end

        ---@cast co thread

        Timer_wait( function()
            futures.wakeup( co )
        end, seconds )

        return futures.pending()
    end

end

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

dofile( "std/crypto.lua" )
dofile( "std/crypto.lzw.lua" )
dofile( "std/crypto.xtea.lua" )
dofile( "std/crypto.binary.lua" )

dofile( "std/crypto.deflate.lua" )
dofile( "std/crypto.hmac.lua" )
dofile( "std/crypto.aes.lua" )

dofile( "std/crypto.byte_reader.lua" )
dofile( "std/crypto.byte_writer.lua" )

dofile( "std/bigint.lua" )

dofile( "std/string.extensions.lua" )

dofile( "std/version.lua" )
dofile( "std/url.lua" )

do

    --- [SHARED AND MENU]
    ---
    --- The game's file library.
    ---@class gpm.std.file
    local file = std.file or {}
    std.file = file

end

dofile( "std/file.path.lua" )
dofile( "std/file.lua" )

dofile( "package/init.lua" )

-- Additional `file.path` function
do

    local string_byteSplit, string_lower = string.byteSplit, string.lower
    local table_flipped = std.table.flipped
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

        return url.scheme .. "/" .. ( ( url.hostname and url.hostname ~= "" ) and table_concat( table_flipped( string_byteSplit( string_lower( url.hostname ), 0x2E --[[ . ]] ) ), "/" ) or "" ) .. string_lower( url.pathname )
    end

end

dofile( "std/console.lua" )
dofile( "std/error.lua" )

-- Welcome message
do

    local name

    local cvar = std.console.Variable.get( SERVER and "hostname" or "name", "string" )
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

dofile( "std/game.lua" )
dofile( "std/level.lua" )

do

    local developer = std.console.Variable.get( "developer", "number" )

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

dofile( "std/logger.lua" )

local logger = std.Logger( {
    title = gpm.PREFIX,
    color = std.Color( 180, 180, 255 ),
    interpolation = false
} )

gpm.Logger = logger

if math.randomseed == 0 then
    math.randomseed = std.os.time()
    logger:info( "Random seed was re-synchronized with unix time." )
end

dofile( "std/sqlite.lua" )
dofile( "database.lua" )

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

    local sv_allowcslua = SERVER and std.console.Variable.get( "sv_allowcslua", "boolean" )

    --- [SHARED AND MENU]
    ---
    --- Loads a binary module
    ---@param name string The binary module name, for example: "chttp"
    ---@return boolean success true if the binary module is installed
    ---@protected
    function loadbinary( name )
        if lookupbinary( name ) then
            if sv_allowcslua ~= nil and sv_allowcslua:get() then
                sv_allowcslua:set( false )
            end

            require( name )
            return true
        end

        return false
    end

    std.loadbinary = loadbinary

end

-- https://github.com/WilliamVenner/gmsv_workshop
---@diagnostic disable-next-line: undefined-field
if SERVER and not ( std.istable( _G.steamworks ) and std.isfunction( _G.steamworks.DownloadUGC ) ) then
    if loadbinary( "workshop" ) then
        logger:info( "'gmsv_workshop' was connected as server-side Steam Workshop API." )
    end
end

-- https://github.com/willox/gmbc
if loadbinary( "gmbc" ) then
    logger:info( "'gmbc' was connected as bytecode compiler, binary code compilation avaliable." )
end

do

    local getfenv, setfenv = std.getfenv, std.setfenv

    do

        local CompileString = _G.CompileString

        --- [SHARED AND MENU]
        ---
        --- Loads a string or function as
        --- a chunk in the specified environment
        --- and returns function as a compile result.
        ---
        ---@param chunk string | function The lua code chunk.
        ---@param chunkName string The lua code chunk name.
        ---@param env table | nil The environment of compiled function.
        ---@return function | nil fn The compiled function.
        ---@return string | nil msg The error message.
        local function loadstring( chunk, chunkName, env )
            if env == nil then
                env = getfenv( 2 )
            end

            if isstring( chunk ) then
                ---@cast chunk string

                local fn = CompileString( chunk, chunkName, false )

                if fn == nil then
                    return nil, "failed to compile chunk"
                elseif isstring( fn ) then
                    ---@diagnostic disable-next-line: cast-type-mismatch
                    ---@cast fn string
                    return nil, fn
                else
                    setfenv( fn, env )
                    return fn
                end
            elseif isfunction( chunk ) then
                ---@cast chunk function

                local segment = chunk()
                if segment == nil then
                    return nil, "first chunk segment cannot be nil"
                end

                local segments, length = {}, 0
                while segment ~= nil do
                    length = length + 1
                    segments[ length ] = segment
                    segment = chunk()
                end

                return loadstring( table_concat( segments, "", 1, length ), chunkName, env )
            else
                return nil, "bad argument #1 to 'loadstring' ('string/function' expected, got '" .. type( chunk ) .. "')"
            end
        end

        std.loadstring = loadstring

    end

    do

        ---@diagnostic disable-next-line: undefined-field
        local gmbc_load_bytecode = _G.gmbc_load_bytecode

        --- [SHARED AND MENU]
        ---
        --- Loads a string or function as
        --- a bytecode chunk in the specified environment
        --- and returns function as a compile result.
        ---
        ---@param chunk string | function The luajit bytecode chunk.
        ---@param env table | nil The environment of compiled function.
        ---@return function | nil fn The compiled function.
        ---@return string | nil msg The error message.
        local function loadbytecode( chunk, env )
            if env == nil then
                env = getfenv( 2 )
            end

            if isstring( chunk ) then
                ---@cast chunk string

                local success, result = pcall( gmbc_load_bytecode, chunk )
                if success then
                    setfenv( result, env )
                    return result
                else
                    return nil, result
                end
            elseif isfunction( chunk ) then
                ---@cast chunk function

                local segment = chunk()
                if segment == nil then
                    return nil, "first chunk segment cannot be nil"
                end

                local segments, length = {}, 0
                while segment ~= nil do
                    length = length + 1
                    segments[ length ] = segment
                    segment = chunk()
                end

                return loadbytecode( table_concat( segments, "", 1, length ), env )
            else
                return nil, "bad argument #1 to 'loadbytecode' ('string/function' expected, got '" .. type( chunk ) .. "')"
            end
        end

        std.loadbytecode = loadbytecode

    end

end

dofile( "std/http.lua" )
dofile( "std/http.github.lua" )

do

    --- [SHARED AND MENU]
    ---
    --- Steam library.
    ---@class gpm.std.steam
    local steam = {}
    std.steam = steam

end

dofile( "std/steam.identifier.lua" )
dofile( "std/steam.workshop_item.lua" )
dofile( "std/steam.lua" )
dofile( "std/addon.lua" )

if std.CLIENT_MENU then
    dofile( "std/os.window.lua" )
    dofile( "std/menu.lua" )
    dofile( "std/client.lua" )
    dofile( "std/render.lua" )
end

dofile( "std/server.lua" )

do

    ---@class gpm.std.coroutine
    local coroutine = std.coroutine
    local coroutine_yield = coroutine.yield
    local server_getUptime = std.server.getUptime

    ---@async
    function coroutine.wait( seconds )
        local endtime = server_getUptime() + seconds
        while true do
            if endtime < server_getUptime() then return end
            coroutine_yield()
        end
    end

end

if std.CLIENT_SERVER then
    dofile( "std/physics.lua" )
    dofile( "std/entity.lua" )
    dofile( "std/player.lua" )
    -- dofile( "std/net.lua" )
end

dofile( "std/input.lua" )

if _G.TYPE_COUNT ~= 44 then
    logger:warn( "Global TYPE_COUNT mismatch, data corruption suspected. (" .. std.tostring( _G.TYPE_COUNT or "missing" ) .. " ~= 44)"  )
end

if _G._VERSION ~= "Lua 5.1" then
    logger:warn( "Lua version changed, possible unpredictable behavior. (" .. std.tostring( _G._VERSION or "missing") .. ")" )
end

logger:info( "Start-up time: %.2f ms.", ( getTime() - gpm.StartTime ) * 1000 )

do

    logger:info( "Preparing the database to begin migration..." )
    local start_time = getTime()

    local db = gpm.db
    db.optimize()
    db.prepare()
    db.migrate( "initial file table" )

    logger:info( "Migration completed, time spent: %.2f ms.", ( getTime() - start_time ) * 1000 )

end

-- TODO: package manager start-up ( aka starting package loading )

do
    local start_time = getTime()
    debug.gc.collect()
    logger:info( "Clean-up time: %.2f ms.", ( getTime() - start_time ) * 1000 )
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
--         dofile( "plugins/" .. files[ i ] )
--     end

-- end

return gpm
