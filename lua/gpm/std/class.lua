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

---@alias gpm.std.Class.__inherited fun( parent: gpm.std.Class, child: gpm.std.Class )
---@alias gpm.std.Object.__new fun( cls: gpm.std.Object, ...: any? ): gpm.std.Object
---@alias gpm.std.Object.__init fun( obj: gpm.std.Object, ...: any? )

---@class gpm.std.Object
---@field private __type string The name of object type. **READ ONLY**
---@field __class gpm.std.Class The class of the object. **READ ONLY**
---@field __parent? gpm.std.Object The parent of the object. **READ ONLY**
---@field protected __new? gpm.std.Object.__new A function that will be called when a new class is created and allows you to replace the result.
---@field private __init? gpm.std.Object.__init A function that will be called when creating a new object and should be used as the constructor.
---@field protected __serialize? fun( obj: gpm.std.Object, writer: gpm.std.pack.Writer ) A function that will be called when the object is serialized.
---@field protected __deserialize? fun( obj: gpm.std.Object, reader: gpm.std.pack.Reader ) A function that will be called when the object is deserialized.

---@alias Object gpm.std.Object

---@class gpm.std.Class : gpm.std.Object
---@field __base gpm.std.Object The base of the class. **READ ONLY**
---@field __parent? gpm.std.Class The parent of the class. **READ ONLY**
---@field __private boolean If the class is private. **READ ONLY**
---@field private __inherited? gpm.std.Class.__inherited The function that will be called when the class is inherited.

---@alias Class gpm.std.Class

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
    ---@param private? boolean If the class is private.
    ---@param parent? gpm.std.Class | unknown The parent of the class.
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
    ---@param obj gpm.std.Object The object to initialize.
    ---@param ... any? Arguments to pass to the constructor.
    ---@return gpm.std.Object object The initialized object.
    local function class_init( base, obj, ... )
        local init_fn = raw_get( base, "__init" )
        if init_fn ~= nil then
            init_fn( obj, ... )
        end

        return obj
    end

    class.init = class_init

    --- [SHARED AND MENU]
    ---
    --- Creates a new class object.
    ---
    ---@param base gpm.std.Object The base object, aka metatable.
    ---@return gpm.std.Object object The new object.
    local function class_new( base )
        if raw_get( base, "__private" ) then
            ---@diagnostic disable-next-line: return-type-mismatch
            return debug_newproxy( templates[ base ] )
        end

        local obj = {}
        setmetatable( obj, base )
        return obj
    end

    class.new = class_new

    ---@param self gpm.std.Class The class.
    ---@return gpm.std.Object object The new object.
    function class__call( self, ... )
        ---@type gpm.std.Object | nil
        local base = raw_get( self, "__base" )
        if base == nil then
            error( "class base is missing, class creation failed.", 2 )
        end

        ---@type gpm.std.Object | nil
        local obj

        ---@type gpm.std.Object.__new | nil
        local new_fn = raw_get( base, "__new" )
        if new_fn ~= nil then
            obj = new_fn( base, ... )
        end

        if obj == nil then
            obj = class_new( base )
        end

        return class_init( base, obj, ... )
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

        ---@type gpm.std.Class | nil
        local parent = raw_get( parent_base, "__class" )
        if parent == nil then
            error( "parent class has no class", 2 )
        else
            ---@type gpm.std.Class.__inherited | nil
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
