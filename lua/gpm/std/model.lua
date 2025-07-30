---@class gpm.std
local std = _G.gpm.std

local Model = std.class.base( "Model" )

function Model:__init( )

end

local ModelClass = std.class.create( Model )
std.Model = ModelClass


-- TODO: model class and think abount merging with Mesh

