local std = _G.gpm.std
local tonumber = std.tonumber
local setmetatable = std.setmetatable

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

---@alias gpm.std.steam.Identifier.Universe
---| string # Steam Account Universe ( https://developer.valvesoftware.com/wiki/SteamID#Universes_Available_for_Steam_Accounts )
---| `"Invalid"`
---| `"Public"`
---| `"Beta"`
---| `"Internal"`
---| `"Dev"`
---| `"RC"`

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

local universe2int = {
    [ "Invalid" ] = 0,
    [ "Public" ] = 1,
    [ "Beta" ] = 2,
    [ "Internal" ] = 3,
    [ "Dev" ] = 4,
    [ "RC" ] = 5
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

---@class gpm.std.steam.Identifier: gpm.std.Object
---@field __class gpm.std.steam.IDClass
---@field universe gpm.std.steam.Identifier.Universe
---@field type gpm.std.steam.Identifier.Type
---@field instance integer
---@field id integer
local Identifier = std.class.base( "Identifier" )

---@class gpm.std.steam.IDClass: gpm.std.steam.Identifier
---@field __base gpm.std.steam.Identifier
---@overload fun( universe?: gpm.std.steam.Identifier.Universe, type?: gpm.std.steam.Identifier.Type, id?: integer, instance?: boolean ): gpm.std.steam.Identifier
local IdentifierClass = std.class.create( Identifier )

do

    local int2universe = std.table.flip( universe2int )
    local int2type = std.table.flip( type2int )
    local rawget = std.rawget

    ---@protected
    function Identifier:__index( key )
        if key == "universe" then
            return int2universe[ self[ 1 ] ]
        elseif key == "type" then
            return int2type[ self[ 2 ] ]
        elseif key == "instance" then
            return self[ 3 ]
        elseif key == "id" then
            return self[ 4 ]
        else
            return rawget( self, key ) or rawget( Identifier, key )
        end
    end

    ---@protected
    function Identifier:__newindex( key, value )
        if key == "universe" then
            self[ 1 ] = universe2int[ value ]
        elseif key == "type" then
            self[ 2 ] = type2int[ value ]
        elseif key == "instance" then
            self[ 3 ] = value
        elseif key == "id" then
            self[ 4 ] = value
        end
    end

end

---@param universe? gpm.std.steam.Identifier.Universe
---@param type? gpm.std.steam.Identifier.Type
---@param id? integer
---@param instance? boolean
---@protected
function Identifier:__new( id, universe, type, instance )
    return setmetatable( {
        universe2int[ universe or "Public" ],
        type2int[ type or "Individual" ],
        instance or 1,
        id or 0
    }, Identifier )
end

do

    local string_format = std.string.format

    --- [SHARED AND MENU]
    --- Converts a SteamID object to a Steam2 identifier.
    ---@param ignore_universe? boolean
    ---@return string
    function Identifier:toSteam2( ignore_universe )
        local id = self[ 4 ]
        local y = id % 2
        return string_format( "STEAM_%d:%d:%d", ignore_universe and 0 or self[ 1 ], y, ( id - y ) * 0.5 )
    end

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

    --- [SHARED AND MENU]
    --- Converts a SteamID object to a Steam3 identifier.
    ---@return string
    function Identifier:toSteam3()
        return string_format( "[%s:%d:%d]", int2letter[ self[ 2 ] ], self[ 1 ], self[ 4 ] )
    end

end

do

    local BigInt = std.BigInt
    local bit = BigInt.bit

    do

        local x64_zero = BigInt.fromBytes( 1, 0, 0, 0, 0, 0, 0, 0, 0 )
        local bit_bor, bit_lshift = bit.bor, bit.lshift
        local BigInt_fromNumber = BigInt.fromNumber

        --- [SHARED AND MENU]
        --- Converts a SteamID object to a 64-bit integer.
        ---@param object gpm.std.steam.Identifier
        ---@return string
        local function to64( object )
            return bit_bor(
                x64_zero,
                bit_lshift( BigInt_fromNumber( object[ 1 ] ), 56 ),
                bit_lshift( BigInt_fromNumber( object[ 2 ] ), 52 ),
                bit_lshift( BigInt_fromNumber( object[ 3 ] ), 32 ),
                BigInt_fromNumber( object[ 4 ] )
            ):toString( 10, true )
        end

        Identifier.to64 = to64

        do

            local int2path = {
                [ 1 ] = "profiles",
                [ 7 ] = "groups"
            }

            --- [SHARED AND MENU]
            --- Gets the URL for a SteamID object.
            ---@param http? boolean
            ---@return string?
            function Identifier:getURL( http )
                local path = int2path[ self[ 2 ] ]
                if path == nil then
                    return nil
                end

                return ( http and "http" or "https" ) .. "://steamcommunity.com/" .. path .. "/" .. to64( self )
            end

        end

    end

    do

        local bit_band, bit_rshift = bit.band, bit.rshift
        local BigInt_fromString = BigInt.fromString
        local BitInt_toInteger = BigInt.toInteger

        --- [SHARED AND MENU]
        --- Checks if a string is a valid 64-bit identifier.
        ---@param str string
        ---@return boolean
        function IdentifierClass.isValid64( str )
            return #BigInt_fromString( str, 10 ) == 8
        end

        --- [SHARED AND MENU]
        --- Creates a new SteamID object from a 64-bit number string.
        ---@param str string
        ---@return gpm.std.steam.Identifier
        function IdentifierClass.from64( str )
            local number = BigInt_fromString( str, 10 )

            return setmetatable( {
                BitInt_toInteger( bit_band( bit_rshift( number, 56 ), 0xFF ) ),
                BitInt_toInteger( bit_band( bit_rshift( number, 52 ), 0xF ) ),
                BitInt_toInteger( bit_band( bit_rshift( number, 32 ), 0xFFFFF ) ),
                BitInt_toInteger( bit_band( number, 0xFFFFFFFF ) )
            }, Identifier )
        end

    end

end

do

    local string_match = string.match

    --- [SHARED AND MENU]
    --- Checks if a string is a valid Steam2 identifier.
    ---@param str string
    ---@return boolean
    function IdentifierClass.isValidSteam2( str )
        local x, y, z = string_match( str, "^STEAM_(%d+):(%d+):(%d+)$" )
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

    --- [SHARED AND MENU]
    --- Checks if a string is a valid Steam3 identifier.
    ---@param str string
    ---@return boolean
    function IdentifierClass.isValidSteam3( str )
        local letter, universe_str, id_str = string_match( str, "^%[(%a):(%d+):(%d+)%]$" )
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

    --- [SHARED AND MENU]
    --- Creates a new SteamID object from a steam2 string.
    ---@param str string
    ---@return gpm.std.steam.Identifier
    function IdentifierClass.fromSteam2( str, allow_zero_universe )
        local x, y, z = string_match( str, "^STEAM_([12]?%d?%d):([01]):(%d+)$" )
        if x == nil or y == nil or z == nil then
            std.error( "steam identifier steam2 is invalid", 2 )
        end

        local universe = tonumber( x, 10 )
        if universe == 0 and not allow_zero_universe then
            universe = 1
        end

        return setmetatable( { universe, 1, 1, ( tonumber( z, 10 ) * 2 ) + ( y == "1" and 1 or 0 ) }, Identifier )
    end

    --- [SHARED AND MENU]
    --- Creates a new SteamID object from a steam3 string.
    ---@param str string
    ---@return gpm.std.steam.Identifier
    function IdentifierClass.fromSteam3( str )
        local letter, universe, id = string_match( str, "^%[(%a):(%d+):(%d+)%]$" )
        if letter == nil or universe == nil or id == nil then
            std.error( "steam identifier steam3 is invalid", 2 )
        end

        return setmetatable( {
            tonumber( universe, 10 ) or 0,
            letter2int[ letter ] or 0,
            1,
            tonumber( id, 10 ) or 0
        }, Identifier )
    end

end

return IdentifierClass
