local std = _G.gpm.std
---@class gpm.std.crypto
local crypto = std.crypto
local string = std.string

--- [SHARED AND MENU]
---
--- SHA1 object.
---
---@class gpm.std.crypto.SHA1 : gpm.std.Object
---@field __class gpm.std.crypto.SHA1Class
local SHA1 = std.class.base( "SHA1" )

---@alias SHA1 gpm.std.crypto.SHA1

--- [SHARED AND MENU]
---
--- SHA1 class that computes a cryptographic 160-bit hash value.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
--- **SHA1 is insecure**
---
--- Because of collision attacks,
--- attackers can find two different inputs
--- that produce the same hash.
---
--- This violates one of the basic principles
--- of a secure hash function - collision resistance.
---
---@class gpm.std.crypto.SHA1Class : gpm.std.crypto.SHA1
---@field __base gpm.std.crypto.SHA1
---@field digest_size integer
---@field block_size integer
---@overload fun(): gpm.std.crypto.SHA1
local SHA1Class = std.class.create( SHA1 )
crypto.SHA1 = SHA1Class

SHA1Class.digest_size = 20
SHA1Class.block_size = 64

-- TODO: implement (example: md5)

local engine_SHA1 = gpm.engine.SHA1

if engine_SHA1 == nil then

    -- TODO: implement (example: md5)

else

    local string_fromHex = string.fromHex

    --- [SHARED AND MENU]
    ---
    --- Computes the SHA1 digest of the given input string.
    ---
    --- This static method takes a string and returns its SHA1 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute SHA1 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The SHA1 string of the message.
    function SHA1Class.digest( message, as_hex )
        local hex = engine_SHA1( message )
        if as_hex then
            return hex
        else
            return string_fromHex( hex )
        end
    end

end
