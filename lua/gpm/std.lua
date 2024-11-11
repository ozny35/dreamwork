local _G = _G
local assert, error, select, pairs, ipairs, tostring, tonumber, getmetatable, setmetatable, rawget, rawset = _G.assert, _G.error, _G.select, _G.pairs, _G.ipairs, _G.tostring, _G.tonumber, _G.getmetatable, _G.setmetatable, _G.rawget, _G.rawset
local include = _G.include

---@class gpm
local gpm = _G.gpm
local gpm_PREFIX = gpm.PREFIX

---@class gpm.std
local std = gpm.std
if std == nil then
    ---@class gpm.std
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

    AddCSLuaFile( "gpm/detour.lua" )
    AddCSLuaFile( "gpm/std.lua" )

    local files = _G.file.Find( "gpm/std/*", "lsv" )
    for i = 1, #files do
        AddCSLuaFile( "gpm/std/" .. files[ i ] )
    end
end

-- lua globals
std.assert = assert
std.print = _G.print
std.collectgarbage = _G.collectgarbage

std.getmetatable = getmetatable
std.setmetatable = setmetatable

std.getfenv = _G.getfenv -- removed in Lua 5.2
std.setfenv = _G.setfenv -- removed in Lua 5.2

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
local glua_string, glua_table, glua_game = _G.string, _G.table, _G.game
local string_format = glua_string.format
local table_concat = glua_table.concat
local system = _G.system
local jit = _G.jit

-- tonumber
std.tonumber = function( value, base )
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

-- tobool
std.tobool = function( value )
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
local coroutine = _G.coroutine
std.coroutine = coroutine

-- jit library
std.jit = jit

---@class gpm.std.debug
local debug = include( "std/debug.lua" )
std.debug = debug

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

    std.argument = argument

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
    std.class = class
    std.extends = classExtends
    std.extend = function( parent, name, base, static )
        return class( name, base, static, parent )
    end

    -- glua metatables
    std.findMetatable = findMetatable
    std.registerMetatable = registerMetatable

end

-- bit library
std.bit = _G.bit

-- math library
local math = include( "std/math.lua" )
std.math = math

-- is library
local is = include( "std/is.lua" )
std.is = is

is_string, is_number, is_function = is.string, is.number, is["function"]

-- futures library
local futures = include( "std/futures.lua" )

---@class gpm.std.os
---@field screenWidth number The width of the game's window (in pixels).
---@field screenHeight number The height of the game's window (in pixels).
local os = include( "std/os.lua" )
std.os = os

-- table library
local table = include( "std/table.lua" )
std.table = table

-- string library
local string = include( "std/string.lua" )
local string_len = string.len
std.string = string

-- console library
local console = include( "std/console.lua" )
std.console = console

-- crypto library
local crypto = include( "std/crypto.lua" )
std.crypto = crypto

-- utf8 library
string.utf8 = include( "std/utf8.lua" )

-- Color class
local Color = include( "std/color.lua" )
std.Color = Color

-- Stack class
std.Stack = class( "Stack", {
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

    std.Queue = class( "Queue", {
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

    local errorClass = class(
        "Error",
        {
            ["name"] = "Error",
            ["new"] = function( self, message, fileName, lineNumber, stackPos )
                if stackPos == nil then stackPos = 3 end

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
            end,
            ["__tostring"] = function( self )
                if self.fileName then
                    return string_format( "%s:%d: %s: %s", self.fileName, self.lineNumber or 0, self.name, self.message )
                else
                    return self.name .. ": " .. self.message
                end
            end,
            ["display"] = function( self )
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
        },
        {
            __inherited = function( self, child )
                child.__base.name = child.__name or self.name
            end,
            callStack = callStack,
            captureStack = captureStack,
            pushCallStack = pushCallStack,
            popCallStack = popCallStack,
            appendStack = appendStack,
            mergeStack = mergeStack,
        }
    )

    std.error = setmetatable(
        {
            ["NotImplementedError"] = class( "NotImplementedError", nil, nil, errorClass ),
            ["FutureCancelError"] = class( "FutureCancelError", nil, nil, errorClass ),
            ["InvalidStateError"] = class( "InvalidStateError", nil, nil, errorClass ),
            ["CodeCompileError"] = class( "CodeCompileError", nil, nil, errorClass ),
            ["FileSystemError"] = class( "FileSystemError", nil, nil, errorClass ),
            ["WebClientError"] = class( "WebClientError", nil, nil, errorClass ),
            ["RuntimeError"] = class( "RuntimeError", nil, nil, errorClass ),
            ["PackageError"] = class( "PackageError", nil, nil, errorClass ),
            ["ModuleError"] = class( "ModuleError", nil, nil, errorClass ),
            ["SourceError"] = class( "SourceError", nil, nil, errorClass ),
            ["FutureError"] = class( "FutureError", nil, nil, errorClass ),
            ["AddonError"] = class( "AddonError", nil, nil, errorClass ),
            ["RangeError"] = class( "RangeError", nil, nil, errorClass ),
            ["TypeError"] = class( "TypeError", nil, nil, errorClass ),
            ["SQLError"] = class( "SQLError", nil, nil, errorClass ),
            ["Error"] = errorClass
        },
        {
            ["__call"] = function( message, level )
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
        }
    )

end

-- engine library
local engine = include( "std/engine.lua" )
std.engine = engine

-- level library
std.level = include( "std/level.lua" )

local isDedicatedServer = false
if CLIENT_SERVER then

    -- entity library
    std.entity = include( "std/entity.lua" )

    isDedicatedServer = engine.isDedicatedServer()

    -- player library
    std.player = include( "std/player.lua" )

end

-- hook library
local hook = include( "std/hook.lua" )
std.hook = hook

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

    setmetatable( std, {
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

    std.Logger = Logger

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

        function std.Material( name, parameters )
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

        function std.Material( name, parameters )
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

    std.loadbinary = loadbinary

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

    std.bitcount = bitcount

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

    -- Player
    if CLIENT_SERVER then
        local maxplayers_bits = bitcount( glua_game.MaxPlayers() )
        findMetatable( "Player" ).__bitcount = function() return maxplayers_bits end
    end

end

if CLIENT_MENU then
    hook.add( "OnScreenSizeChanged", gpm_PREFIX .. "::ScreenSize", function( _, __, width, height )
        os.screenWidth, os.screenHeight = width, height
    end, hook.PRE )

    os.screenWidth, os.screenHeight = _G.ScrW(), _G.ScrH()
end

if _G.TYPE_COUNT ~= 44 then
    logger:Warn( "Global TYPE_COUNT mismatch, data corruption suspected. (" .. tostring( _G.TYPE_COUNT or "missing" ) .. " ~= 44)"  )
end

if _G._VERSION ~= "Lua 5.1" then
    logger:Warn( "Lua version changed, possible unpredictable behavior. (" .. tostring( _G._VERSION or "missing") .. ")" )
end

return std
