local std = _G.gpm.std

local binary = std.crypto.binary
local string = std.string

local string_len = string.len

--- [SHARED AND MENU]
---
--- The byte writer object.
---@alias ByteWriter gpm.std.crypto.ByteWriter
---@class gpm.std.crypto.ByteWriter: gpm.std.Object
---@field __class gpm.std.crypto.ByteWriterClass
local ByteWriter = std.class.base( "ByteWriter" )

---@protected
function ByteWriter:__tostring()
	return string.format( "ByteWriter: %p [%d/%d]", self, self[ 2 ], self[ 0 ] )
end

---@protected
function ByteWriter:__init( base )
	if base == nil then
		self[ 0 ], self[ 1 ], self[ 2 ] = 0, "", 0
	else
		local size = string_len( base )
		self[ 0 ], self[ 1 ], self[ 2 ] = size, base, size
	end

	self[ 3 ], self[ 4 ] = {}, 0
end

do

	local string_rep = string.rep

	do

		local table_concat = std.table.concat
		local string_sub = string.sub

		--- [SHARED AND MENU]
		---
		--- Flushes the writer.
		---@return string data The bynary data.
		---@return integer size The size of the data.
		function ByteWriter:flush()
			local buffer_size = self[ 4 ]
			self[ 4 ] = 0

			if buffer_size == 0 then
				return self[ 1 ], self[ 0 ]
			end

			local old_data, size, pointer = self[ 1 ], self[ 0 ], self[ 2 ]
			if pointer > size then
				old_data, size = old_data .. string_rep( "\0", pointer - size ), pointer
			end

			local content = table_concat( self[ 3 ], "", 1, buffer_size )
			local content_size = string_len( content )
			self[ 3 ] = {}

			local new_data = string_sub( old_data, 1, pointer ) .. content .. string_sub( old_data, pointer + content_size + 1, size )
			local new_size = string_len( new_data )

			self[ 1 ], self[ 0 ] = new_data, new_size
			self[ 2 ] = pointer + content_size

			return new_data, new_size
		end

	end

	--- [SHARED AND MENU]
	---
	--- Skips the specified number of bytes.
	---@param offset integer The number of bytes to skip.
	---@return integer position The new position.
	function ByteWriter:skip( offset )
		local pointer, size = self[ 2 ], self[ 0 ]
		local new_position = pointer + offset

		if new_position > size then
			self:write( string_rep( "\0", new_position - size ) )
		end

		return self:seek( new_position )
	end

end

--- [SHARED AND MENU]
---
--- Returns the current position of the writer.
---@return integer position The current position.
function ByteWriter:tell()
	self:flush()
	return self[ 2 ]
end

--- [SHARED AND MENU]
---
--- Returns the size of the writer data in bytes.
---@return integer size The size of data in bytes.
function ByteWriter:size()
	self:flush()
	return self[ 0 ]
end

--- [SHARED AND MENU]
---
--- Sets the current position of the writer.
---@param position? integer The position to set.
---@return integer new_position The new position.
function ByteWriter:seek( position )
	self:flush()

	if position == nil then
		position = 0
	elseif position < 0 then
		local size = self[ 0 ]
		while position < 0 do
			position = position + size + 1
		end
	end

	self[ 2 ] = position
	return position
end

--- [SHARED AND MENU]
---
--- Writes the specified string to the writer.
---@param str string The string to write.
function ByteWriter:write( str )
	local buffer_size = self[ 4 ] + 1
	self[ 3 ][ buffer_size ] = str
	self[ 4 ] = buffer_size
end

do

	local data = binary.data

	do

		local write = data.writeFixed

		--- [SHARED AND MENU]
		---
		--- Writes a fixed-length string to the writer.
		---@param str string The string to write.
		---@param max_length? integer The size of the string.
		function ByteWriter:writeFixedString( str, max_length )
			return self:write( write( str, max_length ) )
		end

	end

	do

		local write = data.writeCounted

		--- [SHARED AND MENU]
		---
		--- Writes a counted string to the writer.
		---@param byte_count integer The size of the string.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeCountedString( byte_count, big_endian )
			---@diagnostic disable-next-line: redundant-parameter
			return self:write( write( self[ 1 ], byte_count, big_endian ), nil )
		end

	end

	do

		local write = data.writeNullTerminated

		--- [SHARED AND MENU]
		---
		--- Writes a null-terminated string to the writer.
		---@param str string The string to write.
		function ByteWriter:writeNullTerminatedString( str )
			return self:write( write( str ) )
		end

	end

	ByteWriter.writeString = ByteWriter.writeNullTerminatedString

end

do

	local signed = binary.signed

	do

		local write = signed.writeByte

		--- [SHARED AND MENU]
		---
		--- Writes a signed byte (1 byte/8 bits) to the writer.
		---
		--- Allowable values from `-128` to `127`.
		---@param value integer The signed byte.
		function ByteWriter:writeSByte( value )
			return self:write( write( value ) )
		end

	end

	do

		local write = signed.writeShort

		--- [SHARED AND MENU]
		---
		--- Writes a signed short (2 bytes/16 bits) to the writer.
		---
		--- Allowable values from `-32768` to `32767`.
		---@param value integer The signed short.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeShort( value, big_endian )
			return self:write( write( value, big_endian ) )
		end

	end

	do

		local write = signed.writeInteger

		--- [SHARED AND MENU]
		---
		--- Writes a signed integer (4 bytes/32 bits) to the writer.
		---
		--- Allowable values from `-2147483648` to `2147483647`.
		---@param value integer The signed integer.
		---@param byte_count? integer The number of bytes to write.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeInt( value, byte_count, big_endian )
			return self:write( write( value, byte_count, big_endian ) )
		end

	end

	do

		local write = signed.writeLong

		--- [SHARED AND MENU]
		---
		--- Writes a signed long (4 bytes/32 bits) to the writer.
		---
		--- Allowable values from `-2147483648` to `2147483647`.
		---@param value integer The signed long.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeLong( value, big_endian )
			return self:write( write( value, big_endian ) )
		end

	end

	do

		local write = signed.writeLongLong

		--- [SHARED AND MENU]
		---
		--- Writes a signed long long (8 bytes/64 bits) to the writer.
		---
		--- Allowable values from `-9223372036854775808` to `9223372036854775807`.
		---@param value integer The signed long long.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeLongLong( value, big_endian )
			return self:write( write( value, big_endian ) )
		end

	end

	do

		local write = signed.writeFixedPoint

		--- [SHARED AND MENU]
		---
		--- Writes a signed fixed-point number to the writer.
		---
		--- Allowable values from `-2.1 billion to ~2.1 billion`.
		---@param value number The signed fixed-point number.
		---@param m integer Number of integer bits (including sign bit).
		---@param n integer Number of fractional bits.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeFixedPoint( value, m, n, big_endian )
			---@diagnostic disable-next-line: redundant-parameter
			return self:write( write( value, m, n, big_endian ), nil )
		end

	end

end

do

	local unsigned = binary.unsigned

	do

		local write = unsigned.writeByte

		--- [SHARED AND MENU]
		---
		--- Writes an unsigned byte (1 byte/8 bits) to the writer.
		---
		--- Allowable values from `0` to `255`.
		---@param value integer The unsigned byte.
		function ByteWriter:writeByte( value )
			return self:write( write( value ) )
		end

	end

	do

		local write = unsigned.writeShort

		--- [SHARED AND MENU]
		---
		--- Writes an unsigned short (2 bytes/16 bits) to the writer.
		---
		--- Allowable values from `0` to `65535`.
		---@param value integer The unsigned short.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeUShort( value, big_endian )
			return self:write( write( value, big_endian ) )
		end

	end

	do

		local write = unsigned.writeInteger

		--- [SHARED AND MENU]
		---
		--- Writes an unsigned integer to the writer.
		---
		--- Allowable values from `0` to `4294967295`.
		---@param value integer The unsigned integer.
		---@param byte_count? integer The number of bytes to write.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeUInt( value, byte_count, big_endian )
			return self:write( write( value, byte_count or 4, big_endian ) )
		end

	end

	do

		local write = unsigned.writeLong

		--- [SHARED AND MENU]
		---
		--- Writes an unsigned long (4 bytes/32 bits) to the writer.
		---
		--- Allowable values from `0` to `4294967295`.
		---@param value integer The unsigned long.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeULong( value, big_endian )
			return self:write( write( value, big_endian ) )
		end

	end

	do

		local write = unsigned.writeLongLong

		--- [SHARED AND MENU]
		---
		--- Writes an unsigned long long (8 bytes/64 bits) to the writer.
		---
		--- Allowable values from `0` to `18446744073709551615`.
		---@param value integer The unsigned long long.
		---@param big_endian? boolean The endianness of the binary string.
		function ByteWriter:writeULongLong( value, big_endian )
			return self:write( write( value, big_endian ) )
		end

	end

	do

		local write = unsigned.writeFixedPoint

		--- [SHARED AND MENU]
		---
		--- Writes an unsigned fixed-point number (**UQm.n**) from the reader.
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
		function ByteWriter:writeUnsignedFixedPoint( value, m, n, big_endian )
			---@diagnostic disable-next-line: redundant-parameter
			return self:write( write( value, m, n, big_endian ), nil )
		end

	end

end

do

	local write = binary.writeFloat

	--- [SHARED AND MENU]
	---
	--- Writes a float (4 bytes/32 bits) to the writer.
	---
	--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
	---@param value number The float value.
	---@param big_endian? boolean The endianness of the binary string.
	function ByteWriter:writeFloat( value, big_endian )
		return self:write( write( value, big_endian ) )
	end

end

do

	local write = binary.writeDouble

	--- [SHARED AND MENU]
	---
	--- Writes a double (8 bytes/64 bits) to the writer.
	---
	--- Allowable values from `2.2250738585072014e-308` to `1.7976931348623158e+308`.
	---@param value number The double.
	---@param big_endian? boolean The endianness of the binary string.
	function ByteWriter:writeDouble( value, big_endian )
		return self:write( write( value, big_endian ) )
	end

end

--- [SHARED AND MENU]
---
--- The byte writer class.
---@class gpm.std.crypto.ByteWriterClass: gpm.std.crypto.ByteWriter
---@field __base gpm.std.crypto.ByteWriter
---@overload fun( base?: string ): gpm.std.crypto.ByteWriter
local ByteWriterClass = std.class.create( ByteWriter )

return ByteWriterClass
