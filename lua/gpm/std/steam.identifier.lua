local std = _G.gpm.std

local type2int = {
    [ "Invalid" ] = 0,
    [ "Individual" ] = 1,
    [ "Multiseat" ] = 2,
    [ "GameServer" ] = 3,
    [ "AnonGameServer" ] = 4,
    [ "Pending" ] = 5,
    [ "ContentServer" ] = 6,
    [ "Clan" ] = 7,
    [ "Chat" ] = 8,
    [ "ConsoleUser" ] = 9,
    [ "AnonUser" ] = 10
}

---@alias gpm.std.steam.Identifier.Type
---| string # Steam Account Type ( https://developer.valvesoftware.com/wiki/SteamID#Types_of_Steam_Accounts )
---| `"Invalid"`
---| `"Individual"`
---| `"Multiseat"`
---| `"GameServer"`
---| `"AnonGameServer"`
---| `"Pending"`
---| `"ContentServer"`
---| `"Clan"`
---| `"Chat"`
---| `"ConsoleUser"`
---| `"AnonUser"

local universe2int = {
    [ "Invalid" ] = 0,
    [ "Public" ] = 1,
    [ "Beta" ] = 2,
    [ "Internal" ] = 3,
    [ "Dev" ] = 4,
    [ "RC" ] = 5
}

---@alias gpm.std.steam.Identifier.Universe
---| string # Steam Account Universe ( https://developer.valvesoftware.com/wiki/SteamID#Universes_Available_for_Steam_Accounts )
---| `"Invalid"`
---| `"Public"`
---| `"Beta"`
---| `"Internal"`
---| `"Dev"`
---| `"RC"`

local int2letter = {
    [ 0 ] = "I",
    [ 1 ] = "U",
    [ 2 ] = "M",
    [ 3 ] = "G",
    [ 4 ] = "A",
    [ 5 ] = "P",
    [ 6 ] = "C",
    [ 7 ] = "g",
    [ 8 ] = "T",
    [ 9 ] = "i",
    [ 10 ] = "a"
}

local letter2int = {
    I = 0,
    i = 0,
    U = 1,
    M = 2,
    G = 3,
    A = 4,
    P = 5,
    C = 6,
    g = 7,
    T = 8,
    L = 8,
    c = 8,
    a = 10
}

local universes = {
    [ 0 ] = { "450", 3603922337792, 3 },
    [ 1 ] = { "765", 61197960265728, 3 },
    [ 2 ] = { "1486", 18791998193664, 4 },
    [ 3 ] = { "2206", 76386036121600, 4 },
    [ 4 ] = { "2927", 33980074049536, 4 },
    [ 5 ] = { "3647", 91574111977472, 4 }
}

-- full_map[ universe ][ type ] + instance + id
--                                    20     32
--                                        52 bits
--                     64 bits

---@alias Identifier gpm.std.steam.Identifier
---@class gpm.std.steam.Identifier: gpm.std.Object
---@field __class gpm.std.steam.IDClass
---@field universe gpm.std.steam.Identifier.Universe
---@field type gpm.std.steam.Identifier.Type
---@field instance integer
---@field id integer
local Identifier = std.class.base( "Identifier" )

---@class gpm.std.steam.IDClass: gpm.std.steam.Identifier
---@field __base gpm.std.steam.Identifier
---@overload fun( universe?: gpm.std.steam.Identifier.Universe, type?: gpm.std.steam.Identifier.Type, id?: integer, instance?: boolean ): Identifier
local IdentifierClass = std.class.create( Identifier )

---@param universe? gpm.std.steam.Identifier.Universe
---@param type? gpm.std.steam.Identifier.Type
---@param id? integer
---@param instance? boolean
---@protected
function Identifier:__new( id, universe, type, instance )
    return setmetatable( {
        universe = universe2int[ universe or "Public" ],
        type = type2int[ type or "Individual" ],
        instance = instance or 1,
        id = id or 0
    }, Identifier )
end

do

    local int2path = {
        [ 1 ] = "profiles",
        [ 7 ] = "groups"
    }

    function Identifier:getURL( http )
        local path = int2path[ self.type ]
        if path == nil then
            return nil
        end

        return ( http and "http" or "https" ) .. "://steamcommunity.com/" .. path .. "/" .. self:to64()
    end

end

function Identifier:toSteam2()
    local id = self.id
    local y = id % 2
    return string.format( "STEAM_%d:%d:%d", self.universe, y, ( id - y ) * 0.5 )
end

function Identifier:toSteam3()
    return string.format( "[%s:%d:%d]", int2letter[ self.type ], self.universe, self.id )
end

function Identifier:to64()
    local data = universes[ self.universe ]
    return data[ 1 ] .. ( self.id + data[ 2 ] )
end

function IdentifierClass.isValidSteam2( str )
    local x, y, z = string.match( str, "^STEAM_(%d+):(%d+):(%d+)$" )
    if not ( x and y and z ) then return false end

    local universe = tonumber( x, 10 )
    if universe == nil or universe > 255 then -- 2 ^ 8 ( 8 bits )
        return false
    end

    if not ( y == "0" or y == "1" ) then -- 0 or 1 ( 1 bit )
        return false
    end

    local id = tonumber( z, 10 )
    if id == nil or id > 2147483648 then -- 2 ^ 31 ( 31 bits )
        return false
    end

    return true
end

function IdentifierClass.isValidSteam3( str )
    local letter, universe_str, id_str = string.match( str, "^%[(%a):(%d+):(%d+)%]$" )
    if not ( letter and universe_str and id_str ) then return false end
    if letter2int[ letter ] == nil then return false end

    local universe = tonumber( universe_str, 10 )
    if universe == nil or universe > 255 then -- 2 ^ 8 ( 8 bits )
        return false
    end

    local id = tonumber( id_str, 10 )
    if id == nil or id > 4294967296 then -- 2 ^ 32 ( 32 bits )
        return false
    end

    return true
end

function IdentifierClass.isValid64( str )
    for i = 0, 5 do
        local data = universes[ i ]
        if string.sub( str, 1, data[ 3 ] ) == data[ 1 ] then
            local number = tonumber( string.sub( str, data[ 3 ] + 1 ), 10 )
            return number ~= nil and number >= data[ 2 ]
        end
    end

    return false
end

function IdentifierClass.fromSteam2( str, ignore_zero )
    local x, y, z = string.match( str, "^STEAM_([12]?%d?%d):([01]):(%d+)$" )
    if x == nil or y == nil or z == nil then
        std.error( "steam identifier steam2 is invalid", 2 )
    end

    local universe = tonumber( x, 10 )
    if universe == 0 and not ignore_zero then
        universe = 1
    end

    return setmetatable( {
        id = ( tonumber( z, 10 ) * 2 ) + ( y == "1" and 1 or 0 ),
        universe = universe,
        instance = 1,
        type = 1
    }, Identifier )
end

function IdentifierClass.fromSteam3( str )
    local letter, universe, id = string.match( str, "^%[(%a):(%d+):(%d+)%]$" )
    if letter == nil or universe == nil or id == nil then
        std.error( "steam identifier steam3 is invalid", 2 )
    end

    return setmetatable( {
        universe = tonumber( universe, 10 ) or 0,
        type = letter2int[ letter ] or 0,
        id = tonumber( id, 10 ) or 0,
        instance = 1
    }, Identifier )
end

function IdentifierClass.from64( str )
    for i = 0, 5 do
        local data = universes[ i ]
        if string.sub( str, 1, data[ 3 ] ) == data[ 1 ] then
            local number = tonumber( string.sub( str, data[ 3 ] + 1 ), 10 )
            if number then
                return setmetatable( {
                    universe = i,
                    id = number - data[ 2 ],
                    -- TODO: make instance and type getting from str
                    instance = 1,
                    type = 1
                }, Identifier )
            end
        end
    end

    std.error( "steam identifier steam64 is invalid", 2 )
end

-- local obj = IdentifierClass.from64( "76561197960265729" )

-- PrintTable( obj )

-- print( obj:getURL() )

return IdentifierClass
