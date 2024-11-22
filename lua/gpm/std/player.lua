local _G = _G
local std, glua_game = _G.gpm.std, _G.game

local is_string, is_number
do
    local is = std.is
    is_string, is_number = is.string, is.number
end

local glua_player, NULL, Player = _G.player, _G.NULL, _G.Player
local player_Iterator = glua_player.Iterator

---@class Player
local PLAYER = std.findMetatable( "Player" )

---@class gpm.std.player
local player = {
    getLimit = glua_game.MaxPlayers,
    iterator = player_Iterator
}

if std.SERVER then
    local PLAYER_IsListenServerHost = PLAYER.IsListenServerHost
    local player_CreateNextBot = glua_player.CreateNextBot

    PLAYER.new = function( value )
        if is_string( value ) then
            ---@diagnostic disable-next-line: param-type-mismatch
            return player_CreateNextBot( value )
        elseif is_number( value ) then
            ---@diagnostic disable-next-line: param-type-mismatch
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
elseif std.CLIENT then
    local LocalPlayer = _G.LocalPlayer

    PLAYER.new = function( value )
        if is_string( value ) then
            return std.error( "Client cannot create players.", 2 )
        elseif is_number( value ) then
            ---@diagnostic disable-next-line: param-type-mismatch
            return Player( value )
        else
            return LocalPlayer()
        end
    end

    do

        local command_run = std.console.command.run
        local glua_chat = _G.chat

        ---@class gpm.std.player.chat
        local chat = {
            playSound = glua_chat.PlaySound
        }

        local key2key = {
            getPosition = "GetChatBoxPos",
            getSize = "GetChatBoxSize",
            addText = "AddText",
            close = "Close",
            open = "Open"
        }

        setmetatable( chat, {
            __index = function( _, key )
                return glua_chat[ key2key[ key ] or -1 ]
            end
        } )

        --- Sends a message to the player chat.
        ---@param text string: The message's content.
        ---@param teamChat boolean?: Whether the message should be sent as team chat.
        function chat.say( text, teamChat )
            command_run( teamChat and "say_team" or "say", text )
        end

        player.chat = chat

    end

end

-- TODO: https://wiki.facepunch.com/gmod/team
---@class gpm.std.player.team
local team = {}

player.team = team


-- ---@class gpm.std.player
-- player = std.class( "player", PLAYER, player )
-- return player
