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

-- TODO: ffi support?

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
		error( "bit count cannot be negative", 2 )
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
		error( "integer is too small to write", 1 )
	elseif value > ( 2 ^ bit_count ) - 1 then
		error( "integer is too large to write", 2 )
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
		error( "bit count cannot be less than 1", 1 )
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
---@param bytes integer[] The bytecodes (bytes as integers<0-255>).
---@param byte_count? integer The number of bytes.
---@return boolean[] bits The table of bits (booleans).
---@return integer bit_count The size of the bit table.
function bitpack.unpack( big_endian, bytes, byte_count )
	if byte_count == nil then
		byte_count = len( bytes )
	end

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
