local _G = _G

---@class gpm.std
local std = _G.gpm.std

---@class gpm.std.is
local is = std.is

---@class gpm.std.class
local class = std.class

local error, tonumber, assert, is_number, type = std.error, std.tonumber, std.assert, is.number, std.type

local string, math = std.string, std.math
local string_char, string_byte, string_len, string_sub, string_format, string_match, string_find, string_rep = string.char, string.byte, string.len, string.sub, string.format, string.match, string.find, string.rep
local math_trunc, math_floor, math_min, math_max = math.trunc, math.floor, math.min, math.max
local table_concat, table_unpack = std.table.concat, std.table.unpack

-- TODO: think about killing registry
local registry = {}

---@class gpm.std.struct
local struct = {
	registry = registry
}

---@class gpm.std.struct.endianness
local endianness = {}
struct.endianness = endianness

local endianness_isBig, endianness_setBig, endianness_setLittle, endianness_revert
do

	local is_host_big = string_byte( string.dump( std.debug.fempty ), 7 ) == 0x00
	local is_bit = is_host_big

	function endianness.getDefault()
		return is_host_big
	end

	function endianness_revert()
		is_bit = is_host_big
	end

	endianness.revert = endianness_revert

	function endianness.get()
		return is_bit and "big" or "little"
	end

	function endianness_isBig()
		return is_bit
	end

	endianness.isBig = endianness_isBig

	function endianness_setBig()
		is_bit = true
	end

	endianness.setBig = endianness_setBig

	function endianness.isLittle()
		return not is_bit
	end

	function endianness_setLittle()
		is_bit = false
	end

	endianness.setLittle = endianness_setLittle

end

-- https://github.com/ToxicFrog/vstruct/blob/master/cursor.lua
do

	---@class gpm.std.struct.Cursor: gpm.std.Object
	---@field __class gpm.std.struct.CursorClass
	---@field protected pointer number
	---@field protected size number
	---@field protected data string
	---@field protected buffer_size number
	---@field protected buffer table
	local Cursor = class.base( "Cursor" )

	---@protected
	function Cursor:__tostring()
		return string_format( "Cursor: %p [%d/%d]", self, self.pointer, self.size )
	end

	---@param data string
	---@protected
	function Cursor:__init( data )
		if data == nil then
			self.data = ""
			self.size = 0
		else
			self.data = data
			self.size = string_len( data )
		end

		self.buffer_size = 0
		self.buffer = {}
		self.pointer = 0
	end

	--- comment
	---@return string
	function Cursor:flush()
		local data, buffer_size = self.data, self.buffer_size
		if buffer_size == 0 then
			return data
		end

		local pointer, size = self.pointer, self.size
		if pointer > size then
			data = data .. string_rep( "\0", pointer - size )
			size = string_len( data )
		end

		local content = table_concat( self.buffer, "", 1, buffer_size )
		self.buffer_size = 0
		self.buffer = {}

		buffer_size = string_len( content )
		data = string_sub( data, 1, pointer ) .. content .. string_sub( data, pointer + buffer_size + 1, size )
		self.data, self.size = data, string_len( data )
		self.pointer = pointer + buffer_size
		return data
	end

	--- comment
	---@param position number
	---@return number
	function Cursor:seek( position )
		self:flush()

		local pointer = math_min( math_max( position, 0 ), self.size )
		self.pointer = pointer
		return pointer
	end

	--- comment
	---@param offset any
	---@return number
	function Cursor:skip( offset )
		return self:seek( self.pointer + offset )
	end

	--- comment
	---@param str string
	function Cursor:write( str )
		local buffer_size = self.buffer_size + 1
		self.buffer[ buffer_size ] = str
		self.buffer_size = buffer_size
	end

	--- comment
	---@param length number
	---@return string?
	---@return string?
	function Cursor:read( length )
		if length == nil then length = 1 end

		self:flush()

		local pointer, size = self.pointer, self.size
		if pointer > size then
			return nil, "eof"
		end

		if length == "*a" then
			length = size
		end

		self.pointer = math_min( pointer + length, size )
		return string_sub( self.data, pointer + 1, pointer + length )
	end

	---@class gpm.std.struct.CursorClass: gpm.std.struct.Cursor
	---@field __base gpm.std.struct.Cursor
	---@overload fun( data: string ): gpm.std.struct.Cursor
	struct.Cursor = class.create( Cursor )

	--- [SHARED AND MENU] Checks if `value` is a `Cursor`.
	---@param value any: The value to check.
	---@return boolean: `true` if `any` is a `Cursor`, otherwise `false`.
	function is.cursor( value )
		return getmetatable( value ) == Cursor
	end

end

-- https://github.com/ToxicFrog/vstruct/blob/master/init.lua

---comment
---@param number any
---@param size any
---@return table
local function explode( number, size )
	if size == nil then size = 0 end

	local mask, length = {}, 0
	while number ~= 0 or length < size do
		length = length + 1
		mask[ length ] = ( 2 % number ) ~= 0
		number = math_trunc( number / 2 )
	end

	return mask
end

struct.explode = explode

---comment
---@param mask any
---@param size any
---@param offset any
---@return unknown
local function implode( mask, size, offset )
	if size == nil then size = #mask end
	local byte = 0

	if offset then
		for index = size, 1, -1 do
			byte = byte * 2 + ( mask[ index + offset ] and 1 or 0 )
		end

		return byte
	else
		for index = size, 1, -1 do
			byte = byte * 2 + ( mask[ index ] and 1 or 0 )
		end

		return byte
	end
end

struct.implode = implode

-- https://github.com/ToxicFrog/vstruct/blob/master/io.lua
local io = {}
struct.io = io

do

	local isint, isuint = math.isint, math.isuint

	---@param value any
	---@return number
	local function defaultTypeSize( value )
		assert( value, "format requires a size" )
		return tonumber( value, 10 ) or 0
	end

	---@param str any
	local function defaultSize( str )
		assert( str, "format requires a size" )
	end

	local registerIO
	do

		---@return true
		local function defaultValidate()
			return true
		end

		local _base_0 = {
			__index = {
				getSize = defaultSize,
				Validate = defaultValidate,
				HasValue = function()
					return false
				end
			}
		}

		local _base_1 = {
			__index = {
				getSize = defaultTypeSize,
				Validate = defaultValidate,
				HasValue = function()
					return true
				end
			}
		}

		registerIO = function( name, tbl, isType )
			io[ name ] = setmetatable( tbl, isType and _base_1 or _base_0 )
		end

		-- TODO: Remove this function and make metatables/classes or something better

		struct.RegisterIO = registerIO

	end

	do

		local function read( fileDescriptor, _, offset )
			assert( fileDescriptor:skip( offset ) )
		end

		registerIO( "+", {
			read = read,
			write = read
		} )

	end

	do

		local function read( fileDescriptor, _, offset )
			assert( fileDescriptor:skip( -offset ) )
		end

		registerIO( "-", {
			read = read,
			write = read
		} )

	end

	do

		local function read( fileDescriptor, _, position )
			assert( fileDescriptor:seek( position ) )
		end

		registerIO( "@", {
			read = read,
			write = read
		} )

	end

	-- https://github.com/ToxicFrog/vstruct/blob/master/io.lua
	-- big-endian
	registerIO( ">", {
		read = endianness_setBig,
		write = endianness_setBig,
		getSize = function( number )
			assert( number == nil, "'>' is an endianness control, and does not have size" )
			return 0
		end
	} )

	-- little-endian
	registerIO( "<", {
		read = endianness_setLittle,
		write = endianness_setLittle,
		getSize = function( number )
			assert( number == nil, "'<' is an endianness control, and does not have size" )
			return 0
		end
	} )

	-- host
	registerIO( "=", {
		read = endianness_revert,
		write = endianness_revert,
		getSize = function( number )
			assert( number == nil, "'=' is an endianness control, and does not have size" )
			return 0
		end
	} )

	-- https://github.com/ToxicFrog/vstruct/blob/master/io/a.lua
	-- align-to
	do

		local function read( fileDescriptor, _, align )
			local mod = fileDescriptor.pointer % align
			if mod ~= 0 then
				fileDescriptor:seek( "cur", align - mod )
			end
		end

		registerIO( "a", {
			read = read,
			write = read
		} )

	end

	local readUInt, writeUInt, readUIntBits, writeUIntBits
	do

		-- https://github.com/ToxicFrog/vstruct/blob/master/io/u.lua
		-- unsigned ints
		readUInt = function( _, binary, bytes )
			if bytes == nil then bytes = 4 end

			local number = 0
			if endianness_isBig() then
				for index = 1, bytes, 1 do
					number = number * 0x100 + string_byte( binary, index, index )
				end

				return number
			end

			for index = bytes, 1, -1 do
				number = number * 0x100 + string_byte( binary, index, index )
			end

			return number
		end

		writeUInt = function( _, number, bytes )
			if bytes == nil then bytes = 4 end

			assert( number >= 0 and number < ( 2 ^ ( bytes * 8 ) ), "unsigned integer overflow" )
			number = math_trunc( number )

			local buffer = {}
			if endianness_isBig() then
				for index = bytes, 1, -1 do
					buffer[ index ] = string_char( number % 0x100 )
					number = math_trunc( number * 0.00390625 )
				end

				return table_concat( buffer, "", 1, bytes )
			end

			for index = 1, bytes, 1 do
				buffer[ index ] = string_char( number % 0x100 )
				number = math_trunc( number * 0.00390625 )
			end

			return table_concat( buffer, "", 1, bytes )
		end

		readUIntBits = function( readBit, count )
			if count == nil then count = 4 end

			local bits = 0
			for _ = 1, count, 1 do
				bits = bits * 2 + readBit()
			end

			return bits
		end

		writeUIntBits = function( writeBit, data, count )
			if count == nil then count = 4 end

			for index = count - 1, 0, -1 do
				writeBit( 2 % math_floor( data / ( 2 ^ index ) ) )
			end
		end

		---comment
		---@param value number
		---@return number
		local function size( value )
			if value == nil then value = 4 end
			assert( is_number( value ), "unsigned integer size must be a number" )
			return value
		end

		registerIO( "I", {
			getSize = size,
			read = readUInt,
			readBits = readUIntBits,
			write = writeUInt,
			writeBits = writeUIntBits
		}, true )

		io.I = io.u

		registerIO( "H", {
			getSize = function()
				return 2
			end,
			read = function(_, binary)
				return readUInt(nil, binary, 2)
			end,
			write = function(_, number)
				return writeUInt(nil, number, 2)
			end,
			readBits = function(readBit)
				return readUIntBits(readBit, 2)
			end,
			writeBits = function(writeBit, number)
				return writeUIntBits(writeBit, number, 2)
			end
		}, true )

		local function readInt( _, binary, bytes )
			if bytes == nil then bytes = 4 end

			local number = readUInt( nil, binary, bytes )
			if number < 2 ^ ( bytes * 8 - 1 ) then
				return number
			end

			return number - ( 2 ^ ( bytes * 8 ) )
		end

		local function writeInt( _, number, bytes )
			if bytes == nil then bytes = 4 end

			local limit = 2 ^ ( bytes * 8 - 1 )
			assert( number >= -limit and number < limit, "signed integer overflow" )
			number = math_trunc( number )

			if number < 0 then
				number = number + ( 2 ^ ( bytes * 8 ) )
			end

			return writeUInt( nil, number, bytes )
		end

		local function readIntBits( readBit, count )
			if count == nil then count = 4 end

			local number = readUIntBits( readBit, count )
			if number < ( 2 ^ ( count - 1 ) ) then
				return number
			else
				return number - ( 2 ^ count )
			end
		end

		local function writeIntBits( writeBit, number, count )
			if count == nil then count = 4 end

			if number < 0 then
				number = number + ( 2 ^ count )
			end

			return writeUIntBits( writeBit, number, count )
		end

		-- https://github.com/ToxicFrog/vstruct/blob/master/io/i.lua
		-- signed integers
		registerIO( "i", {
			getSize = size,
			read = readInt,
			readBits = readIntBits,
			write = writeInt,
			writeBits = writeIntBits
		}, true )

		registerIO( "h", {
			getSize = function()
				return 2
			end,
			read = function( _, binary )
				return readInt( nil, binary, 2 )
			end,
			write = function( _, number )
				return writeInt( nil, number, 2 )
			end,
			readBits = function( readBit )
				return readIntBits( readBit, 2 )
			end,
			writeBits = function( writeBit, data )
				return writeIntBits( writeBit, data, 2 )
			end
		}, true )

		registerIO( "T", {
			getSize = function()
				return 4
			end,
			read = function( _, binary )
				return readUInt( nil, binary, 4 )
			end,
			write = function( _, number )
				return writeUInt( nil, number, 4 )
			end,
			readBits = function( readBit )
				return readUIntBits( readBit, 4 )
			end,
			writeBits = function( writeBit, data )
				return writeUIntBits( writeBit, data, 4 )
			end
		}, true )

		registerIO( "l", {
			getSize = function()
				return 8
			end,
			read = function( _, binary )
				return readInt( nil, binary, 8 )
			end,
			write = function( _, number )
				return writeInt( nil, number, 8 )
			end,
			readBits = function( readBit )
				return readIntBits( readBit, 8 )
			end,
			writeBits = function( writeBit, data )
				return writeIntBits( writeBit, data, 8 )
			end
		}, true )

		io.l = io.j

		registerIO( "L", {
			getSize = function()
				return 8
			end,
			read = function( _, binary )
				return readUInt( nil, binary, 8 )
			end,
			write = function( _, number )
				return writeUInt( nil, number, 8 )
			end,
			readBits = function( readBit )
				return readUIntBits( readBit, 8 )
			end,
			writeBits = function( writeBit, data )
				return writeUIntBits( writeBit, data, 8 )
			end
		}, true )

		io.L = io.J

		-- https://github.com/ToxicFrog/vstruct/blob/master/io/p.lua
		-- signed fixed point
		-- format is pTOTAL_SIZE,FRACTIONAL_SIZE
		-- Fractional size is in bits, total size in bytes.
		registerIO( "p", {
			getSize = function( count, fraction )
				assert( count, "format requires a bit count" )
				assert( fraction, "format requires a fractional-part size" )

				if tonumber( count, 10 ) and tonumber( fraction, 10 ) then
					-- Check only possible if both values were specified at compile time
					assert( count * 8 >= fraction, "fixed point number has more fractional bits than total bits" )
				end

				return count
			end,
			read = function( _, binary, count, fraction )
				return readInt( nil, binary, count ) / ( 2 ^ fraction )
			end,
			write = function( _, number, count, fraction )
				return writeInt(nil, number * ( 2 ^ fraction ), count)
			end
		}, true )

		-- https://github.com/ToxicFrog/vstruct/blob/master/io/pu.lua
		-- signed fixed point
		-- format is pTOTAL_SIZE,FRACTIONAL_SIZE
		-- Fractional size is in bits, total size in bytes.
		registerIO( "pu", {
			getSize = function( count, fraction )
				assert( count, "format requires a bit count" )
				assert( fraction, "format requires a fractional-part size" )

				if tonumber( count, 10 ) and tonumber( fraction, 10 ) then
					-- Check only possible if both values were specified at compile time
					assert( count * 8 >= fraction, "fixed point number has more fractional bits than total bits" )
				end

				return count
			end,
			read = function( _, binary, count, fraction )
				return readUInt( nil, binary, count ) / ( 2 ^ fraction )
			end,
			write = function( _, number, count, fraction )
				return writeUInt( nil, number * ( 2 ^ fraction ), count )
			end
		}, true )
	end

	-- signed byte
	registerIO( "b", {
		getSize = function()
			return 1
		end,
		read = function( _, str )
			return string_byte( str, 1, 1 ) - 0x80
		end,
		write = function( _, number )
			assert( isint( number ), "signed byte must be an integer" )
			assert( number > -129 and number < 128, "signed byte overflow" )
			return string_char( number + 0x80 )
		end,
		readBits = function( readBit, size )
			return readUIntBits( readBit, size ) - ( ( 2 ^ size ) * 0.5 )
		end,
		writeBits = function( writeBit, data, size )
			return writeUIntBits( writeBit, data + ( ( 2 ^ size ) * 0.5 ), size )
		end
	}, true )

	-- unsigned byte
	registerIO( "B", {
		getSize = function()
			return 1
		end,
		read = function( _, str )
			return string_byte( str, 1, 1 )
		end,
		write = function( _, number )
			assert( isuint( number ), "unsigned byte must be an unsigned integer" )
			assert( number > 0 and number < 256, "unsigned byte overflow" )
			return string_char( number )
		end,
		readBits = readUIntBits,
		writeBits = writeUIntBits
	}, true )

	-- https://github.com/ToxicFrog/vstruct/blob/master/io/b.lua
	-- boolean
	registerIO( "o", {
		read = function( _, buffer )
			return string_match( buffer, "%Z" ) and true or false
		end,
		readBits = function( readBit, size )
			local number = 0
			for _ = 1, size do
				number = number + readBit()
			end

			return number > 0
		end,
		write = function( _, data, size )
			return writeUInt( nil, data and 1 or 0, size )
		end,
		writeBits = function( writeBit, data, size )
			for _ = 1, size, 1 do
				writeBit( data and 1 or 0 )
			end
		end
	}, true )

	-- https://github.com/ToxicFrog/vstruct/blob/master/io/s.lua
	-- fixed length strings
	local function writeString( _, data, size )
		local length = string_len( data )
		if size == nil then size = length end

		if size > length then
			data = data .. string_rep( "\0", size - length )
		end

		return string_sub( data, 1, size )
	end

	local readString
	do

		function readString( fileDescriptor, binary, size )
			if binary then
				assert( string_len( binary ) == size, "length of buffer does not match length of string format" )
				return binary
			else
				return fileDescriptor:read( size or "*a" )
			end
		end

		registerIO( "c", {
			getSize = defaultSize,
			read = readString,
			write = writeString
		}, true )

		-- https://github.com/ToxicFrog/vstruct/blob/master/io/x.lua
		-- skip/pad
		registerIO( "x", {
			read = function( fileDescriptor, binary, size )
				readString( fileDescriptor, binary, size )
			end,
			readBits = function( readBit, size )
				for _ = 1, size do
					readBit()
				end
			end,
			write = function( _, __, size, value )
				return string_rep( string_char( value or 0 ), size )
			end,
			writeBits = function( writeBit, _, size, value )
				if value == nil then value = 0 end

				assert( value == 0 or value == 1, "value must be 0 or 1" )

				for _ = 1, size do
					writeBit( value )
				end
			end
		} )

	end

	-- https://github.com/ToxicFrog/vstruct/blob/master/io/c.lua
	-- counted strings
	registerIO( "s", {
		getSize = function( size )
			if size then
				assert( is_number( size ), "size must be a number" )
				assert( size ~= 0, "size must be greater than 0" )
			end
		end,
		read = function( fileDescriptor, _, size )
			if size == nil then size = 1 end

			-- assert( size, "size is required for counted strings" )
			local length = readUInt( nil, fileDescriptor:read( size ), size )
			if length == 0 then
				return ""
			else
				return fileDescriptor:read( length )
			end
		end,
		write = function( _, data, size )
			return writeUInt( nil, string_len( data ), size or 1 ) .. writeString( nil, data )
		end
	}, true )

	registerIO( "z", {
		getSize = function( size )
			return tonumber( size, 10 )
		end,
		read = function( fileDescriptor, str, size, csize )
			if csize == nil then csize = 1 end

			local null = string_rep( "\0", csize )

			-- read exactly that many characters, then strip the null termination
			if size then
				str = readString( fileDescriptor, str, size )

				local length = 0

				repeat
					---@diagnostic disable-next-line: cast-local-type
					length = string_find( str, null, length + 1, true )
				until length == nil or ( ( length - 1 ) % csize ) == 0

				return string_sub( str, 1, ( length or 0 ) - 1 )
			end

			-- this is where it gets ugly: the size wasn't specified, so we need to
			-- read (csize) bytes at a time looking for the null terminator
			local chars, length = {}, 0

			local c = fileDescriptor:read( csize )
			while c and c ~= null do
				length = length + 1
				chars[ length ] = c
				c = fileDescriptor:read( csize )
			end

			return table_concat( chars, "", 1, length )
		end,
		White = function( _, str, size, csize )
			if csize == nil then csize = 1 end
			if size == nil then size = string_len(str) + csize end

			assert( ( size % csize ) == 0, "string length is not a multiple of character size" )

			-- truncate to field size
			if string_len( str ) >= size then
				str = string_sub( str, 1, size - csize )
			end

			return writeString( nil, str .. string_rep( "\0", csize ), size )
		end
	}, true )

	-- https://github.com/ToxicFrog/vstruct/blob/master/io/m.lua
	-- bitmasks
	local function readBitmask( _, binary, size )
		if size == nil then size = string_len( binary ) end

		local mask, length = {}, 0
		if endianness_isBig() then
			for index = size, 1, -1 do
				local byte = string_byte( binary, index, index )
				for _ = 1, 8 do
					length = length + 1
					mask[ length ] = ( 2 % byte ) == 1
					byte = math_floor( byte / 2 )
				end
			end

			return mask
		else
			for index = 1, size, 1 do
				local byte = string_byte( binary, index, index )
				for _ = 1, 8 do
					length = length + 1
					mask[ length ] = ( 2 % byte ) == 1
					byte = math_floor( byte / 2 )
				end
			end

			return mask
		end
	end

	local function writeBitmask( _, bits, size )
		local buffer, length = {}, 0
		if endianness_isBig() then
			for index = size * 8, 1, -8 do
				length = length + 1
				buffer[ length ] = implode( bits, 8, index - 1 )
			end

			return writeString( nil, string_char( table_unpack( buffer, 1, length ) ), size )
		else
			for index = 1, size * 8, 8 do
				length = length + 1
				buffer[ length ] = implode( bits, 8, index - 1 )
			end

			return writeString( nil, string_char( table_unpack( buffer, 1, length ) ), size )
		end
	end

	registerIO( "m", {
		read = readBitmask,
		readBits = function( readBit, size )
			local mask = {}
			for index = 1, size, 1 do
				mask[ index ] = readBit() == 1
			end

			return mask
		end,
		write = writeBitmask,
		writeBits = function( writeBit, data, size )
			for index = 1, size, 1 do
				writeBit( data[ index ] and 1 or 0 )
			end
		end
	}, true )

	-- https://github.com/ToxicFrog/vstruct/blob/master/io/f.lua
	-- IEEE floating point floats, doubles and quads
	do

		local math_inf, math_nan, math_isnegative, math_frexp, math_ldexp = math.inf, math.nan, math.isnegative, math.frexp, math.ldexp

		-- float
		do

			-- constants
			local c0 = 2 ^ 7
			local c1 = ( 2 ^ 8 ) - 1
			local c2 = 2 ^ 23
			local c3 = 1 - 23 - c0
			local c4 = 2 ^ 22
			local bias = c0 - 1
			local c5 = bias + 1
			local c6 = 2 ^ 24

			registerIO( "f", {
				getSize = function()
					return 4
				end,
				read = function( _, binary )
					local bits = readBitmask( nil, binary, 4 )
					local fraction = implode( bits, 23 )
					local exponent = implode( bits, 8, 23 )
					local sign = bits[ 32 ] and -1 or 1

					if exponent == c1 then
						if fraction == 0 or sign == -1 then
							return sign * math_inf
						else
							return math_nan
						end
					end

					if exponent ~= 0 then
						fraction = fraction + c2
					else
						exponent = 1
					end

					return sign * math_ldexp( fraction, exponent + c3 )
				end,
				write = function( _, float )
					local sign
					if math_isnegative( float ) then
						sign = true
						float = -float
					else
						sign = false
					end

					local exponent, fraction
					if float == math_inf then
						exponent = c5
						fraction = 0
					elseif float ~= float then
						exponent = c5
						fraction = c4
					elseif float == 0 then
						exponent = -bias
						fraction = 0
					else
						fraction, exponent = math_frexp( float )
						local ebs = exponent + bias
						if ebs <= 1 then
							fraction = fraction * ( 2 ^ ( 22 + ebs ) )
							exponent = -bias
						else
							fraction = fraction - 0.5
							exponent = exponent - 1
							fraction = fraction * c6
						end
					end

					local bits = explode( fraction )
					local exponentBits = explode( exponent + bias )
					for index = 1, 8 do
						bits[ 23 + index ] = exponentBits[ index ]
					end

					bits[ 32 ] = sign
					return writeBitmask( nil, bits, 4 )
				end
			}, true )

		end

		-- double
		do

			-- constants
			local c0 = ( 2 ^ 11 ) - 1
			local c1 = 2 ^ 52
			local c2 = 2 ^ 10
			local c3 = 1 - 52 - c2
			local c4 = 2 ^ 51
			local bias = c2 - 1
			local c5 = bias + 1
			local c6 = 2 ^ 53

			registerIO( "d", {
				getSize = function()
					return 8
				end,
				read = function( _, binary )
					local bits = readBitmask( nil, binary, 8 )
					local fraction = implode( bits, 52 )
					local exponent = implode( bits, 11, 52 )
					local sign = bits[ 64 ] and -1 or 1

					if exponent == c0 then
						if fraction == 0 or sign == -1 then
							return sign * math_inf
						else
							return math_nan
						end
					end

					if exponent ~= 0 then
						fraction = fraction + c1
					else
						exponent = 1
					end

					return sign * math_ldexp( fraction, exponent + c3 )
				end,
				write = function( _, double )
					local sign
					if math_isnegative( double ) then
						sign = true
						double = -double
					else
						sign = false
					end

					local exponent, fraction
					if double == math_inf then
						exponent = c5
						fraction = 0
					elseif double ~= double then
						exponent = c5
						fraction = c4
					elseif double == 0 then
						exponent = -bias
						fraction = 0
					else
						fraction, exponent = math_frexp( double )

						local ebs = exponent + bias
						if ebs <= 1 then
							fraction = fraction * ( 2 ^ ( 51 + ebs ) )
							exponent = -bias
						else
							fraction = fraction - 0.5
							exponent = exponent - 1
							fraction = fraction * c6
						end
					end

					local bits = explode( fraction )
					local exponentBits = explode( exponent + bias )
					for index = 1, 11 do
						bits[ 52 + index ] = exponentBits[ index ]
					end

					bits[ 64 ] = sign
					return writeBitmask( nil, bits, 8 )
				end
			}, true )

			io.d = io.n

		end

		-- quad
		do

			-- constants
			local c0 = 2 ^ 14
			local c1 = ( 2 ^ 15 ) - 1
			local c2 = 2 ^ 111
			local c3 = 2 ^ 112
			local c4 = 1 - 112 - c0
			local bias = c0 - 1
			local c5 = bias + 1
			local c6 = 2 ^ 113

			registerIO( "q", {
				getSize = function()
					return 16
				end,
				read = function( _, binary )
					local bits = readBitmask( nil, binary, 16 )
					local fraction = implode( bits, 112 )
					local exponent = implode( bits, 15, 112 )
					local sign = bits[ 128 ] and -1 or 1

					if exponent == c1 then
						if fraction == 0 or sign == -1 then
							return sign * math_inf
						else
							return math_nan
						end
					end

					if exponent ~= 0 then
						fraction = fraction + c3
					else
						exponent = 1
					end

					return sign * math_ldexp( fraction, exponent + c4 )
				end,
				write = function( _, quad )
					local sign
					if math_isnegative( quad ) then
						sign = true
						quad = -quad
					else
						sign = false
					end

					local exponent, fraction
					if quad == math_inf then
						exponent = c5
						fraction = 0
					elseif quad ~= quad then
						exponent = c5
						fraction = c2
					elseif quad == 0 then
						exponent = -bias
						fraction = 0
					else
						fraction, exponent = math_frexp( quad )

						local ebs = exponent + bias
						if ebs <= 1 then
							fraction = fraction * ( 2 ^ ( 111 + ebs ) )
							exponent = -bias
						else
							fraction = fraction - 0.5
							exponent = exponent - 1
							fraction = fraction * c6
						end
					end

					local bits = explode( fraction )
					local exponentBits = explode( exponent + bias )
					for index = 1, 15, 1 do
						bits[ 112 + index ] = exponentBits[ index ]
					end

					bits[ 128 ] = sign
					return writeBitmask( nil, bits, 16 )
				end
			}, true )

		end

	end

end

-- https://github.com/ToxicFrog/vstruct/blob/master/lexer.lua
do

	local lexis, length = {}, 0

	local function addLexer( name, pattern )
		length = length + 1
		lexis[ length ] = {
			name = name,
			pattern = "^" .. pattern
		}
	end

	-- TODO: Make Lexer class

	-- struct.addLexer = addLexer

	addLexer( false, "%s+" )
	addLexer( false, "%-%-[^\n]*" )
	addLexer( "key", "([%a_][%w_.]*):" )
	addLexer( "io", "([-+@<>=])" )
	addLexer( "io", "([%a_]+)" )
	addLexer( "number", "([%d.,]+)" )
	addLexer( "number", "(#[%a_][%w_.]*)" )
	addLexer( "splice", "&(%S+)" )
	addLexer( "{", "%{" )
	addLexer( "}", "%}" )
	addLexer( "(", "%(" )
	addLexer( ")", "%)" )
	addLexer( "*", "%*" )
	addLexer( "[", "%[" )
	addLexer( "]", "%]" )
	addLexer( "|", "%|" )

	function struct.lexer( source )
		local index, hadWhitespace = 1, false
		local function where()
			return string_format( "character %d ('%s')", index, string_sub( source, 1, 4 ) )
		end

		local function find_match()
			for j = 1, length do
				local data = lexis[ j ]
				if string_match( source, data.pattern ) then
					local _, endPos, text = string_find( source, data.pattern )
					return data, endPos, text
				end
			end

			error( string_format( "Lexical error in format string at %s.", where() ) )
		end

		local function eat_whitespace()
			local function aux()
				if #source == 0 then return nil end

				local matched, size = find_match()
				if matched.name then return nil end

				source = string_sub( source, size + 1, string_len( source ) )
				hadWhitespace = true
				index = index + size

				return aux()
			end

			hadWhitespace = false
			return aux()
		end

		local function whitespace()
			return hadWhitespace
		end

		local function next()
			eat_whitespace()

			if #source == 0 then
				return {
					text = nil,
					type = "EOF"
				}
			end

			local data, size, text = find_match()
			source = string_sub( source, size + 1, string_len( source ) )
			index = index + size

			return {
				text = text,
				type = data.name
			}
		end

		local function peek()
			eat_whitespace()

			if #source == 0 then
				return {
					text = nil,
					type = "EOF"
				}
			end

			local data, _, text = find_match()

			return {
				text = text,
				type = data.name
			}
		end

		return {
			next = next,
			peek = peek,
			where = where,
			whitespace = whitespace,
			tokens = function() return next end
		}
	end

end

-- https://github.com/ToxicFrog/vstruct/blob/master/ast.lua
local ast = {}
struct.ast = ast

do

	local string_gmatch = string.gmatch

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/Node.lua


	---@class gpm.std.struct.ast.Node: gpm.std.Object
	---@field __class gpm.std.struct.ast.NodeClass
	---@field size number
	local Node = class.base( "Node" )

	---@protected
	function Node:__init()
		self.size = 0
	end

	---@param self any
	---@param node any
	function Node_append( self, node )
		self[ #self + 1 ] = node
		self.size = self.size + ( node.size or 0 )
	end

	Node.append = Node_append

	---@param fileDescriptor any
	---@param data any
	local function Node_read( self, fileDescriptor, data )
		for i = 1, #self do
			self[ i ]:read( fileDescriptor, data )
		end
	end

	Node.read = Node_read

	---@param bits any
	---@param data table?
	local function Node_readBits( self, bits, data )
		for i = 1, #self, 1 do
			self[ i ]:readBits( bits, data )
		end
	end

	Node.readBits = Node_readBits

	---@param fileDescriptor any
	---@param context any
	function Node:write( fileDescriptor, context )
		for i = 1, #self, 1 do
			self[ i ]:write( fileDescriptor, context )
		end
	end

	---@param bits any
	---@param context any
	local function Node_writeBits( self, bits, context )
		for i = 1, #self, 1 do
			self[ i ]:writeBits( bits, context )
		end
	end

	Node.writeBits = Node_writeBits

	---@class gpm.std.struct.ast.NodeClass: gpm.std.struct.ast.Node
	---@field __base gpm.std.struct.ast.Node
	---@overload fun(): gpm.std.struct.ast.Node
	local NodeClass = class.create( Node )
	ast.Node = NodeClass

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/List.lua


	---@class gpm.std.struct.ast.List: gpm.std.Object
	---@field __class gpm.std.struct.ast.ListClass
	---@field __parent gpm.std.struct.ast.Node
	---@field tag string?
	local List = class.base( "List", NodeClass )
	List.append = Node_append

	---@class gpm.std.struct.ast.ListClass: gpm.std.struct.ast.List
	---@field __base gpm.std.struct.ast.List
	---@overload fun(): gpm.std.struct.ast.List
	local ListClass = class.create( List )
	ast.List = ListClass

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/Table.lua


	---@class gpm.std.struct.ast.Table: gpm.std.Object
	---@field __class gpm.std.struct.ast.TableClass
	---@field __parent gpm.std.struct.ast.Node
	local Table = class.base( "Table", NodeClass )
	Table.append = Node_append

	---@param fileDescriptor any
	function Table:read( fileDescriptor )
		local tbl = {}
		Node_read( self, fileDescriptor, tbl )
		return tbl
	end

	---@param bits any
	function Table:readBits( bits )
		local tbl = {}
		Node_readBits( self, bits, tbl )
		return tbl
	end

	---@class gpm.std.struct.ast.TableClass: gpm.std.struct.ast.Table
	---@field __base gpm.std.struct.ast.Table
	---@overload fun(): gpm.std.struct.ast.Table
	local TableClass = class.create( Table )
	ast.Table = TableClass

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/Number.lua


	---@class gpm.std.struct.ast.Number: gpm.std.Object
	---@field __class gpm.std.struct.ast.NumberClass
	---@field __parent gpm.std.struct.ast.Node
	local Number = class.base( "Number", NodeClass )

	---@param str string
	---@protected
	function Number:__init( str )
		if string_match( str, "^#" ) then
			self.key = string_sub( str, 2, string_len( str ) )
		else
			self.value = assert( tonumber( str, 10 ), "numeric constant '" .. str .. "' is not a number" )
		end
	end

	--- comment
	---@param data table?
	---@return any
	function Number:get( data )
		local value = self.value
		if value then
			return value
		elseif data then
			local key = self.key
			for name in string_gmatch( key, "([^%.]+)%." ) do
				if data[ name ] == nil then break end
				data = data[ name ]
			end

			value = data[ string_match( key, "[^%.]+$" ) ]
			assert( value ~= nil, "backreferenced field '" .. key .. "' has not been read yet" )
			assert( is_number( value ), "backreferenced field '" .. key .. "' is not a numeric type" )
			return value
		end

		return true
	end

	--- A node that holds either a number, or a reference to an already-read, named field which contains a number.
	---@class gpm.std.struct.ast.NumberClass: gpm.std.struct.ast.Number
	---@field __base gpm.std.struct.ast.Number
	---@overload fun( str: string ): gpm.std.struct.ast.Number
	local NumberClass = class.create( Number )
	ast.Number = NumberClass

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/Root.lua


	---@class gpm.std.struct.ast.Root: gpm.std.Object
	---@field __class gpm.std.struct.ast.RootClass
	---@field __parent gpm.std.struct.ast.Node
	---@field size number
	local Root = class.base( "Root", NodeClass )

	---@param children any
	---@protected
	function Root:__init( children )
		self[ 1 ] = children
		self.size = children.size
	end

	function Root:read( fileDescriptor, data )
		endianness_revert()
		self[ 1 ]:read( fileDescriptor, data )
		return data
	end

	function Root:write( fileDescriptor, data )
		endianness_revert()
		self[ 1 ]:write( fileDescriptor, { data = data, n = 1 } )
	end

	---@class gpm.std.struct.ast.RootClass: gpm.std.struct.ast.Root
	---@field __base gpm.std.struct.ast.Root
	---@overload fun( children: any ): gpm.std.struct.ast.Root
	local RootClass = class.create( Root )
	ast.Root = RootClass

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/Repeat.lua


	---@class gpm.std.struct.ast.Repeat: gpm.std.Object
	---@field __class gpm.std.struct.ast.RepeatClass
	---@field __parent gpm.std.struct.ast.Node
	local Repeat = class.base( "Repeat", NodeClass )

	---@param count gpm.std.struct.ast.Number
	---@param child gpm.std.struct.ast.Root | gpm.std.struct.ast.Node
	---@protected
	function Repeat:__init( count, child )
		self.count = count
		self.child = child

		if count.value and child.size then
			self.size = count:get( nil ) * child.size
		else
			-- Child has runtime-deferred size, or count is a backreference
			self.size = nil
		end
	end

	---@param fileDescriptor any
	---@param data table?
	function Repeat:read( fileDescriptor, data )
		local child = self.child
		for _ = 1, self.count:get( data ), 1 do
			child:read( fileDescriptor, data )
		end
	end

	---@param bits any
	---@param data table?
	function Repeat:readBits( bits, data )
		local child = self.child
		for _ = 1, self.count:get( data ), 1 do
			child:readBits( bits, data )
		end
	end

	---@param fileDescriptor any
	---@param data any
	function Repeat:write( fileDescriptor, data )
		local child = self.child
		for _ = 1, self.count:get( data.data ), 1 do
			child:write( fileDescriptor, data )
		end
	end

	function Repeat:writeBits( bits, data )
		local child = self.child
		for _ = 1, self.count:get( data.data ), 1 do
			child:writeBits( bits, data )
		end
	end

	---@class gpm.std.struct.ast.RepeatClass: gpm.std.struct.ast.Repeat
	---@field __base gpm.std.struct.ast.Repeat
	---@overload fun( children: any ): gpm.std.struct.ast.Repeat
	local RepeatClass = class.create( Repeat )
	ast.Repeat = RepeatClass

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/Name.lua
	local NameClass
	do

		local tostring = std.tostring

		local function put( data, key, value )
			if key then
				for name in string_gmatch( key, "([^%.]+)%." ) do
					data = data[ name ]
					if data == nil then data = {} end
				end

				data[ string_match( key, "[^%.]+$" ) ] = value
			else
				data[ #data + 1 ] = value
			end
		end

		-- Return a new subcontext containing only the data referenced by the key.
		-- `parent` points to the parent context, so that backreferences can be resolved.
		local function get( context, key )
			local value
			if key then
				local data = context.data
				for name in string_gmatch( key, "([^%.]+)%." ) do
					if data[ name ] == nil then break end
					data = data[ name ]
				end

				value = data[ string_match( key, "[^%.]+$" ) ]
			else
				local n = context.n
				value = context.data[ n ]
				context.n = n + 1
			end

			assert( value ~= nil, "bad input while writing: no value for key " .. tostring( key or context.n - 1 ) )

			return {
				parent = context,
				data = value,
				n = 1
			}
		end


		---@class gpm.std.struct.ast.Name: gpm.std.Object
		---@field __class gpm.std.struct.ast.NameClass
		---@field __parent gpm.std.struct.ast.Node
		local Name = class.base( "Name", NodeClass )

		---@param key any?
		---@param child any
		function Name:__init( key, child )
			self.key = key
			self.child = child
			self.size = child.size
		end

		---@param fileDescriptor any
		---@param data any
		function Name:read( fileDescriptor, data )
			return put( data, self.key, self.child:read( fileDescriptor, data ) )
		end

		---@param bits any
		---@param data any
		function Name:readBits( bits, data )
			return put( data, self.key, self.child:readBits( bits, data ) )
		end

		function Name:write( fileDescriptor, context )
			return self.child:write( fileDescriptor, get( context, self.key ) )
		end

		function Name:writeBits( bits, context )
			return self.child:writeBits( bits, get( context, self.key ) )
		end

		---@class gpm.std.struct.ast.NameClass: gpm.std.struct.ast.Name
		---@field __base gpm.std.struct.ast.Name
		---@overload fun( key: any?, child: any ): gpm.std.struct.ast.Name
		NameClass = class.create( Name )

	end

	ast.Name = NameClass

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/Bitpack.lua
	local BitpackClass
	do

		-- return an iterator over the individual bits in buffer
		local function biterator( binary )
			local byte_count = string_len( binary )
			local data = { string_byte( binary, 1, byte_count ) }

			local isBig = endianness_isBig()
			local index = isBig and 1 or byte_count
			local delta = isBig and 1 or -1
			local bit0 = 7

			return function()
				local value = 2 % math_floor( data[ index ] / ( 2 ^ bit0 ) )
				bit0 = ( bit0 - 1 ) % 8

				-- we just wrapped around
				if bit0 == 7 then
					index = index + delta
				end

				return value
			end
		end

		local function bitpacker( buffer, size )
			for index = 1, size, 1 do
				buffer[ index ] = 0
			end

			local isBig = endianness_isBig()
			local index = isBig and 1 or size
			local delta = isBig and 1 or -1
			local bit0 = 7

			return function( byte1 )
				buffer[ index ] = buffer[ index ] + ( byte1 * ( 2 ^ bit0 ) )
				bit0 = ( bit0 - 1 ) % 8

				-- we just wrapped around
				if bit0 == 7 then
					index = index + delta
				end
			end
		end


		---@class gpm.std.struct.ast.Bitpack: gpm.std.Object
		---@field __class gpm.std.struct.ast.BitpackClass
		---@field __parent gpm.std.struct.ast.Node
		local Bitpack = class.base( "Bitpack", NodeClass )
		Bitpack.append = Node_append

		---@param size any
		---@protected
		function Bitpack:__init( size )
			self.total_size = size
			self.size = 0
		end

		function Bitpack:finalize()
			-- children are getting added with size in bits, not bytes
			local size = self.size
			size = size * 0.125

			assert( size, "bitpacks cannot contain variable-width fields" )
			assert( size == self.total_size, "bitpack contents do not match bitpack size: " .. size .. " ~= " .. self.total_size )
			self.size = size
		end

		function Bitpack:read( fileDescriptor, data )
			return Node_readBits( self, biterator( fileDescriptor:read( self.size ) ), data )
		end

		function Bitpack:write( fileDescriptor, context )
			local buffer = {}
			Node_writeBits( self, bitpacker( buffer, self.size ), context )
			return fileDescriptor:write( string_char( table_unpack( buffer ) ) )
		end

		---@class gpm.std.struct.ast.BitpackClass: gpm.std.struct.ast.Bitpack
		---@field __base gpm.std.struct.ast.Bitpack
		---@overload fun( size: any ): gpm.std.struct.ast.Bitpack
		BitpackClass = class.create( Bitpack )
		ast.Bitpack = BitpackClass

	end

	-- https://github.com/ToxicFrog/vstruct/blob/master/ast/IO.lua


	---@class gpm.std.struct.ast.IO: gpm.std.Object
	---@field __class gpm.std.struct.ast.IOClass
	---@field __parent gpm.std.struct.ast.Node
	local IO = class.base( "IO", NodeClass )

	---@param name any
	---@param args any
	---@protected
	function IO:__init( name, args )
		local argv, n = { has_backrefs = false }, 0
		self.name = name

		if args then
			for arg in string_gmatch( args .. ",", "([^,]*)," ) do
				n = n + 1

				if arg == "" then
					argv[ n ] = nil
				else
					local number = tonumber( arg, 10 )
					if number then
						argv[ n ] = number
					elseif string_match( arg, "^#[%a_][%w_.]*$" ) then
						argv.has_backrefs = true
						argv[ n ] = NumberClass( arg )
					else
						argv[ n ] = arg
					end
				end
			end
		end

		self.size = io[ name ].getSize( argv[ 1 ] )
		self.hasvalue = io[ name ].HasValue()
		self.argv = argv
		argv.n = n
	end

	function IO:read( fileDescriptor, data )
		local buffer

		local size = self.size
		if size and size > 0 then
			buffer = fileDescriptor:read( size )
			assert( buffer and #buffer == size, "attempt to read past end of buffer in format " .. self.name )
		end

		return io[ self.name ].read( fileDescriptor, buffer, self:getArgv( data ) )
	end

	function IO:readBits( bits, data )
		return io[ self.name ].readBits( bits, self:getArgv( data ) )
	end

	function IO:write( fileDescriptor, context )
		local buffer = io[ self.name ].write( fileDescriptor, context.data, self:GetArgvContext( context ) )
		if buffer then
			fileDescriptor:write( buffer )
		end
	end

	function IO:writeBits( fileDescriptor, bits, context )
		local buffer = io[ self.name ].writeBits( bits, context.data, self:GetArgvContext( context ) )
		if buffer then
			fileDescriptor:write( buffer )
		end
	end

	function IO:getArgv( data )
		local argv = self.argv
		local n = argv.n

		-- If backreferences were involved, we have to try to resolve them.
		if argv.has_backrefs then
			local buffer = {}
			for index = 1, n, 1 do
				if argv[ index ] then
					buffer[ index ] = argv[ index ]:Get( data )
				end
			end

			return table_unpack( buffer, 1, n )
		else
			-- Usually the contents were determined at compile-time and we can just table_unpack it as is.
			return table_unpack( argv, 1, n )
		end
	end

	function IO:GetArgvContext( context )
		return self:getArgv( ( context.parent or context ).data )
	end

	---@class gpm.std.struct.ast.IOClass: gpm.std.struct.ast.IO
	---@field __base gpm.std.struct.ast.IO
	---@overload fun( name: any, args: any ): gpm.std.struct.ast.IO
	local IOClass = class.create( IO )
	ast.IO = IOClass

	local ast_iterator
	do

		-- used by the rest of the parser to report syntax errors
		local function ast_error( lex, expected )
			error( "parsing format string at " .. lex.where() .. ": expected " .. expected .. ", got " .. lex.peek().type )
		end

		ast.error = ast_error

		local function ast_require( lex, typeName )
			local tbl = lex.next()
			if tbl.type ~= typeName then
				ast_error( lex, typeName )
			end

			return tbl
		end

		ast.require = ast_require

		local ast_next

		local function ast_next_until( lex, typeName )
			return function()
				local tokType = lex.peek().type
				if tokType == "EOF" then
					ast_error( lex, typeName )
				end

				if tokType ~= typeName then
					return ast_next( lex )
				end
			end
		end

		ast.next_until = ast_next_until

		local function ast_repetition( lex )
			local count = NumberClass( lex.next().text )
			ast_require( lex, "*" )
			return RepeatClass( count, ast_next( lex ) )
		end

		ast.repetition = ast_repetition

		local function ast_group( lex )
			ast_require( lex, "(" )

			local group = ListClass()
			group.tag = "group"

			for value in ast_next_until( lex, ")" ) do
				group:append( value )
			end

			ast_require( lex, ")" )
			return group
		end

		ast.group = ast_group

		local ast_table, ast_io, ast_key
		do

			local function ast_raw_table( lex )
				ast_require( lex, "{" )

				local group = TableClass()
				for value in ast_next_until( lex, "}" ) do
					group:append( value )
				end

				ast_require( lex, "}" )
				return group
			end

			ast.raw_table = ast_raw_table

			function ast_table( lex )
				return NameClass( nil, ast_raw_table( lex ) )
			end

			ast.table = ast_table

			local function ast_raw_io( lex )
				local name = lex.next().text
				local value = lex.peek()
				if value and value.type == "number" and not lex.whitespace() then
					return IOClass( name, lex.next().text )
				else
					return IOClass( name, nil )
				end
			end

			ast.raw_io = ast_raw_io

			function ast_io( lex )
				local value = ast_raw_io( lex )
				if value.hasvalue then
					return NameClass( nil, value )
				else
					return value
				end
			end

			ast.io = ast_io

			function ast_key( lex )
				local name = lex.next().text
				local type_name = lex.peek().type
				if type_name == "io" then
					local value = ast_raw_io( lex )
					if value.hasvalue then
						return NameClass( name, value )
					end

					ast_error( lex, "value (io specifier or table) - format '" .. name .. "' has no value" )
				elseif type_name == "{" then
					return NameClass( name, ast_raw_table( lex ) )
				end

				ast_error( lex, "value (io specifier or table)" )
			end

			ast.key = ast_key

		end

		local function ast_bitpack( lex )
			ast_require( lex, "[" )

			local bitpack = BitpackClass( tonumber( ast_require( lex, "number" ).text, 10 ) )
			ast_require( lex, "|" )

			for value in ast_next_until( lex, "]" ) do
				bitpack:append( value )
			end

			ast_require( lex, "]" )
			bitpack:finalize()
			return bitpack
		end

		ast.bitpack = ast_bitpack

		local function ast_control( lex )
			local name = lex.next().text
			ast_require( lex, ":" )
			return NameClass( name, ast_next( lex ) )
		end

		ast.control = ast_control

		local function ast_splice( lex )
			local name = lex.next().text

			local root = registry[ name ]
			if root then
				return root[ 1 ]
			end

			error( "attempt to splice in format '" .. name .. "', which is not registered" )
		end

		ast.splice = ast_splice

		function ast_next( lex )
			local type_name = lex.peek().type
			if type_name == "EOF" then
				return nil
			elseif type_name == "(" then
				return ast_group( lex )
			elseif type_name == "{" then
				return ast_table( lex )
			elseif type_name == "[" then
				return ast_bitpack( lex )
			elseif type_name == "io" then
				return ast_io( lex )
			elseif type_name == "key" then
				return ast_key( lex )
			elseif type_name == "number" then
				return ast_repetition( lex )
			elseif type_name == "control" then
				return ast_control( lex )
			elseif type_name == "splice" then
				return ast_splice( lex )
			else
				ast_error( lex, "'(', '{', '[', name, number, control, or io specifier" )
			end
		end

		ast.next = ast_next

		function ast_iterator( lex )
			return function()
				return ast_next( lex )
			end
		end

		ast.iterator = ast_iterator

	end

	do

		local struct_lexer = struct.lexer

		function ast.parse( source )
			local root = ListClass()
			for node in ast_iterator( struct_lexer( source ) ) do
				root:append( node )
			end

			return RootClass( root )
		end

	end

end

---@class gpm.std.struct.api
local api = {}
struct.api = api

-- https://github.com/ToxicFrog/vstruct/blob/master/api.lua
do

	local wrapFileDescriptor
	do

		local Cursor = struct.Cursor
		local is_string = is.string

		---@param fileDescriptor string | gpm.std.struct.Cursor
		---@return gpm.std.struct.Cursor
		function wrapFileDescriptor( fileDescriptor )
			if is_string( fileDescriptor ) then
				---@cast fileDescriptor string
				return Cursor( fileDescriptor )
			end

			---@cast fileDescriptor gpm.std.struct.Cursor

			-- local name = type( fileDescriptor )
			-- if name == "File" or name == "File: Legacy" then -- TODO: Rewrite this crap
			-- 	return Cursor( fileDescriptor:read(), fileDescriptor:Close() )
			-- end

			return fileDescriptor
		end

		api.warpFileDescriptor = wrapFileDescriptor

	end

	local is_cursor = is.cursor
	-- local is_table = is.table

	---comment
	---@param fileDescriptor any
	---@return string
	local function unwrapFileDescriptor( fileDescriptor )
		if is_cursor( fileDescriptor ) then
			return fileDescriptor:flush()
		else
			return fileDescriptor
		end
	end

	api.UnwrapFileDescriptor = unwrapFileDescriptor

	---comment
	---@param obj gpm.std.struct.Object
	---@param fileDescriptor string | gpm.std.struct.Cursor | nil
	---@param data table?
	---@return table
	function api.read( obj, fileDescriptor, data )
		if fileDescriptor == nil then fileDescriptor = "" end
		if data == nil then data = {} end

		fileDescriptor = wrapFileDescriptor( fileDescriptor )

		if not is_cursor( fileDescriptor ) then
			error( "bad argument #2 to 'read' (file or string expected, got " .. type( fileDescriptor ) .. ")", 3 )
		end

		return obj.ast:read( fileDescriptor, data )
	end

	--- comment
	---@param obj gpm.std.struct.Object
	---@param fileDescriptor string | gpm.std.struct.Cursor | nil
	---@param data table?
	---@return string
	function api.write( obj, fileDescriptor, data )
		if fileDescriptor and not data then
			---@cast fileDescriptor table
			---@cast data nil
			data, fileDescriptor = fileDescriptor, nil
		end

		if fileDescriptor == nil then
			fileDescriptor = ""
		end

		fileDescriptor = wrapFileDescriptor( fileDescriptor )

		if not is_cursor( fileDescriptor ) then
			error( "bad argument #2 to 'write' (File or string expected, got " .. type( fileDescriptor ) .. ")", 3 )
		end

		-- if not is_table( data ) then
		-- 	error( "bad argument #3 to 'write' (table expected, got " .. type( data ) .. ")", 3 )
		-- end

		obj.ast:write( fileDescriptor, data )
		return unwrapFileDescriptor( fileDescriptor )
	end

	---
	---@param obj gpm.std.struct.Object
	---@param fileDescriptor string | gpm.std.struct.Cursor | nil
	---@param unpacked boolean?
	---@return function
	function api.records( obj, fileDescriptor, unpacked )
		if fileDescriptor == nil then
			fileDescriptor = ""
		end

		fileDescriptor = wrapFileDescriptor( fileDescriptor )

		if not is_cursor( fileDescriptor ) then
			error( "bad argument #2 to 'Records' (file or string expected, got " .. type( fileDescriptor ) .. ")", 3 )
		end

		return function()
			if fileDescriptor:read( 0 ) then
				if unpacked then
					return table_unpack( obj:read( fileDescriptor ) )
				else
					return obj:read( fileDescriptor )
				end
			end
		end
	end

	---comment
	---@param obj gpm.std.struct.Object
	---@return number?
	function api.sizeOf( obj )
		return obj.ast.size
	end

	do

		local ast_parse = ast.parse

		local cache = {}

		---@class gpm.std.struct.Object: gpm.std.Object
		---@field __class gpm.std.struct.ObjectClass
		---@field source string
		---@field ast gpm.std.struct.ast.Root
		local Object = class.base( "Object" )

		Object.read = api.read
		Object.write = api.write
		Object.sizeOf = api.sizeOf
		Object.records = api.records

		---@param fmt any
		---@param root gpm.std.struct.ast.Root
		---@protected
		function Object:__init( fmt, root )
			self.source = fmt
			self.ast = root
		end

		---@class gpm.std.struct.ObjectClass: gpm.std.struct.Object
		---@field __base gpm.std.struct.Object
		---@overload fun( fmt: string, root: gpm.std.struct.ast.Root ): Object
		local ObjectClass = class.create( Object )
		struct.Object = ObjectClass


		-- local console_variable = std.console.Variable( "gpm_struct_cache", "0", )
		-- local struct_cache = console_variable.create()

		---comment
		---@param name string?
		---@param fmt string
		---@return table
		function api.compile( name, fmt )
			local obj, root = cache[ fmt ], nil
			if obj then
				root = obj.ast
			else
				root = ast_parse( fmt )
				obj = ObjectClass( fmt, root )
				cache[ fmt ] = obj
			end

			if name then
				registry[ name ] = root
			end

			return obj
		end

	end

end

-- https://github.com/ToxicFrog/vstruct/blob/master/init.lua
do

	local struct_records
	do

		local api_compile, api_warpFileDescriptor = api.compile, api.warpFileDescriptor

		--- Given a format string, a buffer or file, and an optional third argument,
		--- read data from the buffer or file according to the format string.
		---@param fmt string
		---@param ... any -- TODO: idk
		---@return table
		local function read( fmt, ... )
			return api_compile( nil, fmt ):read( ... )
		end

		struct.read = read

		--- Given a format string, an optional file-like, and a table of data,
		--- write data into the file-like (or create and return a string of packed data)
		--- according to the format string.
		---@param fmt string
		---@param ... unknown
		---@return unknown
		function struct.write( fmt, ... )
			return api_compile( nil, fmt ):write( ... )
		end

		--- Return the size on disk of the structure described by the format string.
		---
		--- If it can't be determined statically, returns nil.
		---@param fmt string
		---@return number?
		function struct.sizeOf( fmt )
			return api_compile( nil, fmt ).ast.size
		end

		---comment
		---@param ... unknown
		---@param ... unknown
		function struct.readValues( ... )
			return table_unpack( read( ... ) )
		end

		--- Given a format string, compile it and return a table containing
		--- the original source and the read/write functions derived from it.
		---@param name string
		---@param fmt string?
		---@return table
		function struct.compile( name, fmt )
			if fmt then
				return api_compile( name, fmt )
			else
				return api_compile( nil, name )
			end
		end

		--- Takes the same arguments as `struct.unpack`.
		---
		--- Returns an iterator over the input, repeatedly calling read until it runs out of data.
		---@param fmt string
		---@param fileDescriptor any
		---@param unpacked boolean?
		---@return function
		function struct_records( fmt, fileDescriptor, unpacked )
			return api_compile( nil, fmt ):records( api_warpFileDescriptor( fileDescriptor ), unpacked )
		end

		struct.records = struct_records

	end

	--- Returns an array containing the results of struct.records, with an optional starting index.
	---@param fmt string
	---@param fileDescriptor any
	---@param length number?
	---@return table
	function struct.array( fmt, fileDescriptor, length )
		if length == nil then length = 1 end

		local lst = {}
		for record in struct_records( fmt, fileDescriptor ) do
			lst[ length ] = record
			length = length + 1
		end

		return lst
	end
end

return struct
