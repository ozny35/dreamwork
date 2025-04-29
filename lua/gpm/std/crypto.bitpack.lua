
local std = _G.gpm.std
local len = std.len

local math = std.math
local math_floor = math.floor

local table_unpack = std.table.unpack

---@class gpm.std.crypto
local crypto = std.crypto

--- [SHARED AND MENU]
---
--- The bit pack library.
---
--- Library provides functions for reading and writing bits.
---
---@class gpm.std.crypto.bitpack
local bitpack = crypto.bitpack or {}
crypto.bitpack = bitpack


--- [SHARED AND MENU]
---
--- Reads unsigned integer from table of bits (booleans).
---
---@param bits boolean[] The table of bits.
---@param bit_count? integer The size of the table.
---@param start_position? integer The start position of the table.
---@return integer value
local function bitpack_readUInt( bits, bit_count, start_position )
	if start_position == nil then
		start_position = 1
	end

	if bit_count == nil then
		bit_count = len( bits )
	elseif bit_count == 0 then
		return 0
	elseif bit_count < 0 then
		std.error( "bit count cannot be negative", 2 )
	end

	local value = 0

	for i = start_position, bit_count + ( start_position - 1 ), 1 do
		if bits[ i ] then
			value = value * 2 + 1
		else
			value = value * 2
		end
	end

	return value
end

bitpack.readUInt = bitpack_readUInt

--- [SHARED AND MENU]
---
--- Writes unsigned integer as table of bits (booleans).
---
---@param value integer The number to explode.
---@param bit_count? integer The size of the table.
---@return boolean[] bits The table of bits.
local function bitpack_writeUInt( value, bit_count )
	if bit_count == nil then
		bit_count = 8
	end

	if value < 0 then
		std.error( "integer is too small to write", 1 )
	elseif value > ( 2 ^ bit_count ) - 1 then
		std.error( "integer is too large to write", 2 )
	end

	local bits = {}

	for j = bit_count, 1, -1 do
		if value == 0 then
			bits[ j ] = false
		else
			bits[ j ] = value % 2 == 1
			value = math_floor( value * 0.5 )
		end
	end

	return bits
end

bitpack.writeUInt = bitpack_writeUInt

--- [SHARED AND MENU]
---
--- Reads signed integer from table of bits (booleans).
---
---@param bits any
---@param bit_count any
---@param start_position any
---@return unknown
function bitpack.readInt( bits, bit_count, start_position )
	return bitpack_readUInt( bits, bit_count, start_position ) - ( 2 ^ ( bit_count - 1 ) )
end

--- [SHARED AND MENU]
---
--- Writes signed integer as table of bits (booleans).
---
---@param value integer The number to explode.
---@param bit_count integer The size of the table.
---@return boolean[] bits The table of bits.
function bitpack.writeInt( value, bit_count )
	return bitpack_writeUInt( value + ( 2 ^ ( bit_count - 1 ) ), bit_count )
end

--- [SHARED AND MENU]
---
--- Writes table of bits (booleans) as bytecodes.
---
---@param bits boolean[] The table of bits.
---@param bit_count? integer The size of the bit table.
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@return integer ... The bytecodes (bytes as integers<0-255>).
function bitpack.pack( bits, bit_count, big_endian )
	if bit_count == nil then
		bit_count = len( bits )
	elseif bit_count < 1 then
		std.error( "bit count cannot be less than 1", 1 )
	end

	local byte_count = math.ceil( bit_count * 0.125 )
	local bytes = {}

	if big_endian then
		for i = byte_count, 1, -1 do
			bytes[ i ] = bitpack_readUInt( bits, 8, i * 8 - 7 )
		end
	else
		bit_count = bit_count + 1

		for i = 1, byte_count, 1 do
			bytes[ i ] = bitpack_readUInt( bits, 8, bit_count - i * 8 )
		end
	end

	return table_unpack( bytes, 1, byte_count )
end

--- [SHARED AND MENU]
---
--- Reads bytecodes as table of bits (booleans).
---
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@param ... integer The bytecodes (bytes as integers<0-255>).
---@return boolean[] bits The table of bits (booleans).
---@return integer bit_count The size of the bit table.
function bitpack.unpack( big_endian, ... )
	local byte_count = select( "#", ... )
	local bytes = { ... }

	local bits, bit_count = {}, 0

	for i = big_endian and 1 or byte_count, big_endian and byte_count or 1, big_endian and 1 or -1 do
		local byte = bytes[ i ]

		for j = 8, 1, -1 do
			if byte == 0 then
				bits[ bit_count + j ] = false
			else
				bits[ bit_count + j ] = byte % 2 == 1
				byte = math_floor( byte * 0.5 )
			end
		end

		bit_count = bit_count + 8
	end

	return bits, bit_count
end

--- [SHARED AND MENU]
---
--- Creates a reader function from table of bytes (integers<0-255>).
---
--- Can be used as iterator in for loops.
---
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@param bytes integer[] The table of bytes (integers<0-255>).
---@return fun(): integer?, boolean? reader A reader function that returns the bit position and the bit (boolean) value or `nil` if there are no more bits.
function bitpack.reader( big_endian, bytes )
	local byte_count = len( bytes )

	local byte_index = big_endian and 1 or byte_count
	local byte = bytes[ byte_index ]
	local bit_index = 8

	if big_endian then
		return function()
			if bit_index == 0 then
				byte_index, bit_index = byte_index + 1, 8
				byte = bytes[ byte_index ]
				if byte == nil then return nil end
			end

			bit_index = bit_index - 1
			return ( byte_index - 1 ) * 8 + bit_index + 1, math_floor( byte / ( 2 ^ bit_index ) ) % 2 == 1
		end
	else
		return function()
			if bit_index == 0 then
				byte_index, bit_index = byte_index - 1, 8
				byte = bytes[ byte_index ]
				if byte == nil then return nil end
			end

			bit_index = bit_index - 1
			return ( byte_index - 1 ) * 8 + bit_index + 1, math_floor( byte / ( 2 ^ bit_index ) ) % 2 == 1
		end
	end
end

--- [SHARED AND MENU]
---
--- Creates a writer function to table of bytes (integers<0-255>).
---
---@param byte_count? integer The number of bytes to write.
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@return fun( bit: boolean ): integer? writer A write function that writes a bit to a binary string and returns the position of the written bit or `nil` if the binary string is full.
---@return integer[] bytes Result table of bytes (integers<0-255>).
function bitpack.writer( byte_count, big_endian )
	if byte_count == nil then
		if not big_endian then
			std.error( "byte count must be specified for little endian", 2 )
		end

		local bytes, byte_index = {}, 1
		local bit_index = 7

		return function( value )
			if value then
				bytes[ byte_index ] = bytes[ byte_index ] + ( 2 ^ bit_index )
			end

			bit_index = ( bit_index - 1 ) % 8

			if bit_index == 7 then
				byte_index = byte_index + 1
			end

			return byte_index * 8 - ( 6 - bit_index )
		end, bytes
	end

	local bit_index = 7
	local bytes = {}

	for i = 1, byte_count, 1 do
		bytes[ i ] = 0
	end

	if big_endian then
		local byte_index = 1

		return function( value )
			if byte_index > byte_count then return nil end

			if value then
				bytes[ byte_index ] = bytes[ byte_index ] + ( 2 ^ bit_index )
			end

			bit_index = ( bit_index - 1 ) % 8

			if bit_index == 7 then
				byte_index = byte_index + 1
			end

			return byte_index * 8 - ( 6 - bit_index )
		end, bytes
	else

		local byte_index = byte_count

		return function( value )
			if byte_index == 0 then return nil end

			if value then
				bytes[ byte_index ] = bytes[ byte_index ] + ( 2 ^ bit_index )
			end

			bit_index = ( bit_index - 1 ) % 8

			if bit_index == 7 then
				byte_index = byte_index - 1
			end

			return byte_index * 8 - ( 6 - bit_index )
		end, bytes
	end
end
