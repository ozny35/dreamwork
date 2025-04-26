local std = _G.gpm.std
local string = std.string

local string_byte, string_char = string.byte, string.char
local string_sub, string_rep = string.sub, string.rep
local string_len = string.len

---@class gpm.std.crypto
local crypto = std.crypto
local bytepack = crypto.bytepack

--- [SHARED AND MENU]
---
--- The binary pack/unpack library.
---
---@class gpm.std.crypto.pack
local pack = {}
crypto.pack = pack

do

	local bytepack_readUInt = bytepack.readUInt


	--- [SHARED AND MENU]
	---
	--- Reads unsigned integer from binary string.
	---
	--- Valid values without loss of precision: `0` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param str string The binary string.
	---@param byte_count? integer The number of bytes to read. Default: `4`.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned integer.
	function pack.readUInt( str, byte_count, big_endian, start_position )
		if byte_count == nil then
			byte_count = 4
		end

		if start_position == nil then
			start_position = 1
		end

		if byte_count == 0 or str == "" then
			return 0
		elseif byte_count == 1 then
			return string_byte( str, start_position )
		elseif byte_count == 2 then
			local b1, b2 = string_byte( str, start_position, start_position + 1 )

			if b2 == nil then
				std.error( "insufficient data length", 2 )
			end

			if not big_endian then
				b1, b2 = b2, b1
			end

			return bytepack_readUInt( b1, b2 )
		elseif byte_count == 3 then
			local b1, b2, b3 = string_byte( str, start_position, start_position + 2 )

			if b3 == nil then
				std.error( "insufficient data length", 2 )
			end

			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return bytepack_readUInt( b1, b2, b3 )
		elseif byte_count == 4 then
			local b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )

			if b4 == nil then
				std.error( "insufficient data length", 2 )
			end

			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return bytepack_readUInt( b1, b2, b3, b4 )
		elseif byte_count == 5 then
			local b1, b2, b3, b4, b5 = string_byte( str, start_position, start_position + 4 )

			if b5 == nil then
				std.error( "insufficient data length", 2 )
			end

			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return bytepack_readUInt( b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			local b1, b2, b3, b4, b5, b6 = string_byte( str, start_position, start_position + 5 )

			if b6 == nil then
				std.error( "insufficient data length", 2 )
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUInt( b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			local b1, b2, b3, b4, b5, b6, b7 = string_byte( str, start_position, start_position + 6 )

			if b7 == nil then
				std.error( "insufficient data length", 2 )
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUInt( b1, b2, b3, b4, b5, b6, b7 )
		elseif byte_count == 8 then
			local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )

			if b8 == nil then
				std.error( "insufficient data length", 2 )
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUInt( b1, b2, b3, b4, b5, b6, b7, b8 )
		else
			std.error( "unsupported byte count", 2 )
			return 0
		end
	end

end

do

	local bytepack_writeUInt = bytepack.writeUInt

	--- [SHARED AND MENU]
	---
	--- Writes unsigned integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param value integer The unsigned integer.
	---@param byte_count? integer The number of bytes to write. Defaults to `4`.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Defaults to `false`.
	---@return string str The binary string representation of the unsigned integer.
	function pack.writeUInt( value, byte_count, big_endian )
		if byte_count == nil then
			byte_count = 4
		end

		if byte_count == 0 then
			return ""
		elseif byte_count == 1 then
			return string_char( bytepack_writeUInt( value, byte_count ) )
		elseif byte_count == 2 then
			local b1, b2 = bytepack_writeUInt( value, byte_count )

			if not big_endian then
				b1, b2 = b2, b1
			end

			return string_char( b1, b2 )
		elseif byte_count == 3 then
			local b1, b2, b3 = bytepack_writeUInt( value, byte_count )

			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return string_char( b1, b2, b3 )
		elseif byte_count == 4 then
			local b1, b2, b3, b4 = bytepack_writeUInt( value, byte_count )

			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4 )
		elseif byte_count == 5 then
			local b1, b2, b3, b4, b5 = bytepack_writeUInt( value, byte_count )

			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5 )

		elseif byte_count == 6 then
			local b1, b2, b3, b4, b5, b6 = bytepack_writeUInt( value, byte_count )

			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6 )

		elseif byte_count == 7 then
			local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeUInt( value, byte_count )

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7 )
		elseif byte_count == 8 then
			local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeUInt( value, byte_count )

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
		else
			std.error( "unsupported byte count", 2 )
			return ""
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads unsigned 1-byte (8 bit) integer from binary string.
---
--- Valid values without loss of precision: `0` - `255`
---
---@param str string The binary string.
---@param start_position? integer The start position in binary string. Default: `1`.
---@return integer value The unsigned 1-byte integer.
function pack.readUInt8( str, start_position )
	return string_byte( str, start_position or 1 )
end

--- [SHARED AND MENU]
---
--- Writes unsigned 1-byte (8 bit) integer as binary string.
---
--- Valid values without loss of precision: `0` - `255`
---
---@param value integer The unsigned 1-byte integer.
---@return string str The binary string.
function pack.writeUInt8( value )
	return string_char( value )
end

do

	local bytepack_readUInt16 = bytepack.readUInt16

	--- [SHARED AND MENU]
	---
	--- Reads unsigned 2-byte (16 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `0` - `65535`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned 2-byte integer.
	function pack.readUInt16( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2 = string_byte( str, start_position, start_position + 1 )

		if b2 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readUInt16( b1, b2 )
	end

end

do

	local bytepack_writeUInt16 = bytepack.writeUInt16

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 2-byte (16 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `65535`
	---
	---@param value integer The unsigned 2-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@return string str The binary string.
	function pack.writeUInt16( value, big_endian )
		local b1, b2 = bytepack_writeUInt16( value )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

end

do

	local bytepack_readUInt24 = bytepack.readUInt24

	--- [SHARED AND MENU]
	---
	--- Reads unsigned 3-byte (24 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `0` - `16777215`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned 3-byte integer.
	function pack.readUInt24( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3 = string_byte( str, start_position, start_position + 2 )

		if b3 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2, b3 = b3, b2, b1
		end

		return bytepack_readUInt24( b1, b2, b3 )
	end

end

do

	local bytepack_writeUInt24 = bytepack.writeUInt24

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 3-byte (24 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `16777215`
	---
	---@param value integer The unsigned 3-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@return string str The binary string.
	function pack.writeUInt24( value, big_endian )
		local b1, b2, b3 = bytepack_writeUInt24( value )

		if not big_endian then
			b1, b2, b3 = b3, b2, b1
		end

		return string_char( b1, b2, b3 )
	end

end

do

	local bytepack_readUInt32 = bytepack.readUInt32

	--- [SHARED AND MENU]
	---
	--- Reads unsigned 4-byte (32 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `0` - `4294967295`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned 4-byte integer.
	function pack.readUInt32( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )

		if b4 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return bytepack_readUInt32( b1, b2, b3, b4 )
	end

end

do

	local bytepack_writeUInt32 = bytepack.writeUInt32

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 4-byte (32 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `4294967295`
	---
	---@param value integer The unsigned 4-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@return string str The binary string.
	function pack.writeUInt32( value, big_endian )
		local b1, b2, b3, b4 = bytepack_writeUInt32( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4 )
	end

end

do

	local bytepack_readUInt40 = bytepack.readUInt40

	--- [SHARED AND MENU]
	---
	--- Reads unsigned 5-byte (40 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `0` - `1099511627775`.
	---
	--- All values above will have problems when working with them.
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned 5-byte integer.
	function pack.readUInt40( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5 = string_byte( str, start_position, start_position + 4 )

		if b5 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
		end

		return bytepack_readUInt40( b1, b2, b3, b4, b5 )
	end

end

do

	local bytepack_writeUInt40 = bytepack.writeUInt40

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 5-byte (40 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `1099511627775`.
	---
	---@param value integer The unsigned 5-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@return string str The binary string.
	function pack.writeUInt40( value, big_endian )
		local b1, b2, b3, b4, b5 = bytepack_writeUInt40( value )

		if not big_endian then
			b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5 )
	end

end

do

	local bytepack_readUInt48 = bytepack.readUInt48

	--- [SHARED AND MENU]
	---
	--- Reads unsigned 6-byte (48 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `0` - `281474976710655`
	---
	---@param str string The binary string.
	---@param big_endian boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned 6-byte integer.
	function pack.readUInt48( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6 = string_byte( str, start_position, start_position + 5 )

		if b6 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
		end

		return bytepack_readUInt48( b1, b2, b3, b4, b5, b6 )
	end

end

do

	local bytepack_writeUInt48 = bytepack.writeUInt48

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 6-byte (48 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `281474976710655`
	---
	---@param value integer The unsigned 6-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@return string str The binary string.
	function pack.writeUInt48( value, big_endian )
		local b1, b2, b3, b4, b5, b6 = bytepack_writeUInt48( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6 )
	end

end

do

	local bytepack_readUInt56 = bytepack.readUInt56

	--- [SHARED AND MENU]
	---
	--- Reads unsigned 7-byte (56 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `0` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param str string The binary string.
	---@param big_endian? boolean The endianess.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned integer.
	function pack.readUInt56( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7 = string_byte( str, start_position, start_position + 6 )

		if b7 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readUInt56( b1, b2, b3, b4, b5, b6, b7 )
	end

end

do

	local bytepack_writeUInt56 = bytepack.writeUInt56

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 7-byte (56 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param value integer The unsigned 7-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@return string str The binary string.
	function pack.writeUInt56( value, big_endian )
		local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeUInt56( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7 )
	end

end

do

	local bytepack_readUInt64 = bytepack.readUInt64

	--- [SHARED AND MENU]
	---
	--- Reads unsigned 8-byte (64 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The unsigned 8-byte integer.
	function pack.readUInt64( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )

		if b8 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readUInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

end

do

	local bytepack_writeUInt64 = bytepack.writeUInt64

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 8-byte (64 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `0` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param value integer The unsigned 8-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeUInt64( value, big_endian )
		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeUInt64( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

end

do

	local bytepack_readUnsignedFixedPoint = bytepack.readUnsignedFixedPoint

	--- [SHARED AND MENU]
	---
	--- Reads unsigned fixed-point number (**UQm.n**) as binary string.
	---
	--- **Commonly Used UQm.n Formats**
	---| Format | Range | Precision (Step) |
	---|:------|:------------------------|:-----------------|
	---|UQ8.8  |`0 to 255.996`			  |0.00390625 (1/256)
	---|UQ10.6 |`0 to 1023.984375`		  |0.015625 (1/64)
	---|UQ12.4 |`0 to 4095.9375`		  |0.0625 (1/16)
	---|UQ16.16|`0 to 65535.99998`        |0.0000152588 (1/65536)
	---|UQ24.8 |`0 to 16,777,215.996`     |0.00390625 (1/256)
	---|UQ32.16|`0 to 4,294,967,295.99998`|0.0000152588 (1/65536)
	---
	---@param str string The string to read.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return number value The unsigned fixed-point number.
	function pack.readUnsignedFixedPoint( str, m, n, big_endian, start_position )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		if start_position == nil then
			start_position = 1
		end

		if byte_count == 0 or str == "" then
			return 0
		elseif byte_count == 1 then
			return bytepack_readUnsignedFixedPoint( n, string_byte( str, start_position ) )
		elseif byte_count == 2 then
			local b1, b2 = string_byte( str, start_position, start_position + 1 )

			if b2 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2 = b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2 )
		elseif byte_count == 3 then
			local b1, b2, b3 = string_byte( str, start_position, start_position + 2 )

			if b3 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3 )
		elseif byte_count == 4 then
			local b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )

			if b4 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4 )
		elseif byte_count == 5 then
			local b1, b2, b3, b4, b5 = string_byte( str, start_position, start_position + 4 )

			if b5 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			local b1, b2, b3, b4, b5, b6 = string_byte( str, start_position, start_position + 5 )

			if b6 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			local b1, b2, b3, b4, b5, b6, b7 = string_byte( str, start_position, start_position + 6 )

			if b7 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6, b7 )
		elseif byte_count == 8 then
			local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )

			if b8 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6, b7, b8 )
		else
			std.error( "unsupported byte count", 2 )
			return 0
		end
	end

end

do

	local bytepack_writeUnsignedFixedPoint = bytepack.writeUnsignedFixedPoint

	--- [SHARED AND MENU]
	---
	--- Writes unsigned fixed-point number (**UQm.n**) as binary string.
	---
	--- **Commonly Used UQm.n Formats**
	---| Format | Range | Precision (Step) |
	---|:------|:------------------------|:-----------------|
	---|UQ8.8  |`0 to 255.996`			  |0.00390625 (1/256)
	---|UQ10.6 |`0 to 1023.984375`		  |0.015625 (1/64)
	---|UQ12.4 |`0 to 4095.9375`		  |0.0625 (1/16)
	---|UQ16.16|`0 to 65535.99998`        |0.0000152588 (1/65536)
	---|UQ24.8 |`0 to 16,777,215.996`     |0.00390625 (1/256)
	---|UQ32.16|`0 to 4,294,967,295.99998`|0.0000152588 (1/65536)
	---
	---@param value number The unsigned fixed-point number.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string str The binary string.
	function pack.writeFixedPoint( value, m, n, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		if value == 0 then
			return string_rep( "\0", byte_count )
		elseif byte_count == 0 then
			return ""
		elseif byte_count == 1 then
			return string_char( bytepack_writeUnsignedFixedPoint( value, m, n ) )
		elseif byte_count == 2 then
			local b1, b2 = bytepack_writeUnsignedFixedPoint( value, m, n )

			if not big_endian then
				b1, b2 = b2, b1
			end

			return string_char( b1, b2 )
		elseif byte_count == 3 then
			local b1, b2, b3 = bytepack_writeUnsignedFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return string_char( b1, b2, b3 )
		elseif byte_count == 4 then
			local b1, b2, b3, b4 = bytepack_writeUnsignedFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4 )
		elseif byte_count == 5 then
			local b1, b2, b3, b4, b5 = bytepack_writeUnsignedFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			local b1, b2, b3, b4, b5, b6 = bytepack_writeUnsignedFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeUnsignedFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7 )
		elseif byte_count == 8 then
			local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeUnsignedFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
		else
			std.error( "unsupported byte count", 2 )
			return ""
		end
	end

end

do

	local bytepack_readInt = bytepack.readInt

	--- [SHARED AND MENU]
	---
	--- Reads signed integer from binary string.
	---
	--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param str string The binary string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function pack.readInt( str, byte_count, big_endian, start_position )
		if byte_count == nil then
			byte_count = 4
		end

		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + ( byte_count - 1 ) )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readInt( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

end

do

	local bytepack_writeInt = bytepack.writeInt

	--- [SHARED AND MENU]
	---
	--- Writes signed integer as binary string.
	---
	--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param value integer The signed integer.
	---@param byte_count? integer The number of bytes to write. Defaults to `4`.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt( value, byte_count, big_endian )
		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeInt( value, byte_count )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		if b2 == nil then
			return string_char( b1 )
		elseif b3 == nil then
			return string_char( b1, b2 )
		elseif b4 == nil then
			return string_char( b1, b2, b3 )
		elseif b5 == nil then
			return string_char( b1, b2, b3, b4 )
		elseif b6 == nil then
			return string_char( b1, b2, b3, b4, b5 )
		elseif b7 == nil then
			return string_char( b1, b2, b3, b4, b5, b6 )
		elseif b8 == nil then
			return string_char( b1, b2, b3, b4, b5, b6, b7 )
		else
			return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
		end
	end

end

do

	local bytepack_readInt8 = bytepack.readInt8

	--- [SHARED AND MENU]
	---
	--- Reads signed 1-byte (8 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `-128` - `127`
	---
	---@param str string The binary string.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 1-byte integer.
	function pack.readInt8( str, start_position )
		return bytepack_readInt8( string_byte( str, start_position or 1 ) )
	end

end

do

	local bytepack_writeInt8 = bytepack.writeInt8

	--- [SHARED AND MENU]
	---
	--- Writes signed 1-byte (8 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-128` - `127`
	---
	---@param value integer The signed 1-byte integer.
	---@return string str The binary string.
	function pack.writeInt8( value )
		return string_char( bytepack_writeInt8( value ) )
	end

end

do

	local bytepack_readInt16 = bytepack.readInt16

	--- [SHARED AND MENU]
	---
	--- Reads signed 2-byte (16 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-32768` - `32767`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 2-byte integer.
	function pack.readInt16( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2 = string_byte( str, start_position, start_position + 1 )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readInt16( b1, b2 )
	end

end

do

	local bytepack_writeInt16 = bytepack.writeInt16

	--- [SHARED AND MENU]
	---
	--- Writes signed 2-byte (16 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-32768` - `32767`
	---
	---@param value integer The signed 2-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt16( value, big_endian )
		local b1, b2 = bytepack_writeInt16( value )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

end

do

	local bytepack_readInt24 = bytepack.readInt24

	--- [SHARED AND MENU]
	---
	--- Reads signed 3-byte (24 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-8388608` - `8388607`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 3-byte integer.
	function pack.readInt24( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3 = string_byte( str, start_position, start_position + 2 )

		if not big_endian then
			b1, b2, b3 = b3, b2, b1
		end

		return bytepack_readInt24( b1, b2, b3 )
	end

end

do

	local bytepack_writeInt24 = bytepack.writeInt24

	--- [SHARED AND MENU]
	---
	--- Writes signed 3-byte (24 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-8388608` - `8388607`
	---
	---@param value integer The signed 3-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt24( value, big_endian )
		local b1, b2, b3 = bytepack_writeInt24( value )

		if not big_endian then
			b1, b2, b3 = b3, b2, b1
		end

		return string_char( b1, b2, b3 )
	end

end

do

	local bytepack_readInt32 = bytepack.readInt32

	--- [SHARED AND MENU]
	---
	--- Reads signed 4-byte (32 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `-2147483648` - `2147483647`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 4-byte integer.
	function pack.readInt32( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return bytepack_readInt32( b1, b2, b3, b4 )
	end

end

do

	local bytepack_writeInt32 = bytepack.writeInt32

	--- [SHARED AND MENU]
	---
	--- Writes signed 4-byte (32 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-2147483648` - `2147483647`
	---
	---@param value integer The signed 4-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt32( value, big_endian )
		local b1, b2, b3, b4 = bytepack_writeInt32( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4 )
	end

end

do

	local bytepack_readInt40 = bytepack.readInt40

	--- [SHARED AND MENU]
	---
	--- Reads signed 5-byte (40 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `-549755813888` - `549755813887`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 5-byte integer.
	function pack.readInt40( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5 = string_byte( str, start_position, start_position + 4 )

		if not big_endian then
			b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
		end

		return bytepack_readInt40( b1, b2, b3, b4, b5 )
	end

end

do

	local bytepack_writeInt40 = bytepack.writeInt40

	--- [SHARED AND MENU]
	---
	--- Writes signed 5-byte (40 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-549755813888` - `549755813887`
	---
	---@param value integer The signed 5-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt40( value, big_endian )
		local b1, b2, b3, b4, b5 = bytepack_writeInt40( value )

		if not big_endian then
			b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5 )
	end

end

do

	local bytepack_readInt48 = bytepack.readInt48

	--- [SHARED AND MENU]
	---
	--- Reads signed 6-byte (48 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `-140737488355328` - `140737488355327`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 6-byte integer.
	function pack.readInt48( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6 = string_byte( str, start_position, start_position + 5 )

		if not big_endian then
			b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
		end

		return bytepack_readInt48( b1, b2, b3, b4, b5, b6 )
	end

end

do

	local bytepack_writeInt48 = bytepack.writeInt48

	--- [SHARED AND MENU]
	---
	--- Writes signed 6-byte (48 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-140737488355328` - `140737488355327`
	---
	---@param value integer The signed 6-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt48( value, big_endian )
		local b1, b2, b3, b4, b5, b6 = bytepack_writeInt48( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6 )
	end

end

do

	local bytepack_readInt56 = bytepack.readInt56

	--- [SHARED AND MENU]
	---
	--- Reads signed 7-byte (56 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 7-byte integer.
	function pack.readInt56( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7 = string_byte( str, start_position, start_position + 6 )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readInt56( b1, b2, b3, b4, b5, b6, b7 )
	end

end

do

	local bytepack_writeInt56 = bytepack.writeInt56

	--- [SHARED AND MENU]
	---
	--- Writes signed 7-byte (56 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
	---
	---@param value integer The signed 7-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt56( value, big_endian )
		local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeInt56( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7 )
	end

end

do

	local bytepack_readInt64 = bytepack.readInt64

	--- [SHARED AND MENU]
	---
	--- Reads signed 8-byte (64 bit) integer from binary string.
	---
	--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer value The signed 8-byte integer.
	function pack.readInt64( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

end

do

	local bytepack_writeInt64 = bytepack.writeInt64

	--- [SHARED AND MENU]
	---
	--- Writes signed 8-byte (64 bit) integer as binary string.
	---
	--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
	---
	--- All values above will have problems when working with them.
	---
	---@param value integer The signed 8-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeInt64( value, big_endian )
		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeInt64( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

end

do

	local bytepack_readFixedPoint = bytepack.readFixedPoint

	--- [SHARED AND MENU]
	---
	--- Reads signed fixed-point number (**UQm.n**) from binary string.
	---
	--- **Commonly Used UQm.n Formats**
	---| Format | Range | Precision (Step) |
	---|:------|:------------------------|:-----------------|
	---|UQ8.8  |`0 to 255.996`			  |0.00390625 (1/256)
	---|UQ10.6 |`0 to 1023.984375`		  |0.015625 (1/64)
	---|UQ12.4 |`0 to 4095.9375`		  |0.0625 (1/16)
	---|UQ16.16|`0 to 65535.99998`        |0.0000152588 (1/65536)
	---|UQ24.8 |`0 to 16,777,215.996`     |0.00390625 (1/256)
	---|UQ32.16|`0 to 4,294,967,295.99998`|0.0000152588 (1/65536)
	---
	---@param m integer Number of fractional bits.
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return number value The signed fixed-point number.
	function pack.readFixedPoint( str, m, n, big_endian, start_position )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		if start_position == nil then
			start_position = 1
		end

		if byte_count == 0 or str == "" then
			return 0
		elseif byte_count == 1 then
			return bytepack_readFixedPoint( n, string_byte( str, start_position ) )
		elseif byte_count == 2 then
			local b1, b2 = string_byte( str, start_position, start_position + 1 )

			if b2 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2 = b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2 )
		elseif byte_count == 3 then
			local b1, b2, b3 = string_byte( str, start_position, start_position + 2 )

			if b3 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3 )
		elseif byte_count == 4 then
			local b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )

			if b4 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4 )
		elseif byte_count == 5 then
			local b1, b2, b3, b4, b5 = string_byte( str, start_position, start_position + 4 )

			if b5 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			local b1, b2, b3, b4, b5, b6 = string_byte( str, start_position, start_position + 5 )

			if b6 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			local b1, b2, b3, b4, b5, b6, b7 = string_byte( str, start_position, start_position + 6 )

			if b7 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6, b7 )
		elseif byte_count == 8 then
			local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )

			if b8 == nil then
				std.error( "insufficient data length", 2 )
			elseif not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6, b7, b8 )
		else
			std.error( "unsupported byte count", 2 )
			return 0
		end
	end

end

do

	local bytepack_writeFixedPoint = bytepack.writeFixedPoint

	--- [SHARED AND MENU]
	---
	--- Writes unsigned fixed-point number (**UQm.n**) as binary string.
	---
	--- **Commonly Used UQm.n Formats**
	---| Format | Range | Precision (Step) |
	---|:------|:------------------------|:-----------------|
	---|UQ8.8  |`0 to 255.996`			  |0.00390625 (1/256)
	---|UQ10.6 |`0 to 1023.984375`		  |0.015625 (1/64)
	---|UQ12.4 |`0 to 4095.9375`		  |0.0625 (1/16)
	---|UQ16.16|`0 to 65535.99998`        |0.0000152588 (1/65536)
	---|UQ24.8 |`0 to 16,777,215.996`     |0.00390625 (1/256)
	---|UQ32.16|`0 to 4,294,967,295.99998`|0.0000152588 (1/65536)
	---
	---@param value number The unsigned fixed-point number.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeFixedPoint( value, m, n, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		if value == 0 then
			return string_rep( "\0", byte_count )
		elseif byte_count == 0 then
			return ""
		elseif byte_count == 1 then
			return string_char( bytepack_writeFixedPoint( value, m, n ) )
		elseif byte_count == 2 then
			local b1, b2 = bytepack_writeFixedPoint( value, m, n )

			if not big_endian then
				b1, b2 = b2, b1
			end

			return string_char( b1, b2 )
		elseif byte_count == 3 then
			local b1, b2, b3 = bytepack_writeFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return string_char( b1, b2, b3 )
		elseif byte_count == 4 then
			local b1, b2, b3, b4 = bytepack_writeFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4 )
		elseif byte_count == 5 then
			local b1, b2, b3, b4, b5 = bytepack_writeFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			local b1, b2, b3, b4, b5, b6 = bytepack_writeFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7 )
		elseif byte_count == 8 then
			local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeFixedPoint( value, m, n )

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
		else
			std.error( "unsupported byte count", 2 )
			return ""
		end
	end

end

do

	local bytepack_readFloat = bytepack.readFloat

	--- [SHARED AND MENU]
	---
	--- Reads signed 4-byte (32 bit) float from binary string.
	---
	--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return number value The signed 4-byte float.
	function pack.readFloat( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return bytepack_readFloat( b1, b2, b3, b4 )
	end

end

do

	local bytepack_writeFloat = bytepack.writeFloat

	--- [SHARED AND MENU]
	---
	--- Writes signed 4-byte (32 bit) float as binary string.
	---
	--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
	---
	---@param value number The signed 4-byte float.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeFloat( value, big_endian )
		local b1, b2, b3, b4 = bytepack_writeFloat( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4 )
	end

end

do

	local bytepack_readDouble = bytepack.readDouble

	--- [SHARED AND MENU]
	---
	--- Reads signed 8-byte (64 bit) float (double) from binary string.
	---
	--- Allowable values from `2.2250738585072014e-308` to `1.7976931348623158e+308`.
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return number value The double value.
	function pack.readDouble( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readDouble( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

end

do

	local bytepack_writeDouble = bytepack.writeDouble

	--- [SHARED AND MENU]
	---
	--- Writes signed 8-byte (64 bit) float (double) as binary string.
	---
	--- Allowable values from `2.2250738585072014e-308` to `1.7976931348623158e+308`.
	---
	---@param value number The signed 8-byte float.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_string The binary string.
	function pack.writeDouble( value, big_endian )
		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeDouble( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

end

do

	local bytepack_readDate = bytepack.readDate

	--- [SHARED AND MENU]
	---
	--- Reads date in DOS format from binary string.
	---
	---@param str string The string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer day The day.
	---@return integer month The month.
	---@return integer year The year.
	function pack.readDate( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2 = string_byte( str, start_position, start_position + 1 )

		if b2 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readDate( b1, b2 )
	end

end

do

	local bytepack_writeDate = bytepack.writeDate

	--- [SHARED AND MENU]
	---
	--- Writes date in DOS format as binary string.
	---
	---@param day? integer The day.
	---@param month? integer The month.
	---@param year? integer The year.
	function pack.writeDate( day, month, year, big_endian )
		local b1, b2 = bytepack_writeDate( day, month, year )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

end

do

	local bytepack_readTime = bytepack.readTime

	--- [SHARED AND MENU]
	---
	--- Reads time in DOS format from binary string.
	---
	---@param str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return integer hours The number of hours.
	---@return integer minutes The number of minutes.
	---@return integer seconds The number of seconds, **will be rounded**.
	function pack.readTime( str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2 = string_byte( str, start_position, start_position + 1 )

		if b2 == nil then
			std.error( "insufficient data length", 2 )
		end

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readTime( b1, b2 )
	end

end

do

	local bytepack_writeTime = bytepack.writeTime

	--- [SHARED AND MENU]
	---
	--- Writes time in DOS format as binary string.
	---
	---@param hours? integer The number of hours.
	---@param minutes? integer The number of minutes.
	---@param seconds? integer The number of seconds, **will be rounded**.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string str The binary string.
	function pack.writeTime( hours, minutes, seconds, big_endian )
		local b1, b2 = bytepack_writeTime( hours, minutes, seconds )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

end

--- [SHARED AND MENU]
---
--- Reads fixed-length string from binary string.
---
---@param str string The binary string.
---@param length? integer The size of the string.
---@param start_position? integer The start position in binary string. Default: `1`.
---@return string str The fixed-length string.
function pack.readFixedString( str, length, start_position )
	if start_position == nil then
		start_position = 1
	end

	return string_sub( str, start_position, ( start_position - 1 ) + length )
end

--- [SHARED AND MENU]
---
--- Writes fixed-length string as binary string.
---
---@param str string The binary string.
---@param max_length? integer The size of the string. ( 255 by default )
---@return string str The fixed-length string.
function pack.writeFixedString( str, max_length )
	if max_length == nil then
		max_length = 255
	end

	local length = string_len( str )

	if max_length == length then
		return str
	elseif max_length > length then
		return str .. string_rep( "\0", max_length - length )
	else
		return string_sub( str, 1, max_length )
	end
end

do

	local readUInt = pack.readUInt

	--- [SHARED AND MENU]
	---
	--- Reads counted string from binary string.
	---
	---@param str string The binary string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean `true` for big endian, `false` for little endian. Default: `false`.
	---@param start_position? integer The start position in binary string. Default: `1`.
	---@return string result The counted string.
	---@return integer length The length of the counted string.
	function pack.readCountedString( str, byte_count, big_endian, start_position )
		if byte_count == nil then
			byte_count = 1
		end

		if start_position == nil then
			start_position = 1
		end

		local length = readUInt( str, byte_count, big_endian, start_position )

		if length == 0 then
			return "", 0
		end

		start_position = byte_count + ( start_position - 1 )
		return string_sub( str, start_position + 1, start_position + length ), length
	end

end

do

	local pack_writeUInt = pack.writeUInt

	--- [SHARED AND MENU]
	---
	--- Writes counted string as binary string.
	---
	---@param str string The counted string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string result The binary string.
	---@return integer length The length of the binary string.
	function pack.writeCountedString( str, byte_count, big_endian )
		if byte_count == nil then
			byte_count = 1
		end

		local length = string_len( str )
		return pack_writeUInt( length, byte_count, big_endian ) .. str, length + byte_count
	end

end

--- [SHARED AND MENU]
---
--- Reads null-terminated string from binary string.
---
---@param str string The binary string.
---@param start_position? integer The start position in binary string. Default: `1`.
---@return string result The null-terminated string.
---@return integer length The length of the null-terminated string.
function pack.readNullTerminatedString( str, start_position )
	if start_position == nil then
		start_position = 1
	end

	local end_position = start_position

	while string_byte( str, end_position ) ~= 0 do
		end_position = end_position + 1
	end

	if end_position == start_position then
		return "", 0
	else
		return string_sub( str, start_position, end_position - 1 ), end_position - start_position
	end
end

--- [SHARED AND MENU]
---
--- Writes null-terminated string as binary string.
---
---@param str string The null-terminated string.
---@return string result The binary string.
function pack.writeNullTerminatedString( str )
	return str .. "\0"
end
