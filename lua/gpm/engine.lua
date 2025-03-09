local _G = _G
local gpm = _G.gpm

local std = gpm.std
local MENU = std.MENU
local math_clamp = std.math.clamp
local setmetatable = std.setmetatable
local table_insert = std.table.insert
local detour_attach = gpm.detour.attach

local transducers = gpm.transducers

--- [SHARED AND MENU] Source engine events library
---@class gpm.engine
local engine = gpm.engine or {}

-- TODO: ENGINE HOOKS AND OTHER THINGS

local engine_hookCall

if engine.hookCatch == nil then

    local engine_hooks = {}

    do

        local AcceptInput = {}

        setmetatable( AcceptInput, {
            __call = function( self, entity, input, activator, caller, value )
                entity, activator, caller = transducers[ entity ], transducers[ activator ], transducers[ caller ]

                for i = 1, #self, 1 do
                    local allow = self[ i ]( entity, input, activator, caller, value )
                    if allow ~= nil then return not allow end
                end
            end,
            __mode = "v"
        } )

        engine_hooks.AcceptInput = AcceptInput

    end

    do

        local metatable = {
            __call = function( self, ... )
                for i = 1, #self, 1 do
                    local a, b, c, d, e, f = self[ i ]( ... )
                    if a ~= nil then return a, b, c, d, e, f end
                end
            end,
            __mode = "v"
        }

        function engine.hookCatch( event_name, fn, priority )
            local lst = engine_hooks[ event_name ]
            if lst == nil then
                lst = {}
                setmetatable( lst, metatable )
                engine_hooks[ event_name ] = lst
            end

            table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
        end

    end

    function engine_hookCall( event_name, ... )
        return engine_hooks[ event_name ]( ... )
    end

    engine.hookCall = engine_hookCall

    do

        local hook = _G.hook
        if hook == nil then
            ---@diagnostic disable-next-line: inject-field
            hook = {}; _G.hook = hook
        end

        local hook_Call = hook.Call
        if hook_Call == nil then
            function hook.Call( event_name, _, ... )
                local lst = engine_hooks[ event_name ]
                if lst == nil then return end
                return lst( ... )
            end
        else
            hook.Call = detour_attach( hook_Call, function( fn, event_name, gamemode_table, ... )
                local lst = engine_hooks[ event_name ]
                if lst ~= nil then
                    local a, b, c, d, e, f = lst( ... )
                    if a ~= nil then return a, b, c, d, e, f end
                end

                return fn( event_name, gamemode_table, ... )
            end )
        end

    end

    if MENU then

        do

            local json_deserialize = std.crypto.json.deserialize

            local function listAddonPresets()
                local json = _G.LoadAddonPresets()
                if not json then return end

                local tbl = json_deserialize( json, true, true )
                if not tbl then return end

                -- aka GM:AddonPresetsLoaded( tbl )
                engine_hookCall( "AddonPresetsLoaded", tbl )
            end

            local ListAddonPresets = _G.ListAddonPresets
            if std.isfunction( ListAddonPresets ) then
                _G.ListAddonPresets = detour_attach( _G.ListAddonPresets, function( fn )
                    listAddonPresets()
                    return fn()
                end )
            else
                _G.ListAddonPresets = listAddonPresets
            end

        end

        do

            local function gameDetails( server_name, loading_url, map_name, max_players, player_steamid64, gamemode_name )
                engine_hookCall( "GameDetails", {
                    server_name = server_name,
                    loading_url = loading_url,
                    map_name = map_name,
                    max_players = max_players,
                    player_steamid64 = player_steamid64,
                    gamemode_name = gamemode_name
                } )
            end

            local GameDetails = _G.GameDetails
            if GameDetails == nil then
                _G.GameDetails = detour_attach( _G.GameDetails, function( fn, ... )
                    gameDetails( ... )
                    return fn( ... )
                end )
            else
                _G.GameDetails = gameDetails
            end

        end

    end

end

if engine.consoleCommandCatch == nil then

    local lst = {}

    setmetatable( lst, {
        __call = function( self, ply, cmd, args, argument_string )
            for i = 1, #self, 1 do
                local result = self[ i ]( ply, cmd, args, argument_string )
                if result ~= nil then return result ~= false end
            end
        end,
        __mode = "v"
    } )

    function engine.consoleCommandCatch( fn, priority )
        table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local concommand = _G.concommand
    if concommand == nil then
        ---@diagnostic disable-next-line: inject-field
        concommand = {}; _G.concommand = concommand
    end

    local concommand_Run = concommand.Run
    if concommand_Run == nil then
        function concommand.Run( ply, cmd, args, argument_string )
            return lst( ply, cmd, args, argument_string ) == true
        end
    else
        concommand.Run = detour_attach( concommand_Run, function( fn, ply, cmd, args, argument_string )
            local result = lst( ply, cmd, args, argument_string )
            if result == nil then
                return fn( ply, cmd, args, argument_string )
            else
                return result
            end
        end )
    end

end

if engine.consoleVariableCatch == nil then

    local lst = {}

    setmetatable( lst, {
        __call = function( self, name, old, new )
            for i = 1, #self, 1 do
                self[ i ]( name, old, new )
            end
        end,
        __mode = "v"
    } )

    function engine.consoleVariableCatch( fn, priority )
        table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local cvars = _G.cvars
    if cvars == nil then
        ---@diagnostic disable-next-line: inject-field
        cvars = {}; _G.cvars = cvars
    end

    local OnConVarChanged = cvars.OnConVarChanged
    if OnConVarChanged == nil then
        function cvars.OnConVarChanged( name, old, new )
            lst( name, old, new )
        end
    else
        cvars.OnConVarChanged = detour_attach( OnConVarChanged, function( fn, name, old, new )
            lst( name, old, new )
            return fn( name, old, new )
        end )
    end

end

if engine.entityCreationCatch == nil then

    local lst = {}

    setmetatable( lst, {
        __call = function( self, name )
            for i = 1, #self, 1 do
                local tbl = self[ i ]( name )
                if tbl ~= nil then return tbl end
            end
        end,
        __mode = "v"
    } )

    function engine.entityCreationCatch( fn, priority )
        table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local scripted_ents = _G.scripted_ents
    if scripted_ents == nil then
        ---@diagnostic disable-next-line: inject-field
        scripted_ents = {}; _G.scripted_ents = scripted_ents
    end

    local Get = scripted_ents.Get
    if Get == nil then
        function scripted_ents.Get( name )
            return lst( name )
        end
    else
        scripted_ents.Get = detour_attach( Get, function( fn, name )
            local tbl = lst( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )
    end

end

return engine
