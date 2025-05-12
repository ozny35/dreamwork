---@class gpm.std
local std = _G.gpm.std

local string, table = std.string, std.table

-- TODO: rework this library

local table_concat = table.concat
local string_byte, string_sub, string_len, string_match, string_byteSplit, string_byteTrim, string_isURL = string.byte, string.sub, string.len, string.match, string.byteSplit, string.byteTrim, string.isURL

-- References: https://github.com/luvit/luvit/blob/master/deps/path/base.lua

local debug_getfmain, debug_getfpath = std.debug.getfmain, std.debug.getfpath
local getfenv, raw_get, select = std.getfenv, std.raw.get, std.select

---@class gpm.std.file
local file = std.file or {}
std.file = file

--- [SHARED AND MENU]
---
--- The file path library.
---
---@class gpm.std.file.path
local path = {}
file.path = path

--- [SHARED AND MENU]
---
--- Get the file name with extension from file_path.
---
---@param file_path string The file path.
---@return string file_name The file name with extension.
local function getFile( file_path )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            return string_sub( file_path, index + 1 )
        end
    end

    return file_path
end

path.getFile = getFile

--- [SHARED AND MENU]
---
--- Get the file name from file_path.
---
---@param file_path string The file path.
---@param withExtension boolean? Whether to include the extension.
---@return string file_name The file name.
function path.getFileName( file_path, withExtension )
    if withExtension then
        return getFile( file_path )
    end

    local position
    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2E --[[ . ]] then
            if position == nil then
                position = index
            end
        elseif byte == 0x2F --[[ / ]] then
            if position == nil then
                return string_sub( file_path, index + 1 )
            else
                return string_sub( file_path, index + 1, position - 1 )
            end
        end
    end

    if position == nil then
        return file_path
    else
        return string_sub( file_path, 1, position - 1 )
    end
end

--- [SHARED AND MENU]
---
--- Get the directory from file_path.
---
---@param file_path string The file path.
---@param with_trailing_slash boolean? Whether to include the trailing slash.
---@return string directory_path The directory path.
local function getDirectory( file_path, with_trailing_slash )
    if with_trailing_slash == nil then with_trailing_slash = true end

    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            if with_trailing_slash then
                return string_sub( file_path, 1, index )
            else
                return string_sub( file_path, 1, index - 1)
            end
        end
    end

    return ""
end

path.getDirectory = getDirectory

--- [SHARED AND MENU]
---
--- Get the extension from file_path.
---
---@param file_path string The file path.
---@param with_dot boolean? Whether to include the dot.
---@return string extension The extension.
local function getExtension( file_path, with_dot )
    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2F --[[ / ]] then
            break
        elseif byte == 0x2E --[[ . ]] then
            if with_dot then
                return string_sub( file_path, index )
            else
                return string_sub( file_path, index + 1 )
            end
        end
    end

    return ""
end

path.getExtension = getExtension

--- [SHARED AND MENU]
---
--- Strip the file name from file_path.
---
---@param file_path string The file path.
---@param with_trailing_slash boolean? Whether to include the trailing slash in the directory path.
---@return string directory_path The directory path.
---@return string file_name The file name with extension.
local function stripFile( file_path, with_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            if with_trailing_slash then
                return string_sub( file_path, 1, index ), string_sub( file_path, index + 1 )
            else
                return string_sub( file_path, 1, index - 1 ), string_sub( file_path, index + 1 )
            end
        end
    end

    return "", file_path
end

path.stripFile = stripFile

--- [SHARED AND MENU]
---
--- Strip the directory from file_path.
---
---@param file_path string The file path.
---@param with_trailing_slash boolean? Whether to include the trailing slash in the directory path.
---@return string file_name The file name with extension.
---@return string directory_path The directory path.
local function stripDirectory( file_path, with_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            if with_trailing_slash then
                return string_sub( file_path, index + 1 ), string_sub( file_path, 1, index )
            else
                return string_sub( file_path, index + 1 ), string_sub( file_path, 1, index - 1 )
            end
        end
    end

    return file_path, ""
end

path.stripDirectory = stripDirectory

--- [SHARED AND MENU]
---
--- Strip the extension from file_path.
---
---@param file_path string The file path.
---@param with_dot boolean? Whether to include the dot in the extension.
---@return string file_name The file name without extension.
---@return string extension The extension.
local function stripExtension( file_path, with_dot )
    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2F --[[ / ]] then
            return file_path, ""
        elseif byte == 0x2E --[[ . ]] then
            if with_dot then
                return string_sub( file_path, 1, index - 1 ), string_sub( file_path, index )
            else
                return string_sub( file_path, 1, index - 1 ), string_sub( file_path, index + 1 )
            end
        end
    end

    return file_path, ""
end

path.stripExtension = stripExtension

--- [SHARED AND MENU]
---
--- Replace the file name from file_path.
---
---@param file_path string The file path.
---@param file_name string The new file name with extension.
---@return string file_path The new file path.
function path.replaceFile( file_path, file_name )
    return stripFile( file_path ) .. file_name
end

--- [SHARED AND MENU]
---
--- Replace the directory from file_path.
---
---@param file_path string The file path.
---@param directory_name string The new directory path.
---@return string file_path The new file path.
function path.replaceDirectory( file_path, directory_name )
    if string_byte( directory_name, string_len( directory_name ) ) ~= 0x2F --[[ / ]] then
        directory_name = directory_name .. "/"
    end

    return directory_name .. stripDirectory( file_path )
end

--- [SHARED AND MENU]
---
--- Replace the extension from file_path.
---
---@param file_path string The file path.
---@param extension string The new extension.
---@return string file_path The new file path.
function path.replaceExtension( file_path, extension )
    return stripExtension( file_path ) .. "." .. extension
end

--- [SHARED AND MENU]
---
--- Remove the trailing slash from file_path.
---
---@param file_path string The file path.
---@return string file_path The file path without the trailing slash.
local function removeTrailingSlash( file_path )
    local length = string_len( file_path )
    if string_byte( file_path, length ) == 0x2F --[[ / ]] then
        return string_sub( file_path, 1, length - 1 )
    else
        return file_path
    end
end

path.removeTrailingSlash = removeTrailingSlash

local fixSlashes
do

    local string_gsub = string.gsub

    --- [SHARED AND MENU]
    ---
    --- Replaces all backslashes with forward slashes.
    ---
    ---@param str string The string to fix slashes in.
    ---@return string slash_less_str The fixed string.
    function fixSlashes( str )
        ---@diagnostic disable-next-line: redundant-return-value
        return string_gsub( str, "[/\\]+", "/" ), nil
    end

    path.fixSlashes = fixSlashes

end

--- [SHARED AND MENU]
---
--- Get the current file path or function file path.
---
---@param fn function? The function to get the file path from.
---@return string file_path The file path.
local function getCurrentFile( fn )
    if fn == nil then fn = debug_getfmain() end
    if fn == nil then return "/" end

    local fenv = getfenv( fn )
    if fenv then
        local file_path = raw_get( fenv, "__filename" )
        if file_path then
            return file_path
        end
    end

    local file_path = debug_getfpath( fn )
    if string_isURL( file_path ) then
        file_path = string_match( file_path, "^[^/]*([^#?]+).*$" )
        return string_match( file_path, "^//[^/]+/?(.+)$" ) or file_path
    end

    return "/" .. file_path
end

path.getCurrentFile = getCurrentFile

--- [SHARED AND MENU]
---
--- Get the current directory path or function directory path.
---
---@param fn function? The function to get the directory path from.
---@param with_trailing_slash boolean? Whether to include the trailing slash.
---@return string directory_path The directory path.
local function getCurrentDirectory( fn, with_trailing_slash )
    if fn then
        if with_trailing_slash == nil then
            with_trailing_slash = true
        end

        local fenv = getfenv( fn )
        if fenv then
            local dirPath = raw_get( fenv, "__dirname" )
            if dirPath then
                if with_trailing_slash then
                    dirPath = dirPath .. "/"
                else
                    return dirPath
                end
            end
        end

        local file_path = debug_getfpath( fn )
        if string_isURL( file_path ) then
            file_path = string_match( file_path, "^[^/]*([^#?]+).*$" )
            return getDirectory( string_match( file_path, "^//[^/]+/?(.+)$" ) or file_path, with_trailing_slash )
        end

        return getDirectory( "/" .. file_path, with_trailing_slash )
    end

    return "/"
end

path.getCurrentDirectory = getCurrentDirectory

path.delimiter = ":"
path.sep = "/"

--- [SHARED AND MENU]
---
--- Check if file_path is absolute, i.e. starts with a slash.
---
---@param file_path string The file path.
---@return boolean is_abs `true` if file_path is absolute, `false` otherwise.
local function isAbsolute( file_path )
    return string_byte( file_path, 1 ) == 0x2F
end

path.isAbsolute = isAbsolute

local equal
do

    local os_name = std.os.name
    if os_name == "Windows" or os_name == "OSX" then
        local string_lower = string.lower
        --- [SHARED AND MENU]
        ---
        --- Check if filePath1 and filePath2 are equal.
        ---
        ---@param a string The first file path.
        ---@param b string The second file path.
        ---@return boolean is_equal `true` if filePath1 and filePath2 are equal, `false` otherwise.
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

--- [SHARED AND MENU]
---
--- Split a filename into [root, dir, basename].
---
---@param file_path string The file path.
---@return boolean is_abs Whether file_path is absolute.
---@return string directory_path The directory.
---@return string file_name The basename.
local function splitPath( file_path )
    local root
    if isAbsolute( file_path ) then
        file_path = string_sub( file_path, 2 )
        root = true
    else
        root = false
    end

    local basename, dir = stripDirectory( file_path )
    return root, dir, basename
end

path.splitPath = splitPath

--- [SHARED AND MENU]
---
--- Get the directory of a file.
---
---@param file_path string The file path.
---@param with_trailing_slash boolean? Whether to include the trailing slash.
---@return string directory_path The directory path.
function path.dirname( file_path, with_trailing_slash )
    if with_trailing_slash == nil then
        with_trailing_slash = true
    end

    file_path = getDirectory( file_path, with_trailing_slash )
    if file_path == "" then
        if with_trailing_slash then
            return "./"
        else
            return "."
        end
    end

    return file_path
end

--- [SHARED AND MENU]
---
--- Get the basename from file_path.
---
---@param file_path string The file path.
---@param stripSuffix boolean? Whether to strip the extension.
---@return string file_name The basename.
---@return string extension The file extension.
function path.basename( file_path, stripSuffix )
    file_path = getFile( file_path )
    if stripSuffix then
        return stripExtension( file_path )
    end

    return file_path, ""
end

path.extname = getExtension

local normalize
do

    local table_insert, table_remove = table.insert, table.remove

    --- [SHARED AND MENU]
    ---
    --- Normalizes a file path by removing all "." and ".." parts.
    ---
    ---@param file_path string The file path.
    ---@return string file_path The normalized file path.
    function normalize( file_path )
        local trailingSlashes = string_byte( file_path, string_len( file_path ) ) == 0x2F --[[ / ]]

        local isAbs = isAbsolute( file_path )
        if isAbs then
            file_path = string_sub( file_path, 2 )
        end

        local parts, length = string_byteSplit( file_path, 0x2F --[[ / ]] )
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

        file_path = table_concat( parts, "/", 1, length )
        if file_path == "" then
            if isAbs then
                return "/"
            elseif trailingSlashes then
                return "./"
            else
                return "."
            end
        end

        if trailingSlashes then
            file_path = file_path .. "/"
        end

        if isAbs then
            file_path = "/" .. file_path
        end

        return fixSlashes( file_path )
    end

    path.normalize = normalize

end

--- [SHARED AND MENU]
---
--- Join the file paths into a single file path and normalize it.
---
---@param ... string The file paths.
---@return string file_path The joined file path.
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

--- [SHARED AND MENU]
---
--- Resolve the file paths into a single file path.
---
---@param ... string The file paths.
---@return string path The resolved path.
local function resolve( ... )
    local args, resolvedPath = { ... }, ""
    for index = select( "#", ... ), 1, -1 do
        local file_path = args[ index ]
        if file_path and file_path ~= "" then
            resolvedPath = join( normalize( file_path ), resolvedPath )
            if isAbsolute( resolvedPath ) then
                return resolvedPath
            end
        end
    end

    return getCurrentDirectory( nil, true ) .. resolvedPath
end

path.resolve = resolve

--- [SHARED AND MENU]
---
--- Returns the relative path from "from" to "to".
---
--- If no relative path can be solved, then "to" is returned.
---
---@param pathFrom string The file path.
---@param pathTo string The file path.
---@return string relative_path The relative path.
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
---@param file_path string The file path.
---@return gpm.std.file.path.Data data The parsed file path data.
function path.parse( file_path )
    local isAbs, dir, base = splitPath( file_path )
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
