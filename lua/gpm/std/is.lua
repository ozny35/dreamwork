local _G = _G

---@class gpm.std
local std = _G.gpm.std
local debug_setmetatable = _G.debug.setmetatable
local getmetatable, findMetatable, registerMetatable = std.getmetatable, std.findMetatable, std.registerMetatable

---@class gpm.std.is
local is = {}

-- nil ( 0 )
local object = nil
do

    local metatable = getmetatable( object )
    if metatable == nil then
        metatable = {}
        debug_setmetatable( object, metatable )
    end

    registerMetatable( "nil", metatable )

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

    ---Checks if the value is a function
    ---@param value any
    ---@return boolean isFunction returns true if the value is a function, otherwise false
    function is.fn( value )
        return getmetatable( value ) == metatable
    end

    is.func = is.fn
    is["function"] = is.fn

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

    function is.thread( value )
        return getmetatable( value ) == metatable
    end

end

if std.CLIENT_SERVER then
    local ENTITY = findMetatable( "Entity" )

    -- Entity ( 9 )
    function is.entity( value )
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

        function is.player( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Weapon ( 9 )
    do

        local metatable = findMetatable( "Weapon" )
        metatable.IsWeapon = returnTrue

        function is.weapon( value )
            return getmetatable( value ) == metatable
        end

    end

    -- NPC ( 9 )
    do

        local metatable = findMetatable( "NPC" )
        metatable.IsNPC = returnTrue

        function is.npc( value )
            return getmetatable( value ) == metatable
        end

    end

    -- NextBot ( 9 )
    do

        local metatable = findMetatable( "NextBot" )
        metatable.IsNextbot = returnTrue

        function is.nextbot( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Vehicle ( 9 )
    do

        local metatable = findMetatable( "Vehicle" )
        metatable.IsVehicle = returnTrue

        function is.vehicle( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CSEnt ( 9 )
    if std.CLIENT then

        local metatable = findMetatable( "CSEnt" )
        metatable.IsClientEntity = returnTrue

        function is.clientEntity( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PhysObj ( 12 )
    do

        local metatable = findMetatable( "PhysObj" )

        function is.physics( value )
            return getmetatable( value ) == metatable
        end

    end

    -- ISave ( 13 )
    do

        local metatable = findMetatable( "ISave" )

        function is.save( value )
            return getmetatable( value ) == metatable
        end

    end

    -- IRestore ( 14 )
    do

        local metatable = findMetatable( "IRestore" )

        function is.restore( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CTakeDamageInfo ( 15 )
    do

        local metatable = findMetatable( "CTakeDamageInfo" )

        function is.damageInfo( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CEffectData ( 16 )
    do

        local metatable = findMetatable( "CEffectData" )

        function is.effectData( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CMoveData ( 17 )
    do

        local metatable = findMetatable( "CMoveData" )

        function is.movedata( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CUserCmd ( 19 )
    do

        local metatable = findMetatable( "CUserCmd" )

        function is.usercmd( value )
            return getmetatable( value ) == metatable
        end

    end

    -- bf_read ( 26 )
    do

        local metatable = findMetatable( "bf_read" )

        function is.userMessage( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PhysCollide ( 32 )
    do

        local metatable = findMetatable( "PhysCollide" )

        function is.physCollide( value )
            return getmetatable( value ) == metatable
        end

    end

    -- SurfaceInfo ( 33 )
    do

        local metatable = findMetatable( "SurfaceInfo" )

        function is.surfaceInfo( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- Vector ( 10 )
do

    local metatable = findMetatable( "Vector" )

    function is.vector( value )
        return getmetatable( value ) == metatable
    end

end

-- Angle ( 11 )
do

    local metatable = findMetatable( "Angle" )

    function is.angle( value )
        return getmetatable( value ) == metatable
    end

end

if std.SERVER then

    -- CRecipientFilter ( 18 )
    do

        local metatable = findMetatable( "CRecipientFilter" )

        function is.recipientFilter( value )
            return getmetatable( value ) == metatable
        end
    end

    -- CLuaLocomotion ( 35 )
    do

        local metatable = findMetatable( "CLuaLocomotion" )

        function is.locomotion( value )
            return getmetatable( value ) == metatable
        end

    end

    -- PathFollower ( 36 )
    do

        local metatable = findMetatable( "PathFollower" )

        function is.pathFollower( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CNavArea ( 37 )
    do

        local metatable = findMetatable( "CNavArea" )

        function is.navArea( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CNavLadder ( 39 )
    do

        local metatable = findMetatable( "CNavLadder" )

        function is.navLadder( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- IMaterial ( 21 )
do

    local metatable = findMetatable( "IMaterial" )

    function is.material( value )
        return getmetatable( value ) == metatable
    end

end

if std.CLIENT then

    -- CLuaParticle ( 23 )
    do

        local metatable = findMetatable( "CLuaParticle" )

        function is.particle( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CLuaEmitter ( 24 )
    do

        local metatable = findMetatable( "CLuaEmitter" )

        function is.emitter( value )
            return getmetatable( value ) == metatable
        end

    end

    -- pixelvis_handle_t ( 31 )
    do

        local metatable = findMetatable( "pixelvis_handle_t" )

        function is.pixVis( value )
            return getmetatable( value ) == metatable
        end

    end

    -- Dynamic Light ( 32 )
    do
        local metatable = findMetatable( "dlight_t" )

        function is.dynamiclight( value )
            return getmetatable( value ) == metatable
        end

    end

    -- CNewParticleEffect ( 34 )
    do

        local metatable = findMetatable( "CNewParticleEffect" )

        function is.effect( value )
            return getmetatable( value ) == metatable
        end

    end

    -- ProjectedTexture ( 38 )
    do

        local metatable = findMetatable( "ProjectedTexture" )

        function is.projectedTexture( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- ITexture ( 25 )
do

    local metatable = findMetatable( "ITexture" )

    function is.texture( value )
        return getmetatable( value ) == metatable
    end

end

-- ConVar ( 27 )
do

    local metatable = findMetatable( "ConVar" )

    function is.convar( value )
        return getmetatable( value ) == metatable
    end

end

if std.CLIENT_MENU then

    -- Panel ( 22 )
    do

        local metatable = findMetatable( "Panel" )

        function is.panel( value )
            return getmetatable( value ) == metatable
        end

    end

    -- IMesh ( 28 )
    do

        local metatable = findMetatable( "IMesh" )

        if metatable == nil then
            function is.mesh( value )
                return getmetatable( value ) == metatable
            end
        else
            function is.mesh( value )
                return false
            end
        end

    end

    -- IVideoWriter ( 33 )
    do

        local metatable = findMetatable( "IVideoWriter" )

        function is.videoWriter( value )
            return getmetatable( value ) == metatable
        end

    end

    -- IGModAudioChannel ( 38 )
    do

        local metatable = findMetatable( "IGModAudioChannel" )

        function is.audioChannel( value )
            return getmetatable( value ) == metatable
        end

    end

end

-- VMatrix ( 29 )
do

    local metatable = findMetatable( "VMatrix" )

    function is.matrix( value )
        return getmetatable( value ) == metatable
    end

end

-- CSoundPatch ( 30 )
do

    local metatable = findMetatable( "CSoundPatch" )

    function is.sound( value )
        return getmetatable( value ) == metatable
    end

end

-- File ( 34 )
do

    local metatable = findMetatable( "File" )

    function is.file( value )
        return getmetatable( value ) == metatable
    end

    registerMetatable( "File", metatable )

end

-- Error ( 45 )
do

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

    function is.color( value )
        return is_table( value ) and is_number( value.r ) and is_number( value.g ) and is_number( value.b ) and is_number( value.a )
    end

end

return is
