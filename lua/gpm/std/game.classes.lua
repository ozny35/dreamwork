
---@class gpm.std
local std = _G.gpm.std
local class = std.class

local Model = class.base( "Model" )

local ModelClass = class.create( Model )
std.Model = ModelClass

--[[

    TODO:

    https://wiki.facepunch.com/gmod/Global.Material

    https://wiki.facepunch.com/gmod/Global.CreateMaterial

    https://wiki.facepunch.com/gmod/Global.DynamicMaterial


]]

local Material = class.base( "Material" )

local MaterialClass = class.create( Material )
std.Material = MaterialClass

local Sound = class.base( "Sound" )

local SoundClass = class.create( Sound )
std.Sound = SoundClass

-- TODO: csound
