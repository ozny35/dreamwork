local _G = _G
local gpm = _G.gpm
local RunConsoleCommand = _G.RunConsoleCommand

---@class gpm.std
local std = gpm.std

local debug = std.debug
local Future = std.Future
local string_format = std.string.format
local debug_getfpackage = debug.getfpackage
local bit_bor, setmetatable = std.bit.bor, std.setmetatable
local table_insert, table_remove = std.table.insert, std.table.remove

--- [SHARED AND MENU]
---
--- The console variable/commands flags.
---
--- Used in engine internally.
---
--- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/public/tier1/iconvar.h#L39
---
--- https://developer.valvesoftware.com/wiki/Developer_Console_Control#The_FCVAR_flags
---
--- https://wiki.facepunch.com/gmod/Enums/FCVAR
---
---@alias gpm.std.console.Command.Flags gpm.std.console.Variable.Flags
---@class gpm.std.console.Variable.Flags : integer
local flags = {
    --- The default, no flags at all.
    NONE = 0,

    --- If this is set, don't add to linked list, etc.
    UNREGISTERED = 1,

    --- Hidden in released products.
    ---
    --- Flag is removed automatically if `ALLOW_DEVELOPMENT_CVARS` is defined.
    DEVELOPMENTONLY = 2,

    --- Defined by the game DLL.
    GAMEDLL = 4,

    --- Defined by the client DLL.
    CLIENTDLL = 8,

    --- Doesn't appear in find or autocomplete.
    ---
    --- Like `DEVELOPMENTONLY`, but can't be compiled out.
    HIDDEN = 16,

    --- It's a server cvar, but we don't send the data since it's a password, etc.
    ---
    --- Sends `1` if it's not bland/zero, `0` otherwise as value.
    PROTECTED = 32,

    --- This cvar cannot be changed by clients connected to a multiplayer server.
    SPONLY = 64,

    --- Save the cvar value into `client.vdf`.
    ARCHIVE = 128,

    --- For server-side cvars, notifies all players with blue chat text when the value gets changed.
    NOTIFY = 256,

    --- For clientside commands, sends the value to the server.
    USERINFO = 512,

    --- In multiplayer, prevents this command/variable from being used unless the server has `sv_cheats` turned on.
    ---
    --- If a client connects to a server where cheats are disabled (which is the default), all client side console variables labeled as FCVAR_CHEAT are reverted to their default values and can't be changed as long as the client stays connected.
    ---
    --- Console commands marked as `CHEAT` can't be executed either.
    ---
    --- As a general rule of thumb, any client-side command that isn't specifically meant to be configured by users should be marked with this flag, as even the most harmless looking commands can sometimes be misused to cheat.
    ---
    --- For server-side only commands you can be more lenient, since these would have no effect when changed by connected clients anyway.
    CHEAT = 16384,

    --- This cvar's string cannot contain unprintable characters ( e.g., used for player name etc ).
    PRINTABLEONLY = 1024,

    --- If this is a `SERVER`, don't log changes to the log file / console if we are creating a log.
    UNLOGGED = 2048,

    --- Tells the engine to never print this variable as a string.
    ---
    --- This is used for variables which may contain control characters.
    NEVER_AS_STRING = 4096,

    --- When set on a console variable, all connected clients will be forced to match the server-side value.
    ---
    --- This should be used for shared code where it's important that both sides run the exact same path using the same data.
    ---
    --- (e.g. predicted movement/weapons, game rules)
    REPLICATED = 8192,

    --- When starting to record a demo file, explicitly adds the value of this console variable to the recording to ensure a correct playback.
    DEMO = 65536,

    --- Opposite of `DEMO`, ensures the cvar is not recorded in demos.
    DONTRECORD = 131072,

    --- If set and this variable changes, it forces a material reload.
    RELOAD_MATERIALS = 1048576,

    --- If set and this variable changes, it forces a texture reload.
    RELOAD_TEXTURES = 2097152,

    --- Prevents this variable from being changed while the client is currently in a server, due to the possibility of exploitation of the command (e.g. `fps_max`).
    NOT_CONNECTED = 4194304,

    --- Indicates this cvar is read from the material system thread.
    MATERIAL_SYSTEM_THREAD = 8388608,

    --- Like `ARCHIVE`, but for Xbox 360. Needless to say, this is not particularly useful to most modders.
    ARCHIVE_XBOX = 16777216,

    --- Used as a debugging tool necessary to check material system thread convars.
    ACCESSIBLE_FROM_THREADS = 33554432,

    --- The server is allowed to execute this command on clients via `ClientCommand/NET_StringCmd/CBaseClientState::ProcessStringCmd`.
    SERVER_CAN_EXECUTE = 268435456,

    --- If this is set, then the server is not allowed to query this cvar's value (via `IServerPluginHelpers::StartQueryCvarValue`).
    SERVER_CANNOT_QUERY = 536870912,

    --- `IVEngineClient::ClientCmd` is allowed to execute this command.
    CLIENTCMD_CAN_EXECUTE = 1073741824,

    --- Summary of `RELOAD_MATERIALS`, `RELOAD_TEXTURES` and `MATERIAL_SYSTEM_THREAD`.
    MATERIAL_THREAD_MASK = 11534336,

    -- Garry's Mod only
    --- Set automatically on all cvars and console commands created by the `client` Lua state.
    LUA_CLIENT = 262144,

    --- Set automatically on all cvars and console commands created by the `server` Lua state.
    LUA_SERVER = 524288
}

--- [SHARED AND MENU]
---
--- The source engine console library.
---
---@class gpm.std.console
---@field visible boolean `true` if the console is visible, `false` otherwise.
local console = {}
std.console = console

if std.MENU then

    --- [MENU]
    ---
    --- Shows the console.
    ---
    console.show = _G.gui and _G.gui.ShowConsole or function()
        RunConsoleCommand( "showconsole" )
    end

    --- [MENU]
    ---
    --- Hides the console.
    ---
    function console.hide()
        RunConsoleCommand( "hideconsole" )
    end

    --- [MENU]
    ---
    --- Toggles the console.
    ---
    function console.toggle()
        RunConsoleCommand( "toggleconsole" )
    end

end

if std.CLIENT_MENU then

    local gui = _G.gui
    if gui == nil then
        console.visible = false
    else
        local gui_IsConsoleVisible = gui.IsConsoleVisible
        if gui_IsConsoleVisible == nil then
            console.visible = false
        else
            console.visible = gui_IsConsoleVisible()

            _G.timer.Create( gpm.PREFIX .. " - gui.IsConsoleVisible", 0.25, 0, function()
                console.visible = gui_IsConsoleVisible()
            end )
        end
    end

end

do

    local MsgC = _G.MsgC
    console.write = MsgC

    --- [SHARED AND MENU]
    ---
    --- Writes a colored message to the console on a new line.
    ---
    ---@param ... string | Color: The message to write to the console.
    function console.writeLine( ... )
        return MsgC( ... ), MsgC( "\n" )
    end

end

do

    local AddConsoleCommand = _G.AddConsoleCommand

    --- [SHARED AND MENU]
    ---
    --- The console command object.
    ---
    ---@alias ConsoleCommand gpm.std.console.Command
    ---@class gpm.std.console.Command : gpm.std.Object
    ---@field __class gpm.std.console.Command
    ---@field name string The name of the console command.
    ---@field description string The help text of the console command.
    ---@field flags integer The flags of the console command.
    local Command = std.class.base( "ConsoleCommand" )

    local commands = {}

    ---@param name string The name of the console command.
    ---@param description string?: The help text of the console command.
    ---@param ... gpm.std.console.Command.Flags?: The flags of the console command.
    ---@protected
    function Command:__init( name, description, ... )
        self.name = name

        if description == nil then description = "" end
        self.description = description

        local flags
        if ... then
            flags = bit_bor( 0, ... )
        else
            flags = 0
        end

        self.flags = flags

        AddConsoleCommand( name, description, flags )

        commands[ name ] = self
        self.callbacks = {}
    end

    ---@param name string
    ---@return gpm.std.console.Command?
    function Command:__new( name )
        return commands[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- The console command class.
    ---
    ---@class gpm.std.console.CommandClass: gpm.std.console.Command
    ---@field __base gpm.std.console.Command
    ---@overload fun( name: string, description: string?, ...: gpm.std.console.Command.Flags? ): gpm.std.console.Command
    local CommandClass = std.class.create( Command )
    console.Command = CommandClass

    CommandClass.Flags = flags

    --- [SHARED AND MENU]
    ---
    --- Returns the console command with the given name.
    ---
    ---@return gpm.std.console.Command? obj The console command with the given name, or `nil` if it does not exist.
    function CommandClass.get( name )
        return commands[ name ]
    end

    if std.CLIENT_MENU and _G.input ~= nil then
        CommandClass.translateAlias = _G.input.TranslateAlias
    end

    CommandClass.run = RunConsoleCommand

    --- [SHARED AND MENU]
    ---
    --- Runs the console command.
    ---
    ---@param ... string: The arguments to pass to the console command.
    function Command:run( ... )
        RunConsoleCommand( self.name, ... )
    end

    do

        local IsConCommandBlocked = _G.IsConCommandBlocked
        CommandClass.isBlacklisted = IsConCommandBlocked

        --- [SHARED AND MENU]
        ---
        --- Returns whether the console command is blacklisted.
        ---
        ---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
        function Command:isBlacklisted()
            return IsConCommandBlocked( self.name )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the console command.
    ---
    ---@param identifier any The identifier of the callback.
    ---@param fn function The callback function.
    ---@param once boolean?: Whether the callback should be called only once.
    function Command:addCallback( identifier, fn, once )
        local data = { fn, identifier, once }

        local package = debug_getfpackage( 2 )
        if package then
            data[ 2 ], data[ 4 ] = package.prefix .. data[ 2 ], package
            table_insert( package.console_commands, data )
        end

        table_insert( self.callbacks, data )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes a callback from the console command.
    ---
    ---@param identifier string The identifier of the callback.
    function Command:removeCallback( identifier )
        local callbacks = self.callbacks
        for i = #callbacks, 1, -1 do
            local value = callbacks[ i ][ 2 ]
            if value and value == identifier then
                table_remove( callbacks, i )
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Waits for the console command to be executed.
    ---
    ---@async
    function Command:wait()
        local future = Future()

        self:addCallback( future, function( ... )
            return future:setResult( { ... } )
        end, true )

        return future:await()
    end

    gpm.engine.consoleCommandCatch( function( ply, cmd, args, argument_string )
        local command = commands[ cmd ]
        if command == nil then return end

        local callbacks = command.callbacks
        if callbacks == nil then return end

        for index = #callbacks, 1, -1 do
            local data = callbacks[ index ]

            data[ 1 ]( command, ply, args, argument_string )

            if data[ 3 ] then
                table_remove( callbacks, index )
            end
        end
    end, 1 )

end

-- Console Variable
do

    local ConVarExists, GetConVar, CreateConVar = _G.ConVarExists, _G.GetConVar, _G.CreateConVar
    local tostring, tonumber, toboolean = std.tostring, std.tonumber, std.toboolean
    local isstring, isnumber = std.isstring, std.isnumber
    local type = std.type

    ---@alias gpm.std.console.Variable.Type
    ---| string # The type of value of the console variable.
    ---| "boolean"
    ---| "number"
    ---| "string"

    local CONVAR = debug.findmetatable( "ConVar" )
    ---@cast CONVAR ConVar

    local getDefault = CONVAR.GetDefault
    local getString = CONVAR.GetString
    local getFloat = CONVAR.GetFloat
    local getBool = CONVAR.GetBool

    --- [SHARED AND MENU]
    ---
    --- The console variable object.
    ---
    ---@alias ConsoleVariable gpm.std.console.Variable
    ---@class gpm.std.console.Variable: gpm.std.Object
    ---@field __class gpm.std.console.Variable
    ---@field protected object ConVar: The `ConVar` object.
    ---@field protected type gpm.std.console.Variable.Type: The type of the console variable.
    ---@field name string The name of the console variable.
    local Variable = std.class.base( "ConsoleVariable" )

    local variables = {}

    ---@param data gpm.std.console.Variable.Data The data of the console variable.
    ---@protected
    function Variable:__init( data )
        local cvar_type = data.type
        if not isstring( cvar_type ) then
            cvar_type = "string"
        end

        ---@cast cvar_type string
        self.type = cvar_type

        local name = data.name
        if not isstring( name ) then
            error( "Console variable name must be a string.", 3 )
        end

        ---@cast name string
        self.name = name

        local object = GetConVar( name )
        if object == nil then
            local default = data.default
            if default == nil then
                default = ""
            elseif type( default ) ~= cvar_type then
                error( "default value must match console variable data type (" .. cvar_type .. ").", 3 )
            elseif cvar_type == "boolean" then
                default = toboolean( default ) and "1" or "0"
            elseif cvar_type == "string" then
                default = default or ""
            elseif cvar_type == "number" then
                default = tostring( default ) or ""
            end

            ---@cast default string

            local flags = data.flags
            if not isnumber( flags ) then flags = nil end

            ---@cast flags integer

            local description = data.description
            if not isstring( description ) then
                description = tostring( description ) or ""
            end

            ---@cast description string

            local min = data.min
            if not isnumber( min ) then
                min = nil
            end

            ---@cast min number

            local max = data.max
            if not isnumber( max ) then
                max = nil
            end

            ---@cast max number

            self.object = CreateConVar( name, default, flags, description, min, max )
        else
            self.object = object
        end

        variables[ name ] = self
        self.callbacks = {}
    end

    ---@param name string
    ---@return gpm.std.console.Variable?
    function Variable:__new( name )
        return variables[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- The console variable class.
    ---
    ---@class gpm.std.console.VariableClass: gpm.std.console.Variable
    ---@field __base gpm.std.console.Variable
    ---@overload fun( data: gpm.std.console.Variable.Data ): gpm.std.console.Variable
    local VariableClass = std.class.create( Variable )
    console.Variable = VariableClass

    VariableClass.Flags = flags
    VariableClass.exists = ConVarExists

    do

        local type2fn = {
            boolean = getBool,
            number = getFloat,
            string = getString
        }

        --- [SHARED AND MENU]
        ---
        --- Gets the value of the `ConsoleVariable` object.
        ---
        ---@return boolean | string | number value The value of the `ConsoleVariable` object.
        function Variable:get()
            return type2fn[ self.type ]( self.object )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Gets a `ConsoleVariable` object by its name.
    ---
    ---@param name string The name of the console variable.
    ---@param cvar_type gpm.std.console.Variable.Type?: The type of the console variable.
    ---@return gpm.std.console.Variable variable The `ConsoleVariable` object.
    function VariableClass.get( name, cvar_type )
        local value = variables[ name ]
        if value == nil then
            local object = GetConVar( name )
            if object == nil then
                std.error( "console variable '" .. name .. "' does not exist.", 2 )
            end

            ---@cast object ConVar

            value = {
                name = name,
                type = cvar_type or "string",
                object = object,
                callbacks = {}
            }

            setmetatable( value, Variable )
            variables[ name ] = value
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the `ConsoleVariable` object.
    ---
    ---@param value any The value to set.
    function Variable:set( value )
        local cvar_type = self.type
        if cvar_type == "boolean" then
            RunConsoleCommand( self.name, toboolean( value ) and "1" or "0" )
        elseif cvar_type == "string" then
            RunConsoleCommand( self.name, tostring( value ) )
        elseif cvar_type == "number" then
            RunConsoleCommand( self.name, string_format( "%f", tonumber( value, 10 ) ) )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the `ConsoleVariable` object.
    ---
    ---@param name string The name of the console variable.
    ---@param value boolean | string | number: The value to set.
    function VariableClass.set( name, value )
        local value_type = type( value )
        if value_type == "boolean" then
            RunConsoleCommand( name, value and "1" or "0" )
        elseif value_type == "string" then
            RunConsoleCommand( name, value )
        elseif value_type == "number" then
            RunConsoleCommand( name, string_format( "%f", tonumber( value, 10 ) ) )
        else
            error( "invalid value type, must be boolean, string or number.", 2 )
        end
    end

    ---@return string
    ---@protected
    function Variable:__tostring()
        return string_format( "Console Variable: %s [%s]", self.name, getString( self.object ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the value of the `ConsoleVariable` object as a string.
    ---
    ---@param name string The name of the console variable.
    ---@return string value The value of the `ConsoleVariable` object.
    function VariableClass.getString( name )
        local object = GetConVar( name )
        if object == nil then
            return ""
        else
            return getString( object )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the value of the `ConsoleVariable` object as a number.
    ---
    ---@param name string The name of the console variable.
    ---@return number value The value of the `ConsoleVariable` object.
    function VariableClass.getNumber( name )
        local object = GetConVar( name )
        if object == nil then
            return 0.0
        else
            return getFloat( object )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the value of the `ConsoleVariable` object as a boolean.
    ---
    ---@param name string The name of the console variable.
    ---@return boolean value The value of the `ConsoleVariable` object.
    function VariableClass.getBoolean( name )
        local object = GetConVar( name )
        if object == nil then
            return false
        else
            return getBool( object )
        end
    end

    VariableClass.getBool = VariableClass.getBoolean

    --- [SHARED AND MENU]
    ---
    --- Reverts the value of the `ConsoleVariable` object to its default value.
    ---
    function Variable:revert()
        RunConsoleCommand( self.name, getDefault( self.object ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reverts the value of the `ConsoleVariable` object to its default value.
    ---
    ---@param name string The name of the console variable.
    function VariableClass.revert( name )
        local object = GetConVar( name )
        if object == nil then
            error( "Variable '" .. name .. "' does not available.", 2 )
        else
            RunConsoleCommand( name, getDefault( object ) )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the name of the `ConsoleVariable` object.
    ---
    ---@return string name The name of the `ConsoleVariable` object.
    function Variable:getName()
        return self.name
    end

    do

        local getHelpText = CONVAR.GetHelpText

        --- [SHARED AND MENU]
        ---
        --- Gets the help text of the `ConsoleVariable` object.
        ---
        ---@return string help The help text of the `ConsoleVariable` object.
        function Variable:getHelpText()
            return getHelpText( self.object )
        end

        --- [SHARED AND MENU]
        ---
        --- Gets the help text of the `ConsoleVariable` object.
        ---
        ---@param name string The name of the console variable.
        ---@return string help The help text of the `ConsoleVariable` object.
        function VariableClass.getHelpText( name )
            local object = GetConVar( name )
            if object == nil then
                return ""
            else
                return getHelpText( object )
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Gets the default value of the `ConsoleVariable` object.
    ---
    ---@return string default The default value of the `ConsoleVariable` object.
    function Variable:getDefault()
        return getDefault( self.object )
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the default value of the `ConsoleVariable` object.
    ---
    ---@param name string The name of the console variable.
    ---@return string default The default value of the `ConsoleVariable` object.
    function VariableClass.getDefault( name )
        local object = GetConVar( name )
        if object == nil then
            return ""
        else
            return getDefault( object )
        end
    end

    do

        local getFlags = CONVAR.GetFlags

        --- [SHARED AND MENU]
        ---
        --- Gets the flags of the `ConsoleVariable` object.
        ---
        ---@return integer flags The flags of the `ConsoleVariable` object.
        function Variable:getFlags()
            return getFlags( self.object )
        end

        --- [SHARED AND MENU]
        ---
        --- Gets the flags of the `ConsoleVariable` object.
        ---
        ---@param name string The name of the console variable.
        ---@return integer flags The flags of the `ConsoleVariable` object.
        function VariableClass.getFlags( name )
            local object = GetConVar( name )
            if object == nil then
                return 0
            else
                return getFlags( object )
            end
        end

    end

    do

        local isFlagSet = CONVAR.IsFlagSet

        --- [SHARED AND MENU]
        ---
        --- Checks if the flag is set on the `ConsoleVariable` object.
        ---
        ---@param flag integer The flag to check.
        ---@return boolean is_set `true` if the flag is set on the `ConsoleVariable` object, `false` otherwise.
        function Variable:isFlagSet( flag )
            return isFlagSet( self.object, flag )
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the flag is set on the `ConsoleVariable` object.
        ---
        ---@param name string The name of the console variable.
        ---@param flag integer The flag to check.
        ---@return boolean is_set `true` if the flag is set on the `ConsoleVariable` object, `false` otherwise.
        function VariableClass.isFlagSet( name, flag )
            local object = GetConVar( name )
            if object == nil then
                return false
            else
                return isFlagSet( object, flag )
            end
        end

    end

    do

        local getMin, getMax = CONVAR.GetMin, CONVAR.GetMax

        --- [SHARED AND MENU]
        ---
        --- Gets the minimum value of the `ConsoleVariable` object.
        ---
        ---@return number
        function Variable:getMin()
            return getMin( self.object )
        end

        --- [SHARED AND MENU]
        ---
        --- Gets the minimum value of the `ConsoleVariable` object.
        ---
        ---@param name string The name of the console variable.
        ---@return number
        function VariableClass.getMin( name )
            local object = GetConVar( name )
            if object == nil then
                return 0
            else
                return getMin( object )
            end
        end

        --- [SHARED AND MENU]
        ---
        --- Gets the maximum value of the `ConsoleVariable` object.
        ---
        ---@return number
        function Variable:getMax()
            return getMax( self.object )
        end

        --- [SHARED AND MENU]
        ---
        --- Gets the maximum value of the `ConsoleVariable` object.
        ---
        ---@param name string The name of the console variable.
        ---@return number
        function VariableClass.getMax( name )
            local object = GetConVar( name )
            if object == nil then
                return 0
            else
                return getMax( object )
            end
        end

        --- [SHARED AND MENU]
        ---
        --- Gets the minimum and maximum values of the `ConsoleVariable` object.
        ---
        ---@return number, number
        function Variable:getBounds()
            local object = self.object
            return getMin( object ), getMax( object )
        end

        --- [SHARED AND MENU]
        ---
        --- Gets the minimum and maximum values of the `ConsoleVariable` object.
        ---
        ---@param name string The name of the console variable.
        ---@return number, number
        function VariableClass.getBounds( name )
            local object = GetConVar( name )
            if object == nil then
                return 0, 0
            else
                return getMin( object ), getMax( object )
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `ConsoleVariable` object.
    ---
    ---@param identifier string The identifier of the callback.
    ---@param fn fun( object: gpm.std.console.Variable, old: boolean | string | number, new: boolean | string | number ) The callback function.
    function Variable:addChangeCallback( identifier, fn, once )
        self:removeChangeCallback( identifier )
        local data = { fn, identifier, once }

        local package = debug_getfpackage( 2 )
        if package then
            data[ 2 ], data[ 4 ] = package.prefix .. data[ 2 ], package
            table_insert( package.console_variables, data )
        end

        table_insert( self.callbacks, data )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes a callback from the `ConsoleVariable` object.
    ---
    ---@param identifier string The identifier of the callback.
    function Variable:removeChangeCallback( identifier )
        if identifier == nil then return end

        local callbacks = variables[ self.name ]
        for i = #callbacks, 1, -1 do
            local data = callbacks[ i ]
            if data and data[ 2 ] == identifier then
                table_remove( callbacks, i )

                local package = data[ 4 ]
                if package then
                    local console_variables = package.console_variables
                    for j = #console_variables, 1, -1 do
                        if console_variables[ j ] == data then
                            table_remove( console_variables, j )
                        end
                    end
                end
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Waits for the `ConsoleVariable` object to change.
    ---
    ---@return boolean | string | number
    ---@async
    function Variable:waitForChange()
        local f = Future()

        ---@diagnostic disable-next-line: param-type-mismatch
        self:addChangeCallback( nil, function( _, __, value )
            f:setResult( value )
        end, true )

        return f:await()
    end

    gpm.engine.consoleVariableCatch( function( name, old, new )
        local variable = variables[ name ]
        if variable == nil then return end
        local cvar_type = variable.type

        local old_value, new_value
        if cvar_type == "boolean" then
            old_value, new_value = old == "1", new == "1"
        elseif cvar_type == "number" then
            old_value, new_value = tonumber( old, 10 ), tonumber( new, 10 )
        elseif cvar_type == "string" then
            old_value, new_value = old, new
        end

        local callbacks = variable.callbacks

        for i = #callbacks, 1, -1 do
            local data = callbacks[ i ]

            data[ 1 ]( variable, new_value, old_value )

            if data[ 4 ] then
                table_remove( callbacks, i )
            end

            local package = data[ 4 ]
            if package then
                local console_variables = package.console_variables
                for j = #console_variables, 1, -1 do
                    if console_variables[ j ] == data then
                        table_remove( console_variables, j )
                    end
                end
            end
        end
    end )

end
