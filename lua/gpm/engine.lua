local _G = _G

---@class gpm
local gpm = _G.gpm

local std = gpm.std
local MENU = std.MENU
local math_clamp = std.math.clamp
local debug_fempty = std.debug.fempty
local setmetatable = std.setmetatable
local table_insert = std.table.insert
local detour_attach = gpm.detour.attach

local transducers = gpm.transducers

local gameevent_Listen
if _G.gameevent == nil then
    gameevent_Listen = debug_fempty
else
    gameevent_Listen = _G.gameevent.Listen or debug_fempty
end

--- [SHARED AND MENU]
---
--- Source engine library.
---
---@class gpm.engine
local engine = gpm.engine or {}
gpm.engine = engine

if engine.hookCatch == nil then

    local engine_hooks = {}

    local custom_calls = {
        AcceptInput = function( self, entity, input, activator, caller, value )
            entity, activator, caller = transducers[ entity ], transducers[ activator ], transducers[ caller ]

            for i = 1, #self, 1 do
                local allow = self[ i ]( entity, input, activator, caller, value )
                if allow ~= nil then return not allow end
            end
        end
    }

    do

        local metatable = {
            __call = function( self, ... )
                for i = 1, #self, 1 do
                    local a, b, c, d, e, f = self[ i ]( ... )
                    if a ~= nil then return a, b, c, d, e, f end
                end
            end
        }

        --- [SHARED AND MENU]
        ---
        --- Adds a callback to the `hookCatch` event.
        ---
        ---@param event_name string
        ---@param fn gpm.std.Hook | fun( ... ): any, any, any, any, any, any
        ---@param priority integer | nil
        function engine.hookCatch( event_name, fn, priority )
            local lst = engine_hooks[ event_name ]
            if lst == nil then
                lst = {}

                if custom_calls[ event_name ] == nil then
                    setmetatable( lst, metatable )
                else
                    setmetatable( lst, {
                        __call = custom_calls[ event_name ]
                    } )
                end

                engine_hooks[ event_name ] = lst
            end

            if priority == nil then
                table_insert( lst, #lst + 1, fn )
            else
                table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Calls a source engine event.
    ---
    ---@param event_name string
    ---@param ... any
    ---@return any, any, any, any, any, any
    local function engine_hookCall( event_name, ... )
        local lst = engine_hooks[ event_name ]
        if lst ~= nil then
            return lst( ... )
        end
    end

    engine.hookCall = engine_hookCall

    do

        local hook = _G.hook
        if hook == nil then
            ---@diagnostic disable-next-line: inject-field
            hook = {}; _G.hook = hook
        end

        if hook.Call == nil then
            ---@diagnostic disable-next-line: duplicate-set-field
            function hook.Call( event_name, _, ... )
                local lst = engine_hooks[ event_name ]
                if lst == nil then return end
                return lst( ... )
            end
        else
            hook.Call = detour_attach( hook.Call, function( fn, event_name, gamemode_table, ... )
                local lst = engine_hooks[ event_name ]
                if lst ~= nil then
                    local a, b, c, d, e, f = lst( ... )
                    if a ~= nil then
                        return a, b, c, d, e, f
                    end
                end

                return fn( event_name, gamemode_table, ... )
            end )
        end

    end

    if MENU then

        do

            local function listAddonPresets()
                engine_hookCall( "AddonPresetsLoaded", _G.LoadAddonPresets() )
            end

            if _G.ListAddonPresets == nil then
                _G.ListAddonPresets = listAddonPresets
            else
                _G.ListAddonPresets = detour_attach( _G.ListAddonPresets, function( fn )
                    listAddonPresets()
                    return fn()
                end )
            end

        end

        do

            ---@param server_name string
            ---@param loading_url string
            ---@param map_name string
            ---@param max_players integer
            ---@param player_steamid64 string
            ---@param gamemode_name string
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

            if _G.GameDetails == nil then
                _G.GameDetails = gameDetails
            else
                _G.GameDetails = detour_attach( _G.GameDetails, function( fn, ... )
                    gameDetails( ... )
                    return fn( ... )
                end )
            end

        end

    end

end

local engine_hookCall = engine.hookCall

if engine.consoleCommandCatch == nil then

    local lst = {}

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `consoleCommandCatch` event.
    ---
    ---@param fn gpm.std.Hook | fun( ply: Player, cmd: string, args: string[], argument_string: string ): boolean?
    ---@param priority integer | nil
    function engine.consoleCommandCatch( fn, priority )
        if priority == nil then
            table_insert( lst, #lst + 1, fn )
        else
            table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
        end
    end

    ---@param ply Player
    ---@param cmd string
    ---@param args string[]
    ---@param argument_string string
    local function run_callbacks( ply, cmd, args, argument_string )
        for i = 1, #lst, 1 do
            local result = lst[ i ]( ply, cmd, args, argument_string )
            if result ~= nil then
                return result ~= false
            end
        end

        return nil
    end

    local concommand = _G.concommand
    if concommand == nil then
        ---@diagnostic disable-next-line: inject-field
        concommand = {}; _G.concommand = concommand
    end

    if concommand.Run == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function concommand.Run( ply, cmd, args, argument_string )
            return run_callbacks( ply, cmd, args, argument_string ) == true
        end
    else
        concommand.Run = detour_attach( concommand.Run, function( fn, ply, cmd, args, argument_string )
            local result = run_callbacks( ply, cmd, args, argument_string )
            if result == nil then
                return fn( ply, cmd, args, argument_string )
            else
                return result
            end
        end )
    end

end

if engine.consoleCommandAutoCompleteCatch == nil then

    local lst = {}

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `consoleCommandAutoCompleteCatch` event.
    ---
    ---@param fn gpm.std.Hook | fun( cmd: string, argument_string: string, args: string[] ): string[]?
    ---@param priority integer | nil
    function engine.consoleCommandAutoCompleteCatch( fn, priority )
        if priority == nil then
            table_insert( lst, #lst + 1, fn )
        else
            table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
        end
    end

    local function run_callbacks( cmd, argument_string, args )
        for i = 1, #lst, 1 do
            local result = lst[ i ]( cmd, argument_string, args )
            if result ~= nil then
                return result
            end
        end
    end

    local concommand = _G.concommand
    if concommand == nil then
        ---@diagnostic disable-next-line: inject-field
        concommand = {}; _G.concommand = concommand
    end

    if concommand.AutoComplete == nil then
        concommand.AutoComplete = run_callbacks
    else
        concommand.AutoComplete = detour_attach( concommand.AutoComplete, function( fn, cmd, argument_string, args )
            local result = run_callbacks( cmd, argument_string, args )
            if result == nil then
                return fn( cmd, argument_string, args )
            else
                return result
            end
        end )
    end

end

if engine.consoleVariableGet == nil or engine.consoleVariableCreate == nil or engine.consoleVariableExists == nil then

    local GetConVar_Internal = _G.GetConVar_Internal or debug_fempty
    local ConVarExists = _G.ConVarExists or debug_fempty
    local CreateConVar = _G.CreateConVar or debug_fempty

    ---@type table<string, ConVar>
    local cache = {}

    std.debug.gc.setTableRules( cache, false, true )

    --- [SHARED AND MENU]
    ---
    --- Get console variable C object (userdata).
    ---
    ---@param name string The name of the console variable.
    ---@return ConVar? cvar The console variable object.
    function engine.consoleVariableGet( name )
        local value = cache[ name ]
        if value == nil then
            value = GetConVar_Internal( name )
            cache[ name ] = value
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Create console variable C object (userdata).
    ---
    ---@param name string The name of the console variable.
    ---@param default string The default value of the console variable.
    ---@param flags? integer The flags of the console variable.
    ---@param description? string The description of the console variable.
    ---@param min? number The minimum value of the console variable.
    ---@param max? number The maximum value of the console variable.
    ---@return ConVar? cvar The console variable object.
    function engine.consoleVariableCreate( name, default, flags, description, min, max )
        local value = cache[ name ]
        if value == nil then
            ---@diagnostic disable-next-line: param-type-mismatch
            value = CreateConVar( name, default, flags, description, min, max )
            cache[ name ] = value
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the console variable exists.
    ---
    ---@param name string The name of the console variable.
    ---@return boolean exists `true` if the console variable exists, `false` otherwise.
    function engine.consoleVariableExists( name )
        return cache[ name ] ~= nil or ConVarExists( name )
    end

end

if engine.consoleCommandAdd == nil or engine.consoleCommandExists == nil then

    local commands = {}

    if _G.AddConsoleCommand == nil then
        _G.AddConsoleCommand = debug_fempty
    else
        _G.AddConsoleCommand = detour_attach( _G.AddConsoleCommand, function( fn, name, description, flags )
            if commands[ name ] == nil then
                commands[ name ] = true
                fn( name, description, flags )
            end
        end )
    end

    engine.consoleCommandAdd = _G.AddConsoleCommand

    --- [SHARED AND MENU]
    ---
    --- Checks if the console command exists.
    ---
    ---@param name string The name of the console command.
    ---@return boolean exists `true` if the console command exists, `false` otherwise.
    function engine.consoleCommandExists( name )
        return commands[ name ] ~= nil
    end

end

if engine.consoleCommandRun == nil then

    --- [SHARED AND MENU]
    ---
    --- Run console command.
    ---
    ---@param name string The name of the console command.
    ---@param ... string? The arguments of the console command.
    engine.consoleCommandRun = _G.RunConsoleCommand or function( name, ... )
        std.print( "engine.consoleCommandRun", name, ... )
    end

end

if engine.consoleVariableCatch == nil then

    local lst = {}

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `consoleVariableCatch` event.
    ---
    ---@param fn gpm.std.Hook | fun( str_name: string, str_old: string, str_new: string )
    ---@param priority integer | nil
    function engine.consoleVariableCatch( fn, priority )
        if priority == nil then
            table_insert( lst, #lst + 1, fn )
        else
            table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
        end
    end

    ---@param str_name string
    ---@param str_old string
    ---@param str_new string
    local function run_callbacks( str_name, str_old, str_new )
        for i = 1, #lst, 1 do
            lst[ i ]( str_name, str_old, str_new )
        end
    end

    local cvars = _G.cvars
    if cvars == nil then
        ---@diagnostic disable-next-line: inject-field
        cvars = {}; _G.cvars = cvars
    end

    if cvars.OnConVarChanged == nil then
        cvars.OnConVarChanged = run_callbacks
    else
        cvars.OnConVarChanged = detour_attach( cvars.OnConVarChanged, function( fn, str_name, str_old, str_new )
            run_callbacks( str_name, str_old, str_new )
            return fn( str_name, str_old, str_new )
        end )
    end

    gameevent_Listen( "server_cvar" )

    local engine_consoleVariableGet = engine.consoleVariableGet
    local values = {}

    engine.hookCatch( "server_cvar", function( data )
        local str_name, str_new = data.cvarname, data.cvarvalue

        local str_old = values[ str_name ]
        if str_old == nil then
            local convar = engine_consoleVariableGet( str_name )
            if convar == nil then return end

            str_old = convar:GetDefault()
            values[ str_name ] = str_old
        else
            values[ str_name ] = str_new
        end

        run_callbacks( str_name, str_old, str_new )
    end, 1 )

end

if engine.entityCreationCatch == nil then

    local lst = {}

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `entityCreationCatch` event.
    ---
    ---@param fn gpm.std.Hook | fun( name: string ): table | nil
    ---@param priority integer | nil
    function engine.entityCreationCatch( fn, priority )
        if priority == nil then
            table_insert( lst, #lst + 1, fn )
        else
            table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
        end
    end

    ---@param name string
    local function run_callbacks( name )
        for i = 1, #lst, 1 do
            local tbl = lst[ i ]( name )
            if tbl ~= nil then
                return tbl
            end

            return nil
        end
    end

    local scripted_ents = _G.scripted_ents
    if scripted_ents == nil then
        ---@diagnostic disable-next-line: inject-field
        scripted_ents = {}; _G.scripted_ents = scripted_ents
    end

    if scripted_ents.Get == nil then
        scripted_ents.Get = run_callbacks
    else
        scripted_ents.Get = detour_attach( scripted_ents.Get, function( fn, name )
            local tbl = run_callbacks( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )
    end

    if scripted_ents.OnLoaded == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function scripted_ents.OnLoaded( name )
            engine_hookCall( "EntityLoaded", name )
        end
    else
        scripted_ents.OnLoaded = detour_attach( scripted_ents.OnLoaded, function( fn, name )
            engine_hookCall( "EntityLoaded", name )
            return fn( name )
        end )
    end

end

if engine.weaponCreationCatch == nil then

    local lst = {}

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `weaponCreationCatch` event.
    ---
    ---@param fn gpm.std.Hook | fun( name: string ): table | nil
    ---@param priority integer | nil
    function engine.weaponCreationCatch( fn, priority )
        if priority == nil then
            table_insert( lst, #lst + 1, fn )
        else
            table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
        end
    end

    ---@param name string
    local function run_callbacks( name )
        for i = 1, #lst, 1 do
            local tbl = lst[ i ]( name )
            if tbl ~= nil then
                return tbl
            end
        end
    end

    local weapons = _G.weapons
    if weapons == nil then
        ---@diagnostic disable-next-line: inject-field
        weapons = {}; _G.weapons = weapons
    end

    if weapons.Get == nil then

        weapons.Get = run_callbacks

    else

        weapons.Get = detour_attach( weapons.Get, function( fn, name )
            local tbl = run_callbacks( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )

    end

    if weapons.OnLoaded == nil then

        ---@param name string
        ---@diagnostic disable-next-line: duplicate-set-field
        function weapons.OnLoaded( name )
            engine_hookCall( "WeaponLoaded", name )
        end

    else

        ---@param name string
        weapons.OnLoaded = detour_attach( weapons.OnLoaded, function( fn, name )
            engine_hookCall( "WeaponLoaded", name )
            return fn( name )
        end )

    end

end

if engine.effectCreationCatch == nil then

    local lst = {}

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `effectCreationCatch` event.
    ---
    ---@param fn gpm.std.Hook | fun( name: string ): table | nil
    ---@param priority integer | nil
    function engine.effectCreationCatch( fn, priority )
        if priority == nil then
            table_insert( lst, #lst + 1, fn )
        else
            table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
        end
    end

    ---@param name string
    local function run_callbacks( name )
        for i = 1, #lst, 1 do
            local tbl = lst[ i ]( name )
            if tbl ~= nil then
                return tbl
            end
        end
    end

    local effects = _G.effects
    if effects == nil then
        ---@diagnostic disable-next-line: inject-field
        effects = {}; _G.effects = effects
    end

    if effects.Create == nil then
        effects.Create = run_callbacks
    else
        effects.Create = detour_attach( effects.Create, function( fn, name )
            local tbl = run_callbacks( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )
    end

end

if _G.gamemode == nil then

    local gamemode = {}

    ---@diagnostic disable-next-line: inject-field
    _G.gamemode = gamemode

    local gamemodes = {}

    ---@param name string
    function gamemode.Get( name )
        return gamemodes[ name ]
    end

    ---@param gm table
    ---@param name string
    ---@param base_name string
    function gamemode.Register( gm, name, base_name )
        gamemodes[ name ] = {
            FolderName = gm.FolderName,
            Name = gm.Name or name,
            Folder = gm.Folder,
            Base = base_name
        }
    end

end

do

    local engine_GetGames, engine_GetAddons

    if _G.engine == nil then
        engine_GetGames, engine_GetAddons = _G.engine.GetGames, _G.engine.GetAddons
    else
        engine_GetGames, engine_GetAddons = debug_fempty, debug_fempty
    end

    local title2addon = {}
    engine.title2addon = title2addon

    local wsid2addon = {}
    engine.wsid2addon = wsid2addon

    local name2game = {}
    engine.name2game = name2game

    -- TODO: make somewhere Addon is mounted function by addon titile

    local addons, addon_count
    local games, game_count

    local function update_mounted()
        games, addons = engine_GetGames() or {}, engine_GetAddons() or {}
        game_count, addon_count = #games, #addons

        engine.games, engine.game_count = games, game_count
        engine.addons, engine.addon_count = addons, addon_count

        std.table.empty( name2game )

        for i = 1, game_count, 1 do
            local data = games[ i ]
            if data.mounted then
                name2game[ data.folder ] = true
            end
        end

        std.table.empty( title2addon )
        std.table.empty( wsid2addon )

        for i = 1, addon_count, 1 do
            local data = addons[ i ]
            if data.mounted then
                title2addon[ data.title ] = true
                wsid2addon[ data.wsid ] = true
            end
        end
    end

    engine.hookCatch( "GameContentChanged", update_mounted )
    update_mounted()

end

-- TODO: matproxy
-- TODO: effects | particles?
