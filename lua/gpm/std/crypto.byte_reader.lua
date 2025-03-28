local std = _G.gpm.std

local binary = std.crypto.binary
local string = std.string
local math = std.math

--- [SHARED AND MENU]
---
--- The byte reader object.
---@alias ByteReader gpm.std.ByteReader
---@class gpm.std.ByteReader: gpm.std.Object
---@field __class gpm.std.ByteReaderClass
---@field protected pointer integer
---@field protected size integer
---@field protected data string
local ByteReader = std.class.base( "ByteReader" )

---@protected
function ByteReader:__tostring()
	return string.format( "ByteReader: %p [%d/%d]", self, self.pointer, self.size )
end

do

	local string_len = string.len

	---@protected
	function ByteReader:__init( data )
		self.size = string_len( data )
		self.pointer = 0
		self.data = data
	end

end

--- [SHARED AND MENU]
---
--- Resets the reader.
function ByteReader:flush()
	self.pointer = 0
end

--- [SHARED AND MENU]
---
--- Returns the current position of the reader.
function ByteReader:tell()
	return self.pointer
end

do

	local math_clamp = math.clamp

	--- [SHARED AND MENU]
	---
	--- Sets the current position of the reader.
	---@param position? integer The position to set.
	---@return integer: The new position.
	function ByteReader:shift( position )
		if position == nil then
			position = 0
		else
			position = math_clamp( 0, position, self.size )
		end

		self.pointer = position

		return position
	end

end

--- [SHARED AND MENU]
---
--- Skips the reader by the specified offset.
---@param offset integer The offset to skip.
---@return integer: The new position.
function ByteReader:skip( offset )
	return self:shift( self.pointer + offset )
end

do

	local string_sub = string.sub
	local math_min = math.min

	--- [SHARED AND MENU]
	---
	--- Reads the specified number of bytes from the reader.
	---@param length? integer The number of bytes to read.
	---@return string | nil str The readed bytes or `nil` if there are no more bytes to read.
	function ByteReader:read( length )
		local size = self.size

		if length == nil then
			length = size
		elseif length < 0 then
			length = size + length + 1
		end

		local position = self.pointer
		if ( position + length ) >= size then return end
		self.pointer = math_min( position + length, size )
		return string_sub( self.data, position + 1, position + length )
	end

end

do

	local data = binary.data

	do

		local read = data.readFixed

		--- [SHARED AND MENU]
		---
		--- Reads a fixed-length string from the reader.
		---@param length integer The size of the string.
		---@return string | nil str The fixed-length string or `nil` if there are no more bytes to read.
		function ByteReader:readFixedString( length )
			local pointer = self.pointer
			if ( pointer + length ) >= self.size then return end

			self:skip( length )
			return read( self.data, length, pointer )
		end

	end

	do

		local read = data.readCounted

		--- [SHARED AND MENU]
		---
		--- Reads a counted string from the reader.
		---@param byte_count? integer The number of bytes to read.
		---@param big_endian? boolean The endianness of the binary string.
		---@return string | nil str The counted string or `nil` if there are no more bytes to read.
		---@return integer | nil length The length of the counted string or `nil` if there are no more bytes to read.
		function ByteReader:readCountedString( byte_count, big_endian )
			if byte_count == nil then byte_count = 1 end
			local pointer = self.pointer

			local str, length = read( self.data, byte_count, big_endian, pointer )

			local skip_size = length + byte_count
			if ( skip_size + pointer ) > self.size then return end

			self:skip( skip_size )
			return str, length
		end

	end

	do

		local read = data.readNullTerminated

		--- [SHARED AND MENU]
		---
		--- Reads a null-terminated string from the reader.
		---@return string | nil str The null-terminated string or `nil` if there are no more bytes to read.
		function ByteReader:readNullTerminatedString()
			local pointer = self.pointer

			local str, length = read( self.data, pointer )

			local skip_size = length + 1
			if ( skip_size + pointer ) > self.size then return end

			self:skip( skip_size )
			return str
		end

	end

	ByteReader.readString = ByteReader.readNullTerminatedString

end

do

	local signed = binary.signed

	do

		local read = signed.readByte

		--- [SHARED AND MENU]
		---
		--- Reads a signed byte from the reader.
		---
		--- Allowable values from `-128` to `127`.
		---@return integer | nil byte The signed byte or `nil` if there are no more bytes to read.
		function ByteReader:readSByte()
			local position = self.pointer
			if ( position + 1 ) > self.size then return end

			self:skip( 1 )
			return read( self.data, position )
		end

	end

	do

		local read = signed.readShort

		--- [SHARED AND MENU]
		---
		--- Reads a signed short from the reader.
		---
		--- Allowable values from `-32768` to `32767`.
		---@param big_endian? boolean The endianness of the binary string.
		---@return integer | nil short The signed short or `nil` if there are no more bytes to read.
		function ByteReader:readShort( big_endian )
			local position = self.pointer
			if ( position + 2 ) > self.size then return end

			self:skip( 2 )
			return read( self.data, big_endian, position )
		end

	end

	do

		local read = signed.readInteger

		--- [SHARED AND MENU]
		---
		--- Reads a signed integer from the reader.
		---
		--- Allowable values from `-2147483648` to `2147483647`.
		---@param byte_count? integer The number of bytes to read.
		---@param big_endian? boolean The endianness of the binary string.
		---@return integer | nil integer The signed integer or `nil` if there are no more bytes to read.
		function ByteReader:readInt( byte_count, big_endian )
			if byte_count == nil then byte_count = 4 end

			local position = self.pointer
			if ( position + byte_count ) > self.size then return end

			self:skip( byte_count )
			return read( self.data, byte_count, big_endian, position )
		end

	end

	do

		local read = signed.readLong

		--- [SHARED AND MENU]
		---
		--- Reads a signed long (4 bytes/32 bits) from the reader.
		---
		--- Allowable values from `-2147483648` to `2147483647`.
		---@param big_endian? boolean The endianness of the binary string.
		---@return integer | nil long The signed long or `nil` if there are no more bytes to read.
		function ByteReader:readLong( big_endian )
			local position = self.pointer
			if ( position + 4 ) > self.size then return end

			self:skip( 4 )
			return read( self.data, big_endian, position )
		end

	end

	do

		local read = signed.readLongLong

		--- [SHARED AND MENU]
		---
		--- Reads a signed long long from the reader.
		---
		--- Allowable values from `-9223372036854775808` to `9223372036854775807`.
		---@param big_endian? boolean The endianness of the binary string.
		---@return integer | nil longlong The signed long long or `nil` if there are no more bytes to read.
		function ByteReader:readLongLong( big_endian )
			local position = self.pointer
			if ( position + 8 ) > self.size then return end

			self:skip( 8 )
			return read( self.data, big_endian, position )
		end

	end

	do

		local read = signed.readFixedPoint

		--- [SHARED AND MENU]
		---
		--- Reads an signed fixed-point number (**Qm.n**) from the reader.
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
		---|Q24.8 |`-8388608.0 to 8388607.996`	  |0.00390625 (1/256)
		---|Q32.16|`-2.1 billion to ~2.1 billion` |0.0000152588 (1/65536)
		---@param m integer Number of integer bits (including sign bit).
		---@param n integer Number of fractional bits.
		---@param big_endian? boolean The endianness of the binary string.
		---@return number | nil number The signed fixed-point number or `nil` if there are no more bytes to read.
		function ByteReader:readFixedPoint( m, n, big_endian )
			local position = self.pointer

			local number, byte_count = read( self.data, m, n, big_endian, position )
			if ( position + byte_count ) > self.size then return end

			self:skip( byte_count )
			return number
		end

	end

end

do

	local unsigned = binary.unsigned

	do

		local read = unsigned.readByte

		--- [SHARED AND MENU]
		---
		--- Reads a byte from the reader.
		---
		--- Allowable values from `0` to `255`.
		---@return integer | nil byte The byte or `nil` if there are no more bytes to read.
		function ByteReader:readByte()
			local position = self.pointer
			if ( position + 1 ) > self.size then return end

			self:skip( 1 )
			return read( self.data, position )
		end

	end

	do

		local read = unsigned.readShort

		--- [SHARED AND MENU]
		---
		--- Reads an unsigned short (2 bytes/16 bits) from the reader.
		---
		--- Allowable values from `0` to `65535`.
		---@param big_endian? boolean The endianness of the binary string.
		---@return number | nil short The unsigned short or `nil` if there are no more bytes to read.
		function ByteReader:readUShort( big_endian )
			local position = self.pointer
			if ( position + 2 ) > self.size then return end

			self:skip( 2 )
			return read( self.data, big_endian, position )
		end

	end

	do

		local read = unsigned.readInteger

		--- [SHARED AND MENU]
		---
		--- Reads an unsigned integer from the reader.
		---@param byte_count? integer The number of bytes to read.
		---@param big_endian? boolean The endianness of the binary string.
		---@return integer | nil number The unsigned integer or `nil` if there are no more bytes to read.
		function ByteReader:readUInt( byte_count, big_endian )
			if byte_count == nil then byte_count = 4 end

			local position = self.pointer
			if ( position + byte_count ) > self.size then return end

			self:skip( byte_count )
			return read( self.data, byte_count, big_endian, position )
		end

	end

	do

		local read = unsigned.readLong

		--- [SHARED AND MENU]
		---
		--- Reads an unsigned long (4 bytes/32 bits) from the reader.
		---
		--- Allowable values from `0` to `4294967295`.
		---@param big_endian? boolean The endianness of the binary string.
		---@return number | nil long The unsigned long or `nil` if there are no more bytes to read.
		function ByteReader:readULong( big_endian )
			local position = self.pointer
			if ( position + 4 ) > self.size then return end

			self:skip( 4 )
			return read( self.data, big_endian, position )
		end

	end

	do

		local read = unsigned.readLongLong

		--- [SHARED AND MENU]
		---
		--- Reads an unsigned long long (8 bytes/64 bits) from the reader.
		---
		--- Allowable values from `0` to `18446744073709551615`.
		---@param big_endian? boolean The endianness of the binary string.
		---@return integer | nil longlong The unsigned long long or `nil` if there are no more bytes to read.
		function ByteReader:readULongLong( big_endian )
			local position = self.pointer
			if ( position + 8 ) > self.size then return end

			self:skip( 8 )
			return read( self.data, big_endian, position )
		end

	end

	do

		local read = unsigned.readFixedPoint

		--- [SHARED AND MENU]
		---
		--- Reads an unsigned fixed-point number (**UQm.n**) from the reader.
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
		---@param m integer Number of integer bits (including sign bit).
		---@param n integer Number of fractional bits.
		---@param big_endian? boolean The endianness of the binary string.
		---@return number | nil number The unsigned fixed-point number.
		---@return string | nil err The error message or `nil` if there is no error.
		function ByteReader:readUnsignedFixedPoint( m, n, big_endian )
			local position = self.pointer

			local number, byte_count = read( self.data, m, n, big_endian, position )
			if ( position + byte_count ) > self.size then return end

			self:skip( byte_count )
			return number, nil
		end

	end

end

do

	local read = binary.readFloat

	--- [SHARED AND MENU]
	---
	--- Reads a float from the reader.
	---
	--- Allowable values from `-3.4028234663852886E38` to `3.4028234663852886E38`.
	---@param big_endian? boolean The endianness of the binary string.
	---@return number | nil float The float or `nil` if there are no more bytes to read.
	function ByteReader:readFloat( big_endian )
		local position = self.pointer
		if ( position + 4 ) > self.size then return end

		self:skip( 4 )
		return read( self.data, big_endian, position )
	end

end

do

	local read = binary.readDouble

	--- [SHARED AND MENU]
	---
	--- Reads a double from the reader.
	---
	--- Allowable values from `-1.7976931348623157E308` to `1.7976931348623157E308`.
	---@param big_endian? boolean The endianness of the binary string.
	---@return number | nil double The double or `nil` if there are no more bytes to read.
	function ByteReader:readDouble( big_endian )
		local position = self.pointer
		if ( position + 8 ) > self.size then return end

		self:skip( 8 )
		return read( self.data, big_endian, position )
	end

end

--- [SHARED AND MENU]
---
--- The byte reader class.
---@class gpm.std.ByteReaderClass: gpm.std.ByteReader
---@field __base gpm.std.ByteReader
---@overload fun( data: string ): ByteReader
local ByteReaderClass = std.class.create( ByteReader )

return ByteReaderClass
