local _G = _G
local assert, error, select, pairs, ipairs, tostring, tonumber, getmetatable, setmetatable, rawget, rawset, getfenv, setfenv = _G.assert, _G.error, _G.select, _G.pairs, _G.ipairs, _G.tostring, _G.tonumber, _G.getmetatable, _G.setmetatable, _G.rawget, _G.rawset, _G.getfenv, _G.setfenv
local include = _G.include

---@class gpm
local gpm = _G.gpm
local gpm_PREFIX = gpm.PREFIX

---@class gpm.std
local std = gpm.std
if std == nil then
    std = include( "std/constants.lua" )
    gpm.std = std
else
    for key, value in pairs( include( "std/constants.lua" ) ) do
        std[ key ] = value
    end
end

local CLIENT, SERVER, MENU, CLIENT_MENU, CLIENT_SERVER = std.CLIENT, std.SERVER, std.MENU, std.CLIENT_MENU, std.CLIENT_SERVER

-- ULib support ( There are no words to describe how much I hate Ulysses Team )
if CLIENT_SERVER and _G.file.Exists( "ulib/shared/hook.lua", "LUA" ) then
    include( "ulib/shared/hook.lua" )
end

-- client-side files
if SERVER then
    local AddCSLuaFile = _G.AddCSLuaFile

    AddCSLuaFile( "gpm/3rd-party/deflate.lua" )
    AddCSLuaFile( "gpm/3rd-party/bigint.lua" )
    AddCSLuaFile( "gpm/database.lua" )
    AddCSLuaFile( "gpm/detour.lua" )
    AddCSLuaFile( "gpm/std.lua" )

    local files = _G.file.Find( "gpm/std/*", "lsv" )
    for i = 1, #files do
        AddCSLuaFile( "gpm/std/" .. files[ i ] )
    end
end

-- lua globals
std.assert = assert
std.collectgarbage = _G.collectgarbage

std.getmetatable = getmetatable
std.setmetatable = setmetatable

std.getfenv = getfenv -- removed in Lua 5.2
std.setfenv = setfenv -- removed in Lua 5.2

std.rawget = rawget
std.rawset = rawset
std.rawequal = _G.rawequal
std.rawlen = _G.rawlen or function( value ) return #value end

std.tostring = tostring
std.select = select

std.inext = ipairs( std )
std.next = _G.next

std.ipairs = ipairs
std.pairs = pairs

std.pcall = _G.pcall
std.xpcall = _G.xpcall

-- dofile - missing in glua

-- load - missing in glua
-- loadfile - missing in glua
-- loadstring - is deprecated in lua 5.2

-- require - broken in glua

local is_table, is_string, is_number, is_function = _G.istable, _G.isstring, _G.isnumber, _G.isfunction
local glua_string, glua_table, glua_jit, glua_system = _G.string, _G.table, _G.jit, _G.system

local string_byte, string_len, string_format = glua_string.byte, glua_string.len, glua_string.format
local table_concat = glua_table.concat

do

    local print = _G.print
    std.print = print

    --- Prints a formatted string to the console.<br>
    --- Basically the same as `print( string.format( str, ... ) )`
    ---@param str any
    ---@vararg any
    function std.printf( str, ... )
        print( string_format( str, ... ) )
    end

end

--- Attempts to convert the value to a number.
---@param value any: The value to convert.
---@param base number: The base used in the string. Can be any integer between 2 and 36, inclusive. (Default: 10)
---@return number: The numeric representation of the value with the given base, or `nil` if the conversion failed.
function std.tonumber( value, base )
    local metatable = getmetatable( value )
    if metatable == nil then
        return tonumber( value, base )
    end

    local fn = metatable.__tonumber
    if is_function( fn ) then
        return fn( value, base )
    end

    return tonumber( value, base )
end

--- Attempts to convert the value to a boolean.
---@param value any: The value to convert.
---@return boolean
function std.tobool( value )
    local metatable = getmetatable( value )
    if metatable == nil then
        return false
    end

    local fn = metatable.__tobool
    if is_function( fn ) then
        return fn( value )
    end

    return true
end

-- coroutine library
local coroutine
do

    local glua_coroutine = _G.coroutine

    coroutine = {
        -- lua
        create = glua_coroutine.create,
        isyieldable = glua_coroutine.isyieldable,
        resume = glua_coroutine.resume,
        running = glua_coroutine.running,
        status = glua_coroutine.status,
        wrap = glua_coroutine.wrap,
        yield = glua_coroutine.yield,

        -- gmod
        wait = glua_coroutine.wait
    }

    std.coroutine = coroutine

end

-- jit library
std.jit = glua_jit

---@class gpm.std.debug
local debug = include( "std/debug.lua" )
std.debug = debug

local argument, class, findMetatable
do

    local indexes = {
        ["unknown"] = -1,
        ["nil"] = 0,
        ["boolean"] = 1,
        ["light userdata"] = 2,
        ["number"] = 3,
        ["string"] = 4,
        ["table"] = 5,
        ["function"] = 6,
        ["userdata"] = 7,
        ["thread"] = 8,
        ["Entity"] = CLIENT_SERVER and 9 or nil,
        ["Player"] = CLIENT_SERVER and 9 or nil,
        ["Weapon"] = CLIENT_SERVER and 9 or nil,
        ["NPC"] = CLIENT_SERVER and 9 or nil,
        ["Vehicle"] = CLIENT_SERVER and 9 or nil,
        ["CSEnt"] = CLIENT and 9 or nil,
        ["NextBot"] = CLIENT_SERVER and 9 or nil,
        ["Vector"] = 10,
        ["Angle"] = 11,
        ["PhysObj"] = CLIENT_SERVER and 12 or nil,
        ["ISave"] = CLIENT_SERVER and 13 or nil,
        ["IRestore"] = CLIENT_SERVER and 14 or nil,
        ["CTakeDamageInfo"] = CLIENT_SERVER and 15 or nil,
        ["CEffectData"] = CLIENT_SERVER and 16 or nil,
        ["CMoveData"] = CLIENT_SERVER and 17 or nil,
        ["CRecipientFilter"] = SERVER and 18 or nil,
        ["CUserCmd"] = CLIENT_SERVER and 19 or nil,
        ["IMaterial"] = 21,
        ["Panel"] = CLIENT_MENU and 22 or nil,
        ["CLuaParticle"] = CLIENT and 23 or nil,
        ["CLuaEmitter"] = CLIENT and 24 or nil,
        ["ITexture"] = 25,
        ["bf_read"] = CLIENT_SERVER and 26 or nil,
        ["ConVar"] = 27,
        ["IMesh"] = CLIENT_MENU and 28 or nil,
        ["VMatrix"] = 29,
        ["CSoundPatch"] = CLIENT_SERVER and 30 or nil,
        ["pixelvis_handle_t"] = CLIENT and 31 or nil,
        ["dlight_t"] = CLIENT and 32 or nil,
        ["IVideoWriter"] = CLIENT_MENU and 33 or nil,
        ["File"] = 34,
        ["CLuaLocomotion"] = SERVER and 35 or nil,
        ["PathFollower"] = SERVER and 36 or nil,
        ["CNavArea"] = SERVER and 37 or nil,
        ["IGModAudioChannel"] = CLIENT and 38 or nil,
        ["CNavLadder"] = SERVER and 39 or nil,
        ["CNewParticleEffect"] = CLIENT and 40 or nil,
        ["ProjectedTexture"] = CLIENT and 41 or nil,
        ["PhysCollide"] = CLIENT_SERVER and 42 or nil,
        ["SurfaceInfo"] = CLIENT_SERVER and 43 or nil,
        ["Color"] = 255
    }

    local metatables = {}

    local function getID( name, metatable )
        local id = indexes[ name ]
        if id then
            return id
        else
            id = rawget( metatable, "MetaID" ) or rawget( metatable, "__metatable_id" )
            if is_number( id ) and id >= 0 then
                return id
            else
                id = 255

                for _ in pairs( metatables ) do
                    id = id + 1
                end

                return id
            end
        end
    end

    do

        local FindMetaTable = _G.FindMetaTable

        function findMetatable( name )
            assert( is_string( name ), "argument #1 (name) must be a string" )

            local metatable = metatables[ name ]
            if metatable then
                return metatable
            end

            metatable = FindMetaTable( name )
            if metatable == nil then
                return nil
            end

            local id = getID( name, metatable )

            -- gpm keys
            rawset( metatable, "__metatable_name", name )
            rawset( metatable, "__metatable_id", id )

            -- glua keys
            rawset( metatable, "MetaName", name )
            rawset( metatable, "MetaID", id )

            metatables[ name ] = metatable
            return metatable
        end

        std.findMetatable = findMetatable

    end

    local debug_fempty = debug.fempty

    do

        local RegisterMetaTable = _G.RegisterMetaTable or debug_fempty

        function std.registerMetatable( name, new )
            assert( is_string( name ), "argument #1 (name) must be a string" )
            assert( is_table( new ), "argument #2 (metatable) must be a table" )

            local old = findMetatable( name )
            if old == nil then
                RegisterMetaTable( name, new )
                local id = getID( name, new )

                -- gpm keys
                rawset( new, "__metatable_name", name )
                rawset( new, "__metatable_id", id )

                -- glua keys
                rawset( new, "MetaName", name )
                rawset( new, "MetaID", id )

                metatables[ name ] = new
                return new
            end

            if new ~= old then
                local id = getID( name, old )

                for key in pairs( old ) do
                    old[ key ] = nil
                end

                -- backwards compatibility
                setmetatable( old, { __index = new, __newindex = new } )

                -- gpm name
                rawset( new, "__metatable_name", name )
                rawset( old, "__metatable_name", name )

                -- gpm id
                rawset( new, "__metatable_id", id )
                rawset( old, "__metatable_id", id )

                -- glua name
                rawset( new, "MetaName", name )
                rawset( old, "MetaName", name )

                -- glua id
                rawset( new, "MetaID", id )
                rawset( old, "MetaID", id )
            end

            return old
        end

    end

    local type
    do

        local glua_type = _G.type

        function type( value )
            local metatable = getmetatable( value )
            if metatable == nil then
                return glua_type( value )
            else
                local cls = rawget( metatable, "__class" )
                if cls == nil then
                    return rawget( metatable, "__metatable_name" ) or rawget( metatable, "MetaName" ) or glua_type( value )
                else
                    return rawget( cls, "__name" ) or glua_type( value )
                end

                return glua_type( value )
            end
        end

        std.type = type

        std.isinstance = function( any, a, b, ... )
            if is_string( a ) then
                if is_string( b ) then
                    a = { a, b, ... }
                else
                    return type( any ) == a
                end
            end

            local name = type( any )

            for i = 1, #a do
                if name == a[ i ] then
                    return true
                end
            end

            return false
        end

        local glua_TypeID = _G.TypeID or function( value )
            return indexes[ glua_type( value ) ] or -1
        end

        std.TypeID = function( value )
            local metatable = getmetatable( value )
            if metatable == nil then
                return glua_TypeID( value )
            else
                local id = rawget( metatable, "__metatable_id" )
                if id == nil then
                    return glua_TypeID( value )
                else
                    return id
                end
            end
        end

    end

    local typeError
    do

        local debug_getinfo = debug.getinfo

        function typeError( num, expected, got )
            return error( "bad argument #" .. num .. " to \'" .. ( debug_getinfo( 3, "n" ).name or "unknown" ) .. "\' ('" .. expected .. "' expected, got '" .. got .. "')", 4 )
        end

    end

    local string_sub = glua_string.sub

    ---Validates the type of the argument.
    ---@param value any The value to validate.
    ---@param num number The argument number.
    ---@vararg any The expected types.
    ---@return any value
    function argument( value, num, ... )
        local length = select( "#", ... )
        if length == 0 then
            return typeError( num, "none", type( value ) )
        end

        local name = type( value )

        if length == 1 then
            local searchable = ...
            if is_function( searchable ) then
                local expected = searchable( value, name, num )
                if is_string( expected ) then
                    return typeError( num, expected, name )
                else
                    return value
                end
            elseif searchable == "any" or name == searchable then
                return value
            end

            return typeError( num, searchable, name )
        end

        local args = { ... }
        for i = 1, length do
            local searchable = args[ i ]
            if is_function( searchable ) then
                local expected = searchable( value, name, num )
                if is_string( expected ) then
                    return typeError( num, expected, name )
                else
                    return value
                end
            elseif searchable == "any" or name == searchable then
                return value
            end
        end

        return typeError( num, table_concat( args, "/", 1, length ), name )
    end

    std.argument = argument

    ---@class gpm.std.class
    class = {}

    ---@class gpm.std.Object
    ---@field __name string name of the object
    ---@field __class Class class of the object (must be defined)
    ---@field __parent gpm.std.Class | nil parent of the class (must be defined)
    ---@alias Object gpm.std.Object

    ---@class gpm.std.Class : gpm.std.Object
    ---@field __base gpm.std.Object base of the class (must be defined)
    ---@field __inherited fun(parent: gpm.std.Class, child: gpm.std.Class) | nil called when a class is inherited
    ---@alias Class gpm.std.Class

    ---@param obj Object
    ---@return string
    local function base__tostring( obj )
        return string_format( "%s: %p", rawget( getmetatable( obj ),  "__name" ), obj )
    end

    ---@param name string
    ---@param parent Class | unknown | nil
    ---@return Object
    function class.base( name, parent )
        local base = {
            __name = name,
            __tostring = base__tostring
        }

        base.__index = base

        if parent then
            base.__parent = parent

            local parent_base = rawget( parent, "__base" )
            if parent_base == nil then
                error( "parent class has no base", 2 )
            end

            setmetatable( base, { __index = parent_base } )

            -- copy metamethods from parent
            for key, value in pairs( parent_base ) do
                if string_sub( key, 1, 2 ) == "__" and not ( key == "__index" and value == parent_base ) and key ~= "__name" then
                    base[ key ] = value
                end
            end
        end

        return base
    end

    --- Creates a new object from the given base.
    ---@param base Object
    ---@return Object
    local function new( base, ... )
        local obj = setmetatable( {}, base )

        local fn = rawget( base, "__init" )
        if is_function( fn ) then
            fn( obj, ... )
        end

        return obj
    end

    class.new = new

    ---@param self Class
    ---@return Object
    local function class__call( self, ... )
        local fn = rawget( self, "new" )
        if is_function( fn ) then
            return fn( ... )
        else
            return new( self.__base, ... )
        end
    end

    ---@param cls Class
    ---@return string
    local function class__tostring( cls )
        return string_format( "%sClass: %p", rawget( rawget( cls, "__base" ), "__name" ), cls )
    end

    ---@param base Object
    ---@return Class | unknown
    function class.create( base )
        local cls = setmetatable( { __base = base }, {
            __index = base,
            __call = class__call,
            __tostring = class__tostring
        } ) ---@cast cls -Object

        rawset( base, "__class", cls )
        return cls
    end

    ---@param cls Class | unknown
    function class.inherited( cls )
        local base = rawget( cls, "__base" )
        if base == nil then return end

        local parent = rawget( base, "__parent" )
        if parent == nil or not parent.__inherited then return end
        parent:__inherited( cls )
    end

    std.class = class

end

-- symbol library
do

    ---@class gpm.std.Symbol : userdata
    ---@alias Symbol gpm.std.Symbol

    local function __tostring( self )
        return getmetatable( self ).__name
    end

    ---@param name string
    ---@return Symbol
    function std.Symbol( name )
        ---@class gpm.std.Symbol
        local obj = debug.newproxy( true )
        local meta = getmetatable( obj )
        meta.__name = "Symbol(\"" .. tostring( name ) .. "\")"
        meta.__tostring = __tostring
        return obj
    end

end

-- bit library
do

    local glua_bit = _G.bit

    std.bit = {
        arshift = glua_bit.arshift,
        band = glua_bit.band,
        bnot = glua_bit.bnot,
        bor = glua_bit.bor,
        bswap = glua_bit.bswap,
        bxor = glua_bit.bxor,
        lshift = glua_bit.lshift,
        rol = glua_bit.rol,
        ror = glua_bit.ror,
        rshift = glua_bit.rshift,
        tobit = glua_bit.tobit,
        tohex = glua_bit.tohex
    }

end

-- math library
local math = include( "std/math.lua" )
std.math = math

-- is library
local is = include( "std/is.lua" )
std.is = is

is_string, is_number, is_function = is.string, is.number, is["function"]

-- Queue class
do

    ---@alias Queue gpm.std.Queue
    ---@class gpm.std.Queue : gpm.std.Object
    ---@field __class gpm.std.QueueClass
    ---@field private front integer
    ---@field private back integer
    local Queue = class.base("Queue")

    ---@protected
    function Queue:__init()
        self.front = 0
        self.back = 0
    end

    function Queue:len()
        return self.front - self.back
    end

    ---@param value any
    function Queue:append(value)
        self.front = self.front + 1
        self[self.front] = value
    end

    function Queue:pop()
        if self.back ~= self.front then
            self.back = self.back + 1

            local value = self[self.back]
            self[self.back] = nil -- unreference the value

            -- reset pointers if the queue is empty
            if self.back == self.front then
                self.front = 0
                self.back = 0
            end

            return value
        end
    end

    function Queue:peek()
        return self[self.back + 1]
    end

    ---@param value any
    function Queue:prepend(value)
        self[self.back] = value
        self.back = self.back - 1
    end

    function Queue:popBack()
        if self.back ~= self.front then
            local value = self[self.front]
            self[self.front] = nil

            self.front = self.front - 1

            -- reset pointers if the queue is empty
            if self.back == self.front then
                self.front = 0
                self.back = 0
            end

            return value
        end
    end

    function Queue:peekBack()
        return self[self.front]
    end

    function Queue:clear()
        for i = self.back + 1, self.front do
            self[i] = nil
        end

        self.front = 0
        self.back = 0
    end

    --- Checks if the queue is empty.
    ---@return boolean isEmpty Returns true if the queue is empty.
    function Queue:empty()
        return self.front == self.back
    end

    function Queue:iterator()
        return self.pop, self
    end

    ---@class gpm.std.QueueClass : gpm.std.Queue
    ---@field __base gpm.std.Queue
    ---@overload fun(): Queue
    std.Queue = class.create(Queue)
end

-- futures library
local futures = include( "std/futures.lua" )
std.futures = futures
std.run = futures.run
std.yield = futures.yield
std.apairs = futures.apairs
std.Future = futures.Future
std.Task = futures.Task

---@class gpm.std.os
---@field screenWidth number The width of the game's window (in pixels).
---@field screenHeight number The height of the game's window (in pixels).
local os = include( "std/os.lua" )
std.os = os

-- table library
local table = include( "std/table.lua" )
std.table = table

---@class gpm.std.string
local string = include( "std/string.lua" )
std.string = string

string.utf8 = include( "std/string.utf8.lua" )

-- console library
local console = include( "std/console.lua" )
std.console = console

---@class gpm.std.crypto
local crypto = include( "std/crypto.lua" )
crypto.deflate = include( "std/crypto.deflate.lua" )
-- TODO: struct library
-- crypto.struct = include( "std/crypto.struct.lua" )
std.crypto = crypto

-- Color class
local Color = include( "std/color.lua" )
std.Color = Color

-- Bit intenger class
-- std.BigInt = include( "std/bigint.lua" )

-- error
do

    local debug_getstack, debug_getupvalue, debug_getlocal = debug.getstack, debug.getupvalue, debug.getlocal
    local ErrorNoHalt, ErrorNoHaltWithStack = _G.ErrorNoHalt, _G.ErrorNoHaltWithStack
    local coroutine_running = coroutine.running
    local string_rep = string.rep

    local callStack, callStackSize = {}, 0

    local captureStack = function( stackPos )
        return debug_getstack( stackPos or 1 )
    end

    local pushCallStack = function( stack )
        local size = callStackSize + 1
        callStack[ size ] = stack
        callStackSize = size
    end

    local popCallStack = function()
        local pos = callStackSize
        if pos == 0 then
            return nil
        end

        local stack = callStack[ pos ]
        callStack[ pos ] = nil
        callStackSize = pos - 1
        return stack
    end

    local appendStack = function( stack )
        return pushCallStack( { stack, callStack[ callStackSize ] } )
    end

    local mergeStack = function( stack )
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
    function Error:__index(key)
        if key == "name" then
            return self.__name
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
    ---@param stackPos number?
    function Error:__init( message, fileName, lineNumber, stackPos )
        self.message = message
        self.fileName = fileName
        self.lineNumber = lineNumber

        local stack = captureStack( stackPos )
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
        if is_string( self ) then
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
    std.Error = ErrorClass

    --- Creates a new `Error` with custom name
    ---@param name string
    ---@param base Error | nil
    ---@return Error
    function ErrorClass.make( name, base )
        return class.create( class.base(name, base or std.Error) ) ---@type Error
    end

    ---@alias gpm.std.ErrorType
    ---| number # error with level
    ---| `-1` # ErrorNoHalt
    ---| `-2` # ErrorNoHaltWithStack

    ---@class gpm.std.error
    ---@overload fun(message: any, errorLevel: gpm.std.ErrorType?)
    std.error = std.error or setmetatable( {}, {
        ---@param level gpm.std.ErrorType?
        __call = function( self, message, level )
            if not coroutine_running() then
                message = tostring( message )
            end

            if level == -1 then
                return ErrorNoHalt( message )
            elseif level == -2 then
                return ErrorNoHaltWithStack( message )
            else
                return error( message, level )
            end
        end
    } )

    std.error.NotImplementedError = ErrorClass.make( "NotImplementedError" )
    std.error.FutureCancelError = ErrorClass.make( "FutureCancelError" )
    std.error.InvalidStateError = ErrorClass.make( "InvalidStateError" )
    std.error.CodeCompileError = ErrorClass.make( "CodeCompileError" )
    std.error.FileSystemError = ErrorClass.make( "FileSystemError" )
    std.error.WebClientError = ErrorClass.make( "WebClientError" )
    std.error.RuntimeError = ErrorClass.make( "RuntimeError" )
    std.error.PackageError = ErrorClass.make( "PackageError" )
    std.error.ModuleError = ErrorClass.make( "ModuleError" )
    std.error.SourceError = ErrorClass.make( "SourceError" )
    std.error.FutureError = ErrorClass.make( "FutureError" )
    std.error.AddonError = ErrorClass.make( "AddonError" )
    std.error.RangeError = ErrorClass.make( "RangeError" )
    std.error.TypeError = ErrorClass.make( "TypeError" )
    std.error.SQLError = ErrorClass.make( "SQLError" )
    std.error.Error = ErrorClass
end

-- sqlite library
std.sqlite = include( "std/sqlite.lua" )

-- database functions ( gpm only )
include( "database.lua" )

---@class gpm.std.game
local game = include( "std/game.lua" )
std.game = game

-- level library
std.level = include( "std/level.lua" )

local isDedicatedServer = false
if CLIENT_SERVER then
    isDedicatedServer = game.isDedicatedServer()

    -- entity library
    std.entity = include( "std/entity.lua" )

    -- player library
    std.player = include( "std/player.lua" )

    -- network library
    -- std.net = include( "std/net.lua" )

end

-- hook library
local hook = include( "std/hook.lua" )
std.hook = hook

-- timer library
std.timer = include( "std/timer.lua" )

local isInDebug
do

    local developer = console.variable.get( "developer" )

    -- TODO: Think about engine lib in menu
    if isDedicatedServer then
        local value = developer and developer:GetInt() or 0

        _G.cvars.AddChangeCallback( "developer", function( _, __, str )
            value = tonumber( str, 10 )
        end, gpm_PREFIX .. "::Developer" )

        isInDebug = function() return value end
    else
        local console_variable_getInt = console.variable.getInt
        isInDebug = function() return console_variable_getInt( developer ) end
    end

    local key2call = { DEVELOPER = isInDebug }

    setmetatable( std, {
        __index = function( _, key )
            local func = key2call[ key ]
            if func == nil then
                return nil
            else
                return func()
            end
        end
    } )

end

-- path library
std.path = include( "std/path.lua" )

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
    local Logger = class.base("Logger")

    ---@protected
    ---@param title string
    ---@param options gpm.std.LoggerOptions?
    function Logger:__init(title, options)
        argument( title, 1, "string" )
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
                argument( options.debug, 2, "function" )
                self.debug_fn = options.debug
            end
        end

        self.text_color = primaryTextColor
    end

    ---@param color Color
    ---@param level string
    ---@param str string
    function Logger:Log( color, level, str, ... )
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

    function Logger:Info( ... )
        return self:Log( infoColor, "INFO ", ... )
    end

    function Logger:Warn( ... )
        return self:Log( warnColor, "WARN ", ... )
    end

    function Logger:Error( ... )
        return self:Log( errorColor, "ERROR", ... )
    end

    function Logger:Debug( ... )
        if self:debug_fn() then
            return self:Log( debugColor, "DEBUG", ... )
        end

        return nil
    end

    ---@class gpm.std.LoggerClass : gpm.std.Logger
    ---@field __base gpm.std.Logger
    ---@overload fun(title: string, options: gpm.std.LoggerOptions?): Logger
    std.Logger = class.create( Logger )

    logger = std.Logger( gpm_PREFIX, {
        color = Color( 180, 180, 255 ),
        interpolation = false
    } )

    gpm.Logger = logger

end

-- Version class
std.Version = include( "std/version.lua" )

-- TODO: https://github.com/toxidroma/class-war

-- Material
do

    local string_dec2bin = string.dec2bin

    -- TODO: Think about material library

    local Material = game.Material
    if Material == nil then
        Material = _G.Material

        function std.Material( name, parameters )
            if parameters and parameters > 0 then
                parameters = string_dec2bin( parameters, true )

                local buffer = {}

                if string_byte( parameters, 1 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "vertexlitgeneric"
                end

                if string_byte( parameters, 2 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "nocull"
                end

                if string_byte( parameters, 3 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "alphatest"
                end

                if string_byte( parameters, 4 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "mips"
                end

                if string_byte( parameters, 5 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "noclamp"
                end

                if string_byte( parameters, 6 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "smooth"
                end

                if string_byte( parameters, 7 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "ignorez"
                end

                return Material( name, table_concat( buffer, " " ) )
            end

            return Material( name )
        end
    else

        ---Either returns the material with the given name, or loads the material interpreting the first argument as the path.<br>
        ---.png, .jpg and other image formats<br><br>
        ---This function is capable to loading .png or .jpg images, generating a texture and material for them on the fly.<br><br>
        ---PNG, JPEG, GIF, and TGA files will work, but only if they have the .png or .jpg file extensions (even if the actual image format doesn't match the file extension)
        ---@param name string The material name or path relative to the materials/ folder.<br>Paths outside the materials/ folder like data/MyImage.jpg or maps/thumb/gm_construct.png will also work for when generating materials.<br>To retrieve a Lua material created with CreateMaterial, just prepend a ! to the material name.
        ---@param parameters? number A bit flag of material parameters.
        ---@return IMaterial
        function std.Material( name, parameters )
            if parameters and parameters > 0 then
                ---@diagnostic disable-next-line: return-type-mismatch
                return Material( name, string_dec2bin( parameters, true ) )
            end

            ---@diagnostic disable-next-line: return-type-mismatch
            return Material( name )
        end

    end

end

-- loadbinary
local loadbinary
do

    local file_Exists = _G.file.Exists
    local require = _G.require

    local isEdge = glua_jit.version_num ~= 20004
    local is32 = glua_jit.arch == "x86"

    local head = "lua/bin/gm" .. ( ( CLIENT and not MENU ) and "cl" or "sv" ) .. "_"
    local tail = "_" .. ( { "osx64", "osx", "linux64", "linux", "win64", "win32" } )[ ( glua_system.IsWindows() and 4 or 0 ) + ( glua_system.IsLinux() and 2 or 0 ) + ( is32 and 1 or 0 ) + 1 ] .. ".dll"

    local function isBinaryModuleInstalled( name )
        if name == "" then return false, "" end

        local filePath = head .. name .. tail
        if file_Exists( filePath, "MOD" ) then
            return true, filePath
        end

        if isEdge and is32 and tail == "_linux.dll" then
            filePath = head .. name .. "_linux32.dll"
            if file_Exists( filePath, "MOD" ) then
                return true, filePath
            end
        end

        return false, filePath
    end

    game.isBinaryModuleInstalled = isBinaryModuleInstalled

    local sv_allowcslua = console.variable.get( "sv_allowcslua" )
    local console_variable_getBool = console.variable.getBool

    ---Loads a binary module
    ---@param name string The binary module name, for example: "chttp"
    ---@return boolean success: true if the binary module is installed
    ---@return table? module: the binary module table
    function loadbinary( name )
        if isBinaryModuleInstalled( name ) then
            if sv_allowcslua and console_variable_getBool( sv_allowcslua ) then
                console.variable.setBool( sv_allowcslua, false )
            end

            require( name )
            return true, _G[ name ]
        end

        return false, nil
    end

    std.loadbinary = loadbinary

end

-- https://github.com/WilliamVenner/gmsv_workshop
if SERVER and not ( is_table( _G.steamworks ) and is_function( _G.steamworks.DownloadUGC ) ) then
    loadbinary( "workshop" )
end

-- https://github.com/willox/gmbc
loadbinary( "gmbc" )

do

    ---@diagnostic disable-next-line: undefined-field
    local CompileString, gmbc_load_bytecode = _G.CompileString, _G.gmbc_load_bytecode

    --- Loads a chunk
    ---@param chunk string | function: The chunk to load, can be a string or a function.
    ---@param chunkName string?: The chunk name, if chunk is binary the name will be ignored.
    ---@param mode string?: The string mode controls whether the chunk can be text or binary (that is, a precompiled chunk). It may be the string "b" (only binary chunks), "t" (only text chunks), or "bt" (both binary and text). The default is "bt".
    ---@param env table?: The environment to load the chunk in.
    ---@return function?: The loaded chunk
    ---@return string?: Error message
    local function load( chunk, chunkName, mode, env )
        if env == nil then env = getfenv( 2 ) end

        if is_string( chunk ) then
            if mode == nil then mode = "bt" end

            local fn
            ---@diagnostic disable-next-line: param-type-mismatch
            if ( mode == "bt" or mode == "tb" or mode == "b" ) and string_byte( chunk, 1 ) == 0x1B then
                if gmbc_load_bytecode == nil then
                    return nil, "bytecode compilation is not supported"
                else
                    fn = gmbc_load_bytecode( chunk )
                end
            elseif ( mode == "bt" or mode == "tb" or mode == "t" ) then
                ---@diagnostic disable-next-line: param-type-mismatch
                fn = CompileString( chunk, chunkName, false )
                if is_string( fn ) then
                    ---@cast fn string
                    return nil, fn
                end
            end

            ---@cast fn function | nil
            if fn == nil then
                return nil, "wrong load mode"
            end

            if is_table( env ) then
                setfenv( fn, env )
            else
                return nil, "environment must be a table"
            end

            return fn
        elseif is_function( chunk ) then
            local segment = chunk()
            if segment == nil then
                return nil, "first segment is nil"
            end

            local result, length = {}, 0

            while segment do
                length = length + 1
                result[ length ] = segment
                segment = chunk()
            end

            return load( table_concat( result, "", 1, length ), chunkName, mode, env )
        end

        return nil, "wrong chunk type"
    end

    std.load = load

end

-- http client class
std.HttpClient = include( "std/http.lua" )

-- file library
-- local file = include( "std/file.lua" )
-- std.file = file

do

    local math_ceil = math.ceil

    ---Returns the bit count of the given value.
    ---@param value any: The value to get the bit count of.
    ---@return number: The bit count of the value.
    local function bitcount( value )
        local metatable = getmetatable( value )
        if metatable == nil then
            return 0
        end

        local fn = metatable.__bitcount
        if is_function( fn ) then
            return fn( value )
        end

        return 0
    end

    std.bitcount = bitcount

    ---Returns the byte count of the given value.
    ---@param value any: The value to get the byte count of.
    ---@return number: The byte count of the value.
    function std.bytecount( value )
        return math_ceil( bitcount( value ) / 8 )
    end

    findMetatable( "nil" ).__tobool = function() return false end

    -- boolean
    do

        local metatable = findMetatable( "boolean" )
        metatable.__bitcount = function() return 1 end
        metatable.__tobool = function( value ) return value end

    end

    -- number
    do

        local math_log, math_ln2, math_isfinite = math.log, math.ln2, math.isfinite
        local metatable = findMetatable( "number" )

        metatable.__bitcount = function( value )
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

        metatable.__tobool = function( value )
            return value ~= 0
        end

    end

    -- string
    do

        local metatable = findMetatable( "string" )

        metatable.__bitcount = function( value )
            return string_len( value ) * 8
        end

        metatable.__tobool = function( value )
            return value ~= "" and value ~= "0" and value ~= "false"
        end

    end

end

if CLIENT_MENU then
    hook.add( "OnScreenSizeChanged", gpm_PREFIX .. "::ScreenSize", function( _, __, width, height )
        os.screenWidth, os.screenHeight = width, height
    end, hook.PRE )

    os.screenWidth, os.screenHeight = _G.ScrW(), _G.ScrH()
end

if std.TYPE.COUNT ~= 44 then
    logger:Warn( "Global TYPE_COUNT mismatch, data corruption suspected. (" .. tostring( _G.TYPE_COUNT or "missing" ) .. " ~= 44)"  )
end

if std._VERSION ~= "Lua 5.1" then
    logger:Warn( "Lua version changed, possible unpredictable behavior. (" .. tostring( _G._VERSION or "missing") .. ")" )
end
