local _G = _G
local gpm = _G.gpm
local RunConsoleCommand = _G.RunConsoleCommand

local std = gpm.std
local class = std.class
local debug = std.debug
local Future = std.Future
local string_format = std.string.format
local debug_getfpackage = debug.getfpackage
local bit_bor, setmetatable = std.bit.bor, std.setmetatable
local table_insert, table_remove = std.table.insert, std.table.remove

---@class gpm.std.console
local console = {}

if std.MENU then

    --- Shows the console.
    console.show = _G.gui and _G.gui.ShowConsole or function()
        RunConsoleCommand( "showconsole" )
    end

    --- Hides the console.
    function console.hide()
        RunConsoleCommand( "hideconsole" )
    end

    --- Toggles the console.
    function console.toggle()
        RunConsoleCommand( "toggleconsole" )
    end

end

do

    local MsgC = _G.MsgC
    console.write = MsgC

    --- Writes a colored message to the console on a new line.
    ---@param ... string | Color: The message to write to the console.
    function console.writeLine( ... )
        return MsgC( ... ), MsgC( "\n" )
    end

end

do

    local AddConsoleCommand = _G.AddConsoleCommand

    ---@alias ConsoleCommand gpm.std.console.Command
    ---@class gpm.std.console.Command : gpm.std.Object
    ---@field __class gpm.std.console.Command
    ---@field name string: The name of the console command.
    ---@field description string: The help text of the console command.
    ---@field flags integer: The flags of the console command.
    local Command = class.base( "Command" )

    local cache = {}

    ---@param name string: The name of the console command.
    ---@param description string?: The help text of the console command.
    ---@param ... gpm.std.FCVAR?: The flags of the console command.
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

        cache[ name ] = self
    end

    ---@param name string
    ---@return gpm.std.console.Command?
    function Command:__new( name )
        return cache[ name ]
    end

    ---@class gpm.std.console.CommandClass: gpm.std.console.Command
    ---@field __base gpm.std.console.Command
    ---@overload fun( name: string, description: string?, ...: gpm.std.FCVAR? ): ConsoleCommand
    local CommandClass = class.create( Command )
    console.Command = CommandClass

    CommandClass.run = RunConsoleCommand

    --- Runs the console command.
    ---@param ... string: The arguments to pass to the console command.
    function Command:run( ... )
        return RunConsoleCommand( self.name, ... )
    end

    do

        local IsConCommandBlocked = _G.IsConCommandBlocked
        CommandClass.isBlacklisted = IsConCommandBlocked

        --- Returns whether the console command is blacklisted.
        ---@return boolean: `true` if the console command is blacklisted, `false` otherwise.
        function Command:isBlacklisted()
            return IsConCommandBlocked( self.name )
        end

    end

    do

        --- 1 - object, 2 - fn, 3 - identifier, 4 - once
        local callbacks = {}

        setmetatable( callbacks, {
            __index = function( _, name )
                callbacks[ name ] = {}
            end
        } )

        -- TODO:
        function Command:addCallback( identifier, fn, once )
            local data = { self, fn, identifier, once }

            local package = debug_getfpackage( 2 )
            if package then
                table_insert( package.ccommand_callbacks, data )
            end

            table_insert( callbacks[ self.name ], data )
        end

        -- TODO:
        function Command:removeCallback( identifier )
            local lst = callbacks[ self.name ]
            if lst == nil then return end
            for i = #lst, 1, -1 do
                local value = lst[ i ][ 3 ]
                if value and value == identifier then
                    table_remove( lst, i )
                end
            end
        end

        -- TODO:
        function Command:wait()
            local future = Future()

            self:addCallback( future, function( ... )
                return future:setResult( { ... } )
            end, true )

            return future
        end

        local function engine_hook( ply, cmd, args, argumentString )
            local lst = callbacks[ cmd ]
            if lst == nil then return end

            for i = #lst, 1, -1 do
                local data = lst[ i ]
                data[ 2 ]( data[ 1 ], ply, args, argumentString )
                if data[ 4 ] then table_remove( lst, i ) end
            end
        end

        local concommand = _G.concommand
        if concommand == nil then
            ---@diagnostic disable-next-line: inject-field
            concommand = {}; _G.concommand = concommand
        end

        local concommand_Run = concommand.Run
        if concommand_Run == nil then
            concommand.Run = engine_hook
        else
            concommand.Run = gpm.detour.attach( concommand_Run, function( fn, ply, cmd, args, argumentString )
                engine_hook( ply, cmd, args, argumentString )
                return fn( ply, cmd, args, argumentString )
            end )
        end

    end

end

-- Console Variable
do

    local ConVarExists, GetConVar, CreateConVar = _G.ConVarExists, _G.GetConVar, _G.CreateConVar
    local tostring, tonumber, toboolean = std.tostring, std.tonumber, std.toboolean
    local is_string, is_number = std.is.string, std.is.number
    local type = std.type

    ---@alias ConsoleVariableType string
    ---| "boolean"
    ---| "number"
    ---| "string"

    ---@class ConVar
    local CONVAR = debug.findmetatable( "ConVar" )
    local getDefault = CONVAR.GetDefault
    local getString = CONVAR.GetString
    local getFloat = CONVAR.GetFloat
    local getBool = CONVAR.GetBool

    ---@alias ConsoleVariable gpm.std.console.Variable
    ---@class gpm.std.console.Variable: gpm.std.Object
    ---@field __class gpm.std.console.Variable
    ---@field protected object ConVar: The `ConVar` object.
    ---@field protected type ConsoleVariableType: The type of the console variable.
    ---@field name string: The name of the console variable.
    local Variable = class.base( "Variable" )

    local cache = {}

    ---@param data ConsoleVariableData: The data of the console variable.
    ---@protected
    function Variable:__init( data )
        local cvar_type = data.type
        if not is_string( cvar_type ) then
            cvar_type = "string"
        end

        ---@cast cvar_type string
        self.type = cvar_type

        local name = data.name
        if not is_string( name ) then
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
            if not is_number( flags ) then flags = nil end

            ---@cast flags integer

            local description = data.description
            if not is_string( description ) then
                description = tostring( description ) or ""
            end

            ---@cast description string

            local min = data.min
            if not is_number( min ) then
                min = nil
            end

            ---@cast min number

            local max = data.max
            if not is_number( max ) then
                max = nil
            end

            ---@cast max number

            self.object = CreateConVar( name, default, flags, description, min, max )
        else
            self.object = object
        end

        cache[ name ] = self
    end

    ---@param name string
    ---@return gpm.std.console.Variable?
    function Variable:__new( name )
        return cache[ name ]
    end

    ---@class gpm.std.console.VariableClass: gpm.std.console.Variable
    ---@field __base gpm.std.console.Variable
    ---@overload fun( data: ConsoleVariableData ): ConsoleVariable
    local VariableClass = class.create( Variable )
    console.Variable = VariableClass

    VariableClass.exists = ConVarExists

    do

        local type2fn = {
            boolean = getBool,
            number = getFloat,
            string = getString
        }

        --- Gets the value of the `ConsoleVariable` object.
        ---@return boolean | string | number: The value of the `ConsoleVariable` object.
        function Variable:get()
            return type2fn[ self.type ]( self.object )
        end

    end

    --- Gets a `ConsoleVariable` object by its name.
    ---@param name string: The name of the console variable.
    ---@param cvar_type ConsoleVariableType?: The type of the console variable.
    ---@return gpm.std.console.Variable?
    function VariableClass.get( name, cvar_type )
        local object = GetConVar( name )
        if object == nil then return end
        if cvar_type == nil then cvar_type = "string" end

        local value = {
            name = name,
            type = cvar_type,
            object = object
        }

        setmetatable( value, Variable )
        cache[ name ] = value

        return value
    end

    --- Sets the value of the `ConsoleVariable` object.
    ---@param value any: The value to set.
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

    --- Sets the value of the `ConsoleVariable` object.
    ---@param name string: The name of the console variable.
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

    ---@protected
    function Variable:__tostring()
        return string_format( "Console Variable: %s [%s]", self.name, getString( self.object ) )
    end

    --- Gets the value of the `ConsoleVariable` object as a string.
    ---@param name string: The name of the console variable.
    ---@return string: The value of the `ConsoleVariable` object.
    function VariableClass.getString( name )
        local object = GetConVar( name )
        if object == nil then
            return ""
        else
            return getString( object )
        end
    end

    --- Gets the value of the `ConsoleVariable` object as a number.
    ---@param name string: The name of the console variable.
    ---@return number: The value of the `ConsoleVariable` object.
    function VariableClass.getNumber( name )
        local object = GetConVar( name )
        if object == nil then
            return 0.0
        else
            return getFloat( object )
        end
    end

    --- Gets the value of the `ConsoleVariable` object as a boolean.
    ---@param name string: The name of the console variable.
    ---@return boolean: The value of the `ConsoleVariable` object.
    function VariableClass.getBoolean( name )
        local object = GetConVar( name )
        if object == nil then
            return false
        else
            return getBool( object )
        end
    end

    VariableClass.getBool = VariableClass.getBoolean

    --- Reverts the value of the `ConsoleVariable` object to its default value.
    function Variable:revert()
        RunConsoleCommand( self.name, getDefault( self.object ) )
    end

    --- Reverts the value of the `ConsoleVariable` object to its default value.
    ---@param name string: The name of the console variable.
    function VariableClass.revert( name )
        local object = GetConVar( name )
        if object == nil then
            error( "Variable '" .. name .. "' does not available.", 2 )
        else
            RunConsoleCommand( name, getDefault( object ) )
        end
    end

    --- Gets the name of the `ConsoleVariable` object.
    ---@return string: The name of the `ConsoleVariable` object.
    function Variable:getName()
        return self.name
    end

    do

        local getHelpText = CONVAR.GetHelpText

        --- Gets the help text of the `ConsoleVariable` object.
        ---@return string: The help text of the `ConsoleVariable` object.
        function Variable:getHelpText()
            return getHelpText( self.object )
        end

        --- Gets the help text of the `ConsoleVariable` object.
        ---@param name string: The name of the console variable.
        ---@return string: The help text of the `ConsoleVariable` object.
        function VariableClass.getHelpText( name )
            local object = GetConVar( name )
            if object == nil then
                return ""
            else
                return getHelpText( object )
            end
        end

    end

    --- Gets the default value of the `ConsoleVariable` object.
    ---@return string: The default value of the `ConsoleVariable` object.
    function Variable:getDefault()
        return getDefault( self.object )
    end

    --- Gets the default value of the `ConsoleVariable` object.
    ---@param name string: The name of the console variable.
    ---@return string: The default value of the `ConsoleVariable` object.
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

        --- Gets the `Enums/FCVAR` flags of the `ConsoleVariable` object.
        ---@return number: The `Enums/FCVAR` flags of the `ConsoleVariable` object.
        function Variable:getFlags()
            return getFlags( self.object )
        end

        --- Gets the `Enums/FCVAR` flags of the `ConsoleVariable` object.
        ---@param name string: The name of the console variable.
        ---@return number: The `Enums/FCVAR` flags of the `ConsoleVariable` object.
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

        --- Checks if the `Enums/FCVAR` flag is set on the `ConsoleVariable` object.
        ---@param flag number: The `Enums/FCVAR` flag to check.
        ---@return boolean: `true` if the `Enums/FCVAR` flag is set on the `ConsoleVariable` object, `false` otherwise.
        function Variable:isFlagSet( flag )
            return isFlagSet( self.object, flag )
        end

        --- Checks if the `Enums/FCVAR` flag is set on the `ConsoleVariable` object.
        ---@param name string: The name of the console variable.
        ---@param flag number: The `Enums/FCVAR` flag to check.
        ---@return boolean: `true` if the `Enums/FCVAR` flag is set on the `ConsoleVariable` object, `false` otherwise.
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

        --- Gets the minimum value of the `ConsoleVariable` object.
        ---@return number
        function Variable:getMin()
            return getMin( self.object )
        end

        --- Gets the minimum value of the `ConsoleVariable` object.
        ---@param name string: The name of the console variable.
        ---@return number
        function VariableClass.getMin( name )
            local object = GetConVar( name )
            if object == nil then
                return 0
            else
                return getMin( object )
            end
        end

        --- Gets the maximum value of the `ConsoleVariable` object.
        ---@return number
        function Variable:getMax()
            return getMax( self.object )
        end

        --- Gets the maximum value of the `ConsoleVariable` object.
        ---@param name string: The name of the console variable.
        ---@return number
        function VariableClass.getMax( name )
            local object = GetConVar( name )
            if object == nil then
                return 0
            else
                return getMax( object )
            end
        end

        --- Gets the minimum and maximum values of the `ConsoleVariable` object.
        ---@return number, number
        function Variable:getBounds()
            local object = self.object
            return getMin( object ), getMax( object )
        end

        --- Gets the minimum and maximum values of the `ConsoleVariable` object.
        ---@param name string: The name of the console variable.
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

    do

        --- 1 - object, 2 - fn, 3 - identifier, 4 - once
        local callbacks = {}

        setmetatable( callbacks, {
            __index = function( _, name )
                callbacks[ name ] = {}
            end
        } )

        --- Adds a callback to the `ConsoleVariable` object.
        ---@param identifier string The identifier of the callback.
        ---@param fn fun( object: gpm.std.console.Variable, old: boolean | string | number, new: boolean | string | number ) The callback function.
        function Variable:addChangeCallback( identifier, fn, once )
            self:removeChangeCallback( identifier )

            local data = { self, fn, identifier, once }

            local package = debug_getfpackage( 2 )
            if package then
                table_insert( package.cvar_callbacks, data )
            end

            table_insert( callbacks[ self.name ], data )
        end

        --- Removes a callback from the `ConsoleVariable` object.
        ---@param identifier string The identifier of the callback.
        function Variable:removeChangeCallback( identifier )
            if identifier == nil then return end

            local lst = callbacks[ self.name ]
            if lst == nil then return end
            for i = #lst, 1, -1 do
                local value = lst[ i ][ 3 ]
                if value and value == identifier then
                    table_remove( lst, i )
                end
            end
        end

        --- Waits for the `ConsoleVariable` object to change.
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

        _G.cvars.OnConVarChanged = gpm.detour.attach( _G.cvars.OnConVarChanged, function( fn, name, old, new )
            local lst = callbacks[ name ]
            if lst ~= nil then
                for i = #lst, 1, -1 do
                    local data = lst[ i ]

                    local cvar = data[ 1 ]
                    local cvar_type = cvar.type

                    local old_value, new_value
                    if cvar_type == "boolean" then
                        old_value, new_value = old == "1", new == "1"
                    elseif cvar_type == "number" then
                        old_value, new_value = tonumber( old, 10 ), tonumber( new, 10 )
                    elseif cvar_type == "string" then
                        old_value, new_value = old, new
                    end

                    data[ 2 ]( cvar, old_value, new_value )

                    if data[ 4 ] then
                        table_remove( lst, i )
                    end
                end
            end

            return fn( name, old, new )
        end )

    end

end

return console
