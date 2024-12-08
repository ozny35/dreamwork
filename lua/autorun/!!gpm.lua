-- launch as a gmod addon
if SERVER then
    AddCSLuaFile( "gpm/init.lua" )
end

include( "gpm/init.lua" )
