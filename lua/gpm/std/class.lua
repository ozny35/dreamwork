---@class gpm.std
local std = _G.gpm.std

local debug = std.debug
local string = std.string

local debug_newproxy = debug.newproxy
local setmetatable = std.setmetatable
local raw_get = std.raw.get

--- [SHARED AND MENU]
---
--- The class (OOP) library.
---
---@class gpm.std.class
local class = {}
std.class = class

---@alias Object gpm.std.Object
---@class gpm.std.Object
---@field private __type string The name of object type.
---@field __class gpm.std.Class The class of the object.
---@field __parent gpm.std.Object | nil The parent of the object.
---@field protected __new function A function that will be called when a new class is created and allows you to replace the result.
---@field private __init function A function that will be called when creating a new object and should be used as the constructor.

---@alias Class gpm.std.Class
---@class gpm.std.Class : gpm.std.Object
---@field __base gpm.std.Object The base of the class.
---@field __parent gpm.std.Class | nil The parent of the class.
---@field __private boolean If the class is private.
---@field private __inherited fun( parent: gpm.std.Class, child: gpm.std.Class ) | nil The function that will be called when the class is inherited.

---@type table<gpm.std.Object, userdata>
local templates = {}

debug.gc.setTableRules( templates, true, false )

do

    local debug_getmetavalue = debug.getmetavalue
    local debug_getmetatable = debug.getmetatable
    local raw_pairs = std.raw.pairs
    local string_sub = string.sub

    ---@param obj gpm.std.Object The object to convert to a string.
    ---@return string str The string representation of the object.
    local function base__tostring( obj )
        return string.format( "%s: %p", debug_getmetavalue( obj, "__type" ) or "unknown", obj )
    end

    ---@type table<string, boolean>
    local meta_blacklist = {
        __private = true,
        __class = true,
        __base = true,
        __type = true,
        __init = true
    }

    --- [SHARED AND MENU]
    ---
    --- Creates a new class base ( metatable ).
    ---
    ---@param name string The name of the class.
    ---@param private boolean? If the class is private.
    ---@param parent gpm.std.Class? The parent of the class.
    ---@return gpm.std.Object base The base of the class.
    function class.base( name, private, parent )
        local base

        if private then
            local template = debug_newproxy( true )
            base = debug_getmetatable( template )

            if base == nil then
                error( "userdata metatable is missing, lua is corrupted" )
            end

            templates[ base ] = template

            base.__type = name
            base.__private = true
            base.__tostring = base__tostring
        else
            base = {
                __type = name,
                __tostring = base__tostring
            }
        end

        base.__index = base

        if parent ~= nil then
            local parent_base = raw_get( parent, "__base" )
            if parent_base == nil then
                error( "parent class has no base", 2 )
            end

            ---@cast parent_base gpm.std.Object
            base.__parent = parent_base
            setmetatable( base, { __index = parent_base } )

            -- copy metamethods from parent
            for key, value in raw_pairs( parent_base ) do
                if string_sub( key, 1, 2 ) == "__" and not ( key == "__index" and value == parent_base ) and not meta_blacklist[ key ] then
                    base[ key ] = value
                end
            end
        end

        return base
    end

end

local class__call
do

    --- [SHARED AND MENU]
    ---
    --- This function is optional and can be used to re-initialize the object.
    ---
    --- Calls the base initialization function, <b>if it exists</b>, and returns the given object.
    ---
    ---@param base gpm.std.Object The base object, aka metatable.
    ---@param obj any The object to initialize.
    ---@param ... any? Arguments to pass to the constructor.
    ---@return gpm.std.Object object The initialized object.
    function class.init( base, obj, ... )
        local init_fn = raw_get( base, "__init" )
        if init_fn ~= nil then
            init_fn( obj, ... )
        end

        return obj
    end

    ---@param self gpm.std.Class The class.
    ---@return gpm.std.Object object The new object.
    function class__call( self, ... )
        local base = raw_get( self, "__base" )
        if base == nil then
            error( "class base is missing, class creation failed.", 2 )
        end

        ---@cast base gpm.std.Object

        local obj

        local new_fn = raw_get( base, "__new" )
        if new_fn ~= nil then
            obj = new_fn( base, ... )
        end

        if obj == nil then
            if raw_get( base, "__private" ) then
                obj = debug_newproxy( templates[ base ] )
            else
                obj = {}
                setmetatable( obj, base )
            end
        end

        ---@cast obj gpm.std.Object

        local init_fn = raw_get( base, "__init" )
        if init_fn ~= nil then
            init_fn( obj, ... )
        end

        return obj
    end

end

---@param cls gpm.std.Class The class.
---@return string str The string representation of the class.
local function class__tostring( cls )
    return string.format( "%sClass: %p", raw_get( raw_get( cls, "__base" ), "__type" ), cls )
end

local raw_set = std.raw.set

--- [SHARED AND MENU]
---
--- Creates a new class from the given base.
---
---@param base gpm.std.Object The base object, aka metatable.
---@return gpm.std.Class | unknown cls The class.
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
            error( "parent class has no class", 2 )
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
    } )

    ---@cast cls gpm.std.Object

    raw_set( base, "__class", cls )
    return cls
end
