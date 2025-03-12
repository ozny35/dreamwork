local _G = _G
local gpm = _G.gpm
local std = gpm.std
local class = std.class
local debug = std.debug

---@alias gpm.std.EntityType
---| integer # The type of the entity.
---| `0` # anim - A normal entity with visual and/or physical presence in the game world, such as props or whatever else you can imagine.
---| `1` # brush - A serverside only trigger entity. Mostly used very closely with the Hammer Level Editor.
---| `2` # point - A usually serverside only entity that doesn't have a visual or physical representation in the game world, such as logic entities.
---| `3` # nextbot - A NextBot NPC. A newer-type NPCs with better navigation.
---| `4` # ai - 2004 Source Engine NPC system entity.
---| `5` # filter - A different kind of "point" entity used in conjunction with trigger (brush type) entities.

-- local ents, Entity, NULL, ents_GetMapCreatedEntity = _G.ents, _G.Entity, _G.NULL, ents.GetMapCreatedEntity

-- ---@class Entity
-- local ENTITY = debug.findmetatable( "Entity" )
-- local ENTITY_SetModel = ENTITY.SetModel

-- ---@class gpm.std.entity
-- local entity = {
--     useByName = ents.FireTargets,
--     getCount = ents.GetCount,
--     iterator = ents.Iterator,
--     getAll = ents.GetAll,
--     get = function( index, useMapCreationID )
--         return ( useMapCreationID and ents_GetMapCreatedEntity or Entity )( index )
--     end
-- }

-- ---@class gpm.std.entity.find
-- local find = {
--     alongRay = ents.FindAlongRay,
--     byClass = ents.FindByClass,
--     byModel = ents.FindByModel,
--     byName = ents.FindByName,
--     inBox = ents.FindInBox,
--     inCone = ents.FindInCone,
--     inSphere = ents.FindInSphere
-- }

-- entity.find = find

-- do

--     local VECTOR_DistToSqr = debug.findmetatable( "Vector" ).DistToSqr

--     local math_sqrt, math_huge
--     do
--         local math = std.math
--         math_sqrt, math_huge = math.sqrt, math.huge
--     end

--     function find.closest( entities, origin )
--         local closest, closest_distance = nil, 0

--         for i = 1, #entities do
--             local value = entities[ i ]
--             local distance = VECTOR_DistToSqr( origin, value:GetPos() )
--             if closest == nil or distance < closest_distance then
--                 closest, closest_distance = value, distance
--             end
--         end

--         if closest == nil then
--             return NULL, math_huge
--         else
--             return closest, math_sqrt( closest_distance )
--         end
--     end

-- end

-- ---@class gpm.std.entity.damage
-- local damage = {}

-- -- https://wiki.facepunch.com/gmod/Global.DamageInfo

-- entity.damage = damage

-- if std.CLIENT then
--     entity.create = ents.CreateClientside
--     entity.createProp = ents.CreateClientProp
-- elseif std.SERVER then
--     local ents_Create = ents.Create
--     entity.create = ents_Create

--     entity.createProp = function( model )
--         local obj = ents_Create( "prop_physics" )
--         ENTITY_SetModel( obj, model or "models/error.mdl" )
--         return obj
--     end

--     entity.getEdictCount = ents.GetEdictCount

--     -- find in pvs/pas
--     do

--         local is_entity = std.is.entity
--         find.inPVS = ents.FindInPVS

--         local inPAS = ents.FindInPAS
--         if inPAS == nil then
--             ---@class CRecipientFilter
--             local FILTER = debug.findmetatable( "CRecipientFilter" )
--             local FILTER_GetPlayers = FILTER.GetPlayers
--             local FILTER_AddPAS = FILTER.AddPAS

--             local RecipientFilter = _G.RecipientFilter
--             local ENTITY_EyePos = ENTITY.EyePos

--             function find.inPAS( viewPoint )
--                 local filter = RecipientFilter()
--                 if is_entity( viewPoint ) then
--                     viewPoint = ENTITY_EyePos( viewPoint )
--                 end

--                 FILTER_AddPAS( filter, viewPoint )
--                 return FILTER_GetPlayers( filter )
--             end
--         end

--     end

-- end

-- -- TODO: Add https://wiki.facepunch.com/gmod/util.SpriteTrail

-- -- TODO: Add https://wiki.facepunch.com/gmod/Global.ClientsideModel
-- -- TODO: Add https://wiki.facepunch.com/gmod/Global.ClientsideRagdoll
-- -- TODO: Add https://wiki.facepunch.com/gmod/Global.ClientsideScene

-- local entity_create = entity.create

-- -- TODO: https://github.com/Facepunch/garrysmod/tree/master/garrysmod/gamemodes/base/entities/entities/base_entity

-- ENTITY.new = function( self )
--     local cls = rawget( self, "__class" )
--     if cls == nil then return true, NULL end

--     local name = rawget( cls, "__type" )
--     if name == nil then return true, NULL end

--     classes[ name ] = self
--     return true, entity_create( name )
-- end

-- TODO: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/scripted_ents.lua#L256-L260

local glua_ents = _G.ents

---@alias Entity gpm.std.Entity
---@class gpm.std.Entity: gpm.std.Object
---@field __class gpm.std.EntityClass
---@field Type gpm.std.EntityType: The type of the entity.
local Entity = class.base( "Entity" )

---@class gpm.std.EntityClass: gpm.std.Entity
---@field __base gpm.std.Entity
---@overload fun(): Entity
local EntityClass = class.create( Entity )

do

    local engine_hookCatch = gpm.engine.hookCatch
    local Hook = std.Hook

    local Created = Hook( "Entity.Created" )
    engine_hookCatch( "OnEntityCreated", Created, 1 )
    EntityClass.Created = Created

    if std.SERVER then

        --- [SERVER] A hook that is called when map I/O event occurs.
        local MapEvent = Hook( "Entity.MapEvent" )
        engine_hookCatch( "AcceptInput", MapEvent, 1 )
        EntityClass.MapEvent = MapEvent

    end

end

do


    local registry = {}

    local scripted_ents = _G.scripted_ents
    if scripted_ents == nil then
        ---@diagnostic disable-next-line: inject-field
        scripted_ents = {}; _G.scripted_ents = scripted_ents
    end

    local entity2object = {}

    local translator = {
        Think = function( entity )
            print( "entity think", entity, entity2object[ entity ] )
            -- local fn = entity2object[ entity ].think
            -- return fn ~= nil and fn( entity )
        end
    }

    local typeid2type = {
        [ 0 ] = "anim",
        [ 1 ] = "brush",
        [ 2 ] = "point",
        [ 3 ] = "ai",
        [ 4 ] = "nextbot",
        [ 5 ] = "filter"
    }

    if scripted_ents.Get == nil then

        function scripted_ents.Get( identifier )
            local metatable = registry[ identifier ]
            if metatable ~= nil then
                translator.Type = typeid2type[ metatable.Type or 0 ] or "anim"
                return translator
            end
        end

    else

        scripted_ents.Get = gpm.detour.attach( scripted_ents.Get, function( fn, identifier )
            local metatable = registry[ identifier ]
            if metatable == nil then
                return fn( identifier )
            else
                translator.Type = typeid2type[ metatable.Type or 0 ] or "anim"
                return translator
            end
        end )

    end

    local class_init = class.init

    local ENTITY_GetClass = std.debug.findmetatable( "Entity" ).GetClass

    local function init( entity )
        print( entity )

        local metatable = registry[ ENTITY_GetClass( entity ) ]
        if metatable == nil then return end
        translator.Type = nil

        local object = { __userdata = entity }
        setmetatable( object, metatable )

        entity2object[ entity ] = object
        class_init( object, metatable )
        return object
    end

    local ents_Create = SERVER and glua_ents.Create or glua_ents.CreateClientside

    function Entity:__new()
        local entity = ents_Create( self.__type )
        if entity == nil then return NULL end -- TODO: replace with custom NULL class
        return init( entity )
    end

    function EntityClass.__inherited( _, cls )
        local base = cls.__base
        registry[ base.__type ] = base
    end

    -- CreatedHook:attach( "gpm - entity created", function( entity )
    --     init( entity )
    -- end, -2 )

end

-- local test_entity = class.base( "test_entity", EntityClass )
-- function test_entity:think()
--     print( "test" )
-- end


-- local test_entity_class = class.create( test_entity )

if SERVER then

    -- hook.Add("OnEntityCreated", "test", function( e )
    --     timer.Simple( 0, function()
    --         print( debug.getmetatable( e ).s )
    --         print( e:GetTable().s )
    --         print( e )
    --     end )
    -- end)

    -- local e = test_entity_class()
    -- e.__userdata:Spawn()

    -- PrintTable( e.__userdata:GetTable() )

end

return EntityClass
