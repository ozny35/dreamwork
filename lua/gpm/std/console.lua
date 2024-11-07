local _G, tostring, findMetatable, string_format, getfenv, table_unpack, select = ...
local cvars, concommand, GetConVar_Internal, RunConsoleCommand = _G.cvars, _G.concommand, _G.GetConVar_Internal, _G.RunConsoleCommand
local cvars_GetConVarCallbacks, cvars_AddChangeCallback, cvars_RemoveChangeCallback = cvars.GetConVarCallbacks, cvars.AddChangeCallback, cvars.RemoveChangeCallback

local getConVar
do

    local cache = {}

    function getConVar( name )
        local value = cache[ name ]
        if value == nil then
            value = GetConVar_Internal( name )
            cache[ name ] = value
        end

        return value
    end

end

local metatable = findMetatable( "ConVar" ) or {}
local getName, getDefault = metatable.GetName, metatable.GetDefault
local MsgC = _G.MsgC

return {
    ["variable"] = {
        -- TODO: Rewrite this crap
        ["getCallbacks"] = cvars_GetConVarCallbacks,
        ["addCallback"] = function( name, callback, identifier )
            local fenv = getfenv( 2 )
            if fenv then
                local package = fenv.__package
                if package then
                    local prefix = package.prefix
                    identifier = prefix .. ( identifier or "" )
                end
            end

            cvars_AddChangeCallback( name, callback, identifier )
        end,
        ["removeCallback"] = function( name, callback, identifier )
            local fenv = getfenv( 2 )
            if fenv then
                local package = fenv.__package
                if package then
                    local prefix = package.prefix
                    identifier = prefix .. ( identifier or "" )
                end
            end

            cvars_RemoveChangeCallback( name, callback, identifier )
        end,
        ["create"] = _G.CreateConVar,
        ["exists"] = _G.ConVarExists,
        ["get"] = getConVar,
        ["set"] = function( name, value )
            RunConsoleCommand( name, tostring( value ) )
            return nil
        end,

        -- get value
        ["getString"] = metatable.GetString,
        ["getFloat"] = metatable.GetFloat,
        ["getBool"] = metatable.GetBool,
        ["getInt"] = metatable.GetInt,

        -- set value
        ["setString"] = function( self, value )
            RunConsoleCommand( getName( self ), value )
            return self
        end,
        ["setFloat"] = function( self, value )
            RunConsoleCommand( getName( self ), string_format( "%f", value ) )
            return self
        end,
        ["setBool"] = function( self, value )
            RunConsoleCommand( getName( self ), value == true and "1" or "0" )
            return self
        end,
        ["setInt"] = function( self, value )
            RunConsoleCommand( getName( self ), string_format( "%d", value ) )
            return self
        end,
        ["revert"] = function( self )
            RunConsoleCommand( getName( self ), getDefault( self ) )
            return self
        end,

        -- get info
        ["getName"] = getName,
        ["getFlags"] = metatable.GetFlags,
        ["isFlagSet"] = metatable.IsFlagSet,
        ["getDefault"] = getDefault,
        ["getHelpText"] = metatable.GetHelpText,
        ["getMin"] = metatable.GetMin,
        ["getMax"] = metatable.GetMax,
    },
    ["command"] = {
        ["add"] = concommand.Add,
        ["run"] = RunConsoleCommand,
        ["remove"] = concommand.Remove,
        ["getTable"] = concommand.GetTable
    },
    ["write"] = MsgC,
    ["writeLine"] = function( ... )
        local args, length = { ... }, select( '#', ... ) + 1
        args[ length ] = "\n"

        return MsgC( table_unpack( args, 1, length ) )
    end
}
