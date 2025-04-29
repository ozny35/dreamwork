local std = _G.gpm.std

local math = std.math
local math_random = math.random

local string = std.string
local string_format = string.format

local bit_band, bit_bor = std.bit.band, std.bit.bor

---@class gpm.std.crypto
local crypto = std.crypto

do

    local string_len = string.len
    local string_byte = string.byte
    local string_gsub = string.gsub
    local string_fromHex = string.fromHex

    do

        local md5_hash = crypto.md5.hash

        --- [SHARED AND MENU]
        ---
        --- Generates a UUID version 3 (name-based, MD5).
        ---
        --- UUID v3 is generated based on a namespace and a name using MD5 hashing.
        ---
        ---@param namespace string The namespace UUID (must be a valid UUID string).
        ---@param name string The name to hash within the namespace.
        ---@return string uuid A UUID v3 string.
        function crypto.UUIDv3( namespace, name )
            local uuid = string_gsub( namespace, "-", "" )
            if string_len( uuid ) ~= 32 then
                std.error( "invalid namespace UUID format", 2 )
            end

            local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16 = string_byte( string_fromHex( md5_hash( string_fromHex( uuid ) .. name ) ), 1, 16 )

            return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                b1, b2, b3, b4, b5, b6, bit_bor( bit_band( b7, 0x0F ), 0x30 ),
                b8, bit_bor( bit_band( b9, 0x3F ), 0x80 ),
                b10, b11, b12, b13, b14, b15, b16
            )
        end

    end

    do

        local sha1_hash = crypto.sha1.hash

        --- [SHARED AND MENU]
        ---
        --- Generates a UUID version 5 (name-based, SHA-1).
        ---
        --- UUID v5 is similar to v3, but uses SHA-1 instead of MD5 for hashing.
        ---
        ---@param namespace string The namespace UUID (must be a valid UUID string).
        ---@param name string The name to hash within the namespace.
        ---@return string uuid A UUID v5 string.
        function crypto.UUIDv5( namespace, name )
            local uuid = string_gsub( namespace, "-", "" )
            if string_len( uuid ) ~= 32 then
                std.error( "invalid namespace UUID format", 2 )
            end

            local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16 = string_byte( string_fromHex( sha1_hash( string_fromHex( uuid ) .. name ) ), 1, 16 )

            return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                b1, b2, b3, b4, b5, b6, bit_bor( bit_band( b7, 0x0F ), 0x50 ),
                b8, bit_bor( bit_band( b9, 0x3F ), 0x80 ),
                b10, b11, b12, b13, b14, b15, b16
            )
        end

    end

end

--- [SHARED AND MENU]
---
--- Generates a UUID version 4 (random).
---
--- UUID v4 is generated using random or pseudo-random numbers.
--- No input is needed; output is a fully random UUID.
---
---@return string uuid A UUID v4 string.
function crypto.UUIDv4()
    return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),

        math_random( 0, 255 ),
        math_random( 0, 255 ),
        bit_bor( bit_band( math_random( 0, 255 ), 0x0F ), 0x40 ),
        math_random( 0, 255 ),

        bit_bor( bit_band( math_random( 0, 255 ), 0x3F ), 0x80 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),

        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 )
    )
end

do

    local BigInt = std.BigInt
    local BigInt_band, BigInt_rshift = BigInt.band, BigInt.rshift
    local BigInt_fromNumber = BigInt.fromNumber
    local game_getUptime = std.game.getUptime
    local math_floor = math.floor
    local os_time = std.os.time

    local bigint_0xFF = BigInt_fromNumber( 0xFF )

    --- [SHARED AND MENU]
    ---
    --- Generates a UUID version 7 (time-ordered).
    ---
    --- UUID v7 is a 128-bit based on a timestamp unique identifier,
    --- like it's older siblings, such as the widely used UUIDv4.
    ---
    --- But unlike v4, UUIDv7 is time-sortable
    --- with 1 ms precision.
    ---
    --- By combining the timestamp and
    --- the random parts, UUIDv7 becomes an
    --- excellent choice for record identifiers
    --- in databases, including distributed ones.
    ---
    ---@param timestamp? gpm.std.BigInt The UNIX-64 timestamp to use.
    ---@return string uuid A UUID v7 string.
    function crypto.UUIDv7( timestamp )
        if timestamp == nil then
            timestamp = BigInt_fromNumber( math_floor( ( os_time() + game_getUptime() % 1 ) * 1000 ) )
        end

        return string_format( "0%s%s%s%s-%s%s-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            BigInt_rshift( timestamp, 40 ):band( bigint_0xFF ):toHex( true ),
            BigInt_rshift( timestamp, 32 ):band( bigint_0xFF ):toHex( true ),
            BigInt_rshift( timestamp, 24 ):band( bigint_0xFF ):toHex( true ),
            BigInt_rshift( timestamp, 16 ):band( bigint_0xFF ):toHex( true ),

            BigInt_rshift( timestamp, 8 ):band( bigint_0xFF ):toHex( true ),
            BigInt_band( timestamp, bigint_0xFF ):toHex( true ),
            bit_bor( bit_band( math_random( 0, 255 ), 0x0F ), 0x70 ),
            math_random( 0, 255 ),

            bit_bor( bit_band( math_random( 0, 255 ), 0x3F ), 0x80 ),
            math_random( 0, 255 ),
            math_random( 0, 255 ),
            math_random( 0, 255 ),

            math_random( 0, 255 ),
            math_random( 0, 255 ),
            math_random( 0, 255 ),
            math_random( 0, 255 )
        )
    end

end
