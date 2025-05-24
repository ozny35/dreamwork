local std = _G.gpm.std
local tonumber = std.tonumber
local setmetatable = std.setmetatable

---@class gpm.std.steam
local steam = std.steam or {}
std.steam = steam

--- [SHARED AND MENU]
---
--- [Steam Account Type](https://developer.valvesoftware.com/wiki/SteamID#Types_of_Steam_Accounts)
---
---@alias gpm.std.steam.Identifier.type
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

--- [SHARED AND MENU]
---
--- [Steam Account Universe](https://developer.valvesoftware.com/wiki/SteamID#Universes_Available_for_Steam_Accounts)
---
---@alias gpm.std.steam.Identifier.universe
---| `"Invalid"`
---| `"Public"`
---| `"Beta"`
---| `"Internal"`
---| `"Dev"`
---| `"RC"`

---@type table<gpm.std.steam.Identifier.type, integer>
local type2int = {
    Invalid = 0,
    Individual = 1,
    Multiseat = 2,
    GameServer = 3,
    AnonGameServer = 4,
    Pending = 5,
    ContentServer = 6,
    Clan = 7,
    Chat = 8,
    ConsoleUser = 9,
    AnonUser = 10
}

---@type table<gpm.std.steam.Identifier.universe, integer>
local universe2int = {
    Invalid = 0,
    Public = 1,
    Beta = 2,
    Internal = 3,
    Dev = 4,
    RC = 5
}

---@type table<string, integer>
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

---@type table<integer, gpm.std.steam.Identifier.universe>
local int2universe = std.table.flipped( universe2int )

---@type table<integer, gpm.std.steam.Identifier.type>
local int2type = std.table.flipped( type2int )

--- [SHARED AND MENU]
---
--- The Steam ID object.
---
---@class gpm.std.steam.Identifier : gpm.std.Object
---@field __class gpm.std.steam.IdentifierClass
---@field universe gpm.std.steam.Identifier.universe Indicates the Steam environment (e.g., public, beta).
---@field type gpm.std.steam.Identifier.type Specifies the entity type (e.g., individual user, group, game server).
---@field instance integer Differentiates between multiple instances of the same type within a universe. For individual user accounts, this is typically set to 1, representing the desktop instance.
---@field id integer The unique account number.
---@operator add( integer ): gpm.std.steam.Identifier
---@operator sub( integer ): gpm.std.steam.Identifier
local Identifier = std.class.base( "Identifier" )

--- [SHARED AND MENU]
---
--- The Steam ID class.
---
---@class gpm.std.steam.IdentifierClass : gpm.std.steam.Identifier
---@field __base gpm.std.steam.Identifier
---@overload fun( universe?: gpm.std.steam.Identifier.universe, type?: gpm.std.steam.Identifier.type, id?: integer, instance?: boolean ): gpm.std.steam.Identifier
local IdentifierClass = std.class.create( Identifier )
steam.Identifier = IdentifierClass

---@protected
function Identifier:__add( int32 )
    return setmetatable( {
        universe = self.universe,
        type = self.type,
        instance = self.instance,
        id = self.id + int32
    }, Identifier )
end

---@protected
function Identifier:__sub( int32 )
    return setmetatable( {
        universe = self.universe,
        type = self.type,
        instance = self.instance,
        id = self.id - int32
    }, Identifier )
end

---@protected
function Identifier:__new( id, universe, type, instance )
    return setmetatable( {
        universe = universe or "Public",
        type = type or "Individual",
        instance = instance or 1,
        id = id or 0
    }, Identifier )
end

do

    local string_format = std.string.format

    --- [SHARED AND MENU]
    ---
    --- Converts a SteamID object to a Steam2 identifier.
    ---
    ---@param ignore_universe? boolean
    ---@return string
    function Identifier:toSteam2( ignore_universe )
        local id = self.id
        local y = id % 2
        return string_format( "STEAM_%d:%d:%d", ignore_universe and 0 or ( universe2int[ self.universe ] or 1 ), y, ( id - y ) * 0.5 )
    end

    ---@type table<gpm.std.steam.Identifier.type, string>
    local type2letter = {
        Invalid = "I",
        Individual = "U",
        Multiseat = "M",
        GameServer = "G",
        AnonGameServer = "A",
        Pending = "P",
        ContentServer = "C",
        Clan = "g",
        Chat = "T",
        ConsoleUser = "i",
        AnonUser = "a"
    }

    --- [SHARED AND MENU]
    ---
    --- Converts a SteamID object to a Steam3 identifier.
    ---
    ---@return string
    function Identifier:toSteam3()
        return string_format( "[%s:%d:%d]", type2letter[ self.type ] or "I", universe2int[ self.universe ] or 0, self.id )
    end

    ---@protected
    function Identifier:__tostring()
        return string_format( "Steam Identifier: %p %s", self, self:toSteam3() )
    end

end

do

    local BigInt = std.BigInt

    do

        local x64_zero = BigInt.fromBytes( { 0, 0, 0, 0, 0, 0, 0, 0 }, 8, false, false )
        local BigInt_bor, BigInt_lshift = BigInt.bor, BigInt.lshift
        local BigInt_fromNumber = BigInt.fromNumber

        --- [SHARED AND MENU]
        ---
        --- Converts a SteamID object to a 64-bit integer.
        ---
        ---@param object gpm.std.steam.Identifier
        ---@return string
        local function to64( object )
            return BigInt_bor(
                x64_zero,
                BigInt_lshift( BigInt_fromNumber( universe2int[ object.universe ] or 0 ), 56 ),
                BigInt_lshift( BigInt_fromNumber( type2int[ object.type ] or 0 ), 52 ),
                BigInt_lshift( BigInt_fromNumber( object.instance ), 32 ),
                BigInt_fromNumber( object.id )
            ):toString( 10, true )
        end

        Identifier.to64 = to64

        do

            local int2path = {
                [ 1 ] = "profiles",
                [ 7 ] = "groups"
            }

            --- [SHARED AND MENU]
            ---
            --- Gets the URL for a SteamID object.
            ---
            ---@param http? boolean
            ---@return string?
            function Identifier:getURL( http )
                local path = int2path[ self.type ]
                if path == nil then
                    return nil
                else
                    return ( http and "http" or "https" ) .. "://steamcommunity.com/" .. path .. "/" .. to64( self )
                end
            end

        end

    end

    do

        local BigInt_band, BigInt_rshift = BigInt.band, BigInt.rshift
        local BigInt_fromString = BigInt.fromString
        local BitInt_toInteger = BigInt.toInteger

        --- [SHARED AND MENU]
        ---
        --- Checks if a string is a valid 64-bit identifier.
        ---
        ---@param str string
        ---@return boolean
        function IdentifierClass.isValid64( str )
            return #BigInt_fromString( str, 10 ) == 8
        end

        --- [SHARED AND MENU]
        ---
        --- Creates a new SteamID object from a 64-bit number string.
        ---
        ---@param str string
        ---@return gpm.std.steam.Identifier
        function IdentifierClass.from64( str )
            local number = BigInt_fromString( str, 10 )

            return setmetatable( {
                universe = int2universe[ BitInt_toInteger( BigInt_band( BigInt_rshift( number, 56 ), 0xFF ) ) ] or "Invalid",
                type = int2type[ BitInt_toInteger( BigInt_band( BigInt_rshift( number, 52 ), 0xF ) ) ] or "Invalid",
                instance = BitInt_toInteger( BigInt_band( BigInt_rshift( number, 32 ), 0xFFFFF ) ),
                id = BitInt_toInteger( BigInt_band( number, 0xFFFFFFFF ) )
            }, Identifier )
        end

    end

end

do

    local string_match = string.match

    --- [SHARED AND MENU]
    ---
    --- Checks if a string is a valid Steam2 identifier.
    ---
    ---@param str string
    ---@return boolean
    function IdentifierClass.isValidSteam2( str )
        local x, y, z = string_match( str, "^STEAM_(%d+):(%d+):(%d+)$" )
        if not ( x and y and z ) then
            return false
        end

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
    ---
    --- Checks if a string is a valid Steam3 identifier.
    ---
    ---@param str string
    ---@return boolean
    function IdentifierClass.isValidSteam3( str )
        local letter, universe_str, id_str = string_match( str, "^%[(%a):(%d+):(%d+)%]$" )
        if not ( letter and universe_str and id_str ) or letter2int[ letter ] == nil then
            return false
        end

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
    ---
    --- Creates a new SteamID object from a steam2 string.
    ---
    ---@param str string
    ---@return gpm.std.steam.Identifier
    function IdentifierClass.fromSteam2( str, allow_zero_universe )
        local x, y, z = string_match( str, "^STEAM_([12]?%d?%d):([01]):(%d+)$" )
        if x == nil or y == nil or z == nil then
            error( "steam identifier steam2 is invalid", 2 )
        end

        local universe = tonumber( x, 10 )
        if universe == 0 and not allow_zero_universe then
            universe = 1
        end

        return setmetatable( {
            universe = int2universe[ universe ] or "Invalid",
            type = "Individual",
            instance = 1,
            id = ( tonumber( z, 10 ) * 2 ) + ( y == "1" and 1 or 0 )
        }, Identifier )
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a new SteamID object from a steam3 string.
    ---
    ---@param str string
    ---@return gpm.std.steam.Identifier
    function IdentifierClass.fromSteam3( str )
        local letter, universe, id = string_match( str, "^%[?(%a):(%d+):(%d+)%]?$" )
        if letter == nil or universe == nil or id == nil then
            error( "steam identifier steam3 is invalid", 2 )
        end

        return setmetatable( {
            universe = int2universe[ tonumber( universe, 10 ) or 0 ] or "Invalid",
            type = int2type[ letter2int[ letter ] or 0 ] or "Invalid",
            instance = 1,
            id = tonumber( id, 10 ) or 0
        }, Identifier )
    end

end
