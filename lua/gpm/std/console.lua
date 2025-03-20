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

--- [SHARED AND MENU]
--- The console library.
---@class gpm.std.console
---@field visible boolean `true` if the console is visible, `false` otherwise.
local console = {}

if std.MENU then

    --- [MENU]
    --- Shows the console.
    console.show = _G.gui and _G.gui.ShowConsole or function()
        RunConsoleCommand( "showconsole" )
    end

    --- [MENU]
    --- Hides the console.
    function console.hide()
        RunConsoleCommand( "hideconsole" )
    end

    --- [MENU]
    --- Toggles the console.
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
    --- Writes a colored message to the console on a new line.
    ---@param ... string | Color: The message to write to the console.
    function console.writeLine( ... )
        return MsgC( ... ), MsgC( "\n" )
    end

end

do

    local AddConsoleCommand = _G.AddConsoleCommand

    --- [SHARED AND MENU]
    --- The console command object.
    ---@alias ConsoleCommand gpm.std.console.Command
    ---@class gpm.std.console.Command : gpm.std.Object
    ---@field __class gpm.std.console.Command
    ---@field name string The name of the console command.
    ---@field description string The help text of the console command.
    ---@field flags integer The flags of the console command.
    local Command = class.base( "Command" )

    local commands = {}

    ---@param name string The name of the console command.
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

        commands[ name ] = self
        self.callbacks = {}
    end

    ---@param name string
    ---@return gpm.std.console.Command?
    function Command:__new( name )
        return commands[ name ]
    end

    --- [SHARED AND MENU]
    --- The console command class.
    ---@class gpm.std.console.CommandClass: gpm.std.console.Command
    ---@field __base gpm.std.console.Command
    ---@overload fun( name: string, description: string?, ...: gpm.std.FCVAR? ): ConsoleCommand
    local CommandClass = class.create( Command )
    console.Command = CommandClass

    --- [SHARED AND MENU]
    --- Returns the console command with the given name.
    ---@return gpm.std.console.Command?: The console command with the given name, or `nil` if it does not exist.
    function CommandClass.get( name )
        return commands[ name ]
    end

    CommandClass.run = RunConsoleCommand

    --- [SHARED AND MENU]
    --- Runs the console command.
    ---@param ... string: The arguments to pass to the console command.
    function Command:run( ... )
        RunConsoleCommand( self.name, ... )
    end

    do

        local IsConCommandBlocked = _G.IsConCommandBlocked
        CommandClass.isBlacklisted = IsConCommandBlocked

        --- [SHARED AND MENU]
        --- Returns whether the console command is blacklisted.
        ---@return boolean: `true` if the console command is blacklisted, `false` otherwise.
        function Command:isBlacklisted()
            return IsConCommandBlocked( self.name )
        end

    end

    --- [SHARED AND MENU]
    --- Adds a callback to the console command.
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
    --- Removes a callback from the console command.
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
    --- Waits for the console command to be executed.
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
    --- The console variable object.
    ---@alias ConsoleVariable gpm.std.console.Variable
    ---@class gpm.std.console.Variable: gpm.std.Object
    ---@field __class gpm.std.console.Variable
    ---@field protected object ConVar: The `ConVar` object.
    ---@field protected type gpm.std.console.Variable.Type: The type of the console variable.
    ---@field name string The name of the console variable.
    local Variable = class.base( "Variable" )

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
    --- The console variable class.
    ---@class gpm.std.console.VariableClass: gpm.std.console.Variable
    ---@field __base gpm.std.console.Variable
    ---@overload fun( data: gpm.std.console.Variable.Data ): ConsoleVariable
    local VariableClass = class.create( Variable )
    console.Variable = VariableClass

    VariableClass.exists = ConVarExists

    do

        local type2fn = {
            boolean = getBool,
            number = getFloat,
            string = getString
        }

        --- [SHARED AND MENU]
        --- Gets the value of the `ConsoleVariable` object.
        ---@return boolean | string | number: The value of the `ConsoleVariable` object.
        function Variable:get()
            return type2fn[ self.type ]( self.object )
        end

    end

    --- [SHARED AND MENU]
    --- Gets a `ConsoleVariable` object by its name.
    ---@param name string The name of the console variable.
    ---@param cvar_type gpm.std.console.Variable.Type?: The type of the console variable.
    ---@return gpm.std.console.Variable?
    function VariableClass.get( name, cvar_type )
        local value = variables[ name ]
        if value == nil then
            local object = GetConVar( name )
            if object == nil then return end

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
    --- Sets the value of the `ConsoleVariable` object.
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
    --- Sets the value of the `ConsoleVariable` object.
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
    --- Gets the value of the `ConsoleVariable` object as a string.
    ---@param name string The name of the console variable.
    ---@return string: The value of the `ConsoleVariable` object.
    function VariableClass.getString( name )
        local object = GetConVar( name )
        if object == nil then
            return ""
        else
            return getString( object )
        end
    end

    --- [SHARED AND MENU]
    --- Gets the value of the `ConsoleVariable` object as a number.
    ---@param name string The name of the console variable.
    ---@return number: The value of the `ConsoleVariable` object.
    function VariableClass.getNumber( name )
        local object = GetConVar( name )
        if object == nil then
            return 0.0
        else
            return getFloat( object )
        end
    end

    --- [SHARED AND MENU]
    --- Gets the value of the `ConsoleVariable` object as a boolean.
    ---@param name string The name of the console variable.
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

    --- [SHARED AND MENU]
    --- Reverts the value of the `ConsoleVariable` object to its default value.
    function Variable:revert()
        RunConsoleCommand( self.name, getDefault( self.object ) )
    end

    --- [SHARED AND MENU]
    --- Reverts the value of the `ConsoleVariable` object to its default value.
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
    --- Gets the name of the `ConsoleVariable` object.
    ---@return string: The name of the `ConsoleVariable` object.
    function Variable:getName()
        return self.name
    end

    do

        local getHelpText = CONVAR.GetHelpText

        --- [SHARED AND MENU]
        --- Gets the help text of the `ConsoleVariable` object.
        ---@return string: The help text of the `ConsoleVariable` object.
        function Variable:getHelpText()
            return getHelpText( self.object )
        end

        --- [SHARED AND MENU]
        --- Gets the help text of the `ConsoleVariable` object.
        ---@param name string The name of the console variable.
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

    --- [SHARED AND MENU]
    --- Gets the default value of the `ConsoleVariable` object.
    ---@return string: The default value of the `ConsoleVariable` object.
    function Variable:getDefault()
        return getDefault( self.object )
    end

    --- [SHARED AND MENU]
    --- Gets the default value of the `ConsoleVariable` object.
    ---@param name string The name of the console variable.
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

        --- [SHARED AND MENU]
        --- Gets the `Enums/FCVAR` flags of the `ConsoleVariable` object.
        ---@return number: The `Enums/FCVAR` flags of the `ConsoleVariable` object.
        function Variable:getFlags()
            return getFlags( self.object )
        end

        --- [SHARED AND MENU]
        --- Gets the `Enums/FCVAR` flags of the `ConsoleVariable` object.
        ---@param name string The name of the console variable.
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

        --- [SHARED AND MENU]
        --- Checks if the `Enums/FCVAR` flag is set on the `ConsoleVariable` object.
        ---@param flag number The `Enums/FCVAR` flag to check.
        ---@return boolean: `true` if the `Enums/FCVAR` flag is set on the `ConsoleVariable` object, `false` otherwise.
        function Variable:isFlagSet( flag )
            return isFlagSet( self.object, flag )
        end

        --- [SHARED AND MENU]
        --- Checks if the `Enums/FCVAR` flag is set on the `ConsoleVariable` object.
        ---@param name string The name of the console variable.
        ---@param flag number The `Enums/FCVAR` flag to check.
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

        --- [SHARED AND MENU]
        --- Gets the minimum value of the `ConsoleVariable` object.
        ---@return number
        function Variable:getMin()
            return getMin( self.object )
        end

        --- [SHARED AND MENU]
        --- Gets the minimum value of the `ConsoleVariable` object.
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
        --- Gets the maximum value of the `ConsoleVariable` object.
        ---@return number
        function Variable:getMax()
            return getMax( self.object )
        end

        --- [SHARED AND MENU]
        --- Gets the maximum value of the `ConsoleVariable` object.
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
        --- Gets the minimum and maximum values of the `ConsoleVariable` object.
        ---@return number, number
        function Variable:getBounds()
            local object = self.object
            return getMin( object ), getMax( object )
        end

        --- [SHARED AND MENU]
        --- Gets the minimum and maximum values of the `ConsoleVariable` object.
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
    --- Adds a callback to the `ConsoleVariable` object.
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
    --- Removes a callback from the `ConsoleVariable` object.
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

return console
