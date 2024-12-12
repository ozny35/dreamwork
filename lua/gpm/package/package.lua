local _G = _G

---@class gpm
local gpm = _G.gpm

local std = gpm.std
local class = std.class
local Version = std.Version

---@alias Package gpm.Package
---@class gpm.Package: gpm.std.Object
---@field __class gpm.PackageClass
---@field name string
---@field version Version
---@field cvar_callbacks table
local Package = class.base( "Package" )

local cache = {}

---@param name string
---@param version string | Version
---@protected
function Package:__init( name, version )
    local prefix = name .. "@" .. version
    self.version = Version( version )
    cache[ prefix ] = self

    package.cvar_callbacks = {}

end

---@protected
function Package.__new( name, version )
    return cache[ name .. "@" .. version ]
end

---@class gpm.PackageClass: gpm.Package
---@field __base gpm.Package
---@overload fun( name: string, version: string | Version ): Package
local PackageClass = class.create( Package )
gpm.Package = PackageClass

