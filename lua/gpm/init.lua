local version = "2.0.0"

---@class _G
local _G = _G

---@diagnostic disable-next-line: undefined-field
local include = _G.include or _G.dofile

---@diagnostic disable-next-line: undefined-field
local getTime = _G.SysTime or _G.os.time

local gpm = _G.gpm
if gpm == nil then
    ---@class gpm
    ---@field VERSION string Package manager version in semver format.
    ---@field PREFIX string Package manager unique prefix.
    ---@field StartTime number SysTime point when package manager was started.
    gpm = {}; _G.gpm = gpm
end

gpm.VERSION = version
gpm.StartTime = getTime()
gpm.PREFIX = "gpm@" .. version

if gpm.detour == nil then
    ---@class gpm.detour
    gpm.detour = include( "detour.lua" )
end

--- gpm standard environment
---@class gpm.std
---@field DEDICATED_SERVER boolean: `true` if game is dedicated server, `false` otherwise.
local std = gpm.std
if std == nil then
    std = include( "std/constants.lua" )
    gpm.std = std
else
    for key, value in std.pairs( include( "std/constants.lua" ) ) do
        std[ key ] = value
    end
end

local error = _G.error
std.error = error

std.assert = std.assert or _G.assert
std.getmetatable = std.getmetatable or _G.getmetatable
std.setmetatable = std.setmetatable or _G.setmetatable

do

    std.getfenv = getfenv -- removed in Lua 5.2
    std.setfenv = setfenv -- removed in Lua 5.2

end

local rawget, rawset = std.rawget or _G.rawget, std.rawset or _G.rawset
std.rawget, std.rawset = rawget, rawset

std.rawequal = std.rawequal or _G.rawequal
std.rawlen = std.rawlen or _G.rawlen or function( value ) return #value end

local tostring = std.tostring or _G.tostring
std.tostring = tostring

std.select = std.select or _G.select

local ipairs, pairs = std.ipairs or _G.ipairs, std.pairs or _G.pairs
std.ipairs, std.pairs = ipairs, pairs

std.inext = std.inext or ipairs( std )
std.next = std.next or _G.next

std.xpcall = std.xpcall or _G.xpcall
std.pcall = std.pcall or _G.pcall

-- jit library
local jit = std.jit or _G.jit
std.jit = jit

local CLIENT, SERVER, MENU, CLIENT_MENU, CLIENT_SERVER = std.CLIENT, std.SERVER, std.MENU, std.CLIENT_MENU, std.CLIENT_SERVER

-- client-side files
if SERVER then
    ---@diagnostic disable-next-line: undefined-field
    local AddCSLuaFile = _G.AddCSLuaFile
    if AddCSLuaFile ~= nil then
        AddCSLuaFile( "gpm/database.lua" )
        AddCSLuaFile( "gpm/detour.lua" )

        local files = _G.file.Find( "gpm/std/*", "lsv" )
        local string_find = _G.string.find

        for i = 1, #files do
            if not string_find( files[ i ], ".meta.lua$" ) then
                AddCSLuaFile( "gpm/std/" .. files[ i ] )
            end
        end
    end
end

---@class gpm.std.debug
local debug = include( "std/debug.lua" )
std.debug = debug

-- garbage collector
debug.gc = include( "std/garbage-collection.lua" )

local debug_getmetatable = debug.getmetatable

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

local tonumber = _G.tonumber

--- Attempts to convert the value to a number.
---@param value any: The value to convert.
---@param base number: The base used in the string. Can be any integer between 2 and 36, inclusive. (Default: 10)
---@return number: The numeric representation of the value with the given base, or `nil` if the conversion failed.
function std.tonumber( value, base )
    local metatable = debug_getmetatable( value )
    return metatable ~= nil and metatable.__tonumber( value, base ) or 0
end

--- Attempts to convert the value to a boolean.
---@param value any: The value to convert.
---@return boolean
function std.toboolean( value )
    if value == nil or value == false then return false end

    local metatable = debug_getmetatable( value )
    return metatable ~= nil and metatable.__tobool( value ) or true
end

std.tobool = std.toboolean

--- Checks if the value is valid.
---@param value any: The value to check.
---@return boolean: Returns `true` if the value is valid, otherwise `false`.
function std.isvalid( value )
    local metatable = debug_getmetatable( value )
    return ( metatable ~= nil and metatable.__isvalid and metatable.__isvalid( value ) ) == true
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

        --- Checks if the value type is a `boolean`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a boolean, otherwise `false`.
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

        --- Checks if the value type is a `number`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a number, otherwise `false`.
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

        STRING.__tonumber = tonumber

        --- Checks if the value type is a `string`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a string, otherwise `false`.
        function isstring( value )
            return debug_getmetatable( value ) == STRING
        end

        std.isstring = isstring

    end

    -- table ( 5 )
    std.istable = _G.istable

    -- function ( 6 )
    do

        local object = debug.fempty

        local FUNCTION = debug_getmetatable( object )
        if FUNCTION == nil then
            FUNCTION = {}
            debug_setmetatable( object, FUNCTION )
        end

        debug_registermetatable( "function", FUNCTION )

        --- Checks if the value type is a `function`.
        ---@param value any
        ---@return boolean isFunction returns true if the value is a function, otherwise false
        function std.isfunction( value )
            return debug_getmetatable( value ) == FUNCTION
        end

        --- Checks if the value is callable.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is can be called (like a function), otherwise `false`.
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

        --- Checks if the value type is a `thread`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a thread, otherwise `false`.
        function std.isthread( value )
            return debug_getmetatable( value ) == THREAD
        end

    end

end

do

    local game = _G.game
    if game == nil then
        std.DEDICATED_SERVER = false
    else
        local game_isDedicatedServer = game.IsDedicated
        if std.isfunction( game_isDedicatedServer ) then
            std.DEDICATED_SERVER = game_isDedicatedServer()
        else
            std.DEDICATED_SERVER = false
        end
    end

end

--- math library
---@class gpm.std.math
local math = include( "std/math.lua" )
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

    --- Returns the bit count of the given value.
    ---@param value any: The value to get the bit count of.
    ---@return number: The bit count of the value.
    local function bitcount( value )
        local metatable = debug_getmetatable( value )
        return metatable and metatable.__bitcount( value ) or 0
    end

    std.bitcount = bitcount

    --- Returns the byte count of the given value.
    ---@param value any: The value to get the byte count of.
    ---@return number: The byte count of the value.
    function std.bytecount( value )
        return math_ceil( bitcount( value ) * 0.125 )
    end

end

--- string library
---@class gpm.std.string
local string = include( "std/string.lua" )
std.string = string

local string_format = string.format
local string_len = string.len

function STRING.__bitcount( value )
    return string_len( value ) * 8
end

do

    local print = _G.print
    std.print = print

    --- Prints a formatted string to the console.
    ---
    --- Basically the same as `print( string.format( str, ... ) )`
    ---@param str any
    ---@param ... any
    function std.printf( str, ... )
        return print( string_format( str, ... ) )
    end

end

-- bit library
std.bit = include( "std/bit.lua" )

--- os library
---@class gpm.std.os
local os = include( "std/os.lua" )
std.os = os

-- TODO: remove me later or rewrite
do

    local iter = 100000
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

--- table library
---@class gpm.std.table
local table = include( "std/table.lua" )
std.table = table

local table_concat = table.concat

do

    local debug_getinfo = debug.getinfo
    local glua_type = _G.type

    --- Returns a string representing the name of the type of the passed object.
    ---@param value any: The value to get the type of.
    ---@return string: The type name of the given value.
    local function type( value )
        local metatable = debug_getmetatable( value )
        if metatable ~= nil then
            local name = rawget( metatable, "__type" )
            if isstring( name ) then return name end
        end

        return glua_type( value )
    end

    std.type = type

    --- Validates the type of the argument and returns a boolean and an error message.
    ---@param value any: The argument value.
    ---@param arg_num number: The argument number.
    ---@param expected_type string: The expected type name.
    ---@return boolean: `true` if the argument is of the expected type, `false` otherwise.
    ---@return string?: The error message.
    function std.arg( value, arg_num, expected_type )
        local got = type( value )
        if got == expected_type or expected_type == "any" then
            return true, nil
        else
            return false, string_format( "bad argument #%d to \'%s\' ('%s' expected, got '%s')", arg_num, debug_getinfo( 2, "n" ).name or "unknown", expected_type, got )
        end
    end

end

-- utf8 library
string.utf8 = include( "std/string.utf8.lua" )

--- Returns an iterator `next` for a for loop that will return the values of the specified table in an arbitrary order.
---@param tbl table: The table to iterate over.
---@return function: The iterator function.
---@return table: The table being iterated over.
---@return any: The previous key in the table (by default `nil`).
function std.pairs( tbl )
    local metatable = debug_getmetatable( tbl )
    return ( metatable ~= nil and metatable.__pairs or pairs )( tbl )
end

--- Returns a [Stateless Iterator](https://www.lua.org/pil/7.3.html) for a [Generic For Loops](https://www.lua.org/pil/4.3.5.html), to return ordered key-value pairs from a table.
---
--- This will only iterate though <b>numerical keys</b>, and these must also be sequential; starting at 1 with no gaps.
---
---@param tbl table: The table to iterate over.
---@return function: The iterator function.
---@return table: The table being iterated over.
---@return number: The origin index =0.
function std.ipairs( tbl )
    local metatable = debug_getmetatable( tbl )
    if metatable == nil or rawget( metatable, "__index" ) == nil then
        return ipairs( tbl )
    end

    local index = 0
    return function()
        index = index + 1
        local value = tbl[ index ]
        if value == nil then return end
        return index, value
    end, tbl, index
end

--- class library
---@class gpm.std.class
local class = include( "std/class.lua" )
std.class = class

-- symbol class
do

    local function __tostring( self )
        return rawget( debug_getmetatable( self ), "__type" )
    end

    local debug_newproxy = debug.newproxy

    ---@class gpm.std.Symbol : userdata
    ---@alias Symbol gpm.std.Symbol

    ---@param name string: The name of the symbol.
    ---@return Symbol: The new symbol.
    function std.Symbol( name )
        ---@class gpm.std.Symbol
        local obj = debug_newproxy( true )
        local metatable = debug_getmetatable( obj )
        metatable.__type = string_format( "Symbol: %p ['%s']", obj, name )
        metatable.__tostring = __tostring
        return obj
    end

end

--- [SHARED AND MENU] Hook class
std.Hook = include( "std/hook.lua" )

do

    local Hook = std.Hook

    --- [SHARED AND MENU] A hook that is called every tick.
    std.TickHook = std.TickHook or Hook( "Tick" )

end

--- [SHARED AND MENU] Timer class
std.Timer = include( "std/timer.lua" )

--- [SHARED AND MENU] File class
local File = include( "std/file.lua" )
std.File = File

--- [SHARED AND MENU] Color class
local Color = include( "std/color.lua" )
std.Color = Color

-- error
do

    local debug_getstack, debug_getupvalue, debug_getlocal = debug.getstack, debug.getupvalue, debug.getlocal
    local coroutine_running = coroutine.running
    local string_rep = string.rep

    ---@diagnostic disable-next-line: undefined-field
    local ErrorNoHalt, ErrorNoHaltWithStack = _G.ErrorNoHalt, _G.ErrorNoHaltWithStack

    if not ErrorNoHalt then
        ErrorNoHalt = std.print
    end

    if not ErrorNoHaltWithStack then
        ErrorNoHaltWithStack = std.print
    end

    local callStack, callStackSize = {}, 0

    local function pushCallStack( stack )
        local size = callStackSize + 1
        callStack[ size ] = stack
        callStackSize = size
    end

    local function popCallStack()
        local pos = callStackSize
        if pos == 0 then
            return nil
        end

        local stack = callStack[ pos ]
        callStack[ pos ] = nil
        callStackSize = pos - 1
        return stack
    end

    local function appendStack( stack )
        return pushCallStack( { stack, callStack[ callStackSize ] } )
    end

    local function mergeStack( stack )
        local pos = #stack

        local currentCallStack = callStack[ callStackSize ]
        while currentCallStack do
            local lst = currentCallStack[ 1 ]
            for i = 1, #lst do
                local info = lst[ i ]
                pos = pos + 1
                stack[ pos ] = info
            end

            currentCallStack = currentCallStack[ 2 ]
        end

        return stack
    end

    local dumpFile
    do

        local math_min, math_max, math_floor, math_log10, math_huge = math.min, math.max, math.floor, math.log10, math.huge
        local string_split, string_find, string_sub = string.split, string.find, string.sub
        local file_Open = _G.file.Open
        local MsgC = _G.MsgC

        local gray = Color( 180, 180, 180 )
        local white = Color( 225, 225, 225 )
        local danger = Color( 239, 68, 68 )

        dumpFile = function( message, fileName, line )
            if not ( fileName and line ) then
                return
            end

            ---@class File
            ---@diagnostic disable-next-line: assign-type-mismatch
            local handler = file_Open( fileName, "rb", "GAME" )
            if handler == nil then return end

            local str = handler:Read( handler:Size() )
            handler:Close()

            if string_len( str ) == 0 then
                return
            end

            local lines = string_split( str, "\n" )
            if not ( lines and lines[ line ] ) then
                return
            end

            local start = math_max( 1, line - 5 )
            local finish = math_min( #lines, line + 3 )
            local numWidth = math_floor( math_log10( finish ) ) + 1

            local longestLine, firstChar = 0, math_huge
            for i = start, finish do
                local code = lines[ i ]
                local pos = string_find( code, "%S" )
                if pos and pos < firstChar then
                    firstChar = pos
                end

                longestLine = math_max( longestLine, string_len( code ) )
            end

            longestLine = math_min( longestLine - firstChar, 120 )
            MsgC( gray, string_rep( " ", numWidth + 3 ), string_rep( "_", longestLine + 4 ), "\n", string_rep( " ", numWidth + 2 ), "|\n" )

            local numFormat = " %0" .. numWidth .. "d | "
            for i = start, finish do
                local code = lines[ i ]

                MsgC( i == line and white or gray, string_format( numFormat, i ), string_sub( code, firstChar, longestLine + firstChar ), "\n" )

                if i == line then
                    MsgC(
                        gray, string_rep(" ", numWidth + 2), "| ", string_sub( code, firstChar, ( string_find( code, "%S" ) or 1 ) - 1 ), danger, "^ ", tostring( message ), "\n",
                        gray, string_rep(" ", numWidth + 2), "|\n"
                    )
                end
            end

            MsgC( gray, string_rep( " ", numWidth + 2 ), "|\n", string_rep( " ", numWidth + 3 ), string_rep( "¯", longestLine + 4 ), "\n\n" )
        end

    end

    ---@alias Error gpm.std.Error
    ---@class gpm.std.Error : gpm.std.Object
    ---@field __class gpm.std.ErrorClass
    ---@field __parent gpm.std.Error | nil
    ---@field name string
    local Error = class.base( "Error" )

    ---@protected
    function Error:__index( key )
        if key == "name" then
            return self.__type
        end

        return Error[ key ]
    end

    ---@protected
    function Error:__tostring()
        if self.fileName then
            return string_format( "%s:%d: %s: %s", self.fileName, self.lineNumber or 0, self.name, self.message )
        else
            return self.name .. ": " .. self.message
        end
    end

    ---@protected
    ---@param message string
    ---@param fileName string?
    ---@param lineNumber number?
    ---@param stackPos integer?
    function Error:__init( message, fileName, lineNumber, stackPos )
        if stackPos == nil then stackPos = 0 end
        self.lineNumber = lineNumber
        self.fileName = fileName
        self.message = message

        local stack = debug_getstack( stackPos )
        self.stack = stack
        mergeStack( stack )

        local first = stack[ 1 ]
        if first == nil then return end

        self.fileName = self.fileName or first.short_src
        self.lineNumber = self.lineNumber or first.currentline

        if debug_getupvalue and first.func and first.nups and first.nups > 0 then
            local upvalues = {}
            self.upvalues = upvalues

            for i = 1, first.nups do
                local name, value = debug_getupvalue( first.func, i )
                if name == nil then
                    self.upvalues = nil
                    break
                end

                upvalues[ i ] = { name, value }
            end
        end

        if debug_getlocal then
            local locals, count, i = {}, 0, 1
            while true do
                local name, value = debug_getlocal( stackPos, i )
                if name == nil then break end

                if name ~= "(*temporary)" then
                    count = count + 1
                    locals[ count ] = { name, value }
                end

                i = i + 1
            end

            if count ~= 0 then
                self.locals = locals
            end
        end
    end

    function Error:display()
        if isstring( self ) then
            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast self string
            ErrorNoHaltWithStack( self )
            return
        end

        local lines, length = { "\n[ERROR] " .. tostring( self ) }, 1

        local stack = self.stack
        if stack then
            for i = 1, #stack do
                local info = stack[ i ]
                length = length + 1
                lines[ length ] = string_format( "%s %d. %s - %s:%d", string_rep( " ", i ), i, info.name or "unknown", info.short_src, info.currentline or -1 )
            end
        end

        local locals = self.locals
        if locals then
            length = length + 1
            lines[ length ] = "\n=== Locals ==="

            for i = 1, #locals do
                local entry = locals[ i ]
                length = length + 1
                lines[ length ] = string_format( "  - %s = %s", entry[ 1 ], entry[ 2 ] )
            end
        end

        local upvalues = self.upvalues
        if upvalues ~= nil then
            length = length + 1
            lines[ length ] = "\n=== Upvalues ==="

            for i = 1, #upvalues do
                local entry = upvalues[ i ]
                length = length + 1
                lines[ length ] = string_format( "  - %s = %s", entry[ 1 ], entry[ 2 ] )
            end
        end

        length = length + 1
        lines[ length ] = "\n"
        ErrorNoHalt( table_concat( lines, "\n", 1, length ) )

        if self.message and self.fileName and self.lineNumber then
            dumpFile( self.name .. ": " .. self.message, self.fileName, self.lineNumber )
        end
    end

    ---@class gpm.std.ErrorClass : gpm.std.Error
    ---@field __base gpm.std.Error
    ---@overload fun(message: string, fileName: string?, lineNumber: number?, stackPos: number?): Error
    local ErrorClass = class.create( Error )

    -- Basic error class
    std.Error = ErrorClass

    --- Creates a new `Error` with custom name
    ---@param name string
    ---@param base Error | nil
    ---@return Error
    function ErrorClass.make( name, base )
        return class.create( class.base( name, base or ErrorClass ) ) ---@type Error
    end

    -- Built-in errors
    std.NotImplementedError = ErrorClass.make( "NotImplementedError" )
    std.FutureCancelError = ErrorClass.make( "FutureCancelError" )
    std.InvalidStateError = ErrorClass.make( "InvalidStateError" )
    std.CodeCompileError = ErrorClass.make( "CodeCompileError" )
    std.FileSystemError = ErrorClass.make( "FileSystemError" )
    std.HTTPClientError = ErrorClass.make( "HTTPClientError" )
    std.RuntimeError = ErrorClass.make( "RuntimeError" )
    std.PackageError = ErrorClass.make( "PackageError" )
    std.ModuleError = ErrorClass.make( "ModuleError" )
    std.SourceError = ErrorClass.make( "SourceError" )
    std.FutureError = ErrorClass.make( "FutureError" )
    std.AddonError = ErrorClass.make( "AddonError" )
    std.RangeError = ErrorClass.make( "RangeError" )
    std.TypeError = ErrorClass.make( "TypeError" )

    ---@alias gpm.std.ErrorType
    ---| number # error with level
    ---| `-1` # ErrorNoHalt
    ---| `-2` # ErrorNoHaltWithStack

    --- Throws a Lua error.
    ---@param message any: The error message to throw.
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
            return error( message, level )
        end
    end

end

-- Extensions for string library
include( "std/string.extensions.lua" )

-- Version class
std.Version = include( "std/version.lua" )

-- URL and URLSearchParams classes
include( "std/url.lua" )

-- Additional `File.path` function
do

    local string_byteSplit, string_lower = string.byteSplit, string.lower
    local table_flip = table.flip
    local is_url = std.isurl
    local URL = std.URL

    ---@class gpm.std.File.path
    local path = File.path

    --- Converts a URL to a file path.
    ---@param url string | URL: The URL to convert.
    ---@return string: The file path.
    function path.fromURL( url )
        if not is_url( url ) then
            ---@cast url string
            url = URL( url )
        end

        ---@cast url URL

        return url.scheme .. "/" .. ( ( url.hostname and url.hostname ~= "" ) and table_concat( table_flip( string_byteSplit( string_lower( url.hostname ), 0x2E --[[ . ]] ) ), "/" ) or "" ) .. string_lower( url.pathname )
    end

end

-- Queue class
do

    ---@alias Queue gpm.std.Queue
    ---@class gpm.std.Queue : gpm.std.Object
    ---@field __class gpm.std.QueueClass
    ---@field protected front integer
    ---@field protected back integer
    local Queue = class.base( "Queue" )

    ---@protected
    function Queue:__init()
        self.front = 0
        self.back = 0
    end

    --- Returns the length of the queue.
    ---@return number
    local function len( self )
        return self.front - self.back
    end

    Queue.__len = len
    Queue.GetLength = len

    --- Appends a value to the end of the queue.
    ---@param value any
    function Queue:Append( value )
        local front = self.front + 1
        self[ front ] = value
        self.front = front
    end

    --- Removes and returns the value at the front of the queue.
    ---@return any
    function Queue:Pop()
        local back, front = self.back, self.front
        if back == front then return nil end

        back = back + 1

        local value = self[ back ]
        self[ back ] = nil -- unreference the value

        -- reset pointers if the queue is empty
        if back == front then
            self.front = 0
            self.back = 0
        else
            self.back = back
        end

        return value
    end

    --- Returns the value at the front of the queue.
    --- @return any
    function Queue:Peek()
        return self[ self.back + 1 ]
    end

    ---@param value any
    function Queue:Prepend( value )
        local back = self.back
        self[ back ] = value
        self.back = back - 1
    end

    --- Removes and returns the value at the back of the queue.
    ---@return any
    function Queue:PopBack()
        local back, front = self.back, self.front
        if back == front then return nil end

        local value = self[ front ]
        self[ front ] = nil -- unreference the value

        front = front - 1

        -- reset pointers if the queue is empty
        if back == front then
            self.front = 0
            self.back = 0
        else
            self.front = front
        end

        return value
    end

    --- Returns the value at the back of the queue.
    ---@return unknown
    function Queue:PeekBack()
        return self[ self.front ]
    end

    function Queue:Clear()
        for i = self.back + 1, self.front, 1 do
            self[ i ] = nil
        end

        self.front = 0
        self.back = 0
    end

    --- Checks if the queue is empty.
    ---@return boolean isEmpty Returns true if the queue is empty.
    function Queue:IsEmpty()
        return self.front == self.back
    end

    --- Returns an iterator for the queue.
    function Queue:Iterator()
        return self.Pop, self
    end

    ---@class gpm.std.QueueClass : gpm.std.Queue
    ---@field __base gpm.std.Queue
    ---@overload fun(): Queue
    std.Queue = class.create( Queue )

end

--- futures library
---@class gpm.std.futures
local futures = include( "std/futures.lua" )
std.futures = futures

std.apairs = futures.apairs
std.yield = futures.yield
std.sleep = futures.sleep

std.Future = futures.Future
std.Task = futures.Task

--- crypto library
---@class gpm.std.crypto
local crypto = include( "std/crypto.lua" )
crypto.deflate = include( "std/crypto.deflate.lua" )
crypto.struct = include( "std/crypto.struct.lua" )
std.crypto = crypto

-- Bit intenger class
std.BigInt = include( "std/bigint.lua" )

-- ByteStream and BitStream classes
std.ByteStream = include( "std/byte_stream.lua" )
std.BitStream = include( "std/bit_stream.lua" )

--- console library
---@class gpm.std.console
local console = include( "std/console.lua" )
std.console = console

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
        "Light Up ♪"
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
    local string_byte = string.byte
    local istable = std.istable

    --- Loads a chunk
    ---@param chunk string | function: The chunk to load, can be a string or a function.
    ---@param chunkName string?: The chunk name, if chunk is binary the name will be ignored.
    ---@param mode string?: The string mode controls whether the chunk can be text or binary (that is, a precompiled chunk). It may be the string "b" (only binary chunks), "t" (only text chunks), or "bt" (both binary and text). The default is "bt".
    ---@param env table?: The environment to load the chunk in.
    ---@return function?: The loaded chunk
    ---@return string?: Error message
    local function load( chunk, chunkName, mode, env )
        if env == nil then env = getfenv( 2 ) end

        local chunk_type = type( chunk )
        if chunk_type == "string" then
            if mode == nil then mode = "bt" end

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

            if fn == nil then
                return nil, "wrong load mode"
            end

            if istable( env ) then
                setfenv( fn, env )
            else
                return nil, "environment must be a table"
            end

            return fn
        elseif chunk_type == "function" then
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

        return nil, "bad argument #1 to \'load\' ('string/function' expected, got '" .. chunk_type .. "')"
    end

    std.load = load

end

--- game library
---@class gpm.std.game
local game = include( "std/game.lua" )
std.game = game

--- level library
std.level = include( "std/level.lua" )

--- Vector2 class
std.Vector2 = include( "std/vector2.lua" )

--- Vector3 class
std.Vector3 = include( "std/vector3.lua" )

if CLIENT_SERVER then
    -- physics library
    std.physics = include( "std/physics.lua" )

    -- entity library
    std.entity = include( "std/entity.lua" )

    -- player library
    std.player = include( "std/player.lua" )

    -- network library
    -- std.net = include( "std/net.lua" )

end

local isInDebug
do

    local developer = console.Variable.get( "developer", "number" )

    -- TODO: Think about engine lib in menu
    local getDeveloper
    if developer == nil then
        getDeveloper = function() return 1 end
    elseif std.DEDICATED_SERVER then
        local value = developer:get()
        developer:addChangeCallback( "isInDebug", function( _, __, new ) value = new end )
        getDeveloper = function() return value end
    else
        getDeveloper = function() return developer:get() end
    end

    function isInDebug()
        return getDeveloper() > 0
    end

    local key2call = { DEVELOPER = getDeveloper }

    setmetatable( std, {
        __index = function( _, key )
            local func = key2call[ key ]
            if func ~= nil then
                return func()
            end
        end
    } )

end

-- Logger
local logger
do

    local string_gsub, string_sub = string.gsub, string.sub
    local console_write = console.write
    local os_date = os.date

    local color_white = Color( 255 )
    std.color_white = color_white

    local infoColor = Color( 70, 135, 255 )
    local warnColor = Color( 255, 130, 90 )
    local errorColor = Color( 250, 55, 40 )
    local debugColor = Color( 0, 200, 150 )
    local secondaryTextColor = Color( 150 )
    local primaryTextColor = Color( 200 )

    local state, stateColor
    if MENU then
        state = "[Main Menu] "
        stateColor = Color( 75, 175, 80 )
    elseif CLIENT then
        state = "[ Client ]  "
        stateColor = Color( 225, 170, 10 )
    elseif SERVER then
        state = "[ Server ]  "
        stateColor = Color( 5, 170, 250 )
    else
        state = "[ Unknown ] "
        stateColor = color_white
    end

    ---@class gpm.std.LoggerOptions
    ---@field color? Color
    ---@field interpolation? boolean
    ---@field debug? fun(): boolean

    ---@alias Logger gpm.std.Logger
    ---@class gpm.std.Logger : gpm.std.Object
    ---@field __class gpm.std.LoggerClass
    local Logger = class.base( "Logger" )

    ---@protected
    ---@param title string
    ---@param options gpm.std.LoggerOptions?
    function Logger:__init( title, options )
        self.title = title
        self.title_color = color_white
        self.interpolation = true
        self.debug_fn = isInDebug

        if options then
            if options.color then
                -- argument( options.color, 2, "Color" )
                self.title_color = options.color
            end

            if options.interpolation ~= nil then
                self.interpolation = options.interpolation == true
            end

            if options.debug then
                self.debug_fn = options.debug
            end
        end

        self.text_color = primaryTextColor
    end

    ---@param color Color
    ---@param level string
    ---@param str string
    function Logger:log( color, level, str, ... )
        if self.interpolation then
            local args = { ... }
            for index = 1, select( '#', ... ) do
                args[ tostring( index ) ] = tostring( args[ index ] )
            end

            str = string_gsub( str, "{([0-9]+)}", args )
        else
            str = string_format( str, ... )
        end

        local title = self.title
        local titleLength = string_len( title )
        if titleLength > 64 then
            title = string_sub( title, 1, 64 )
            titleLength = 64
            self.title = title
        end

        if ( string_len( str ) + titleLength ) > 950 then
            str = string_sub( str, 1, 950 - titleLength ) .. "..."
        end

        console_write( secondaryTextColor, os_date( "%d-%m-%Y %H:%M:%S " ), stateColor, state, color, level, secondaryTextColor, " --> ", self.title_color, title, secondaryTextColor, " : ", self.text_color, str .. "\n")
        return nil
    end

    function Logger:info( ... )
        return self:log( infoColor, "INFO ", ... )
    end

    function Logger:warn( ... )
        return self:log( warnColor, "WARN ", ... )
    end

    function Logger:error( ... )
        return self:log( errorColor, "ERROR", ... )
    end

    function Logger:debug( ... )
        if self:debug_fn() then
            return self:log( debugColor, "DEBUG", ... )
        end

        return nil
    end

    ---@class gpm.std.LoggerClass : gpm.std.Logger
    ---@field __base gpm.std.Logger
    ---@overload fun(title: string, options: gpm.std.LoggerOptions?): Logger
    std.Logger = class.create( Logger )

    logger = std.Logger( gpm.PREFIX, {
        color = Color( 180, 180, 255 ),
        interpolation = false
    } )

    gpm.Logger = logger

end

-- sqlite library
std.sqlite = include( "std/sqlite.lua" )

-- gpm database
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

    --- [SHARED AND MENU] Checks if a binary module is installed and returns its path.
    ---@param name string: The binary module name.
    ---@return boolean: `true` if the binary module is installed, `false` otherwise.
    ---@return string: The absolute path to the binary module.
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

    --- [SHARED AND MENU] Loads a binary module
    ---@param name string The binary module name, for example: "chttp"
    ---@return boolean success: true if the binary module is installed
    ---@return table? module: the binary module table
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

--- http library
---@class gpm.std.http
local http = include( "std/http.lua" )
std.http = http

http.steam = include( "std/http.steam.lua" )
http.github = include( "std/http.github.lua" )

-- Addon class
std.Addon = include( "std/addon.lua" )

if CLIENT_MENU then

    -- menu library
    std.menu = include( "std/menu.lua" )

    -- client library
    std.client = include( "std/client.lua" )

    -- input library
    std.input = include( "std/input.lua" )

end

-- server library
std.server = include( "std/server.lua" )

if std.TYPE.COUNT ~= 44 then
    logger:warn( "Global TYPE_COUNT mismatch, data corruption suspected. (" .. tostring( _G.TYPE_COUNT or "missing" ) .. " ~= 44)"  )
end

if std._VERSION ~= "Lua 5.1" then
    logger:warn( "Lua version changed, possible unpredictable behavior. (" .. tostring( _G._VERSION or "missing") .. ")" )
end

logger:info( "Start-up time: %.4f sec.", SysTime() - gpm.StartTime )

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
--         include( "gpm/plugins/" .. files[ i ] )
--     end

-- end

return gpm
