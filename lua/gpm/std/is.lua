local _G = _G

---@class gpm.std
local std = _G.gpm.std
local debug_setmetatable = _G.debug.setmetatable
local getmetatable, findMetatable, registerMetatable = std.getmetatable, std.findMetatable, std.registerMetatable

--- Table of functions to check the type of a value.
---@class gpm.std.is
local is = {}

-- Table of functions to check the validity of a value.
---@class gpm.std.is.valid
---@overload fun(value: any): boolean
local valid = {}
is.valid = valid

---@diagnostic disable-next-line: param-type-mismatch
setmetatable( valid, {
    __call = function( _, value )
        local metatable = getmetatable( value )
        return ( metatable and metatable.__isvalid and metatable.__isvalid( value ) ) == true
    end
} )

-- nil ( 0 )
local object = nil
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "nil", metatable )

    --- Checks if the value type is `nil`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value type is `nil`, otherwise `false`.
    is["nil"] = function( value )
        return getmetatable( value ) == metatable
    end

end

-- boolean ( 1 )
object = false
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "boolean", metatable )

    --- Checks if the value type is a `boolean`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a boolean, otherwise `false`.
    function is.bool( value )
        return getmetatable( value ) == metatable
    end

    is.boolean = is.bool

end

-- light userdata ( 2 )

-- number ( 3 )
object = 0
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "number", metatable )

    --- Checks if the value type is a `number`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a number, otherwise `false`.
    function is.number( value )
        return getmetatable( value ) == metatable
    end

end

-- string ( 4 )
object = ""
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "string", metatable )

    --- Checks if the value type is a `string`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a string, otherwise `false`.
    function is.string( value )
        return getmetatable( value ) == metatable
    end

end

-- table ( 5 )
is.table = _G.istable

-- function ( 6 )
object = std.debug.fempty
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "function", metatable )

    --- Checks if the value type is a `function`.
    ---@param value any
    ---@return boolean isFunction returns true if the value is a function, otherwise false
    function is.fn( value )
        return getmetatable( value ) == metatable
    end

    is.func = is.fn
    is["function"] = is.fn

    --- Checks if the value is callable.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is can be called (like a function), otherwise `false`.
    function is.callable( value )
        local mtbl = getmetatable( value )
        return mtbl ~= nil and ( mtbl == metatable or getmetatable( mtbl.__call ) == metatable )
    end

end

-- userdata ( 7 )

-- thread ( 8 )
object = _G.coroutine.create( object )
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "thread", metatable )

    --- Checks if the value type is a `thread`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a thread, otherwise `false`.
    function is.thread( value )
        return getmetatable( value ) == metatable
    end

end

if std.CLIENT_SERVER then
    do

        local util = _G.util

        valid.prop = util.IsValidProp
        valid.model = util.IsValidModel
        valid.ragdoll = util.IsValidRagdoll

    end

    ---@class Entity
    local ENTITY = findMetatable( "Entity" )

    --- Checks if the value type is an `entity`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is an entity (SENT, Player, Weapon, NPC, Vehicle, CSEnt, and NextBot), otherwise `false`.
    function is.entity( value )
        local metatable = getmetatable( value )
        return metatable and metatable.__metatable_id == 9
    end

    valid.entity = ENTITY.IsValid

    -- Player ( 9 )
    do

        ---@class Player
        local metatable = findMetatable( "Player" )

        --- Checks if the value type is a `player`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a player, otherwise `false`.
        function is.player( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Weapon ( 9 )
    do

        ---@class Weapon
        local metatable = findMetatable( "Weapon" )

        --- Checks if the value type is a `weapon`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a weapon, otherwise `false`.
        function is.weapon( value )
            return getmetatable( value ) == metatable
        end

    end

    -- NPC ( 9 )
    do

        ---@class NPC
        local metatable = findMetatable( "NPC" )

        --- Checks if the value type is an `npc`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is an NPC, otherwise `false`.
        function is.npc( value )
            return getmetatable( value ) == metatable
        end

    end

    -- NextBot ( 9 )
    do

        ---@class NextBot
        local metatable = findMetatable( "NextBot" )

        --- Checks if the value type is a `nextbot`.
        ---@param value any: The value to check.
        ---@return boolean
        function is.nextbot( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Vehicle ( 9 )
    do

        ---@class Vehicle
        local metatable = findMetatable( "Vehicle" )

        --- Checks if the value type is a `vehicle`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a vehicle, otherwise `false`.
        function is.vehicle( value )
            return getmetatable( value ) == metatable
        end

        valid.vehicle = metatable.IsValidVehicle

    end

    -- CSEnt ( 9 )
    if std.CLIENT then

        ---@class CSEnt
        local metatable = findMetatable( "CSEnt" )

        --- Checks if the value type is a `client entity` (or `CSEnt`).
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a client entity, otherwise `false`.
        function is.clientEntity( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PhysObj ( 12 )
    do

        ---@class PhysObj
        local metatable = findMetatable( "PhysObj" )

        --- Checks if the value type is a `physics object`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a physics object, otherwise `false`.
        function is.physics( value )
            return getmetatable( value ) == metatable
        end

        valid.physics = metatable.IsValid

    end

    -- ISave ( 13 )
    do

        ---@class ISave
        local metatable = findMetatable( "ISave" )

        --- Checks if the value type is an `ISave`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is an `ISave`, otherwise `false`.
        function is.save( value )
            return getmetatable( value ) == metatable
        end

    end

    -- IRestore ( 14 )
    do

        ---@class IRestore
        local metatable = findMetatable( "IRestore" )

        --- Checks if the value type is an `IRestore`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is an `IRestore`, otherwise `false`.
        function is.restore( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CTakeDamageInfo ( 15 )
    do

        ---@class CTakeDamageInfo
        local metatable = findMetatable( "CTakeDamageInfo" )

        --- Checks if the value type is a `damage info`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a damage info, otherwise `false`.
        function is.damageInfo( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CEffectData ( 16 )
    do

        ---@class CEffectData
        local metatable = findMetatable( "CEffectData" )

        --- Checks if the value type is an `CEffectData`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is an effect data, otherwise `false`.
        function is.effectData( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CMoveData ( 17 )
    do

        ---@class CMoveData
        local metatable = findMetatable( "CMoveData" )

        --- Checks if the value type is a `CMoveData`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a move data, otherwise `false`.
        function is.movedata( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CUserCmd ( 19 )
    do

        ---@class CUserCmd
        local metatable = findMetatable( "CUserCmd" )

        --- Checks if the value type is a `CUserCmd`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a user command, otherwise `false`.
        function is.usercmd( value )
            return getmetatable( value ) == metatable
        end

    end

    -- bf_read ( 26 )
    do

        ---@class bf_read
        local metatable = findMetatable( "bf_read" )

        --- Checks if the value type is a `bf_read` (aka `usmg` or `usermessage`).
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a bf_read, otherwise `false`.
        function is.userMessage( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PhysCollide ( 32 )
    do

        ---@class PhysCollide
        local metatable = findMetatable( "PhysCollide" )

        --- Checks if the value type is a `PhysCollide`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a physics collide, otherwise `false`.
        function is.physCollide( value )
            return getmetatable( value ) == metatable
        end

        valid.physCollide = metatable.IsValid

    end

    -- SurfaceInfo ( 33 )
    do

        ---@class SurfaceInfo
        local metatable = findMetatable( "SurfaceInfo" )

        --- Checks if the value type is a `SurfaceInfo`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a surface info, otherwise `false`.
        function is.surfaceInfo( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- Vector ( 10 )
do

    ---@class Vector
    local metatable = findMetatable( "Vector" )

    --- Checks if the value type is a `Vector`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a vector, otherwise `false`.
    function is.vector( value )
        return getmetatable( value ) == metatable
    end

end

-- Angle ( 11 )
do

    ---@class Angle
    local metatable = findMetatable( "Angle" )

    --- Checks if the value type is an `Angle`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is an angle, otherwise `false`.
    function is.angle( value )
        return getmetatable( value ) == metatable
    end

end

if std.SERVER then

    -- CRecipientFilter ( 18 )
    do

        ---@class CRecipientFilter
        local metatable = findMetatable( "CRecipientFilter" )

        --- Checks if the value type is a `CRecipientFilter`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a recipient filter, otherwise `false`.
        function is.recipientFilter( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CLuaLocomotion ( 35 )
    do

        ---@class CLuaLocomotion
        local metatable = findMetatable( "CLuaLocomotion" )

        --- Checks if the value type is a `CLuaLocomotion`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a locomotion, otherwise `false`.
        function is.locomotion( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PathFollower ( 36 )
    do

        ---@class PathFollower
        local metatable = findMetatable( "PathFollower" )

        --- Checks if the value type is a `PathFollower`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a path follower, otherwise `false`.
        function is.pathFollower( value )
            return getmetatable( value ) == metatable
        end

        valid.pathFollower = metatable.IsValid

    end

    -- CNavArea ( 37 )
    do

        ---@class CNavArea
        local metatable = findMetatable( "CNavArea" )

        --- Checks if the value type is a `CNavArea`.
        --- @param value any: The value to check.
        --- @return boolean: Returns `true` if the value is a nav area, otherwise `false`.
        function is.navArea( value )
            return getmetatable( value ) == metatable
        end

        valid.navArea = metatable.IsValid

    end

    -- CNavLadder ( 39 )
    do

        ---@class CNavLadder
        local metatable = findMetatable( "CNavLadder" )

        --- Checks if the value type is a `CNavLadder`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a nav ladder, otherwise `false`.
        function is.navLadder( value )
            return getmetatable( value ) == metatable
        end

        valid.navLadder = metatable.IsValid

    end

end

-- IMaterial ( 21 )
do

    ---@class IMaterial
    local metatable = findMetatable( "IMaterial" )

    --- Checks if the value type is a `IMaterial`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a material, otherwise `false`.
    function is.material( value )
        return getmetatable( value ) == metatable
    end

end

if std.CLIENT then

    -- CLuaParticle ( 23 )
    do

        ---@class CLuaParticle
        local metatable = findMetatable( "CLuaParticle" )

        --- Checks if the value type is a `CLuaParticle`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a particle, otherwise `false`.
        function is.particle( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CLuaEmitter ( 24 )
    do

        ---@class CLuaEmitter
        local metatable = findMetatable( "CLuaEmitter" )

        --- Checks if the value type is a `CLuaEmitter`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is an emitter, otherwise `false`.
        function is.emitter( value )
            return getmetatable( value ) == metatable
        end

        valid.emitter = metatable.IsValid

    end

    -- pixelvis_handle_t ( 31 )
    do

        ---@class pixelvis_handle_t
        local metatable = findMetatable( "pixelvis_handle_t" )

        --- Checks if the value type is a `pixelvis_handle_t`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a pixel vis handle, otherwise `false`.
        function is.pixVis( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Dynamic Light ( 32 )
    do

        ---@class dlight_t
        local metatable = findMetatable( "dlight_t" )

        --- Checks if the value type is a `dlight_t`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a dynamic light, otherwise `false`.
        function is.dynamiclight( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CNewParticleEffect ( 34 )
    do

        ---@class CNewParticleEffect
        local metatable = findMetatable( "CNewParticleEffect" )

        --- Checks if the value type is a `CNewParticleEffect`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a particle effect, otherwise `false`.
        function is.particleEffect( value )
            return getmetatable( value ) == metatable
        end

        valid.particleEffect = metatable.IsValid

    end

    -- ProjectedTexture ( 38 )
    do

        ---@class ProjectedTexture
        local metatable = findMetatable( "ProjectedTexture" )

        --- Checks if the value type is a `ProjectedTexture`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a projected texture, otherwise `false`.
        function is.projectedTexture( value )
            return getmetatable( value ) == metatable
        end

        valid.projectedTexture = metatable.IsValid

    end

end

-- ITexture ( 25 )
do

    ---@class ITexture
    local metatable = findMetatable( "ITexture" )

    --- Checks if the value type is a `ITexture`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a texture, otherwise `false`.
    function is.texture( value )
        return getmetatable( value ) == metatable
    end

end

-- ConVar ( 27 )
do

    ---@class ConVar
    local metatable = findMetatable( "ConVar" )

    --- Checks if the value type is a `ConVar`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a convar, otherwise `false`.
    function is.convar( value )
        return getmetatable( value ) == metatable
    end

end

if std.CLIENT_MENU then

    -- Panel ( 22 )
    do

        ---@class Panel
        local metatable = findMetatable( "Panel" )

        --- Checks if the value type is a `Panel`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a panel, otherwise `false`.
        function is.panel( value )
            return getmetatable( value ) == metatable
        end

        valid.panel = metatable.IsValid

    end

    -- IMesh ( 28 )
    do

        ---@class IMesh
        local metatable = findMetatable( "IMesh" )

        if metatable == nil then
            function is.mesh() return false end
        else

            --- Checks if the value type is a `IMesh`.
            ---@param value any: The value to check.
            ---@return boolean: Returns `true` if the value is a mesh, otherwise `false`.
            function is.mesh( value )
                return getmetatable( value ) == metatable
            end

            valid.mesh = metatable.IsValid

        end

    end

    -- IVideoWriter ( 33 )
    do

        ---@class IVideoWriter
        local metatable = findMetatable( "IVideoWriter" )

        --- Checks if the value type is a `IVideoWriter`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is a video writer, otherwise `false`.
        function is.videoWriter( value )
            return getmetatable( value ) == metatable
        end

    end

    -- IGModAudioChannel ( 38 )
    do

        ---@class IGModAudioChannel
        local metatable = findMetatable( "IGModAudioChannel" )

        --- Checks if the value type is a `IGModAudioChannel`.
        ---@param value any: The value to check.
        ---@return boolean: Returns `true` if the value is an audio channel, otherwise `false`.
        function is.audioChannel( value )
            return getmetatable( value ) == metatable
        end

        valid.audioChannel = metatable.IsValid

    end

end

-- VMatrix ( 29 )
do

    ---@class VMatrix
    local metatable = findMetatable( "VMatrix" )

    --- Checks if the value type is a `VMatrix`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a matrix, otherwise `false`.
    function is.matrix( value )
        return getmetatable( value ) == metatable
    end

end

-- CSoundPatch ( 30 )
do

    ---@class CSoundPatch
    local metatable = findMetatable( "CSoundPatch" )

    --- Checks if the value is a `CSoundPatch`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a sound patch, otherwise `false`.
    function is.sound( value )
        return getmetatable( value ) == metatable
    end

end

-- File ( 34 )
do

    ---@class File
    local metatable = findMetatable( "File" )

    --- Checks if the value is a `File`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a file, otherwise `false`.
    function is.file( value )
        return getmetatable( value ) == metatable
    end

    registerMetatable( "File", metatable )

end

-- Error ( 45 )
do

    --- Checks if the value is an error.
    ---@param value any: The value to check.
    ---@param name string?: The name of the error.
    ---@return boolean: Returns `true` if the value is an error, otherwise `false`.
    function is.error( value, name )
        if name == nil then name = "Error" end

        local metatable = getmetatable( value )
        if metatable == nil then return false end

        local class = metatable.__class
        while class ~= nil do
            if class.__name == name then return true end
            class = class.__parent
        end

        return false
    end

end

-- Color ( 255 )
do

    local is_table, is_number = is.table, is.number

    --- Checks if the value is a `color`.
    ---@param value any: The value to check.
    ---@return boolean: Returns `true` if the value is a color, otherwise `false`.
    function is.color( value )
        return is_table( value ) and is_number( value.r ) and is_number( value.g ) and is_number( value.b ) and is_number( value.a )
    end

end

return is
