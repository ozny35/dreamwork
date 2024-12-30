local std = _G.gpm.std

local rawget = std.rawget
local rawset = std.rawset

local string = std.string
local string_sub = string.sub
local string_format = string.format

local pairs = std.pairs
local is_function = std.is.fn
local setmetatable = std.setmetatable
local debug_getmetatable = std.debug.getmetatable

---@class gpm.std.class
local class = {}

---@class gpm.std.Object
---@field __name string name of the object
---@field __class Class class of the object (must be defined)
---@field __parent gpm.std.Class | nil parent of the class (must be defined)
---@alias Object gpm.std.Object

---@class gpm.std.Class : gpm.std.Object
---@field __base gpm.std.Object base of the class (must be defined)
---@field __inherited fun( parent: gpm.std.Class, child: gpm.std.Class ) | nil called when a class is inherited
---@alias Class gpm.std.Class

---@param obj Object: The object to convert to a string.
---@return string: The string representation of the object.
local function base__tostring( obj )
    return string_format( "%s: %p", rawget( debug_getmetatable( obj ),  "__name" ), obj )
end

---@param name string: name of the class.
---@param parent Class | unknown | nil: parent of the class.
---@return Object: The base of the class.
function class.base( name, parent )
    local base = {
        __name = name,
        __metatable_id = 5,
        __metatable_name = name,
        __tostring = base__tostring
    }

    base.__index = base

    if parent then
        base.__parent = parent

        local parent_base = rawget( parent, "__base" )
        if parent_base == nil then
            std.error( "parent class has no base", 2 )
        end

        setmetatable( base, { __index = parent_base } )

        -- copy metamethods from parent
        for key, value in pairs( parent_base ) do
            if string_sub( key, 1, 2 ) == "__" and not ( key == "__index" and value == parent_base ) and key ~= "__name" then
                base[ key ] = value
            end
        end
    end

    return base
end

--- Calls the base initialization function, <b>if it exists</b>, and returns the given object.
---@param obj table | userdata: The object to initialize.
---@param base Object: The base object, aka metatable.
---@param ... any: Arguments to pass to the constructor.
---@return Object | userdata: The initialized object.
local function init( obj, base, ... )
    local fn = rawget( base, "__init" )
    if is_function( fn ) then
        fn( obj, ... )
    end

    return obj
end

class.init = init

--- Creates a new object from the given base.
---@param base Object: The base object, aka metatable.
---@vararg any: Arguments to pass to the constructor.
---@return Object | userdata: The new object.
local function new( base, ... )
    local fn = rawget( base, "__new" )
    if is_function( fn ) then
        local obj = fn( ... )
        if obj ~= nil then
            return obj
        end
    end

    return init( setmetatable( {}, base ), base, ... )
end

class.new = new

---@param self Class: The class.
---@return Object | userdata: The new object.
local function class__call( self, ... )
    return new( rawget( self, "__base" ), ... )
end

---@param cls Class: The class.
---@return string: The string representation of the class.
local function class__tostring( cls )
    return string_format( "%sClass: %p", rawget( rawget( cls, "__base" ), "__name" ), cls )
end

---@param base Object: The base object, aka metatable.
---@return Class | unknown: The class.
function class.create( base )
    local cls = {
        __base = base
    }

    setmetatable( cls, {
        __index = base,
        __metatable_id = 5,
        __call = class__call,
        __tostring = class__tostring,
        __metatable_name = rawget( base, "__name" ) .. "Class"
    } ) ---@cast cls -Object

    rawset( base, "__class", cls )
    return cls
end

---@param cls Class | unknown: The class.
function class.inherited( cls )
    local base = rawget( cls, "__base" )
    if base == nil then return end

    local parent = rawget( base, "__parent" )
    if parent == nil or not parent.__inherited then return end
    parent:__inherited( cls )
end

return class
