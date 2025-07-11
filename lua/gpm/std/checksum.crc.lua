local _G = _G
local std = _G.gpm.std
---@class gpm.std.checksum
local checksum = std.checksum

local bit = std.bit
local bit_bxor = bit.bxor
local bit_reverse = bit.reverse
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local string = std.string
local string_len = string.len
local string_byte = string.byte

local setmetatable = std.setmetatable

-- Tests: https://www.texttool.com/crc-online

do

    ---@type table<integer, table<integer, integer>>
    local crc8_lookup = {}

    setmetatable( crc8_lookup, {
        __index = function( self, poly )
            local hash_map = {}

            for uint8 = 0, 255, 1 do
                local crc = uint8

                for _ = 1, 8, 1 do
                    if bit_band( crc, 0x80 ) == 0 then
                        crc = bit_lshift( crc, 1 )
                    else
                        crc = bit_bxor( bit_lshift( crc, 1 ), poly )
                    end
                end

                hash_map[ uint8 ] = bit_band( crc, 0xFF )
            end

            self[ poly ] = hash_map

            return hash_map
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-8 checksum of the specified string.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-8 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-8 checksum.
    ---@param poly? integer The polynomial used to calculate the CRC-8 checksum.
    ---@param init? integer The initial value of the CRC-8 checksum.
    ---@param ref_in? boolean `true` if the input CRC-8 checksum is reversed, otherwise `false`.
    ---@param ref_out? boolean `true` if the output CRC-8 checksum is reversed, otherwise `false`.
    ---@param xor_out? integer The value to be XORed with the output CRC-8 checksum.
    ---@return integer checksum The CRC-8 checksum, which is greater or equal to 0, and less than 2^8 (0x100).
    local function crypto_crc8( raw_str, poly, init, ref_in, ref_out, xor_out )
        ref_in = ref_in == true
        ref_out = ref_out == true

        local crc

        if init == nil then
            crc = 0x00
        else
            crc = init % 0x100
        end

        local hash_map

        if poly == nil then
            hash_map = crc8_lookup[ 0x07 ]
        else
            hash_map = crc8_lookup[ poly % 0x100 ]
        end

        for index = 1, string_len( raw_str ), 1 do
            if ref_in then
                crc = hash_map[ bit_bxor( crc, bit_reverse( string_byte( raw_str, index, index ), 8 ) ) ]
            else
                crc = hash_map[ bit_bxor( crc, string_byte( raw_str, index, index ) ) ]
            end
        end

        if ref_out then
            crc = bit_reverse( crc, 8 )
        end

        if xor_out ~= nil then
            crc = bit_bxor( crc, xor_out % 0x100 )
        end

        return bit_band( crc, 0xFF )
    end

    checksum.crc8 = crypto_crc8

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-8 checksum of the specified string using the Maxim algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-8 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-8 checksum.
    ---@return integer checksum The CRC-8 checksum, which is greater or equal to 0, and less than 2^8 (0x100).
    function checksum.crc8maxim( raw_str )
        return crypto_crc8( raw_str, 0x31, 0x00, true, true )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-8 checksum of the specified string using the ROHC algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-8 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-8 checksum.
    ---@return integer checksum The CRC-8 checksum, which is greater or equal to 0, and less than 2^8 (0x100).
    function checksum.crc8rohc( raw_str )
        return crypto_crc8( raw_str, 0x07, 0xFF, true, true )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-8 checksum of the specified string using the CDMA2000 algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-8 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-8 checksum.
    ---@return integer checksum The CRC-8 checksum, which is greater or equal to 0, and less than 2^8 (0x100).
    function checksum.crc8cdma2000( raw_str )
        return crypto_crc8( raw_str, 0x9B, 0xFF, false, false )
    end

end

do

    ---@type table<integer, table<integer, integer>>
    local crc16_lookup = {}

    setmetatable( crc16_lookup, {
        __index = function( self, uint17 )
            local ref_out = bit_band( uint17, 0x20000 ) ~= 0
            local ref_in = bit_band( uint17, 0x10000 ) ~= 0
            local poly = bit_band( uint17, 0xFFFF )

            local hash_map = {}

            for uint8 = 0, 255, 1 do
                local crc

                if ref_in then
                    crc = bit_reverse( uint8, 8 )
                else
                    crc = uint8
                end

                crc = bit_lshift( crc, 8 )

                for _ = 1, 8, 1 do
                    if bit_band( crc, 0x8000 ) == 0 then
                        crc = bit_lshift( crc, 1 )
                    else
                        crc = bit_bxor( bit_lshift( crc, 1 ), poly )
                    end
                end

                crc = bit_band( crc, 0xFFFF )

                if ref_out then
                    crc = bit_reverse( crc, 16 )
                end

                hash_map[ uint8 ] = crc
            end

            self[ uint17 ] = hash_map

            return hash_map
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-16 checksum of the specified string.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-16 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-16 checksum.
    ---@param poly? integer The polynomial used to calculate the CRC-16 checksum.
    ---@param init? integer The initial value used to calculate the CRC-16 checksum.
    ---@param ref_in? boolean Whether to reflect the input data before processing.
    ---@param ref_out? boolean Whether to reflect the output data after processing.
    ---@param xor_out? integer The XOR value used to calculate the CRC-16 checksum.
    ---@return integer checksum The CRC-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
    local function crypto_crc16( raw_str, poly, init, ref_in, ref_out, xor_out )
        ref_in = ref_in ~= false
        ref_out = ref_out ~= false

        local crc

        if init == nil then
            crc = 0x0000
        else
            crc = init % 0x10000
        end

        local hash_key

        if poly == nil then
            hash_key = 0x8005
        else
            hash_key = poly % 0x10000
        end

        if ref_in then
            hash_key = bit_bor( hash_key, 0x10000 )
        end

        if ref_out then
            hash_key = bit_bor( hash_key, 0x20000 )
        end

        local hash_map = crc16_lookup[ hash_key ]

        for index = 1, string_len( raw_str ), 1 do
            if ref_in then
                crc = bit_bxor( bit_rshift( crc, 8 ), hash_map[ bit_band( bit_bxor( crc, string_byte( raw_str, index, index ) ), 0xFF ) ] )
            else
                crc = bit_bxor( bit_lshift( crc, 8 ), hash_map[ bit_band( bit_bxor( bit_rshift( crc, 8 ), string_byte( raw_str, index, index ) ), 0xFF ) ] )
            end
        end

        if xor_out ~= nil then
            crc = bit_bxor( crc, xor_out )
        end

        return bit_band( crc, 0xFFFF )
    end

    checksum.crc16 = crypto_crc16

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-16 checksum of the specified string using the Maxim algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-16 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-16 checksum.
    ---@return integer checksum The CRC-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
    function checksum.crc16maxim( raw_str )
        return crypto_crc16( raw_str, 0x8005, 0x0000, true, true )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-16 checksum of the specified string using the XModem algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-16 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-16 checksum.
    ---@return integer checksum The CRC-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
    function checksum.crc16xmodem( raw_str )
        return crypto_crc16( raw_str, 0x1021, 0x0000, false, false )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-16 checksum of the specified string using the USB algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-16 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-16 checksum.
    ---@return integer checksum The CRC-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
    function checksum.crc16usb( raw_str )
        return crypto_crc16( raw_str, 0x8005, 0xFFFF, true, true, 0xFFFF )
    end

end

do

    local raw_tonumber = std.raw.tonumber
    local crc32 = ( _G.util or {} ).CRC

    ---@type table<integer, table<integer, integer>>
    local crc32_lookup = {}

    setmetatable( crc32_lookup, {
        __index = function( self, poly )
            local hash_map = {}

            for uint8 = 0, 255, 1 do
                local crc = bit_lshift( uint8, 24 )

                for _ = 1, 8, 1 do
                    if bit_band( crc, 0x80000000 ) == 0 then
                        crc = bit_lshift( crc, 1 )
                    else
                        crc = bit_bxor( bit_lshift( crc, 1 ), poly )
                    end
                end

                hash_map[ uint8 ] = crc % 0x100000000
            end

            self[ poly ] = hash_map

            return hash_map
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@param poly? integer The polynomial used to calculate the CRC-32 checksum.
    ---@param init? integer The initial value used to calculate the CRC-32 checksum.
    ---@param ref_in? boolean Whether to reflect the input data before processing.
    ---@param ref_out? boolean Whether to reflect the output data after processing.
    ---@param xor_out? integer The XOR value used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    local function crypto_crc32( raw_str, poly, init, ref_in, ref_out, xor_out )
        ref_in = ref_in ~= false
        ref_out = ref_out ~= false

        if init == nil then
            init = 0xFFFFFFFF
        else
            init = init % 0x100000000
        end

        if poly == nil then
            poly = 0x04C11DB7
        else
            poly = poly % 0x100000000
        end

        if xor_out == nil then
            xor_out = 0xFFFFFFFF
        else
            xor_out = xor_out % 0x100000000
        end

        if poly == 0x04C11DB7 and init == 0xFFFFFFFF and ref_in and ref_out and xor_out == 0xFFFFFFFF then
            return raw_tonumber( crc32( raw_str ) or 0, 10 ) or 0
        end

        local hash_map = crc32_lookup[ poly ]
        local crc = init

        for index = 1, string_len( raw_str ), 1 do
            if ref_in then
                crc = bit_bxor( bit_lshift( crc, 8 ), hash_map[ bit_band( bit_bxor( bit_band( bit_rshift( crc, 24 ), 0xFF ), bit_reverse( string_byte( raw_str, index, index ), 8 ) ), 0xFF ) ] )
            else
                crc = bit_bxor( bit_lshift( crc, 8 ), hash_map[ bit_band( bit_bxor( bit_band( bit_rshift( crc, 24 ), 0xFF ), string_byte( raw_str, index, index ) ), 0xFF ) ] )
            end
        end

        if ref_out then
            crc = bit_reverse( crc, 32 )
        end

        return bit_bxor( crc, xor_out ) % 0x100000000
    end

    checksum.crc32 = crypto_crc32

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the BZip2 algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32bzip2( raw_str )
        return crypto_crc32( raw_str, 0x04C11DB7, 0xFFFFFFFF, false, false, 0xFFFFFFFF )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the Castagnoli algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32c( raw_str )
        return crypto_crc32( raw_str, 0x1EDC6F41, 0xFFFFFFFF, true, true, 0xFFFFFFFF )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the D algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32d( raw_str )
        return crypto_crc32( raw_str, 0xA833982B, 0xFFFFFFFF, true, true, 0xFFFFFFFF )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the JamCRC algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32jamcrc( raw_str )
        return crypto_crc32( raw_str, 0x04C11DB7, 0xFFFFFFFF, true, true, 0x00000000 )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the MPEG-2 algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32mpeg2( raw_str )
        return crypto_crc32( raw_str, 0x04C11DB7, 0xFFFFFFFF, false, false, 0x00000000 )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the POSIX algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32posix( raw_str )
        return crypto_crc32( raw_str, 0x04C11DB7, 0x00000000, false, false, 0xFFFFFFFF )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the Q algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32q( raw_str )
        return crypto_crc32( raw_str, 0x814141AB, 0x00000000, false, false, 0x00000000 )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the CRC-32 checksum of the specified string using the XFER algorithm.
    ---
    --- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
    ---
    ---@param raw_str string The string used to calculate the CRC-32 checksum.
    ---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function checksum.crc32xfer( raw_str )
        return crypto_crc32( raw_str, 0x000000AF, 0x00000000, false, false, 0x00000000 )
    end

end
