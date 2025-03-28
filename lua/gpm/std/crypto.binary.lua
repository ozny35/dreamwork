local std = _G.gpm.std
local bit, string, math, table = std.bit, std.string, std.math, std.table

local string_byte, string_char, string_len, string_sub, string_rep = string.byte, string.char, string.len, string.sub, string.rep
local table_unpack = table.unpack
local math_floor = math.floor

--- [SHARED AND MENU]
---
--- A binary library.
---@class gpm.std.crypto.binary
local binary = {}

local unsigned, unsigned_implode, unsigned_explode, unsigned_readInteger, unsigned_writeInteger
do

	--- [SHARED AND MENU]
	---
	--- The unsigned binary library.
	---@class gpm.std.crypto.binary.unsigned
	unsigned = {}
	binary.unsigned = unsigned

	--- Implodes a table of booleans (bits) into a number.
	---@param bits boolean[] The table of bits.
	---@param bit_count? integer The size of the table.
	---@param start_position? integer The start position of the table.
	---@return integer value
	function unsigned_implode( bits, bit_count, start_position )
		local value = 0

		if start_position == nil then
			for index = bit_count or #bits, 1, -1 do
				value = value * 2 + ( bits[ index ] and 1 or 0 )
			end
		else
			start_position = start_position - 1

			for index = bit_count or #bits, 1, -1 do
				value = value * 2 + ( bits[ index + start_position ] and 1 or 0 )
			end
		end

		return value
	end

	unsigned.implode = unsigned_implode

	--- Explodes a integer into a table of booleans (bits).
	---@param value integer The number to explode.
	---@param max_size? integer The maximum size of the table.
	---@return boolean[] bits The table of bits.
	---@return integer bit_count The size of the bit table.
	function unsigned_explode( value, max_size )
		if max_size == nil then max_size = 0 end

		local bits, bit_count = {}, 0
		while value ~= 0 or bit_count < max_size do
			bit_count = bit_count + 1
			bits[ bit_count ] = value % 2 ~= 0
			value = math_floor( value * 0.5 )
		end

		return bits, bit_count
	end

	unsigned.explode = unsigned_explode

	--- [SHARED AND MENU]
	---
	--- Reads an unsigned integer from a binary string.
	---@param str string The binary string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The unsigned integer.
	function unsigned_readInteger( str, byte_count, big_endian, start_position )
		if start_position == nil then start_position = 1 end

		if byte_count == nil then
			byte_count = 4
		elseif byte_count == 1 then
			return string_byte( str, start_position )
		end

		local bytes = { string_byte( str, start_position, ( start_position - 1 ) + byte_count ) }

		local value = 0
		if big_endian then
			for index = 1, byte_count, 1 do
				value = value * 0x100 + bytes[ index ]
			end

			return value
		end

		for index = byte_count, 1, -1 do
			value = value * 0x100 + bytes[ index ]
		end

		return value
	end

	unsigned.readInteger = unsigned_readInteger

	--- [SHARED AND MENU]
	---
	--- Writes an unsigned integer to a binary string.
	---@param value integer The unsigned integer.
	---@param byte_count? integer The number of bytes to write.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	function unsigned_writeInteger( value, byte_count, big_endian )
		if byte_count == nil then
			byte_count = 4
		elseif byte_count == 1 then
			return string_char( value )
		end

		local bytes = {}
		for index = big_endian and byte_count or 1, big_endian and 1 or byte_count, big_endian and -1 or 1 do
			bytes[ index ] = value % 0x100
			value = math_floor( value * 0.00390625 )
		end

		return string_char( table_unpack( bytes, 1, byte_count ) )
	end

	unsigned.writeInteger = unsigned_writeInteger

	--- [SHARED AND MENU]
	---
	--- Reads an unsigned byte (1 byte/8 bits) from a binary string.
	---
	--- Allowable values from `0` to `255`.
	---@param str string The binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The unsigned byte.
	function unsigned.readByte( str, start_position )
		return string_byte( str, start_position )
	end

	--- [SHARED AND MENU]
	---
	--- Writes an unsigned byte (1 byte/8 bits) to a binary string.
	---
	--- Allowable values from `0` to `255`.
	---@param value integer The unsigned byte.
	---@return string: The binary string.
	function unsigned.writeByte( value )
		return string_char( value )
	end

	--- [SHARED AND MENU]
	---
	--- Reads an unsigned short (2 bytes/16 bits) from a binary string.
	---
	--- Allowable values from `0` to `65535`.
	---@param str string The binary string.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The unsigned short.
	function unsigned.readShort( str, big_endian, start_position )
		if start_position == nil then start_position = 1 end
		local b1, b2

		if big_endian then
			b1, b2 = string_byte( str, start_position, start_position + 1 )
		else
			b2, b1 = string_byte( str, start_position, start_position + 1 )
		end

		return b1 * 0x100 + b2
	end

	--- [SHARED AND MENU]
	---
	--- Writes an unsigned short (2 bytes/16 bits) to a binary string.
	---
	--- Allowable values from `0` to `65535`.
	---@param value integer The unsigned short.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	function unsigned.writeShort( value, big_endian )
		return string_char(
			big_endian and math_floor( value / 0x100 ) or ( value % 0x100 ),
			big_endian and ( value % 0x100 ) or math_floor( value / 0x100 )
		)
	end

	--- [SHARED AND MENU]
	---
	--- Reads an unsigned long (4 bytes/32 bits) from a binary string.
	---
	--- Allowable values from `0` to `4294967295`.
	---@param str string The binary string.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The unsigned long.
	function unsigned.readLong( str, big_endian, start_position )
		if start_position == nil then start_position = 1 end
		local b1, b2, b3, b4

		if big_endian then
			b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )
		else
			b4, b3, b2, b1 = string_byte( str, start_position, start_position + 3 )
		end

		return ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4
	end

	--- [SHARED AND MENU]
	---
	--- Writes an unsigned long (4 bytes/32 bits) to a binary string.
	---
	--- Allowable values from `0` to `4294967295`.
	---@param value integer The unsigned long.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	function unsigned.writeLong( value, big_endian )
		return string_char(
			big_endian and math_floor( value / 0x1000000 ) or ( value % 0x100 ),
			( big_endian and math_floor( value / 0x10000 ) or math_floor( value / 0x100 ) ) % 0x100,
			( big_endian and math_floor( value / 0x100 ) or math_floor( value / 0x10000 ) ) % 0x100,
			big_endian and ( value % 0x100 ) or math_floor( value / 0x1000000 )
		)
	end

	--- [SHARED AND MENU]
	---
	--- Reads an unsigned long long (8 bytes/53 bits) from a binary string.
	---
	--- Allowable values from `0` to `9007199254740991`.
	---@param str string The binary string.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The unsigned long long.
	function unsigned.readLongLong( str, big_endian, start_position )
		if start_position == nil then start_position = 1 end
		local b1, b2, b3, b4, b5, b6, b7, b8

		if big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )
		else
			b8, b7, b6, b5, b4, b3, b2, b1 = string_byte( str, start_position, start_position + 7 )
		end

		return ( ( ( ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6 ) * 0x100 + b7 ) * 0x100 + b8
	end

	--- [SHARED AND MENU]
	---
	--- Writes an unsigned long long (8 bytes/53 bits) to a binary string.
	---
	--- Allowable values from `0` to `9007199254740991`.
	---@param value integer The unsigned long long.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	function unsigned.writeLongLong( value, big_endian )
		return string_char(
			big_endian and 0 or ( value % 0x100 ),
			( big_endian and math_floor( value / 0x1000000000000 ) or math_floor( value / 0x100 ) ) % 0x100,
			( big_endian and math_floor( value / 0x10000000000 ) or math_floor( value / 0x10000 ) ) % 0x100,
			( big_endian and math_floor( value / 0x100000000 ) or math_floor( value / 0x1000000 ) ) % 0x100,
			( big_endian and math_floor( value / 0x1000000 ) or math_floor( value / 0x100000000 ) ) % 0x100,
			( big_endian and math_floor( value / 0x10000 ) or math_floor( value / 0x10000000000 ) ) % 0x100,
			( big_endian and math_floor( value / 0x100 ) or math_floor( value / 0x1000000000000 ) ) % 0x100,
			big_endian and ( value % 0x100 ) or 0
		)
	end

	--- [SHARED AND MENU]
	---
	--- Reads an unsigned fixed-point number (**UQm.n**) from a binary string.
	--- <br/>
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
	---@param str string The binary string.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return number value The unsigned fixed-point number.
	---@return integer byte_count The number of readed bytes.
	function unsigned.readFixedPoint( str, m, n, big_endian, start_position )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		return unsigned_readInteger( str, byte_count, big_endian, start_position ) / ( 2 ^ n ), byte_count
	end

	--- [SHARED AND MENU]
	---
	--- Writes an unsigned fixed-point number (**UQm.n**) to a binary string.
	--- <br/>
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
	---@param value number The unsigned fixed-point number.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string binary The binary string.
	---@return integer byte_count The number of written bytes.
	function unsigned.writeFixedPoint( value, m, n, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		return unsigned_writeInteger( value * ( 2 ^ n ), byte_count, big_endian ), byte_count
	end

end

do

	--- [SHARED AND MENU]
	---
	--- The signed binary module.
	---@class gpm.std.crypto.binary.signed
	local signed = {}
	binary.signed = signed

	--- [SHARED AND MENU]
	---
	--- Reads a signed integer from a binary string.
	---@param str string The binary string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The signed integer.
	local function signed_readInteger( str, byte_count, big_endian, start_position )
		local value, bit_count = unsigned_readInteger( str, byte_count, big_endian, start_position ), byte_count * 8
		return ( value < 2 ^ ( bit_count - 1 ) ) and value or ( value - ( 2 ^ bit_count ) )
	end

	signed.readInteger = signed_readInteger

	--- [SHARED AND MENU]
	---
	--- Writes a signed integer to a binary string.
	---@param value integer The signed integer.
	---@param byte_count? integer The number of bytes to write.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string str The binary string.
	local function signed_writeInteger( value, byte_count, big_endian )
		return unsigned_writeInteger( ( value < 0 ) and ( value + ( 2 ^ ( byte_count * 8 ) ) ) or value, byte_count, big_endian )
	end

	signed.writeInteger = signed_writeInteger

	--- [SHARED AND MENU]
	---
	--- Reads a signed byte (1 byte/8 bits) from a binary string.
	---
	--- Allowable values from `-128` to `127`.
	---@param str string The binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The signed byte.
	function signed.readByte( str, start_position )
		return string_byte( str, start_position ) - 0x80
	end

	--- [SHARED AND MENU]
	---
	--- Writes a signed byte (1 byte/8 bits) to a binary string.
	---
	--- Allowable values from `-128` to `127`.
	---@param value integer The signed byte.
	---@return string: The binary string.
	function signed.writeByte( value )
		return string_char( value + 0x80 )
	end

	do

		local unsigned_readShort = unsigned.readShort

		--- [SHARED AND MENU]
		---
		--- Reads a signed short (2 bytes/16 bits) from a binary string.
		---
		--- Allowable values from `-32768` to `32767`.
		---@param str string The binary string.
		---@param big_endian? boolean The endianness of the binary string.
		---@param start_position? integer The start position of the binary string.
		---@return integer: The signed short.
		function signed.readShort( str, big_endian, start_position )
			return unsigned_readShort( str, big_endian, start_position ) - 0x8000
		end

	end

	do

		local unsigned_writeShort = unsigned.writeShort

		--- [SHARED AND MENU]
		---
		--- Writes a signed short (2 bytes/16 bits) to a binary string.
		---
		--- Allowable values from `-32768` to `32767`.
		---@param value integer The signed short.
		---@param big_endian? boolean The endianness of the binary string.
		---@return string: The binary string.
		function signed.writeShort( value, big_endian )
			return unsigned_writeShort( value + 0x8000, big_endian )
		end

	end

	do

		local unsigned_readLong = unsigned.readLong

		--- [SHARED AND MENU]
		---
		--- Reads a signed long (4 bytes/32 bits) from a binary string.
		---
		--- Allowable values from `-2147483648` to `2147483647`.
		---@param str string The binary string.
		---@param big_endian? boolean The endianness of the binary string.
		---@param start_position? integer The start position of the binary string.
		---@return integer: The signed long.
		function signed.readLong( str, big_endian, start_position )
			return unsigned_readLong( str, big_endian, start_position ) - 0x80000000
		end

	end

	do

		local unsigned_writeLong = unsigned.writeLong

		--- [SHARED AND MENU]
		---
		--- Writes a signed long (4 bytes/32 bits) to a binary string.
		---
		--- Allowable values from `-2147483648` to `2147483647`.
		---@param value integer The signed long.
		---@param big_endian? boolean The endianness of the binary string.
		---@return string: The binary string.
		function signed.writeLong( value, big_endian )
			return unsigned_writeLong( value + 0x80000000, big_endian )
		end

	end

	--- [SHARED AND MENU]
	---
	--- Reads a signed long long (8 bytes/53 bits) from a binary string.
	---
	--- Allowable values from `-9007199254740991` to `9007199254740991`.
	---@param str string The binary string.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return integer: The signed long long.
	function signed.readLongLong( str, big_endian, start_position )
		local b1, b2, b3, b4, b5, b6, b7, b8

		if big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )
		else
			b8, b7, b6, b5, b4, b3, b2, b1 = string_byte( str, start_position, start_position + 7 )
		end

		if b1 < 0x80 then
			return ( ( ( ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6 ) * 0x100 + b7 ) * 0x100 + b8
		else
			return ( ( ( ( ( ( ( ( b1 - 0xFF ) * 0x100 + ( b2 - 0xFF ) ) * 0x100 + ( b3 - 0xFF ) ) * 0x100 + ( b4 - 0xFF ) ) * 0x100 + ( b5 - 0xFF ) ) * 0x100 + ( b6 - 0xFF ) ) * 0x100 + ( b7 - 0xFF ) ) * 0x100 + ( b8 - 0xFF ) ) - 1
		end
	end

	do

		local math_ispositive = math.ispositive

		--- [SHARED AND MENU]
		---
		--- Writes a signed long long (8 bytes/53 bits) to a binary string.
		---
		--- Allowable values from `-9007199254740991` to `9007199254740991`.
		---@param value integer The signed long long.
		---@param big_endian? boolean The endianness of the binary string.
		---@return string: The binary string.
		function signed.writeLongLong( value, big_endian )
			return string_char(
				big_endian and ( math_ispositive( value ) and 0 or 0xFF ) or ( value % 0x100 ),
				( big_endian and math_floor( value / 0x1000000000000 ) or math_floor( value / 0x100 ) ) % 0x100,
				( big_endian and math_floor( value / 0x10000000000 ) or math_floor( value / 0x10000 ) ) % 0x100,
				( big_endian and math_floor( value / 0x100000000 ) or math_floor( value / 0x1000000 ) ) % 0x100,
				( big_endian and math_floor( value / 0x1000000 ) or math_floor( value / 0x100000000 ) ) % 0x100,
				( big_endian and math_floor( value / 0x10000 ) or math_floor( value / 0x10000000000 ) ) % 0x100,
				( big_endian and math_floor( value / 0x100 ) or math_floor( value / 0x1000000000000 ) ) % 0x100,
				big_endian and ( value % 0x100 ) or ( math_ispositive( value ) and 0 or 0xFF )
			)
		end

	end

	--- [SHARED AND MENU]
	---
	--- Reads an signed fixed-point number (**Qm.n**) from a binary string.
	--- <br/>
	---
	--- **Commonly Used Qm.n Formats**
	---| Format | Range | Precision (Step) |
	---|:------|:------------------------|:-----------------|
	---|Q1.7  |`-1.0 to 0.9921875`			  |0.0078125 (1/128)
	---|Q2.6  |`-2.0 to 1.984375`			  |0.015625 (1/64)
	---|Q4.4  |`-8.0 to 7.9375`				  |0.0625 (1/16)
	---|Q8.8  |`-128.0 to 127.996`			  |0.00390625 (1/256)
	---|Q10.6 |`-512.0 to 511.984375`		  |0.015625 (1/64)
	---|Q12.4 |`-2048.0 to 2047.9375`		  |0.0625 (1/16)
	---|Q16.16|`-32768.0 to 32767.99998`	  |0.0000152588 (1/65536)
	---|Q24.8 |`-8,388,608.0 to 8,388,607.996`|0.00390625 (1/256)
	---|Q32.16|`-2.1 billion to ~2.1 billion` |0.0000152588 (1/65536)
	---@param str string The binary string.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return number value: The signed fixed-point number.
	---@return integer byte_count: The number of readed bytes.
	function signed.readFixedPoint( str, m, n, big_endian, start_position )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		return signed_readInteger( str, byte_count, big_endian, start_position ) / ( 2 ^ n ), byte_count
	end

	--- [SHARED AND MENU]
	---
	--- Writes an signed fixed-point number (**Qm.n**) to a binary string.
	--- <br/>
	---
	--- **Commonly Used Qm.n Formats**
	---| Format | Range | Precision (Step) |
	---|:------|:------------------------|:-----------------|
	---|Q1.7  |`-1.0 to 0.9921875`			  |0.0078125 (1/128)
	---|Q2.6  |`-2.0 to 1.984375`			  |0.015625 (1/64)
	---|Q4.4  |`-8.0 to 7.9375`				  |0.0625 (1/16)
	---|Q8.8  |`-128.0 to 127.996`			  |0.00390625 (1/256)
	---|Q10.6 |`-512.0 to 511.984375`		  |0.015625 (1/64)
	---|Q12.4 |`-2048.0 to 2047.9375`		  |0.0625 (1/16)
	---|Q16.16|`-32768.0 to 32767.99998`	  |0.0000152588 (1/65536)
	---|Q24.8 |`-8,388,608.0 to 8,388,607.996`|0.00390625 (1/256)
	---|Q32.16|`-2.1 billion to ~2.1 billion` |0.0000152588 (1/65536)
	---@param value number The signed fixed-point number.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string binary The binary string.
	---@return integer byte_count The number of written bytes.
	function signed.writeFixedPoint( value, m, n, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			std.error( "invalid byte count", 2 )
		end

		return signed_writeInteger( value * ( 2 ^ n ), byte_count, big_endian ), byte_count
	end

end

do

	--- [SHARED AND MENU]
	---
	--- The data binary module.
	---@class gpm.std.crypto.binary.data
	local data = {}
	binary.data = data

	--- [SHARED AND MENU]
	---
	--- Reads a fixed-length string from a binary string.
	---@param str string The binary string.
	---@param length? integer The size of the string.
	---@param start_position? integer The start position of the binary string.
	---@return string str The fixed-length string.
	function data.readFixed( str, length, start_position )
		if start_position == nil then start_position = 1 end
		return string_sub( str, start_position, ( start_position - 1 ) + length )
	end

	--- [SHARED AND MENU]
	---
	--- Reads a fixed-length string from a binary string.
	---@param str string The binary string.
	---@param max_length? integer The size of the string. ( 255 by default )
	---@return string str The fixed-length string.
	function data.writeFixed( str, max_length )
		if max_length == nil then max_length = 255 end
		local length = string_len( str )

		if max_length == length then
			return str
		elseif max_length > length then
			return str .. string_rep( "\0", max_length - length )
		else
			return string_sub( str, 1, max_length )
		end
	end

	--- [SHARED AND MENU]
	---
	--- Reads a counted string from a binary string.
	---@param str string The binary string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean The endianness of the binary string.
	---@param start_position? integer The start position of the binary string.
	---@return string: The counted string.
	---@return integer: The length of the counted string.
	function data.readCounted( str, byte_count, big_endian, start_position )
		if start_position == nil then start_position = 1 end
		if byte_count == nil then byte_count = 1 end

		local length = unsigned_readInteger( str, byte_count, big_endian, start_position )
		if length == 0 then return "", 0 end

		start_position = byte_count + ( start_position - 1 )
		return string_sub( str, start_position + 1, start_position + length ), length
	end

	--- [SHARED AND MENU]
	---
	--- Writes a counted string to a binary string.
	---@param str string The counted string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	---@return integer: The length of the binary string.
	function data.writeCounted( str, byte_count, big_endian )
		if byte_count == nil then byte_count = 1 end

		local length = string_len( str )
		return unsigned_writeInteger( length, byte_count, big_endian ) .. str, length + byte_count
	end

	--- [SHARED AND MENU]
	---
	--- Reads a null-terminated string from a binary string.
	---@param str string The binary string.
	---@param start_position? integer The start position of the binary string.
	---@return string: The null-terminated string.
	---@return integer: The length of the null-terminated string.
	function data.readNullTerminated( str, start_position )
		if start_position == nil then start_position = 1 end

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
	--- Writes a null-terminated string to a binary string.
	---@param str string The null-terminated string.
	---@return string: The binary string.
	function data.writeNullTerminated( str )
		return str .. "\0"
	end

end

--- [SHARED AND MENU]
---
--- Reads a sequence of bits from a binary string.
---@param str string The binary string.
---@param byte_count? integer The number of bytes to read.
---@param big_endian? boolean The endianness of the binary string.
---@return boolean[]: The sequence of bits.
---@return integer: The count of the sequence of bits.
local function unpack( str, byte_count, big_endian, start_position )
	if start_position == nil then start_position = 1 end
	if byte_count == nil then byte_count = string_len( str ) end

	local bytes = { string_byte( str, start_position, ( start_position - 1 ) + byte_count ) }
	local result, length = {}, 0

	for i = big_endian and byte_count or 1, big_endian and 1 or byte_count, big_endian and -1 or 1 do
		local byte = bytes[ i ]
		for _ = 1, 8 do
			length = length + 1
			result[ length ] = byte % 2 == 1
			byte = math_floor( byte * 0.5 )
		end
	end

	return result, length
end

binary.unpack = unpack

local string_reverse = string.reverse

--- [SHARED AND MENU]
---
--- Writes a sequence of bits to a binary string.
---@param bits boolean[] The sequence of bits.
---@param bit_count integer The size of the sequence of bits.
---@param big_endian? boolean The endianness of the binary string.
---@param start_position? integer The start position of the binary string.
---@return string: The binary string.
local function pack( bits, bit_count, big_endian, start_position )
	local bytes, length = {}, 0

	for i = start_position or 1, ( bit_count or #bits ) * 8, 8 do
		length = length + 1
		bytes[ length ] = unsigned_implode( bits, 8, i )
	end

	if length == 0 then
		return ""
	end

	local str = string_char( table_unpack( bytes, 1, length ) )
	if big_endian then
		return string_reverse( str )
	else
		return str
	end
end

binary.pack = pack

local math_huge, math_tiny, math_nan = math.huge, math.tiny, math.nan
local math_frexp, math_ldexp = math.frexp, math.ldexp

--- [SHARED AND MENU]
---
--- Reads a float (4 bytes/32 bits) from a binary string.
---
--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
---@param str string The binary string.
---@param big_endian? boolean The endianness of the binary string.
---@param start_position? integer The start position of the binary string.
---@return number: The float.
function binary.readFloat( str, big_endian, start_position )
	if start_position == nil then start_position = 1 end
	local b1, b2, b3, b4

	if big_endian then
		b1, b2, b3, b4 = string_byte( str, start_position, start_position + 3 )
	else
		b4, b3, b2, b1 = string_byte( str, start_position, start_position + 3 )
	end

	local sign = b1 > 0x7F
	local expo = ( b1 % 0x80 ) * 0x2 + math_floor( b2 / 0x80 )
	local mant = ( ( b2 % 0x80 ) * 0x100 + b3 ) * 0x100 + b4

	if mant == 0 and expo == 0 then
		if sign then
			return -0.0
		else
			return 0.0
		end
	elseif expo == 0xFF then
		if mant == 0 then
			if sign then
				return math_tiny
			else
				return math_huge
			end
		else
			return math_nan
		end
	end

	return ( sign and -1 or 1 ) * math_ldexp( 1.0 + mant / 0x800000, expo - 0x7F )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes a float (4 bytes/32 bits) to a binary string.
	---
	--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
	---@param value number The float value.
	---@return string: The binary string.
	local function binary_writeFloat( value, big_endian )
		if not big_endian then
			return string_reverse( binary_writeFloat( value, true ) )
		elseif value ~= value then
			return "\255\136\0\0"
		end

		local sign = false
		if value < 0.0 then
			value = -value
			sign = true
		end

		local mant, expo = math_frexp( value )
		if mant == math_huge or expo > 0x80 then
			return sign and "\255\128\0\0" or "\127\128\0\0"
		elseif ( mant == 0.0 and expo == 0 ) or ( expo < -0x7E ) then
			return sign and "\128\0\0\0" or "\0\0\0\0"
		end

		mant = math_floor( ( mant * 2.0 - 1.0 ) * math_ldexp( 0.5, 24 ) )
		expo = expo + 0x7E

		return string_char(
			( sign and 0x80 or 0 ) + math_floor( expo / 0x2 ),
			( expo % 0x2 ) * 0x80 + math_floor( mant / 0x10000 ),
			math_floor( mant / 0x100 ) % 0x100,
			mant % 0x100
		)
	end

	binary.writeFloat = binary_writeFloat

end

--- [SHARED AND MENU]
---
--- Reads a double from a binary string.
---
--- Allowable values from `2.2250738585072014e-308` to `1.7976931348623158e+308`.
---@param str string The binary string.
---@param big_endian? boolean The endianness of the binary string.
---@param start_position? integer The start position of the binary string.
---@return number: The double.
function binary.readDouble( str, big_endian, start_position )
	if start_position == nil then start_position = 1 end
	local b1, b2, b3, b4, b5, b6, b7, b8

	if big_endian then
		b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( str, start_position, start_position + 7 )
	else
		b8, b7, b6, b5, b4, b3, b2, b1 = string_byte( str, start_position, start_position + 7 )
	end

	local sign = b1 > 0x7F
	local expo = ( b1 % 0x80 ) * 0x10 + math_floor( b2 / 0x10 )
	local mant = ( ( ( ( ( ( b2 % 0x10 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6 ) * 0x100 + b7 ) * 0x100 + b8

	if mant == 0 and expo == 0 then
		if sign then
			return -0.0
		else
			return 0.0
		end
	elseif expo == 0x7FF then
		if mant == 0 then
			if sign then
				return math_tiny
			else
				return math_huge
			end
		else
			return math_nan
		end
	end

	return ( sign and -1 or 1 ) * math_ldexp( 1.0 + mant / 4503599627370496.0, expo - 0x3FF )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes a double to a binary string.
	---
	--- Allowable values from `2.2250738585072014e-308` to `1.7976931348623158e+308`.
	---@param value number The double.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	local function binary_writeDouble( value, big_endian )
		if not big_endian then
			return string_reverse( binary_writeDouble( value, true ) )
		elseif value ~= value then -- NaN
			return "\255\248\0\0\0\0\0\0"
		end

		local sign = false
		if value < 0.0 then
			value = -value
			sign = true
		end

		local mant, expo = math_frexp( value )
		if mant == math_huge or expo > 0x400 then -- inf
			return sign and "\255\240\0\0\0\0\0\0" or "\127\240\0\0\0\0\0\0"
		elseif ( mant == 0.0 and expo == 0 ) or ( expo < -0x3FE ) then -- zero
			return ( 1 / value ) == math_huge and "\0\0\0\0\0\0\0\0" or "\128\0\0\0\0\0\0\0"
		end

		mant = math_floor( ( mant * 2.0 - 1.0 ) * math_ldexp( 0.5, 53 ) )
		expo = expo + 0x3FE

		return string_char(
			( sign and 0x80 or 0 ) + math_floor( expo / 0x10 ),
			( expo % 0x10 ) * 0x10 + math_floor( mant / 0x1000000000000 ),
			math_floor( mant / 0x10000000000 ) % 0x100,
			math_floor( mant / 0x100000000 ) % 0x100,
			math_floor( mant / 0x1000000 ) % 0x100,
			math_floor( mant / 0x10000 ) % 0x100,
			math_floor( mant / 0x100 ) % 0x100,
			mant % 0x100
		)
	end

	binary.writeDouble = binary_writeDouble

end

--- [SHARED AND MENU]
---
--- Reads a binary string as a stream of bits.
---
--- Can be used as iterator in for loops.
---
---@param str string The binary string.
---@param big_endian? boolean The endianness of the binary string.
---@return fun(): integer?, boolean? reader A reader function that returns the bit position and the bit (boolean) value or `nil` if there are no more bits.
function binary.reader( str, big_endian )
	local bytes = { string_byte( str, 1, string_len( str ) ) }
	local i, j = big_endian and 1 or #bytes, 8
	local byte = bytes[ i ]

	return function()
		if j == 0 then
			i, j = big_endian and ( i + 1 ) or ( i - 1 ), 8
			byte = bytes[ i ]
			if byte == nil then return nil end
		end

		j = j - 1
		return ( i - 1 ) * 8 + j + 1, math_floor( byte / ( 2 ^ j ) ) % 2 == 1
	end
end

--- [SHARED AND MENU]
---
--- Writes a stream of bits to a binary string.
---
---@param bytes integer[] The stream of bits.
---@param byte_count integer The number of bytes to write.
---@param big_endian? boolean The endianness of the binary string.
---@return fun( bit: boolean ): integer? writer A write function that writes a bit to a binary string and returns the position of the written bit or `nil` if the binary string is full.
function binary.writer( bytes, byte_count, big_endian )
	for i = 1, byte_count, 1 do
		bytes[ i ] = 0
	end

	local i = big_endian and 1 or byte_count
	local j = 7

	return function( value )
		if i > byte_count or i == 0 then return nil end

		if value then
			bytes[ i ] = bytes[ i ] + ( 2 ^ j )
		end

		j = ( j - 1 ) % 8

		if j == 7 then
			i = big_endian and ( i + 1 ) or ( i - 1 )
		end

		return i * 8 - ( 6 - j )
	end
end

return binary
