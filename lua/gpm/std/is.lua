local getmetatable, is_table, debug, findMetatable, registerMetatable, coroutine_create, CLIENT, SERVER, CLIENT_SERVER, CLIENT_MENU = ...
local debug_setmetatable = debug.setmetatable
local library = {}

-- nil ( 2 )
local object = nil
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "nil", metatable )

    library["nil"] = function( value )
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

    function library.bool( value )
        return getmetatable( value ) == metatable
    end

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

    function library.number( value )
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

    function library.string( value )
        return getmetatable( value ) == metatable
    end

end

-- table ( 5 )
library.table = is_table

-- function ( 6 )
object = debug.fempty
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "function", metatable )

    -- yeah here we have a little problem with key
    library["function"] = function( value )
        return getmetatable( value ) == metatable
    end

    function library.callable( value )
        local mtbl = getmetatable( value )
        return mtbl ~= nil and ( mtbl == metatable or getmetatable( mtbl.__call ) == metatable )
    end

end

-- userdata ( 7 )

-- thread ( 8 )
object = coroutine_create( object )
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "thread", metatable )

    function library.thread( value )
        return getmetatable( value ) == metatable
    end

end

if CLIENT_SERVER then
    local ENTITY = findMetatable( "Entity" )

    -- Entity ( 9 )
    function library.entity( value )
        local metatable = getmetatable( value )
        return metatable and metatable.__metatable_id == 9
    end

    local function returnTrue() return true end
    local function returnFalse() return false end

    ENTITY.IsClientEntity = returnFalse
    ENTITY.IsVehicle = returnFalse
    ENTITY.IsNextbot = returnFalse
    ENTITY.IsPlayer = returnFalse
    ENTITY.IsWeapon = returnFalse
    ENTITY.IsNPC = returnFalse

    -- Player ( 9 )
    do

        local metatable = findMetatable( "Player" )
        metatable.IsPlayer = returnTrue

        function library.player( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Weapon ( 9 )
    do

        local metatable = findMetatable( "Weapon" )
        metatable.IsWeapon = returnTrue

        function library.weapon( value )
            return getmetatable( value ) == metatable
        end

    end

    -- NPC ( 9 )
    do

        local metatable = findMetatable( "NPC" )
        metatable.IsNPC = returnTrue

        function library.npc( value )
            return getmetatable( value ) == metatable
        end

    end

    -- NextBot ( 9 )
    do

        local metatable = findMetatable( "NextBot" )
        metatable.IsNextbot = returnTrue

        function library.nextbot( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Vehicle ( 9 )
    do

        local metatable = findMetatable( "Vehicle" )
        metatable.IsVehicle = returnTrue

        function library.vehicle( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CSEnt ( 9 )
    if CLIENT then

        local metatable = findMetatable( "CSEnt" )
        metatable.IsClientEntity = returnTrue

        function library.clientEntity( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PhysObj ( 12 )
    do

        local metatable = findMetatable( "PhysObj" )

        function library.physics( value )
            return getmetatable( value ) == metatable
        end

    end

    -- ISave ( 13 )
    do

        local metatable = findMetatable( "ISave" )

        function library.save( value )
            return getmetatable( value ) == metatable
        end

    end

    -- IRestore ( 14 )
    do

        local metatable = findMetatable( "IRestore" )

        function library.restore( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CTakeDamageInfo ( 15 )
    do

        local metatable = findMetatable( "CTakeDamageInfo" )

        function library.damageInfo( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CEffectData ( 16 )
    do

        local metatable = findMetatable( "CEffectData" )

        function library.effectData( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CMoveData ( 17 )
    do

        local metatable = findMetatable( "CMoveData" )

        function library.movedata( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CUserCmd ( 19 )
    do

        local metatable = findMetatable( "CUserCmd" )

        function library.usercmd( value )
            return getmetatable( value ) == metatable
        end

    end

    -- bf_read ( 26 )
    do

        local metatable = findMetatable( "bf_read" )

        function library.userMessage( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PhysCollide ( 32 )
    do

        local metatable = findMetatable( "PhysCollide" )

        function library.physCollide( value )
            return getmetatable( value ) == metatable
        end

    end

    -- SurfaceInfo ( 33 )
    do

        local metatable = findMetatable( "SurfaceInfo" )

        function library.surfaceInfo( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- Vector ( 10 )
do

    local metatable = findMetatable( "Vector" )

    function library.vector( value )
        return getmetatable( value ) == metatable
    end

end

-- Angle ( 11 )
do

    local metatable = findMetatable( "Angle" )

    function library.angle( value )
        return getmetatable( value ) == metatable
    end

end

if SERVER then

    -- CRecipientFilter ( 18 )
    do

        local metatable = findMetatable( "CRecipientFilter" )

        function library.recipientFilter( value )
            return getmetatable( value ) == metatable
        end
    end

    -- CLuaLocomotion ( 35 )
    do

        local metatable = findMetatable( "CLuaLocomotion" )

        function library.locomotion( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PathFollower ( 36 )
    do

        local metatable = findMetatable( "PathFollower" )

        function library.pathFollower( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CNavArea ( 37 )
    do

        local metatable = findMetatable( "CNavArea" )

        function library.navArea( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CNavLadder ( 39 )
    do

        local metatable = findMetatable( "CNavLadder" )

        function library.navLadder( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- IMaterial ( 21 )
do

    local metatable = findMetatable( "IMaterial" )

    function library.material( value )
        return getmetatable( value ) == metatable
    end

end

-- Panel ( 22 )
if CLIENT_MENU then
    local metatable = findMetatable( "Panel" )

    function library.panel( value )
        return getmetatable( value ) == metatable
    end

end

if CLIENT then

    -- CLuaParticle ( 23 )
    do

        local metatable = findMetatable( "CLuaParticle" )

        function library.particle( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CLuaEmitter ( 24 )
    do

        local metatable = findMetatable( "CLuaEmitter" )

        function library.emitter( value )
            return getmetatable( value ) == metatable
        end

    end

    -- pixelvis_handle_t ( 31 )
    do

        local metatable = findMetatable( "pixelvis_handle_t" )

        function library.pixVis( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Dynamic Light ( 32 )
    do
        local metatable = findMetatable( "dlight_t" )

        function library.dynamiclight( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CNewParticleEffect ( 34 )
    do

        local metatable = findMetatable( "CNewParticleEffect" )

        function library.effect( value )
            return getmetatable( value ) == metatable
        end

    end

    -- ProjectedTexture ( 38 )
    do

        local metatable = findMetatable( "ProjectedTexture" )

        function library.projectedTexture( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- ITexture ( 25 )
do

    local metatable = findMetatable( "ITexture" )

    function library.texture( value )
        return getmetatable( value ) == metatable
    end

end

-- ConVar ( 27 )
do

    local metatable = findMetatable( "ConVar" )

    function library.convar( value )
        return getmetatable( value ) == metatable
    end

end

if CLIENT_MENU then

    -- IMesh ( 28 )
    do

        local metatable = findMetatable( "IMesh" )

        if metatable == nil then
            function library.mesh( value )
                return getmetatable( value ) == metatable
            end
        else
            function library.mesh( value )
                return false
            end
        end

    end

    -- IVideoWriter ( 33 )
    do

        local metatable = findMetatable( "IVideoWriter" )

        function library.videoWriter( value )
            return getmetatable( value ) == metatable
        end

    end

    -- IGModAudioChannel ( 38 )
    do

        local metatable = findMetatable( "IGModAudioChannel" )

        function library.audioChannel( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- VMatrix ( 29 )
do

    local metatable = findMetatable( "VMatrix" )

    function library.matrix( value )
        return getmetatable( value ) == metatable
    end

end

-- CSoundPatch ( 30 )
do

    local metatable = findMetatable( "CSoundPatch" )

    function library.sound( value )
        return getmetatable( value ) == metatable
    end

end

-- File ( 34 )
do

    local metatable = findMetatable( "File" )

    function library.file( value )
        return getmetatable( value ) == metatable
    end

    registerMetatable( "File", metatable )

end

-- Color ( 255 )
do

    local metatable = findMetatable( "Color" )

    function library.color( value )
        return getmetatable( value ) == metatable
    end

    registerMetatable( "Color", metatable )

end

return library
