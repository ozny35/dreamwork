local std = _G.gpm.std
local string = std.string

---@class gpm.std.crypto
local crypto = std.crypto

--- [SHARED AND MENU]
---
--- A hmac library.
---
---@class gpm.std.crypto.hmac
local hmac = crypto.hmac or {}
crypto.hmac = hmac

local key_normalize
do

    local string_len = string.len
    local string_rep = string.rep

    --- [SHARED AND MENU]
    ---
    --- Normalizes the key to the block size of the hash function.
    ---
    ---@param key string The key to normalize.
    ---@param hash_fn function The hash function to use.
    ---@param block_size integer The block size of the hash function.
    ---@return string key The normalized key.
    function key_normalize( key, hash_fn, block_size )
        local key_length = string_len( key )
        if key_length > block_size then
            return hash_fn( key )
        elseif key_length < block_size then
            return key .. string_rep( "\0", block_size - key_length )
        else
            return key
        end
    end

    hmac.key = key_normalize

end

local key_padding
do

    local string_byte, string_char = string.byte, string.char
    local table_unpack = std.table.unpack
    local bit_bxor = std.bit.bxor

    --- [SHARED AND MENU]
    ---
    --- Computes the key padding.
    ---
    --- This function will NOT check
    --- if the padding's entered into
    --- it is correct.
    ---
    --- See https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation for the algorithm.
    ---
    ---@param key string The normalized by given block size key.
    ---@param block_size integer The block size of the hash function.
    ---@param outer? string The known outer padding.
    ---@param inner? string The known inner padding.
    ---@return string outer The outer padding.
    ---@return string inner The inner padding.
    function key_padding( key, block_size, outer, inner )
        if outer == nil and inner == nil then
            local outer_tbl, inner_tbl = {}, {}

            for i = 1, block_size, 1 do
                local byte = string_byte( key, i )
                outer_tbl[ i ] = bit_bxor( byte, 0x5c )
                inner_tbl[ i ] = bit_bxor( byte, 0x36 )
            end

            return string_char( table_unpack( outer_tbl, 1, block_size ) ), string_char( table_unpack( inner_tbl, 1, block_size ) )
        elseif outer == nil then
            ---@cast inner string
            local outer_tbl = {}

            for i = 1, block_size, 1 do
                outer_tbl[ i ] = bit_bxor( string_byte( key, i ), 0x5c )
            end

            return string_char( table_unpack( outer_tbl, 1, block_size ) ), inner
        elseif inner == nil then
            ---@cast outer string
            local inner_tbl = {}

            for i = 1, block_size, 1 do
                inner_tbl[ i ] = bit_bxor( string_byte( key, i ), 0x36 )
            end

            return outer, string_char( table_unpack( inner_tbl, 1, block_size ) )
        else
            ---@cast inner string
            ---@cast outer string
            return outer, inner
        end
    end

    hmac.padding = key_padding

end

--- [SHARED AND MENU]
---
--- Computes a hmac using the given hash function, outer and inner padding.
---
---@param hash_fn function The hash function to use.
---@param str string The string to compute hmac for.
---@param outer string The outer padding.
---@param inner string The inner padding.
---@return string hash The hmac of the string.
local function compute( hash_fn, str, outer, inner )
    return hash_fn( outer .. hash_fn( inner .. str ) )
end

hmac.compute = compute

--- [SHARED AND MENU]
---
--- Computes a hmac.
---
---@param msg string The message to compute hmac for.
---@param key string The key to use.
---@param hash_fn function The hash function to use.
---@param block_size integer The block size of the hash function.
---@param outer? string The outer padding.
---@param inner? string The inner padding.
---@return string hash The hmac of the message.
local function hash( msg, key, hash_fn, block_size, outer, inner )
    return compute( hash_fn, msg, key_padding( key_normalize( key, hash_fn, block_size ), block_size, outer, inner ) )
end

hmac.hash = hash

-- sha1
do

    local sha1 = crypto.sha1

    local block_size = sha1.block
    local hash_fn = sha1.hash

    --- [SHARED AND MENU]
    ---
    --- Computes a hmac using the sha1 hash function.
    ---
    ---@param msg string The message to compute hmac for.
    ---@param key string The key to use.
    ---@return string sha1_hmac The hmac of the message.
    function hmac.sha1( msg, key )
        return hash( msg, key, hash_fn, block_size )
    end

end

-- sha256
do

    local sha256 = crypto.sha256

    local block_size = sha256.block
    local hash_fn = sha256.hash

    --- [SHARED AND MENU]
    ---
    --- Computes a hmac using the sha256 hash function.
    ---
    ---@param msg string The message to compute hmac for.
    ---@param key string The key to use.
    ---@return string sha256_hmac The hmac of the message.
    function hmac.sha256( msg, key )
        return hash( msg, key, hash_fn, block_size )
    end

end

-- md5
do

    local md5 = crypto.md5

    local block_size = md5.block
    local hash_fn = md5.hash

    --- [SHARED AND MENU]
    ---
    --- Computes a hmac using the md5 hash function.
    ---
    ---@param msg string The message to compute hmac for.
    ---@param key string The key to use.
    ---@return string md5_hmac The hmac of the message.
    function hmac.md5( msg, key )
        return hash( msg, key, hash_fn, block_size )
    end

end
