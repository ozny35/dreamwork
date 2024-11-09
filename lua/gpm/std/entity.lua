local _G, math, findMetatable, CLIENT, SERVER, is_entity, detour, class = ...
local ents, scripted_ents = _G.ents, _G.scripted_ents

local Entity, NULL, ents_GetMapCreatedEntity = _G.Entity, _G.NULL, ents.GetMapCreatedEntity

local ENTITY = findMetatable( "Entity" )
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

    local VECTOR_DistToSqr = findMetatable( "Vector" ).DistToSqr
    local math_sqrt, math_huge = math.sqrt, math.huge

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

if CLIENT then
    library.create = ents.CreateClientside
    library.createProp = ents.CreateClientProp
elseif SERVER then
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

        local find = library.find
        find.inPVS = ents.FindInPVS

        local inPAS = ents.FindInPAS
        if inPAS == nil then
            local FILTER = findMetatable( "CRecipientFilter" )
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
scripted_ents.Get = detour.attach( scripted_ents.Get, function( fn, name )
    local value = classes[ name ]
    if value == nil then
        return fn( name )
    end

    classes[ name ] = nil
    return value
end )

do

    -- TODO: Think about moving this into globals
    library.weapon = {
        ["ammo"] = {
            -- https://wiki.facepunch.com/gmod/game.AddAmmoType
            -- https://wiki.facepunch.com/gmod/game.BuildAmmoTypes
            -- https://wiki.facepunch.com/gmod/game.GetAmmoDamageType
            -- ...
            -- https://wiki.facepunch.com/gmod/game.GetAmmoTypes
        }
    }

end

-- do

    -- TODO: create particle class for registry and creation

-- end


-- TODO: Decals lib/class in globals

-- TODO: https://github.com/Facepunch/garrysmod/tree/master/garrysmod/gamemodes/base/entities/entities/base_entity

ENTITY.new = function( self )
    local cls = rawget( self, "__class" )
    if cls == nil then return true, NULL end

    local name = rawget( cls, "__name" )
    if name == nil then return true, NULL end

    classes[ name ] = self
    return true, entity_create( name )
end

return class( "entity", ENTITY, library )
