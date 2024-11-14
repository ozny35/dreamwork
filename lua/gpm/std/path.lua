local _G = _G
local std = _G.gpm.std
local string, table = std.string, std.table
local string_byte, string_sub, string_len, string_match, string_byteSplit, string_trimByte, string_isURL = string.byte, string.sub, string.len, string.match, string.byteSplit, string.trimByte, string.isURL
local table_concat = table.concat

local debug_getfmain, debug_getfpath
do
    local debug = std.debug
    debug_getfmain, debug_getfpath = debug.getfmain, debug.getfpath
end

local getfenv, rawget, select = std.getfenv, std.rawget, std.select

---@class gpm.std.path
local path = {}

local function getFile( filePath )
    for index = string_len( filePath ), 1, -1 do
        if string_byte( filePath, index ) == 0x2F --[[ / ]] then
            return string_sub( filePath, index + 1 )
        end
    end

    return filePath
end

path.getFile = getFile

function path.getFileName( filePath, withExtension )
    if withExtension then
        return getFile( filePath )
    end

    local position
    for index = string_len( filePath ), 1, -1 do
        local byte = string_byte( filePath, index )
        if byte == 0x2E --[[ . ]] then
            if position == nil then
                position = index
            end
        elseif byte == 0x2F --[[ / ]] then
            if position == nil then
                return string_sub( filePath, index + 1 )
            else
                return string_sub( filePath, index + 1, position - 1 )
            end
        end
    end

    if position == nil then
        return filePath
    else
        return string_sub( filePath, 1, position - 1 )
    end
end

local function getDirectory( filePath, withTrailingSlash )
    if withTrailingSlash == nil then withTrailingSlash = true end

    for index = string_len( filePath ), 1, -1 do
        if string_byte( filePath, index ) == 0x2F --[[ / ]] then
            if withTrailingSlash then
                return string_sub( filePath, 1, index )
            else
                return string_sub( filePath, 1, index - 1)
            end
        end
    end

    return ""
end

path.getDirectory = getDirectory

local getExtension = function( filePath, withDot )
    for index = string_len( filePath ), 1, -1 do
        local byte = string_byte( filePath, index )
        if byte == 0x2F --[[ / ]] then
            break
        elseif byte == 0x2E --[[ . ]] then
            if withDot then
                return string_sub( filePath, index )
            else
                return string_sub( filePath, index + 1 )
            end
        end
    end

    return ""
end

path.getExtension = getExtension

local function stripFile( filePath )
    for index = string_len( filePath ), 1, -1 do
        if string_byte( filePath, index ) == 0x2F --[[ / ]] then
            return string_sub( filePath, 1, index ), string_sub( filePath, index + 1 )
        end
    end

    return "", filePath
end

path.stripFile = stripFile

local function stripDirectory( filePath )
    for index = string_len( filePath ), 1, -1 do
        if string_byte( filePath, index ) == 0x2F --[[ / ]] then
            return string_sub( filePath, index + 1 ), string_sub( filePath, 1, index )
        end
    end

    return filePath, ""
end

path.stripDirectory = stripDirectory

local function stripExtension( filePath )
    for index = string_len( filePath ), 1, -1 do
        local byte = string_byte( filePath, index )
        if byte == 0x2F --[[ / ]] then
            return filePath, ""
        elseif byte == 0x2E --[[ . ]] then
            return string_sub( filePath, 1, index - 1 ), string_sub( filePath, index + 1 )
        end
    end

    return filePath, ""
end

path.stripExtension = stripExtension

function path.replaceFile( filePath, newFile )
    return stripFile( filePath ) .. newFile
end

function path.replaceDirectory( filePath, newDirectory )
    if string_byte( newDirectory, string_len( newDirectory ) ) ~= 0x2F --[[ / ]] then
        newDirectory = newDirectory .. "/"
    end

    return newDirectory .. stripDirectory( filePath )
end

function path.replaceExtension( filePath, newExtension )
    return stripExtension( filePath ) .. "." .. newExtension
end

local function fixFileName( filePath )
    local length = string_len( filePath )
    if string_byte( filePath, length ) == 0x2F --[[ / ]] then
        return string_sub( filePath, 1, length - 1 )
    else
        return filePath
    end
end

path.fixFileName = fixFileName

local fixSlashes
do

    local string_gsub = string.gsub

    function fixSlashes( str )
        return string_gsub( str, "[/\\]+", "/" ), nil
    end

    path.fixSlashes = fixSlashes

end

function path.fix( filePath )
    return fixFileName( fixSlashes( filePath ) )
end

local function getCurrentFile( fn )
    if fn == nil then fn = debug_getfmain() end
    if fn == nil then return nil end

    local fenv = getfenv( fn )
    if fenv then
        local filePath = rawget(fenv, "__filename")
        if filePath then
            return filePath
        end
    end

    local filePath = debug_getfpath( fn )
    if string_isURL( filePath ) then
        filePath = string_match( filePath, "^[^/]*([^#?]+).*$" )
        return string_match( filePath, "^//[^/]+/?(.+)$" ) or filePath
    end

    return "/" .. filePath
end

path.getCurrentFile = getCurrentFile

local function getCurrentDirectory( fn, withTrailingSlash )
    if fn == nil then
        fn = debug_getfmain()
    end

    if fn then
        if withTrailingSlash == nil then
            withTrailingSlash = true
        end

        local fenv = getfenv( fn )
        if fenv then
            local dirPath = rawget( fenv, "__dirname" )
            if dirPath then
                if withTrailingSlash then
                    dirPath = dirPath .. "/"
                else
                    return dirPath
                end
            end
        end

        local filePath = debug_getfpath( fn )
        if string_isURL( filePath ) then
            filePath = string_match( filePath, "^[^/]*([^#?]+).*$" )
            return getDirectory( string_match( filePath, "^//[^/]+/?(.+)$" ) or filePath, withTrailingSlash )
        end

        return getDirectory( "/" .. filePath, withTrailingSlash )
    end

    return "/"
end

path.getCurrentDirectory = getCurrentDirectory

path.delimiter = ":"
path.sep = "/"

local function isAbsolute( filePath ) return string_byte( filePath, 1 ) == 0x2F end
path.isAbsolute = isAbsolute

local equal
do

    local os_name = std.os.name
    if os_name == "Windows" or os_name == "OSX" then
        local string_lower = string.lower
        function equal( a, b )
            if a and b then
                return string_lower( a ) == string_lower( b )
            else
                return false
            end
        end
    else
        function equal( a, b ) return a == b end
    end


    path.equal = equal

end

local function splitPath( filePath )
    local root
    if isAbsolute( filePath ) then
        filePath = string_sub( filePath, 2 )
        root = "/"
    else
        root = ""
    end

    local basename, dir = stripDirectory( filePath )
    return root, dir, basename
end

path.splitPath = splitPath

function path.dirname( filePath, withTrailingSlash )
    if withTrailingSlash == nil then
        withTrailingSlash = true
    end

    filePath = getDirectory( filePath, withTrailingSlash )
    if filePath == "" then
        if withTrailingSlash then
            return "./"
        else
            return "."
        end
    end

    return filePath
end

function path.basename( filePath, stripSuffix )
    filePath = getFile( filePath )
    if stripSuffix then
        return stripExtension( filePath )
    end

    return filePath, ""
end

path.extname = getExtension

local normalize
do

    local table_insert, table_remove = table.insert, table.remove

    function normalize( filePath )
        local trailingSlashes = string_byte( filePath, string_len( filePath ) ) == 0x2F --[[ / ]]

        local isAbs = isAbsolute( filePath )
        if isAbs then
            filePath = string_sub( filePath, 2 )
        end

        local parts, length = string_byteSplit( filePath, 0x2F --[[ / ]] )
        local skip = 0

        for index = length, 1, -1 do
            local part = parts[ index ]
            if part == "." then
                table_remove( parts, index )
                length = length - 1
            elseif part == ".." then
                table_remove( parts, index )
                length = length - 1
                skip = skip + 1
            elseif skip > 0 then
                table_remove( parts, index )
                length = length - 1
                skip = skip - 1
            end
        end

        if not isAbs then
            while skip > 0 do
                table_insert( parts, 1, ".." )
                length = length + 1
                skip = skip - 1
            end
        end

        filePath = table_concat( parts, "/", 1, length )
        if filePath == "" then
            if isAbs then
                return "/"
            elseif trailingSlashes then
                return "./"
            else
                return "."
            end
        end

        if trailingSlashes then
            filePath = filePath .. "/"
        end

        if isAbs then
            filePath = "/" .. filePath
        end

        return fixSlashes( filePath )
    end

    path.normalize = normalize

end

---@vararg string
---@return string
local function join( ... )
    local length = select( "#", ... )
    if length == 0 then return "" end

    local args = { ... }
    for index = 1, length do
        local value = args[ index ]
        if value and value ~= "" then
            args[ index ] = value
        else
            args[ index ] = ""
        end
    end

    for index = 1, length do
        local value = args[ index ]
        if index > 1 then
            value = string_trimByte( value, 0x2F, 1 )
        end

        if index < length then
            value = string_trimByte( value, 0x2F, -1 )
        end

        args[ index ] = value
    end

    return normalize( table_concat( args, "/", 1, length ) )
end

path.join = join

---@vararg string
---@return string
local function resolve( ... )
    local args, resolvedPath = { ... }, ""
    for index = select( "#", ... ), 1, -1 do
        local filePath = args[ index ]
        if filePath and filePath ~= "" then
            resolvedPath = join( normalize( filePath ), resolvedPath )
            if isAbsolute( resolvedPath ) then
                return resolvedPath
            end
        end
    end

    return getCurrentDirectory( nil, true ) .. resolvedPath
end

path.resolve = resolve

---Returns the relative path from "from" to "to"
---If no relative path can be solved, then "to" is returned
---@param pathFrom string
---@param pathTo string
---@return string
function path.relative( pathFrom, pathTo )
    local fromRoot, fromDir, fromBaseName = splitPath( resolve( pathFrom ) )

    pathTo = resolve( pathTo )
    local toRoot, toDir, toBaseName = splitPath( pathTo )
    if not equal( fromRoot, toRoot ) then return pathTo end

    local fromParts, fromLength = string_byteSplit( fromDir .. fromBaseName, 0x2F --[[ / ]] )
    local toParts, toLength = string_byteSplit( toDir .. toBaseName, 0x2F --[[ / ]] )

    local commonLength = 0
    for index = 1, fromLength do
        local part = fromParts[ index ]
        if not equal( part, toParts[ index ] ) then break end
        commonLength = commonLength + 1
    end

    local parts, length = { }, 0
    for _ = commonLength + 1, fromLength do
        length = length + 1
        parts[ length ] = ".."
    end

    for index = commonLength + 1, toLength do
        length = length + 1
        parts[ length ] = toParts[ index ]
    end

    return table_concat( parts, "/", 1, length )
end

--[[
    ┌─────────────────────┬────────────┐
    │          dir        │    base    │
    ├──────┬              ├──────┬─────┤
    │ root │              │ name │ ext │
    "  /    home/user/dir/  file  .txt "
    └──────┴──────────────┴──────┴─────┘
    (All spaces in the "" line should be ignored. They are purely for formatting.)

]]

---@param filePath string
---@return table
function path.parse( filePath )
    local root, dir, base = splitPath( filePath )
    local name, ext = string_match( base, "^(.+)%.(.+)$" )

    if name then
        ext = ext or ""
    else
        name = base
        ext = ""
    end

    return { root = root, dir = dir, base = base, ext = ext, name = name }
end

return path
