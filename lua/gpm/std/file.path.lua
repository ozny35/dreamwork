local _G = _G
local std = _G.gpm.std
local string, table = std.string, std.table
local string_byte, string_sub, string_len, string_match, string_byteSplit, string_byteTrim, string_isURL = string.byte, string.sub, string.len, string.match, string.byteSplit, string.byteTrim, string.isURL
local table_concat = table.concat

-- References: https://github.com/luvit/luvit/blob/master/deps/path/base.lua

local debug_getfmain, debug_getfpath
do
    local debug = std.debug
    debug_getfmain, debug_getfpath = debug.getfmain, debug.getfpath
end

local getfenv, raw_get, select = std.getfenv, std.raw.get, std.select

---@class gpm.std.file.path
local path = {}

--- Get the file name with extension from filePath.
---@param filePath string The file path.
---@return string: The file name with extension.
local function getFile( filePath )
    for index = string_len( filePath ), 1, -1 do
        if string_byte( filePath, index ) == 0x2F --[[ / ]] then
            return string_sub( filePath, index + 1 )
        end
    end

    return filePath
end

path.getFile = getFile

--- Get the file name from filePath.
---@param filePath string The file path.
---@param withExtension boolean?: Whether to include the extension.
---@return string: The file name.
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

--- Get the directory from filePath.
---@param filePath string The file path.
---@param withTrailingSlash boolean?: Whether to include the trailing slash.
---@return string: The directory path.
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

--- Get the extension from filePath.
---@param filePath string The file path.
---@param withDot boolean?: Whether to include the dot.
---@return string: The extension.
local function getExtension( filePath, withDot )
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

--- Strip the file name from filePath.
---@param filePath string The file path.
---@return string: The directory path.
---@return string: The file name with extension.
local function stripFile( filePath, withTrailingSlash )
    for index = string_len( filePath ), 1, -1 do
        if string_byte( filePath, index ) == 0x2F --[[ / ]] then
            if withTrailingSlash then
                return string_sub( filePath, 1, index ), string_sub( filePath, index + 1 )
            else
                return string_sub( filePath, 1, index - 1 ), string_sub( filePath, index + 1 )
            end
        end
    end

    return "", filePath
end

path.stripFile = stripFile

--- Strip the directory from filePath.
---@param filePath string The file path.
---@return string: The file name with extension.
---@return string: The directory path.
local function stripDirectory( filePath, withTrailingSlash )
    for index = string_len( filePath ), 1, -1 do
        if string_byte( filePath, index ) == 0x2F --[[ / ]] then
            if withTrailingSlash then
                return string_sub( filePath, index + 1 ), string_sub( filePath, 1, index )
            else
                return string_sub( filePath, index + 1 ), string_sub( filePath, 1, index - 1 )
            end
        end
    end

    return filePath, ""
end

path.stripDirectory = stripDirectory

--- Strip the extension from filePath.
---@param filePath string The file path.
---@param withDot boolean?: Whether to include the dot in the extension.
---@return string: The file name without extension.
---@return string: The extension.
local function stripExtension( filePath, withDot )
    for index = string_len( filePath ), 1, -1 do
        local byte = string_byte( filePath, index )
        if byte == 0x2F --[[ / ]] then
            return filePath, ""
        elseif byte == 0x2E --[[ . ]] then
            if withDot then
                return string_sub( filePath, 1, index - 1 ), string_sub( filePath, index )
            else
                return string_sub( filePath, 1, index - 1 ), string_sub( filePath, index + 1 )
            end
        end
    end

    return filePath, ""
end

path.stripExtension = stripExtension

--- Replace the file name from filePath.
---@param filePath string The file path.
---@param newFile string The new file name with extension.
---@return string: The new file path.
function path.replaceFile( filePath, newFile )
    return stripFile( filePath ) .. newFile
end

--- Replace the directory from filePath.
---@param filePath string The file path.
---@param newDirectory string The new directory path.
---@return string: The new file path.
function path.replaceDirectory( filePath, newDirectory )
    if string_byte( newDirectory, string_len( newDirectory ) ) ~= 0x2F --[[ / ]] then
        newDirectory = newDirectory .. "/"
    end

    return newDirectory .. stripDirectory( filePath )
end

--- Replace the extension from filePath.
---@param filePath string The file path.
---@param newExtension string The new extension.
---@return string: The new file path.
function path.replaceExtension( filePath, newExtension )
    return stripExtension( filePath ) .. "." .. newExtension
end

--- Remove the trailing slash from filePath.
---@param filePath string The file path.
---@return string: The file path without the trailing slash.
local function removeTrailingSlash( filePath )
    local length = string_len( filePath )
    if string_byte( filePath, length ) == 0x2F --[[ / ]] then
        return string_sub( filePath, 1, length - 1 )
    else
        return filePath
    end
end

path.removeTrailingSlash = removeTrailingSlash

local fixSlashes
do

    local string_gsub = string.gsub

    --- Replaces all backslashes with forward slashes.
    ---@param str string The string to fix slashes in.
    ---@return string: The fixed string.
    function fixSlashes( str )
        ---@diagnostic disable-next-line: redundant-return-value
        return string_gsub( str, "[/\\]+", "/" ), nil
    end

    path.fixSlashes = fixSlashes

end

--- Get the current file path or function file path.
---@param fn function?: The function to get the file path from.
---@return string: The file path.
local function getCurrentFile( fn )
    if fn == nil then fn = debug_getfmain() end
    if fn == nil then return "/" end

    local fenv = getfenv( fn )
    if fenv then
        local filePath = raw_get( fenv, "__filename" )
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

--- Get the current directory path or function directory path.
---@param fn function?: The function to get the directory path from.
---@param withTrailingSlash boolean?: Whether to include the trailing slash.
---@return string: The directory path.
local function getCurrentDirectory( fn, withTrailingSlash )
    if fn then
        if withTrailingSlash == nil then
            withTrailingSlash = true
        end

        local fenv = getfenv( fn )
        if fenv then
            local dirPath = raw_get( fenv, "__dirname" )
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

--- Check if filePath is absolute, i.e. starts with a slash.
---@param filePath string The file path.
---@return boolean: `true` if filePath is absolute, `false` otherwise.
local function isAbsolute( filePath )
    return string_byte( filePath, 1 ) == 0x2F
end

path.isAbsolute = isAbsolute

local equal
do

    local os_name = std.os.name
    if os_name == "Windows" or os_name == "OSX" then
        local string_lower = string.lower
        --- Check if filePath1 and filePath2 are equal.
        ---@param a string The first file path.
        ---@param b string The second file path.
        ---@return boolean: `true` if filePath1 and filePath2 are equal, `false` otherwise.
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

--- Split a filename into [root, dir, basename].
---@param filePath string The file path.
---@return boolean: Whether filePath is absolute.
---@return string: The directory.
---@return string: The basename.
local function splitPath( filePath )
    local root
    if isAbsolute( filePath ) then
        filePath = string_sub( filePath, 2 )
        root = true
    else
        root = false
    end

    local basename, dir = stripDirectory( filePath )
    return root, dir, basename
end

path.splitPath = splitPath

--- Get the directory of a file.
---@param filePath string The file path.
---@param withTrailingSlash boolean?: Whether to include the trailing slash.
---@return string: The directory path.
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

--- Get the basename from filePath.
---@param filePath string The file path.
---@param stripSuffix boolean?: Whether to strip the extension.
---@return string: The basename.
---@return string: The file extension.
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

    --- Normalizes a file path by removing all "." and ".." parts.
    ---@param filePath string The file path.
    ---@return string: The normalized file path.
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

--- Join the file paths into a single file path and normalize it.
---@param ... string: The file paths.
---@return string: The joined file path.
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
            value = string_byteTrim( value, 0x2F, 1 )
        end

        if index < length then
            value = string_byteTrim( value, 0x2F, -1 )
        end

        args[ index ] = value
    end

    return normalize( table_concat( args, "/", 1, length ) )
end

path.join = join

--- Resolve the file paths into a single file path.
---@param ... string: The file paths.
---@return string: The resolved file path.
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

--- Returns the relative path from "from" to "to".
---
--- If no relative path can be solved, then "to" is returned.
---@param pathFrom string The file path.
---@param pathTo string The file path.
---@return string: The relative path.
function path.relative( pathFrom, pathTo )
    local fromIsAbs, fromDir, fromBaseName = splitPath( resolve( pathFrom ) )

    pathTo = resolve( pathTo )
    local toIsAbs, toDir, toBaseName = splitPath( pathTo )
    if fromIsAbs ~= toIsAbs then return pathTo end

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

--- Parse a file path into [root, dir, basename, ext, name].
---@param filePath string The file path.
---@return ParsedFilePath: The parsed file path.
function path.parse( filePath )
    local isAbs, dir, base = splitPath( filePath )
    if isAbs then dir = "/" .. dir end

    local name, ext = string_match( base, "^(.+)%.(.+)$" )
    if name then
        ext = ext or ""
    else
        name = base
        ext = ""
    end

    return { root = isAbs and "/" or "", dir = dir, base = base, ext = ext, name = name, abs = isAbs }
end

return path
