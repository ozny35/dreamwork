-- Semver lua parser. Based on https://github.com/kikito/semver.lua
-- https://github.com/Pika-Software/gpm_legacy/blob/main/lua/gpm/sh_semver.lua



-- TODO: rewrite to class system


local _G = _G
local std = _G.gpm.std
local table_sort = std.table.sort
local error, tonumber, rawget = std.error, std.tonumber, std.rawget

local bit_band, bit_bor, bit_lshift, bit_rshift
do
	local bit = std.bit
	bit_band, bit_bor, bit_lshift, bit_rshift = bit.band, bit.bor, bit.lshift, bit.rshift
end

local isstring, isnumber = std.isstring, std.isnumber

local math_isuint, math_max
do
	local math = std.math
	math_isuint, math_max = math.isuint, math.max
end

local string = std.string
local string_match, string_gsub, string_find, string_sub = string.match, string.gsub, string.find, string.sub

local smallerPreRelease
do

	local function compare( a, b )
		return a == b and 0 or a < b and -1 or 1
	end

	local function compareIDs( a, b )
		if a == b then
			return 0
		elseif not a then
			return -1
		elseif not b then
			return 1
		end

		local a_num, b_num = tonumber( a, 10 ), tonumber( b, 10 )
		if a_num and b_num then
			return compare( a_num, b_num )
		elseif a_num then
			return -1
		elseif b_num then
			return 1
		else
			return compare( a, b )
		end
	end

	local string_byteSplit = string.byteSplit

	function smallerPreRelease( first, second )
		if not first or first == second then
			return false
		elseif not second then
			return true
		end

		local fisrt, fcount = string_byteSplit( first, 0x2E --[[ . ]] )

		local scount
		second, scount = string_byteSplit( second, 0x2E --[[ . ]] )

		local comparison
		for index = 1, fcount do
			comparison = compareIDs( fisrt[ index ], second[ index ] )
			if comparison ~= 0 then
				return comparison == -1
			end
		end

		return fcount < scount
	end

end

local function parsePreRelease( str )
	if str == nil or str == "" then return end

	local pre_release = string_match( str, "^-(%w[%.%w-]*)$" )
	if not pre_release or string_match( pre_release, "%.%." ) then
		error( "the pre-release '" .. str .. "' is not valid" )
	end

	return pre_release
end

local function parseBuild( str )
	if str == nil or str == "" then return end

	local build = string_match( str, "^%+(%w[%.%w-]*)$" )
	if not build or string_match( build, "%.%." ) then
		error( "the build '" .. str .. "' is not valid" )
	end

	return build
end

local parsePreReleaseAndBuild
do

	local string_byte = string.byte

	function parsePreReleaseAndBuild( str )
		if str == nil or str == "" then return end

		local pre_release, build = string_match( str, "^(%-[^+]+)(%+.+)$" )
		if pre_release == nil or build == nil then
			local byte = string_byte( str, 1 )
			if byte == 0x2D --[[ - ]] then
				pre_release = parsePreRelease( str )
			elseif byte == 0x2B --[[ + ]] then
				build = parseBuild( str )
			else
				error( "the parameter '" .. str .. "' must begin with + or - to denote a pre-release or a build", 3 )
			end
		end

		return pre_release, build
	end

end

local function numbersToString( major, minor, patch, pre_release, build )
	if pre_release and build then
		return major .. "." .. minor .. "." .. patch .. "-" .. pre_release .. "+" .. build
	elseif pre_release then
		return major .. "." .. minor .. "." .. patch .. "-" .. pre_release
	elseif build then
		return major .. "." .. minor .. "." .. patch .. "+" .. build
	else
		return major .. "." .. minor .. "." .. patch
	end
end

local function parse( major, minor, patch, pre_release, build )
	if major == nil then
		error( "at least one parameter is needed", 2 )
	end

	if isnumber( major ) then
		if not math_isuint( major ) then
			error( "major version must be unsigned integer", 2 )
		end

		if minor == nil then
			minor = 0
		elseif not ( isnumber( minor ) and math_isuint( minor ) ) then
			error( "minor version must be unsigned integer number", 2 )
			error( "minor version must be a number", 2 )
		end

		if patch == nil then
			patch = 0
		elseif not ( isnumber( patch ) and math_isuint( patch ) ) then
			error( "patch version must be unsigned integer number", 2 )
		end

		if isstring( build ) then
			if isstring( pre_release ) then
				pre_release = parsePreRelease( pre_release )
			end

			build = parseBuild( build )
		elseif isnumber( pre_release ) then
			pre_release, build = parsePreReleaseAndBuild( pre_release )
		end
	else
		local extra
		major, minor, patch, extra = string_match( tostring( major ), "^(%d+)%.?(%d*)%.?(%d*)(.-)$" )
		if major == nil then error( "the major version is missing", 2 ) end

		major = tonumber( major, 10 )
		if minor == "" then minor = "0" end

		minor = tonumber( minor, 10 )
		if patch == "" then patch = "0" end

		patch = tonumber( patch, 10 )
		pre_release, build = parsePreReleaseAndBuild( extra )
	end

	if major > 0x3ff or minor > 0x7ff or patch > 0x7ff then
		error( "version is too large (max 1023.2047.2047)", 2 )
	elseif major < 0 or minor < 0 or patch < 0 then
		error( "version is too small (min 0.0.0)", 2 )
	end

	return major, minor, patch, pre_release, build
end

local VersionClass

local function nextMajor( self )
	return VersionClass( self[ 1 ] + 1, 0, 0 )
end

local function nextMinor( self )
	return VersionClass( self[ 1 ], self[ 2 ] + 1, 0 )
end

local function nextPatch( self )
	return VersionClass( self[ 1 ], self[ 2 ], self[ 3 ] + 1 )
end

---@alias Version gpm.std.Version
---@class gpm.std.Version: gpm.std.Object
---@field __class gpm.std.VersionClass
local Version = std.class.base( "Version" )

Version.nextMajor = nextMajor
Version.nextMinor = nextMinor
Version.nextPatch = nextPatch

function Version:toNumber()
	local major = tonumber( self[ 1 ], 10 )
	if major > 0x3ff then
		error( "major version is too large (max 1023)", 2 )
	end

	local minor = tonumber( self[ 2 ], 10 )
	if minor > 0x7ff then
		error( "minor version is too large (max 2047)", 2 )
	end

	local patch = tonumber( self[ 3 ], 10 )
	if patch > 0x7ff then
		error( "patch version is too large (max 2047)", 2 )
	end

	return bit_bor( bit_lshift( patch, 21 ), bit_lshift( minor, 10 ), major )
end

local keys = {}
setmetatable( keys, { __mode = "kv" } )

function Version:unpack()
	local values = rawget( keys, self )
	return values[ 1 ], values[ 2 ], values[ 3 ], values[ 4 ], values[ 5 ]
end

function Version:__index( key )
	return rawget( rawget( keys, self ), key ) or rawget( Version, key )
end

local names = {}
setmetatable( names, { __mode = "kv" } )

function Version:__tostring()
	return names[ self ] or "unknown"
end

function Version:__eq( other )
	return names[ self ] == names[ other ]
end

function Version:__lt( other )
	if self[ 1 ] ~= other[ 1 ] then
		return self[ 1 ] < other[ 1 ]
	elseif self[ 2 ] ~= other[ 2 ] then
		return self[ 2 ] < other[ 2 ]
	elseif self[ 3 ] ~= other[ 3 ] then
		return self[ 3 ] < other[ 3 ]
	else
		return smallerPreRelease( self[ 4 ], other[ 4 ] )
	end
end

function Version:__le( other )
	return self == other or self < other
end

function Version:__pow( other )
	if self[ 1 ] == 0 then
		return self == other
	else
		return self[ 1 ] == other[ 1 ] and self[ 2 ] <= other[ 2 ]
	end
end

do

	local string_byteCount, string_trim = string.byteCount, string.trim

	local operators = {
		-- primitive operators
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#ranges
		["<"] = function( self, sv ) return self < sv end,
		[">"] = function( self, sv, xrange )
			if xrange > 0 then
				if xrange == 1 then
					sv = nextMinor( sv )
				elseif xrange == 2 then
					sv = nextMajor( sv )
				end

				return self >= sv
			else
				return self > sv
			end
		end,
		["<="] = function( self, sv, xrange )
			if xrange > 0 then
				if xrange == 1 then
					sv = nextMinor( sv )
				elseif xrange == 2 then
					sv = nextMajor( sv )
				end

				return self < sv
			else
				return self <= sv
			end
		end,
		[">="] = function( self, sv ) return self >= sv end,
		["="] = function( self, sv, xrange )
			if xrange > 0 then
				if self < sv then
					return false
				elseif xrange == 1 then
					sv = nextMinor( sv )
				elseif xrange == 2 then
					sv = nextMajor( sv )
				end

				return self < sv
			else
				return self == sv
			end
		end,

		-- Caret Ranges ^1.2.3 ^0.2.5 ^0.0.4
		-- Allows changes that do not modify the left-most non-zero digit in the [major, minor, patch] tuple.
		-- In other words, this allows patch and minor updates for versions 1.0.0 and above, patch updates for
		-- versions 0.X >=0.1.0, and no updates for versions 0.0.X.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#caret-ranges-123-025-004
		["^"] = function( self, sv, xrange )
			if sv[ 1 ] == 0 and xrange < 2 then
				if sv[ 2 ] == 0 and xrange < 1 then
					return self[ 1 ] == 0 and self[ 2 ] == 0 and self >= sv and self < nextPatch( sv )
				else
					return self[ 1 ] == 0 and self >= sv and self < nextMinor( sv )
				end
			else
				return self[ 1 ] == sv[ 1 ] and self >= sv and self < nextMajor( sv )
			end
		end,

		-- Tilde Ranges ~1.2.3 ~1.2 ~1
		-- Allows patch-level changes if a minor version is specified on the comparator. Allows minor-level changes if not.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#tilde-ranges-123-12-1
		["~"] = function( self, sv, xrange )
			if self < sv then
				return false
			elseif xrange == 2 then
				return self < nextMajor( sv )
			else
				return self < nextMinor( sv )
			end
		end
	}

	function Version:__mod( str )
		-- spaces clean up
		str = string_trim( string_gsub( str, "%s+", " " ), "%s", 0 )

		-- version range := comparator sets
		if string_find( str, "||", 1, true ) then
			local pointer = 1
			while true do
				local position = string_find( str, "||", pointer, true )
				if self % string_sub( str, pointer, position and ( position - 1 ) ) then
					return true
				elseif position == nil then
					return false
				else
					pointer = position + 2
				end
			end
		end

		-- comparator set := comparators
		if string_find( str, " ", 1, true ) then
			local pos, part
			local start = 1
			while true do
				pos = string_find( str, " ", start, true )
				part = string_sub( str, start, pos and ( pos - 1 ) )

				-- Hyphen Ranges: X.Y.Z - A.B.C
				-- https://docs.npmjs.com/cli/v6/using-npm/semver#hyphen-ranges-xyz---abc
				if pos ~= nil and string_sub( str, pos, pos + 2 ) == " - " then
					if not ( self % ( ">=" .. part ) ) then
						return false
					end

					start = pos + 3
					pos = string_find( str, " ", start, true )
					part = string_sub( str, start, pos and ( pos - 1 ) )

					if not ( self % ( "<=" .. part ) ) then
						return false
					end
				elseif not ( self % part ) then
					return false
				end

				if pos == nil then
					return true
				end

				start = pos + 1
			end

			return true
		end

		-- comparators := operator + version
		str = string_gsub( string_gsub( str, "^=", "" ), "^v", "" )

		-- X-Ranges *
		-- Any of X, x, or * may be used to 'stand in' for one of the numeric values in the [major, minor, patch] tuple.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#x-ranges-12x-1x-12-
		if str == "" or str == "*" then
			return self % ">=0.0.0"
		end

		local pos = string_find( str, "%d" )
		if pos == nil then
			error( "Version range must starts with number: " .. str, 2 )
		end

		-- X-Ranges 1.2.x 1.X 1.2.*
		-- Any of X, x, or * may be used to 'stand in' for one of the numeric values in the [major, minor, patch] tuple.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#x-ranges-12x-1x-12-
		local operator
		if pos == 1 then
			operator = "="
		else
			operator = string_sub( str, 1, pos - 1 )
		end

		local name = string_gsub( string_sub( str, pos ), "%.[xX*]", "" )

		local xrange = math_max( 2 - string_byteCount( name, 0x2E --[[ . ]] ), 0 )
		for _ = 1, xrange do
			name = name .. ".0"
		end

		local fn = operators[ operator ]
		if fn == nil then
			error( "Invaild operator: '" .. operator .. "'", 2 )
		else
			return fn( self, VersionClass( name ), xrange )
		end
	end

end

do

	local debug_setmetatable = std.debug.setmetatable
	local debug_newproxy = std.debug.newproxy

	local keys_metatable
	do

		local string_lower = string.lower

		local key2key = {
			major = 1,
			minor = 2,
			patch = 3,
			prerelease = 4,
			build = 5
		}

		keys_metatable = {
			__index = function( tbl, key )
				return rawget( tbl, rawget( key2key, string_lower( key ) ) or -1 )
			end
		}

	end

	local cache = {}

	setmetatable( cache, { __mode = "kv" } )

	---@protected
	function Version:__new( major, minor, patch, pre_release, build )
		if getmetatable( major ) == Version then return major end

		major, minor, patch, pre_release, build = parse( major, minor, patch, pre_release, build )
		local name = numbersToString( major, minor, patch, pre_release, build )

		local object = cache[ name ]
		if object == nil then
			object = debug_newproxy()
			cache[ name ] = object

			if not debug_setmetatable( object, Version ) then
				error( "failed to set metatable", 2 )
			end

			keys[ object ] = setmetatable( { major, minor, patch, pre_release, build }, keys_metatable )
			names[ object ] = name
		end

		return object
	end

end

---@class gpm.std.VersionClass: gpm.std.Version
---@field __base gpm.std.Version
---@overload fun( major: string | number | Version, minor: number?, patch: number?, pre_release: string?, build: string? ): Version
VersionClass = std.class.create( Version )
VersionClass.parse = parse

function VersionClass.toString( major, minor, patch, pre_release, build )
	return numbersToString( parse( major, minor, patch, pre_release, build ) )
end

function VersionClass.fromNumber( uint )
	return VersionClass( bit_band( uint, 0x3ff ), bit_band( bit_rshift( uint, 10 ), 0x7ff ), bit_band( bit_rshift( uint, 21 ), 0x7ff ) )
end

do

	local function sort_fn( a, b ) return a > b end

	--- Selects the first version in `tbl` that matches `target`.
	---@param target string The version selector.
	---@param tbl table<string|gpm.std.Version>: The table to search.
	---@return gpm.std.Version?: The first version that matches `target`.
	---@return integer: The index of the version in `tbl`.
	function VersionClass.select( target, tbl )
		table_sort( tbl, sort_fn )

		for index = 1, #tbl, 1 do
			local version = VersionClass( tbl[ index ] )
			if version % target then return version, index end
		end

		return nil, -1
	end

end

return VersionClass
