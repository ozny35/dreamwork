local std = _G.gpm.std
local len = std.len

local math = std.math
local math_floor = math.floor

local table_unpack = std.table.unpack

---@class gpm.std.pack
local pack = std.pack

--- [SHARED AND MENU]
---
--- Library that packs/unpacks types as bit sequences.
---
---@class gpm.std.pack.bits
local bitpack = pack.bits or {}
pack.bits = bitpack

---@alias gpm.std.pack.bits.Sequence boolean[] The sequence of bits (booleans).
---@alias gpm.std.pack.bytes.Sequence integer[] The sequence of bytes (integers<0-255>).

--- [SHARED AND MENU]
---
--- Reads unsigned integer from table of bits (booleans).
---
---@param bit_sequence gpm.std.pack.bits.Sequence The sequence of bits.
---@param bit_sequence_size? integer The size of the bit sequence.
---@param start_position? integer The start position in the bit sequence.
---@return integer uint The unsigned integer.
local function bitpack_readUInt( bit_sequence, bit_sequence_size, start_position )
	if start_position == nil then
		start_position = 1
	end

	if bit_sequence_size == nil then
		bit_sequence_size = len( bit_sequence )
	elseif bit_sequence_size == 0 then
		return 0
	elseif bit_sequence_size < 0 then
		error( "bit count cannot be negative", 2 )
	end

	local value = 0

	for i = start_position, bit_sequence_size + ( start_position - 1 ), 1 do
		if bit_sequence[ i ] then
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
---@param value integer
---@param bit_sequence_size? integer
---@return gpm.std.pack.bits.Sequence bit_sequence
local function bitpack_writeUInt( value, bit_sequence_size )
	if bit_sequence_size == nil then
		bit_sequence_size = 8
	end

	if value < 0 then
		error( "integer is too small to write", 1 )
	elseif value > ( 2 ^ bit_sequence_size ) - 1 then
		error( "integer is too large to write", 2 )
	end

	local bit_sequence = {}

	for j = bit_sequence_size, 1, -1 do
		if value == 0 then
			bit_sequence[ j ] = false
		else
			bit_sequence[ j ] = value % 2 == 1
			value = math_floor( value * 0.5 )
		end
	end

	return bit_sequence
end

bitpack.writeUInt = bitpack_writeUInt

--- [SHARED AND MENU]
---
--- Reads signed integer from table of bits (booleans).
---
---@param bit_sequence gpm.std.pack.bits.Sequence
---@param bit_sequence_size integer
---@param start_position integer
---@return integer value
function bitpack.readInt( bit_sequence, bit_sequence_size, start_position )
	return bitpack_readUInt( bit_sequence, bit_sequence_size, start_position ) - ( 2 ^ ( bit_sequence_size - 1 ) )
end

--- [SHARED AND MENU]
---
--- Writes signed integer as table of bits (booleans).
---
---@param value integer The number to explode.
---@param bit_sequence_size integer
---@return gpm.std.pack.bits.Sequence bit_sequence
function bitpack.writeInt( value, bit_sequence_size )
	return bitpack_writeUInt( value + ( 2 ^ ( bit_sequence_size - 1 ) ), bit_sequence_size )
end

--- [SHARED AND MENU]
---
--- Writes table of bits (booleans) as bytecodes.
---
---@param bit_sequence gpm.std.pack.bits.Sequence
---@param bit_sequence_size? integer
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@return integer ... The bytecodes (bytes as integers<0-255>).
function bitpack.pack( bit_sequence, bit_sequence_size, big_endian )
	if bit_sequence_size == nil then
		bit_sequence_size = len( bit_sequence )
	elseif bit_sequence_size < 1 then
		error( "bit count cannot be less than 1", 1 )
	end

	local byte_count = math.ceil( bit_sequence_size * 0.125 )
	local bytes = {}

	if big_endian then
		for i = byte_count, 1, -1 do
			bytes[ i ] = bitpack_readUInt( bit_sequence, 8, i * 8 - 7 )
		end
	else
		bit_sequence_size = bit_sequence_size + 1

		for i = 1, byte_count, 1 do
			bytes[ i ] = bitpack_readUInt( bit_sequence, 8, bit_sequence_size - i * 8 )
		end
	end

	return table_unpack( bytes, 1, byte_count )
end

--- [SHARED AND MENU]
---
--- Reads bytecodes as table of bits (booleans).
---
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@param bytes gpm.std.pack.bytes.Sequence The bytecodes (bytes as integers<0-255>).
---@param byte_count? integer The number of bytes.
---@return gpm.std.pack.bits.Sequence bit_sequence The table of bits (booleans).
---@return integer bit_sequence_size The size of the bit table.
function bitpack.unpack( big_endian, bytes, byte_count )
	if byte_count == nil then
		byte_count = len( bytes )
	end

	local bit_sequence, bit_sequence_size = {}, 0

	for i = big_endian and 1 or byte_count, big_endian and byte_count or 1, big_endian and 1 or -1 do
		local byte = bytes[ i ]

		for j = 8, 1, -1 do
			if byte == 0 then
				bit_sequence[ bit_sequence_size + j ] = false
			else
				bit_sequence[ bit_sequence_size + j ] = byte % 2 == 1
				byte = math_floor( byte * 0.5 )
			end
		end

		bit_sequence_size = bit_sequence_size + 8
	end

	return bit_sequence, bit_sequence_size
end

do

	local string_char = std.string.char

	function bitpack.asString( bit_sequence, bit_sequence_size, full_bytes )
		if bit_sequence_size == nil then
			bit_sequence_size = len( bit_sequence )
		end

		if bit_sequence_size > 8000 then
			error( "bit count cannot be greater than 8000", 1 )
		end

		local bytes = {}

		for i = 1, bit_sequence_size, 8 do
			bytes[ i ] = bit_sequence[ i ] and 0x31 or 0x30
		end

		print( bit_sequence_size % 8 )

		-- if full_bytes then
		-- 	for i = bit_sequence_size % 8 + 1, do
		-- end

		return string_char( table_unpack( bytes, 1, bit_sequence_size ) )
	end

	-- print( bitpack.asString( bitpack. ) )

end

-- TODO: Reader/Writer like https://github.com/Nak2/NikNaks/blob/main/lua/niknaks/modules/sh_bitbuffer.lua
