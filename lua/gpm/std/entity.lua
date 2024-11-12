local _G = _G
local std = _G.gpm.std
local ents, scripted_ents, Entity, NULL, ents_GetMapCreatedEntity = _G.ents, _G.scripted_ents, _G.Entity, _G.NULL, ents.GetMapCreatedEntity

---@class Entity
local ENTITY = std.findMetatable( "Entity" )
local ENTITY_SetModel = ENTITY.SetModel

local library = {
    ["find"] = {
        ["alongRay"] = ents.FindAlongRay,
        ["byClass"] = ents.FindByClass,
        ["byModel"] = ents.FindByModel,
        ["byName"] = ents.FindByName,
        ["inBox"] = ents.FindInBox,
        ["inCone"] = ents.FindInCone,
        ["inSphere"] = ents.FindInSphere
    },
    ["useByName"] = ents.FireTargets,
    ["getCount"] = ents.GetCount,
    ["getAll"] = ents.GetAll,
    ["get"] = function( index, useMapCreationID )
        return ( useMapCreationID and ents_GetMapCreatedEntity or Entity )( index )
    end
}

do

    local VECTOR_DistToSqr = std.findMetatable( "Vector" ).DistToSqr

    local math_sqrt, math_huge
    do
        local math = std.math
        math_sqrt, math_huge = math.sqrt, math.huge
    end

    function library.find.closest( entities, origin )
        local closest, closest_distance = nil, 0

        for i = 1, #entities do
            local entity = entities[ i ]
            local distance = VECTOR_DistToSqr( origin, entity:GetPos() )
            if closest == nil or distance < closest_distance then
                closest, closest_distance = entity, distance
            end
        end

        if closest == nil then
            return NULL, math_huge
        else
            return closest, math_sqrt( closest_distance )
        end
    end

end

if std.CLIENT then
    library.create = ents.CreateClientside
    library.createProp = ents.CreateClientProp
elseif std.SERVER then
    local ents_Create = ents.Create
    library.create = ents_Create

    library.createProp = function( model )
        local entity = ents_Create( "prop_physics" )
        ENTITY_SetModel( entity, model or "models/error.mdl" )
        return entity
    end

    library.getEdictCount = ents.GetEdictCount

    -- find in pvs/pas
    do

        local is_entity = std.is.entity
        local find = library.find
        find.inPVS = ents.FindInPVS

        local inPAS = ents.FindInPAS
        if inPAS == nil then
            ---@class CRecipientFilter
            local FILTER = std.findMetatable( "CRecipientFilter" )
            local FILTER_GetPlayers = FILTER.GetPlayers
            local FILTER_AddPAS = FILTER.AddPAS

            local RecipientFilter = _G.RecipientFilter
            local ENTITY_EyePos = ENTITY.EyePos

            find.inPAS = function( viewPoint )
                local filter = RecipientFilter()
                if is_entity( viewPoint ) then
                    viewPoint = ENTITY_EyePos( viewPoint )
                end

                FILTER_AddPAS( filter, viewPoint )
                return FILTER_GetPlayers( filter )
            end
        end

    end

end

local entity_create = library.create
local classes = {}

-- TODO: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/scripted_ents.lua#L256-L260
scripted_ents.Get = _G.gpm.detour.attach( scripted_ents.Get, function( fn, name )
    local value = classes[ name ]
    if value == nil then
        return fn( name )
    end

    classes[ name ] = nil
    return value
end )

-- TODO: https://github.com/Facepunch/garrysmod/tree/master/garrysmod/gamemodes/base/entities/entities/base_entity

ENTITY.new = function( self )
    local cls = rawget( self, "__class" )
    if cls == nil then return true, NULL end

    local name = rawget( cls, "__name" )
    if name == nil then return true, NULL end

    classes[ name ] = self
    return true, entity_create( name )
end

return std.class( "entity", ENTITY, library )
