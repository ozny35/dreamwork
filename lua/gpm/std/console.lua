local _G = _G
local gpm = _G.gpm
local engine = gpm.engine

---@class gpm.std
local std = gpm.std

local debug = std.debug
local futures_Future = std.futures.Future

local isstring = std.isstring
local string_format = std.string.format
local debug_getfpackage = debug.getfpackage
local engine_consoleCommandRun = engine.consoleCommandRun
local bit_bor, setmetatable = std.bit.bor, std.setmetatable
local table_insert, table_remove = std.table.insert, std.table.remove

local convar_flags = {
    { "unregistered", 1 },
    { "development_only", 2 },
    { "game_dll", 4 },
    { "client_dll", 8 },
    { "hidden", 16 },
    { "protected", 32 },
    { "sponly", 64 },
    { "archive", 128 },
    { "notify", 256 },
    { "userinfo", 512 },
    { "cheat", 16384 },
    { "printable_only", 1024 },
    { "unlogged", 2048 },
    { "never_as_string", 4096 },
    { "replicated", 8192 },
    { "demo", 65536 },
    { "dont_record", 131072 },
    { "reload_materials", 1048576 },
    { "reload_textures", 2097152 },
    { "not_connected", 4194304 },
    { "material_system_thread", 8388608 },
    { "archive_xbox", 16777216 },
    { "accessible_from_threads", 33554432 },
    { "server_can_execute", 268435456 },
    { "server_cannot_query", 536870912 },
    { "clientcmd_can_execute", 1073741824 },
    { "material_thread_mask", 11534336 },
    { "lua_client", 262144 },
    { "lua_server", 524288 }
}

local convar_flag_count = #convar_flags

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
    console.show = _G.gui.ShowConsole or function()
        engine_consoleCommandRun( "showconsole" )
    end

    --- [MENU]
    ---
    --- Hides the console.
    ---
    function console.hide()
        engine_consoleCommandRun( "hideconsole" )
    end

    --- [MENU]
    ---
    --- Toggles the console.
    ---
    function console.toggle()
        engine_consoleCommandRun( "toggleconsole" )
    end

end

if std.CLIENT_MENU then

    local gui_IsConsoleVisible = _G.gui.IsConsoleVisible

    console.visible = gui_IsConsoleVisible()

    _G.timer.Create( gpm.PREFIX .. " - gui.IsConsoleVisible", 0.25, 0, function()
        console.visible = gui_IsConsoleVisible()
    end )

end

do

    ---@diagnostic disable-next-line: undefined-field
    local console_write = _G.MsgC

    if console_write == nil then

        local table_concat = std.table.concat
        local print = std.print

        function console_write( ... )
            local buffer, buffer_size = {}, 0
            local args = { ... }

            for i = 1, select( "#", ... ), 1 do
                local value = args[ i ]
                if isstring( value ) then
                    buffer_size = buffer_size + 1
                    buffer[ buffer_size ] = value
                end
            end

            if buffer_size == 1 then
                print( buffer[ 1 ] )
            elseif buffer_size ~= 0 then
                print( table_concat( buffer, "", 1, buffer_size ) )
            end
        end
    end

    console.write = console_write

    --- [SHARED AND MENU]
    ---
    --- Writes a colored message to the console on a new line.
    ---
    ---@param ... string | Color The message to write to the console.
    function console.writeLine( ... )
        return console_write( ... ), console_write( "\n" )
    end

end

do

    local engine_consoleCommandAdd = engine.consoleCommandAdd

    --- [SHARED AND MENU]
    ---
    --- The console command object.
    ---
    ---@class gpm.std.console.Command : gpm.std.Object
    ---@field __class gpm.std.console.Command
    ---@field name string The name of the console command.
    ---@field description string The help text of the console command.
    ---@field flags integer The flags of the console command.
    local Command = std.class.base( "console.Command" )

    local commands = {}

    ---@param options gpm.std.console.Command.Options
    ---@protected
    function Command:__init( options )
        local name = options.name
        self.name = name

        local description = options.description or ""
        self.description = description

        local flags = options.flags or 0

        for i = 1, convar_flag_count, 1 do
            local flag = convar_flags[ i ]
            local flag_name = flag[ 1 ]
            if options[ flag_name ] then
                flags = bit_bor( flags, flag[ 2 ] )
                self[ flag_name ] = true
            else
                self[ flag_name ] = false
            end
        end

        self.flags = flags

        engine_consoleCommandAdd( name, description, flags )

        self.callbacks = {}

        commands[ name ] = self
    end

    ---@param name string
    ---@return gpm.std.console.Command?
    ---@protected
    function Command:__new( name )
        return commands[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- The console command class.
    ---
    ---@class gpm.std.console.CommandClass : gpm.std.console.Command
    ---@field __base gpm.std.console.Command
    ---@overload fun( options: gpm.std.console.Command.Options ): gpm.std.console.Command
    local CommandClass = std.class.create( Command )
    console.Command = CommandClass

    --- [SHARED AND MENU]
    ---
    --- Returns the console command with the given name.
    ---
    ---@return gpm.std.console.Command? obj The console command with the given name, or `nil` if it does not exist.
    function CommandClass.get( name )
        return commands[ name ]
    end

    CommandClass.exists = engine.consoleCommandExists

    ---@diagnostic disable-next-line: undefined-field
    if std.CLIENT_MENU then
        local glua_input = _G.input
        if glua_input ~= nil and glua_input.TranslateAlias ~= nil then
            ---@diagnostic disable-next-line: undefined-field
            CommandClass.translateAlias = glua_input.TranslateAlias
        else

            --- [CLIENT AND MENU]
            ---
            --- Translates a console command alias, basically reverse of the `alias` console command.
            ---
            ---@param str string The alias to lookup.
            ---@return string | nil cmd The command(s) this alias will execute if ran, or nil if the alias doesn't exist.
            ---@diagnostic disable-next-line: duplicate-set-field
            function CommandClass.translateAlias( str ) end

        end
    end

    CommandClass.run = engine_consoleCommandRun

    --- [SHARED AND MENU]
    ---
    --- Runs the console command.
    ---
    ---@param ... string The arguments to pass to the console command.
    function Command:run( ... )
        engine_consoleCommandRun( self.name, ... )
    end

    do

        ---@diagnostic disable-next-line: undefined-field
        local is_blacklisted = _G.IsConCommandBlocked

        if is_blacklisted == nil then
            ---@param str string
            function is_blacklisted( str )
                return false
            end
        end

        CommandClass.isBlacklisted = is_blacklisted

        --- [SHARED AND MENU]
        ---
        --- Returns whether the console command is blacklisted.
        ---
        ---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
        function Command:isBlacklisted()
            return is_blacklisted( self.name )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the console command.
    ---
    ---@param identifier any The identifier of the callback.
    ---@param fn function The callback function.
    ---@param once boolean? Whether the callback should be called only once.
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
        local future = futures_Future()

        self:addCallback( future, function( ... )
            return future:setResult( { ... } )
        end, true )

        return future:await()
    end

    engine.consoleCommandCatch( function( ply, cmd, args, argument_string )
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

    local engine_consoleVariableCreate = engine.consoleVariableCreate
    local engine_consoleVariableGet = engine.consoleVariableGet

    local tostring, tonumber, toboolean = std.tostring, std.tonumber, std.toboolean
    local isnumber = std.isnumber
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
    ---@class gpm.std.console.Variable : gpm.std.Object
    ---@field __class gpm.std.console.Variable
    ---@field protected object ConVar The `ConVar` object.
    ---@field protected type gpm.std.console.Variable.Type The type of the console variable.
    ---@field name string The name of the console variable.
    local Variable = std.class.base( "console.Variable" )

    local variables = {}

    ---@param options gpm.std.console.Variable.Options The data of the console variable.
    ---@protected
    function Variable:__init( options )
        local name = options.name
        self.name = name

        local cvar_type = options.type or "string"
        self.type = cvar_type

        local object = engine_consoleVariableGet( name )
        if object == nil then
            local default = options.default
            if default == nil then
                default = ""
            elseif type( default ) ~= cvar_type then
                error( "default value must match console variable options type (" .. cvar_type .. ").", 3 )
            elseif cvar_type == "boolean" then
                default = default and "1" or "0"
            elseif cvar_type == "number" then
                default = tostring( default ) or "0"
            end

            ---@cast default string

            ---@type string
            local description = options.description or ""
            self.description = description

            ---@type integer
            local flags = options.flags or 0

            for i = 1, convar_flag_count, 1 do
                local flag = convar_flags[ i ]
                local flag_name = flag[ 1 ]
                if options[ flag_name ] then
                    flags = bit_bor( flags, flag[ 2 ] )
                    self[ flag_name ] = true
                else
                    self[ flag_name ] = false
                end
            end

            self.flags = flags

            local min = options.min
            self.min = min

            local max = options.max
            self.max = max

            object = engine_consoleVariableCreate( name, default, flags, description, min, max )
        end

        if object == nil then
            error( "failed to create console variable, unknown error", 3 )
        else
            self.object = object
        end

        self.callbacks = {}

        variables[ name ] = self
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
    ---@class gpm.std.console.VariableClass : gpm.std.console.Variable
    ---@field __base gpm.std.console.Variable
    ---@overload fun( options: gpm.std.console.Variable.Options ): gpm.std.console.Variable
    local VariableClass = std.class.create( Variable )
    console.Variable = VariableClass

    VariableClass.exists = engine.consoleVariableExists

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
    ---@param cvar_type gpm.std.console.Variable.Type? The type of the console variable.
    ---@return gpm.std.console.Variable variable The `ConsoleVariable` object.
    function VariableClass.get( name, cvar_type )
        local value = variables[ name ]
        if value == nil then
            local object = engine_consoleVariableGet( name )
            if object == nil then
                error( "console variable '" .. name .. "' does not exist.", 2 )
            end

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
            engine_consoleCommandRun( self.name, toboolean( value ) and "1" or "0" )
        elseif cvar_type == "string" then
            engine_consoleCommandRun( self.name, tostring( value ) )
        elseif cvar_type == "number" then
            engine_consoleCommandRun( self.name, string_format( "%f", tonumber( value, 10 ) ) )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the `ConsoleVariable` object.
    ---
    ---@param name string The name of the console variable.
    ---@param value boolean | string | number The value to set.
    function VariableClass.set( name, value )
        local value_type = type( value )
        if value_type == "boolean" then
            engine_consoleCommandRun( name, value and "1" or "0" )
        elseif value_type == "string" then
            engine_consoleCommandRun( name, value )
        elseif value_type == "number" then
            engine_consoleCommandRun( name, string_format( "%f", tonumber( value, 10 ) ) )
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
        local object = engine_consoleVariableGet( name )
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
        local object = engine_consoleVariableGet( name )
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
        local object = engine_consoleVariableGet( name )
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
        engine_consoleCommandRun( self.name, getDefault( self.object ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reverts the value of the `ConsoleVariable` object to its default value.
    ---
    ---@param name string The name of the console variable.
    function VariableClass.revert( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            error( "Variable '" .. name .. "' does not available.", 2 )
        else
            engine_consoleCommandRun( name, getDefault( object ) )
        end
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
            local object = engine_consoleVariableGet( name )
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
        local object = engine_consoleVariableGet( name )
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
            local object = engine_consoleVariableGet( name )
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
            local object = engine_consoleVariableGet( name )
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
            local object = engine_consoleVariableGet( name )
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
            local object = engine_consoleVariableGet( name )
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
            local object = engine_consoleVariableGet( name )
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
        local f = futures_Future()

        ---@diagnostic disable-next-line: param-type-mismatch
        self:addChangeCallback( nil, function( _, __, value )
            f:setResult( value )
        end, true )

        return f:await()
    end

    engine.consoleVariableCatch( function( name, old, new )
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
