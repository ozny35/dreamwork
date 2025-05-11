local _G = _G

local glua_net = _G.net
local std = _G.gpm.std
local string, math, debug = std.string, std.math, std.debug

local bit_size, getmetatable, debug_findmetatable = std.bit.size, std.getmetatable, debug.findmetatable
local isfunction = std.isfunction

---@class Entity
local ENTITY = debug_findmetatable( "Entity" )

---@class Player
local PLAYER = debug_findmetatable( "Player" )

local ENTITY_IsValid, ENTITY_EntIndex = ENTITY.IsValid, ENTITY.EntIndex
local Entity, NULL = _G.Entity, _G.NULL

local readUInt64, writeUInt64 = glua_net.ReadUInt64, glua_net.WriteUInt64
local readString, writeString = glua_net.ReadString, glua_net.WriteString
local readDouble, writeDouble = glua_net.ReadDouble, glua_net.WriteDouble
local readVector, writeVector = glua_net.ReadVector, glua_net.WriteVector
local readMatrix, writeMatrix = glua_net.ReadMatrix, glua_net.WriteMatrix
local readNormal, writeNormal = glua_net.ReadNormal, glua_net.WriteNormal
local readFloat, writeFloat = glua_net.ReadFloat, glua_net.WriteFloat
local readAngle, writeAngle = glua_net.ReadAngle, glua_net.WriteAngle
local readUInt, writeUInt = glua_net.ReadUInt, glua_net.WriteUInt
local readData, writeData = glua_net.ReadData, glua_net.WriteData
local readInt, writeInt = glua_net.ReadInt, glua_net.WriteInt
local readBit, writeBit = glua_net.ReadBit, glua_net.WriteBit

--- Reads a signed byte from the received net message.
---@return unknown
local function readSByte()
    return readInt( 8 )
end

--- Writes a signed byte to the sent net message.
---@param value number
local function writeSByte( value )
    writeInt( value, 8 )
end

--- Reads a unsigned byte from the received net message.
---@return number
local function readByte()
    return readUInt( 8 )
end

--- Writes a unsigned byte to the sent net message.
---@param value number
local function writeByte( value )
    writeUInt( value, 8 )
end

--- Reads a signed short from the received net message.
---@return number
local function readShort()
    return readInt( 16 )
end

--- Writes a signed short to the sent net message.
---@param value number
local function writeShort( value )
    writeInt( value, 16 )
end

--- Reads a unsigned short from the received net message.
---@return number
local function readUShort()
    return readUInt( 16 )
end

--- Writes a unsigned short to the sent net message.
---@param value number
local function writeUShort( value )
    writeUInt( value, 16 )
end

local function readLong()
    return readInt( 32 )
end

local function writeLong( value )
    writeInt( value, 32 )
end

local function readULong()
    return readUInt( 32 )
end

local function writeULong( value )
    writeUInt( value, 32 )
end

local readNumber, writeNumber
do

    -- local math_inf, math_ninf = math.inf, math.ninf

    local BigInt_FromBytes, BigInt_ToBytes, BigInt_new
    do
        local BigInt = std.BigInt
        BigInt_FromBytes, BigInt_ToBytes, BigInt_new = BigInt.FromBytes, BigInt.ToBytes, BigInt.new
    end

    function readNumber()
        local type = readUInt( 4 )
        if type == 0 then
            return 0
        elseif type == 1 then
            return 1
        elseif type == 2 then
            return 2
        elseif type == 3 then
            return readSByte()
        elseif type == 4 then
            return readByte()
        elseif type == 5 then
            return readShort()
        elseif type == 6 then
            return readUShort()
        elseif type == 7 then
            return readLong()
        elseif type == 8 then
            return readULong()
        elseif type == 10 then
            return BigInt_FromBytes( readData( 8 ) )
        elseif type == 11 then
            return readFloat()
        elseif type == 12 then
            return readDouble()
        elseif type == 13 then
            return math.nan
        elseif type == 14 then
            return math_ninf
        elseif type == 15 then
            return math_inf
        end
    end

    function writeNumber( value )
        if value == -1 then
            writeUInt( 0, 4 )
        elseif value == 0 then
            writeUInt( 1, 4 )
        elseif value == 1 then
            writeUInt( 2, 4 )
        elseif value == 2 then
            writeUInt( 3, 4 )
        elseif value ~= value then
            writeUInt( 13, 4 )
        elseif value == math_ninf then
            writeUInt( 14, 4 )
        elseif value == math_inf then
            writeUInt( 15, 4 )
        elseif ( value % 1 ) == 0 then
            if value >= -128 and value <= 127 then
                writeUInt( 5, 4 )
                writeSByte( value )
            elseif value >= 0 and value <= 255 then
                writeUInt( 6, 4 )
                writeByte( value )
            elseif value >= -32768 and value <= 32767 then
                writeUInt( 7, 4 )
                writeShort( value )
            elseif value >= 0 and value <= 65535 then
                writeUInt( 8, 4 )
                writeUShort( value )
            elseif value >= -2147483648 and value <= 2147483647 then
                writeUInt( 9, 4 )
                writeLong( value )
            elseif value >= 0 and value <= 4294967295 then
                writeUInt( 10, 4 )
                writeULong( value )
            else
                writeData( BigInt_ToBytes( BigInt_new( value ) ), 8 )
            end
        elseif value >= -3.402823466E+38 and value <= 3.402823466E+38 then
            writeUInt( 11, 4 )
            writeFloat( value )
        else
            writeUInt( 12, 4 )
            writeDouble( value )
        end
    end

end

local NUMBER = debug_findmetatable( "number" )
local STRING = debug_findmetatable( "string" )
local BOOLEAN = debug_findmetatable( "boolean" )
local MATRIX = debug_findmetatable( "VMatrix" )
local VECTOR = debug_findmetatable( "Vector" )
local ANGLE = debug_findmetatable( "Angle" )

--- Reads a boolean from the received net message.
---@return boolean `true` or `false`, or `false` if the bool could not be read.
local function readBool()
    return readBit() == 1
end

local net = {
    readBit = readBool,
    writeBit = writeBit,

    readUInt = readUInt,
    writeUInt = writeUInt,

    readFloat = readFloat,
    writeFloat = writeFloat,

    readDouble = readDouble,
    writeDouble = writeDouble,

    readString = readString,
    writeString = writeString,

    readNumber = readNumber,
    writeNumber = writeNumber,

    readAngle = readAngle,
    writeAngle = writeAngle,

    readVector = readVector,
    writeVector = writeVector,

    readNormal = readNormal,
    writeNormal = writeNormal,

    readMatrix = readMatrix,
    writeMatrix = writeMatrix,

    readData = readData,
    writeData = writeData
}

-- tx rx

---@param metatable table
---@param ... any
---@return any
local function read( metatable, ... )
    if metatable == nil then
        error( "metatable not found", 2 )
    end

    local fn = metatable.__rx
    if isfunction( fn ) then
        return fn( ... )
    else
        error( "metatable method __rx is missing", 2 )
    end
end

---@param value any
---@param ... any
---@return any
local function write( value, ... )
    local metatable = getmetatable( value )
    if metatable == nil then
        error( "metatable not found", 2 )
    end

    local fn = value.__tx
    if isfunction( fn ) then
        return fn( value, ... )
    else
        error( "metatable method __tx is missing", 2 )
    end
end

do

    local readers = {
        [ NUMBER ] = readNumber,
        [ STRING ] = readString,
        [ BOOLEAN ] = readBool,
        [ MATRIX ] = readMatrix,
        [ VECTOR ] = readVector,
        [ ANGLE ] = readAngle
    }

    local name2id = {
        bool = 0,
        boolean = 0,

        double = 1,
        number = 1,

        string = 2,

        VMatrix = 3,
        matrix = 3,

        Vector = 4,
        vector = 4,

        Angle = 5,
        angle = 5
    }

    local function readType( typeName )

    end

    local writers = {
        [ NUMBER ] = writeDouble,
        [ STRING ] = writeString,
        [ BOOLEAN ] = writeBit,
        [ MATRIX ] = writeMatrix,
        [ VECTOR ] = writeVector,
        [ ANGLE ] = writeAngle
    }

    local fn2id = {
        [ readBool ] = 0,
        [ writeBit ] = 0,

        [ readDouble ] = 1,
        [ writeDouble ] = 1,

        [ readString ] = 2,
        [ writeString ] = 2,

        [ readMatrix ] = 3,
        [ writeMatrix ] = 3,

        [ readVector ] = 4,
        [ writeVector ] = 4,

        [ readAngle ] = 5,
        [ writeAngle ] = 5
    }

    local function writeType( value, typeName )
        if value == nil then return end
    end

end

-- table
local function readTable()
    local result = {}
    ::read::

    local key = readType()
    if key == nil then
        return result
    end

    result[ key ] = readType()
    goto read

    return result
end

local function writeTable( tbl )
    local length = 0

    for key, value in pairs( tbl ) do
        writeType( key )
        writeType( value )
        length = length + 1
    end

    writeType( nil, 0 )
    return tbl, length
end

net.readTable = readTable
net.writeTable = writeTable


-- list
local function readList()
    local result = {}
    for index = 1, readUInt( readUInt( 5 ) ), 1 do
        result[ index ] = readType()
    end

    return result
end

local function writeList( tbl )
    local length = table_len( tbl )
    writeUInt( length, bit_size( length ) )

    for index = 1, length, 1 do
        writeType( tbl[ index ] )
    end
end

net.readList = readList
net.writeList = writeList

-- function ( 6 )
do

    local string_dump, string_len = string.dump, string.len
    -- import Compress, Decompress from util
    -- import load from environment

    local function readFunction()
        local binary = Decompress( readString() )
        if binary == nil or string_len( binary ) < 2 then
            return nil
        end

        return load( binary, nil, "b", getfenv( 2 ) )
    end

    local function writeFunction( func, stripDebugInfo )
        writeString( Compress( string_dump( func, stripDebugInfo ~= false ) ) )
        return nil
    end

    local metatable = debug_findmetatable( "function" )
    if metatable then
        metatable.__rx = readFunction
        metatable.__tx = writeFunction
    end

    net.readFunction = readFunction
    net.writeFunction = writeFunction

end

-- string
STRING.__rx = readString
STRING.__tx = writeString

-- number
NUMBER.__rx = readDouble
NUMBER.__tx = writeDouble

-- vector
VECTOR.__rx = readVector
VECTOR.__tx = writeVector

-- angle
ANGLE.__rx = readAngle
ANGLE.__tx = writeAngle

-- matrix
MATRIX.__rx = readMatrix
MATRIX.__tx = writeMatrix

-- entity
local function readEntity()
    local index = readUInt( 14 )
    if index == nil or index == 0 then
        return NULL
    else
        return Entity( index - 1 )
    end
end

local function writeEntity( entity )
    if entity and ENTITY_IsValid( entity ) then
        writeUInt( ENTITY_EntIndex( entity ) + 1, 14 )
    else
        writeUInt( 0, 14 )
    end
end

ENTITY.__rx = readEntity
ENTITY.__tx = writeEntity

net.readEntity = readEntity
net.writeEntity = writeEntity

-- Player ( 9 )
do

    local maxplayers_bits = bit_size( std.player.getLimit() )

    PLAYER.__bitcount = function()
        return maxplayers_bits
    end

    local function readPlayer()
        local index = readUInt( maxplayers_bits )
        if index == nil or index == 0 then
            return NULL
        else
            return Entity( index )
        end
    end

    local function writePlayer( player )
        if player and ENTITY_IsValid( player ) then
            writeUInt( ENTITY_EntIndex( player ), maxplayers_bits )
        else
            writeUInt( 0, maxplayers_bits )
        end
    end

    PLAYER.__rx = readPlayer
    PLAYER.__tx = writePlayer

    net.readPlayer = readPlayer
    net.writePlayer = writePlayer

end

-- TODO: https://wiki.facepunch.com/gmod/usermessage
-- TODO: https://wiki.facepunch.com/gmod/umsg
-- TODO: https://wiki.facepunch.com/gmod/Global.SuppressHostEvents

-- TODO: https://wiki.facepunch.com/gmod/util.NetworkIDToString
-- TODO: https://wiki.facepunch.com/gmod/util.NetworkStringToID
-- TODO: https://wiki.facepunch.com/gmod/util.AddNetworkString

return net
