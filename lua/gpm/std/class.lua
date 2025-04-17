---@class gpm.std
local std = _G.gpm.std

local debug = std.debug
local string = std.string

local raw_get = std.raw.get
local string_format = string.format
local setmetatable = std.setmetatable
local debug_getmetatable = debug.getmetatable

--- [SHARED AND MENU]
---
--- The class library.
---@class gpm.std.class
local class = {}
std.class = class

---@class gpm.std.Object
---@field __type string The name of object type.
---@field __class Class The class of the object (must be defined).
---@field __parent gpm.std.Object | nil: The parent of the object.
---@alias Object gpm.std.Object

---@class gpm.std.Class : gpm.std.Object
---@field __base gpm.std.Object: The base of the class (must be defined).
---@field __parent gpm.std.Class | nil: The parent of the class.
---@field __inherited fun( parent: gpm.std.Class, child: gpm.std.Class ) | nil: The function that will be called when the class is inherited.
---@alias Class gpm.std.Class

---@param obj Object The object to search in.
---@param key string The key to search for.
local function find_rawkey( obj, key )
    if obj == nil then return nil end
    return raw_get( obj, key ) or find_rawkey( debug_getmetatable( obj ), key )
end

do

    local string_sub = string.sub
    local pairs = std.pairs

    ---@param obj Object The object to convert to a string.
    ---@return string str The string representation of the object.
    local function base__tostring( obj )
        return string_format( "%s: %p", raw_get( debug_getmetatable( obj ), "__type" ), obj )
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a new class base ( metatable ).
    ---@param name string The name of the class.
    ---@param parent Class | unknown | nil: The parent of the class.
    ---@return Object base The base of the class.
    function class.base( name, parent )
        local base = {
            __type = name,
            __tostring = base__tostring
        }

        base.__index = base

        if parent then
            local parent_base = raw_get( parent, "__base" )
            if parent_base == nil then
                std.error( "parent class has no base", 2 )
            end

            ---@cast parent_base gpm.std.Object
            base.__parent = parent_base
            setmetatable( base, { __index = parent_base } )

            -- copy metamethods from parent
            for key, value in pairs( parent_base ) do
                if string_sub( key, 1, 2 ) == "__" and not ( key == "__index" and value == parent_base ) and key ~= "__type" then
                    base[ key ] = value
                end
            end
        end

        return base
    end

end

do

    local class__call
    do

        --- [SHARED AND MENU]
        ---
        --- Calls the base initialization function, <b>if it exists</b>, and returns the given object.
        ---@param obj table The object to initialize.
        ---@param base Object The base object, aka metatable.
        ---@param ... any?: Arguments to pass to the constructor.
        ---@return Object object The initialized object.
        local function init( obj, base, ... )
            local init_fn = find_rawkey( base, "__init" )
            if init_fn ~= nil then
                init_fn( obj, ... )
            end

            ---@diagnostic disable-next-line: return-type-mismatch
            return obj
        end

        class.init = init

        ---@param self Class The class.
        ---@return Object object The new object.
        function class__call( self, ... )
            local base = find_rawkey( self, "__base" )
            if base == nil then
                std.error( "class base is missing, class creation failed.", 2 )
            end

            ---@cast base gpm.std.Object

            local new_fn, obj = find_rawkey( base, "__new" )
            if new_fn ~= nil then
                obj = new_fn( base, ... )
            end

            if obj == nil then
                obj = {}
                setmetatable( obj, base )
            end

            local init_fn = find_rawkey( base, "__init" )
            if init_fn ~= nil then
                init_fn( obj, ... )
            end

            return obj
        end

    end

    ---@param cls Class The class.
    ---@return string str The string representation of the class.
    local function class__tostring( cls )
        return string_format( "%sClass: %p", raw_get( raw_get( cls, "__base" ), "__type" ), cls )
    end

    local raw_set = std.raw.set

    --- [SHARED AND MENU]
    ---
    --- Creates a new class from the given base.
    ---@param base Object The base object, aka metatable.
    ---@return Class | unknown cls The class.
    function class.create( base )
        local cls = {
            __base = base
        }

        local parent_base = raw_get( base, "__parent" )
        if parent_base ~= nil then
            ---@cast parent_base gpm.std.Object
            cls.__parent = parent_base.__class

            local parent = raw_get( parent_base, "__class" )
            if parent == nil then
                std.error( "parent class has no class", 2 )
            else
                local inherited_fn = raw_get( parent, "__inherited" )
                if inherited_fn ~= nil then
                    inherited_fn( parent, cls )
                end
            end
        end

        setmetatable( cls, {
            __index = base,
            __call = class__call,
            __tostring = class__tostring,
            __type = raw_get( base, "__type" ) .. "Class"
        } ) ---@cast cls -Object

        raw_set( base, "__class", cls )
        return cls
    end

end
