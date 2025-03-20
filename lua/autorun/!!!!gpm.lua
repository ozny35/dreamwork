if gpm == nil then
    if SERVER then
        AddCSLuaFile( "gpm/init.lua" )
    end

    include( "gpm/init.lua" )
end
