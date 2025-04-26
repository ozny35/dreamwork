local std = _G.gpm.std

local table_create = std.table.create

local string = std.string
local math = std.math
local bit = std.bit

local math_ispositive = math.ispositive
local math_floor = math.floor

local bit_lshift, bit_rshift = bit.lshift, bit.rshift
local bit_band, bit_bor = bit.band, bit.bor

---@class gpm.std.crypto
local crypto = std.crypto


--- [SHARED AND MENU]
---
--- The bytepack library that packs/unpacks types as bytes.
---
---@class gpm.std.crypto.bytepack
local bytepack = {}
crypto.bytepack = bytepack

--- [SHARED AND MENU]
---
--- Reads unsigned 2-byte (16 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@return integer value The unsigned 2-byte integer.
local function readUInt16( b1, b2 )
	return b1 * 0x100 + b2
end

bytepack.readUInt16 = readUInt16

--- [SHARED AND MENU]
---
--- Writes unsigned 2-byte (16 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param value integer The unsigned 2-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
local function writeUInt16( value )
	return bit_band( bit_rshift( value, 8 ), 0xFF ),
		bit_band( value, 0xFF )
end

bytepack.writeUInt16 = writeUInt16

--- [SHARED AND MENU]
---
--- Reads unsigned 3-byte (24 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `16777215`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@return integer value The unsigned 3-byte integer.
local function readUInt24( b1, b2, b3 )
	return ( b1 * 0x100 + b2 ) * 0x100 + b3
end

bytepack.readUInt24 = readUInt24

--- [SHARED AND MENU]
---
--- Writes unsigned 3-byte (24 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `16777215`
---
---@param value integer The unsigned 3-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
local function writeUInt24( value )
	return bit_band( bit_rshift( value, 16 ), 0xFF ),
		bit_band( bit_rshift( value, 8 ), 0xFF ),
		bit_band( value, 0xFF )
end

bytepack.writeUInt24 = writeUInt24

--- [SHARED AND MENU]
---
--- Reads unsigned 4-byte (32 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `4294967295`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@return integer value The unsigned 4-byte integer.
local function readUInt32( b1, b2, b3, b4 )
	return ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4
end

bytepack.readUInt32 = readUInt32

--- [SHARED AND MENU]
---
--- Writes unsigned 4-byte (32 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `4294967295`
---
---@param value integer The unsigned 4-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
local function writeUInt32( value )
	return bit_band( bit_rshift( value, 24 ), 0xFF ),
		bit_band( bit_rshift( value, 16 ), 0xFF ),
		bit_band( bit_rshift( value, 8 ), 0xFF ),
		bit_band( value, 0xFF )
end

bytepack.writeUInt32 = writeUInt32

--- [SHARED AND MENU]
---
--- Reads unsigned 5-byte (40 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `1099511627775`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@return integer value The unsigned 5-byte integer.
local function readUInt40( b1, b2, b3, b4, b5 )
	return ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5
end

bytepack.readUInt40 = readUInt40

--- [SHARED AND MENU]
---
--- Writes unsigned 5-byte (40 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `1099511627775`.
---
---@param value integer The unsigned 5-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
local function writeUInt40( value )
	return math_floor( value / 0x100000000 ) % 0x100,
		math_floor( value / 0x1000000 ) % 0x100,
		math_floor( value / 0x10000 ) % 0x100,
		math_floor( value / 0x100 ) % 0x100,
		value % 0x100

end

bytepack.writeUInt40 = writeUInt40

--- [SHARED AND MENU]
---
--- Reads unsigned 6-byte (48 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `281474976710655`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@param b6 integer The sixth byte.
---@return integer value The unsigned 6-byte integer.
local function readUInt48( b1, b2, b3, b4, b5, b6 )
	return ( ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6
end

bytepack.readUInt48 = readUInt48

--- [SHARED AND MENU]
---
--- Writes unsigned 6-byte (48 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `281474976710655`
---
---@param value integer The unsigned 6-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
---@return integer b6 The sixth byte.
local function writeUInt48( value )
	return math_floor( value / 0x10000000000 ) % 0x100,
		math_floor( value / 0x100000000 ) % 0x100,
		math_floor( value / 0x1000000 ) % 0x100,
		math_floor( value / 0x10000 ) % 0x100,
		math_floor( value / 0x100 ) % 0x100,
		value % 0x100
end

bytepack.writeUInt48 = writeUInt48

--- [SHARED AND MENU]
---
--- Reads unsigned 7-byte (56 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@param b6 integer The sixth byte.
---@param b7 integer The seventh byte.
---@return integer value The unsigned 7-byte integer.
local function readUInt56( b1, b2, b3, b4, b5, b6, b7 )
	return ( ( ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6 ) * 0x100 + b7
end

bytepack.readUInt56 = readUInt56

--- [SHARED AND MENU]
---
--- Writes unsigned 7-byte (56 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param value integer The unsigned 7-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
---@return integer b6 The sixth byte.
---@return integer b7 The seventh byte.
local function writeUInt56( value )
	return math_floor( value / 0x1000000000000 ) % 0x100,
		math_floor( value / 0x10000000000 ) % 0x100,
		math_floor( value / 0x100000000 ) % 0x100,
		math_floor( value / 0x1000000 ) % 0x100,
		math_floor( value / 0x10000 ) % 0x100,
		math_floor( value / 0x100 ) % 0x100,
		value % 0x100
end

bytepack.writeUInt56 = writeUInt56

--- [SHARED AND MENU]
---
--- Reads unsigned 8-byte (64 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@param b6 integer The sixth byte.
---@param b7 integer The seventh byte.
---@param b8 integer The eighth byte.
---@return integer value The unsigned 8-byte integer.
local function readUInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
	return ( ( ( ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6 ) * 0x100 + b7 ) * 0x100 + b8
end

bytepack.readUInt64 = readUInt64

--- [SHARED AND MENU]
---
--- Writes unsigned 8-byte (64 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param value integer The unsigned 8-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
---@return integer b6 The sixth byte.
---@return integer b7 The seventh byte.
---@return integer b8 The eighth byte.
local function writeUInt64( value )
	return 0,
		math_floor( value / 0x1000000000000 ) % 0x100,
		math_floor( value / 0x10000000000 ) % 0x100,
		math_floor( value / 0x100000000 ) % 0x100,
		math_floor( value / 0x1000000 ) % 0x100,
		math_floor( value / 0x10000 ) % 0x100,
		math_floor( value / 0x100 ) % 0x100,
		value % 0x100
end

bytepack.writeUInt64 = writeUInt64

do

	local math_clamp = math.clamp

	--- [SHARED AND MENU]
	---
	--- Reads time in DOS format from big endian bytes.
	---
	---@param b1 integer The first byte.
	---@param b2 integer The second byte.
	---@return integer hours The number of hours.
	---@return integer minutes The number of minutes.
	---@return integer seconds The number of seconds, **will be rounded**.
	function bytepack.readTime( b1, b2 )
		local short = readUInt16( b1, b2 )
		return bit_rshift( bit_band( short, 0xF800 ), 11 ),
			bit_rshift( bit_band( short, 0x7E0 ), 5 ),
			bit_band( short, 0x1F ) * 2
	end

	--- [SHARED AND MENU]
	---
	--- Writes time in DOS format as big endian bytes.
	---
	---@param hours? integer The number of hours.
	---@param minutes? integer The number of minutes.
	---@param seconds? integer The number of seconds, **will be rounded**.
	---@return integer b1 The first byte.
	---@return integer b2 The second byte.
	function bytepack.writeTime( hours, minutes, seconds )
		return writeUInt16( bit_bor(
			---@cast hours integer
			bit_lshift( hours == nil and 0 or math_clamp( hours, 0, 24 ), 11 ),

			---@cast minutes integer
			bit_lshift( minutes == nil and 0 or math_clamp( minutes, 0, 60 ), 5 ),

			---@cast seconds integer
			seconds == nil and 0 or math_floor( math_clamp( seconds, 0, 60 ) * 0.5 )
		) )
	end

	--- [SHARED AND MENU]
	---
	--- Reads date in DOS format from big endian bytes.
	---
	---@param b1 integer The first byte.
	---@param b2 integer The second byte.
	---@return integer day The day.
	---@return integer month The month.
	---@return integer year The year.
	function bytepack.readDate( b1, b2 )
		local short = readUInt16( b1, b2 )
		return bit_band( short, 0x1F ),
			bit_rshift( bit_band( short, 0x1E0 ), 5 ),
			bit_rshift( bit_band( short, 0xFE00 ), 9 ) + 1980
	end

	--- [SHARED AND MENU]
	---
	--- Writes date in DOS format as big endian bytes.
	---
	---@param day? integer The day.
	---@param month? integer The month.
	---@param year? integer The year.
	---@return integer b1 The first byte.
	---@return integer b2 The second byte.
	function bytepack.writeDate( day, month, year )
		return writeUInt16( bit_bor(
			---@cast day integer
			day == nil and 1 or math_clamp( day, 1, 31 ),

			---@cast month integer
			bit_lshift( month == nil and 1 or math_clamp( month, 1, 12 ), 5 ),

			---@cast year integer
			bit_lshift( year == nil and 0 or ( math_clamp( year, 1980, 2107 ) - 1980 ), 9 )
		) )
	end

end

--- [SHARED AND MENU]
---
--- Reads unsigned integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param b1? integer The first byte.
---@param b2? integer The second byte.
---@param b3? integer The third byte.
---@param b4? integer The fourth byte.
---@param b5? integer The fifth byte.
---@param b6? integer The sixth byte.
---@param b7? integer The seventh byte.
---@param b8? integer The eighth byte.
---@return integer value The unsigned integer.
local function readUInt( b1, b2, b3, b4, b5, b6, b7, b8 )
	if b1 == nil then
		return 0
	elseif b2 == nil then
		return b1
	elseif b3 == nil then
		return readUInt16( b1, b2 )
	elseif b4 == nil then
		return readUInt24( b1, b2, b3 )
	elseif b5 == nil then
		return readUInt32( b1, b2, b3, b4 )
	elseif b6 == nil then
		return readUInt40( b1, b2, b3, b4, b5 )
	elseif b7 == nil then
		return readUInt48( b1, b2, b3, b4, b5, b6 )
	elseif b8 == nil then
		return readUInt56( b1, b2, b3, b4, b5, b6, b7 )
	else
		return readUInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
	end
end

bytepack.readUInt = readUInt

--- [SHARED AND MENU]
---
--- Writes unsigned integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param value integer The unsigned integer.
---@param byte_count? integer The number of bytes to write. Defaults to `4`.
---@return integer ... The written bytes.
local function writeUInt( value, byte_count )
	if byte_count == nil then
		byte_count = 4
	end

	if value == 0 then
		---@diagnostic disable-next-line: return-type-mismatch
		return table_create( 0, byte_count )
	elseif byte_count == 1 then
		return value
	elseif byte_count == 2 then
		return writeUInt16( value )
	elseif byte_count == 3 then
		return writeUInt24( value )
	elseif byte_count == 4 then
		return writeUInt32( value )
	elseif byte_count == 5 then
		return writeUInt40( value )
	elseif byte_count == 6 then
		return writeUInt48( value )
	elseif byte_count == 7 then
		return writeUInt56( value )
	elseif byte_count == 8 then
		return writeUInt64( value )
	else
		std.error( "unsupported byte count", 2 )
		return 0
	end
end

bytepack.writeUInt = writeUInt

--- [SHARED AND MENU]
---
--- Reads unsigned fixed-point number (**UQm.n**) as big endian bytes.
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
---@param n integer Number of fractional bits.
---@param ... integer The bytes to read.
---@return number value The unsigned fixed-point number.
function bytepack.readUnsignedFixedPoint( n, ... )
	return readUInt( ... ) / ( 2 ^ n )
end

--- [SHARED AND MENU]
---
--- Writes unsigned fixed-point number (**UQm.n**) as big endian bytes.
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
---@return integer ... The written bytes.
function bytepack.writeUnsignedFixedPoint( value, m, n )
	local byte_count = ( m + n ) * 0.125
	if byte_count % 1 ~= 0 then
		std.error( "invalid number of integer or fractional bits", 2 )
	end

	return writeUInt( value * ( 2 ^ n ), byte_count )
end

--- [SHARED AND MENU]
---
--- Reads signed 1-byte (8 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param b1 integer The byte.
---@return integer value The signed 1-byte integer.
local function readInt8( b1 )
	return b1 - 0x80
end

bytepack.readInt8 = readInt8

--- [SHARED AND MENU]
---
--- Writes signed 1-byte (8 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param value integer The signed 1-byte integer.
---@return integer b1 The byte.
local function writeInt8( value )
	return value + 0x80
end

bytepack.writeInt8 = writeInt8

--- [SHARED AND MENU]
---
--- Reads signed 2-byte (16 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@return integer value The signed 2-byte integer.
local function readInt16( b1, b2 )
	return readUInt16( b1, b2 ) - 0x8000
end

bytepack.readInt16 = readInt16

--- [SHARED AND MENU]
---
--- Writes signed 2-byte (16 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param value integer The signed 2-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
local function writeInt16( value )
	return writeUInt16( value + 0x8000 )
end

bytepack.writeInt16 = writeInt16

--- [SHARED AND MENU]
---
--- Reads signed 3-byte (24 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-8388608` - `8388607`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@return integer value The signed 3-byte integer.
local function readInt24( b1, b2, b3 )
	return readUInt24( b1, b2, b3 ) - 0x800000
end

bytepack.readInt24 = readInt24

--- [SHARED AND MENU]
---
--- Writes signed 3-byte (24 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-8388608` - `8388607`
---
---@param value integer The signed 3-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
local function writeInt24( value )
	return writeUInt24( value + 0x800000 )
end

bytepack.writeInt24 = writeInt24

--- [SHARED AND MENU]
---
--- Reads signed 4-byte (32 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `-2147483648` - `2147483647`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@return integer value The signed 4-byte integer.
local function readInt32( b1, b2, b3, b4 )
	return readUInt32( b1, b2, b3, b4 ) - 0x80000000
end

bytepack.readInt32 = readInt32

--- [SHARED AND MENU]
---
--- Writes signed 4-byte (32 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-2147483648` - `2147483647`
---
---@param value integer The signed 4-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
local function writeInt32( value )
	return writeUInt32( value + 0x80000000 )
end

bytepack.writeInt32 = writeInt32

--- [SHARED AND MENU]
---
--- Reads signed 5-byte (40 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `-549755813888` - `549755813887`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@return integer value The signed 5-byte integer.
local function readInt40( b1, b2, b3, b4, b5 )
	return readUInt40( b1, b2, b3, b4, b5 ) - 0x8000000000
end

bytepack.readInt40 = readInt40

--- [SHARED AND MENU]
---
--- Writes signed 5-byte (40 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-549755813888` - `549755813887`
---
---@param value integer The signed 5-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
local function writeInt40( value )
	return writeUInt40( value + 0x8000000000 )
end

bytepack.writeInt40 = writeInt40

--- [SHARED AND MENU]
---
--- Reads signed 6-byte (48 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `-140737488355328` - `140737488355327`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@param b6 integer The sixth byte.
---@return integer value The signed 6-byte integer.
local function readInt48( b1, b2, b3, b4, b5, b6 )
	return readUInt48( b1, b2, b3, b4, b5, b6 ) - 0x800000000000
end

bytepack.readInt48 = readInt48

--- [SHARED AND MENU]
---
--- Writes signed 6-byte (48 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-140737488355328` - `140737488355327`
---
---@param value integer The signed 6-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
---@return integer b6 The sixth byte.
local function writeInt48( value )
	return writeUInt48( value + 0x800000000000 )
end

bytepack.writeInt48 = writeInt48

--- [SHARED AND MENU]
---
--- Reads signed 7-byte (56 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@param b6 integer The sixth byte.
---@param b7 integer The seventh byte.
---@return integer value The signed 7-byte integer.
local function readInt56( b1, b2, b3, b4, b5, b6, b7 )
	if b1 < 0x80 then
		return ( ( ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6 ) * 0x100 + b7
	else
		return ( ( ( ( ( ( ( b1 - 0xFF ) * 0x100 + ( b2 - 0xFF ) ) * 0x100 + ( b3 - 0xFF ) ) * 0x100 + ( b4 - 0xFF ) ) * 0x100 + ( b5 - 0xFF ) ) * 0x100 + ( b6 - 0xFF ) ) * 0x100 + ( b7 - 0xFF ) ) - 1
	end
end

bytepack.readInt56 = readInt56

--- [SHARED AND MENU]
---
--- Writes signed 7-byte (56 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
---
---@param value integer The signed 7-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
---@return integer b6 The sixth byte.
---@return integer b7 The seventh byte.
local function writeInt56( value )
	return math_ispositive( value ) and 0 or 0xFF,
		math_floor( value / 0x10000000000 ) % 0x100,
		math_floor( value / 0x100000000 ) % 0x100,
		math_floor( value / 0x1000000 ) % 0x100,
		math_floor( value / 0x10000 ) % 0x100,
		math_floor( value / 0x100 ) % 0x100,
		value % 0x100
end

bytepack.writeInt56 = writeInt56

-- print( bytepack.readInt56( bytepack.writeInt56( 2 ^ 48 ) ) )

--- [SHARED AND MENU]
---
--- Reads signed 8-byte (64 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@param b6 integer The sixth byte.
---@param b7 integer The seventh byte.
---@param b8 integer The eighth byte.
---@return integer value The signed 8-byte integer.
local function readInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
	if b1 < 0x80 then
		return ( ( ( ( ( ( b1 * 0x100 + b2 ) * 0x100 + b3 ) * 0x100 + b4 ) * 0x100 + b5 ) * 0x100 + b6 ) * 0x100 + b7 ) * 0x100 + b8
	else
		return ( ( ( ( ( ( ( ( b1 - 0xFF ) * 0x100 + ( b2 - 0xFF ) ) * 0x100 + ( b3 - 0xFF ) ) * 0x100 + ( b4 - 0xFF ) ) * 0x100 + ( b5 - 0xFF ) ) * 0x100 + ( b6 - 0xFF ) ) * 0x100 + ( b7 - 0xFF ) ) * 0x100 + ( b8 - 0xFF ) ) - 1
	end
end

bytepack.readInt64 = readInt64

--- [SHARED AND MENU]
---
--- Writes signed 8-byte (64 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param value integer The signed 8-byte integer.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
---@return integer b6 The sixth byte.
---@return integer b7 The seventh byte.
---@return integer b8 The eighth byte.
local function writeInt64( value )
	return math_ispositive( value ) and 0 or 0xFF,
		math_floor( value / 0x1000000000000 ) % 0x100,
		math_floor( value / 0x10000000000 ) % 0x100,
		math_floor( value / 0x100000000 ) % 0x100,
		math_floor( value / 0x1000000 ) % 0x100,
		math_floor( value / 0x10000 ) % 0x100,
		math_floor( value / 0x100 ) % 0x100,
		value % 0x100
end

bytepack.writeInt64 = writeInt64

--- [SHARED AND MENU]
---
--- Reads signed integer from big endian bytes.
---
--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param b1? integer The first byte.
---@param b2? integer The second byte.
---@param b3? integer The third byte.
---@param b4? integer The fourth byte.
---@param b5? integer The fifth byte.
---@param b6? integer The sixth byte.
---@param b7? integer The seventh byte.
---@param b8? integer The eighth byte.
---@return integer value The signed integer.
local function readInt( b1, b2, b3, b4, b5, b6, b7, b8 )
	if b1 == nil then
		return 0
	elseif b2 == nil then
		return readInt8( b1 )
	elseif b3 == nil then
		return readInt16( b1, b2 )
	elseif b4 == nil then
		return readInt24( b1, b2, b3 )
	elseif b5 == nil then
		return readInt32( b1, b2, b3, b4 )
	elseif b6 == nil then
		return readInt40( b1, b2, b3, b4, b5 )
	elseif b7 == nil then
		return readInt48( b1, b2, b3, b4, b5, b6 )
	elseif b8 == nil then
		return readInt56( b1, b2, b3, b4, b5, b6, b7 )
	else
		return readInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
	end
end

bytepack.readInt = readInt

--- [SHARED AND MENU]
---
--- Writes signed integer as big endian bytes.
---
--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
---
--- All values above will have problems when working with them.
---
---@param value integer The signed integer.
---@param byte_count? integer The number of bytes to write. Defaults to `4`.
---@return integer ... The written bytes.
local function writeInt( value, byte_count )
	if byte_count == nil then
		byte_count = 4
	end

	if value == 0 then
		---@diagnostic disable-next-line: return-type-mismatch
		return table_create( 0, byte_count )
	elseif byte_count == 1 then
		return writeInt8( value )
	elseif byte_count == 2 then
		return writeInt16( value )
	elseif byte_count == 3 then
		return writeInt24( value )
	elseif byte_count == 4 then
		return writeInt32( value )
	elseif byte_count == 5 then
		return writeInt40( value )
	elseif byte_count == 6 then
		return writeInt48( value )
	elseif byte_count == 7 then
		return writeInt56( value )
	elseif byte_count == 8 then
		return writeInt64( value )
	else
		std.error( "unsupported byte count", 2 )
		return 0
	end
end

bytepack.writeInt = writeInt

--- [SHARED AND MENU]
---
--- Reads signed fixed-point number (**UQm.n**) as big endian bytes.
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
---@param n integer Number of fractional bits.
---@param ... integer The bytes to read.
---@return number value The signed fixed-point number.
function bytepack.readFixedPoint( n, ... )
	return readInt( ... ) / ( 2 ^ n )
end

--- [SHARED AND MENU]
---
--- Writes unsigned fixed-point number (**UQm.n**) as big endian bytes.
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
---@return integer ... The written bytes.
function bytepack.writeFixedPoint( value, m, n )
	local byte_count = ( m + n ) * 0.125
	if byte_count % 1 ~= 0 then
		std.error( "invalid byte count", 2 )
	end

	return writeInt( value * ( 2 ^ n ), byte_count )
end

local math_huge, math_tiny, math_nan = math.huge, math.tiny, math.nan
local math_frexp, math_ldexp = math.frexp, math.ldexp

--- [SHARED AND MENU]
---
--- Reads signed 4-byte (32 bit) float from big endian bytes.
---
--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@return number value The signed 4-byte float.
function bytepack.readFloat( b1, b2, b3, b4 )
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

	if sign then
		return -math_ldexp( 1.0 + mant / 0x800000, expo - 0x7F )
	else
		return math_ldexp( 1.0 + mant / 0x800000, expo - 0x7F )
	end
end

--- [SHARED AND MENU]
---
--- Writes signed 4-byte (32 bit) float as big endian bytes.
---
--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
---
---@param value number The signed 4-byte float.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
function bytepack.writeFloat( value, big_endian )
	if value ~= value then
		return 255, 136, 0, 0
	end

	local sign = false
	if value < 0.0 then
		value = -value
		sign = true
	end

	local mant, expo = math_frexp( value )
	if mant == math_huge or expo > 0x80 then
		if sign then
			return 255, 128, 0, 0
		else
			return 127, 128, 0, 0
		end
	elseif ( mant == 0.0 and expo == 0 ) or ( expo < -0x7E ) then
		if ( 1 / value ) == math_huge then
			return 0, 0, 0, 0
		else
			return 128, 0, 0, 0
		end
	end

	mant = math_floor( ( mant * 2.0 - 1.0 ) * math_ldexp( 0.5, 24 ) )
	expo = expo + 0x7E

	return ( sign and 0x80 or 0 ) + math_floor( expo / 0x2 ),
		( expo % 0x2 ) * 0x80 + math_floor( mant / 0x10000 ),
		math_floor( mant / 0x100 ) % 0x100,
		mant % 0x100
end

--- [SHARED AND MENU]
---
--- Reads signed 8-byte (64 bit) float (double) from big endian bytes.
---
--- Allowable values from `2.2250738585072014e-308` to `1.7976931348623158e+308`.
---
---@param b1 integer The first byte.
---@param b2 integer The second byte.
---@param b3 integer The third byte.
---@param b4 integer The fourth byte.
---@param b5 integer The fifth byte.
---@param b6 integer The sixth byte.
---@param b7 integer The seventh byte.
---@param b8 integer The eighth byte.
---@return number value The signed 8-byte float.
function bytepack.readDouble( b1, b2, b3, b4, b5, b6, b7, b8 )
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

	if sign then
		return -math_ldexp( 1.0 + mant / 4503599627370496.0, expo - 0x3FF )
	else
		return math_ldexp( 1.0 + mant / 4503599627370496.0, expo - 0x3FF )
	end
end

--- [SHARED AND MENU]
---
--- Writes signed 8-byte (64 bit) float (double) as big endian bytes.
---
--- Allowable values from `2.2250738585072014e-308` to `1.7976931348623158e+308`.
---
---@param value number The signed 8-byte float.
---@return integer b1 The first byte.
---@return integer b2 The second byte.
---@return integer b3 The third byte.
---@return integer b4 The fourth byte.
---@return integer b5 The fifth byte.
---@return integer b6 The sixth byte.
---@return integer b7 The seventh byte.
---@return integer b8 The eighth byte.
function bytepack.writeDouble( value )
	if value ~= value then -- NaN
		return 255, 248, 0, 0, 0, 0, 0, 0
	end

	local sign = false
	if value < 0.0 then
		value = -value
		sign = true
	end

	local mant, expo = math_frexp( value )
	if mant == math_huge or expo > 0x400 then -- inf
		if sign then
			return 255, 240, 0, 0, 0, 0, 0, 0
		else
			return 127, 240, 0, 0, 0, 0, 0, 0
		end
	elseif ( mant == 0.0 and expo == 0 ) or ( expo < -0x3FE ) then -- zero
		if ( 1 / value ) == math_huge then
			return 0, 0, 0, 0, 0, 0, 0, 0
		else
			return 128, 0, 0, 0, 0, 0, 0, 0
		end
	end

	mant = math_floor( ( mant * 2.0 - 1.0 ) * math_ldexp( 0.5, 53 ) )
	expo = expo + 0x3FE

	return ( sign and 0x80 or 0 ) + math_floor( expo / 0x10 ),
		( expo % 0x10 ) * 0x10 + math_floor( mant / 0x1000000000000 ),
		math_floor( mant / 0x10000000000 ) % 0x100,
		math_floor( mant / 0x100000000 ) % 0x100,
		math_floor( mant / 0x1000000 ) % 0x100,
		math_floor( mant / 0x10000 ) % 0x100,
		math_floor( mant / 0x100 ) % 0x100,
		mant % 0x100
end

do

	local string_byte = string.byte
	local string_len = string.len

	--- [SHARED AND MENU]
	---
	--- Reads a binary string as a stream of bytes.
	---
	--- Can be used as iterator in for loops.
	---
	---@param str string The binary string.
	---@param big_endian? boolean The endianness of the binary string.
	---@return fun(): integer?, integer? reader A reader function that returns the byte position and the byte value or `nil` if there are no more bytes.
	function bytepack.reader( str, big_endian )
		local byte_count = string_len( str )
		local byte_index = big_endian and 1 or byte_count
		local bytes = { string_byte( str, 1, byte_count ) }

		if big_endian then
			return function()
				if byte_index > byte_count then return nil end

				local value = bytes[ byte_index ]
				byte_index = byte_index + 1
				return byte_index, value
			end
		else
			return function()
				if byte_index == 0 then return nil end

				local value = bytes[ byte_index ]
				byte_index = byte_index - 1
				return byte_index, value
			end
		end
	end

end

--- [SHARED AND MENU]
---
--- Writes a stream of bytes to a binary string.
---
--- If the number of bytes is not specified and
--- big endian is `true` then `writer_fn` will
--- not be limited by the number of bytes
--- it will be able to write them indefinitely.
---
---@param byte_count? integer The number of bytes to write.
---@param big_endian? boolean The endianness of the binary string.
---@return fun( byte: integer ): integer? writer_fn A write function that writes a byte to a binary string and returns the position of the written byte or `nil` if the binary string is full.
---@return integer[] bytes The stream of bytes.
function bytepack.writer( byte_count, big_endian )
	if byte_count == nil then
		if not big_endian then
			std.error( "byte count must be specified for little endian", 2 )
		end

		local bytes, byte_index = {}, 1

		return function( value )
			bytes[ byte_index ] = value
			byte_index = byte_index + 1
			return byte_index
		end, bytes
	end

	local bytes = {}

	for i = 1, byte_count, 1 do
		bytes[ i ] = 0
	end

	if big_endian then
		local byte_index = 1

		return function( value )
			if byte_index > byte_count then return nil end
			bytes[ byte_index ] = value
			byte_index = byte_index + 1
			return byte_index
		end, bytes
	else
		local byte_index = byte_count

		return function( value )
			if byte_index == 0 then return nil end
			bytes[ byte_index ] = value
			byte_index = byte_index - 1
			return byte_index
		end, bytes
	end
end
