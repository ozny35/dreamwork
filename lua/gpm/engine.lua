local _G = _G

---@class gpm
local gpm = _G.gpm

local std = gpm.std
local MENU = std.MENU
local math_clamp = std.math.clamp
local setmetatable = std.setmetatable
local table_insert = std.table.insert
local detour_attach = gpm.detour.attach

local transducers = gpm.transducers

--- [SHARED AND MENU]
---
--- Source engine events library
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
            end,
            __mode = "v"
        }

        function engine.hookCatch( event_name, fn, priority )
            local lst = engine_hooks[ event_name ]
            if lst == nil then
                lst = {}

                if custom_calls[ event_name ] == nil then
                    setmetatable( lst, metatable )
                else
                    setmetatable( lst, {
                        __call = custom_calls[ event_name ],
                        __mode = "v"
                    } )
                end

                engine_hooks[ event_name ] = lst
            end

            table_insert( lst, priority == nil and ( #lst + 1 ) or math_clamp( priority, 1, #lst + 1 ), fn )
        end

    end

    local function engine_hookCall( event_name, ... )
        local lst = engine_hooks[ event_name ]
        if lst == nil then return end
        return lst( ... )
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
            ---@diagnostic disable-next-line: duplicate-set-field
            function hook.Call( event_name, _, ... )
                local lst = engine_hooks[ event_name ]
                if lst == nil then return end
                return lst( ... )
            end
        else
            ---@diagnostic disable-next-line: duplicate-set-field
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

                local tbl = json_deserialize( json )
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

local engine_hookCall = engine.hookCall

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
        table_insert( lst, priority == nil and ( #lst + 1 ) or math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local concommand = _G.concommand
    if concommand == nil then
        ---@diagnostic disable-next-line: inject-field
        concommand = {}; _G.concommand = concommand
    end

    local concommand_Run = concommand.Run
    if concommand_Run == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function concommand.Run( ply, cmd, args, argument_string )
            return lst( ply, cmd, args, argument_string ) == true
        end
    else
        ---@diagnostic disable-next-line: duplicate-set-field
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
        table_insert( lst, priority == nil and ( #lst + 1 ) or math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local cvars = _G.cvars
    if cvars == nil then
        ---@diagnostic disable-next-line: inject-field
        cvars = {}; _G.cvars = cvars
    end

    local OnConVarChanged = cvars.OnConVarChanged
    if OnConVarChanged == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function cvars.OnConVarChanged( name, old, new )
            lst( name, old, new )
        end
    else
        ---@diagnostic disable-next-line: duplicate-set-field
        cvars.OnConVarChanged = detour_attach( OnConVarChanged, function( fn, name, old, new )
            lst( name, old, new )
            return fn( name, old, new )
        end )
    end

    local CONVAR = std.debug.findmetatable( "ConVar" )

    local gameevent = _G.gameevent
    if gameevent ~= nil and gameevent.Listen ~= nil and CONVAR ~= nil then
        ---@cast CONVAR ConVar

        local GetConVar = _G.GetConVar_Internal or std.debug.fempty
        local CONVAR_GetDefault = CONVAR.GetDefault

        gameevent.Listen( "server_cvar" )

        local values = {}

        engine.hookCatch( "server_cvar", function( data )
            local name, new = data.cvarname, data.cvarvalue

            local old = values[ name ]
            if old == nil then
                local convar = GetConVar( name )
                if not convar then return end

                old = CONVAR_GetDefault( convar )
                values[ name ] = old
            else
                values[ name ] = new
            end

            lst( name, old, new )
        end, 1 )

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
        table_insert( lst, priority == nil and ( #lst + 1 ) or math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local scripted_ents = _G.scripted_ents
    if scripted_ents == nil then
        ---@diagnostic disable-next-line: inject-field
        scripted_ents = {}; _G.scripted_ents = scripted_ents
    end

    local Get = scripted_ents.Get
    if Get == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function scripted_ents.Get( name )
            return lst( name )
        end
    else
        ---@diagnostic disable-next-line: duplicate-set-field
        scripted_ents.Get = detour_attach( Get, function( fn, name )
            local tbl = lst( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )
    end

    local OnLoaded = scripted_ents.OnLoaded
    if OnLoaded == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function scripted_ents.OnLoaded( name )
            engine_hookCall( "EntityLoaded", name )
        end
    else
        ---@diagnostic disable-next-line: duplicate-set-field
        scripted_ents.OnLoaded = detour_attach( OnLoaded, function( fn, name )
            engine_hookCall( "EntityLoaded", name )
            return fn( name )
        end )
    end

end

if engine.weaponCreationCatch == nil then

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

    function engine.weaponCreationCatch( fn, priority )
        table_insert( lst, priority == nil and ( #lst + 1 ) or math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local weapons = _G.weapons
    if weapons == nil then
        ---@diagnostic disable-next-line: inject-field
        weapons = {}; _G.weapons = weapons
    end

    local Get = weapons.Get
    if Get == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function weapons.Get( name )
            return lst( name )
        end
    else
        ---@diagnostic disable-next-line: duplicate-set-field
        weapons.Get = detour_attach( Get, function( fn, name )
            local tbl = lst( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )
    end

    local OnLoaded = weapons.OnLoaded
    if OnLoaded == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function weapons.OnLoaded( name )
            engine_hookCall( "WeaponLoaded", name )
        end
    else
        ---@diagnostic disable-next-line: duplicate-set-field
        weapons.OnLoaded = detour_attach( OnLoaded, function( fn, name )
            engine_hookCall( "WeaponLoaded", name )
            return fn( name )
        end )
    end

end

if engine.effectCreationCatch == nil then

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

    function engine.effectCreationCatch( fn, priority )
        table_insert( lst, priority == nil and ( #lst + 1 ) or math_clamp( priority, 1, #lst + 1 ), fn )
    end

    local effects = _G.effects
    if effects == nil then
        ---@diagnostic disable-next-line: inject-field
        effects = {}; _G.effects = effects
    end

    local Create = effects.Create
    if Create == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function effects.Create( name )
            return lst( name )
        end
    else
        ---@diagnostic disable-next-line: duplicate-set-field
        effects.Create = detour_attach( Create, function( fn, name )
            local tbl = lst( name )
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

    function gamemode.Get( name )
        return gamemodes[ name ]
    end

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
        engine_GetGames, engine_GetAddons = std.debug.fempty, std.debug.fempty
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

if engine.consoleVariableGet == nil or engine.consoleVariableCreate == nil or engine.consoleVariableExists == nil then

    local GetConVar_Internal = _G.GetConVar_Internal or std.debug.fempty
    local ConVarExists = _G.ConVarExists or std.debug.fempty
    local CreateConVar = _G.CreateConVar or std.debug.fempty

    local cache = {}

    std.setmetatable( cache, { __mode = "v" } )

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
        _G.AddConsoleCommand = std.debug.fempty
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
    engine.consoleCommandRun = _G.RunConsoleCommand or function( name, ... ) std.print( "engine.consoleCommandRun", name, ... ) end

end

-- TODO: matproxy
-- TODO: effects | particles?
