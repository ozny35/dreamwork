---@class gpm.std
local std = _G.gpm.std

local string = std.string

local string_sub, string_gsub = string.sub, string.gsub
local string_byte = string.byte
local string_len = string.len

---@class gpm.std.file
local file = std.file or {}
std.file = file

--- [SHARED AND MENU]
---
--- The file path library.
---
---@class gpm.std.file.path
---@field delimiter string The path delimiter.
---@field sep string The path separator.
local path = file.path or {}
file.path = path

path.delimiter = ":"
path.sep = "/"

--- [SHARED AND MENU]
---
--- Check to see if the file path is absolute.
---
---@param file_path string The file path.
---@return boolean is_abs `true` if the file path is absolute, `false` otherwise.
function path.isAbsolute( file_path )
    return string_byte( file_path, 1 ) == 0x2F --[[ / ]]
end

--- [SHARED AND MENU]
---
--- Check to see if the file path is relative.
---
---@param file_path string The file path.
---@return boolean is_rel `true` if the file path is relative, `false` otherwise.
function path.isRelative( file_path )
    return string_byte( file_path, 1 ) ~= 0x2F --[[ / ]]
end

if std.WINDOWS or std.OSX then

    local string_lower = string.lower

    --- [SHARED AND MENU]
    ---
    --- Check to see if the paths are equal.
    ---
    ---@param file_path1 string The first file path.
    ---@param file_path2 string The second file path.
    ---@return boolean is_equal `true` if the paths are equal, `false` otherwise.
    function path.equals( file_path1, file_path2 )
        return string_lower( file_path1 ) == string_lower( file_path2 )
    end

else

    --- [SHARED AND MENU]
    ---
    --- Check to see if the paths are equal.
    ---
    ---@param file_path1 string The first file path.
    ---@param file_path2 string The second file path.
    ---@return boolean is_equal `true` if the paths are equal, `false` otherwise.
    function path.equals( file_path1, file_path2 )
        return file_path1 == file_path2
    end

end

--- [SHARED AND MENU]
---
--- Get the name of the file path.
---
---@param file_path string The file path.
---@param keep_extension? boolean `true` to keep the extension, `false` otherwise
---@return string file_name The name of the file.
function path.getName( file_path, keep_extension )
    if keep_extension then
        for index = string_len( file_path ), 1, -1 do
            if string_byte( file_path, index ) == 0x2F --[[ / ]] then
                return string_sub( file_path, index + 1 )
            end
        end

        return file_path
    end

    local dot_position

    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2E --[[ . ]] then
            if dot_position == nil then
                dot_position = index
            end
        elseif byte == 0x2F --[[ / ]] then
            if dot_position == nil then
                return string_sub( file_path, index + 1 )
            else
                return string_sub( file_path, index + 1, dot_position - 1 )
            end
        end
    end

    if dot_position == nil then
        return file_path
    else
        return string_sub( file_path, 1, dot_position - 1 )
    end
end

--- [SHARED AND MENU]
---
--- Get the directory of the file path.
---
---@param file_path string The file path.
---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
---@return string | nil directory The directory of the file, or `nil` if the file path is invalid.
local function path_getDirectory( file_path, keep_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            if not keep_trailing_slash then
                index = index - 1
            end

            return string_sub( file_path, 1, index )
        end
    end
end

path.getDirectory = path_getDirectory

--- [SHARED AND MENU]
---
--- Get the extension of the file path.
---
---@param file_path string The file path.
---@param keep_dot? boolean `true` to keep the dot, `false` otherwise.
---@return string extension The extension of the file.
function path.getExtension( file_path, keep_dot )
    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2F --[[ / ]] then
            break
        elseif byte == 0x2E --[[ . ]] then
            if not keep_dot then
                index = index + 1
            end

            return string_sub( file_path, index )
        end
    end

    return ""
end

--- [SHARED AND MENU]
---
--- Split a file path into a directory and a file name.
---
---@param file_path string The file path.
---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
---@return string directory The directory from the file path.
---@return string file_name The file from the file path.
local function path_split( file_path, keep_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            return string_sub( file_path, 1, keep_trailing_slash and index or ( index - 1 ) ), string_sub( file_path, index + 1 )
        end
    end

    return "", file_path
end

path.split = path_split

--- [SHARED AND MENU]
---
--- Split a file path into a file name and an extension.
---
---@param file_path string The file path.
---@param keep_dot? boolean `true` to keep the extension dot, `false` otherwise.
---@return string file_name The file name from the file path.
---@return string extension The extension from the file path.
local function path_splitExtension( file_path, keep_dot )
    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2F --[[ / ]] then
            return file_path, ""
        elseif byte == 0x2E --[[ . ]] then
            return string_sub( file_path, 1, index - 1 ), string_sub( file_path, keep_dot and index or ( index + 1 ) )
        end
    end

    return file_path, ""
end

path.splitExtension = path_splitExtension

--- [SHARED AND MENU]
---
--- Replaces the file name in the file path.
---
---@param file_path string The file path.
---@param file_name string The new file name.
---@return string new_file_path The new file path.
function path.replaceName( file_path, file_name )
    return path_split( file_path, true ) .. file_name
end

--- [SHARED AND MENU]
---
--- Replaces the directory in the file path.
---
---@param file_path string The file path.
---@param dir_name string The new directory.
---@return string new_file_path The new file path.
function path.replaceDirectory( file_path, dir_name )
    if string_byte( dir_name, string_len( dir_name ) ) ~= 0x2F --[[ / ]] then
        dir_name = dir_name .. "/"
    end

    local _, file_name = path_split( file_path, false )
    return dir_name .. file_name
end

--- [SHARED AND MENU]
---
--- Replaces the extension in the file path.
---
---@param file_path string The file path.
---@param ext_name string The new extension.
---@return string new_file_path The new file path.
function path.replaceExtension( file_path, ext_name )
    return path_splitExtension( file_path, false ) .. "." .. ext_name
end

--- [SHARED AND MENU]
---
--- Strips the trailing slash from the file path.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.stripTrailingSlash( file_path )
    ---@diagnostic disable-next-line: redundant-return-value
    return string_gsub( file_path, "[/\\]+$", "" ), nil
end

--- [SHARED AND MENU]
---
--- Ensures the file path has a trailing slash.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.ensureTrailingSlash( file_path )
    if string_byte( file_path, string_len( file_path ) ) == 0x2F --[[ / ]] then
        return file_path
    else
        return file_path .. "/"
    end
end

--- [SHARED AND MENU]
---
--- Strips the leading slash from the file path.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.stripLeadingSlash( file_path )
    ---@diagnostic disable-next-line: redundant-return-value
    return string_gsub( file_path, "^[/\\]+", "" ), nil
end

--- [SHARED AND MENU]
---
--- Ensures the file path has a leading slash.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.ensureLeadingSlash( file_path )
    if string_byte( file_path, 1 ) == 0x2F --[[ / ]] then
        return file_path
    else
        return "/" .. file_path
    end
end

--- [SHARED AND MENU]
---
--- Normalizes the slashes in the file path.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.normalizeSlashes( file_path )
    ---@diagnostic disable-next-line: redundant-return-value
    return string_gsub( file_path, "[/\\]+", "/" ), nil
end

--- [SHARED AND MENU]
---
--- Parse a file path into [root, dir, basename, ext, name, abs] table.
---
---     ┌─────────────────────┬────────────┐
---     │          dir        │    base    │
---     ├──────┬              ├──────┬─────┤
---     │ root │              │ name │ ext │
---     "  /    home/user/dir/  file  .txt "
---     └──────┴──────────────┴──────┴─────┘
--- (All spaces in the "" line should be ignored. They are purely for formatting.)
---
---@param file_path string The file path.
---@return gpm.std.file.path.Data data The parsed file path data.
function path.parse( file_path )
    local is_abs = string_byte( file_path, 1 ) == 0x2F --[[ / ]]
    local directory, base = path_split( file_path, true )
    local name, ext = path_splitExtension( base, true )

    return { root = is_abs and "/" or "", dir = directory, base = base, ext = ext, name = name, abs = is_abs }
end

local path_getCurrentDirectory
do

    local debug = std.debug
    local debug_getfmain = debug.getfmain
    local debug_getfpath = debug.getfpath

    --- [SHARED AND MENU]
    ---
    --- Get the current file path.
    ---
    ---@param level? integer The stack level to get the file path from.
    ---@return string file_path
    function path.getCurrentFile( level )
        local fn = debug_getfmain( ( level or 1 ) + 1 )
        if fn == nil then
            return "/unknown.lua"
        end

        local fenv = getfenv( fn )
        if fenv ~= nil then
            local file_path = fenv.__filename
            if file_path ~= nil then
                return file_path
            end
        end

        return debug_getfpath( fn ) or "/unknown.lua"
    end

    --- [SHARED AND MENU]
    ---
    --- Get the current directory path.
    ---
    ---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
    ---@param level? integer The stack level to get the file path from.
    ---@return string directory_path
    function path_getCurrentDirectory( keep_trailing_slash, level )
        local fn = debug_getfmain( ( level or 1 ) + 1 )
        if fn == nil then
            return "/"
        end

        local fenv = getfenv( fn )
        if fenv ~= nil then
            local directory_path = fenv.__dirname
            if directory_path ~= nil then
                if keep_trailing_slash then
                    return directory_path .. "/"
                else
                    return directory_path
                end
            end
        end

        local file_path = debug_getfpath( fn )
        if file_path == nil then
            return "/"
        else
            return path_getDirectory( file_path, keep_trailing_slash ) or "/"
        end
    end

    path.getCurrentDirectory = path_getCurrentDirectory

end

local table = std.table
local table_concat = table.concat
local table_insert, table_remove = table.insert, table.remove

local string_byteSplit = string.byteSplit

--- [SHARED AND MENU]
---
--- Normalizes a file path by removing all "." and ".." parts.
---
---@param file_path string The file path.
---@return string new_file_path The normalized file path.
local function path_normalize( file_path )
    local path_length = string_len( file_path )

    if path_length == 0 then
        return file_path
    end

    local has_trailing_slash = string_byte( file_path, path_length ) == 0x2F --[[ / ]]
    local is_abs = string_byte( file_path, 1 ) == 0x2F --[[ / ]]

    if has_trailing_slash and is_abs then
        file_path = string_sub( file_path, 2, path_length - 1 )
    elseif has_trailing_slash then
       file_path = string_sub( file_path, 1, path_length - 1 )
    elseif is_abs then
        file_path = string_sub( file_path, 2 )
    end

    local parts, length = string_byteSplit( file_path, 0x2F --[[ / ]] )
    local skip = 0

    for index = length, 1, -1 do
        local b1, b2, b3 = string_byte( parts[ index ], 1, 3 )
        if b2 == nil and b1 == 0x2E --[[ . ]] then
            table_remove( parts, index )
            length = length - 1
        elseif b3 == nil and b1 == 0x2E --[[ . ]] and b2 == 0x2E --[[ . ]] then
            table_remove( parts, index )
            length = length - 1
            skip = skip + 1
        elseif skip > 0 then
            table_remove( parts, index )
            length = length - 1
            skip = skip - 1
        end
    end

    if not is_abs then
        while skip > 0 do
            table_insert( parts, 1, ".." )
            length = length + 1
            skip = skip - 1
        end
    end

    local new_path

    if length == 0 then
        new_path = ""
    else
        new_path = table_concat( parts, "/", 1, length )
    end

    if string_byte( new_path, 1, 1 ) == nil then
        if has_trailing_slash then
            return "./"
        elseif is_abs then
            return "/"
        else
            return "."
        end
    end

    if has_trailing_slash and is_abs then
        return "/" .. new_path .. "/"
    elseif has_trailing_slash then
        return new_path .. "/"
    elseif is_abs then
        return "/" .. new_path
    else
        return new_path
    end
end

path.normalize = path_normalize

--- [SHARED AND MENU]
---
--- Resolve a file path.
---
---@param file_path string The file path.
---@return string file_path The resolved file path.
local function path_resolve( file_path )
    if string_byte( file_path, 1, 1 ) == 0x2F --[[ / ]] then
        return path_normalize( file_path )
    else
        return path_normalize( path_getCurrentDirectory( true ) .. file_path )
    end
end

path.resolve = path_resolve

local path_join
do

    local string_byteTrim = string.byteTrim

    --- [SHARED AND MENU]
    ---
    --- Join the file paths into a single file path and normalize it.
    ---
    ---@param ... string The file paths.
    ---@return string file_path The joined file path.
    function path_join( ... )
        local arg_count = select( "#", ... )
        local args = { ... }

        for index = 1, arg_count, 1 do
            local value = args[ index ]
            if value and value ~= "" then
                args[ index ] = value
            else
                args[ index ] = ""
            end
        end

        for index = 1, arg_count, 1 do
            local value = args[ index ]
            if index > 1 then
                value = string_byteTrim( value, 0x2F, 1 )
            end

            if index < arg_count then
                value = string_byteTrim( value, 0x2F, -1 )
            end

            args[ index ] = value
        end

        return path_normalize( table_concat( args, "/", 1, arg_count ) )
    end

    path.join = path_join

end

do

    local path_equals = path.equals
    local math_min = std.math.min

    --- [SHARED AND MENU]
    ---
    --- Get the relative path from one file path to another.
    ---
    ---@param from string The from file path.
    ---@param to string The to file path.
    ---@return string relative_path The relative path.
    function path.relative( from, to )
        local from_path, to_path = path_normalize( from ), path_normalize( to )

        if path_equals( from_path, to_path ) then
            return "."
        end

        local from_parts, from_part_count = string_byteSplit( from_path, 0x2F --[[ / ]] )
        local to_parts, to_part_count = string_byteSplit( to_path, 0x2F --[[ / ]] )
        local equal_count = 0

        for index = 1, math_min( from_part_count, to_part_count ), 1 do
            if path_equals( from_parts[ index ], to_parts[ index ] ) then
                equal_count = equal_count + 1
            else
                break
            end
        end

        local result_parts, result_part_count = {}, 0
        for _ = equal_count + 1, from_part_count, 1 do
            result_part_count = result_part_count + 1
            result_parts[ result_part_count ] = ".."
        end

        for index = equal_count + 1, to_part_count, 1 do
            result_part_count = result_part_count + 1
            result_parts[ result_part_count ] = to_parts[ index ]
        end

        if result_part_count == 0 then
            return "."
        else
            return table_concat( result_parts, "/", 1, result_part_count )
        end
    end

end
