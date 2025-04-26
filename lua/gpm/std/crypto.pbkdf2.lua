local std = _G.gpm.std

---@class gpm.std.crypto
local crypto = std.crypto

local hmac = crypto.hmac
local hmac_key = hmac.key
local hmac_padding = hmac.padding
local hmac_computeBinary = hmac.computeBinary

local pack_writeUInt32 = crypto.pack.writeUInt32

local string = std.string
local string_toHex = string.toHex
local string_len, string_sub = string.len, string.sub
local string_char, string_byte = string.char, string.byte

local bit_bxor = std.bit.bxor

local table_concat, table_unpack = std.table.concat, std.table.unpack
local math_ceil = std.math.ceil

--- [SHARED AND MENU]
---
--- A pbkdf2 library.
---
---@class gpm.std.crypto.pbkdf2
local pbkdf2 = crypto.pbkdf2 or {}
crypto.pbkdf2 = pbkdf2

--- [SHARED AND MENU]
---
--- Derives a password using the pbkdf2 algorithm.
---
--- See https://en.wikipedia.org/wiki/PBKDF2 for the algorithm.
---
---@param options gpm.std.crypto.pbkdf2.Options
---@return string pbkdf2_hash The derived password as a hex string.
function pbkdf2.derive( options )
    local pbkdf2_iterations = options.iterations or 4096
    local pbkdf2_length = options.length or 16
    local pbkdf2_password = options.password
    local pbkdf2_salt = options.salt

    local hash = options.hash
    if hash == nil then
        std.error( "hash name not specified", 2 )
    end

    ---@cast hash gpm.std.crypto.hashlib

    local digest_length = hash.digest
    local hash_fn = hash.hash

    local hmac_outer, hmac_inner = hmac_padding( hmac_key( pbkdf2_password, hash_fn, hash.block ), hash.block )
    local block_count = math_ceil( pbkdf2_length / digest_length )
    local blocks = {}

    for block = 1, block_count, 1 do
        local u = hmac_computeBinary( hash_fn, hmac_outer, hmac_inner, pbkdf2_salt .. pack_writeUInt32( block, true ) )
        local t = { string_byte( u, 1, digest_length ) }

        for _ = 2, pbkdf2_iterations, 1 do
            u = hmac_computeBinary( hash_fn, hmac_outer, hmac_inner, u )

            for j = 1, digest_length, 1 do
                t[ j ] = bit_bxor( t[ j ], string_byte( u, j ) )
            end
        end

        blocks[ block ] = string_char( table_unpack( t, 1, digest_length ) )
    end

    local pbkdf2_hash = string_toHex( table_concat( blocks, "", 1, block_count ) )

    if string_len( pbkdf2_hash ) ~= pbkdf2_length then
        pbkdf2_hash = string_sub( pbkdf2_hash, 1, pbkdf2_length )
    end

    return pbkdf2_hash
end
