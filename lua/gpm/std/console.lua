local _G = _G
local std = _G.gpm.std
local class = std.class
local string_format = std.string.format
local RunConsoleCommand = _G.RunConsoleCommand

---@class gpm.std.console
local console = {}

if std.MENU then
    console.show = _G.gui.ShowConsole
end

function console.hide()
    RunConsoleCommand( "hideconsole" )
end

function console.toggle()
    RunConsoleCommand( "toggleconsole" )
end

do

    local MsgC = _G.MsgC

    --- Writes a colored message to the console.
    ---@vararg string | Color: The message to write to the console.
    function console.write( ... )
        return MsgC( ... )
    end

    --- Writes a colored message to the console on a new line.
    ---@vararg string | Color: The message to write to the console.
    function console.writeLine( ... )
        MsgC( ... )
        MsgC( "\n" )
    end

end

do

    local AddConsoleCommand = _G.AddConsoleCommand

    ---@alias ConsoleCommand gpm.std.console.Command
    ---@class gpm.std.console.Command : gpm.std.Object
    ---@field __class gpm.std.console.Command
    ---@field name string: The name of the console command.
    ---@field help_text string: The help text of the console command.
    ---@field flags integer: The flags of the console command.
    local Command = class.base( "Command" )

    local cache = {}

    function Command:__init( name, help_text, flags )
        AddConsoleCommand( name, help_text, flags )
        cache[ name ] = self
        self.name = name
        self.help_text = help_text
        self.flags = flags
    end

    function Command.__new( name )
        return cache[ name ]
    end

    ---@class gpm.std.console.CommandClass: gpm.std.console.Command
    ---@field __base gpm.std.console.Command
    ---@overload fun( name: string, help_text: string?, flags: integer? ): ConsoleCommand
    local CommandClass = class.create( Command )
    console.Command = CommandClass

    CommandClass.run = RunConsoleCommand

    function Command:run( ... )
        RunConsoleCommand( self.name, ... )
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

    -- TODO:
    local callbacks = {}

    _G.concommand.Run = gpm.detour.attach( _G.concommand.Run, function( fn, ply, cmd, args, argumentString )


        return fn( ply, cmd, args, argumentString )
    end )


    -- TODO: callbacks and async/future functions
    -- somethink like once and etc

end

-- Console Variable
do

    local ConVarExists, GetConVar, CreateConVar = _G.ConVarExists, _G.GetConVar, _G.CreateConVar
    local setmetatable = std.setmetatable

    ---@class ConVar
    local CONVAR = _G.FindMetaTable( "ConVar" )
    local getDefault = CONVAR.GetDefault

    ---@alias ConsoleVariable gpm.std.console.Variable
    ---@class gpm.std.console.Variable: gpm.std.Object
    ---@field __class gpm.std.console.Variable
    ---@field private object ConVar: The `ConVar` object.
    ---@field name string: The name of the console variable.
    local Variable = class.base( "Variable" )

    local cache = {}

    ---@param name string
    ---@param default string?
    ---@param helptext string?
    ---@param min number?
    ---@param max number?
    ---@vararg gpm.std.FCVAR: Flags numbers TODO:
    ---@protected
    function Variable:__init( name, default, flags, helptext, min, max )
        cache[ name ] = self
        self.name = name

        local object = GetConVar( name )
        if object == nil then
            self.object = CreateConVar( name, default or "", flags, helptext, min, max )
        else
            self.object = object
        end
    end

    function Variable.__new( name )
        return cache[ name ]
    end

    ---@class gpm.std.console.VariableClass: gpm.std.console.Variable
    ---@field __base gpm.std.console.Variable
    ---@overload fun( name: string, default: string?, helptext: string?, min: number?, max: number?, ...: gpm.std.FCVAR? ): ConsoleVariable
    local VariableClass = class.create( Variable )
    console.Variable = VariableClass

    VariableClass.exists = ConVarExists

    --- Gets a `ConsoleVariable` object by its name.
    ---@param name string: The name of the console variable.
    ---@return gpm.std.console.Variable?
    function VariableClass.get( name )
        local object = GetConVar( name )
        if object == nil then return end

        local value = {
            name = name,
            object = object
        }

        setmetatable( value, Variable )
        cache[ name ] = value

        return value
    end

    do

        local getString = CONVAR.GetString

        ---@protected
        function Variable:__tostring()
            return string_format( "Console Variable: %s [%s]", self.name, getString( self.object ) )
        end

        --- Gets the value of the `ConsoleVariable` object as a string.
        ---@return string: The value of the `ConsoleVariable` object.
        function Variable:getString()
            return getString( self.object )
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

    end

    --- Sets the value of the `ConsoleVariable` object as a string.
    ---@param value string: The value to set.
    function Variable:setString( value )
        RunConsoleCommand( self.name, value )
    end

    --- Sets the value of the `ConsoleVariable` object as a string.
    ---@param name string: The name of the console variable.
    ---@param value string: The value to set.
    function VariableClass.setString( name, value )
        RunConsoleCommand( name, value )
    end

    do

        local getFloat = CONVAR.GetFloat

        --- Gets the value of the `ConsoleVariable` object as a float.
        ---@return number: The value of the `ConsoleVariable` object.
        function Variable:getFloat()
            return getFloat( self.object )
        end

        --- Gets the value of the `ConsoleVariable` object as a float.
        ---@param name string: The name of the console variable.
        ---@return number: The value of the `ConsoleVariable` object.
        function VariableClass.getFloat( name )
            local object = GetConVar( name )
            if object == nil then
                return 0.0
            else
                return getFloat( object )
            end
        end

    end

    --- Sets the value of the `ConsoleVariable` object as a float.
    ---@param value number: The value to set.
    function Variable:setFloat( value )
        RunConsoleCommand( self.name, string_format( "%f", value ) )
    end

    --- Sets the value of the `ConsoleVariable` object as a float.
    ---@param name string: The name of the console variable.
    ---@param value number: The value to set.
    function VariableClass.setFloat( name, value )
        RunConsoleCommand( name, string_format( "%f", value ) )
    end

    do

        local getBool = CONVAR.GetBool

        --- Gets the value of the `ConsoleVariable` object as a boolean.
        ---@return boolean: The value of the `ConsoleVariable` object.
        function Variable:getBool()
            return getBool( self.object )
        end

        --- Gets the value of the `ConsoleVariable` object as a boolean.
        ---@param name string: The name of the console variable.
        ---@return boolean: The value of the `ConsoleVariable` object.
        function VariableClass.getBool( name )
            local object = GetConVar( name )
            if object == nil then
                return false
            else
                return getBool( object )
            end
        end

    end

    --- Sets the value of the `ConsoleVariable` object as a boolean.
    ---@param value boolean: The value to set.
    function Variable:setBool( value )
        RunConsoleCommand( self.name, value == true and "1" or "0" )
    end

    --- Sets the value of the `ConsoleVariable` object as a boolean.
    ---@param name string: The name of the console variable.
    ---@param value boolean: The value to set.
    function VariableClass.setBool( name, value )
        RunConsoleCommand( name, value == true and "1" or "0" )
    end

    do

        local getInt = CONVAR.GetInt

        --- Gets the value of the `ConsoleVariable` object as an integer.
        ---@return integer: The value of the `ConsoleVariable` object.
        function Variable:getInteger()
            return getInt( self.object )
        end

        --- Gets the value of the `ConsoleVariable` object as an integer.
        ---@param name string: The name of the console variable.
        ---@return integer: The value of the `ConsoleVariable` object.
        function VariableClass.getInteger( name )
            local object = GetConVar( name )
            if object == nil then
                return 0
            else
                return getInt( object )
            end
        end

    end

    --- Sets the value of the `ConsoleVariable` object as an integer.
    ---@param value integer: The value to set.
    function Variable:setInteger( value )
        RunConsoleCommand( self.name, string_format( "%d", value ) )
    end

    --- Sets the value of the `ConsoleVariable` object as an integer.
    ---@param name string: The name of the console variable.
    ---@param value integer: The value to set.
    function VariableClass.setInteger( name, value )
        RunConsoleCommand( name, string_format( "%d", value ) )
    end

    --- Reverts the value of the `ConsoleVariable` object to its default value.
    function Variable:revert()
        RunConsoleCommand( self.name, getDefault( self.object ) )
    end

    --- Reverts the value of the `ConsoleVariable` object to its default value.
    ---@param name string: The name of the console variable.
    function VariableClass.revert( name )
        local object = GetConVar( name )
        if object == nil then return end
        RunConsoleCommand( name, getDefault( object ) )
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

        local table_insert, table_remove = std.table.insert, std.table.remove
        local debug_getfpackage = std.debug.getfpackage
        local Future = std.Future

        --- 1 - object, 2 - fn, 3 - name, 4 - once
        local callbacks = {}

        setmetatable( callbacks, {
            __index = function( _, identifier )
                callbacks[ identifier ] = {}
            end
        } )

        function Variable:addChangeCallback( identifier, fn, once )
            local data = { self, fn, identifier, once }

            local package = debug_getfpackage( 2 )
            if package then
                table_insert( package.cvar_callbacks, data )
            end

            table_insert( callbacks[ self.name ], data )
        end

        function Variable:removeChangeCallback( identifier )
            local lst = callbacks[ identifier ]
            if lst == nil then return end
            for i = #lst, 1, -1 do
                local value = lst[ i ][ 3 ]
                if value and value == identifier then
                    table_remove( lst, i )
                end
            end
        end

        ---@async
        function Variable:waitForChange()
            local f = Future()

            self:addChangeCallback( nil, function( _, value )
                f:setResult( value )
            end, true )

            return f:await()
        end

        _G.cvars.OnConVarChanged = gpm.detour.attach( _G.cvars.OnConVarChanged, function( fn, name, old, new )
            local lst = callbacks[ name ]
            if lst ~= nil then
                for i = #lst, 1, -1 do
                    local data = lst[ i ]
                    data[ 2 ]( data[ 1 ], old, new )

                    if data[ 4 ] then
                        table_remove( lst, i )
                    end
                end
            end

            return fn( name, old, new )
        end )

        -- TODO: Rewrite this crap
        -- variable.getCallbacks = cvars_GetConVarCallbacks

        -- variable.addCallback = function( name, callback, identifier )
        --     local package = debug_getfpackage( 2 )
        --     if package == nil then
        --         -- cvars_AddChangeCallback( name, callback, identifier )
        --     else
        --         local prefix = package.prefix
        --         identifier = prefix .. ( identifier or "" )
        --     end
        -- end

        -- variable.removeCallback = function( name, identifier )
        --     local package = debug_getfpackage( 2 )
        --     if package == nil then
        --         -- cvars_RemoveChangeCallback( name, identifier )
        --     else
        --         local prefix = package.prefix
        --         identifier = prefix .. ( identifier or "" )
        --     end
        -- end

    end

end

return console
