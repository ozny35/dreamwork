local std = _G.gpm.std
local string, math, table = std.string, std.math, std.table

local string_byte, string_char, string_len, string_sub, string_rep = string.byte, string.char, string.len, string.sub, string.rep
local table_unpack = table.unpack
local math_floor = math.floor

--- [SHARED AND MENU]
--- The binary library.
---@class gpm.std.crypto.binary
local binary = {}

--- Explodes a number into a table of booleans (bits).
---@param number integer The number to explode.
---@param max_size? integer The maximum size of the table.
---@return boolean[]: The table of bits.
---@return integer: The size of the bit table.
local function explode( number, max_size )
	if max_size == nil then max_size = 0 end

	local bits, length = {}, 0
	while number ~= 0 or length < max_size do
		length = length + 1
		bits[ length ] = number % 2 ~= 0
		number = math_floor( number * 0.5 )
	end

	return bits, length
end

binary.explode = explode

--- Implodes a table of booleans (bits) into a number.
---@param bits boolean[] The table of bits.
---@param size? integer The size of the table.
---@param start_position? integer The start position of the table.
---@return integer: The number.
local function implode( bits, size, start_position )
	local number = 0

	if start_position == nil then
		for index = size or #bits, 1, -1 do
			number = number * 2 + ( bits[ index ] and 1 or 0 )
		end
	else
		start_position = start_position - 1

		for index = size or #bits, 1, -1 do
			number = number * 2 + ( bits[ index + start_position ] and 1 or 0 )
		end
	end

	return number
end

binary.implode = implode

--- [SHARED AND MENU]
--- Reads an unsigned byte from a binary string.
---@param str string The binary string.
---@param start_position? integer The start position of the binary string.
---@return integer: The unsigned byte.
function binary.readUByte( str, start_position )
	return string_byte( str, start_position )
end

--- [SHARED AND MENU]
--- Writes an unsigned byte to a binary string.
---@param number integer The unsigned byte.
---@return string: The binary string.
function binary.writeUByte( number )
	return string_char( number )
end

--- [SHARED AND MENU]
--- Reads a signed byte from a binary string.
---@param str string The binary string.
---@param start_position? integer The start position of the binary string.
---@return integer: The signed byte.
function binary.readSByte( str, start_position )
	return string_byte( str, start_position ) - 0x80
end

--- [SHARED AND MENU]
--- Writes a signed byte to a binary string.
---@param number integer The signed byte.
---@return string: The binary string.
function binary.writeSByte( number )
	return string_char( number + 0x80 )
end

--- [SHARED AND MENU]
--- Reads a boolean from a binary string.
---@param str string The binary string.
---@param start_position? integer The start position of the binary string.
---@return boolean: The boolean.
function binary.readBool( str, start_position )
	return string_byte( str, start_position ) ~= 0
end

--- [SHARED AND MENU]
--- Writes a boolean to a binary string.
---@param bool boolean The boolean.
---@return string: The binary string.
function binary.writeBool( bool )
	return string_char( bool and 1 or 0 )
end

--- [SHARED AND MENU]
--- Reads an `\0` characters length from a binary string.
---@param str string The binary string.
---@param start_position? integer The start position of the binary string.
---@return integer: The count of `\0` characters.
function binary.readNull( str, start_position )
	if start_position == nil then start_position = 1 end

	local bytes = { string_byte( str, start_position, string_len( str ) ) }
	local length = #bytes

	for i = 1, length, 1 do
		if bytes[ i ] ~= 0 then
			length = i
			break
		end
	end

	return length
end

--- [SHARED AND MENU]
--- Writes an `\0` character as a binary string.
---@param length? integer The length of the empty string.
---@return string: The empty string.
function binary.writeNull( length )
	return string_rep( "\0", length or 1 )
end

local findNull
do

	local string_find = string.find

	--- [SHARED AND MENU]
	--- Finds the first `\0` character in a binary string.
	---@param str string The binary string.
	---@param start_position? integer The start position of the binary string.
	---@return number | nil: The position of the `\0` character.
	function findNull( str, start_position )
		return string_find( str, "\0", start_position, true )
	end

	binary.findNull = findNull

end

--- [SHARED AND MENU]
--- Reads an unsigned integer from a binary string.
---@param str string The binary string.
---@param length? integer The number of bytes to read.
---@param start_position? integer The start position of the binary string.
---@param big_endian? boolean The endianness of the binary string.
---@return integer: The unsigned integer.
local function readUInt( str, length, big_endian, start_position )
	if start_position == nil then start_position = 1 end
	if length == nil then length = 4 end

	local bytes = { string_byte( str, start_position, ( start_position - 1 ) + length ) }

	local number = 0
	if big_endian then
		for index = 1, length, 1 do
			number = number * 0x100 + bytes[ index ]
		end

		return number
	end

	for index = length, 1, -1 do
		number = number * 0x100 + bytes[ index ]
	end

	return number
end

binary.readUInt = readUInt

--- [SHARED AND MENU]
--- Writes an unsigned integer to a binary string.
---@param number integer The unsigned integer.
---@param length? integer The number of bytes to write.
---@param big_endian? boolean The endianness of the binary string.
---@return string: The binary string.
local function writeUInt( number, length, big_endian )
	if length == nil then length = 4 end

	local bytes = {}
	for index = big_endian and length or 1, big_endian and 1 or length, big_endian and -1 or 1 do
		bytes[ index ] = number % 0x100
		number = math_floor( number * 0.00390625 )
	end

	return string_char( table_unpack( bytes, 1, length ) )
end

binary.writeUInt = writeUInt

--- [SHARED AND MENU]
--- Reads a signed integer from a binary string.
---@param str string The binary string.
---@param length? integer The number of bytes to read.
---@param start_position? integer The start position of the binary string.
---@param big_endian? boolean The endianness of the binary string.
---@return integer: The signed integer.
local function readInt( str, length, big_endian, start_position )
	local number, bit_count = readUInt( str, length, big_endian, start_position ), length * 8
	return ( number < 2 ^ ( bit_count - 1 ) ) and number or ( number - ( 2 ^ bit_count ) )
end

binary.readInt = readInt

--- [SHARED AND MENU]
--- Writes a signed integer to a binary string.
---@param number integer The signed integer.
---@param length? integer The number of bytes to write.
---@param big_endian? boolean The endianness of the binary string.
---@return string str The binary string.
local function writeInt( number, length, big_endian )
	return writeUInt( ( number < 0 ) and ( number + ( 2 ^ ( length * 8 ) ) ) or number, length, big_endian )
end

binary.writeInt = writeInt

--- [SHARED AND MENU]
--- Reads a fixed-length string from a binary string.
---@param str string The binary string.
---@param size? integer The size of the string.
---@param start_position? integer The start position of the binary string.
---@return string: The fixed-length string.
function binary.readFixedString( str, size, start_position )
	if start_position == nil then start_position = 1 end
	return string_sub( str, start_position, ( start_position - 1 ) + size )
end

--- [SHARED AND MENU]
--- Reads a fixed-length string from a binary string.
---@param str string The binary string.
---@param size integer The size of the string.
---@return string: The fixed-length string.
function binary.writeFixedString( str, size )
	local length = string_len( str )
	if size == nil then size = length end

	if size == length then
		return str
	elseif size > length then
		return str .. string_rep( "\0", size - length )
	else
		return string_sub( str, 1, size )
	end
end

--- [SHARED AND MENU]
--- Reads a counted string from a binary string.
---@param str string The binary string.
---@param uint_bytes? integer The number of bytes to read.
---@param start_position? integer The start position of the binary string.
---@param big_endian? boolean The endianness of the binary string.
---@return string: The counted string.
function binary.readCountedString( str, uint_bytes, start_position, big_endian )
	if start_position == nil then start_position = 1 end
	if uint_bytes == nil then uint_bytes = 4 end

	local length = readUInt( str, uint_bytes, big_endian, start_position )
	if length == 0 then return "" end

	start_position = ( start_position - 1 ) + uint_bytes
	return string_sub( str, start_position + 1, start_position + length )
end

--- [SHARED AND MENU]
--- Writes a counted string to a binary string.
---@param str string The counted string.
---@param uint_bytes? integer The number of bytes to write.
---@param big_endian? boolean The endianness of the binary string.
---@return string: The binary string.
function binary.writeCountedString( str, uint_bytes, big_endian )
	return writeUInt( string_len( str ), uint_bytes or 4, big_endian ) .. str
end

--- [SHARED AND MENU]
--- Reads a null-terminated string from a binary string.
---@param str string The binary string.
---@param start_position? integer The start position of the binary string.
---@return string: The null-terminated string.
function binary.readString( str, start_position )
	if start_position == nil then start_position = 1 end

	local end_position = findNull( str, start_position )
	if end_position == nil then
		end_position = string_len( str )
	else
		end_position = end_position - 1
	end

	return string_sub( str, start_position, end_position )
end

--- [SHARED AND MENU]
--- Writes a null-terminated string to a binary string.
---@param str string The null-terminated string.
---@return string: The binary string.
function binary.writeString( str )
	return str .. "\0"
end

--- [SHARED AND MENU]
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

local pack
do

	local table_reverse = table.reverse

	--- [SHARED AND MENU]
	--- Writes a sequence of bits to a binary string.
	---@param bits boolean[] The sequence of bits.
	---@param size integer The size of the sequence of bits.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	function pack( bits, size, big_endian )
		local bytes, length = {}, 0

		for i = 1, size * 8, 8 do
			length = length + 1
			bytes[ length ] = implode( bits, 8, i )
		end

		if big_endian then
			return string_char( table_unpack( table_reverse( bytes ), 1, length ) )
		else
			return string_char( table_unpack( bytes, 1, length ) )
		end
	end

	binary.pack = pack

end

local bit_band, bit_bor, bit_lshift, bit_rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local math_huge, math_tiny, math_nan = math.huge, math.tiny, math.nan
local math_frexp, math_ldexp = math.frexp, math.ldexp

--- [SHARED AND MENU]
--- Reads a float from a binary string.
---@param str string The binary string.
---@return number: The float.
function binary.readFloat( str, big_endian )
	local b1, b2, b3, b4

	if big_endian then
		b1, b2, b3, b4 = string_byte( str, 1, 4 )
	else
		b4, b3, b2, b1 = string_byte( str, 1, 4 )
	end

	local sign = bit_band( b1, 0x80 ) ~= 0
	local exponent = bit_bor( bit_lshift( bit_band( b1, 0x7F ), 1 ), bit_rshift( b2, 7 ) )
	local mantissa = bit_bor( bit_lshift( bit_band( b2, 0x7F ), 16 ), bit_lshift( b3, 8 ), b4 )

	if exponent == 0 then
		return ( sign and -1 or 1 ) * ( mantissa / 8388608 ) * 2 ^ -126
	elseif exponent == 255 then
		return mantissa == 0 and ( sign and math_tiny or math_huge ) or math_nan
	end

	return ( sign and -1 or 1 ) * ( 1 + ( mantissa / 8388608 ) ) * 2 ^ ( exponent - 127 )
end

do

	local string_reverse = string.reverse

	--- [SHARED AND MENU]
	--- Writes a float to a binary string.
	---@param value number The float value.
	---@return string: The binary string.
	function binary.writeFloat( value, big_endian )
		if big_endian then
			return string_reverse( binary.writeFloat( value, false ) )
		end

		if value == 0 then
			return "\0\0\0\0"
		elseif value ~= value then
			return "\255\255\255\255"
		end

		local sign = value < 0
		if sign then
			value = -value
		end

		if value == math.huge then
			if sign then
				return "\0\0\128\255"
			else
				return "\0\0\128\127"
			end
		end

		local mantissa, exponent = math_frexp( value )
		mantissa = bit_rshift( ( ( mantissa * 2 ) - 1 ) * 8388608, 0 )
		exponent = exponent + 126

		return string_char(
			bit_band( mantissa, 0xFF ),
			bit_band( bit_rshift( mantissa, 8 ), 0xFF ),
			bit_bor( bit_lshift( bit_band( exponent, 1 ), 7 ), bit_rshift( mantissa, 16 ) ),
			bit_bor( bit_lshift( sign and 1 or 0, 7 ), bit_rshift( exponent, 1 ) )
		)
	end

end

do

	local c0 = ( 2 ^ 11 ) - 1
	local c1 = 2 ^ 52
	local c2 = 2 ^ 10
	local c3 = 1 - 52 - c2
	local c4 = 2 ^ 53
	local bias = c2 - 1

	--- [SHARED AND MENU]
	--- Reads a double from a binary string.
	---@param str string The binary string.
	---@param big_endian? boolean The endianness of the binary string.
	---@return number: The double.
	function binary.readDouble( str, big_endian )
		if str == "\0\0\0\0\0\0\0\0" then
			return 0
		elseif str == "\128\0\0\0\0\0\0\0" or str == "\0\0\0\0\0\0\0\128" then
			return -0
		elseif str == "\255\255\255\255\255\255\255\255" then
			return math_nan
		elseif str == "\0\0\0\0\0\0\240\127" or str == "\127\240\0\0\0\0\0\0" then
			return math_huge
		elseif str == "\0\0\0\0\0\0\240\255" or str == "\255\240\0\0\0\0\0\0" then
			return math_tiny
		end

		local bits = unpack( str, 8, big_endian )

		local mantissa = implode( bits, 52 )
		local exponent = implode( bits, 11, 53 )
		local sign = bits[ 64 ]

		if exponent == c0 then
			if mantissa == 0 then
				if sign then
					return math_tiny
				else
					return math_huge
				end
			else
				return math_nan
			end
		end

		if exponent ~= 0 then
			mantissa = mantissa + c1
		else
			exponent = 1
		end

		return ( sign and -1 or 1 ) * math_ldexp( mantissa, exponent + c3 )
	end

	--- [SHARED AND MENU]
	--- Writes a double to a binary string.
	---@param value number The double.
	---@param big_endian? boolean The endianness of the binary string.
	---@return string: The binary string.
	function binary.writeDouble( value, big_endian )
		if value == 0 then
			if ( 1 / value ) == math_huge then
				return "\0\0\0\0\0\0\0\0"
			elseif big_endian then
				return "\128\0\0\0\0\0\0\0"
			else
				return "\0\0\0\0\0\0\0\128"
			end
		elseif value ~= value then
			return "\255\255\255\255\255\255\255\255"
		elseif value == math_huge then
			if big_endian then
				return "\127\240\0\0\0\0\0\0"
			else
				return "\0\0\0\0\0\0\240\127"
			end
		elseif value == math_tiny then
			if big_endian then
				return "\255\240\0\0\0\0\0\0"
			else
				return "\0\0\0\0\0\0\240\255"
			end
		end

		local sign
		if value < 0 then
			sign = true
			value = -value
		else
			sign = false
		end

		local mantissa, exponent = math_frexp( value )

		local ebs = exponent + bias
		if ebs <= 1 then
			mantissa, exponent = mantissa * ( 2 ^ ( 51 + ebs ) ), -bias
		else
			mantissa, exponent = ( mantissa - 0.5 ) * c4, exponent - 1
		end

		local bits = explode( mantissa )
		local exponentBits = explode( exponent + bias )

		for i = 1, 11 do
			bits[ 52 + i ] = exponentBits[ i ]
		end

		bits[ 64 ] = sign

		return pack( bits, 8, big_endian )
	end

end

return binary
