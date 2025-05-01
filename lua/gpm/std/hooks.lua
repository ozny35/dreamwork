local gpm = _G.gpm
local std = gpm.std

local engine_hookCatch = gpm.engine.hookCatch
local Hook = std.Hook

do

    ---@class gpm.std.game
    local game = std.game

    if game.Tick == nil then

        --- [SHARED AND MENU]
        ---
        --- A hook that is called every tick.
        local Tick = Hook( "game.Tick" )
        engine_hookCatch( "Tick", Tick )
        game.Tick = Tick

    end

    if game.ShutDown == nil then

        --- [SHARED]
        ---
        --- A hook that is called when the game is shutting down.
        local ShutDown = Hook( "game.ShutDown" )
        engine_hookCatch( "ShutDown", ShutDown )
        game.ShutDown = ShutDown

    end

end
