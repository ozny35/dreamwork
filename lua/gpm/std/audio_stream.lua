---@class gpm.std
local std = _G.gpm.std


--- [SHARED AND MENU]
---
--- The audio stream object.
---
---@class gpm.std.AudioStream : gpm.std.Object
---@field __class gpm.std.AudioStreamClass
local AudioStream = std.class.base( "AudioStream" )

---@class gpm.std.AudioStreamClass : gpm.std.AudioStream
---@field __base gpm.std.AudioStream
---@overload fun(): gpm.std.AudioStream
local AudioStreamClass = std.class.create( AudioStream )
std.AudioStream = AudioStreamClass

do

    local function fromURL( self, url )

    end

    local function fromFile( self, path )

    end

    ---@protected
    function AudioStream:__init( location )
        if std.isurl( location ) then
            fromURL( self, location )
        else
            fromFile( self, location )
        end
    end

end

-- TODO: https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_cl/bass.lua
