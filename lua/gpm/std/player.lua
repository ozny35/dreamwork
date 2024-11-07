local _G, error, findMetatable, CLIENT, SERVER, is_string, is_number, isDedicatedServer, glua_game_MaxPlayers, class = ...
local player, NULL, Player = _G.player, _G.NULL, _G.Player
local player_Iterator = player.Iterator

local PLAYER = findMetatable( "Player" )

if SERVER then
    local PLAYER_IsListenServerHost = PLAYER.IsListenServerHost
    local player_CreateNextBot = player.CreateNextBot

    PLAYER.new = function( value )
        if is_string( value ) then
            return player_CreateNextBot( value )
        elseif is_number( value ) then
            return Player( value )
        else
            for _, ply in player_Iterator() do
                if PLAYER_IsListenServerHost( ply ) then
                    return ply
                end
            end

            return NULL
        end
    end

elseif CLIENT then
    local LocalPlayer = _G.LocalPlayer

    PLAYER.new = function( value )
        if is_string( value ) then
            return error( "Client cannot create players.", 2 )
        elseif is_number( value ) then
            return Player( value )
        else
            return LocalPlayer()
        end
    end
end

local library = {
    ["getLimit"] = glua_game_MaxPlayers,
    ["iterator"] = player_Iterator
}

return class( "player", PLAYER, library )
