local _G = _G
---@class gpm
local gpm = _G.gpm
local dofile = gpm.dofile
local pairs = _G.pairs
local detour = gpm.detour
local assert, select, ipairs, next, tostring, tonumber, getmetatable, setmetatable, rawget, rawset, pcall, xpcall, getfenv = _G.assert, _G.select, _G.ipairs, _G.next, _G.tostring, _G.tonumber, _G.getmetatable, _G.setmetatable, _G.rawget, _G.rawset, _G.pcall, _G.xpcall, _G.getfenv
local gpm_PREFIX = gpm.PREFIX

---@class gpm.environment
local environment = gpm.environment
if environment == nil then
    environment = dofile( "std/constants.lua", _G, setmetatable )
    gpm.environment = environment
else
    for key, value in pairs( dofile( "std/constants.lua", _G, setmetatable ) ) do
        environment[ key ] = value
    end
end

local CLIENT, SERVER, MENU, CLIENT_MENU, CLIENT_SERVER = environment.CLIENT, environment.SERVER, environment.MENU, environment.CLIENT_MENU, environment.CLIENT_SERVER

-- ULib support ( There are no words to describe how much I hate Ulysses Team )
if CLIENT_SERVER and _G.file.Exists( "ulib/shared/hook.lua", "LUA" ) then
    _G.include( "ulib/shared/hook.lua" )
end

-- client-side files
if SERVER then
    local AddCSLuaFile = _G.AddCSLuaFile

    AddCSLuaFile( "gpm/detour.lua" )
    AddCSLuaFile( "gpm/std.lua" )

    local files = _G.file.Find( "gpm/std/*", "lsv" )
    for i = 1, #files do
        AddCSLuaFile( "gpm/std/" .. files[ i ] )
    end
end

-- lua globals
environment.assert = assert
environment.print = _G.print
environment.collectgarbage = _G.collectgarbage

environment.getmetatable = getmetatable
environment.setmetatable = setmetatable

environment.getfenv = getfenv -- removed in Lua 5.2
environment.setfenv = _G.setfenv -- removed in Lua 5.2

environment.rawget = rawget
environment.rawset = rawset
environment.rawequal = _G.rawequal
environment.rawlen = _G.rawlen or function( value ) return #value end

environment.tostring = tostring
environment.select = select

environment.inext = ipairs( environment )
environment.next = next

environment.ipairs = ipairs
environment.pairs = pairs

environment.pcall = pcall
environment.xpcall = xpcall

-- dofile - missing in glua

-- load - missing in glua
-- loadfile - missing in glua
-- loadstring - is deprecated in lua 5.2

-- require - broken in glua

-- coroutine library
local coroutine = dofile( "std/coroutine.lua", _G.coroutine, _G.CurTime )
environment.coroutine = coroutine

do

    local error, ErrorNoHalt, ErrorNoHaltWithStack = _G.error, _G.ErrorNoHalt, _G.ErrorNoHaltWithStack
    local coroutine_running = coroutine.running

    -- error
    function environment.error( message, level )
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

end

local is_table, is_string, is_number, is_bool, is_function = _G.istable, _G.isstring, _G.isnumber, _G.isbool, _G.isfunction
local glua_string, glua_table, glua_game, glua_engine = _G.string, _G.table, _G.game, _G.engine
local string_format = glua_string.format
local table_concat = glua_table.concat
local system = _G.system
local jit = _G.jit

environment.tonumber = function( value, base )
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

-- jit library
environment.jit = jit

-- debug library
local debug = dofile( "std/debug.lua", glua_string, _G.debug )
environment.debug = debug

local argument, class, type, findMetatable, registerMetatable
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

    end

    do

        local RegisterMetaTable = _G.RegisterMetaTable or debug.fempty

        function registerMetatable( name, new )
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
                setmetatable( old, { ["__index"] = new, ["__newindex"] = new } )

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

        environment.type = type

        environment.isinstance = function( any, a, b, ... )
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

        environment.TypeID = function( value )
            local metatable = getmetatable( value )
            if metatable ~= nil then
                local id = rawget( metatable, "__metatable_id" )
                if id ~= nil then
                    return id
                end
            end

            return glua_TypeID( value )
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

    environment.argument = argument

    local class__call = function( cls, ... )
        local init = rawget( cls, "__init" )
        if init == nil then
            local parent = rawget( cls, "__parent" )
            if parent then
                init = rawget( parent, "__init" )
            end
        end

        local base = rawget( cls, "__base" )
        if base == nil then
            return error( "class '" .. tostring( cls ) .. "' has been corrupted", 2 )
        end

        local obj = {}
        setmetatable( obj, base )

        if init ~= nil then
            local override, new = init( obj, ... )
            if override then return new end
        end

        return obj
    end

    local extends__index = function( cls, key )
        local base = rawget( cls, "__base" )
        if base == nil then return nil end

        local value = rawget( base, key )
        if value == nil then
            local parent = rawget( cls, "__parent" )
            if parent then
                value = parent[ key ]
            end
        end

        return value
    end

    local tostring_object = function( obj )
        return string_format( "@object '%s': %p", obj.__class.__name, obj )
    end

    local tostring_class = function( cls )
        return string_format( "@class '%s': %p", cls.__name, cls )
    end

    local classExtends = function( cls, parent )
        argument( cls, 1, "class" )
        argument( parent, 2, "class" )

        local base = rawget( cls, "__base" )
        if base == nil then
            return error( "class '" .. tostring( cls ) .. "' has been corrupted", 2 )
        end

        local metatable = getmetatable( cls )
        if metatable == nil then
            return error( "metatable of class '" .. tostring( cls ) .. "' has been corrupted", 2 )
        end

        local base_parent = rawget( parent, "__base" )
        if base_parent == nil then
            return error( "invalid parent", 2 )
        end

        if metatable.__index ~= base then
            return error( "class '" .. tostring( cls ) .. "' has already been extended", 2 )
        end

        if rawget( base, "__tostring" ) == tostring_object then
            rawset( base, "__tostring", nil )
        end

        metatable.__index = extends__index
        setmetatable( base, { ["__index"] = base_parent } )

        for key, value in pairs( base_parent ) do
            if string_sub( key, 1, 2 ) == "__" and rawget( base, key ) == nil and not ( key == "__index" and value == base_parent ) then
                rawset( base, key, value )
            end
        end

        local inherited = rawget( parent, "__inherited" )
        if inherited then inherited( parent, cls ) end
        rawset( cls, "__parent", parent )
        rawset( base, "__class", cls )
        return cls
    end

    function class( name, base, static, parent )
        argument( name, 1, "string" )

        if base then
            argument( base, 2, "table" )
            rawset( base, "__index", rawget( base, "__index" ) or base )
            rawset( base, "__tostring", rawget( base, "__tostring" ) or tostring_object )
        else
            base = { ["__tostring"] = tostring_object }
            base.__index = base
        end

        if static then
            argument( static, 3, "table")
            rawset( static, "__init", rawget( base, "new" ) )
            rawset( static, "__name", name )
            rawset( static, "__base", base )
        else
            static = {
                ["__init"] = rawget( base, "new" ),
                ["__name"] = name,
                ["__base"] = base
            }
        end

        rawset( base, "new", nil )

        setmetatable( static, {
            ["__tostring"] = tostring_class,
            ["__metatable_name"] = "class",
            ["__call"] = class__call,
            ["__metatable_id"] = 5,
            ["__index"] = base
        } )

        if parent == nil then
            rawset( base, "__class", static )
        else
            classExtends( static, parent )
        end

        return static
    end

    -- gpm classes
    environment.class = class
    environment.extends = classExtends
    environment.extend = function( parent, name, base, static )
        return class( name, base, static, parent )
    end

    -- glua metatables
    environment.FindMetatable = findMetatable
    environment.RegisterMetatable = registerMetatable

end

-- bit library
local bit = dofile( "std/bit.lua", _G.bit )
environment.bit = bit

-- math library
local math = dofile( "std/math.lua", _G.math )
environment.math = math

-- is library
local is = dofile( "std/is.lua", getmetatable, is_table, debug, findMetatable, registerMetatable, coroutine.create, CLIENT, SERVER, CLIENT_SERVER, CLIENT_MENU )
environment.is = is

is_string, is_number, is_bool, is_function = is.string, is.number, is.bool, is["function"]

-- futures library
local futures = dofile( "std/futures.lua" )

-- os library
local os = dofile( "std/os.lua", _G.os, system, jit, bit, math.fdiv )
environment.os = os

-- table library
local table = dofile( "std/table.lua", glua_table, math, glua_string, select, pairs, is_table, is_string, is_function, getmetatable, setmetatable, rawget, next )
environment.table = table

-- string library
local string = dofile( "std/string.lua", glua_string, table_concat, math, tostring, is_number, is_bool, tonumber )
local string_len = string.len
environment.string = string

-- utf8 library
string.utf8 = dofile( "std/utf8.lua", bit, string, table, math, tonumber )

-- Color class
local Color = dofile( "std/color.lua", _G, class, bit, string, math, is_number, setmetatable, findMetatable( "Color" ) )
environment.Color = Color

-- Stack class
environment.Stack = class( "Stack", {
    ["__tostring"] = function( self )
        return string_format( "Stack: %p [%d/%d]", self, self.pointer, self.size )
    end,
    ["new"] = function( self, size )
        self.size = ( is_number( size ) and size > 0 ) and size or -1
        self.pointer = 0
    end,
    ["IsEmpty"] = function( self )
        return self.pointer == 0
    end,
    ["IsFull"] = function( self )
        return self.pointer == self.size
    end,
    ["Peek"] = function( self )
        return self[ self.pointer ]
    end,
    ["Push"] = function( self, value )
        local pointer = self.pointer
        if pointer ~= self.size then
            pointer = pointer + 1
            self[ pointer ] = value
            self.pointer = pointer
        end

        return pointer
    end,
    ["Pop"] = function( self )
        local pointer = self.pointer
        if pointer == 0 then
            return nil
        end

        self.pointer = pointer - 1
        local value = self[ pointer ]
        self[ pointer ] = nil

        return value
    end,
    ["Empty"] = function( self )
        for index = 1, self.pointer do
            self[ index ] = nil
        end

        self.pointer = 0
    end
} )

-- Queue class
do

    --[[

        Queue References:
            https://github.com/darkwark/queue-lua
            https://en.wikipedia.org/wiki/Queue_(abstract_data_type)

    --]]

    local function enqueue( self, value )
        if not self:IsFull() then
            local rear = self.rear + 1
            self[ rear ] = value
            self.rear = rear
        end

        return nil
    end

    local function dequeue( self )
        if not self:IsEmpty() then
            local front = self.front

            local value = self[ front ]
            self[ front ] = nil

            front = front + 1
            self.front = front

            if ( front * 2 ) >= self.rear then
                self:Optimize()
            end

            return value
        end

        return nil
    end

    environment.Queue = class( "Queue", {
        ["__tostring"] = function( self )
            return string_format( "Queue: %p [%d/%d]", self, self.pointer, self.size )
        end,
        ["new"] = function( self, size )
            self.size = ( is_number( size ) and size > 0 ) and size or -1
            self.front = 1
            self.rear = 0
        end,
        ["Length"] = function( self )
            return ( self.rear - self.front ) + 1
        end,
        ["IsEmpty"] = function( self )
            local rear = self.rear
            return rear == 0 or self.front > rear
        end,
        ["IsFull"] = function( self )
            return self:Length() == self.size
        end,
        ["Push"] = enqueue,
        ["Pop"] = dequeue,
        ["Enqueue"] = enqueue,
        ["Dequeue"] = dequeue,
        ["Get"] = function( self, index )
            return self[ self.front + index ]
        end,
        ["Set"] = function( self, index, value )
            self[ self.front + index ] = value
        end,
        ["Optimize"] = function( self )
            local pointer, buffer = 1, {}

            for index = self.front, self.rear do
                buffer[ pointer ] = self[ index ]
                self[ index ] = nil
                pointer = pointer + 1
            end

            for index = 1, pointer do
                self[ index ] = buffer[ index ]
            end

            self.front = 1
            self.rear = pointer - 1
        end,
        ["Peek"] = function( self )
            return self[ self.front ]
        end,
        ["Empty"] = function( self )
            for index = self.front, self.rear do
                self[ index ] = nil
            end
        end,
        ["Iterator"] = function( self )
            self:Optimize()

            local front, rear = self.front - 1, self.rear
            return function()
                if rear ~= 0 and front < rear then
                    front = front + 1
                    return front, self[ front ]
                end
            end
        end
    } )

end

-- console library
local console = dofile( "std/console.lua", _G, tostring, findMetatable, string_format, getfenv, table.unpack, select )
environment.console = console

-- engine library
local engine = dofile( "std/engine.lua", _G, debug, glua_engine, glua_game, system.IsWindowed, CLIENT_SERVER, CLIENT_MENU, SERVER )
environment.engine = engine

-- level library
environment.level = dofile( "std/level.lua", glua_game, glua_engine, CLIENT_SERVER, SERVER )

local isDedicatedServer = false
if CLIENT_SERVER then

    -- entity library
    environment.entity = dofile( "std/entity.lua", _G, math, findMetatable, CLIENT, SERVER, is.entity, detour, class )

    isDedicatedServer = engine.isDedicatedServer()

    -- player library
    environment.player = dofile( "std/player.lua", _G, error, findMetatable, CLIENT, SERVER, is_string, is_number, isDedicatedServer, glua_game.MaxPlayers, class )

end

-- hook library
local hook = dofile( "std/hook.lua", _G, rawset, getfenv, setmetatable, table.isEmpty )
environment.hook = hook

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

    local key2call = { ["DEVELOPER"] = isInDebug }

    setmetatable( environment, {
        ["__index"] = function( _, key )
            local func = key2call[ key ]
            if func == nil then
                return nil
            else
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
    environment.color_white = color_white

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

    local log = function( self, color, level, str, ... )
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

    local Logger = class( "Logger", {
        ["__tostring"] = function( self )
            return string_format( "Logger: %p [%s]", self, self.title )
        end,
        ["new"] = function( self, title, title_color, interpolation, debug_func )
            argument( title, 1, "string" )
            self.title = title

            if title_color == nil then
                self.title_color = color_white
            else
                argument( title_color, 2, "Color" )
                self.title_color = title_color
            end

            if interpolation == nil then
                self.interpolation = true
            else
                self.interpolation = interpolation == true
            end

            if debug_func == nil then
                self.debug_fn = isInDebug
            else
                argument( debug_func, 1, "function" )
                self.debug_fn = debug_func
            end

            self.text_color = primaryTextColor
        end,
        ["Log"] = log,
        ["Info"] = function( self, ... )
            return log( self, infoColor, "INFO ", ... )
        end,
        ["Warn"] = function( self, ... )
            return log( self, warnColor, "WARN ", ... )
        end,
        ["Error"] = function( self, ... )
            return log( self, errorColor, "ERROR", ... )
        end,
        ["Debug"] = function( self, ... )
            if self:debug_fn() then
                log( self, debugColor, "DEBUG", ... )
            end

            return nil
        end
    } )

    environment.Logger = Logger

    logger = Logger( gpm_PREFIX, Color( 180, 180, 255 ), false )
    gpm.Logger = logger

end

-- Material
do

    local string_dec2bin = string.dec2bin

    -- TODO: Think about material library

    local Material = engine.Material
    if Material == nil then
        local string_byte = string.byte
        Material = _G.Material

        function environment.Material( name, parameters )
            if parameters then
                argument( name, 1, "number", "string" )

                if is_string( parameters ) then
                    return Material( name, parameters )
                elseif parameters > 0 then
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
            end

            return Material( name )
        end
    else
        local string_find = string.find

        function environment.Material( name, parameters )
            if parameters then
                argument( name, 1, "number", "string" )

                if is_string( parameters ) then
                    if parameters == "" then
                        return Material( name )
                    end

                    return Material( name,
                        ( string_find( parameters, "vertexlitgeneric", 1, true ) and "1" or "0" ) ..
                        ( string_find( parameters, "nocull", 1, true ) and "1" or "0" ) ..
                        ( string_find( parameters, "alphatest", 1, true ) and "1" or "0" ) ..
                        ( string_find( parameters, "mips", 1, true ) and "1" or "0" ) ..
                        ( string_find( parameters, "noclamp", 1, true ) and "1" or "0" ) ..
                        ( string_find( parameters, "smooth", 1, true ) and "1" or "0" ) ..
                        ( string_find( parameters, "ignorez", 1, true ) and "1" or "0" )
                    )
                elseif parameters > 0 then
                    return Material( name, string_dec2bin( parameters, true ) )
                end
            end

            return Material( name )
        end
    end

end

-- loadbinary
local loadbinary
do

    local file_Exists = _G.file.Exists
    local require = _G.require

    local isEdge = jit.versionnum ~= 20004
    local is32 = jit.arch == "x86"

    local head = "lua/bin/gm" .. ( ( CLIENT and not MENU ) and "cl" or "sv" ) .. "_"
    local tail = "_" .. ( { "osx64", "osx", "linux64", "linux", "win64", "win32" } )[ ( system.IsWindows() and 4 or 0 ) + ( system.IsLinux() and 2 or 0 ) + ( is32 and 1 or 0 ) + 1 ] .. ".dll"

    local function isBinaryModuleInstalled( name )
        argument( name, 1, "string" )

        if name == "" then
            return false, ""
        end

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

    engine.isBinaryModuleInstalled = isBinaryModuleInstalled

    local sv_allowcslua = console.variable.get( "sv_allowcslua" )
    local console_variable_getBool = console.variable.getBool

    function loadbinary( name )
        if isBinaryModuleInstalled( name ) then
            if console_variable_getBool( sv_allowcslua ) then
                console.variable.setBool( sv_allowcslua, "0" )
            end

            require( name )
            return true, _G[ name ]
        end

        return false, nil
    end

    environment.loadbinary = loadbinary

end

do

    local math_ceil = math.ceil

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

    environment.bitcount = bitcount

    function environment.bytecount( value )
        return math_ceil( bitcount( value ) / 8 )
    end

    -- boolean
    findMetatable( "boolean" ).__bitcount = function() return 1 end

    -- number
    do

        local math_log, math_ln2, math_isfinite = math.log, math.ln2, math.isfinite

        findMetatable( "number" ).__bitcount = function( value )
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

    -- string
    findMetatable( "string" ).__bitcount = function( value )
        return string_len( value ) * 8
    end

    -- Player
    if CLIENT_SERVER then
        local maxplayers_bits = bitcount( glua_game.MaxPlayers() )
        findMetatable( "Player" ).__bitcount = function() return maxplayers_bits end
    end

end

if CLIENT_MENU then
    hook.add( "OnScreenSizeChanged", gpm_PREFIX .. "::ScreenSize", function( _, __, width, height )
        os.ScreenWidth, os.ScreenHeight = width, height
    end, hook.PRE )

    os.ScreenWidth, os.ScreenHeight = _G.ScrW(), _G.ScrH()
end

if _G.TYPE_COUNT ~= 44 then
    logger:Warn( "Global TYPE_COUNT mismatch, data corruption suspected. (" .. tostring( _G.TYPE_COUNT or "missing" ) .. " ~= 44)"  )
end

if _G._VERSION ~= "Lua 5.1" then
    logger:Warn( "Lua version changed, possible unpredictable behavior. (" .. tostring( _G._VERSION or "missing") .. ")" )
end

return environment
